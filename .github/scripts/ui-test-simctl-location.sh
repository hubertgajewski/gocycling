#!/usr/bin/env bash
set -euo pipefail

# Configure simulator location permission for UI tests.
# Usage: ui-test-simctl-location.sh grant|reset [simulator-id] [bundle-id]
#
# bundle-id is optional: reads PRODUCT_BUNDLE_IDENTIFIER from the Go Cycling
# app target when omitted (honours SRCROOT when set).
#
# Environment:
#   UI_TEST_PREFERRED_DEVICE  Simulator name to prefer (default: iPhone 17)
#
# grant resets per-bundle location first, then grants location + location-always.
# This clears a prior "Don't Allow" from the Permission scheme on the same sim.
# reset clears both services for permission-prompt tests.

action="${1:?expected grant or reset}"
simulator_id="${2:-booted}"
bundle_id="${3:-}"

case "$action" in
  grant|reset) ;;
  *)
    echo "expected grant or reset, got: $action" >&2
    exit 1
    ;;
esac

location_services=(location location-always)
preferred_device="${UI_TEST_PREFERRED_DEVICE:-iPhone 17}"
# Fixed coordinate used for UI-test map zoom (Apple Park).
simulated_latitude="${UI_TEST_SIMULATED_LATITUDE:-37.334606}"
simulated_longitude="${UI_TEST_SIMULATED_LONGITUDE:--122.009102}"

repo_root() {
  if [[ -n "${SRCROOT:-}" ]]; then
    printf '%s' "$SRCROOT"
    return 0
  fi
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

resolve_bundle_id() {
  local root
  root="$(repo_root)"
  local project="${root}/Go Cycling.xcodeproj"
  if [[ ! -d "$project" ]]; then
    echo "could not find Go Cycling.xcodeproj under ${root}" >&2
    return 1
  fi

  xcodebuild \
    -project "$project" \
    -target "Go Cycling" \
    -configuration "${CONFIGURATION:-Debug}" \
    -sdk iphonesimulator \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/^    PRODUCT_BUNDLE_IDENTIFIER = / { print $2; exit }'
}

booted_simulator_lines() {
  xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get("devices", {}).items():
    for device in devices:
        if device.get("state") == "Booted":
            udid = device["udid"]
            name = device.get("name", "")
            print(f"{udid}\t{name}")
'
}

pick_booted_simulator_udid() {
  local udid name first_udid=""
  while IFS=$'\t' read -r udid name; do
    [[ -n "$udid" ]] || continue
    if [[ -z "$first_udid" ]]; then
      first_udid="$udid"
    fi
    if [[ "$name" == "$preferred_device" ]]; then
      printf '%s' "$udid"
      return 0
    fi
  done < <(booted_simulator_lines)

  if [[ -n "$first_udid" ]]; then
    printf '%s' "$first_udid"
    return 0
  fi
  return 1
}

destination_simulator_udid() {
  local var
  for var in TARGET_DEVICE_IDENTIFIER PLATFORM_DEVICE_IDENTIFIER RUN_DESTINATION_DEVICE_UDID; do
    if [[ -n "${!var:-}" ]]; then
      printf '%s' "${!var}"
      return 0
    fi
  done
  return 1
}

preferred_simulator_udid() {
  local root dest
  root="$(repo_root)"
  dest="$("${root}/.github/scripts/ios-simulator-destination.sh" iPhone "$preferred_device")"
  printf '%s' "${dest#*id=}"
}

resolve_simulator_udid() {
  local requested="${1:-booted}"

  if [[ "$requested" != "booted" ]]; then
    printf '%s' "$requested"
    return 0
  fi

  local udid=""
  # Prefer the simulator that is already booted (e.g. after Permission on iPhone 17).
  if udid="$(pick_booted_simulator_udid)"; then
    [[ -n "$udid" ]] || return 1
    echo "ui-test-simctl-location: using booted simulator ${udid}" >&2
    printf '%s' "$udid"
    return 0
  fi

  if udid="$(destination_simulator_udid)"; then
    echo "ui-test-simctl-location: using destination env simulator ${udid}" >&2
    printf '%s' "$udid"
    return 0
  fi

  udid="$(preferred_simulator_udid)"
  echo "ui-test-simctl-location: using preferred simulator ${preferred_device} (${udid})" >&2
  printf '%s' "$udid"
}

ensure_simulator_booted() {
  local udid="$1"
  if ! xcrun simctl list devices booted 2>/dev/null | grep -Fq "$udid"; then
    echo "ui-test-simctl-location: booting simulator ${udid}" >&2
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  fi
}

set_simulated_location() {
  local udid="$1"
  echo "ui-test-simctl-location: set simulated location on ${udid}" >&2
  xcrun simctl location "$udid" set "${simulated_latitude},${simulated_longitude}"
}

apply_privacy_action() {
  local udid="$1"
  local service="$2"
  local privacy_action="$3"

  if [[ "$privacy_action" == "reset" ]]; then
    echo "ui-test-simctl-location: reset ${service} on ${udid}" >&2
    xcrun simctl privacy "$udid" reset "$service"
    if [[ -n "$bundle_id" ]]; then
      echo "ui-test-simctl-location: reset ${service} for ${bundle_id} on ${udid}" >&2
      xcrun simctl privacy "$udid" reset "$service" "$bundle_id"
    fi
  else
    echo "ui-test-simctl-location: grant ${service} for ${bundle_id} on ${udid}" >&2
    xcrun simctl privacy "$udid" grant "$service" "$bundle_id"
  fi
}

if [[ -z "$bundle_id" ]]; then
  bundle_id="$(resolve_bundle_id)" || exit 1
  if [[ -z "$bundle_id" ]]; then
    echo "could not find PRODUCT_BUNDLE_IDENTIFIER for Go Cycling" >&2
    exit 1
  fi
fi

simulator_udid="$(resolve_simulator_udid "$simulator_id")"
ensure_simulator_booted "$simulator_udid"

if [[ "$action" == "grant" ]]; then
  for service in "${location_services[@]}"; do
    apply_privacy_action "$simulator_udid" "$service" reset
  done
fi

for service in "${location_services[@]}"; do
  apply_privacy_action "$simulator_udid" "$service" "$action"
done

if [[ "$action" == "grant" ]]; then
  set_simulated_location "$simulator_udid"
fi
