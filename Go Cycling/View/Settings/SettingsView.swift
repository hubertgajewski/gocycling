//
//  SettingsView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-04-17.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var cyclingStatus: CyclingStatus

    var body: some View {
        NavigationView {
            VStack {
                if (cyclingStatus.isCycling) {
                    Text("Certain sections are disabled while cycling is in progress. Please end the current cycling session to enable editing of all settings.")
                        .padding(.all, 10)
                }
                Form {
                    Section(header: Text("Customization")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.customizationSection)) {
                        ColourView()
                        ChangeAppIconView().environmentObject(IconNames())
                    }
                    .disabled(cyclingStatus.isCycling)
                    .navigationBarTitle("Settings", displayMode: .inline)
                    Section(header: Text("Cycling Metrics")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.cyclingMetricsSection)) {
                        UnitsView()
                    }
                    .disabled(cyclingStatus.isCycling)
                    Section(header: Text("Cycling History")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.cyclingHistorySection)) {
                        CyclingHistorySettingsView()
                    }
                    .disabled(cyclingStatus.isCycling)
                    Section(header: Text("Cycling")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.cyclingSection)) {
                        CyclingView()
                    }
                    .disabled(cyclingStatus.isCycling)
                    Section(header: Text("Sync")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.syncSection)) {
                        SyncSettingsView()
                    }
                    .disabled(cyclingStatus.isCycling)
                    Section(header: Text("About the app")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.aboutSection)) {
                        AboutAppView()
                    }
                    Section(header: Text("Support")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.supportSection)) {
                        SupportView()
                    }
                    Section(header: Text("Reset")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.resetSection)) {
                        ResetView()
                    }
                    .disabled(cyclingStatus.isCycling)
                    Section(header: Text("Privacy")
                        .accessibilityIdentifier(AccessibilityIdentifier.Settings.privacySection),
                            footer: Text("Analytics are completely anonymous and contain no personal or identifiable information. They help prioritize future improvements. You can opt out at any time.")
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier(AccessibilityIdentifier.Settings.privacyFooter)) {
                        PrivacySettingsView()
                    }
                }
                .navigationBarTitle(Text("Settings"))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibilityIdentifier("main-tab-settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
