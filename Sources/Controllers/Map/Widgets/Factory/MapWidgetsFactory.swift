//
//  OABaseWidgetViewsFactory.swift
//  OsmAnd Maps
//
//  Created by Paul on 10.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapWidgetsFactory)
class MapWidgetsFactory: NSObject {
    
    func createMapWidget(widgetType: WidgetType) -> OABaseWidgetView? {
        return createMapWidgetImpl(customId: nil, widgetType: widgetType)
    }
    
    func createMapWidget(customId: String?, widgetType: WidgetType) -> OABaseWidgetView? {
        if isWidgetCreationAllowed(widgetType: widgetType) {
            return createMapWidgetImpl(customId: customId, widgetType: widgetType)
        }
        return nil
    }
    
    private func createMapWidgetImpl(customId: String?, widgetType: WidgetType) -> OABaseWidgetView? {
        switch widgetType {
        case .nextTurn:
            return OANextTurnWidget(horisontalMini: false, nextNext: false)
        case .smallNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: false)
        case .secondNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: true)
        case .coordinatesCurrentLocation:
            let widget = CoordinatesCurrentLocationWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .coordinatesMapCenter:
            let widget = CoordinatesMapCenterWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .streetName:
            let widget = OATopTextView()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .markersTopBar:
            return nil // MapMarkersBarWidget(mapActivity: mapActivity)
        case .lanes:
            let widget = OALanesControl()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .distanceToDestination:
            return DistanceToDestinationWidget()
        case .intermediateDestination:
            return DistanceToIntermediateDestinationWidget()
        case .timeToIntermediate:
            let state = TimeToNavigationPointWidgetState(customId: customId, intermediate: true)
            return TimeToNavigationPointWidget(widgetState: state)
        case .timeToDestination:
            let widgetState = TimeToNavigationPointWidgetState(customId: customId, intermediate: false)
            return TimeToNavigationPointWidget(widgetState: widgetState)
        case .sideMarker1:
            let firstMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: true)
            return MapMarkerSideWidget(widgetState: firstMarkerState)
        case .sideMarker2:
            let secondMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: false)
            return MapMarkerSideWidget(widgetState: secondMarkerState)
        case .relativeBearing:
            return OABearingWidget(bearingType: .relative)
        case .magneticBearing:
            return OABearingWidget(bearingType: .magnetic)
        case .trueBearing:
            return OABearingWidget(bearingType: .true)
        case .currentSpeed:
            return OACurrentSpeedWidget()
        case .averageSpeed:
            return /*AverageSpeedWidget(mapActivity: mapActivity, customId: customId)*/nil
        case .maxSpeed:
            return OAMaxSpeedWidget()
        case .altitudeMyLocation:
            return OAAltitudeWidget(type: .myLocation)
        case .altitudeMapCenter:
            return OAAltitudeWidget(type: .mapCenter)
        case .gpsInfo:
            return /*GpsInfoWidget(mapActivity: mapActivity)*/nil
        case .currentTime:
            return CurrentTimeWidget()
        case .battery:
            return BatteryWidget()
        case .radiusRuler:
            return RulerDistanceWidget()
        case .sunrise:
            let sunriseState = OASunriseSunsetWidgetState(type: true, customId: customId)
            return OASunriseSunsetWidget(state: sunriseState)
        case .sunset:
            let sunsetState = OASunriseSunsetWidgetState(type: false, customId: customId)
            return OASunriseSunsetWidget(state: sunsetState)
        case .elevationProfile:
            return /*ElevationProfileWidget(mapActivity: mapActivity)*/nil
        default:
            return nil /*PluginsHelper.createOABaseWidgetView(mapActivity: mapActivity, widgetType: widgetType)*/
        }
    }
    
    private func isWidgetCreationAllowed(widgetType: WidgetType) -> Bool {
        if widgetType == .altitudeMapCenter {
            let plugin = OAPlugin.getPlugin(OAOsmandDevelopmentPlugin.self) as? OAOsmandDevelopmentPlugin
            return plugin != nil && plugin!.is3DMapsEnabled()
        }
        return true
    }
}
