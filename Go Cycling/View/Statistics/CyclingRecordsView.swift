//
//  CyclingRecordsView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-08-30.
//

import SwiftUI

struct CyclingRecordsView: View {
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var records: CyclingRecords
    
    var body: some View {
        Section(
            header: Text(RecordsFormatting.headerStrings[0])
                .accessibilityIdentifier(AccessibilityIdentifier.Statistics.cyclingRecordsSection),
            footer: Text(RecordsFormatting.getCyclingRecordsFooterText(usingMetric: preferences.usingMetric))
                .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordsFooter)
        ) {
            VStack {
                HStack {
                    Text("Single Route Records")
                        .font(.headline)
                        .foregroundColor(Color(UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted)))
                        .accessibilityIdentifier(AccessibilityIdentifier.Statistics.singleRouteRecordsHeader)
                    Spacer()
                }
                CyclingSingleRecordView(recordValue: MetricsFormatting.formatDistance(distance: records.longestCyclingDistance, usingMetric: preferences.usingMetric), recordName: RecordsFormatting.recordsStrings[3], recordDate: RecordsFormatting.formatOptionalDate(date: records.longestCyclingDistanceDate), firstEntry: true)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordLongestDistance)
                CyclingSingleRecordView(recordValue: MetricsFormatting.formatTime(time: records.longestCyclingTime), recordName: RecordsFormatting.recordsStrings[4], recordDate: RecordsFormatting.formatOptionalDate(date: records.longestCyclingTimeDate), firstEntry: false)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordLongestTime)
                CyclingSingleRecordView(recordValue: MetricsFormatting.formatSingleSpeed(speed: records.fastestAverageSpeed, usingMetric: preferences.usingMetric), recordName: RecordsFormatting.recordsStrings[5], recordDate: RecordsFormatting.formatOptionalDate(date: records.fastestAverageSpeedDate), firstEntry: false)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordBestSpeed)
            }
            VStack {
                HStack {
                    Text("Cummulative Records")
                        .font(.headline)
                        .foregroundColor(Color(UserPreferences.convertColourChoiceToUIColor(colour: preferences.colourChoiceConverted)))
                        .accessibilityIdentifier(AccessibilityIdentifier.Statistics.cumulativeRecordsHeader)
                    Spacer()
                }
                CyclingSingleRecordView(recordValue: MetricsFormatting.formatDistance(distance: records.totalCyclingDistance, usingMetric: preferences.usingMetric), recordName: RecordsFormatting.recordsStrings[0], recordDate: nil, firstEntry: true)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordTotalDistance)
                CyclingSingleRecordView(recordValue: MetricsFormatting.formatTime(time: records.totalCyclingTime), recordName: RecordsFormatting.recordsStrings[1], recordDate: nil, firstEntry: false)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordTotalTime)
                CyclingSingleRecordView(recordValue: "\(records.totalCyclingRoutes)", recordName: RecordsFormatting.recordsStrings[2], recordDate: nil, firstEntry: false)
                    .accessibilityIdentifier(AccessibilityIdentifier.Statistics.recordTotalRoutes)
            }
        }
    }
}

struct CyclingRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        CyclingRecordsView()
    }
}
