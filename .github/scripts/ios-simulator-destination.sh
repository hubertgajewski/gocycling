#!/usr/bin/env bash
set -euo pipefail

# Resolves a stable xcodebuild -destination value for an available iOS Simulator.
# Usage: ios-simulator-destination.sh iPhone|iPad [preferred device name]

device_family="${1:?expected iPhone or iPad}"
preferred="${2:-}"

python3 - "$device_family" "$preferred" <<'PY'
import json
import subprocess
import sys

family, preferred = sys.argv[1], sys.argv[2]

data = json.loads(
    subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        text=True,
    )
)

ios_runtimes = sorted(
    (runtime for runtime in data["devices"] if "iOS" in runtime and "SimRuntime" in runtime),
    reverse=True,
)

devices: list[dict[str, object]] = []
for runtime in ios_runtimes:
    for device in data["devices"][runtime]:
        if not device.get("isAvailable", False):
            continue
        name = str(device.get("name", ""))
        if family == "iPhone" and name.startswith("iPhone"):
            devices.append(device)
        elif family == "iPad" and name.startswith("iPad"):
            devices.append(device)


def emit(device: dict[str, object]) -> None:
    print(f"platform=iOS Simulator,id={device['udid']}")
    raise SystemExit(0)


def match_name(device: dict[str, object], candidate: str) -> bool:
    name = str(device.get("name", ""))
    return name == candidate or name.startswith(candidate)


if preferred:
    for device in devices:
        if device.get("name") == preferred:
            emit(device)
    for device in devices:
        if match_name(device, preferred.split(" (")[0]):
            emit(device)

preferred_fallbacks: dict[str, list[str]] = {
    "iPhone SE (3rd generation)": [
        "iPhone SE (3rd generation)",
        "iPhone SE",
        "iPhone 16e",
    ],
    "iPhone 17": ["iPhone 17", "iPhone 16", "iPhone 15"],
    "iPhone 17 Pro Max": [
        "iPhone 17 Pro Max",
        "iPhone 16 Pro Max",
        "iPhone 15 Pro Max",
    ],
    "iPad mini (A17 Pro)": [
        "iPad mini (A17 Pro)",
        "iPad mini",
    ],
    "iPad Pro 11-inch (M5)": [
        "iPad Pro 11-inch (M5)",
        "iPad Pro 11-inch",
    ],
    "iPad Pro 13-inch (M5)": [
        "iPad Pro 13-inch (M5)",
        "iPad Pro 13-inch",
        "iPad Pro 12.9-inch",
    ],
}

for candidate in preferred_fallbacks.get(preferred, []):
    for device in devices:
        if match_name(device, candidate):
            emit(device)

fallback_names = {
    "iPhone": ["iPhone 17", "iPhone 16", "iPhone 15", "iPhone SE"],
    "iPad": ["iPad Pro 11-inch (M5)", "iPad Pro 11-inch", "iPad mini"],
}
for candidate in fallback_names.get(family, []):
    for device in devices:
        if match_name(device, candidate):
            emit(device)

if devices:
    emit(devices[0])

print(f"No available {family} simulator found", file=sys.stderr)
raise SystemExit(1)
PY
