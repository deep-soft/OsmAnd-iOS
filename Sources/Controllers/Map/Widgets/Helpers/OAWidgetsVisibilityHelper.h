//
//  OAWidgetsVisibilityHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAWidgetsVisibilityHelper : NSObject

- (BOOL)shouldShowQuickActionButton;
- (BOOL)shouldShowMap3DButton;
- (BOOL)shouldShowFabButton;
- (BOOL)shouldShowTopMapCenterCoordinatesWidget;
- (BOOL)shouldShowTopCurrentLocationCoordinatesWidget;
- (BOOL)shouldHideMapMarkersWidget;
- (BOOL)shouldShowBottomMenuButtons;
- (BOOL)shouldShowZoomButtons;
- (BOOL)shouldHideCompass;
- (BOOL)shouldShowTopButtons;
- (BOOL)shouldShowBackToLocationButton;

@end

NS_ASSUME_NONNULL_END
