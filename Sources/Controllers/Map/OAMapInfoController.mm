//
//  OAMapInfoController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OARoutingHelper.h"
#import "Localization.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OADayNightHelper.h"
#import "OASizes.h"
#import "OATextInfoWidget.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OARouteInfoWidgetsFactory.h"
#import "OAMapInfoWidgetsFactory.h"
#import "OANextTurnWidget.h"
#import "OACoordinatesWidget.h"
#import "OALanesControl.h"
#import "OATopTextView.h"
#import "OAAlarmWidget.h"
#import "OARulerWidget.h"
#import "OATimeWidgetState.h"
#import "OABearingWidgetState.h"
#import "OACompassRulerWidgetState.h"
#import "OAUserInteractionPassThroughView.h"
#import "OAToolbarViewController.h"
#import "OADownloadMapWidget.h"
#import "OAWeatherToolbar.h"
#import "OAWeatherPlugin.h"
#import "OACompassModeWidgetState.h"
#import "OAFloatingButtonsHudViewController.h"
#import "OAMapLayers.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OASunriseSunsetWidget.h"
#import "OASunriseSunsetWidgetState.h"
#import "OAAltitudeWidget.h"

#import "OsmAnd_Maps-Swift.h"

@implementation OATextState
@end

@interface OAMapInfoController () <OAWeatherLayerSettingsDelegate, OAWidgetPanelDelegate>

@end

