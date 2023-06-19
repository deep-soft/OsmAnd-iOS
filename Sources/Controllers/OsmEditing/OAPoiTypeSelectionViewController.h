//
//  OAPoiTypeSelectionViewController.h
//  OsmAnd
//
//  Created by Paul on 2/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAOsmEditingViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOASelectionType)
{
    CATEGORY_SCREEN = 0,
    POI_TYPE_SCREEN
};

@protocol OAPoiTypeSelectionDelegate <NSObject>

@required

- (void) onPoiTypeSelected:(NSString *)name;

@end

@interface OAPoiTypeSelectionViewController : OABaseNavbarViewController

@property (nonatomic) id<OAOsmEditingDataProtocol> dataProvider;

@property id<OAPoiTypeSelectionDelegate> delegate;

-(instancetype)initWithType:(EOASelectionType)type;

@end

NS_ASSUME_NONNULL_END
