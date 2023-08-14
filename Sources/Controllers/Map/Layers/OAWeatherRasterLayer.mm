//
//  OAWeatherRasterLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherRasterLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherToolbar.h"
#import "OAMapLayers.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/WeatherRasterLayerProvider.h>

@implementation OAWeatherRasterLayer
{
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _resourcesManager;
    std::shared_ptr<OsmAnd::WeatherRasterLayerProvider> _provider;

    OAWeatherHelper *_weatherHelper;
    OAAutoObserverProxy *_weatherToolbarStateChangeObservable;
    BOOL _needsSettingsForToolbar;
    OAAutoObserverProxy* _weatherChangeObserver;
    OAAutoObserverProxy* _weatherUseOfflineDataChangeObserver;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    NSMutableArray<OAAutoObserverProxy *> *_alphaChangeObservers;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherLayer:(EOAWeatherLayer)weatherLayer date:(NSDate *)date
{
    self = [super initWithMapViewController:mapViewController layerIndex:layerIndex];
    if (self)
    {
        _weatherLayer = weatherLayer;
        _date = date;
    }
    return self;
}

- (NSString *) layerId
{
    return [NSString stringWithFormat:@"%@_%d", kWeatherRasterMapLayerId, (int)_weatherLayer];
}

- (void) initLayer
{
    _resourcesManager = self.app.resourcesManager->getWeatherResourcesManager();
    _weatherHelper = [OAWeatherHelper sharedInstance];

    _weatherToolbarStateChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherToolbarStateChanged)
                                                                      andObserve:[OARootViewController instance].mapPanel.weatherToolbarStateChangeObservable];
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    _weatherUseOfflineDataChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherLayerChanged)
                                                                      andObserve:self.app.data.weatherUseOfflineDataChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    _alphaChangeObservers = [NSMutableArray array];
    
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
    {
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onWeatherLayerChanged)]];
        [_alphaChangeObservers addObject:[band createAlphaObserver:self handler:@selector(onWeatherLayerAlphaChanged)]];
    }
}

- (void) deinitLayer
{
    if (_weatherToolbarStateChangeObservable)
    {
        [_weatherToolbarStateChangeObservable detach];
        _weatherToolbarStateChangeObservable = nil;
    }
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
    }
    if (_weatherUseOfflineDataChangeObserver)
    {
        [_weatherUseOfflineDataChangeObserver detach];
        _weatherUseOfflineDataChangeObserver = nil;
    }
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];

    for (OAAutoObserverProxy *observer in _alphaChangeObservers)
        [observer detach];
    
    [_layerChangeObservers removeAllObjects];
    [_alphaChangeObservers removeAllObjects];
}

- (void) resetLayer
{
    _provider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    [super updateLayer];

    if ([[OAPlugin getPlugin:OAWeatherPlugin.class] isEnabled])
    {
        [self updateOpacitySliderVisibility];

        QList<OsmAnd::BandIndex> bands = [_weatherHelper getVisibleBands];
        if ((!self.app.data.weather && !_needsSettingsForToolbar) || bands.empty())
            return NO;

        //[self showProgressHUD];

        NSDate *roundedDate = [OAWeatherHelper roundForecastTimeToHour:_date];
        int64_t dateTime = roundedDate.timeIntervalSince1970 * 1000;
        OsmAnd::WeatherLayer layer;
        switch (_weatherLayer) {
            case WEATHER_LAYER_LOW:
                layer = OsmAnd::WeatherLayer::Low;
                break;
            case WEATHER_LAYER_HIGH:
                layer = OsmAnd::WeatherLayer::High;
                break;
            default:
                layer = OsmAnd::WeatherLayer::Low;
                break;
        }
        if (true)//!_provider)
        {
            _provider = std::make_shared<OsmAnd::WeatherRasterLayerProvider>(_resourcesManager, layer, dateTime, bands, self.app.data.weatherUseOfflineData);
            [self.mapView setProvider:_provider forLayer:self.layerIndex];

            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(1.0f);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }
        else
        {
            _provider->setDateTime(dateTime);
            _provider->setBands(bands);

            [self.mapView invalidateFrame];
        }

        //[self hideProgressHUD];

        return YES;
    }
    return NO;
}

- (void)onWeatherToolbarStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needsSettingsForToolbar = [[OARootViewController instance].mapPanel.hudViewController needsSettingsForWeatherToolbar];
        if (_needsSettingsForToolbar != needsSettingsForToolbar)
        {
            _date = self.mapViewController.mapLayers.weatherDate;
            _needsSettingsForToolbar = needsSettingsForToolbar;
            [self updateWeatherLayerAlpha];
        }
    });
}

- (void) onWeatherChanged
{
    [self updateWeatherLayer];
}

- (void) updateDate:(NSDate *)date
{
    _date = date;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) onWeatherLayerChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) onWeatherLayerAlphaChanged
{
    [self updateWeatherLayerAlpha];
/*
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor([value floatValue]);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
 */
}

- (void) updateWeatherLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            if (![self updateLayer])
            {
                //[self.mapView resetProviderFor:0];
                [self.mapView resetProviderFor:self.layerIndex];
                _provider.reset();
            }
        }];
    });
}

- (void) updateWeatherLayerAlpha
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            _resourcesManager->setBandSettings([_weatherHelper getBandSettings]);
            [self updateWeatherLayer];
        }];
    });
}

- (void) updateOpacitySliderVisibility
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //TODO [[OARootViewController instance].mapPanel updateWeatherView];
    });
}

@end
