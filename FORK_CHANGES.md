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

GitHub Actions runs on every push to `main` and on pull requests. Jobs run in a fail-fast sequence: **Swift format** → **SwiftPM unit tests** → **unit tests** and **UI tests** in parallel. A formatting or SwiftPM failure does not start simulator jobs. When repository variable `CI_RUN_UNIT_TESTS` is `false`, SwiftPM and Xcode unit jobs are skipped and UI tests may still run after format passes. Unit and UI simulator jobs are intentionally parallel after SwiftPM so UI feedback is not blocked on the iPhone 17 unit lane.

- **Swift format** - `swift-format` linting for `Go CyclingTests` and `Go CyclingUITests`
- **SwiftPM unit tests** - `swift test` for the package-compatible formatting unit-test slice
- **Unit tests** - `Go CyclingTests` on an iPhone simulator, with code coverage collected for later merge
- **UI tests** - `Go CyclingUITests` on representative iPhone and iPad simulators across the hosted `macos-14`, `macos-15`, and `macos-26` runner lines, with a **35-minute** job timeout per matrix entry. CI runs the **Smoke** test plan by default (`Go Cycling UI Smoke`); set `CI_RUN_UI_REGRESSION` to `true` or dispatch with `run_regression: true` for the **Regression** plan (`Go Cycling UI Regression`) on the same matrix. Regression runs every Smoke suite plus `CycleRideRegressionTests` and `CycleAutoPauseRegressionTests`.
- **Combined code coverage** - merges unit-test coverage with the `ios26-iphone` UI test run (Smoke by default; Regression when enabled) into one `Go Cycling.app` report

The hosted UI test matrix (Smoke or Regression) currently requests these simulators:

- `macos-14` - iPhone SE (3rd generation), iPad mini (6th generation)
- `macos-15` - iPhone 16, iPad (10th generation)
- `macos-26` - iPhone 17, iPad Pro 11-inch (M5)

CI copies `TelemetryDeck.xcconfig.example` to `TelemetryDeck.xcconfig` when the gitignored file is absent, so no TelemetryDeck account is required. Simulator builds pass `DEVELOPMENT_TEAM=` so no committed development team is needed.
CI also passes `-retry-tests-on-failure`, which retries failed tests using Xcode's default maximum of 3 iterations.
Combined `Go Cycling.app` coverage is generated after unit and UI test jobs finish. The `ios26-iphone` matrix entry runs with `-enableCodeCoverage YES`; a follow-up `coverage` job merges that UI result bundle with `TestResults/unit.xcresult` via `xcrun xccov`, summarizes the union in the GitHub Actions run summary, and uploads the combined artifact.
GitHub-hosted CI does not provide iOS/iPadOS 14, 15, or 16 simulator coverage on those runner lines; the deployment target, availability checks, and optional physical-device, self-hosted-runner, or device-cloud testing remain the compatibility path for those OS versions.

### CI helper scripts

The Tests workflow uses small helpers under `.github/scripts/`:

- **`ios-simulator-destination.sh`** — Resolves a stable `xcodebuild -destination` value for an available iPhone or iPad simulator. Accepts a device family (`iPhone` or `iPad`), an optional preferred device name, and falls back to equivalent devices when the exact name is unavailable on the current runner image. Used by the unit-test and UI test jobs.

- **`merge-combined-coverage.sh`** — Exports coverage from a unit `.xcresult` and a UI `.xcresult`, merges them with `xcrun xccov merge`, and writes combined coverage artifacts under an output directory. Used by the `coverage` job and in the local repro steps below.

- **`write-xccov-summary.py`** — Reads `xcrun xccov view --report --json` output and prints a Markdown coverage table (target summary plus collapsible per-file rows). The `coverage` job appends this to the GitHub Actions job summary.

- **`restore-xcresult-bundle.sh`** — Reconstructs an `.xcresult` bundle from a flattened artifact directory that contains `Info.plist` and `Data/`. CI uploads result bundles in flattened form for artifact size limits; the `coverage` job downloads those artifacts and runs this script before `merge-combined-coverage.sh`. You normally do not need it for local reproduction when you already have real `.xcresult` directories from `xcodebuild`.

- **`validate-ci-simulator-coverage.sh`** — Optional manual check; **not** run in GitHub Actions. It (1) parses `tests.yml` and related docs to catch drift in the simulator matrix, coverage upload/merge wiring, and documentation expectations, and (2) exercises `ios-simulator-destination.sh` and `write-xccov-summary.py` offline with canned `simctl` fixtures so no Xcode run or real simulators are required. Run it before opening a PR that changes CI simulator or coverage wiring:

```bash
bash .github/scripts/validate-ci-simulator-coverage.sh
```

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

The resolver's optional third argument pins the simulator runtime major version (for example `iOS 17`, `iOS 18`, or `iOS 26`). CI passes each matrix row's `runtime` label so job names match the OS that actually runs. UI matrix rows use `iOS 17` / `iOS 18` / `iOS 26`; unit tests on `macos-26` use `iOS 26`.