@implementation OAMapInfoController
{
    OAMapHudViewController __weak *_mapHudViewController;
    UIView __weak *_widgetsView;

    OAMapWidgetRegistry *_mapWidgetRegistry;
    BOOL _expanded;
    BOOL _isBordersOfDownloadedMaps;
    OADownloadMapWidget *_downloadMapWidget;
    OAWeatherToolbar *_weatherToolbar;
    OAAlarmWidget *_alarmControl;
    OARulerWidget *_rulerControl;

    OAAppSettings *_settings;
    OADayNightHelper *_dayNightHelper;
    OAAutoObserverProxy* _framePreparedObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapSourceUpdatedObserver;

    NSTimeInterval _lastUpdateTime;
    int _themeId;

    NSArray<OABaseWidgetView *> *_widgetsToUpdate;
    NSTimer *_framePreparedTimer;
}

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _dayNightHelper = [OADayNightHelper instance];

        _mapHudViewController = mapHudViewController;
        _topPanelController = [[OAWidgetPanelViewController alloc] initWithHorizontal:YES];
        _topPanelController.delegate = self;
        _leftPanelController = [[OAWidgetPanelViewController alloc] init];
        _leftPanelController.delegate = self;
        _bottomPanelController = [[OAWidgetPanelViewController alloc] initWithHorizontal:YES];
        _bottomPanelController.delegate = self;
        _rightPanelController = [[OAWidgetPanelViewController alloc] init];
        _rightPanelController.delegate = self;

        [mapHudViewController addChildViewController:_topPanelController];
        [mapHudViewController addChildViewController:_leftPanelController];
        [mapHudViewController addChildViewController:_bottomPanelController];
        [mapHudViewController addChildViewController:_rightPanelController];

        [mapHudViewController.topWidgetsView addSubview:_topPanelController.view];
        [mapHudViewController.leftWidgetsView addSubview:_leftPanelController.view];
        [mapHudViewController.bottomWidgetsView addSubview:_bottomPanelController.view];
        [mapHudViewController.rightWidgetsView addSubview:_rightPanelController.view];

        _topPanelController.view.translatesAutoresizingMaskIntoConstraints = NO;
        _leftPanelController.view.translatesAutoresizingMaskIntoConstraints = NO;
        _bottomPanelController.view.translatesAutoresizingMaskIntoConstraints = NO;
        _rightPanelController.view.translatesAutoresizingMaskIntoConstraints = NO;

        [NSLayoutConstraint activateConstraints:@[

            [_topPanelController.view.topAnchor constraintEqualToAnchor:mapHudViewController.topWidgetsView.topAnchor constant:0.],
            [_topPanelController.view.leftAnchor constraintEqualToAnchor:mapHudViewController.topWidgetsView.leftAnchor constant:0.],
            [_topPanelController.view.bottomAnchor constraintEqualToAnchor:mapHudViewController.topWidgetsView.bottomAnchor constant:0.],
            [_topPanelController.view.rightAnchor constraintEqualToAnchor:mapHudViewController.topWidgetsView.rightAnchor constant:0.],

            [_leftPanelController.view.topAnchor constraintEqualToAnchor:mapHudViewController.leftWidgetsView.topAnchor constant:0.],
            [_leftPanelController.view.leftAnchor constraintEqualToAnchor:mapHudViewController.leftWidgetsView.leftAnchor constant:0.],
            [_leftPanelController.view.bottomAnchor constraintEqualToAnchor:mapHudViewController.leftWidgetsView.bottomAnchor constant:0.],
            [_leftPanelController.view.rightAnchor constraintEqualToAnchor:mapHudViewController.leftWidgetsView.rightAnchor constant:0.],

            [_bottomPanelController.view.topAnchor constraintEqualToAnchor:mapHudViewController.bottomWidgetsView.topAnchor constant:0.],
            [_bottomPanelController.view.leftAnchor constraintEqualToAnchor:mapHudViewController.bottomWidgetsView.leftAnchor constant:0.],
            [_bottomPanelController.view.bottomAnchor constraintEqualToAnchor:mapHudViewController.bottomWidgetsView.bottomAnchor constant:0.],
            [_bottomPanelController.view.rightAnchor constraintEqualToAnchor:mapHudViewController.bottomWidgetsView.rightAnchor constant:0.],

            [_rightPanelController.view.topAnchor constraintEqualToAnchor:mapHudViewController.rightWidgetsView.topAnchor constant:0.],
            [_rightPanelController.view.leftAnchor constraintEqualToAnchor:mapHudViewController.rightWidgetsView.leftAnchor constant:0.],
            [_rightPanelController.view.bottomAnchor constraintEqualToAnchor:mapHudViewController.rightWidgetsView.bottomAnchor constant:0.],
            [_rightPanelController.view.rightAnchor constraintEqualToAnchor:mapHudViewController.rightWidgetsView.rightAnchor constant:0.]

        ]];

        [_topPanelController didMoveToParentViewController:mapHudViewController];
        [_leftPanelController didMoveToParentViewController:mapHudViewController];
        [_bottomPanelController didMoveToParentViewController:mapHudViewController];
        [_rightPanelController didMoveToParentViewController:mapHudViewController];

        _mapWidgetRegistry = [OAMapWidgetRegistry sharedInstance];
        _expanded = NO;
        _themeId = -1;

        [self registerAllControls];
        [self recreateControls];
        
        _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onMapRendererFramePrepared)
                                                            andObserve:[OARootViewController instance].mapPanel.mapViewController.framePreparedObservable];
        
        _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(onLocationServicesUpdate)
                                                                     andObserve:[OsmAndApp instance].locationServices.updateObserver];
        
        _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                      andObserve:[OARootViewController instance].mapPanel.mapViewController.zoomObservable];
        
        _mapSourceUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapSourceUpdated)
                                                      andObserve:[OARootViewController instance].mapPanel.mapViewController.mapSourceUpdatedObservable];
    }
    return self;
}

- (void) updateRuler {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rulerControl updateInfo];
    });
}

- (void) execOnDraw
{
    _lastUpdateTime = CACurrentMediaTime();
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onDraw];
    });
}

- (void) onMapRendererFramePrepared
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_framePreparedTimer)
            [_framePreparedTimer invalidate];
        
        _framePreparedTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(execOnDraw) userInfo:nil repeats:NO];
    });
    if (CACurrentMediaTime() - _lastUpdateTime > 1.0)
        [self execOnDraw];

    // Render the ruler more often
    [self updateRuler];
}

- (void) onRightWidgetSuperviewLayout
{
    [self execOnDraw];
}

- (void) onMapSourceUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rulerControl onMapSourceUpdated];
    });
}

- (void) onLocationServicesUpdate
{
    [self updateCurrentLocationAddress];
    [self updateInfo];
}

