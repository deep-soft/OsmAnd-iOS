//
//  OAExportItemsViewController.m
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportItemsViewController.h"
#import "OARootViewController.h"
#import "OAExportSettingsType.h"
#import "Localization.h"
#import "OAProgressTitleCell.h"
#import "OAColors.h"
#import "OAExportSettingsCategory.h"
#import "OASettingsCategoryItems.h"
#import "OATableViewCustomHeaderView.h"

#define kDefaultArchiveName @"Export"
#define kSettingsSectionIndex 0
#define kMyPlacesSectionIndex 1
#define kResourcesSectionIndex 2

@implementation OAExportItemsViewController
{
    NSString *_descriptionText;
    NSString *_descriptionBoldText;

    OASettingsHelper *_settingsHelper;
    OAApplicationMode *_appMode;

    BOOL _exportStarted;
    long _itemsSize;
    NSString *_fileSize;
    NSString *_headerLabel;
    BOOL _shouldOpenSettingsOnInit;
    BOOL _shouldOpenMyPlacesOnInit;
    BOOL _shouldOpenResourcesOnInit;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
    }
    return self;
}

- (instancetype)initWithTracks:(NSArray<NSString *> *)tracks
{
    self = [super init];
    if (self)
    {
        self.selectedItemsMap[OAExportSettingsType.TRACKS] = tracks;
        _shouldOpenMyPlacesOnInit = YES;
    }
    return self;
}

- (instancetype)initWithType:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems
{
    self = [super init];
    if (self)
    {
        self.selectedItemsMap[type] = selectedItems;
        _shouldOpenMyPlacesOnInit = YES;
    }
    return self;
}

- (instancetype) initWithTypes:(NSDictionary<OAExportSettingsType *, NSArray<id> *> *)typesItems;
{
    self = [super init];
    if (self)
    {
        for (OAExportSettingsType *type in typesItems.allKeys)
        {
            self.selectedItemsMap[type] = typesItems[type];
            if ([type isSettingsCategory])
                _shouldOpenSettingsOnInit = YES;
            else if ([type isMyPlacesCategory])
                _shouldOpenMyPlacesOnInit = YES;
            else if ([type isResourcesCategory])
                _shouldOpenResourcesOnInit = YES;
        }
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = OASettingsHelper.sharedInstance;
    _itemsSize = 0;
    [self updateFileSize];
}

- (void)applyLocalization
{
    [super applyLocalization];
    _descriptionText = OALocalizedString(@"export_profile_select_descr");
    _descriptionBoldText = _appMode ? OALocalizedString(@"export_profile") : OALocalizedString(@"shared_string_export");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setTableHeaderView:_descriptionBoldText];
    } completion:nil];
}

- (void)setupView
{
    [self setTableHeaderView:_descriptionBoldText];

    if (_exportStarted)
    if (_exportStarted)
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = OALocalizedString(@"preparing_file");
        self.data = @[group];
        self.additionalNavBarButton.hidden = YES;
        return;
    }
    self.itemsMap = [_settingsHelper getSettingsByCategory:YES];
    self.itemTypes = self.itemsMap.allKeys;
    [self generateData];
    [self updateSelectedProfile];
    [self updateControls];
}

- (void) generateData
{
    [super generateData];
    if (_shouldOpenSettingsOnInit)
    {
        self.data[kSettingsSectionIndex].isOpen = YES;
        _shouldOpenSettingsOnInit = NO;
    }
    if (_shouldOpenMyPlacesOnInit)
    {
        self.data[kMyPlacesSectionIndex].isOpen = YES;
        _shouldOpenMyPlacesOnInit = NO;
    }
    if (_shouldOpenResourcesOnInit)
    {
        self.data[kResourcesSectionIndex].isOpen = YES;
        _shouldOpenResourcesOnInit = NO;
    }
}

- (NSString *)descriptionText
{
    return _descriptionText;
}

- (NSString *)descriptionBoldText
{
    return _descriptionBoldText;
}

- (NSString *)getTitleForSection
{
    return [NSString stringWithFormat: @"%@\n%@", _descriptionText, _fileSize];
}

