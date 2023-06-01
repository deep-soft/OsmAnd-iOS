//
//  OAGPXAppearanceCollection.m
//  OsmAnd
//
//  Created by Paul on 1/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXAppearanceCollection.h"
#import "OARootViewController.h"
#import "OAEditPointViewController.h"
#import "Localization.h"
#import "OAMapStyleSettings.h"
#import "OAOsmAndFormatter.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define kItemWithColorId @"gpxFilePathWithColor"

@implementation OAGPXTrackAppearance

@end

@implementation OAGPXTrackWidth

- (instancetype)initWithKey:(NSString *)key value:(NSObject *)value
{
    self = [super init];
    if (self)
    {
        BOOL isCustom = !key || key.length == 0;
        self.key = key;
        self.title = OALocalizedString(!isCustom ? [NSString stringWithFormat:@"rendering_value_%@_name", key] : @"shared_string_custom");
        self.icon = !isCustom ? [NSString stringWithFormat:@"ic_custom_track_line_%@", key] : @"ic_custom_slider";
        self.customValue = !isCustom ? @"-1" : (NSString *) value;
        if ([value isKindOfClass:[NSArray class]])
        {
            NSArray *newValue = (NSArray *) value;
            if (newValue.count > 0 && ![newValue[0] isKindOfClass:[NSArray class]])
                value = @[newValue];
        }
        self.allValues = !isCustom ? (NSArray *) value : [NSArray array];
    }
    return self;
}

+ (instancetype)getDefault
{
    return [[OAGPXTrackWidth alloc] initWithKey:@""
                                          value:[NSString stringWithFormat:@"%li", [self.class getCustomTrackWidthMin]]];
}

- (BOOL)isCustom
{
    return !self.key || self.key.length == 0;
}

+ (NSInteger)getCustomTrackWidthMin
{
    return 1;
}

+ (NSInteger)getCustomTrackWidthMax
{
    return 24;
}

@end

@implementation OAGPXTrackSplitInterval

- (instancetype)initWithType:(EOAGpxSplitType)type
{
    self = [super init];
    if (self)
    {
        NSString *key = [OAGPXDatabase splitTypeNameByValue:type];
        self.key = key;
        self.title = OALocalizedString([NSString stringWithFormat:@"shared_string_%@", type == EOAGpxSplitTypeNone ? @"none" : key]);
        self.type = type;

        switch (type)
        {
            case EOAGpxSplitTypeTime:
            {
                [self generateTimeOptionSplit];
                break;
            }
            case EOAGpxSplitTypeDistance:
            {
                [self generateDistanceOptionSplit];
                break;
            }
            default:
            {
                self.titles = [NSArray array];
                self.values = [NSArray array];
                break;
            }
        }

        self.customValue = type != EOAGpxSplitTypeNone ? _titles.firstObject : @"0";
    }
    return self;
}

+ (instancetype)getDefault
{
    return [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeNone];
}

- (BOOL)isCustom
{
    return self.type != EOAGpxSplitTypeNone;
}

- (void)generateDistanceOptionSplit
{
    NSArray<NSNumber *> *customValues = @[
            @30, // 50 feet, 20 yards, 20 m
            @60, // 100 feet, 50 yards, 50 m
            @150, // 200 feet, 100 yards, 100 m
            @300, // 500 feet, 200 yards, 200 m
            @600, // 1000 feet, 500 yards, 500 m
            @1500, // 2000 feet, 1000 yards, 1 km
            @3000, // 1 mi, 2 km
            @6000, // 2 mi, 5 km
            @15000 // 5 mi, 10 k
            ];

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    for (NSNumber *customValue in customValues)
    {
        [titles addObject:[OAOsmAndFormatter getFormattedDistanceInterval:customValue.intValue]];
        [values addObject:@([OAOsmAndFormatter calculateRoundedDist:customValue.intValue])];
    }
    self.titles = titles;
    self.values = values;
}