- (void) onDraw
{
    [self updateColorShadowsOfText];
    [_mapWidgetRegistry updateInfo:[_settings.applicationMode get] expanded:_expanded];
    for (OABaseWidgetView *widget in _widgetsToUpdate)
    {
        [widget updateInfo];
    }
}

- (void) updateCurrentLocationAddress
{
    [_mapHudViewController updateCurrentLocationAddress];
}

- (void) updateInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self onDraw];
    });
}

- (void) updateColorShadowsOfText
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    
    BOOL transparent = [_settings.transparentMapTheme get];
    BOOL nightMode = _settings.nightMode;
    BOOL following = [routingHelper isFollowingMode];
    
    int calcThemeId = (transparent ? 4 : 0) | (nightMode ? 2 : 0) | (following ? 1 : 0);
    if (_themeId != calcThemeId) {
        _themeId = calcThemeId;
        OATextState *state = [self calculateTextState];
        for (OAMapWidgetInfo *widgetInfo in [_mapWidgetRegistry getAllWidgets])
        {
            [widgetInfo.widget updateColors:state];
        }

        for (OAMapWidgetInfo *widgetInfo in [_mapWidgetRegistry getWidgetsForPanel:OAWidgetsPanel.leftPanel])
        {
            [self updateColors:state sideWidget:widgetInfo.widget];
        }

        for (OAMapWidgetInfo *widgetInfo in [_mapWidgetRegistry getWidgetsForPanel:OAWidgetsPanel.rightPanel])
        {
            [self updateColors:state sideWidget:widgetInfo.widget];
        }
    }
}

- (void) layoutWidgets
{
    BOOL portrait = ![OAUtilities isLandscape];

    BOOL hasTopWidgets = [_topPanelController hasWidgets];
    BOOL hasLeftWidgets = [_leftPanelController hasWidgets];
    BOOL hasBottomWidgets = [_bottomPanelController hasWidgets];
    BOOL hasRightWidgets = [_rightPanelController hasWidgets];

    if (_alarmControl && _alarmControl.superview && !_alarmControl.hidden)
    {
        CGRect optionsButtonFrame = _mapHudViewController.optionsMenuButton.frame;
        _alarmControl.center = CGPointMake(_alarmControl.bounds.size.width / 2, optionsButtonFrame.origin.y - _alarmControl.bounds.size.height / 2);
    }

    if (_rulerControl && _rulerControl.superview && !_rulerControl.hidden)
    {
        CGRect superFrame = _rulerControl.superview.frame;
        _rulerControl.frame = CGRectMake(superFrame.origin.x, superFrame.origin.y, superFrame.size.width, superFrame.size.height);
        _rulerControl.center = _rulerControl.superview.center;
    }

    if (hasTopWidgets)
    {
        if (_lastUpdateTime == 0)
            [[OARootViewController instance].mapPanel updateToolbar];
        _mapHudViewController.topWidgetsViewHeightConstraint.constant = [_topPanelController calculateContentSize].height;
    }
    else
    {
        _mapHudViewController.topWidgetsViewHeightConstraint.constant = 0.;
    }

    if (hasLeftWidgets)
    {
        CGSize leftSize = [_leftPanelController calculateContentSize];
        _mapHudViewController.leftWidgetsViewHeightConstraint.constant = leftSize.height;
        _mapHudViewController.leftWidgetsViewWidthConstraint.constant = leftSize.width;
    }
    else
    {
        _mapHudViewController.leftWidgetsViewHeightConstraint.constant = 0.;
        _mapHudViewController.leftWidgetsViewWidthConstraint.constant = 0.;
    }

    _mapHudViewController.bottomWidgetsViewHeightConstraint.constant = hasBottomWidgets ? [_bottomPanelController calculateContentSize].height : 0.;

    if (hasRightWidgets)
    {
        CGSize rightSize = [_rightPanelController calculateContentSize];
        _mapHudViewController.rightWidgetsViewHeightConstraint.constant = rightSize.height;
        _mapHudViewController.rightWidgetsViewWidthConstraint.constant = rightSize.width;
    }
    else
    {
        _mapHudViewController.rightWidgetsViewHeightConstraint.constant = 0.;
        _mapHudViewController.rightWidgetsViewWidthConstraint.constant = 0.;
    }

    if (_downloadMapWidget && _downloadMapWidget.superview && !_downloadMapWidget.hidden)
    {
        if (_lastUpdateTime == 0)
            [[OARootViewController instance].mapPanel updateToolbar];
        
        if (portrait)
        {
            _downloadMapWidget.frame = CGRectMake(0, _mapHudViewController.statusBarView.frame.size.height, DeviceScreenWidth, 155.);
        }
        else
        {
            CGFloat widgetWidth = DeviceScreenWidth / 2;
            CGFloat leftOffset = widgetWidth / 2 - [OAUtilities getLeftMargin];
            _downloadMapWidget.frame = CGRectMake(leftOffset, _mapHudViewController.statusBarView.frame.size.height, widgetWidth, 155.);
        }
    }

    if (_weatherToolbar && _weatherToolbar.superview)
        [self updateWeatherToolbarVisible];

    [self.delegate widgetsLayoutDidChange:YES];
}

