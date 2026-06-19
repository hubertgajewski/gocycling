#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "merge-combined-coverage error: $*" >&2
  exit 1
}

usage() {
  fail "usage: merge-combined-coverage.sh <unit.xcresult> <ui.xcresult> <output-dir>"
}

if [[ $# -ne 3 ]]; then
  usage
fi

unit_result="$1"
ui_result="$2"
output_dir="$3"

for bundle in "$unit_result" "$ui_result"; do
  [[ -d "$bundle" ]] || fail "missing result bundle: $bundle"
done

unit_cov="$output_dir/unit-cov"
ui_cov="$output_dir/ui-cov"
rm -rf "$unit_cov" "$ui_cov" "$output_dir/combined.xccovreport" "$output_dir/combined.xccovarchive"
mkdir -p "$unit_cov" "$ui_cov"

xcrun xcresulttool export coverage --path "$unit_result" --output-path "$unit_cov"
xcrun xcresulttool export coverage --path "$ui_result" --output-path "$ui_cov"

unit_report="$(find "$unit_cov" -maxdepth 1 -name '*_CoverageReport' -type f | head -1)"
unit_archive="$(find "$unit_cov" -maxdepth 1 -name '*_CoverageArchive' -type d | head -1)"
ui_report="$(find "$ui_cov" -maxdepth 1 -name '*_CoverageReport' -type f | head -1)"
ui_archive="$(find "$ui_cov" -maxdepth 1 -name '*_CoverageArchive' -type d | head -1)"

[[ -n "$unit_report" && -n "$unit_archive" ]] || fail "unit coverage export is incomplete"
[[ -n "$ui_report" && -n "$ui_archive" ]] || fail "UI coverage export is incomplete"

xcrun xccov merge \
  --outReport "$output_dir/combined.xccovreport" \
  --outArchive "$output_dir/combined.xccovarchive" \
  "$unit_report" "$unit_archive" \
  "$ui_report" "$ui_archive"

xcrun xccov view --report --json "$output_dir/combined.xccovreport" > "$output_dir/coverage.json"

xcrun xccov view --report --json "$unit_result" > "$output_dir/unit-only-coverage.json"

python3 - "$output_dir/unit-only-coverage.json" "$output_dir/coverage.json" <<'PY'
import json
import sys


def app_line_coverage(path: str) -> float:
    with open(path, encoding="utf-8") as handle:
        report = json.load(handle)

    targets = report.get("targets")
    if not isinstance(targets, list):
        raise SystemExit(f"{path} does not contain a targets array")

    target = next(
        (candidate for candidate in targets if candidate.get("name") == "Go Cycling.app"),
        None,
    )
    if target is None:
        raise SystemExit(f"Go Cycling.app not found in {path}")

    value = target.get("lineCoverage")
    if isinstance(value, (int, float)):
        return float(value)

    covered = target.get("coveredLines")
    executable = target.get("executableLines")
    if isinstance(covered, int) and isinstance(executable, int) and executable > 0:
        return covered / executable

    raise SystemExit(f"Go Cycling.app coverage is missing in {path}")


unit_only = app_line_coverage(sys.argv[1])
combined = app_line_coverage(sys.argv[2])

if combined + 1e-12 < unit_only:
    raise SystemExit(
        "merge-combined-coverage error: combined Go Cycling.app coverage "
        f"{combined:.4%} is lower than unit-only {unit_only:.4%}"
    )

print(
    "merge-combined-coverage: combined Go Cycling.app coverage "
    f"{combined:.4%} >= unit-only {unit_only:.4%}"
)
PY
