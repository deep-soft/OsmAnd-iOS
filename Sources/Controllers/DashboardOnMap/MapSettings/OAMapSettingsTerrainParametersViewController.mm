//
//  OAMapSettingsTerrainParametersViewController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 08.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMapSettingsTerrainParametersViewController.h"
#import "Localization.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OsmAndApp.h"
#import "OATitleSliderTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OARootViewController.h"
#import "OAColors.h"
#import "OAMapLayers.h"
#import "OATerrainMapLayer.h"

static const NSInteger kMinAllowedZoom = 1;
static const NSInteger kMaxAllowedZoom = 22;
static const NSInteger kMaxMissingDataZoomShift = 5;
static const NSInteger kMinZoomPickerRow = 1;
static const NSInteger kMaxZoomPickerRow = 2;

@interface OAMapSettingsTerrainParametersViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

@end

@implementation OAMapSettingsTerrainParametersViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    EOATerrainType _type;
    OAMapPanelViewController *_mapPanel;
    
    NSArray<NSString *> *_possibleZoomValues;
    
    NSInteger _minZoom;
    NSInteger _maxZoom;
    NSInteger _baseMinZoom;
    NSInteger _baseMaxZoom;
    double _baseAlpha;
    double _currentAlpha;
    
    NSIndexPath *_minValueIndexPath;
    NSIndexPath *_maxValueIndexPath;
    NSIndexPath *_pickerIndexPath;
    
    UIView *_footerView;
    UIButton *_applyButton;
    
    BOOL _isValueChange;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(EOATerrainSettingsType)terrainType
{
    self = [super initWithNibName:@"OAMapSettingsTerrainParametersViewController" bundle:nil];
    if (self)
    {
        _terrainType = terrainType;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = OsmAndApp.instance;
    _type = _app.data.terrainType;
    _mapPanel = OARootViewController.instance.mapPanel;
    
    _baseMinZoom = _type == EOATerrainTypeHillshade ? _app.data.hillshadeMinZoom : _app.data.slopeMinZoom;
    _baseMaxZoom = _type == EOATerrainTypeHillshade ? _app.data.hillshadeMaxZoom : _app.data.slopeMaxZoom;
    _baseAlpha = _type == EOATerrainTypeHillshade ? _app.data.hillshadeAlpha : _app.data.slopeAlpha;
    _minZoom = _baseMinZoom;
    _maxZoom = _baseMaxZoom;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self applyLocalization];
    
    _possibleZoomValues = [self getPossibleZoomValues];
    [self generateData];
    
    [self.resetButton setImage:[UIImage templateImageNamed:@"ic_navbar_reset"] forState:UIControlStateNormal];
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];
    [self.resetButton addBlurEffect:YES cornerRadius:12. padding:0];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setupBottomButton];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat btnMargin = MAX(10, [OAUtilities getLeftMargin]);
    CGFloat yPosition = _footerView.frame.size.height - 44.0;
    _footerView.subviews[0].frame = CGRectMake(btnMargin, yPosition, _footerView.frame.size.width - btnMargin * 2, 44.0);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_mapPanel targetUpdateControlsLayout:YES
                     customStatusBarStyle:[OAAppSettings sharedManager].nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (![self isLandscape])
            [self goMinimized:NO];
    } completion:nil];
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void)generateData
{
    _data = [OATableDataModel model];
    
    OATableSectionData *topSection = [_data createNewSection];
    topSection.headerText = _terrainType == EOATerrainSettingsTypeVisibility ? OALocalizedString(@"visibility") : OALocalizedString(@"shared_string_zoom_levels");
    topSection.footerText = _terrainType == EOATerrainSettingsTypeZoomLevels ? OALocalizedString(@"map_settings_zoom_level_description") : nil;
    if (_terrainType == EOATerrainSettingsTypeVisibility)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey : @"visibilitySlider",
            kCellTypeKey : [OATitleSliderTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"visibility")
        }];
    }
    else
    {
        [topSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey: OALocalizedString(@"rec_interval_minimum"),
            @"value" : @(_minZoom)
        }];
        _minValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_pickerIndexPath && _pickerIndexPath.row == _minValueIndexPath.row + 1)
            [topSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell getCellIdentifier] }];
        
        [topSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_maximum"),
            @"value" : @(_maxZoom)
        }];
        _maxValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_pickerIndexPath && _pickerIndexPath.row == _maxValueIndexPath.row + 1)
            [topSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell getCellIdentifier] }];
    }
}