- (void)generateTimeOptionSplit
{
    NSArray<NSNumber *> *customValues = @[
            @15,
            @30,
            @60,
            @120,
            @150,
            @300,
            @600,
            @900,
            @1800
            ];

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];

    for (NSNumber *customValue in customValues)
    {
        [titles addObject:[OAOsmAndFormatter getFormattedTimeInterval:customValue.intValue]];
        [values addObject:customValue];
    }
    self.titles = titles;
    self.values = values;
}

@end

@implementation OAGPXAppearanceCollection
{
    OAMapViewController *_mapViewController;
    OAAppSettings *_settings;

    NSMutableArray<OAColorItem *> *_availableColors;
    NSMutableDictionary<NSString *, NSNumber *> *_defaultColorValues;
    OAColorItem *_defaultPointColorItem;
    OAColorItem *_defaultLineColorItem;

    NSArray<OAGPXTrackWidth *> *_availableWidth;
    NSArray<OAGPXTrackSplitInterval *> *_availableSplitInterval;

    NSArray<OAFavoriteGroup *> *_cachedFavoriteGroups;
}

+ (OAGPXAppearanceCollection *)sharedInstance
{
    static OAGPXAppearanceCollection *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAGPXAppearanceCollection alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _settings = [OAAppSettings sharedManager];
    [self generateAvailableColors];
}

- (void)generateAvailableColors
{
    _availableColors = [NSMutableArray array];
    if (!_mapViewController)
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    if (!_mapViewController)
        return;

    NSMutableArray<NSString *> *possibleTrackColorKeys = [NSMutableArray array];
    OAMapStyleParameter *currentTrackColor = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_COLOR_ATTR];
    if (currentTrackColor)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackColorParameters = currentTrackColor.possibleValuesUnsorted;
        [currentTrackColorParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackColorKeys addObject:parameter.name];
        }];

        _defaultColorValues = [NSMutableDictionary dictionaryWithDictionary:[_mapViewController getGpxColors]];
        [_defaultColorValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL *_Nonnull stop) {
            if (![possibleTrackColorKeys containsObject:key])
            {
                [_defaultColorValues removeObjectForKey:key];
            }
            else
            {
                OAColorItem *colorItem = [[OAColorItem alloc] initWithKey:key value:obj.integerValue isDefault:YES];
                [_availableColors addObject:colorItem];
                colorItem.sortedPosition = [_availableColors indexOfObject:colorItem];
                [colorItem generateId];
                if ([colorItem.key isEqualToString:@"red"])
                    _defaultLineColorItem = colorItem;
            }
        }];
        [_availableColors sortUsingComparator:^NSComparisonResult(OAColorItem *obj1, OAColorItem *obj2) {
            return [@([possibleTrackColorKeys indexOfObject:obj1.key]) compare:@([possibleTrackColorKeys indexOfObject:obj2.key])];
        }];
    }

    if (!_defaultLineColorItem)
        [self getDefaultLineColorItem];
    [self getDefaultPointColorItem];
    NSMutableArray<NSString *> *defaultHexColors = [NSMutableArray array];
    for (OAColorItem *defaultColorItem in _availableColors)
    {
        [defaultHexColors addObject:[defaultColorItem getHexColor]];
    }
    [self saveColorsToEndOfLastUsedIfNeeded:defaultHexColors];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors enumerateObjectsUsingBlock:^(NSString *hexColor, NSUInteger ids, BOOL *stop) {
        if (hexColor.length == 0)
            [customTrackColors removeObject:hexColor];
    }];
    [_settings.customTrackColors set:customTrackColors];

    [self saveColorsToEndOfLastUsedIfNeeded:customTrackColors];
    for (NSString *hexColor in customTrackColors)
    {
        OAColorItem *colorItem = [[OAColorItem alloc] initWithHexColor:hexColor];
        [_availableColors addObject:colorItem];
        colorItem.sortedPosition = [_availableColors indexOfObject:colorItem];
        [colorItem generateId];
    }
    BOOL isRegenerated = NO;
    if (_cachedFavoriteGroups)
    {
        isRegenerated = [self saveFavoriteColorsIfNeeded:_cachedFavoriteGroups];
        _cachedFavoriteGroups = nil;
    }
    if (!isRegenerated)
        [self regenerateSortedPosition];
}

