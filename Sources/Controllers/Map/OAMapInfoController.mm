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
#import "OAQuickActionHudViewController.h"
#import "OAMapLayers.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OASunriseSunsetWidget.h"
#import "OASunriseSunsetWidgetState.h"
#import "OAAltitudeWidget.h"

#import "OsmAnd_Maps-Swift.h"

@interface OATextState : NSObject

@property (nonatomic) BOOL textBold;
@property (nonatomic) BOOL night;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *textShadowColor;
@property (nonatomic) int boxTop;
@property (nonatomic) UIColor *rightColor;
@property (nonatomic) UIColor *leftColor;
@property (nonatomic) NSString *expand;
@property (nonatomic) int boxFree;
@property (nonatomic) float textShadowRadius;

@end

@implementation OATextState
@end

@interface OAMapInfoController () <OAWeatherLayerSettingsDelegate>

@end

@implementation OAMapInfoController
{
    OAMapHudViewController __weak *_mapHudViewController;
    UIView __weak *_widgetsView;
    UIView __weak *_leftWidgetsView;
    UIView __weak *_rightWidgetsView;
    
    OAWidgetPanelViewController *_leftPanelController;
    OAWidgetPanelViewController *_rightPanelController;

    OAMapWidgetRegistry *_mapWidgetRegistry;
    BOOL _expanded;
    OATopTextView *_streetNameView;
    OABaseWidgetView *_topCoordinatesView;
    OABaseWidgetView *_coordinatesMapCenterWidget;
    OADownloadMapWidget *_downloadMapWidget;
    OAWeatherToolbar *_weatherToolbar;
    OALanesControl *_lanesControl;
    OAAlarmWidget *_alarmControl;
    OARulerWidget *_rulerControl;

    OAAppSettings *_settings;
    OADayNightHelper *_dayNightHelper;
    OAAutoObserverProxy* _framePreparedObserver;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapSourceUpdatedObserver;
    OAAutoObserverProxy* _rightWidgetSuperviewDidLayoutObserver;

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
        _widgetsView = mapHudViewController.widgetsView;
        _leftPanelController = [[OAWidgetPanelViewController alloc] init];
        _rightPanelController = [[OAWidgetPanelViewController alloc] init];
        
        [mapHudViewController addChildViewController:_leftPanelController];
        [mapHudViewController addChildViewController:_rightPanelController];
        [_widgetsView addSubview:_leftPanelController.view];
        [_widgetsView addSubview:_rightPanelController.view];
        
        _leftPanelController.view.translatesAutoresizingMaskIntoConstraints = false;
        [_leftPanelController.view.topAnchor constraintEqualToAnchor:_widgetsView.topAnchor].active = YES;
        [_leftPanelController.view.leadingAnchor constraintEqualToAnchor:_widgetsView.leadingAnchor].active = YES;
        _rightPanelController.view.translatesAutoresizingMaskIntoConstraints = false;
        [_rightPanelController.view.topAnchor constraintEqualToAnchor:_widgetsView.topAnchor].active = YES;
        [_rightPanelController.view.trailingAnchor constraintEqualToAnchor:_widgetsView.trailingAnchor].active = YES;
        
        [_leftPanelController didMoveToParentViewController:mapHudViewController];
        [_rightPanelController didMoveToParentViewController:mapHudViewController];

        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
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
        
//        if (_rightWidgetsView.superview && [_rightWidgetsView.superview isKindOfClass:OAUserInteractionPassThroughView.class])
//            _rightWidgetSuperviewDidLayoutObserver = [[OAAutoObserverProxy alloc] initWith:self
//                                                         withHandler:@selector(onRightWidgetSuperviewLayout)
//                                                          andObserve:((OAUserInteractionPassThroughView *)_rightWidgetsView.superview).didLayoutObservable];
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
    [_mapWidgetRegistry updateInfo:_settings.applicationMode.get expanded:_expanded];
//    for (OABaseWidgetView *widget in _widgetsToUpdate)
//         [widget updateInfo];
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
        OATextState *ts = [self calculateTextState];
        for (OAMapWidgetInfo *reg in [_mapWidgetRegistry getWidgetsForPanel:OAWidgetsPanel.leftPanel])
            [self updateReg:ts reg:reg];

        for (OAMapWidgetInfo *reg in [_mapWidgetRegistry getWidgetsForPanel:OAWidgetsPanel.rightPanel])
            [self updateReg:ts reg:reg];

        [self updateStreetName:nightMode ts:ts];
        //updateTopToolbar(nightMode);
        _lanesControl.backgroundColor = ts.leftColor;
        [_lanesControl updateTextColor:ts.textColor textShadowColor:ts.textShadowColor bold:ts.textBold shadowRadius:ts.textShadowRadius];
        //rulerControl.updateTextSize(nightMode, ts.textColor, ts.textShadowColor,  (int) (2 * view.getDensity()));
    }
}

