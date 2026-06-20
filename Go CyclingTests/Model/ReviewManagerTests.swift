//
//  ReviewManagerTests.swift
//  Go CyclingTests
//

import Foundation
import Testing

@testable import Go_Cycling

@Suite("ReviewManager", .serialized)
struct ReviewManagerTests {

  @Test("increments review-worthy count and caps at three")
  func incrementsReviewWorthyCountAndCapsAtThree() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    defaults.set(0, forKey: ReviewManager.reviewCountKey)

    ReviewManager.incrementReviewWorthyCount()
    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 1)

    ReviewManager.incrementReviewWorthyCount()
    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 2)

    ReviewManager.incrementReviewWorthyCount()
    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 3)

    ReviewManager.incrementReviewWorthyCount()
    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 3)
  }

  @Test("sets completed route state idempotently")
  func setsCompletedRouteStateIdempotently() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    defaults.set(false, forKey: ReviewManager.completedRouteKey)

    ReviewManager.completedRoute()
    #expect(defaults.bool(forKey: ReviewManager.completedRouteKey))

    ReviewManager.completedRoute()
    #expect(defaults.bool(forKey: ReviewManager.completedRouteKey))
  }

  @Test("skips review request when no route has been completed")
  func skipsReviewRequestWhenNoRouteHasBeenCompleted() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    defaults.set(3, forKey: ReviewManager.reviewCountKey)
    defaults.set(false, forKey: ReviewManager.completedRouteKey)

    ReviewManager.requestReviewIfAppropriate()

    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 3)
    #expect(defaults.string(forKey: ReviewManager.reviewRequestVersionKey) == nil)
  }

  @Test("skips review request when review-worthy count is below threshold")
  func skipsReviewRequestWhenReviewWorthyCountIsBelowThreshold() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    defaults.set(true, forKey: ReviewManager.completedRouteKey)
    defaults.set(1, forKey: ReviewManager.reviewCountKey)

    ReviewManager.requestReviewIfAppropriate()

    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 1)
    #expect(defaults.string(forKey: ReviewManager.reviewRequestVersionKey) == nil)
  }

  @Test("skips review request when current version was already requested")
  func skipsReviewRequestWhenCurrentVersionWasAlreadyRequested() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    let bundleVersionKey = kCFBundleVersionKey as String
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: bundleVersionKey) as? String
    defaults.set(true, forKey: ReviewManager.completedRouteKey)
    defaults.set(3, forKey: ReviewManager.reviewCountKey)
    if let currentVersion {
      defaults.set(currentVersion, forKey: ReviewManager.reviewRequestVersionKey)
    }

    ReviewManager.requestReviewIfAppropriate()

    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 3)
    if let currentVersion {
      #expect(defaults.string(forKey: ReviewManager.reviewRequestVersionKey) == currentVersion)
    }
  }

  @Test("resets review counter when review request preconditions are met")
  func resetsReviewCounterWhenReviewRequestPreconditionsAreMet() async {
    let snapshot = await PersistedStoreSnapshot(keys: reviewManagerStoreKeys)
    defer { snapshot.restore() }

    let defaults = UserDefaults.standard
    let bundleVersionKey = kCFBundleVersionKey as String
    defaults.set(true, forKey: ReviewManager.completedRouteKey)
    defaults.set(3, forKey: ReviewManager.reviewCountKey)
    defaults.removeObject(forKey: ReviewManager.reviewRequestVersionKey)

    ReviewManager.requestReviewIfAppropriate()

    #expect(defaults.integer(forKey: ReviewManager.reviewCountKey) == 0)
    #expect(
      defaults.string(forKey: ReviewManager.reviewRequestVersionKey)
        == Bundle.main.object(forInfoDictionaryKey: bundleVersionKey) as? String
    )
  }

  @Test("returns App Store product and write-review URLs")
  func returnsAppStoreProductAndWriteReviewURLs() throws {
    #expect(
      ReviewManager.getProductURL().absoluteString == "https://apps.apple.com/app/id1565861313")

    let writeReviewURL = try #require(ReviewManager.getWriteReviewURL())
    #expect(
      writeReviewURL.absoluteString
        == "https://apps.apple.com/app/id1565861313?action=write-review")
  }
}

private let reviewManagerStoreKeys = [
  ReviewManager.reviewCountKey,
  ReviewManager.reviewRequestVersionKey,
  ReviewManager.completedRouteKey,
]
