//
//  SensorAttributesUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 18.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import Charts

@objc(OASensorAttributesUtils)
@objcMembers
final class SensorAttributesUtils: NSObject {

    static let sensorGpxTags: [String] = [PointAttributes.sensorTagHeartRate, PointAttributes.sensorTagSpeed,
                                                 PointAttributes.sensorTagCadence, PointAttributes.sensorTagBikePower,
                                                 PointAttributes.sensorTagTemperature]

    static func hasHeartRateData(_ analysis: OAGPXTrackAnalysis) -> Bool {
        analysis.hasData(PointAttributes.sensorTagHeartRate)
    }

    static func hasSensorSpeedData(_ analysis: OAGPXTrackAnalysis) -> Bool {
        analysis.hasData(PointAttributes.sensorTagSpeed)
    }

    static func hasBikeCadenceData(_ analysis: OAGPXTrackAnalysis) -> Bool {
        analysis.hasData(PointAttributes.sensorTagCadence)
    }

    static func hasBikePowerData(_ analysis: OAGPXTrackAnalysis) -> Bool {
        analysis.hasData(PointAttributes.sensorTagBikePower)
    }

    static func hasTemperatureData(_ analysis: OAGPXTrackAnalysis) -> Bool {
        analysis.hasData(PointAttributes.sensorTagTemperature)
    }

    @objc static func getAvailableGPXDataSetTypes(analysis: OAGPXTrackAnalysis, availableTypes: NSMutableArray) {
        if Self.hasSensorSpeedData(analysis) {
            availableTypes.add([NSNumber(value: GPXDataSetType.sensorSpeed.rawValue)])
        }
        if Self.hasHeartRateData(analysis) {
            availableTypes.add([NSNumber(value: GPXDataSetType.sensorHeartRate.rawValue)])
        }
        if Self.hasBikePowerData(analysis) {
            availableTypes.add([NSNumber(value: GPXDataSetType.sensorBikePower.rawValue)])
        }
        if Self.hasBikeCadenceData(analysis) {
            availableTypes.add([NSNumber(value: GPXDataSetType.sensorBikeCadence.rawValue)])
        }
        if Self.hasTemperatureData(analysis) {
            availableTypes.add([NSNumber(value: GPXDataSetType.sensorTemperature.rawValue)])
        }
    }

    @objc static func getOrderedLineDataSet(chart: LineChartView,
                                                   analysis: OAGPXTrackAnalysis,
                                                   graphType: GPXDataSetType,
                                                   axisType: GPXDataSetAxisType,
                                                   calcWithoutGaps: Bool,
                                                   useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        switch graphType {
        case .sensorSpeed where hasSensorSpeedData(analysis):
            return createSensorDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
        case .sensorHeartRate where hasHeartRateData(analysis):
            return createSensorDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
        case .sensorBikePower where hasBikePowerData(analysis):
            return createSensorDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
        case .sensorBikeCadence where hasBikeCadenceData(analysis):
            return createSensorDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
        case .sensorTemperature where hasTemperatureData(analysis):
            return createSensorDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
        default:
            return nil
        }
    }

    static func createSensorDataSet(chart: LineChartView,
                                          analysis: OAGPXTrackAnalysis,
                                          graphType: GPXDataSetType,
                                          axisType: GPXDataSetAxisType,
                                          useRightAxis: Bool,
                                          drawFilled: Bool,
                                          calcWithoutGaps:Bool) -> GpxUIHelper.OrderedLineDataSet {
        let divX: Double = GpxUIHelper.getDivX(lineChart: chart, analysis: analysis, axisType: axisType, calcWithoutGaps: calcWithoutGaps)

        let pair: Pair<Double, Double>? = GpxUIHelper.getScalingY(graphType)
        let mulY: Double = pair?.first ?? 1
        let divY: Double = pair?.second ?? Double.nan

        let yAxis: YAxis = GpxUIHelper.getYAxis(chart: chart, textColor: graphType.getTextColor(), useRightAxis: useRightAxis)
        yAxis.axisMinimum = 0

        let values: [ChartDataEntry] = GpxUIHelper.getPointAttributeValues(key: graphType.getDatakey(),
                                                                           pointAttributes: analysis.pointAttributes as! [PointAttributes],
                                                                           axisType: axisType,
                                                                           divX: divX,
                                                                           mulY: mulY,
                                                                           divY: divY,
                                                                           calcWithoutGaps: calcWithoutGaps)
        let dataSet: GpxUIHelper.OrderedLineDataSet = GpxUIHelper.OrderedLineDataSet.init(entries: values, label: "", dataSetType: graphType, dataSetAxisType: axisType)
        let mainUnitY: String = graphType.getMainUnitY()
        yAxis.valueFormatter = GpxUIHelper.ValueFormatter(formatX: dataSet.yMax < 3 ? "%.0f" : nil, unitsX: mainUnitY)
        
        dataSet.divX = divX
        dataSet.units = mainUnitY
        
        let color: UIColor = graphType.getFillColor()
        GpxUIHelper.setupDataSet(dataSet: dataSet, color: color, fillColor: color, drawFilled: drawFilled, drawCircles: false, useRightAxis: useRightAxis)
        
        return dataSet
    }
}