- (BOOL)topTextViewVisible
{
    return _streetNameView && _streetNameView.superview && !_streetNameView.hidden;
}

- (void) layoutWidgets:(OABaseWidgetView *)widget
{
    NSMutableArray<UIView *> *containers = [NSMutableArray array];
    if (widget)
    {
        for (UIView *w in _leftWidgetsView.subviews)
        {
            if (w == widget)
            {
                [containers addObject:_leftWidgetsView];
                break;
            }
        }
        for (UIView *w in _rightWidgetsView.subviews)
        {
            if (w == widget)
            {
                [containers addObject:_rightWidgetsView];
                break;
            }
        }
    }
    else
    {
//        [containers addObject:_leftPanelController.view];
//        [containers addObject:_rightPanelController.view];
    }
    
    BOOL portrait = ![OAUtilities isLandscape];
    CGFloat maxContainerHeight = 0;
    CGFloat yPos = 0;
    BOOL hasStreetName = NO;
    if ([self topTextViewVisible])
    {
        hasStreetName = YES;
        if (portrait)
        {
            yPos += _streetNameView.frame.size.height + 2;
            maxContainerHeight += _streetNameView.frame.size.height + 2;
        }
    }
    else
    {
        yPos += 1;
    }
    
    BOOL hasLeftWidgets = _leftPanelController.hasWidgets;
    BOOL hasRightWidgets = _rightPanelController.hasWidgets;

    CGRect leftRect = _leftPanelController.view.frame;
//    [_leftPanelController updateWidgetSizes];
//    [_rightPanelController updateWidgetSizes];
    
    CGFloat maxWidth = fmax(_leftPanelController.view.frame.size.width, _rightPanelController.view.frame.size.width);
    CGFloat widgetsHeight = fmax(_leftPanelController.view.frame.size.height, _rightPanelController.view.frame.size.height);
    
    maxContainerHeight = fmax(maxContainerHeight, widgetsHeight);
    
    if (self.delegate && !CGRectEqualToRect(leftRect, _leftPanelController.view.frame))
        [self.delegate leftWidgetsLayoutDidChange:_leftPanelController.view animated:YES];
    
    for (UIView *container in containers)
    {
        NSArray<UIView *> *allViews = container.subviews;
        NSMutableArray<UIView *> *views = [NSMutableArray array];
        for (UIView *v in allViews)
            if (!v.hidden)
                [views addObject:v];
        
        
        for (UIView *v in views)
        {
            if (v.hidden)
                continue;
            
            if ([v isKindOfClass:[OATextInfoWidget class]])
                [((OATextInfoWidget *)v) adjustViewSize];
            else
                [v sizeToFit];
            
            if (maxWidth < v.frame.size.width)
                maxWidth = v.frame.size.width;
            
            widgetsHeight += v.frame.size.height + 2;
        }
        
        CGFloat containerHeight = widgetsHeight;
        
        if (container == _rightWidgetsView)
        {
            hasRightWidgets = widgetsHeight > 0;
            CGFloat rightOffset = 2.0;
            CGRect rightContainerFrame = CGRectMake(_mapHudViewController.view.frame.size.width - maxWidth - 2 * rightOffset, yPos, maxWidth, containerHeight);
            if (!CGRectEqualToRect(container.frame, rightContainerFrame))
                container.frame = rightContainerFrame;
        }
        else
        {
            hasLeftWidgets = widgetsHeight > 0;
            CGRect leftContainerFrame = CGRectMake(0, yPos, maxWidth, containerHeight);
            if (!CGRectEqualToRect(container.frame, leftContainerFrame))
            {
                container.frame = leftContainerFrame;
                if (self.delegate)
                    [self.delegate leftWidgetsLayoutDidChange:container animated:YES];
            }
        }
        
        if (maxContainerHeight < containerHeight)
            maxContainerHeight = containerHeight;
        
        CGFloat y = 0;
        for (int i = 0; i < views.count; i++)
        {
            UIView *v = views[i];
            CGFloat h = v.frame.size.height;
            v.frame = CGRectMake(0, y, maxWidth, h);
            y += h + 2;
        }
    }
    
    if (hasStreetName)
    {
        CGFloat streetNameViewHeight = _streetNameView.bounds.size.height;
        CGRect f = _streetNameView.superview.frame;
        if (portrait)
        {
            _streetNameView.frame = CGRectMake(0, 0, f.size.width, streetNameViewHeight);
        }
        else
        {
            CGRect leftFrame = _leftWidgetsView.frame;
            CGRect rightFrame = _rightWidgetsView.frame;
            CGFloat w = f.size.width - (hasRightWidgets ? rightFrame.size.width + 2 : 0) - (hasLeftWidgets ? leftFrame.size.width + 2 : 0);
            _streetNameView.frame = CGRectMake(hasLeftWidgets ? leftFrame.size.width + 2 : 0, yPos, w, streetNameViewHeight);
        }
        [self.delegate streetViewLayoutDidChange:_streetNameView animate:YES];
        if (maxContainerHeight < streetNameViewHeight)
            maxContainerHeight = streetNameViewHeight;
    }
    
    if (_lanesControl && _lanesControl.superview && !_lanesControl.hidden)
    {
        CGRect f = _lanesControl.superview.frame;
        CGFloat y = yPos + (!portrait && hasStreetName ? _streetNameView.frame.origin.y + _streetNameView.frame.size.height + 2 : 0);
        _lanesControl.center = CGPointMake(f.size.width / 2, y + _lanesControl.bounds.size.height / 2);
    }

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
    
    CGRect f = _widgetsView.frame;
    _widgetsView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, maxContainerHeight);
    
    BOOL showTopCoordinatesView = _topCoordinatesView && _topCoordinatesView.superview && !_topCoordinatesView.hidden;
    BOOL showCoordinatesMapCenterWidget = _coordinatesMapCenterWidget && _coordinatesMapCenterWidget.superview && !_coordinatesMapCenterWidget.hidden;
    
    if (showTopCoordinatesView || showCoordinatesMapCenterWidget)
    {
        if (_lastUpdateTime == 0)
            [[OARootViewController instance].mapPanel updateToolbar];
        
        BOOL hasTopWidgetsPanel = _mapHudViewController.toolbarViewController.view.alpha != 0;
        if (portrait)
        {
            if (showTopCoordinatesView)
            {
                _topCoordinatesView.frame = CGRectMake(0, _mapHudViewController.statusBarView.frame.size.height, DeviceScreenWidth, 52);
                if (showCoordinatesMapCenterWidget)
                    _coordinatesMapCenterWidget.frame = CGRectMake(0, _mapHudViewController.statusBarView.frame.size.height + 52, DeviceScreenWidth, 52);
            }
            else if (showCoordinatesMapCenterWidget)
            {
                _coordinatesMapCenterWidget.frame = CGRectMake(0, _mapHudViewController.statusBarView.frame.size.height, DeviceScreenWidth, 52);
            }
        }
        else
        {
            CGFloat widgetWidth = DeviceScreenWidth / 2 - [OAUtilities getLeftMargin];
            CGFloat withMarkersLeftOffset = [_topCoordinatesView isDirectionRTL] ? DeviceScreenWidth / 2 : [OAUtilities getLeftMargin];
            CGFloat leftOffset = hasTopWidgetsPanel ? withMarkersLeftOffset : (DeviceScreenWidth - widgetWidth) / 2;
            if (showTopCoordinatesView)
            {
                _topCoordinatesView.frame = CGRectMake(leftOffset - [OAUtilities getLeftMargin], _mapHudViewController.statusBarView.frame.size.height, widgetWidth, 50);
                if (showCoordinatesMapCenterWidget)
                    _coordinatesMapCenterWidget.frame = CGRectMake(leftOffset - [OAUtilities getLeftMargin], _mapHudViewController.statusBarView.frame.size.height + 50, widgetWidth, 50);
            }
            else if (showCoordinatesMapCenterWidget)
            {
                _coordinatesMapCenterWidget.frame = CGRectMake(leftOffset - [OAUtilities getLeftMargin], _mapHudViewController.statusBarView.frame.size.height, widgetWidth, 50);
            }
        }
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

    [UIView animateWithDuration:.3 animations:^{
        [_weatherToolbar moveToScreen];

        [_mapHudViewController showBottomControls:[OAUtilities isLandscape] ? 0. : _weatherToolbar.frame.size.height - [OAUtilities getBottomMargin]
                                         animated:YES];
        [mapPanel setTopControlsVisible:YES];
        [_mapHudViewController.quickActionController updateViewVisibility];
        [self recreateControls];

        CGFloat height = [OAUtilities isLandscape] ? 0. : _weatherToolbar.frame.size.height;
        CGFloat leftMargin = [OAUtilities isLandscape]
                ? _weatherToolbar.frame.size.width - [OAUtilities getLeftMargin] + 20.
                : _mapHudViewController.driveModeButton.frame.origin.x + _mapHudViewController.driveModeButton.frame.size.width + 16.;
        [_mapHudViewController updateRulerPosition:[OAUtilities isLandscape] ? 0. : -(height - [OAUtilities getBottomMargin] + 20.)
                                              left:leftMargin];
    }];
}