- (void)generateValueForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == _minValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_minZoom) forKey:@"value"];
    else if (indexPath == _maxValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_maxZoom) forKey:@"value"];
}

- (void)setupBottomButton
{
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, _terrainType == EOATerrainSettingsTypeZoomLevels ? 80.0 : 120.0)];
    _applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_applyButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
    _applyButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _applyButton.layer.cornerRadius = 10;
    _applyButton.frame = CGRectMake(10, 0, _footerView.frame.size.width - 20.0, 44.0);
    [_applyButton addTarget:self action:@selector(onApplyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self updateApplyButton];
    [_footerView addSubview:_applyButton];
    self.tableView.tableFooterView = _footerView;
}

- (void)updateApplyButton
{
    _applyButton.backgroundColor = _isValueChange ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_disabled_light);
    [_applyButton setTitleColor: _isValueChange ? [UIColor whiteColor] : [UIColor lightGrayColor] forState:UIControlStateNormal];
    _applyButton.userInteractionEnabled = _isValueChange;
}

- (CGFloat)initialMenuHeight
{
    return ([OAUtilities calculateScreenHeight] / 3.0) + [OAUtilities getBottomMargin];
}

- (CGFloat)getToolbarHeight
{
    return 0.;
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (BOOL)useGestureRecognizer
{
    return NO;
}

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    self.backButtonLeadingConstraint.constant = [self isLandscape]
    ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
    : [OAUtilities getLeftMargin] + 10.;
}

#pragma mark - Aditions

- (void)resetVisibilityValues
{
    double alpha;
    if (_type == EOATerrainTypeHillshade)
    {
        [_app.data resetHillshadeAlpha];
        alpha = _app.data.hillshadeAlpha;
    }
    else
    {
        [_app.data resetSlopeAlpha];
        alpha = _app.data.slopeAlpha;
    }

    if (_currentAlpha != alpha)
    {
        _currentAlpha = alpha;
        _isValueChange = YES;
        [self updateApplyButton];
    }
}

- (void)resetZoomLevels
{
    NSInteger minZoom;
    NSInteger maxZoom;
    if (_type == EOATerrainTypeHillshade)
    {
        [_app.data resetHillshadeMinZoom];
        [_app.data resetHillshadeMaxZoom];
        minZoom = _app.data.hillshadeMinZoom;
        maxZoom = _app.data.hillshadeMaxZoom;
    }
    else
    {
        [_app.data resetSlopeMinZoom];
        [_app.data resetSlopeMaxZoom];
        minZoom = _app.data.slopeMinZoom;
        maxZoom = _app.data.slopeMaxZoom;
    }

    if (_minZoom != minZoom || _maxZoom != maxZoom)
    {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _isValueChange = YES;
        [self updateApplyButton];
    }
    
}

- (void)applyCurrentVisibility
{
    if (_type == EOATerrainTypeHillshade)
        _app.data.hillshadeAlpha = _currentAlpha;
    else
        _app.data.slopeAlpha = _currentAlpha;
}

- (void)applyCurrentZoomLevels
{
    if (_type == EOATerrainTypeHillshade)
    {
        _app.data.hillshadeMinZoom = _minZoom;
        _app.data.hillshadeMaxZoom = _maxZoom;
    }
    else
    {
        _app.data.slopeMinZoom = _minZoom;
        _app.data.slopeMaxZoom = _maxZoom;
    }
}

- (NSArray<NSString *> *)getPossibleZoomValues
{
    NSMutableArray *res = [NSMutableArray new];
    OsmAnd::ZoomLevel maxZoom = OARootViewController.instance.mapPanel.mapViewController.mapLayers.terrainMapLayer.getMaxZoom;
    int maxVisibleZoom = maxZoom + kMaxMissingDataZoomShift;
    for (int i = 1; i <= maxVisibleZoom; i++)
    {
        [res addObject:[NSString stringWithFormat:@"%d", i]];
    }
    return res;
}

#pragma mark - Actions

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self hide];
}

- (IBAction)resetButtonPressed:(UIButton *)sender
{
    if (_terrainType == EOATerrainSettingsTypeVisibility)
        [self resetVisibilityValues];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels)
        [self resetZoomLevels];
    
    [self generateData];
    [self.tableView reloadData];
}

