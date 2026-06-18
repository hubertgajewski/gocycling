//
//  GoCyclingUITests.m
//  Go CyclingUITests
//
//  Created by Anthony Hopkins on 2021-03-14.
//

#import <XCTest/XCTest.h>

static NSString *const UITestingLaunchArgument = @"-ui-testing";
static NSString *const UITestingRouteSaveFixtureArgument = @"-ui-testing-route-save-fixture";

typedef NS_ENUM(NSInteger, MainTab) {
  MainTabCycle,
  MainTabHistory,
  MainTabStatistics,
  MainTabSettings
};

@interface GoCyclingUITests : XCTestCase
@end

@implementation GoCyclingUITests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)testMainTabBarNavigatesToAllTabs {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ UITestingLaunchArgument ];
  [app launch];

  XCTAssertTrue([self waitForMainChromeInApplication:app], @"Expected Cycle tab chrome after launch");

  XCTAssertTrue([[self tabContent:MainTabCycle inApplication:app] waitForExistenceWithTimeout:5]);
  XCTAssertTrue([app.buttons[@"Start"] waitForExistenceWithTimeout:3]);

  [self tapTab:MainTabHistory inApplication:app];
  XCTAssertTrue([[self tabContent:MainTabHistory inApplication:app] waitForExistenceWithTimeout:5]);

  [self tapTab:MainTabStatistics inApplication:app];
  XCTAssertTrue([[self tabContent:MainTabStatistics inApplication:app] waitForExistenceWithTimeout:5]);

  [self tapTab:MainTabSettings inApplication:app];
  XCTAssertTrue([[self tabContent:MainTabSettings inApplication:app] waitForExistenceWithTimeout:5]);
}

- (void)testRouteSaveFixtureCreatesHistoryRide {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ UITestingLaunchArgument, UITestingRouteSaveFixtureArgument ];
  [app launch];

  XCTAssertTrue([self waitForMainChromeInApplication:app], @"Expected Cycle tab chrome after launch");

  [self tapTab:MainTabHistory inApplication:app];
  XCTAssertTrue([[self tabContent:MainTabHistory inApplication:app] waitForExistenceWithTimeout:5]);
  XCTAssertTrue([app.staticTexts[@"Distance Cycled"] waitForExistenceWithTimeout:8]);

  [self tapTab:MainTabCycle inApplication:app];
  XCTAssertTrue([[self tabContent:MainTabCycle inApplication:app] waitForExistenceWithTimeout:5]);
}

- (BOOL)waitForMainChromeInApplication:(XCUIApplication *)app {
  if ([app.tabBars.firstMatch waitForExistenceWithTimeout:2]) {
    return YES;
  }
  return [[self tabButton:MainTabCycle inApplication:app] waitForExistenceWithTimeout:8];
}

- (XCUIElement *)tabButton:(MainTab)tab inApplication:(XCUIApplication *)app {
  NSString *label = [self englishLabelForTab:tab];
  XCUIElement *tabBarByLabel = app.tabBars.buttons[label];
  if (tabBarByLabel.exists) {
    return tabBarByLabel;
  }

  NSString *imageIdentifier = [self imageIdentifierForTab:tab];
  XCUIElement *tabBarByIdentifier = app.tabBars.buttons[imageIdentifier];
  if (tabBarByIdentifier.exists) {
    return tabBarByIdentifier;
  }

  return [[app.buttons matchingIdentifier:imageIdentifier] firstMatch];
}

- (XCUIElement *)tabContent:(MainTab)tab inApplication:(XCUIApplication *)app {
  return [[[app descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:[self contentIdentifierForTab:tab]] firstMatch];
}

- (void)tapTab:(MainTab)tab inApplication:(XCUIApplication *)app {
  XCUIElement *button = [self tabButton:tab inApplication:app];
  XCTAssertTrue([button waitForExistenceWithTimeout:3]);
  [button tap];
}

- (NSString *)imageIdentifierForTab:(MainTab)tab {
  switch (tab) {
    case MainTabCycle:
      return @"bicycle";
    case MainTabHistory:
      return @"clock.arrow.circlepath";
    case MainTabStatistics:
      return @"chart.bar.xaxis";
    case MainTabSettings:
      return @"gear";
  }
}

- (NSString *)englishLabelForTab:(MainTab)tab {
  switch (tab) {
    case MainTabCycle:
      return @"Cycle";
    case MainTabHistory:
      return @"History";
    case MainTabStatistics:
      return @"Statistics";
    case MainTabSettings:
      return @"Settings";
  }
}

- (NSString *)contentIdentifierForTab:(MainTab)tab {
  switch (tab) {
    case MainTabCycle:
      return @"main-tab-cycle";
    case MainTabHistory:
      return @"main-tab-history";
    case MainTabStatistics:
      return @"main-tab-statistics";
    case MainTabSettings:
      return @"main-tab-settings";
  }
}

@end