```bash
cp -n TelemetryDeck.xcconfig.example TelemetryDeck.xcconfig
mkdir -p TestResults
rm -rf TestResults/unit.xcresult
DEST=$(.github/scripts/ios-simulator-destination.sh iPhone 'iPhone 17' 'iOS 26')
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
xcrun xccov view --report --json TestResults/unit.xcresult > TestResults/unit-coverage.json
python3 .github/scripts/write-xccov-summary.py TestResults/unit-coverage.json --target "Go Cycling.app"
```

Reproduce a UI smoke run with coverage for merge, substituting the device name as needed:

```bash
cp -n TelemetryDeck.xcconfig.example TelemetryDeck.xcconfig
mkdir -p TestResults
rm -rf TestResults/ui-ios26-iphone.xcresult
DEST=$(.github/scripts/ios-simulator-destination.sh iPhone 'iPhone 17' 'iOS 26')
xcodebuild \
  -project "Go Cycling.xcodeproj" \
  -scheme "Go Cycling UI Smoke" \
  -configuration Debug \
  -destination "$DEST" \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults/ui-ios26-iphone.xcresult \
  -retry-tests-on-failure \
  DEVELOPMENT_TEAM= \
  test
```

Reproduce a UI regression run, substituting the device name as needed:

```bash
DEST=$(.github/scripts/ios-simulator-destination.sh iPhone 'iPhone 17' 'iOS 26')
xcodebuild \
  -project "Go Cycling.xcodeproj" \
  -scheme "Go Cycling UI Regression" \
  -configuration Debug \
  -destination "$DEST" \
  -retry-tests-on-failure \
  DEVELOPMENT_TEAM= \
  test
```

Merge unit and UI coverage locally:

```bash
chmod +x .github/scripts/merge-combined-coverage.sh
.github/scripts/merge-combined-coverage.sh \
  TestResults/unit.xcresult \
  TestResults/ui-ios26-iphone.xcresult \
  TestResults
xcrun xccov view --report TestResults/combined.xccovreport
python3 .github/scripts/write-xccov-summary.py TestResults/coverage.json --target "Go Cycling.app"
```

Reproduce a UI smoke run without coverage, substituting the device name as needed:

```bash
DEST=$(.github/scripts/ios-simulator-destination.sh iPad 'iPad Pro 11-inch (M5)' 'iOS 26')
xcodebuild \
  -project "Go Cycling.xcodeproj" \
  -scheme "Go Cycling UI Smoke" \
  -configuration Debug \
  -destination "$DEST" \
  -retry-tests-on-failure \
  DEVELOPMENT_TEAM= \
  test
```

Set the `CI_RUN_UI_REGRESSION` repository variable to `true`, or dispatch the Tests workflow with `run_regression: true`, to run the Regression test plan in CI instead of Smoke. Regression includes the full Smoke plan (`HistorySmokeTests`, `SettingsSmokeTests`, `StatisticsSmokeTests`, `CycleRideSmokeTests`, `MainTabNavigationTests`) plus cycle regression suites.

## Feature and Maintenance Differences

Current fork-specific differences include:

- Local build fixes for fork owners: `TelemetryDeck.xcconfig.example`, in-repository default alternate icon paths, generic signing guidance, and explicit `NSUbiquitousKeyValueStore` integer writes.
- Focused Swift Testing unit coverage for cycling record sorting, aggregation, unlocked-icon, and reset-statistics behavior, plus UI smoke coverage for the main Cycle, History, Statistics, and Settings tabs and a Cycle start-pause-resume-stop-save smoke path.
- UI smoke and regression test plans (`Smoke.xctestplan`, `Regression.xctestplan`) under `Go CyclingUITests`, with `Go Cycling UI Smoke` and `Go Cycling UI Regression` schemes selecting the tier in CI and locally. `Regression.xctestplan` includes every Smoke suite plus `CycleRideRegressionTests` and `CycleAutoPauseRegressionTests`.
- UI smoke tests use a layered harness under `Go CyclingUITests/`: `Support/` (`Timeouts`, `ElementAssertions`, `BaseUITestCase`, `CycleUITestCase`, `StatisticsUITestCase`, `SettingsUITestCase`), `Screens/` (queries and actions), `Flows/` (`ResetAppDataFlow` with selectable reset areas), `Assertions/` (`Screen+Assertions.swift` composite expectations), and `Tests/` including `HistorySmokeTests`, `StatisticsSmokeTests`, and `SettingsSmokeTests`.
- UI testing support through the `-ui-testing` launch argument to avoid location authorization prompts during automated tests.
- A shared `Go Cycling` Xcode scheme for command-line and CI testing.
- A focused SwiftPM package slice for package-compatible formatting logic, declared over the existing Xcode-owned source and test directories so `swift test` complements the Xcode test action.
- GitHub Actions coverage for Swift formatting, SwiftPM unit tests, Xcode unit tests, combined unit-plus-UI `Go Cycling.app` coverage summaries, and UI smoke tests (Regression optional via `CI_RUN_UI_REGRESSION`).
- CI retries for failed XCTest and XCUITest cases via `-retry-tests-on-failure`.
- Hosted simulator coverage across selected GitHub-hosted macOS runner lines.
- Test-target `swift-format` enforcement in CI and the committed pre-commit hook.

Add future fork-only setup notes, CI changes, maintenance changes, and new feature differences here instead of expanding `README.md`.
