//
//  BikeRideListViewModelTests.swift
//  Go CyclingTests
//

import CoreData
import Foundation
import Testing

@testable import Go_Cycling

private typealias RideCategory = Go_Cycling.Category

@Suite("BikeRideListViewModel", .serialized)
@MainActor
struct BikeRideListViewModelTests {

  @Test("updates rides and state for each sort selection")
  func updatesRidesAndStateForEachSortSelection() async {
    let snapshot = await PersistedStoreSnapshot(keys: viewModelStoreKeys)
    defer { snapshot.restore() }

    let context = PersistenceController(inMemory: true).container.viewContext
    let short = makeListRide(
      in: context,
      name: "short",
      distance: 1_000,
      start: listDate(2026, 6, 15),
      time: 600
    )
    let medium = makeListRide(
      in: context,
      name: "medium",
      distance: 2_000,
      start: listDate(2026, 6, 16),
      time: 900
    )
    let long = makeListRide(
      in: context,
      name: "long",
      distance: 3_000,
      start: listDate(2026, 6, 17),
      time: 1_200
    )
    let original = [medium, long, short]
    let viewModel = makeListViewModel(rides: original)

    viewModel.bikeRides = original
    viewModel.sortByDistanceAscending()
    #expect(viewModel.currentSortChoice == SortChoice.distanceAscending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["short", "medium", "long"])

    viewModel.bikeRides = original
    viewModel.sortByDistanceDescending()
    #expect(viewModel.currentSortChoice == SortChoice.distanceDescending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["long", "medium", "short"])

    viewModel.bikeRides = original
    viewModel.sortByDateAscending()
    #expect(viewModel.currentSortChoice == SortChoice.dateAscending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["short", "medium", "long"])

    viewModel.bikeRides = original
    viewModel.sortByDateDescending()
    #expect(viewModel.currentSortChoice == SortChoice.dateDescending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["long", "medium", "short"])

    viewModel.bikeRides = original
    viewModel.sortByTimeAscending()
    #expect(viewModel.currentSortChoice == SortChoice.timeAscending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["short", "medium", "long"])

    viewModel.bikeRides = original
    viewModel.sortByTimeDescending()
    #expect(viewModel.currentSortChoice == SortChoice.timeDescending)
    #expect(viewModel.bikeRides.map { $0.cyclingRouteName } == ["long", "medium", "short"])
  }

  @Test("returns display title and sort descriptor for current sort")
  func returnsDisplayTitleAndSortDescriptorForCurrentSort() async {
    let snapshot = await PersistedStoreSnapshot(keys: viewModelStoreKeys)
    defer { snapshot.restore() }

    let viewModel = makeListViewModel(rides: [])
    let cases: [(SortChoice, String, String, Bool)] = [
      (.distanceAscending, "Distance ↑", "cyclingDistance", true),
      (.distanceDescending, "Distance ↓", "cyclingDistance", false),
      (.dateAscending, "Date ↑", "cyclingStartTime", true),
      (.dateDescending, "Date ↓", "cyclingStartTime", false),
      (.timeAscending, "Time ↑", "cyclingTime", true),
      (.timeDescending, "Time ↓", "cyclingTime", false),
    ]

    for (choice, title, key, ascending) in cases {
      viewModel.currentSortChoice = choice
      let descriptor = viewModel.getSortDescriptor()

      #expect(viewModel.getSortActionSheetTitle() == title)
      #expect(descriptor.key == key)
      #expect(descriptor.ascending == ascending)
    }
  }

  @Test("manages selected route names and category availability")
  func managesSelectedRouteNamesAndCategoryAvailability() async {
    let snapshot = await PersistedStoreSnapshot(keys: viewModelStoreKeys)
    defer { snapshot.restore() }

    let categories = [
      RideCategory(name: "All", number: 3),
      RideCategory(name: "Uncategorized", number: 1),
      RideCategory(name: "Training", number: 2),
    ]
    var replacementCategories = [RideCategory(name: "All", number: 1)]
    let viewModel = makeListViewModel(
      rides: [],
      categories: categories,
      currentName: "Training",
      categoryProvider: { replacementCategories }
    )

    #expect(viewModel.validateCategory(name: "Training"))
    #expect(!viewModel.validateCategory(name: "Missing"))
    #expect(viewModel.currentName == "Training")

    viewModel.setCurrentName(name: "Uncategorized")
    #expect(viewModel.currentName == "Uncategorized")
    #expect(viewModel.getFilterActionSheetTitle() == "Filter")
    #expect(viewModel.editEnabledCheck())
    #expect(viewModel.filterEnabledCheck())

    replacementCategories = [
      RideCategory(name: "All", number: 2),
      RideCategory(name: "Uncategorized", number: 2),
    ]
    viewModel.updateCategories()
    #expect(viewModel.categories.map { $0.name } == ["All", "Uncategorized"])
    #expect(viewModel.currentName == "Uncategorized")
    #expect(!viewModel.editEnabledCheck())

    replacementCategories = []
    viewModel.updateCategories()
    #expect(viewModel.categories.isEmpty)
    #expect(viewModel.currentName == "")
    #expect(!viewModel.editEnabledCheck())
    #expect(!viewModel.filterEnabledCheck())
  }

  @Test("clears invalid selected route during initialization")
  func clearsInvalidSelectedRouteDuringInitialization() async {
    let snapshot = await PersistedStoreSnapshot(keys: viewModelStoreKeys)
    defer { snapshot.restore() }

    let viewModel = makeListViewModel(
      rides: [],
      categories: [RideCategory(name: "All", number: 1)],
      currentName: "Missing"
    )

    #expect(viewModel.currentName == "")
  }
}

private let viewModelStoreKeys = [
  iCloudSyncPreferenceKey,
  ReviewManager.reviewCountKey,
  ReviewManager.reviewRequestVersionKey,
  ReviewManager.completedRouteKey,
]

private func makeListViewModel(
  rides: [BikeRide],
  categories: [RideCategory] = [RideCategory(name: "All", number: 0)],
  currentSortChoice: SortChoice = .dateDescending,
  currentName: String = "",
  categoryProvider: @escaping () -> [RideCategory] = { [RideCategory(name: "All", number: 0)] }
) -> BikeRideListViewModel {
  BikeRideListViewModel(
    bikeRides: rides,
    categories: categories,
    currentSortChoice: currentSortChoice,
    currentName: currentName,
    categoryProvider: categoryProvider,
    reviewActionsEnabled: false
  )
}

private func makeListRide(
  in context: NSManagedObjectContext,
  name: String,
  distance: Double,
  start: Date,
  time: Double
) -> BikeRide {
  let entity = NSEntityDescription.entity(forEntityName: "BikeRide", in: context)!
  let ride = BikeRide(entity: entity, insertInto: context)
  ride.cyclingRouteName = name
  ride.cyclingDistance = distance
  ride.cyclingStartTime = start
  ride.cyclingTime = time
  ride.cyclingSpeeds = []
  ride.cyclingLatitudes = []
  ride.cyclingLongitudes = []
  ride.cyclingElevations = []
  return ride
}

private func listDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
  var components = DateComponents()
  components.calendar = Calendar(identifier: .gregorian)
  components.timeZone = TimeZone(secondsFromGMT: 0)
  components.year = year
  components.month = month
  components.day = day
  return components.date!
}
