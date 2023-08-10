//
//  OAMainSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OAMainSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"
#import "OAPurchasesViewController.h"
#import "OABackupHelper.h"
#import "OASizes.h"
#import "OACreateProfileViewController.h"
#import "OARearrangeProfilesViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAExportItemsViewController.h"
#import "OACloudIntroductionViewController.h"
#import "OACloudBackupViewController.h"

#define kAppModesSection 2

@interface OAMainSettingsViewController () <UIDocumentPickerDelegate>

@end

@implementation OAMainSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;

    OAApplicationMode *_targetAppMode;
    NSString *_targetScreenKey;
}

#pragma mark - Initialization

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey
{
    self = [super init];
    if (self)
    {
        _targetAppMode = mode;
        _targetScreenKey = targetScreenKey;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAvailableAppModesChanged)
                                                 andObserve:[OsmAndApp instance].availableAppModesChangedObservable]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onAvailableAppModesChanged)
                                                 andObserve:OsmAndApp.instance.data.applicationModeChangedObservable]];
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OACloudBackupViewController class]])
        {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            return;
        }
    }
    [super viewWillDisappear:animated];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_settings");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - UIViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_targetAppMode)
    {
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:_targetAppMode
                                                                                                  targetScreenKey:_targetScreenKey];
        [self.navigationController pushViewController:profileConf animated:YES];
        _targetAppMode = nil;
        _targetScreenKey = nil;
    }
}

#pragma mark - Table data

- (void)generateData
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"name" : @"osmand_settings",
            @"title" : OALocalizedString(@"osmand_settings"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"left_menu_icon_settings",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        },
        @{
            @"name" : @"backup_restore",
            @"title" : OALocalizedString(@"osmand_cloud"),
            @"value" : @"", // TODO: insert value
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_cloud_upload_colored_day",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        },
        @{
            @"name" : @"purchases",
            @"title" : OALocalizedString(@"purchases"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_shop_bag",
            @"type" : [OAValueTableViewCell getCellIdentifier]
        }
    ]];
    
    [data addObject:@[
        @{
            @"name" : @"current_profile",
            @"app_mode" : appMode,
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"isColored" : @YES
        }
    ]];
    
    NSMutableArray *profilesSection = [NSMutableArray new];
    for (int i = 0; i < OAApplicationMode.allPossibleValues.count; i++)
    {
        [profilesSection addObject:@{
            @"name" : @"profile_val",
            @"app_mode" : OAApplicationMode.allPossibleValues[i],
            @"type" : i == 0 ? [OASimpleTableViewCell getCellIdentifier] : [OASwitchTableViewCell getCellIdentifier],
            @"isColored" : @NO
        }];
    }
    
    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"new_profile"),
        @"img" : @"ic_custom_add",
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"name" : @"add_profile"
    }];

    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"reorder_profiles"),
        @"img" : @"ic_custom_edit",
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"name" : @"edit_profiles"
    }];
    
    [data addObject:profilesSection];
    
    [data addObject:[self getLocalBackupSectionData]];
    
    _data = [NSArray arrayWithArray:data];
}

