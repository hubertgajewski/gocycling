#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "restore-xcresult-bundle error: $*" >&2
  exit 1
}

if [[ $# -ne 2 ]]; then
  fail "usage: restore-xcresult-bundle.sh <flattened-artifact-dir> <output.xcresult>"
fi

source_dir="$1"
bundle_path="$2"

[[ -d "$source_dir" ]] || fail "missing artifact directory: $source_dir"
[[ -f "$source_dir/Info.plist" ]] || fail "artifact directory is missing Info.plist: $source_dir"
[[ -d "$source_dir/Data" ]] || fail "artifact directory is missing Data/: $source_dir"

rm -rf "$bundle_path"
mkdir -p "$bundle_path"
cp -R "$source_dir"/. "$bundle_path/"