- (void)regenerateSortedPosition
{
    NSArray<NSString *> *customTrackColorsLastUsed = [_settings.customTrackColorsLastUsed get];
    NSMutableDictionary<NSNumber *, NSString *> *sortedPositionWithHexColors = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < customTrackColorsLastUsed.count; i++)
    {
        sortedPositionWithHexColors[@(i)] = customTrackColorsLastUsed[i];
    }

    NSMutableArray<NSNumber *> *sortedColorItems = [NSMutableArray array];
    NSDictionary<NSString *, NSNumber *> *itemWithColorId = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kItemWithColorId];
    if (itemWithColorId)
    {
        NSMutableArray<NSNumber *> *ids = [NSMutableArray arrayWithArray:itemWithColorId.allValues];
        for (NSInteger i = 0; i < _availableColors.count; i++)
        {
            OAColorItem *colorItem = _availableColors[i];
            if ([ids containsObject:@(colorItem.id)])
            {
                [ids removeObject:@(colorItem.id)];
                NSInteger indexOfColorId = [itemWithColorId.allValues indexOfObject:@(colorItem.id)];
                NSString *hexColor = [colorItem getHexColor];
                NSInteger sortedPosition = sortedPositionWithHexColors.allKeys[[sortedPositionWithHexColors.allValues indexOfObject:hexColor]].integerValue;
                colorItem.sortedPosition = sortedPosition;
                [colorItem generateId];
                [sortedPositionWithHexColors removeObjectForKey:@(sortedPosition)];
                [sortedColorItems addObject:@(i)];
                [self setColorId:colorItem.id toItem:[itemWithColorId.allKeys objectAtIndex:indexOfColorId]];
            }
        }
    }

    [_availableColors enumerateObjectsUsingBlock:^(OAColorItem * _Nonnull colorItem, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![sortedColorItems containsObject:@(idx)])
        {
            NSString *hexColor = [colorItem getHexColor];
            NSInteger sortedHexColorIndex = [sortedPositionWithHexColors.allValues indexOfObject:hexColor];
            if (sortedHexColorIndex != NSNotFound)
            {
                NSInteger sortedPosition = sortedPositionWithHexColors.allKeys[sortedHexColorIndex].integerValue;
                colorItem.sortedPosition = sortedPosition;
                [colorItem generateId];
                [sortedPositionWithHexColors removeObjectForKey:@(sortedPosition)];
            }
            else
            {
                [_availableColors removeObject:colorItem];
            }
        }
    }];
}

- (void)saveColorsToEndOfLastUsedIfNeeded:(NSArray<NSString *> *)customColors
{
    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    for (NSString *hexColor in customColors)
    {
        NSInteger availableCount = [self getMaxCountOfDuplicates:hexColor];
        NSInteger lastUsedCount = [self getMaxCountOfDuplicatesInLastUsed:hexColor];
        if (lastUsedCount < availableCount
            || (lastUsedCount == 0 && availableCount == 0 && ([hexColor isEqualToString:[[self getDefaultLineColorItem] getHexColor]]
                                                              || [hexColor isEqualToString:[[self getDefaultPointColorItem] getHexColor]])))
            [customTrackColorsLastUsed addObject:hexColor];
    }
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
}