- (void)updateWeatherToolbarVisible
{
    if (_weatherToolbarVisible && (_weatherToolbar.hidden || _weatherToolbar.frame.origin.y != [OAWeatherToolbar calculateY]))
        [self showWeatherToolbar];
    else if (!_weatherToolbarVisible && !_weatherToolbar.hidden && _weatherToolbar.frame.origin.y != [OAWeatherToolbar calculateYOutScreen])
        [self hideWeatherToolbar];
}

- (void)showWeatherToolbar
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if (!mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar)
    {
        mapPanel.mapViewController.mapLayers.weatherDate = [NSDate date];
        [_weatherToolbar resetHandlersData];
    }

    mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar = NO;
    [mapPanel.weatherToolbarStateChangeObservable notifyEvent];

    if (_weatherToolbar.hidden)
    {
        [_weatherToolbar moveOutOfScreen];
        _weatherToolbar.hidden = NO;
        [_mapHudViewController updateWeatherButtonVisibility];
    }

    _isBordersOfDownloadedMaps = [_settings.mapSettingShowBordersOfDownloadedMaps get];
    if (_isBordersOfDownloadedMaps)
    {
        [_settings.mapSettingShowBordersOfDownloadedMaps set:NO];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }

    [UIView animateWithDuration:.3 animations:^{
        [_weatherToolbar moveToScreen];
        [mapPanel targetUpdateControlsLayout:NO customStatusBarStyle:UIStatusBarStyleDefault];
        [_mapHudViewController.floatingButtonsController updateViewVisibility];
        [self recreateControls];
    }];
}

- (void)hideWeatherToolbar
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL needsSettingsForToolbar = mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar;
    if (!needsSettingsForToolbar)
    {
        mapPanel.mapViewController.mapLayers.weatherDate = [NSDate date];
        [mapPanel targetUpdateControlsLayout:NO customStatusBarStyle:UIStatusBarStyleDefault];
    }
    [mapPanel.weatherToolbarStateChangeObservable notifyEvent];

    if (_isBordersOfDownloadedMaps)
    {
        [_settings.mapSettingShowBordersOfDownloadedMaps set:YES];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }

    _weatherToolbar.hidden = YES;
    [_mapHudViewController updateWeatherButtonVisibility];
    [UIView animateWithDuration:.3 animations: ^{
        [_weatherToolbar moveOutOfScreen];
    }                completion:^(BOOL finished) {
        if (needsSettingsForToolbar)
        {
            OAWeatherLayerSettingsViewController *weatherLayerSettingsViewController =
            [[OAWeatherLayerSettingsViewController alloc] initWithLayerType:(EOAWeatherLayerType) _weatherToolbar.selectedLayerIndex];
            weatherLayerSettingsViewController.delegate = self;
            [mapPanel showScrollableHudViewController:weatherLayerSettingsViewController];
        }
    }];
    [_mapHudViewController.floatingButtonsController updateViewVisibility];
    [self recreateControls];
}

- (void) recreateAllControls
{
    [_mapWidgetRegistry clearWidgets];
    [self registerAllControls];
    [_mapWidgetRegistry reorderWidgets];
    [self recreateControls];
}

