//
//  OAWeatherFrequencySettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 11.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherFrequencySettingsViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAWeatherHelper.h"
#import "OAWorldRegion.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

#define kFrequencySemiDailyIndex 0
#define kFrequencyDailyIndex 1
#define kFrequencyWeeklyIndex 2

@interface OAWeatherFrequencySettingsViewController () <UIViewControllerTransitioningDelegate>

@end

@implementation OAWeatherFrequencySettingsViewController
{
    OAWorldRegion *_region;
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *_data;
    NSInteger _indexSelected;
}

#pragma mark - Initialization

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
    }
    return self;
}

- (void)commonInit
{
    EOAWeatherForecastUpdatesFrequency frequency = [OAWeatherHelper getPreferenceFrequency:[OAWeatherHelper checkAndGetRegionId:_region]];
    _indexSelected = frequency == EOAWeatherForecastUpdatesSemiDaily ? kFrequencySemiDailyIndex
            : frequency == EOAWeatherForecastUpdatesDaily ? kFrequencyDailyIndex
                    : kFrequencyWeeklyIndex;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_updates_frequency");
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"weather_generates_new_forecast_description");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *frequencyCells = [NSMutableArray array];
    NSMutableDictionary *frequencySection = [NSMutableDictionary dictionary];
    frequencySection[@"header"] = OALocalizedString(@"shared_string_updates_frequency");
    frequencySection[@"key"] = @"title_section";
    frequencySection[@"cells"] = frequencyCells;
    frequencySection[@"footer"] = [NSString stringWithFormat:@"%@: %@",
            OALocalizedString(@"shared_string_next_update"),
            [OAWeatherHelper getUpdatesDateFormat:[OAWeatherHelper checkAndGetRegionId:_region] next:YES]];
    [data addObject:frequencySection];

    NSMutableDictionary *semiDailyData = [NSMutableDictionary dictionary];
    semiDailyData[@"key"] = @"semi_daily_cell";
    semiDailyData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    semiDailyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesSemiDaily];
    [frequencyCells addObject:semiDailyData];

    NSMutableDictionary *dailyData = [NSMutableDictionary dictionary];
    dailyData[@"key"] = @"daily_cell";
    dailyData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    dailyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesDaily];
    [frequencyCells addObject:dailyData];

    NSMutableDictionary *weeklyData = [NSMutableDictionary dictionary];
    weeklyData[@"key"] = @"weekly_cell";
    weeklyData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    weeklyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesWeekly];
    [frequencyCells addObject:weeklyData];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _data[section][@"header"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _data[section][@"footer"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.accessoryType = indexPath.row == _indexSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
    _indexSelected = indexPath.row;
    [OAWeatherHelper setPreferenceFrequency:[OAWeatherHelper checkAndGetRegionId:_region]
                                      value:_indexSelected == kFrequencySemiDailyIndex ? EOAWeatherForecastUpdatesSemiDaily
                                              : _indexSelected == kFrequencyDailyIndex ? EOAWeatherForecastUpdatesDaily
                                                      : EOAWeatherForecastUpdatesWeekly];
    if (self.frequencyDelegate)
        [self.frequencyDelegate onFrequencySelected];

    [self dismissViewController];
}

@end
