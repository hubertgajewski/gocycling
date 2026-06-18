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
