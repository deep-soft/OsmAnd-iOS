//
//  OAProfileGeneralSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 01.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileGeneralSettingsViewController.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAIconTitleValueCell.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAProfileGeneralSettingsParametersViewController.h"
#import "OACoordinatesFormatViewController.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"

@implementation OAProfileGeneralSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"general_settings_2");
}

#pragma mark - Table data

- (NSString *)getLocationPositionValue
{
    switch ([_settings.positionPlacementOnMap get:self.appMode]) {
        case EOAPositionPlacementAuto:
            return OALocalizedString(@"shared_string_automatic");
        case EOAPositionPlacementCenter:
            return OALocalizedString(@"position_on_map_center");
        case EOAPositionPlacementBottom:
            return OALocalizedString(@"position_on_map_bottom");
            
        default:
            return @"";
    }
}

- (NSString *)getLocationPositionIcon
{
    switch ([_settings.positionPlacementOnMap get:self.appMode]) {
        case EOAPositionPlacementAuto:
            return @"ic_custom_display_position_automatic";
        case EOAPositionPlacementCenter:
            return @"ic_custom_display_position_center";
        case EOAPositionPlacementBottom:
            return @"ic_custom_display_position_bottom";
            
        default:
            return @"";
    }
}

- (void)generateData
{
    NSString *rotateMapValue;
    NSString *rotateMapIcon;
    if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_BEARING)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_bearing_opt");
        rotateMapIcon = @"ic_custom_direction_movement";
    }
    else if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_COMPASS)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_compass_opt");
        rotateMapIcon = @"ic_custom_direction_compass";
    }
    else if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_MANUAL)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_manual_opt");
        rotateMapIcon = @"ic_custom_direction_manual_day";
    }
    else
    {
        rotateMapValue = OALocalizedString(@"rotate_map_north_opt");
        rotateMapIcon = @"ic_custom_direction_north";
    }
    
    NSString *positionMapValue = [self getLocationPositionValue];
    NSString *positionMapIcon = [self getLocationPositionIcon];
    
    NSNumber *allow3DValue = @([_settings.settingAllow3DView get:self.appMode]);
    
    NSString *drivingRegionValue;
    if ([_settings.drivingRegionAutomatic get:self.appMode])
        drivingRegionValue = OALocalizedString(@"shared_string_automatic");
    else
        drivingRegionValue = [OADrivingRegion getName:[_settings.drivingRegion get:self.appMode]];
    
    NSString* metricSystemValue;
    switch ([_settings.metricSystem get:self.appMode]) {
        case KILOMETERS_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_km_m");
            break;
        case MILES_AND_FEET:
            metricSystemValue = OALocalizedString(@"si_mi_feet");
            break;
        case MILES_AND_YARDS:
            metricSystemValue = OALocalizedString(@"si_mi_yard");
            break;
        case MILES_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_mi_meters");
            break;
        case NAUTICAL_MILES_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_nm_mt");
            break;
        case NAUTICAL_MILES_AND_FEET:
            metricSystemValue = OALocalizedString(@"si_nm_ft");
            break;
        default:
            metricSystemValue = OALocalizedString(@"si_km_m");
            break;
    }
    
    NSString* speedSystemValue;
    switch ([_settings.speedSystem get:self.appMode]) {
        case KILOMETERS_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_kmh");
            break;
        case MILES_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_mph");
            break;
        case METERS_PER_SECOND:
            speedSystemValue = OALocalizedString(@"si_m_s");
            break;
        case MINUTES_PER_MILE:
            speedSystemValue = OALocalizedString(@"si_min_m");
            break;
        case MINUTES_PER_KILOMETER:
            speedSystemValue = OALocalizedString(@"si_min_km");
            break;
        case NAUTICALMILES_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_nm_h");
            break;
        default:
            speedSystemValue = OALocalizedString(@"si_kmh");
            break;
    }
    
    NSString* geoFormatValue;
    switch ([_settings.settingGeoFormat get:self.appMode]) {
        case MAP_GEO_FORMAT_DEGREES:
            geoFormatValue = OALocalizedString(@"navigate_point_format_D");
            break;
        case MAP_GEO_FORMAT_MINUTES:
            geoFormatValue = OALocalizedString(@"navigate_point_format_DM");
            break;
        case MAP_GEO_FORMAT_SECONDS:
            geoFormatValue = OALocalizedString(@"navigate_point_format_DMS");
            break;
        case MAP_GEO_UTM_FORMAT:
            geoFormatValue = @"UTM";
            break;
        case MAP_GEO_OLC_FORMAT:
            geoFormatValue = @"OLC";
            break;
        case MAP_GEO_MGRS_FORMAT:
            geoFormatValue = @"MGRS";
            break;
        default:
            geoFormatValue = OALocalizedString(@"navigate_point_format_D");
            break;
    }
    
    NSString* angularUnitsValue = @"";
    switch ([_settings.angularUnits get:self.appMode])
    {
        case DEGREES360:
        {
            angularUnitsValue = OALocalizedString(@"sett_deg360");
            break;
        }
        case DEGREES:
        {
            angularUnitsValue = OALocalizedString(@"sett_deg180");
            break;
        }
        case MILLIRADS:
        {
            angularUnitsValue = OALocalizedString(@"shared_string_milliradians");
            break;
        }
        default:
            break;
    }
    
    NSString* externalInputDeviceValue;
    if ([_settings.settingExternalInputDevice get:self.appMode] == GENERIC_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_generic_ext_input");
    else if ([_settings.settingExternalInputDevice get:self.appMode] == WUNDERLINQ_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_wunderlinq_ext_input");
    else
        externalInputDeviceValue = OALocalizedString(@"shared_string_none");
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *appearanceArr = [NSMutableArray array];
    NSMutableArray *unitsAndFormatsArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
//    [appearanceArr addObject:@{
//        @"type" : [OAIconTitleValueCell getCellIdentifier],
//        @"title" : OALocalizedString(@"settings_app_theme"),
//        @"value" : OALocalizedString(@"light_theme"),
//        @"icon" : @"ic_custom_contrast",
//        @"key" : @"app_theme",
//    }];
    [appearanceArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"rotate_map_to"),
        @"value" : rotateMapValue,
        @"icon" : rotateMapIcon,
        @"key" : @"map_orientation",
    }];
    [appearanceArr addObject:@{
        @"name" : @"allow_3d",
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"allow_3D_view"),
        @"isOn" : allow3DValue,
        @"icon" : @"ic_custom_2_5d_view",
        @"key" : @"3dView",
    }];
    [appearanceArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"position_on_map"),
        @"value" : positionMapValue,
        @"icon" : positionMapIcon,
        @"key" : @"position_on_map",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"driving_region"),
        @"value" : drivingRegionValue,
        @"icon" : @"ic_profile_car",
        @"key" : @"drivingRegion",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"unit_of_length"),
        @"value" : metricSystemValue,
        @"icon" : @"ic_custom_ruler",
        @"key" : @"lengthUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"units_of_speed"),
        @"value" : speedSystemValue,
        @"icon" : @"ic_action_speed",
        @"key" : @"speedUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"coords_format"),
        @"value" : geoFormatValue,
        @"icon" : @"ic_custom_coordinates",
        @"key" : @"coordsFormat",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"title" : OALocalizedString(@"angular_measurment_units"),
        @"value" : angularUnitsValue,
        @"icon" : @"ic_custom_angular_unit",
        @"key" : @"angulerMeasurmentUnits",
    }];
    [otherArr addObject:@{
        @"type" : [OASettingsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"external_input_device"),
        @"value" : externalInputDeviceValue,
        @"key" : @"externalImputDevice",
    }];
    [tableData addObject:appearanceArr];
    [tableData addObject:unitsAndFormatsArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"shared_string_appearance");
    else if (section == 1)
        return OALocalizedString(@"units_and_formats");
    else
        return OALocalizedString(@"other_location");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}
- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftIconView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [item[@"isOn"] boolValue] ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);

            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont scaledSystemFontOfSize:17.0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
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
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"app_theme"])
        settingsViewController = [[OABaseSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"map_orientation"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsMapOrientation applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"position_on_map"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsDisplayPosition applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"drivingRegion"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsDrivingRegion applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"lengthUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsUnitsOfLenght applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"speedUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsUnitsOfSpeed applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"coordsFormat"])
        settingsViewController = [[OACoordinatesFormatViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"angulerMeasurmentUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsAngularMeasurmentUnits applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"externalImputDevice"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsExternalInputDevices applicationMode:self.appMode];
    if (settingsViewController != nil)
    {
        settingsViewController.delegate = self;
        [self showModalViewController:settingsViewController];
    }
}

#pragma mark - Selectors

- (void)onRotation
{
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *name = item[@"name"];
        if (name)
        {
            BOOL isChecked = sw.on;
            if ([name isEqualToString:@"allow_3d"])
            {
                [_settings.settingAllow3DView set:isChecked mode:self.appMode];
                if (!isChecked)
                {
                    OsmAndAppInstance app = OsmAndApp.instance;
                    if (app.mapMode == OAMapModeFollow)
                        [app setMapMode:OAMapModePositionTrack];
                    else
                        [app.mapModeObservable notifyEvent];
                }
            }
            [self generateData];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged;
{
    [self generateData];
    [self.tableView reloadData];
}

@end
