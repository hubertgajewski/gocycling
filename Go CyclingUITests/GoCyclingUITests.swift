//
//  GoCyclingUITests.swift
//  Go CyclingUITests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

import XCTest

// CI scaffolding: minimal UI smoke coverage until a follow-up issue refactors tests.
class GoCyclingUITests: XCTestCase {

    private enum MainTab {
        case cycle
        case history
        case statistics
        case settings

        var imageIdentifier: String {
            switch self {
            case .cycle: return "bicycle"
            case .history: return "clock.arrow.circlepath"
            case .statistics: return "chart.bar.xaxis"
            case .settings: return "gear"
            }
        }

        var englishLabel: String {
            switch self {
            case .cycle: return "Cycle"
            case .history: return "History"
            case .statistics: return "Statistics"
            case .settings: return "Settings"
            }
        }

        var contentIdentifier: String {
            switch self {
            case .cycle: return "main-tab-cycle"
            case .history: return "main-tab-history"
            case .statistics: return "main-tab-statistics"
            case .settings: return "main-tab-settings"
            }
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainTabBarNavigatesToAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = [UITesting.launchArgument]
        app.launch()

        XCTAssertTrue(waitForMainChrome(in: app), "Expected Cycle tab chrome after launch")

        XCTAssertTrue(tabContent(.cycle, in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 3))

        tapTab(.history, in: app)
        XCTAssertTrue(tabContent(.history, in: app).waitForExistence(timeout: 5))

        tapTab(.statistics, in: app)
        XCTAssertTrue(tabContent(.statistics, in: app).waitForExistence(timeout: 5))

        tapTab(.settings, in: app)
        XCTAssertTrue(tabContent(.settings, in: app).waitForExistence(timeout: 5))
    }

    /// iPhone uses a bottom `TabBar`; iPad uses nested floating tab item buttons.
    private func waitForMainChrome(in app: XCUIApplication) -> Bool {
        if app.tabBars.firstMatch.waitForExistence(timeout: 2) {
            return true
        }
        return tabButton(.cycle, in: app).waitForExistence(timeout: 8)
    }

    private func tabButton(_ tab: MainTab, in app: XCUIApplication) -> XCUIElement {
        let tabBarByLabel = app.tabBars.buttons[tab.englishLabel]
        if tabBarByLabel.exists {
            return tabBarByLabel.firstMatch
        }
        let tabBarByIdentifier = app.tabBars.buttons[tab.imageIdentifier]
        if tabBarByIdentifier.exists {
            return tabBarByIdentifier.firstMatch
        }
        return app.buttons.matching(identifier: tab.imageIdentifier).firstMatch
    }

    private func tabContent(_ tab: MainTab, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: tab.contentIdentifier).firstMatch
    }

    private func tapTab(_ tab: MainTab, in app: XCUIApplication) {
        let button = tabButton(tab, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
    }
}
