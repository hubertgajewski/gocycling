#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflow="$repo_root/.github/workflows/tests.yml"
readme="$repo_root/README.md"
resolver="$repo_root/.github/scripts/ios-simulator-destination.sh"

python3 - "$workflow" "$readme" <<'PY'
import re
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text()
readme = Path(sys.argv[2]).read_text()
failures: list[str] = []

match = re.search(r"(?ms)^  ui-tests:\n(?P<body>.*?)(?:\n  [A-Za-z0-9_-]+:\n|\Z)", workflow)
if not match:
    failures.append("ui-tests job not found")
else:
    body = match.group("body")
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
    for os_name, families in sorted(required.items()):
        missing = families - observed.get(os_name, set())
        if missing:
            failures.append(f"ui-tests matrix missing {', '.join(sorted(missing))} entry for {os_name}")

doc_text = "\n".join((workflow, readme))
if "iOS/iPadOS 14-16" not in doc_text and "iOS/iPadOS 14, 15, or 16" not in doc_text:
    failures.append("CI docs must state hosted runners do not cover iOS/iPadOS 14-16 simulators")

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
