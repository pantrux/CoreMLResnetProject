#!/usr/bin/env python3
import re
import sys
from pathlib import Path

SEMVER_RE = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-((?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)"
    r"(?:\.(?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)


def fail(msg: str) -> int:
    print(f"[release-metadata] FAIL: {msg}")
    return 1


def main() -> int:
    version_path = Path("VERSION")
    changelog_path = Path("CHANGELOG.md")

    if not version_path.exists():
        return fail("missing VERSION file")
    if not changelog_path.exists():
        return fail("missing CHANGELOG.md file")

    version = version_path.read_text(encoding="utf-8").strip()
    match = SEMVER_RE.match(version)
    if not match:
        return fail(
            "VERSION must follow semver (x.y.z, optional -prerelease and +build metadata). "
            f"Got: '{version}'"
        )

    prerelease = match.group(4)
    changelog = changelog_path.read_text(encoding="utf-8")

    if "## [Unreleased]" not in changelog:
        return fail("CHANGELOG.md must include '## [Unreleased]' section")

    if prerelease is None:
        expected_version_header = f"## [{version}]"
        if expected_version_header not in changelog:
            return fail(f"CHANGELOG.md must include '{expected_version_header}' section")
    else:
        release_headers = re.findall(r"^## \[(\d+\.\d+\.\d+)\]", changelog, flags=re.M)
        if not release_headers:
            return fail("CHANGELOG.md must include at least one stable release section '## [x.y.z]'")

    print("[release-metadata] PASS")
    print(f"[release-metadata] VERSION={version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