- (void)hideWeatherToolbar
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL needsSettingsForToolbar = mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar;
    if (!needsSettingsForToolbar)
    {
        mapPanel.mapViewController.mapLayers.weatherDate = [NSDate date];
        [mapPanel setTopControlsVisible:YES];
        [_mapHudViewController showBottomControls:0. animated:YES];
    }
    [mapPanel.weatherToolbarStateChangeObservable notifyEvent];

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
    [_mapHudViewController resetToDefaultRulerLayout];
    [_mapHudViewController.quickActionController updateViewVisibility];
    [self recreateControls];
}

- (CGFloat) getLeftBottomY
{
    CGFloat res = 0;
    if (!_streetNameView.hidden)
        res = _streetNameView.frame.origin.y + _streetNameView.frame.size.height;
    
    if (!_leftPanelController.view.hidden && _leftPanelController.view.frame.size.height > 0)
        res = _leftPanelController.view.frame.origin.y + _leftPanelController.view.frame.size.height;
        
    return res;
}

- (void) recreateControls
{
    OAApplicationMode *appMode = _settings.applicationMode.get;
    
    [_mapHudViewController setCoordinatesWidget:_topCoordinatesView];
    [_mapHudViewController setCenterCoordinatesWidget:_coordinatesMapCenterWidget];
    [_mapHudViewController setDownloadMapWidget:_downloadMapWidget];
    [_mapHudViewController setWeatherToolbarMapWidget:_weatherToolbar];

    [_streetNameView removeFromSuperview];
    [_widgetsView addSubview:_streetNameView];

    [_lanesControl removeFromSuperview];
    [_widgetsView addSubview:_lanesControl];
    
    [_rulerControl removeFromSuperview];
    [[OARootViewController instance].mapPanel.mapViewController.view insertSubview:_rulerControl atIndex:0];
    [self updateRuler];

    [_alarmControl removeFromSuperview];
    [_mapHudViewController.view addSubview:_alarmControl];

    for (UIView *widget in _leftWidgetsView.subviews)
        [widget removeFromSuperview];
    
    for (UIView *widget in _rightWidgetsView.subviews)
        [widget removeFromSuperview];
    
    [_leftPanelController clearWidgets];
    [_rightPanelController clearWidgets];
    
    //[self.view insertSubview:self.widgetsView belowSubview:_toolbarViewController.view];
//    [_mapWidgetRegistry populateStackControl:_leftWidgetsView mode:appMode left:YES expanded:_expanded];
//    [_mapWidgetRegistry populateStackControl:_rightWidgetsView mode:appMode left:NO expanded:_expanded];
    
    [_mapWidgetRegistry clearWidgets];
    [_mapWidgetRegistry registerAllControls];
    [_mapWidgetRegistry reorderWidgets];
    
    [_mapWidgetRegistry populateStackControl:_leftPanelController mode:appMode widgetPanel:OAWidgetsPanel.leftPanel];
    [_mapWidgetRegistry populateStackControl:_rightPanelController mode:appMode widgetPanel:OAWidgetsPanel.rightPanel];
        
    for (UIView *v in _leftWidgetsView.subviews)
    {
        OATextInfoWidget *w = (OATextInfoWidget *)v;
        w.delegate = self;
    }
    for (UIView *v in _rightWidgetsView.subviews)
    {
        OATextInfoWidget *w = (OATextInfoWidget *)v;
        w.delegate = self;
    }
    _themeId = -1;
    [self updateColorShadowsOfText];
    [self layoutWidgets:nil];
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

- (void) updateReg:(OATextState *)ts reg:(OAMapWidgetInfo *)reg
{
    if ([reg.widget isKindOfClass:OATextInfoWidget.class])
    {
        OATextInfoWidget *widget = (OATextInfoWidget *) reg.widget;
        widget.backgroundColor = ts.leftColor;
        [widget updateTextColor:ts.textColor textShadowColor:ts.textShadowColor bold:ts.textBold shadowRadius:ts.textShadowRadius];
        [widget updateIconMode:ts.night];
    }
}

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    return [self registerSideWidget:widget imageId:imageId message:message description:nil key:key left:left priorityOrder:priorityOrder];
}

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message description:(NSString *)description key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *reg = [_mapWidgetRegistry registerSideWidgetInternal:widget imageId:imageId message:message description:description key:key left:left priorityOrder:priorityOrder];
//    [self updateReg:[self calculateTextState] reg:reg];
    return reg;
}

