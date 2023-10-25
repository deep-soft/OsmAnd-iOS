//
//  OAFavoritesHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define kPersonalCategory @"personal"

@class OAFavoriteItem, OAFavoriteGroup, OASpecialPointType, OAGPXDocument, OAGPXMutableDocument, OAPointsGroup;

@interface OAFavoritesHelper : NSObject

+ (BOOL) isFavoritesLoaded;
+ (void) loadFavorites;
+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites;

+ (void)loadFileGroups:(NSString *)file
                groups:(NSMutableDictionary<NSString *, OAFavoriteGroup *> *)groups;
+ (OAGPXDocument *)loadGpxFile:(NSString *)file;
+ (void)importFavoritesFromGpx:(OAGPXDocument *)gpxFile;

+ (OAFavoriteItem *) getSpecialPoint:(OASpecialPointType *)specialType;
+ (void) setSpecialPoint:(OASpecialPointType *)specialType lat:(double)lat lon:(double)lon address:(NSString *)address;
+ (void) setParkingPoint:(double)lat lon:(double)lon address:(NSString *)address pickupDate:(NSDate *)pickupDate addToCalendar:(BOOL)addToCalendar;

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems;
+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems;
+ (OAFavoriteItem *) getVisibleFavByLat:(double)lat lon:(double)lon;
+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites;
+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *) getGroups;
+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId;
+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem;


+ (BOOL)addFavorite:(OAFavoriteItem *)point;
+ (BOOL)addFavorite:(OAFavoriteItem *)point
      lookupAddress:(BOOL)lookupAddress
        sortAndSave:(BOOL)sortAndSave
        pointsGroup:(OAPointsGroup *)pointsGroup;

+ (BOOL) editFavoriteName:(OAFavoriteItem *)item newName:(NSString *)newName group:(NSString *)group descr:(NSString *)descr address:(NSString *)address;
+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon;
+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon description:(NSString *)description;
+ (void) saveCurrentPointsIntoFile;

+ (void)updateGroup:(OAFavoriteGroup *)group
            newName:(NSString *)newName
    saveImmediately:(BOOL)saveImmediately;

+ (void)updateGroup:(OAFavoriteGroup *)group
           iconName:(NSString *)iconName
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately;

+ (void)updateGroup:(OAFavoriteGroup *)group
              color:(UIColor *)color
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately;

+ (void)updateGroup:(OAFavoriteGroup *)group
 backgroundIconName:(NSString *)backgroundIconName
       updatePoints:(BOOL)updatePoints
    saveImmediately:(BOOL)saveImmediately;

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups;

+ (void) addFavoriteGroup:(NSString *)name
                    color:(UIColor *)color
                 iconName:(NSString *)iconName
       backgroundIconName:(NSString *)backgroundIconName;

- (BOOL)deleteFavorite:(OAFavoriteItem *)p saveImmediately:(BOOL)saveImmediately;

+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item;
+ (OAFavoriteGroup *)getOrCreateGroup:(OAFavoriteItem *)item
                          pointsGroup:(OAPointsGroup *)pointsGroup;
+ (BOOL) deleteNewFavoriteItem:(OAFavoriteItem *)favoritesItem;
+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems;
+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems isNewFavorite:(BOOL)isNewFavorite;

+ (NSDictionary<NSString *, NSString *> *) checkDuplicates:(OAFavoriteItem *)point;
+ (void) sortAll;
+ (void) recalculateCachedFavPoints;

+ (NSArray<NSString *> *) getFlatBackgroundIconNamesList;
+ (NSArray<NSString *> *) getFlatBackgroundContourIconNamesList;

+ (OAGPXMutableDocument *) asGpxFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups;

+ (void) addParkingReminderToCalendar;
+ (void) removeParkingReminderFromCalendar;

+ (UIImage *) getCompositeIcon:(NSString *)icon backgroundIcon:(NSString *)backgroundIcon color:(UIColor *)color;

+ (void) saveFile:(NSArray<OAFavoriteGroup *> *)favoriteGroups file:(NSString *)file;
+ (void) backup;
+ (NSArray<NSString *> *) getGroupFiles;

@end

@interface OAFavoriteGroup : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) UIColor* color;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *backgroundType;
@property (nonatomic) NSMutableArray<OAFavoriteItem*> *points;

- (instancetype)initWithPoint:(OAFavoriteItem *)point;
- (instancetype) initWithName:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (void) addPoint:(OAFavoriteItem *)point;

- (BOOL) isPersonal;
+ (BOOL) isPersonal:(NSString *)name;

+ (BOOL) isPersonalCategoryDisplayName:(NSString *)name;
+ (NSString *) getDisplayName:(NSString *)name;
+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name;
- (OAPointsGroup *)toPointsGroup;
+ (OAFavoriteGroup *)fromPointsGroup:(OAPointsGroup *)pointsGroup;

@end
