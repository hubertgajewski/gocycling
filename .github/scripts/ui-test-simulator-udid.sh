#!/usr/bin/env bash
set -euo pipefail

# Prints the UDID for the default iPhone simulator used by UI tests and CI.
# Usage: ui-test-simulator-udid.sh [iPhone|iPad] [preferred device name]
#
# UI_TEST_PREFERRED_DEVICE overrides the preferred device name (default: iPhone 17).

device_family="${1:-iPhone}"
preferred_device="${2:-${UI_TEST_PREFERRED_DEVICE:-iPhone 17}}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dest="$("${root}/.github/scripts/ios-simulator-destination.sh" "$device_family" "$preferred_device")"
printf '%s' "${dest#*id=}"