- (BOOL)saveFavoriteColorsIfNeeded:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    BOOL isRegenerated = NO;

    if (!_mapViewController)
        _cachedFavoriteGroups = favoriteGroups;

    if (_mapViewController && favoriteGroups && favoriteGroups.count > 0)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
        NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
        NSMutableDictionary<NSString *, NSNumber *> *itemWithColorId = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:kItemWithColorId]];
        for (OAFavoriteGroup *favoriteGroup in favoriteGroups)
        {
            NSString *groupName = favoriteGroup.name;
            if (!groupName || groupName.length == 0)
                groupName = @"default";
            if ([self saveValueIfNeeded:customTrackColorsLastUsed
                      customTrackColors:customTrackColors
                        itemWithColorId:itemWithColorId
                                   item:[NSString stringWithFormat:@"%@_%@", kFavoritePrefixColorId, groupName]
                               hexColor:[favoriteGroup.color toHexARGBString]])
                isRegenerated = YES;

            for (OAFavoriteItem *favoriteItem in favoriteGroup.points)
            {
                if ([self saveValueIfNeeded:customTrackColorsLastUsed
                          customTrackColors:customTrackColors
                            itemWithColorId:itemWithColorId
                                       item:[NSString stringWithFormat:@"%@_%@_%@", kFavoritePrefixColorId, groupName, [favoriteItem getName]]
                                   hexColor:[[favoriteItem getColor] toHexARGBString]])
                    isRegenerated = YES;
            }
        }
        if (isRegenerated)
        {
            [_settings.customTrackColors set:customTrackColors];
            [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
            [defaults setObject:itemWithColorId forKey:kItemWithColorId];
        }
    }

    if (isRegenerated)
        [self regenerateSortedPosition];

    return isRegenerated;
}

- (BOOL)saveValueIfNeeded:(NSMutableArray<NSString *> *)customTrackColorsLastUsed
        customTrackColors:(NSMutableArray<NSString *> *)customTrackColors
          itemWithColorId:(NSMutableDictionary<NSString *, NSNumber *> *)itemWithColorId
                     item:(NSString *)item
                 hexColor:(NSString *)hexColor
{
    if (![itemWithColorId.allKeys containsObject:item])
    {
        BOOL hasColor = NO;
        NSInteger colorId = -1;
        NSInteger colorValue = [OAUtilities colorToNumberFromString:hexColor];
        for (OAColorItem *colorItem in _availableColors)
        {
            if (colorItem.value == colorValue)
            {
                hasColor = YES;
                colorId = colorItem.id;
                break;
            }
        }

        if (!hasColor)
        {
            OAColorItem *newColorItem = [[OAColorItem alloc] initWithHexColor:hexColor];
            [_availableColors addObject:newColorItem];
            newColorItem.sortedPosition = [_availableColors indexOfObject:newColorItem];
            [newColorItem generateId];
            colorId = newColorItem.id;
        }

        itemWithColorId[item] = @(colorId);
        if (![customTrackColors containsObject:hexColor])
            [customTrackColors addObject:hexColor];
        if (![customTrackColorsLastUsed containsObject:hexColor])
            [customTrackColorsLastUsed addObject:hexColor];

        return YES;
    }
    return NO;
}

- (OAColorItem *)getDefaultLineColorItem
{
    if (!_defaultLineColorItem || ![_availableColors containsObject:_defaultLineColorItem])
    {
        _defaultLineColorItem = [[OAColorItem alloc] initWithKey:@"red" value:0xFFFF0000 isDefault:YES];
        [_availableColors addObject:_defaultLineColorItem];
        _defaultLineColorItem.sortedPosition = [_availableColors indexOfObject:_defaultLineColorItem];
        [_defaultLineColorItem generateId];
    }
    return _defaultLineColorItem;
}

- (OAColorItem *)getDefaultPointColorItem
{
    if (!_defaultPointColorItem || ![_availableColors containsObject:_defaultPointColorItem])
    {
        _defaultPointColorItem = [[OAColorItem alloc] initWithKey:@"purple" value:0xFF3F51B5 isDefault:YES];
        [_availableColors addObject:_defaultPointColorItem];
        _defaultPointColorItem.sortedPosition = [_availableColors indexOfObject:_defaultPointColorItem];
        [_defaultPointColorItem generateId];
    }
    return _defaultPointColorItem;
}

- (NSInteger)getMaxCountOfDuplicates:(NSString *)hexColor
{
    NSInteger count = 0;
    for (NSString *hx in [_settings.customTrackColors get])
    {
        if ([hexColor isEqualToString:hx])
            count++;
    }
    for (NSNumber *colorValue in _defaultColorValues.allValues)
    {
        if ([hexColor isEqualToString:[UIColorFromARGB(colorValue.integerValue) toHexARGBString]])
            count++;
    }
    return count;
}

