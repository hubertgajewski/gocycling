#!/usr/bin/env bash
set -euo pipefail

# Resolves a stable xcodebuild -destination value for an available iOS Simulator.
# Usage: ios-simulator-destination.sh iPhone|iPad [preferred device name] [runtime label]
# Runtime labels match CI matrix values such as "iOS 17", "iOS 18", or "iOS 26".

device_family="${1:?expected iPhone or iPad}"
preferred="${2:-}"
requested_runtime="${3:-}"

python3 - "$device_family" "$preferred" "$requested_runtime" <<'PY'
import json
import re
import subprocess
import sys

family, preferred, requested_runtime = sys.argv[1], sys.argv[2], sys.argv[3]


def runtime_major_from_key(runtime_key: str) -> int | None:
    match = re.search(r"SimRuntime\.iOS-(\d+)", runtime_key)
    return int(match.group(1)) if match else None


def parse_requested_runtime_major(label: str) -> int | None:
    if not label:
        return None
    match = re.match(r"^iOS\s+(\d+)(?:\.\d+)?$", label.strip())
    if not match:
        print(f"Unrecognized iOS runtime label: {label!r}", file=sys.stderr)
        print('Expected a label such as "iOS 17", "iOS 18", or "iOS 26".', file=sys.stderr)
        raise SystemExit(1)
    return int(match.group(1))


def format_runtime_label(runtime_key: str) -> str:
    major = runtime_major_from_key(runtime_key)
    if major is None:
        return runtime_key
    match = re.search(rf"SimRuntime\.iOS-{major}-(\d+)", runtime_key)
    if match:
        return f"iOS {major}.{match.group(1)}"
    return f"iOS {major}"


requested_major = parse_requested_runtime_major(requested_runtime)

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
if requested_major is not None:
    matching_runtimes = [
        runtime
        for runtime in ios_runtimes
        if runtime_major_from_key(runtime) == requested_major
    ]
    if not matching_runtimes:
        available_labels = sorted(
            {
                format_runtime_label(runtime)
                for runtime in ios_runtimes
                if runtime_major_from_key(runtime) is not None
            }
        )
        print(
            f"No installed iOS {requested_major} simulator runtime is available.",
            file=sys.stderr,
        )
        if available_labels:
            print(
                "Installed iOS simulator runtimes: " + ", ".join(available_labels),
                file=sys.stderr,
            )
        else:
            print("No iOS simulator runtimes are installed.", file=sys.stderr)
        raise SystemExit(1)
    ios_runtimes = matching_runtimes

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
    "iPad mini (6th generation)": [
        "iPad mini (6th generation)",
        "iPad mini (A17 Pro)",
        "iPad mini",
    ],
    "iPad mini (A17 Pro)": [
        "iPad mini (A17 Pro)",
        "iPad mini",
    ],
    "iPad (10th generation)": [
        "iPad (10th generation)",
        "iPad (A16)",
        "iPad (",
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

if preferred:
    for device in devices:
        if match_name(device, preferred.split(" (")[0]):
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

if requested_major is not None:
    print(
        f"No available {family} simulator found for requested runtime iOS {requested_major}.",
        file=sys.stderr,
    )
else:
    print(f"No available {family} simulator found", file=sys.stderr)
raise SystemExit(1)
PY
