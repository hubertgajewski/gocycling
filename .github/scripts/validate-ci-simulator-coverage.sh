#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflow="$repo_root/.github/workflows/tests.yml"
readme="$repo_root/README.md"
fork_changes="$repo_root/FORK_CHANGES.md"
resolver="$repo_root/.github/scripts/ios-simulator-destination.sh"
coverage_summary="$repo_root/.github/scripts/write-xccov-summary.py"

python3 - "$workflow" "$readme" "$fork_changes" "$coverage_summary" <<'PY'
import re
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text()
readme = Path(sys.argv[2]).read_text()
fork_changes = Path(sys.argv[3]).read_text()
coverage_summary = Path(sys.argv[4])
failures: list[str] = []

unit_match = re.search(r"(?ms)^  unit-tests:\n(?P<body>.*?)(?:\n  [A-Za-z0-9_-]+:\n|\Z)", workflow)
if not unit_match:
    failures.append("unit-tests job not found")
else:
    unit_body = unit_match.group("body")
    unit_name = re.search(r"(?m)^\s+name:\s*(?P<value>.+)$", unit_body)
    if not unit_name or "iPhone Air" not in unit_name.group("value"):
        failures.append("unit-tests job name must mention the requested iPhone Air simulator")
    if "-enableCodeCoverage YES" not in unit_body:
        failures.append("unit-tests must enable Xcode code coverage")
    if "xcrun xccov view --report --json TestResults/unit.xcresult > TestResults/coverage.json" not in unit_body:
        failures.append("unit-tests must generate coverage JSON with xccov")
    if "write-xccov-summary.py" not in unit_body or "GITHUB_STEP_SUMMARY" not in unit_body:
        failures.append("unit-tests must publish coverage to the GitHub job summary")
    if "TestResults/coverage.json" not in unit_body or "unit-test-coverage" not in unit_body:
        failures.append("unit-tests must upload coverage artifacts")
    if not coverage_summary.exists():
        failures.append("coverage summary script not found")

match = re.search(r"(?ms)^  ui-tests:\n(?P<body>.*?)(?:\n  [A-Za-z0-9_-]+:\n|\Z)", workflow)
if not match:
    failures.append("ui-tests job not found")
else:
    body = match.group("body")
    job_name = re.search(r"(?m)^\s+name:\s*(?P<value>.+)$", body)
    if not job_name or "matrix.runtime" not in job_name.group("value") or "matrix.device_label" not in job_name.group("value"):
        failures.append("ui-tests job name must include matrix.runtime and matrix.device_label")

    runs_on = re.search(r"(?m)^\s+runs-on:\s*(?P<value>.+)$", body)
    if not runs_on or "matrix.os" not in runs_on.group("value"):
        failures.append("ui-tests runs-on must reference matrix.os")

    entries: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    in_include = False
    for line in body.splitlines():
        if re.match(r"^\s+include:\s*$", line):
            in_include = True
            continue
        if not in_include:
            continue
        item = re.match(r"^\s+-\s+([A-Za-z0-9_-]+):\s*(.+?)\s*$", line)
        if item:
            if current is not None:
                entries.append(current)
            current = {item.group(1): item.group(2).strip('"')}
            continue
        field = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(.+?)\s*$", line)
        if field and current is not None:
            current[field.group(1)] = field.group(2).strip('"')
            continue
        if re.match(r"^\s+steps:\s*$", line):
            break
    if current is not None:
        entries.append(current)

    required = {
        "macos-14": {"iPhone", "iPad"},
        "macos-15": {"iPhone", "iPad"},
        "macos-26": {"iPhone", "iPad"},
    }
    observed: dict[str, set[str]] = {}
    for entry in entries:
        if "os" in entry and "family" in entry:
            observed.setdefault(entry["os"], set()).add(entry["family"])
        if "runtime" not in entry:
            failures.append(f"ui-tests matrix entry {entry.get('id', '<unknown>')} is missing runtime")
        if "device_label" not in entry:
            failures.append(f"ui-tests matrix entry {entry.get('id', '<unknown>')} is missing device_label")
        elif "(" in entry["device_label"] or ")" in entry["device_label"]:
            failures.append(f"ui-tests device_label for {entry.get('id', entry['device_label'])} must not contain parentheses")
    for os_name, families in sorted(required.items()):
        missing = families - observed.get(os_name, set())
        if missing:
            failures.append(f"ui-tests matrix missing {', '.join(sorted(missing))} entry for {os_name}")

