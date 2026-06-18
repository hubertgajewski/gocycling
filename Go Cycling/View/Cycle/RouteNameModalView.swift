//
//  RouteNameModalView.swift
//  Go Cycling
//
//  Created by Anthony Hopkins on 2021-05-15.
//

import SwiftUI

struct RouteNameModalView: View {
    let persistenceController = PersistenceController.shared

    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.presentationMode) var presentationMode

    @Binding var showEditModal: Bool

    @State private var selectedNameIndex = 0
    @State private var namedRoutesViewSelection = NamedRoutesViewSelection.new
    
    @State private var typedRouteName: String = ""
    
    @ObservedObject var routeNamingViewModel = RouteNamingViewModel()
    
    private var bikeRideToEdit: BikeRide?
    // Cycle tab passes the saved ride directly so naming cannot attach to
    // another recently saved route.
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
            if (bikeRideToEdit != nil && bikeRideToEdit?.cyclingRouteName != "Uncategorized") {
                self.selectedNameIndex = routeNamingViewModel.routeNames.firstIndex(of: bikeRideToEdit!.cyclingRouteName)!
            }
            else {
                self.selectedNameIndex = 0
            }
        }
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
        
        // This means that we are in the Cycle tab
        if let ride = self.bikeRideToName {
            updateBikeRideRouteName(ride: ride, routeName: routeName)
            presentationMode.wrappedValue.dismiss()
            self.showEditModal = false
        }
        else if (self.bikeRideToEdit == nil) {
            // Older Cycle-tab presentations still fall back to the latest ride,
            // but the guard avoids a crash if History has not loaded a ride yet.
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

    // Keep all route-name writes on the same path so the direct saved-ride flow
    // and the existing edit/remove flows cannot drift in which ride fields they copy.
    private func updateBikeRideRouteName(ride: BikeRide, routeName: String) {
        persistenceController.updateBikeRideRouteName(
            existingBikeRide: ride,
            latitudes: ride.cyclingLatitudes,
            longitudes: ride.cyclingLongitudes,
            speeds: ride.cyclingSpeeds,
            distance: ride.cyclingDistance,
            elevations: ride.cyclingElevations,
            startTime: ride.cyclingStartTime,
            time: ride.cyclingTime,
            routeName: routeName)
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