- (void)onApplyButtonPressed
{
    if (_terrainType == EOATerrainSettingsTypeVisibility)
        [self applyCurrentVisibility];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels)
        [self applyCurrentZoomLevels];
    
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onBackTerrainParameters];
    }];
}

- (void)hide
{
    if (_terrainType == EOATerrainSettingsTypeVisibility)
    {
        if (_type == EOATerrainTypeHillshade)
            _app.data.hillshadeAlpha = _baseAlpha;
        else
            _app.data.slopeAlpha = _baseAlpha;
    }
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels)
    {
        if (_type == EOATerrainTypeHillshade)
        {
            _app.data.hillshadeMinZoom = _baseMinZoom;
            _app.data.hillshadeMaxZoom = _baseMaxZoom;
        }
        else
        {
            _app.data.slopeMinZoom = _baseMinZoom;
            _app.data.slopeMaxZoom = _baseMaxZoom;
        }
    }
    
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onBackTerrainParameters];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanel hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

- (void)sliderValueChanged:(UISlider *)slider
{
    if (_type == EOATerrainTypeHillshade)
    {
        _currentAlpha = slider.value;
        _app.data.hillshadeAlpha = _currentAlpha;
    }
    else
    {
        _currentAlpha = slider.value;
        _app.data.slopeAlpha = _currentAlpha;
    }
    
    _isValueChange = YES;
    [self updateApplyButton];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    if ([item.cellType isEqualToString:[OATitleSliderTableViewCell getCellIdentifier]])
    {
        OATitleSliderTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.minimumTrackTintColor = UIColor.systemBlueColor;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.sliderView.value = _app.data.terrainType == EOATerrainTypeSlope ? _app.data.slopeAlpha : _app.data.hillshadeAlpha;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.valueLabel.textColor = UIColor.blackColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.dataArray = _possibleZoomValues;
            NSInteger minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
            NSInteger maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
            [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
            cell.picker.tag = indexPath.row;
            cell.delegate = self;
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath == _minValueIndexPath || indexPath == _maxValueIndexPath)
    {
        [self.tableView beginUpdates];
        NSIndexPath *newPickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        BOOL isThisPicker = _pickerIndexPath == newPickerIndexPath;
        if (_pickerIndexPath != nil)
            [self.tableView deleteRowsAtIndexPaths:@[_pickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        _pickerIndexPath = isThisPicker ? nil : newPickerIndexPath;
        [self generateData];
        if (!isThisPicker)
            [self.tableView insertRowsAtIndexPaths:@[_pickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:_minValueIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)resetPickerValue:(NSInteger)zoomValue
{
    if (_pickerIndexPath)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_pickerIndexPath];
        if ([cell isKindOfClass:OACustomPickerTableViewCell.class])
        {
            OACustomPickerTableViewCell *pickerCell = (OACustomPickerTableViewCell *) cell;
            [pickerCell.picker selectRow:zoomValue - 1 inComponent:0 animated:YES];
        }
    }
}

- (void)customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    NSIndexPath *zoomValueIndexPath;
    NSInteger intValue = [value integerValue];
    if (pickerTag == kMinZoomPickerRow)
    {
        zoomValueIndexPath = _minValueIndexPath;
        if (intValue <= _maxZoom)
        {
            _minZoom = intValue;
            if (_type == EOATerrainTypeHillshade)
                _app.data.hillshadeMinZoom = _minZoom;
            else if (_type == EOATerrainTypeSlope)
                _app.data.slopeMinZoom = _minZoom;
        }
        else
        {
            _minZoom = _maxZoom;
            [self resetPickerValue:_maxZoom];
        }
    }
    else if (pickerTag == kMaxZoomPickerRow)
    {
        zoomValueIndexPath = _maxValueIndexPath;
        if (intValue >= _minZoom)
        {
            _maxZoom = intValue;
            if (_type == EOATerrainTypeHillshade)
                _app.data.hillshadeMaxZoom = _maxZoom;
            else if (_type == EOATerrainTypeSlope)
                _app.data.slopeMaxZoom = _maxZoom;
        }
        else
        {
            _maxZoom = _minZoom;
            [self resetPickerValue:_minZoom];
        }
    }
    
    if (zoomValueIndexPath)
    {
        [self generateValueForIndexPath:zoomValueIndexPath];
        [self.tableView reloadRowsAtIndexPaths:@[zoomValueIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        _isValueChange = YES;
        [self updateApplyButton];
    }
}

@end