- (void) recreateControls
{
    OAApplicationMode *appMode = _settings.applicationMode.get;

    [_mapHudViewController setDownloadMapWidget:_downloadMapWidget];
    [_mapHudViewController setWeatherToolbarMapWidget:_weatherToolbar];

    [_rulerControl removeFromSuperview];
    [[OARootViewController instance].mapPanel.mapViewController.view insertSubview:_rulerControl atIndex:0];
    [self updateRuler];

    [_alarmControl removeFromSuperview];
    _alarmControl.delegate = self;
    [_mapHudViewController.view addSubview:_alarmControl];

    [_mapWidgetRegistry updateWidgetsInfo:[[OAAppSettings sharedManager].applicationMode get]];

    [self recreateWidgetsPanel:_topPanelController panel:OAWidgetsPanel.topPanel appMode:appMode];
    [self recreateWidgetsPanel:_bottomPanelController panel:OAWidgetsPanel.bottomPanel appMode:appMode];
    [self recreateWidgetsPanel:_leftPanelController panel:OAWidgetsPanel.leftPanel appMode:appMode];
    [self recreateWidgetsPanel:_rightPanelController panel:OAWidgetsPanel.rightPanel appMode:appMode];

    _themeId = -1;
    [self updateColorShadowsOfText];
    [self layoutWidgets];
}

- (void)recreateTopWidgetsPanel
{
    OAApplicationMode *appMode = [[OAAppSettings sharedManager].applicationMode get];
    [_mapWidgetRegistry updateWidgetsInfo:appMode];
    [self recreateWidgetsPanel:_topPanelController panel:OAWidgetsPanel.topPanel appMode:appMode];
}

- (void)recreateWidgetsPanel:(OAWidgetPanelViewController *)container panel:(OAWidgetsPanel *)panel appMode:(OAApplicationMode *)appMode
{
    if (container)
    {
        [container clearWidgets];
        [_mapWidgetRegistry populateControlsContainer:container mode:appMode widgetPanel:panel];
        [container updateWidgetSizes];
    }
}

- (void) expandClicked:(id)sender
{
    _expanded = !_expanded;
    [self recreateControls];
}

- (OATextState *) calculateTextState
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];

    BOOL transparent = [_settings.transparentMapTheme get];
    BOOL nightMode = _settings.nightMode;
    BOOL following = [routingHelper isFollowingMode];
    OATextState *ts = [[OATextState alloc] init];
    ts.textBold = following;
    ts.night = nightMode;
    ts.textColor = nightMode ? UIColorFromRGB(0xC8C8C8) : [UIColor blackColor];
    
    // Night shadowColor always use widgettext_shadow_night, same as widget background color for non-transparent
    ts.textShadowColor = nightMode ? UIColorFromARGB(color_widgettext_shadow_night_argb) : [UIColor whiteColor];
    if (!transparent && !nightMode)
        ts.textShadowRadius = 0;
    else
        ts.textShadowRadius = 16.0;

    if (transparent)
    {
        //ts.boxTop = R.drawable.btn_flat_transparent;
        ts.rightColor = [UIColor clearColor];
        ts.leftColor = [UIColor clearColor];
        //ts.boxFree = R.drawable.btn_round_transparent;
    }
    else if (nightMode)
    {
        //ts.boxTop = R.drawable.btn_flat_night;
        ts.rightColor = UIColorFromRGBA(0x000000a0);
        ts.leftColor = UIColorFromRGBA(0x000000a0);
        //ts.boxFree = R.drawable.btn_round_night;
    }
    else
    {
        //ts.boxTop = R.drawable.btn_flat;
        ts.rightColor = [UIColor whiteColor];
        ts.leftColor = [UIColor whiteColor];
        //ts.boxFree = R.drawable.btn_round;
    }
    
    return ts;
}

- (void) updateColors:(OATextState *)state sideWidget:(OABaseWidgetView *)sideWidget
{
    if ([sideWidget isKindOfClass:OATextInfoWidget.class])
    {
        OATextInfoWidget *widget = (OATextInfoWidget *) sideWidget;
        widget.backgroundColor = state.leftColor;
        [widget updateTextColor:state.textColor textShadowColor:state.textShadowColor bold:state.textBold shadowRadius:state.textShadowRadius];
        [widget updateIconMode:state.night];
    }
}