- (NSArray *)getLocalBackupSectionData
{
    return @[
        @{
            @"type": OATitleRightIconCell.getCellIdentifier,
            @"name": @"backupIntoFile",
            @"title": OALocalizedString(@"backup_into_file"),
            @"img": @"ic_custom_save_to_file",
            @"regular_text": @(YES)
        },
        @{
            @"type": OATitleRightIconCell.getCellIdentifier,
            @"name": @"restoreFromFile",
            @"title": OALocalizedString(@"restore_from_file"),
            @"img": @"ic_custom_read_from_file",
            @"regular_text": @(YES)
        }
    ];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"profile_type_custom_string") : OALocalizedString(@"profile_type_base_string");
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 1)
        return OALocalizedString(@"selected_profile");
    else if (section == 2)
        return OALocalizedString(@"application_profiles");
    else if (section == 3)
        return OALocalizedString(@"local_backup");

    return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"global_settings_descr");
    else if (section == 2)
        return OALocalizedString(@"import_profile_descr");
    else if (section == 3)
        return OALocalizedString(@"local_backup_descr");

    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.leftIconView.image = [item[@"name"] isEqualToString:@"backup_restore"] ? [UIImage rtlImageNamed:item[@"img"]] : [UIImage templateImageNamed:item[@"img"]];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            cell.titleLabel.numberOfLines = 3;
            cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            OAApplicationMode *am = item[@"app_mode"];
            UIImage *img = am.getIcon;
            cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.leftIconView.tintColor = UIColorFromRGB(am.getIconColor);
            cell.titleLabel.text = am.toHumanString;
            cell.descriptionLabel.text = [self getProfileDescription:am];
            cell.contentView.backgroundColor = UIColor.clearColor;
            if ([item[@"isColored"] boolValue])
                cell.backgroundColor = [UIColorFromRGB(am.getIconColor) colorWithAlphaComponent:0.1];
            else
                cell.backgroundColor = UIColor.whiteColor;
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        OAApplicationMode *am = item[@"app_mode"];
        BOOL isEnabled = [OAApplicationMode.values containsObject:am];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? kPaddingToLeftOfContentWithIcon : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
        cell.leftIconView.tintColor = isEnabled ? UIColorFromRGB(am.getIconColor) : UIColorFromRGB(color_tint_gray);
        cell.titleLabel.text = am.toHumanString;
        cell.descriptionLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        BOOL isDefault = am == OAApplicationMode.DEFAULT;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (!isDefault)
        {
            [cell.switchView setOn:isEnabled];
            [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        [cell switchVisibility:!isDefault];
        [cell dividerVisibility:!isDefault];
        return cell;
    }
    else if ([type isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if ([item[@"regular_text"] boolValue])
        {
            cell.titleView.textColor = UIColor.blackColor;
            cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        else
        {
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    [self selectSettingMain:item];
}

#pragma mark - Selectors

- (void)onBackupIntoFilePressed
{
    OAExportItemsViewController *exportController = [[OAExportItemsViewController alloc] init];
    [self.navigationController pushViewController:exportController animated:YES];
}

- (void)onRestoreFromFilePressed
{
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"net.osmand.osf"] inMode:UIDocumentPickerModeImport];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

- (void) selectSettingMain:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    if ([name isEqualToString:@"osmand_settings"])
    {
        OAGlobalSettingsViewController* globalSettingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAGlobalSettingsMain];
        [self.navigationController pushViewController:globalSettingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"backup_restore"])
    {
        UIViewController *vc;
        if (OABackupHelper.sharedInstance.isRegistered)
            vc = [[OACloudBackupViewController alloc] init];
        else
            vc = [[OACloudIntroductionViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([name isEqualToString:@"purchases"])
    {
        OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
        [self.navigationController pushViewController:purchasesViewController animated:YES];
    }
    else if ([name isEqualToString:@"profile_val"] || [name isEqualToString:@"current_profile"])
    {
        OAApplicationMode *mode = item[@"app_mode"];
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:mode
                                                                                                  targetScreenKey:nil];
        [self.navigationController pushViewController:profileConf animated:YES];
    }
    else if ([name isEqualToString:@"add_profile"])
    {
        OACreateProfileViewController* createProfileViewController = [[OACreateProfileViewController alloc] init];
        [self.navigationController pushViewController:createProfileViewController animated:YES];
    }
    else if ([name isEqualToString:@"edit_profiles"])
    {
        OARearrangeProfilesViewController* rearrangeProfilesViewController = [[OARearrangeProfilesViewController alloc] init];
        [self.navigationController pushViewController:rearrangeProfilesViewController animated:YES];
    }
    else if ([name isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([name isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    if (sender.tag < OAApplicationMode.allPossibleValues.count)
    {
        OAApplicationMode *am = OAApplicationMode.allPossibleValues[sender.tag];
        [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
    }
}

- (void)onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSString *path = urls[0].path;
    NSString *extension = [[path pathExtension] lowercaseString];
    if ([extension caseInsensitiveCompare:@"osf"] == NSOrderedSame)
        [OASettingsHelper.sharedInstance collectSettings:urls[0].path latestChanges:@"" version:1];
}

@end