- (NSInteger)getMaxCountOfDuplicatesInLastUsed:(NSString *)hexColor
{
    NSInteger count = 0;
    for (NSString *hx in [_settings.customTrackColorsLastUsed get])
    {
        if ([hexColor isEqualToString:hx])
            count++;
    }
    return count;
}

- (void)changeColor:(OAColorItem *)colorItem newColor:(UIColor *)newColor
{
    NSString *newHexColor = [newColor toHexARGBString];
    [colorItem setValueWithNewValue:[OAUtilities colorToNumberFromString:newHexColor]];
    [colorItem generateId];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    customTrackColors[[_availableColors indexOfObject:colorItem] - _defaultColorValues.count] = newHexColor;
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    customTrackColorsLastUsed[colorItem.sortedPosition] = newHexColor;
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
}

- (void)addNewSelectedColor:(UIColor *)newColor
{
    NSString *newHexColor = [newColor toHexARGBString];
    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors addObject:newHexColor];
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed insertObject:newHexColor atIndex:0];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    OAColorItem *colorItem = [[OAColorItem alloc] initWithHexColor:newHexColor];
    [_availableColors addObject:colorItem];
    colorItem.sortedPosition = [_availableColors indexOfObject:colorItem];
    [colorItem generateId];
    [self regenerateSortedPosition];
}

- (void)duplicateColor:(OAColorItem *)colorItem
{
    NSString *hexColor = [colorItem getHexColor];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    if (colorItem.isDefault)
        [customTrackColors addObject:hexColor];
    else
        [customTrackColors insertObject:hexColor atIndex:[_availableColors indexOfObject:colorItem] - _defaultColorValues.count + 1];
    [_settings.customTrackColors set:customTrackColors];

    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed insertObject:hexColor atIndex:colorItem.sortedPosition + 1];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    OAColorItem *duplicatedColorItem = [[OAColorItem alloc] initWithHexColor:hexColor];
    if (colorItem.isDefault)
        [_availableColors addObject:duplicatedColorItem];
    else
        [_availableColors insertObject:duplicatedColorItem atIndex:[_availableColors indexOfObject:colorItem] + 1];
    [self regenerateSortedPosition];
}

- (void)deleteColor:(OAColorItem *)colorItem
{
    NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
    [customTrackColorsLastUsed removeObjectAtIndex:colorItem.sortedPosition];
    [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];

    NSMutableArray<NSString *> *customTrackColors = [NSMutableArray arrayWithArray:[_settings.customTrackColors get]];
    [customTrackColors removeObjectAtIndex:[_availableColors indexOfObject:colorItem] - _defaultColorValues.count];
    [_settings.customTrackColors set:customTrackColors];

    [_availableColors removeObject:colorItem];
    [self regenerateSortedPosition];
}

- (void)selectColor:(OAColorItem *)colorItem toItem:(NSString *)item
{
    if (colorItem)
    {
        NSString *hexColor = [colorItem getHexColor];
        NSMutableArray<NSString *> *customTrackColorsLastUsed = [NSMutableArray arrayWithArray:[_settings.customTrackColorsLastUsed get]];
        [customTrackColorsLastUsed removeObjectAtIndex:colorItem.sortedPosition];
        [customTrackColorsLastUsed insertObject:hexColor atIndex:0];
        [_settings.customTrackColorsLastUsed set:customTrackColorsLastUsed];
        [self setColorId:colorItem.id toItem:item];
        [self regenerateSortedPosition];
    }
}

- (void)selectColor:(OAColorItem *)colorItem toFavoriteGroupName:(NSString *)groupName pointName:(NSString *)pointName
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    NSString *item = [NSString stringWithFormat:@"%@_%@%@", kFavoritePrefixColorId, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    [self selectColor:colorItem toItem:item];
}

