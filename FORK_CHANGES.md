# Fork Changes

This repository is a fork of [AnthonyH93/GoCycling](https://github.com/AnthonyH93/GoCycling). This file tracks setup notes, maintenance changes, CI updates, and feature differences that are specific to this fork.

## Local Development

After cloning this repository, complete the fork-specific setup below before building in Xcode.

### TelemetryDeck Configuration

The app target references `TelemetryDeck.xcconfig` at the repository root for the optional TelemetryDeck App ID (`GoCyclingAppID` in `Go Cycling/Info.plist`). That file is gitignored.

```bash
cp TelemetryDeck.xcconfig.example TelemetryDeck.xcconfig
```

Leave `GoCyclingAppID` empty for local development without a TelemetryDeck account, or set an App ID from [TelemetryDeck](https://telemetrydeck.com) if you want analytics.

### Git Hooks

This repository commits local Git hooks in `.githooks`. Enable them once per clone:

```bash
git config core.hooksPath .githooks
```

The pre-commit hook checks staged Swift files under `Go CyclingTests/` and `Go CyclingUITests/` with `swift-format`. App source files under `Go Cycling/` are not part of this scoped formatting rollout yet.

### Code Signing

Upstream bundle identifiers and the author development team (`QMBJV5C74X`) belong to the original maintainer. To build on your machine:

1. Open `Go Cycling.xcodeproj` in Xcode and add your Apple ID under **Settings -> Accounts**.
2. For the **Go Cycling**, **Go CyclingTests**, and **Go CyclingUITests** targets, enable **Automatically manage signing** and select your **Development Team**.
3. Change each target **Bundle Identifier** from `com.hopkins.*` to a unique ID in your namespace, for example `com.example.GoCycling`.
4. If you change the app bundle ID, update the iCloud container in `Go Cycling/Go Cycling.entitlements` to match, for example `iCloud.com.example.GoCycling`, and let Xcode create the container for your team. In **Signing & Capabilities** for the **Go Cycling** app target, enable **iCloud** (CloudKit) and **HealthKit** if Xcode prompts or those features fail at runtime.

Simulator builds typically work with a free Personal Team once signing is configured.

## Continuous Integration

GitHub Actions runs on every push to `main` and on pull requests. Jobs run in a fail-fast sequence: **Swift format** → **SwiftPM unit tests** → **unit tests** and **UI smoke tests** in parallel. A formatting or SwiftPM failure does not start simulator jobs. When repository variable `CI_RUN_UNIT_TESTS` is `false`, SwiftPM and Xcode unit jobs are skipped and UI smoke may still run after format passes. Unit and UI simulator jobs are intentionally parallel after SwiftPM so UI feedback is not blocked on the iPhone 17 unit lane.

- **Swift format** - `swift-format` linting for `Go CyclingTests` and `Go CyclingUITests`
- **SwiftPM unit tests** - `swift test` for the package-compatible formatting unit-test slice
- **Unit tests** - `Go CyclingTests` on an iPhone simulator, with Xcode code coverage published to the workflow summary
- **UI smoke tests** - `Go CyclingUITests` on representative iPhone and iPad simulators across the hosted `macos-14`, `macos-15`, and `macos-26` runner lines

The hosted UI smoke matrix currently requests these simulators:

- `macos-14` - iPhone SE (3rd generation), iPad mini (6th generation)
- `macos-15` - iPhone 16, iPad (10th generation)
- `macos-26` - iPhone 17, iPad Pro 11-inch (M5)

CI copies `TelemetryDeck.xcconfig.example` to `TelemetryDeck.xcconfig` when the gitignored file is absent, so no TelemetryDeck account is required. Simulator builds pass `DEVELOPMENT_TEAM=` so no committed development team is needed.
CI also passes `-retry-tests-on-failure`, which retries failed tests using Xcode's default maximum of 3 iterations.
Unit-test coverage is generated from `TestResults/unit.xcresult` with `xcrun xccov`, summarized in the GitHub Actions run summary, and uploaded with the unit-test result bundle as a workflow artifact.
GitHub-hosted CI does not provide iOS/iPadOS 14, 15, or 16 simulator coverage on those runner lines; the deployment target, availability checks, and optional physical-device, self-hosted-runner, or device-cloud testing remain the compatibility path for those OS versions.

### Reproduce CI Locally

Reproduce the Swift formatting check locally:

```bash
xcrun swift-format lint --recursive --strict "Go CyclingTests" "Go CyclingUITests"
```

Reproduce the SwiftPM unit-test lane locally:

```bash
swift test
```

Reproduce the unit tests locally:

```bash
cp -n TelemetryDeck.xcconfig.example TelemetryDeck.xcconfig
mkdir -p TestResults
rm -rf TestResults/unit.xcresult
DEST=$(.github/scripts/ios-simulator-destination.sh iPhone 'iPhone 17')
xcodebuild \
  -project "Go Cycling.xcodeproj" \
  -scheme "Go Cycling" \
  -configuration Debug \
  -destination "$DEST" \
  -only-testing:"Go CyclingTests" \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults/unit.xcresult \
  -retry-tests-on-failure \
  DEVELOPMENT_TEAM= \
  test
```

Inspect the local unit-test coverage report:

```bash
xcrun xccov view --report TestResults/unit.xcresult
xcrun xccov view --report --json TestResults/unit.xcresult > TestResults/coverage.json
python3 .github/scripts/write-xccov-summary.py TestResults/coverage.json --target "Go Cycling.app"
```

Reproduce a UI smoke run, substituting the device name as needed:

```bash
DEST=$(.github/scripts/ios-simulator-destination.sh iPad 'iPad Pro 11-inch (M5)')
xcodebuild \
  -project "Go Cycling.xcodeproj" \
  -scheme "Go Cycling UI Smoke" \
  -configuration Debug \
  -destination "$DEST" \
  -only-testing:"Go CyclingUITests" \
  -retry-tests-on-failure \
  DEVELOPMENT_TEAM= \
  test
```

## Feature and Maintenance Differences

Current fork-specific differences include:

- Local build fixes for fork owners: `TelemetryDeck.xcconfig.example`, in-repository default alternate icon paths, generic signing guidance, and explicit `NSUbiquitousKeyValueStore` integer writes.
- Focused Swift Testing unit coverage for cycling record sorting, aggregation, unlocked-icon, and reset-statistics behavior, plus UI smoke coverage for the main Cycle, History, Statistics, and Settings tabs.
- UI testing support through the `-ui-testing` launch argument to avoid location authorization prompts during automated tests.
- A shared `Go Cycling` Xcode scheme for command-line and CI testing.
- A focused SwiftPM package slice for package-compatible formatting logic, declared over the existing Xcode-owned source and test directories so `swift test` complements the Xcode test action.
- GitHub Actions coverage for Swift formatting, SwiftPM unit tests, Xcode unit tests, unit-test code coverage summaries, and UI smoke tests.
- CI retries for failed XCTest and XCUITest cases via `-retry-tests-on-failure`.
- Hosted simulator coverage across selected GitHub-hosted macOS runner lines.
- Test-target `swift-format` enforcement in CI and the committed pre-commit hook.

Add future fork-only setup notes, CI changes, maintenance changes, and new feature differences here instead of expanding `README.md`.
