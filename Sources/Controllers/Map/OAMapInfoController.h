//
//  OAMapInfoController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAWidgetListener;

@protocol OAMapInfoControllerProtocol
@required

- (void) leftWidgetsLayoutDidChange:(UIView *)leftWidgetsView animated:(BOOL)animated;

- (void) streetViewLayoutDidChange: (UIView *)streetNameView animate:(BOOL)animated;
@end

@class OAMapHudViewController, OATextInfoWidget, OAWidgetState, OAMapWidgetRegInfo, OARulerWidget;

@interface OAMapInfoController : NSObject <OAWidgetListener>

@property (nonatomic, weak) id<OAMapInfoControllerProtocol> delegate;
@property (nonatomic) BOOL weatherToolbarVisible;

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController;

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message description:(NSString *)description key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) registerSideWidget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder;
- (void) removeSideWidget:(OATextInfoWidget *)widget;

- (CGFloat) getLeftBottomY;

- (void) recreateAllControls;
- (void) recreateControls;
- (void) updateInfo;
- (void) updateWeatherToolbarVisible;
- (void) expandClicked:(id)sender;

- (void) updateRuler;

- (BOOL)topTextViewVisible;

@end