- (void)selectColor:(OAColorItem *)colorItem toGpxFilePath:(NSString *)gpxFilePath groupName:(NSString *)groupName pointName:(NSString *)pointName
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    gpxFilePath = gpxFilePath ? [gpxFilePath stringByReplacingOccurrencesOfString:[OsmAndApp instance].gpxPath withString:@""] : @"current";
    NSString *item = [NSString stringWithFormat:@"%@_%@_%@%@", kWaypointPrefixColorId, gpxFilePath, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    [self selectColor:colorItem toItem:item];
}

- (NSArray<OAColorItem *> *)getAvailableColorsSortingByKey
{
    return _availableColors;
}

- (NSArray<OAColorItem *> *)getAvailableColorsSortingByLastUsed
{
    return [_availableColors sortedArrayUsingComparator:^NSComparisonResult(OAColorItem *obj1, OAColorItem *obj2) {
        return [@(obj1.sortedPosition) compare:@(obj2.sortedPosition)];
    }];
}

- (void)setColorId:(NSInteger)colorId toItem:(NSString *)item
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kItemWithColorId])
    {
        [defaults setObject:@{ item: @(colorId) } forKey:kItemWithColorId];
    }
    else
    {
        NSMutableDictionary<NSString *, NSNumber *> *itemWithColorId = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:kItemWithColorId]];
        itemWithColorId[item] = @(colorId);
        [defaults setObject:itemWithColorId forKey:kItemWithColorId];
    }
}

- (NSInteger)getColorId:(NSString *)item
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, NSNumber *> *itemWithColorId = [defaults dictionaryForKey:kItemWithColorId];
    if (!itemWithColorId)
        return -1;
    else
        return itemWithColorId[item].integerValue;
}

- (void)removeItem:(NSString *)item
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kItemWithColorId])
    {
        NSMutableDictionary<NSString *, NSNumber *> *itemWithColorId = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:kItemWithColorId]];
        [itemWithColorId removeObjectForKey:item];
        [defaults setObject:itemWithColorId forKey:kItemWithColorId];
    }
}

- (void)removeFavoriteGroupName:(NSString *)groupName pointName:(NSString *)pointName
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    NSString *item = [NSString stringWithFormat:@"%@_%@%@", kFavoritePrefixColorId, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    [self removeItem:item];
}

- (void)removeGpxFilePath:(NSString *)gpxFilePath groupName:(NSString *)groupName pointName:(NSString *)pointName
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    gpxFilePath = gpxFilePath ? [gpxFilePath stringByReplacingOccurrencesOfString:[OsmAndApp instance].gpxPath withString:@""] : @"current";
    NSString *item = [NSString stringWithFormat:@"%@_%@_%@%@", kWaypointPrefixColorId, gpxFilePath, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    [self removeItem:item];
}

- (OAColorItem *)getColorForItem:(NSString *)item defaultValue:(NSInteger)defaultValue
{
    NSInteger colorId = [self getColorId:item];
    if (colorId != -1)
    {
        for (OAColorItem *colorItem in _availableColors)
        {
            if (colorItem.id == colorId && colorItem.value == defaultValue)
                return colorItem;
        }
    }
    for (OAColorItem *colorItem in _availableColors)
    {
        if (defaultValue == 0 && [colorItem.key isEqualToString:@"red"])
            return colorItem;
        else if (colorItem.value == defaultValue)
            return colorItem;
    }

    [self addNewSelectedColor:UIColorFromARGB(defaultValue)];
    return _availableColors.lastObject;
}

- (OAColorItem *)getColorForFavoriteGroupName:(NSString *)groupName pointName:(NSString *)pointName defaultValue:(NSInteger)defaultValue
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    NSString *item = [NSString stringWithFormat:@"%@_%@%@", kFavoritePrefixColorId, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    return [self getColorForItem:item defaultValue:defaultValue];
}

- (OAColorItem *)getColorForGpxFilePath:(NSString *)gpxFilePath groupName:(NSString *)groupName pointName:(NSString *)pointName defaultValue:(NSInteger)defaultValue
{
    if (!groupName || groupName.length == 0)
        groupName = @"default";
    gpxFilePath = gpxFilePath ? [gpxFilePath stringByReplacingOccurrencesOfString:[OsmAndApp instance].gpxPath withString:@""] : @"current";
    NSString *item = [NSString stringWithFormat:@"%@_%@_%@%@", kWaypointPrefixColorId, gpxFilePath, groupName, pointName ? [@"_" stringByAppendingString:pointName] : @""];
    return [self getColorForItem:item defaultValue:defaultValue];
}

