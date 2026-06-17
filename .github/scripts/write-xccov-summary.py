#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


def fail(message: str) -> int:
    print(f"coverage summary error: {message}", file=sys.stderr)
    return 1


def line_coverage_percent(item: dict) -> float:
    value = item.get("lineCoverage")
    if isinstance(value, (int, float)):
        return float(value) * 100

    covered = item.get("coveredLines")
    executable = item.get("executableLines")
    if isinstance(covered, int) and isinstance(executable, int) and executable > 0:
        return (covered / executable) * 100

    return 0.0


def line_count(item: dict, key: str) -> int:
    value = item.get(key)
    return value if isinstance(value, int) else 0


def markdown_escape(value: str) -> str:
    return value.replace("|", "\\|")


def display_path(file_entry: dict, repo_root: Path) -> str:
    raw_path = str(file_entry.get("path") or file_entry.get("name") or "<unknown>")
    path = Path(raw_path)

    if path.is_absolute():
        try:
            return str(path.resolve().relative_to(repo_root.resolve()))
        except ValueError:
            pass

    for marker in ("Go Cycling/", "Go CyclingTests/", "Go CyclingUITests/"):
        marker_index = raw_path.find(marker)
        if marker_index >= 0:
            return raw_path[marker_index:]

    return raw_path


def render_summary(report: dict, target_name: str, repo_root: Path) -> str:
    targets = report.get("targets")
    if not isinstance(targets, list):
        raise ValueError("coverage JSON does not contain a targets array")

    target = next(
        (candidate for candidate in targets if candidate.get("name") == target_name),
        None,
    )
    if target is None:
        available = ", ".join(
            sorted(str(candidate.get("name")) for candidate in targets if candidate.get("name"))
        )
        raise ValueError(f"target {target_name!r} not found; available targets: {available or '<none>'}")

    files = target.get("files")
    if not isinstance(files, list):
        files = []

    lines = [
        "## Code Coverage",
        "",
        "| Target | Coverage | Covered Lines | Executable Lines |",
        "| --- | ---: | ---: | ---: |",
        (
            f"| {markdown_escape(target_name)} | {line_coverage_percent(target):.1f}% | "
            f"{line_count(target, 'coveredLines')} | {line_count(target, 'executableLines')} |"
        ),
        "",
        "<details>",
        f"<summary>File Coverage ({len(files)} files)</summary>",
        "",
    ]

    if files:
        lines.extend(
            [
                "| File | Coverage | Covered Lines | Executable Lines |",
                "| --- | ---: | ---: | ---: |",
            ]
        )
        for file_entry in sorted(
            files,
            key=lambda entry: (
                line_coverage_percent(entry),
                display_path(entry, repo_root),
            ),
        ):
            lines.append(
                (
                    f"| {markdown_escape(display_path(file_entry, repo_root))} | "
                    f"{line_coverage_percent(file_entry):.1f}% | "
                    f"{line_count(file_entry, 'coveredLines')} | "
                    f"{line_count(file_entry, 'executableLines')} |"
                )
            )
    else:
        lines.append("_No file-level coverage was reported._")

    lines.extend(["", "</details>"])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render an xccov JSON report as a GitHub Actions Markdown summary."
    )
    parser.add_argument("coverage_json", type=Path)
    parser.add_argument("--target", required=True)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    args = parser.parse_args()

    try:
        with args.coverage_json.open(encoding="utf-8") as handle:
            report = json.load(handle)
        print(render_summary(report, args.target, args.repo_root))
    except FileNotFoundError:
        return fail(f"coverage JSON not found: {args.coverage_json}")
    except json.JSONDecodeError as error:
        return fail(f"coverage JSON is invalid: {error}")
    except ValueError as error:
        return fail(str(error))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
