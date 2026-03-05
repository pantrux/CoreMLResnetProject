#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate line coverage threshold from xccov JSON report.")
    parser.add_argument("--report", required=True, help="Path to xccov JSON report")
    parser.add_argument("--target", default="CoreMLProject", help="Target name (substring match)")
    parser.add_argument("--min-line", type=float, default=0.15, help="Minimum line coverage ratio (0.0-1.0)")
    return parser.parse_args()


def load_targets(report_path: Path):
    data = json.loads(report_path.read_text())
    if isinstance(data, dict):
        return data.get("targets", [])
    if isinstance(data, list):
        return data
    return []


def pick_target(targets, target_substring: str):
    needle = target_substring.lower()
    candidates = [t for t in targets if needle in str(t.get("name", "")).lower()]

    if not candidates:
        return None

    # Prefer app target over test bundle if both match.
    non_test = [t for t in candidates if not str(t.get("name", "")).lower().endswith("xctest")]
    return non_test[0] if non_test else candidates[0]


def main() -> int:
    args = parse_args()
    report_path = Path(args.report)

    if not report_path.exists():
        print(f"[coverage] ERROR: report not found: {report_path}")
        return 2

    targets = load_targets(report_path)
    if not targets:
        print("[coverage] ERROR: no targets found in report")
        return 2

    target = pick_target(targets, args.target)
    if target is None:
        print(f"[coverage] ERROR: target containing '{args.target}' not found")
        return 2

    name = str(target.get("name", "<unknown>"))
    line_coverage = target.get("lineCoverage")

    if line_coverage is None:
        print(f"[coverage] ERROR: target '{name}' does not expose lineCoverage")
        return 2

    try:
        line_ratio = float(line_coverage)
    except (TypeError, ValueError):
        print(f"[coverage] ERROR: invalid lineCoverage value for '{name}': {line_coverage}")
        return 2

    line_pct = line_ratio * 100
    min_pct = args.min_line * 100

    print(f"[coverage] target: {name}")
    print(f"[coverage] line coverage: {line_pct:.2f}%")
    print(f"[coverage] threshold: {min_pct:.2f}%")

    if line_ratio < args.min_line:
        print("[coverage] FAIL: coverage is below threshold")
        return 1

    print("[coverage] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
