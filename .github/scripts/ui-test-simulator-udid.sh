#!/usr/bin/env bash
set -euo pipefail

# Prints the UDID for a simulator used by UI tests and CI.
# Usage: ui-test-simulator-udid.sh [iPhone|iPad] [preferred device name] [runtime label]
#
# UI_TEST_PREFERRED_DEVICE overrides the preferred device name (default: iPhone 17).

device_family="${1:-iPhone}"
preferred_device="${2:-${UI_TEST_PREFERRED_DEVICE:-iPhone 17}}"
requested_runtime="${3:-}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dest="$("${root}/.github/scripts/ios-simulator-destination.sh" "$device_family" "$preferred_device" "$requested_runtime")"
printf '%s' "${dest#*id=}"
