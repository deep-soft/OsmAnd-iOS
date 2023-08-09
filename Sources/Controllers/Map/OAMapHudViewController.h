//
//  OAMapHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAMapModeHeaders.h"
#import "OAHudButton.h"

@class OAFloatingButtonsHudViewController;
@class OAToolbarViewController;
@class OAMapRulerView;
@class OAMapInfoController;
@class OADownloadMapWidget;
@class OAWeatherToolbar;

@interface OAMapHudViewController : UIViewController

@property (nonatomic, readonly) EOAMapHudType mapHudType;
@property (nonatomic) OAFloatingButtonsHudViewController *floatingButtonsController;

@property (weak, nonatomic) IBOutlet UIView *statusBarView;
@property (weak, nonatomic) IBOutlet UIView *bottomBarView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusBarViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomBarViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet OAHudButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;

@property (weak, nonatomic) IBOutlet OAHudButton *weatherButton;

@property (weak, nonatomic) IBOutlet UIView *widgetsView;
@property (weak, nonatomic) IBOutlet UIView *topWidgetsView;
@property (weak, nonatomic) IBOutlet UIView *leftWidgetsView;
@property (weak, nonatomic) IBOutlet UIView *bottomWidgetsView;
@property (weak, nonatomic) IBOutlet UIView *rightWidgetsView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topWidgetsViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomWidgetsViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftWidgetsViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftWidgetsViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightWidgetsViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightWidgetsViewWidthConstraint;

@property (weak, nonatomic) IBOutlet OAHudButton *mapSettingsButton;
@property (weak, nonatomic) IBOutlet OAHudButton *searchButton;

@property (weak, nonatomic) IBOutlet OAHudButton *mapModeButton;
@property (weak, nonatomic) IBOutlet OAHudButton *zoomInButton;
@property (weak, nonatomic) IBOutlet OAHudButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIView *zoomButtonsView;

@property (weak, nonatomic) IBOutlet OAHudButton *driveModeButton;
@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextfield;
@property (weak, nonatomic) IBOutlet OAHudButton *optionsMenuButton;

@property (strong, nonatomic) IBOutlet OAMapRulerView *rulerLabel;

@property (nonatomic) OAToolbarViewController *toolbarViewController;
@property (nonatomic) OAMapInfoController *mapInfoController;
@property (nonatomic) OADownloadMapWidget *downloadMapWidget;
@property (nonatomic) OAWeatherToolbar *weatherToolbar;

@property (nonatomic, assign) BOOL contextMenuMode;
@property (nonatomic, assign) EOAMapModeButtonType mapModeButtonType;

@property (nonatomic, readonly) CGFloat toolbarTopPosition;

- (void) enterContextMenuMode;
- (void) restoreFromContextMenuMode;
- (void) updateRulerPosition:(CGFloat)bottom left:(CGFloat)left;
- (void) resetToDefaultRulerLayout;
- (void) updateMapRulerData;
- (void) updateMapRulerDataWithDelay;

- (void) updateDependentButtonsVisibility;
- (void) updateCompassButton;

- (BOOL) needsSettingsForWeatherToolbar;
- (void) changeWeatherToolbarVisible;
- (void) hideWeatherToolbarIfNeeded;
- (void) updateWeatherButtonVisibility;

- (void) setToolbar:(OAToolbarViewController *)toolbarController;
- (void) updateControlsLayout:(BOOL)animated;
- (void) removeToolbar;

- (void) setDownloadMapWidget:(OADownloadMapWidget *)widget;
- (void) setWeatherToolbarMapWidget:(OAWeatherToolbar *)widget;

- (BOOL) isOverlayUnderlayViewVisible;
- (void) updateOverlayUnderlayView;

- (void) updateTopControlsVisibility;
- (void) updateBottomControlsVisibility:(BOOL)animated;

- (CGFloat) getHudMinTopOffset;
- (CGFloat) getHudTopOffset;
- (CGFloat) getHudMinBottomOffset;
- (CGFloat) getHudBottomOffset;

- (void) onRoutingProgressChanged:(int)progress;
- (void) onRoutingProgressFinished;

- (void) updateRouteButton:(BOOL)routePlanningMode followingMode:(BOOL)followingMode;

- (void) recreateAllControls;
- (void) recreateControls;
- (void) updateInfo;

- (void) updateCurrentLocationAddress;

@end