- (void)onGroupCheckmarkPressed:(UIButton *)sender
{
    [super onGroupCheckmarkPressed:sender];
    [self updateFileSize];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) updateSelectedProfile {
    OASettingsCategoryItems *items = self.itemsMap[OAExportSettingsCategory.SETTINGS];
    NSArray<OAApplicationModeBean *> *profileItems = [items getItemsForType:OAExportSettingsType.PROFILE];

    for (OAApplicationModeBean *item in profileItems) {
        if ([_appMode.stringKey isEqualToString:(item.stringKey)]) {
            NSArray<id> *selectedProfiles = @[item];
            self.selectedItemsMap[OAExportSettingsType.PROFILE] = selectedProfiles;
            break;
        }
    }
}

- (void)shareProfile
{
    _exportStarted = YES;
    [self setupView];
    [self.tableView reloadData];

    OASettingsHelper *settingsHelper = OASettingsHelper.sharedInstance;
    NSArray<OASettingsItem *> *settingsItems = [settingsHelper prepareSettingsItems:self.getSelectedItems settingsItems:@[] doExport:YES];
    NSString *fileName;
    if (_appMode)
    {
        fileName = _appMode.toHumanString;
    }
    else
    {
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yy"];
        NSString *dateFormat = [formatter stringFromDate:date];
        fileName = [NSString stringWithFormat:@"%@_%@", kDefaultArchiveName, dateFormat];
    }
    [settingsHelper exportSettings:NSTemporaryDirectory() fileName:fileName items:settingsItems exportItemFiles:YES delegate:self];
}

- (long)getItemSize:(NSString *)item
{
    NSFileManager *defaultManager = NSFileManager.defaultManager;
    NSDictionary *attrs = [defaultManager attributesOfItemAtPath:item error:nil];
    return attrs.fileSize;
}

- (void)updateFileSize
{
    _itemsSize = [self calculateItemsSize:self.getSelectedItems];
    _fileSize = [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"approximate_file_size"), [NSByteCountFormatter stringFromByteCount:_itemsSize countStyle:NSByteCountFormatterCountStyleFile]];
}

- (IBAction)primaryButtonPressed:(id)sender
{
    [self shareProfile];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        [customHeader setYOffset:8];
        UITextView *headerLabel = customHeader.label;
        NSMutableAttributedString *newHeaderText = [[NSMutableAttributedString alloc] initWithString:_descriptionText attributes:@{NSForegroundColorAttributeName:UIColorFromRGB(color_text_footer)}];
        UIColor *colorFileSize = _itemsSize == 0 ? UIColorFromRGB(color_text_footer) : [UIColor blackColor];
        NSMutableAttributedString *headerFileSizeText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@", _fileSize] attributes:@{NSForegroundColorAttributeName: colorFileSize}];
        [newHeaderText appendAttributedString:headerFileSizeText];
        headerLabel.attributedText = newHeaderText;
        headerLabel.font = [UIFont scaledSystemFontOfSize:15];
        return customHeader;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        NSString *title = [self getTitleForSection];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + 8;
    }
    return UITableViewAutomaticDimension;
}

- (void) setTableHeaderView:(NSString *)label
{
    _headerLabel = label;
    [super setTableHeaderView:label];
    self.titleLabel.text = label;
}

- (NSString *) getTableHeaderTitle
{
    return _headerLabel;
}

#pragma mark - OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    self.selectedItemsMap[type] = items;
    [self updateFileSize];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

    OAExportSettingsCategory * category = [type getCategory];
    NSInteger indexCategory = [self.itemTypes indexOfObject:category];
    if (category && indexCategory != 0)
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexCategory] withRowAnimation:UITableViewRowAnimationNone];

    [self updateControls];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        [self shareProfile];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"export_failed") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed {
    [self.navigationController popViewControllerAnimated:YES];
    
    if (succeed)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            OARootViewController *rootVC = [OARootViewController instance];
            
            UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:file]]
                                              applicationActivities:nil];
            
            activityViewController.popoverPresentationController.sourceView = rootVC.view;
            activityViewController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rootVC.view.bounds), CGRectGetMidY(rootVC.view.bounds), 0., 0.);
            activityViewController.popoverPresentationController.permittedArrowDirections = 0;
            
            [rootVC presentViewController:activityViewController
                                 animated:YES
                               completion:nil];
        });
    }
}

@end