- (NSArray<OAGPXTrackWidth *> *)getAvailableWidth
{
    if (_availableWidth && [_availableWidth count] > 0)
        return _availableWidth;

    NSMutableArray<NSString *> *possibleTrackWidthKeys = [NSMutableArray new];
    OAMapStyleParameter *currentTrackWidth = [[OAMapStyleSettings sharedInstance] getParameter:CURRENT_TRACK_WIDTH_ATTR];

    if (currentTrackWidth)
    {
        NSArray<OAMapStyleParameterValue *> *currentTrackWidthParameters = currentTrackWidth.possibleValuesUnsorted;
        [currentTrackWidthParameters enumerateObjectsUsingBlock:^(OAMapStyleParameterValue *parameter, NSUInteger ids, BOOL *stop) {
            if (ids != 0)
                [possibleTrackWidthKeys addObject:parameter.name];
        }];

        NSMutableArray<OAGPXTrackWidth *> *result = [NSMutableArray new];
        NSDictionary<NSString *, NSArray<NSNumber *> *> *possibleValues = [_mapViewController getGpxWidth];
        [possibleValues enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSArray<NSNumber *> *_Nonnull obj, BOOL *_Nonnull stop) {
            NSString *originalKey = [key substringToIndex:[key indexOf:@"_"]];
            if ([possibleTrackWidthKeys containsObject:originalKey]) {
                OAGPXTrackWidth *existWidth = _availableWidth ? [self getWidthForValue:originalKey] : nil;
                if (existWidth) {
                    NSMutableArray *existValues = [existWidth.allValues mutableCopy];
                    [existValues addObject:obj];
                    existWidth.allValues = existValues;
                } else {
                    [result addObject:[[OAGPXTrackWidth alloc] initWithKey:originalKey value:obj]];
                    _availableWidth = result;
                }
            }
        }];

        [result addObject:[OAGPXTrackWidth getDefault]];

        _availableWidth = [result sortedArrayUsingComparator:^NSComparisonResult(OAGPXTrackWidth *obj1, OAGPXTrackWidth *obj2) {
            return [@([possibleTrackWidthKeys indexOfObject:obj1.key]) compare:@([possibleTrackWidthKeys indexOfObject:obj2.key])];
        }];
    }
    else
    {
        _availableWidth = [NSArray array];
    }

    return _availableWidth;
}

- (OAGPXTrackWidth *)getWidthForValue:(NSString *)value
{
    if (!_availableWidth || [_availableWidth count] == 0)
        [self getAvailableWidth];

    for (OAGPXTrackWidth *width in _availableWidth)
    {
        if (value.intValue > 0 && [width isCustom])
        {
            width.customValue = value;
            return width;
        }
        else if ([width.key isEqualToString:value])
        {
            return width;
        }
    }

    return nil;
}

- (NSArray<OAGPXTrackSplitInterval *> *)getAvailableSplitIntervals
{
    if (_availableSplitInterval && [_availableSplitInterval count] > 0)
        return _availableSplitInterval;

    _availableSplitInterval = @[
            [OAGPXTrackSplitInterval getDefault],
            [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeTime],
            [[OAGPXTrackSplitInterval alloc] initWithType:EOAGpxSplitTypeDistance]
    ];

    return _availableSplitInterval;
}

- (OAGPXTrackSplitInterval *)getSplitIntervalForType:(EOAGpxSplitType)type
{
    if (!_availableSplitInterval || [_availableSplitInterval count] == 0)
        [self getAvailableSplitIntervals];

    for (OAGPXTrackSplitInterval *splitInterval in _availableSplitInterval)
    {
        if (splitInterval.type == type)
            return splitInterval;
    }

    return [OAGPXTrackSplitInterval getDefault];
}

@end
