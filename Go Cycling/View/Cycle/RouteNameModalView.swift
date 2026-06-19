//
//  RouteNameModalView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-05-15.
//

import SwiftUI

struct RouteNameModalView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.presentationMode) var presentationMode

    @Binding var showEditModal: Bool

    @State private var selectedNameIndex = 0
    @State private var namedRoutesViewSelection = NamedRoutesViewSelection.new
    
    @State private var typedRouteName: String = ""
    
    @ObservedObject var routeNamingViewModel = RouteNamingViewModel()
    
    private var bikeRideToEdit: BikeRide?
    // Route-naming UI tests pass the Cycle-tab saved ride directly so a delayed
    // sheet cannot rename another recently saved route.
    private var bikeRideToName: BikeRide?
    
    let telemetryManager = TelemetryManager.sharedTelemetryManager
    let telemetryTab = TelemetryTab.Cycle
    
    init(showEditModal: Binding<Bool>, bikeRideToEdit: BikeRide?, bikeRideToName: BikeRide? = nil) {
        if (bikeRideToEdit != nil) {
            self.bikeRideToEdit = bikeRideToEdit
        }
        self.bikeRideToName = bikeRideToName
        self._showEditModal = showEditModal
    }
    
    var body: some View {
        VStack {
            Text("Categorize Your Route")
                .font(.headline)
                .padding()
            
            Picker("Selected Category", selection: $namedRoutesViewSelection) {
                Text("Create a New Category").tag(NamedRoutesViewSelection.new)
                Text("Use an Existing Category").tag(NamedRoutesViewSelection.existing)
            }
            .pickerStyle(.segmented)
            .padding(EdgeInsets.init(top: 0, leading: 10, bottom: 10, trailing: 10))
            
            switch namedRoutesViewSelection {
            case .new:
                Text("Enter your new category name")
                    
                TextField("Category Name", text: $typedRouteName)
                    .border(Color(UIColor.separator))
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                // Extra option for existing routes where the category can be removed
                if (self.bikeRideToEdit != nil) {
                    Divider()
                    Button (action: {self.removeCategoryPressed()}) {
                        Text("Remove From Category")
                            .foregroundColor(Color.red)
                    }
                    .padding()
                }
                Divider()
                Button (action: {self.savePressed()}) {
                    Text("Save")
                }
                .disabled(!((self.typedRouteName.count > 0)))
                .padding()
                Divider()
                Button (action: {
                    presentationMode.wrappedValue.dismiss()

                    if (self.bikeRideToEdit == nil) {
                        telemetryManager.sendCyclingSignal(
                            tab: telemetryTab,
                            action: TelemetryCyclingAction.Save
                        )
                    }
                }) {
                    Text(self.bikeRideToEdit == nil ? "Save Without a Category" : "Cancel")
                        .bold()
                }
                .padding()
                Divider()
            case .existing:
                if (routeNamingViewModel.routeNames.count > 0) {
                    List {
                        ForEach(0 ..< routeNamingViewModel.routeNames.count, id: \.self) { index in
                        Button(action: {
                            self.selectedNameIndex = index
                        }) {
                            HStack {
                                Text(self.routeNamingViewModel.routeNames[index])
                                Spacer()
                                if self.selectedNameIndex == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .foregroundColor(.primary)
                        }
                        }
                    }
                    .listStyle(.plain)
                }
                else {
                    Text("There are no saved categories.")
                }
                Spacer()
                // Extra option for existing routes where the category can be removed
                if (self.bikeRideToEdit != nil) {
                    Divider()
                    Button (action: {self.removeCategoryPressed()}) {
                        Text("Remove From Category")
                            .foregroundColor(Color.red)
                    }
                    .padding()
                }
                Divider()
                Button (action: {self.savePressed()}) {
                    Text("Save")
                }
                .padding()
                .disabled(!(self.routeNamingViewModel.routeNames.count > 0))
                Divider()
                if (self.bikeRideToEdit != nil) {
                    Button (action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cancel")
                            .bold()
                    }
                    .padding()
                    Divider()
                }
            }
        }
        .onAppear {
            routeNamingViewModel.useBikeRideContext(managedObjectContext)
            if (bikeRideToEdit != nil && bikeRideToEdit?.cyclingRouteName != "Uncategorized") {
                guard let selectedIndex = Self.selectedExistingRouteIndex(
                    editingRouteName: bikeRideToEdit!.cyclingRouteName,
                    routeNames: routeNamingViewModel.routeNames
                ) else {
                    // Route-naming UI tests need selected-context drift to fail
                    // closed; guessing index 0 can rename a route into the wrong
                    // category.
                    presentationMode.wrappedValue.dismiss()
                    self.showEditModal = false
                    return
                }
                self.selectedNameIndex = selectedIndex
            }
            else {
                self.selectedNameIndex = 0
            }
        }
    }

    // Unit tests need this selection rule outside the SwiftUI lifecycle so
    // route-editing can verify that a missing category is rejected instead of
    // silently mapped to another route name.
    static func selectedExistingRouteIndex(
        editingRouteName: String,
        routeNames: [String]
    ) -> Int? {
        if editingRouteName != "Uncategorized" {
            return routeNames.firstIndex(of: editingRouteName)
        }
        return 0
    }
    
    func savePressed() {
        var routeName = ""
        switch namedRoutesViewSelection {
        case .new:
            routeName = typedRouteName
            
            telemetryManager.sendCyclingSignal(
                tab: telemetryTab,
                action: TelemetryCyclingAction.NewSave
            )
        case .existing:
            routeName = self.routeNamingViewModel.routeNames[self.selectedNameIndex]
            
            telemetryManager.sendCyclingSignal(
                tab: telemetryTab,
                action: TelemetryCyclingAction.ExistingSave
            )
        }
        
        // Route-naming UI tests need the exact Cycle-tab saved ride; the
        // latest-History fallback is kept only for older presentations.
        if let ride = self.bikeRideToName {
            updateBikeRideRouteName(ride: ride, routeName: routeName)
            presentationMode.wrappedValue.dismiss()
            self.showEditModal = false
        }
        else if (self.bikeRideToEdit == nil) {
            // UI tests can open the legacy path before History has rows, so fail
            // closed instead of crashing or guessing a different route.
            guard let ride = self.routeNamingViewModel.allBikeRides.last else {
                presentationMode.wrappedValue.dismiss()
                self.showEditModal = false
                return
            }
            // Route name should be Uncategorized at this point
            if (ride.cyclingRouteName == "Uncategorized") {
                updateBikeRideRouteName(ride: ride, routeName: routeName)
            }
            presentationMode.wrappedValue.dismiss()
            self.showEditModal = false
        }
        else {
            let ride = self.bikeRideToEdit!
            updateBikeRideRouteName(ride: ride, routeName: routeName)
            presentationMode.wrappedValue.dismiss()
            self.showEditModal = false
        }
    }
    
    func removeCategoryPressed() {
        let ride = self.bikeRideToEdit!
        updateBikeRideRouteName(ride: ride, routeName: "Uncategorized")
        presentationMode.wrappedValue.dismiss()
        self.showEditModal = false
    }

    // Route-naming tests need one update path so a naming flow cannot copy a
    // different field set while only the category should change.
    private func updateBikeRideRouteName(ride: BikeRide, routeName: String) {
        // Route-naming UI tests need the BikeRide updated in its selected launch
        // context; shared persistence can rename a different store than the UI shows.
        PersistenceController.updateBikeRideRouteName(
            existingBikeRide: ride,
            routeName: routeName
        )
    }
}

// Used for the picker
enum NamedRoutesViewSelection: String, CaseIterable, Identifiable {
    case new
    case existing

    var id: String { self.rawValue }
}

//struct RouteNameModalView_Previews: PreviewProvider {
//    static var previews: some View {
//        RouteNameModalView()
//    }
//}
