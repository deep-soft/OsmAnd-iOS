//
//  OAMapStyleSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *HORSE_ROUTES_ATTR = @"horseRoutes";
static NSString *PISTE_ROUTES_ATTR = @"pisteRoutes";
static NSString *ALPINE_HIKING_ATTR = @"alpineHiking";
static NSString *SHOW_MTB_ROUTES_ATTR = @"showMtbRoutes";
static NSString *SHOW_CYCLE_ROUTES_ATTR = @"showCycleRoutes";
static NSString *WHITE_WATER_SPORTS_ATTR = @"whiteWaterSports";
static NSString *HIKING_ROUTES_OSMC_ATTR = @"hikingRoutesOSMC";
static NSString *CYCLE_NODE_NETWORK_ROUTES_ATTR = @"showCycleNodeNetworkRoutes";
static NSString *TRAVEL_ROUTES = @"travel_routes";

static NSString *ROAD_STYLE_CATEGORY = @"roadStyle";
static NSString *DETAILS_CATEGORY = @"details";
static NSString *HIDE_CATEGORY = @"hide";
static NSString *TRANSPORT_CATEGORY = @"transport";
static NSString *ROUTES_CATEGORY = @"routes";

typedef NS_ENUM(NSInteger, OAMapStyleValueDataType)
{
    OABoolean,
    OAInteger,
    OAFloat,
    OAString,
    OAColor,
};

@interface OAMapStyleParameterValue : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;

@end

@interface OAMapStyleParameter : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSString *mapPresetName;
@property (nonatomic) NSString *category;
@property (nonatomic) OAMapStyleValueDataType dataType;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *storedValue;
@property (nonatomic) NSString *defaultValue;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValues;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValuesUnsorted;

- (NSString *) getValueTitle;

@end

@interface OAMapStyleSettings : NSObject

- (instancetype) initWithStyleName:(NSString *)mapStyleName mapPresetName:(NSString *)mapPresetName;

+ (OAMapStyleSettings *) sharedInstance;

- (void) loadParameters;
- (NSArray<OAMapStyleParameter *> *) getAllParameters;
- (OAMapStyleParameter *) getParameter:(NSString *)name;

- (NSArray<NSString *> *) getAllCategories;
- (NSString *) getCategoryTitle:(NSString *)categoryName;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category sorted:(BOOL)sorted;

- (BOOL) isCategoryEnabled:(NSString *)categoryName;
- (void) setCategoryEnabled:(BOOL)isVisible categoryName:(NSString *)categoryName;

- (void) saveParameters;
- (void) save:(OAMapStyleParameter *)parameter;
- (void) save:(OAMapStyleParameter *)parameter refreshMap:(BOOL)refreshMap;

- (void) resetMapStyleForAppMode:(NSString *)mapPresetName;

@end
