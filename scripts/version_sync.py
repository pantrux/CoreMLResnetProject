#!/usr/bin/env python3
import argparse
import plistlib
import re
import sys
from pathlib import Path

from semver_utils import semver_core


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check/sync iOS app version metadata (MARKETING_VERSION + "
            "CFBundleShortVersionString) from VERSION semver."
        )
    )
    parser.add_argument("--mode", choices=["check", "sync"], default="check")
    parser.add_argument("--version-file", default="VERSION")
    parser.add_argument("--plist", default="CoreMLProject/Info.plist")
    parser.add_argument("--pbxproj", default="CoreMLProject.xcodeproj/project.pbxproj")
    return parser.parse_args()


def fail(msg: str) -> int:
    print(f"[version-sync] FAIL: {msg}")
    return 1


def read_version(version_path: Path) -> tuple[str, str]:
    if not version_path.exists():
        raise FileNotFoundError(f"No existe VERSION: {version_path}")
    version = version_path.read_text(encoding="utf-8").strip()
    core = semver_core(version)
    return version, core


def load_plist(plist_path: Path) -> dict:
    if not plist_path.exists():
        raise FileNotFoundError(f"No existe plist: {plist_path}")
    with plist_path.open("rb") as fh:
        return plistlib.load(fh)


def save_plist(plist_path: Path, data: dict) -> None:
    with plist_path.open("wb") as fh:
        plistlib.dump(data, fh, sort_keys=False)


def read_pbxproj(pbxproj_path: Path) -> str:
    if not pbxproj_path.exists():
        raise FileNotFoundError(f"No existe pbxproj: {pbxproj_path}")
    return pbxproj_path.read_text(encoding="utf-8")


def write_pbxproj(pbxproj_path: Path, content: str) -> None:
    pbxproj_path.write_text(content, encoding="utf-8")


def extract_marketing_versions(pbxproj_text: str) -> list[str]:
    return [v.strip() for v in re.findall(r"MARKETING_VERSION = ([^;]+);", pbxproj_text)]


def sync_pbxproj_marketing_version(pbxproj_text: str, core_version: str) -> tuple[str, int]:
    return re.subn(r"(MARKETING_VERSION = )[^;]+;", rf"\g<1>{core_version};", pbxproj_text)


def run_check(version_path: Path, plist_path: Path, pbxproj_path: Path) -> int:
    try:
        version, core = read_version(version_path)
        plist_data = load_plist(plist_path)
        pbxproj_text = read_pbxproj(pbxproj_path)
    except (FileNotFoundError, ValueError) as exc:
        return fail(str(exc))

    plist_version = str(plist_data.get("CFBundleShortVersionString", "")).strip()
    marketing_versions = extract_marketing_versions(pbxproj_text)

    if not marketing_versions:
        return fail("No se encontraron MARKETING_VERSION en project.pbxproj")

    mismatches = [v for v in marketing_versions if v != core]

    errors = []
    if plist_version != core:
        errors.append(
            "CFBundleShortVersionString no coincide con VERSION (core). "
            f"VERSION={version} core={core} plist={plist_version}"
        )

    if mismatches:
        errors.append(
            "MARKETING_VERSION no coincide con VERSION (core). "
            f"VERSION={version} core={core} mismatching_values={sorted(set(mismatches))}"
        )

    if errors:
        for error in errors:
            print(f"[version-sync] FAIL: {error}")
        return 1

    print("[version-sync] PASS")
    print(f"[version-sync] VERSION={version}")
    print(f"[version-sync] CORE={core}")
    print(f"[version-sync] MARKETING_VERSION values={sorted(set(marketing_versions))}")
    print(f"[version-sync] CFBundleShortVersionString={plist_version}")
    return 0


def run_sync(version_path: Path, plist_path: Path, pbxproj_path: Path) -> int:
    try:
        version, core = read_version(version_path)
        plist_data = load_plist(plist_path)
        pbxproj_text = read_pbxproj(pbxproj_path)
    except (FileNotFoundError, ValueError) as exc:
        return fail(str(exc))

    changes = []

    plist_before = str(plist_data.get("CFBundleShortVersionString", "")).strip()
    if plist_before != core:
        plist_data["CFBundleShortVersionString"] = core
        save_plist(plist_path, plist_data)
        changes.append(f"plist: {plist_before} -> {core}")

    updated_pbxproj, replacements = sync_pbxproj_marketing_version(pbxproj_text, core)
    if replacements > 0 and updated_pbxproj != pbxproj_text:
        write_pbxproj(pbxproj_path, updated_pbxproj)
        changes.append(f"pbxproj MARKETING_VERSION updates: {replacements}")

    if changes:
        print("[version-sync] SYNC APPLIED")
        for change in changes:
            print(f"[version-sync] {change}")
    else:
        print("[version-sync] SYNC NO-OP (already in sync)")

    return run_check(version_path, plist_path, pbxproj_path)


def main() -> int:
    args = parse_args()
    version_path = Path(args.version_file)
    plist_path = Path(args.plist)
    pbxproj_path = Path(args.pbxproj)

    if args.mode == "sync":
        return run_sync(version_path, plist_path, pbxproj_path)
    return run_check(version_path, plist_path, pbxproj_path)


if __name__ == "__main__":
    sys.exit(main())