- (void) removeSideWidget:(OATextInfoWidget *)widget
{
    [_mapWidgetRegistry removeSideWidgetInternal:widget];
}

- (void) registerAllControls
{
    OARouteInfoWidgetsFactory *ric = [[OARouteInfoWidgetsFactory alloc] init];
//    OAMapInfoWidgetsFactory *mic = [[OAMapInfoWidgetsFactory alloc] init];
//    /*
//    MapMarkersWidgetsFactory mwf = map.getMapLayers().getMapMarkersLayer().getWidgetsFactory();
//    OsmandApplication app = view.getApplication();
//     */
    NSMutableArray<OABaseWidgetView *> *widgetsToUpdate = [NSMutableArray array];

    _alarmControl = [ric createAlarmInfoControl];
    _alarmControl.delegate = self;
    [widgetsToUpdate addObject:_alarmControl];

    _downloadMapWidget = [[OADownloadMapWidget alloc] init];
    _downloadMapWidget.delegate = self;
    [widgetsToUpdate addObject:_downloadMapWidget];

    _weatherToolbar = [[OAWeatherToolbar alloc] init];
    _weatherToolbar.delegate = self;
    [widgetsToUpdate addObject:_weatherToolbar];

    _widgetsToUpdate = widgetsToUpdate;
    
    _rulerControl = [ric createRulerControl];
//
//    /*
//    topToolbarView = new TopToolbarView(map);
//    updateTopToolbar(false);
//
//    */
//    // register left stack
//
//    [self registerSideWidget:nil widgetState:[[OACompassModeWidgetState alloc] init] key:@"compass" left:YES priorityOrder:4];
//
//    OANextTurnWidget *bigInfoControl = [ric createNextInfoControl:NO];
//    [self registerSideWidget:bigInfoControl imageId:@"ic_action_next_turn" message:OALocalizedString(@"map_widget_next_turn") key:@"next_turn" left:YES priorityOrder:5];
//    OANextTurnWidget *smallInfoControl = [ric createNextInfoControl:YES];
//    [self registerSideWidget:smallInfoControl imageId:@"ic_action_next_turn" message:OALocalizedString(@"map_widget_next_turn_small") key:@"next_turn_small" left:YES priorityOrder:6];
//    OANextTurnWidget *nextNextInfoControl = [ric createNextNextInfoControl:YES];
//    [self registerSideWidget:nextNextInfoControl imageId:@"ic_action_next_turn" message:OALocalizedString(@"map_widget_next_next_turn") key:@"next_next_turn" left:YES priorityOrder:7];
//
//    // register right stack
//
//    // priorityOrder: 10s navigation-related, 20s position-related, 30s recording- and other plugin-related, 40s general device information, 50s debugging-purpose
//    OATextInfoWidget *intermediateDist = [ric createIntermediateDistanceControl];
//    [self registerSideWidget:intermediateDist imageId:@"ic_action_intermediate" message:OALocalizedString(@"map_widget_intermediate_distance") key:@"intermediate_distance" left:NO priorityOrder:13];
//    OATextInfoWidget *intermediateTime = [ric createTimeControl:YES];
//    [self registerSideWidget:intermediateTime widgetState:[[OAIntermediateTimeControlWidgetState alloc] init] key:@"intermediate_time" left:NO priorityOrder:14];
//    OATextInfoWidget *dist = [ric createDistanceControl];
//    [self registerSideWidget:dist imageId:@"ic_action_target" message:OALocalizedString(@"route_descr_destination") key:@"distance" left:NO priorityOrder:15];
//    OATextInfoWidget *time = [ric createTimeControl:NO];
//    [self registerSideWidget:time widgetState:[[OATimeWidgetState alloc] init] key:@"time" left:NO priorityOrder:16];
//    OATextInfoWidget *bearing = [ric createBearingControl];
//    [self registerSideWidget:bearing widgetState:[[OABearingWidgetState alloc] init] key:@"bearing" left:NO priorityOrder:17];
//
//    OATextInfoWidget *marker = [ric createMapMarkerControl:YES];
//    [self registerSideWidget:marker imageId:@"widget_marker_day" message:OALocalizedString(@"map_marker") key:@"map_marker_1st" left:NO priorityOrder:18];
//    OATextInfoWidget *marker2nd = [ric createMapMarkerControl:NO];
//    [self registerSideWidget:marker2nd imageId:@"widget_marker_day" message:OALocalizedString(@"map_marker") key:@"map_marker_2nd" left:NO priorityOrder:19];
//
//    OATextInfoWidget *speed = [ric createSpeedControl];
//    [self registerSideWidget:speed imageId:@"ic_action_speed" message:OALocalizedString(@"shared_string_speed") key:@"speed" left:false priorityOrder:20];
//    OATextInfoWidget *maxspeed = [ric createMaxSpeedControl];
//    [self registerSideWidget:maxspeed imageId:@"ic_action_speed_limit" message:OALocalizedString(@"map_widget_max_speed") key:@"max_speed" left:false priorityOrder:21];
//
//    OAAltitudeWidget *altitudeWidgetMyLocation = [[OAAltitudeWidget alloc] initWithType:EOAAltitudeWidgetTypeMyLocation];
//    [self registerSideWidget:altitudeWidgetMyLocation imageId:@"widget_altitude_location_day" message:OALocalizedString(@"map_widget_altitude_current_location") description:OALocalizedString(@"altitude_widget_desc") key:@"altitude" left:NO priorityOrder:23];
//
//    OATextInfoWidget *plainTime = [ric createPlainTimeControl];
//    [self registerSideWidget:plainTime imageId:@"ic_action_time" message:OALocalizedString(@"map_widget_plain_time") key:@"plain_time" left:false priorityOrder:41];
//    OATextInfoWidget *battery = [ric createBatteryControl];
//    [self registerSideWidget:battery imageId:@"ic_action_battery" message:OALocalizedString(@"map_widget_battery") key:@"battery" left:false priorityOrder:42];
//
//    OATextInfoWidget *ruler = [mic createRulerControl];
//    [self registerSideWidget:ruler widgetState:[[OACompassRulerWidgetState alloc] init] key:@"radius_ruler" left:NO priorityOrder:43];
//
//    OASunriseSunsetWidgetState *sunriseState = [[OASunriseSunsetWidgetState alloc] initWithType:YES customId:nil];
//    OASunriseSunsetWidget *sunriseWidget = [[OASunriseSunsetWidget alloc] initWithState:sunriseState];
//    [self registerSideWidget:sunriseWidget widgetState:sunriseState key:@"sunrise" left:NO priorityOrder:44];
//
//    OASunriseSunsetWidgetState *sunsetState = [[OASunriseSunsetWidgetState alloc] initWithType:NO customId:nil];
//    OASunriseSunsetWidget *sunsetWidget = [[OASunriseSunsetWidget alloc] initWithState:sunsetState];
//    [self registerSideWidget:sunsetWidget widgetState:sunsetState key:@"sunset" left:NO priorityOrder:45];
    
    [_mapWidgetRegistry registerAllControls];
    _themeId = -1;
    [self updateColorShadowsOfText];
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    [self updateRuler];
}

#pragma mark - OAWidgetListener

- (void) widgetChanged:(OABaseWidgetView *)widget
{
    if (widget.isTopText)
        [self layoutWidgets];
}

- (void) widgetVisibilityChanged:(OABaseWidgetView *)widget visible:(BOOL)visible
{
    [self layoutWidgets];
}

- (void) widgetClicked:(OABaseWidgetView *)widget
{
    if (!widget.isTopText)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapWidgetRegistry updateInfo:_settings.applicationMode.get expanded:_expanded];
        });
    }
}

#pragma mark - OAWeatherLayerSettingsDelegate

- (void)onDoneWeatherLayerSettings:(BOOL)show
{
    if (show)
        [_mapHudViewController changeWeatherToolbarVisible];
}

// MARK: OAWidgetPanelDelegate

- (void)onPanelSizeChanged
{
    [self layoutWidgets];
}

@end