doc_text = "\n".join((workflow, readme, fork_changes))
if "iOS/iPadOS 14-16" not in doc_text and "iOS/iPadOS 14, 15, or 16" not in doc_text:
    failures.append("CI docs must state hosted runners do not cover iOS/iPadOS 14-16 simulators")
if "xcrun xccov" not in doc_text:
    failures.append("CI docs must explain local xccov coverage inspection")

if failures:
    print("CI simulator coverage validation failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    raise SystemExit(1)
PY

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/xcrun" <<'SH'
#!/usr/bin/env bash
cat "$SIMCTL_FIXTURE"
SH
chmod +x "$tmpdir/xcrun"

cat > "$tmpdir/devices.json" <<'JSON'
{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
      {
        "isAvailable": true,
        "name": "iPad Pro 11-inch (M4)",
        "udid": "IPAD-PRO-11-M4"
      },
      {
        "isAvailable": true,
        "name": "iPad (A16)",
        "udid": "IPAD-A16"
      }
    ]
  }
}
JSON

destination="$(
  SIMCTL_FIXTURE="$tmpdir/devices.json" \
  PATH="$tmpdir:$PATH" \
  bash "$resolver" iPad "iPad (10th generation)"
)"

expected="platform=iOS Simulator,id=IPAD-A16"
if [[ "$destination" != "$expected" ]]; then
  printf 'Expected plain iPad fallback %q, got %q\n' "$expected" "$destination" >&2
  exit 1
fi

cat > "$tmpdir/iphone17-only.json" <<'JSON'
{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-26-5": [
      {
        "isAvailable": true,
        "name": "iPhone 17",
        "udid": "IPHONE-17"
      }
    ]
  }
}
JSON

if SIMCTL_FIXTURE="$tmpdir/iphone17-only.json" PATH="$tmpdir:$PATH" bash "$resolver" iPhone "iPhone Air" > "$tmpdir/iphone-air.out" 2> "$tmpdir/iphone-air.err"; then
  printf 'Expected iPhone Air resolver to reject iPhone 17 fallback, got %q\n' "$(cat "$tmpdir/iphone-air.out")" >&2
  exit 1
fi

cat > "$tmpdir/coverage.json" <<'JSON'
{
  "targets": [
    {
      "name": "Go Cycling.app",
      "lineCoverage": 0.625,
      "coveredLines": 50,
      "executableLines": 80,
      "files": [
        {
          "path": "/tmp/work/gocycling/Go Cycling/Model/CyclingRecords.swift",
          "lineCoverage": 0.5,
          "coveredLines": 10,
          "executableLines": 20
        },
        {
          "path": "/tmp/work/gocycling/Go Cycling/View/MainView.swift",
          "lineCoverage": 1,
          "coveredLines": 40,
          "executableLines": 40
        }
      ]
    }
  ]
}
JSON

summary="$(python3 "$coverage_summary" "$tmpdir/coverage.json" --target "Go Cycling.app")"
for expected_fragment in \
  "## Code Coverage" \
  "| Go Cycling.app | 62.5% | 50 | 80 |" \
  "<details>" \
  "Go Cycling/Model/CyclingRecords.swift" \
  "Go Cycling/View/MainView.swift"; do
  if [[ "$summary" != *"$expected_fragment"* ]]; then
    printf 'Coverage summary missing expected fragment %q\n' "$expected_fragment" >&2
    exit 1
  fi
done
