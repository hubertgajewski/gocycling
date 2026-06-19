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