- (void) registerSideWidget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *reg = [_mapWidgetRegistry registerSideWidgetInternal:widget widgetState:widgetState key:key left:left priorityOrder:priorityOrder];
//    [self updateReg:[self calculateTextState] reg:reg];
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
//
//    _rulerControl = [ric createRulerControl];
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
    // TODO: Refactor this logic to use a stack view and get rid of the references entirely
    _topCoordinatesView = [_mapWidgetRegistry getWidgetInfoById:OAWidgetType.coordinatesCurrentLocation.id].widget;
    _coordinatesMapCenterWidget = [_mapWidgetRegistry getWidgetInfoById:OAWidgetType.coordinatesMapCenter.id].widget;
    _lanesControl = (OALanesControl *) [_mapWidgetRegistry getWidgetInfoById:OAWidgetType.lanes.id].widget;
    _rulerControl = (OARulerWidget *) [_mapWidgetRegistry getWidgetInfoById:OAWidgetType.radiusRuler.id].widget;
    _streetNameView = (OATopTextView *) [_mapWidgetRegistry getWidgetInfoById:OAWidgetType.streetName.id].widget;
    OATextState *ts = [self calculateTextState];
    [self updateStreetName:NO ts:ts];
    _themeId = -1;
    [self updateColorShadowsOfText];
}

- (void) updateStreetName:(BOOL)nightMode ts:(OATextState *)ts
{
    _streetNameView.backgroundColor = ts.leftColor;
    [_streetNameView updateTextColor:ts.textColor textShadowColor:ts.textShadowColor bold:ts.textBold shadowRadius:ts.textShadowRadius nightMode:nightMode];
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    [self updateRuler];
}

#pragma mark - OAWidgetListener

- (void) widgetChanged:(OABaseWidgetView *)widget
{
    if (!widget.isTopText)
        [self layoutWidgets:widget];
}

- (void) widgetVisibilityChanged:(OABaseWidgetView *)widget visible:(BOOL)visible
{
    [self layoutWidgets:widget.isTopText ? nil : widget];
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

@end
