# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Post-release housekeeping after `v1.0.0`: development cycle moved to `VERSION=1.0.1-dev`.
- iOS app metadata versioning now follows the `x.y.z` core from `VERSION` (`1.0.1`).

### Added
- `scripts/version_sync.py` to check/sync `MARKETING_VERSION` and `CFBundleShortVersionString` from `VERSION`.
- New CI mandatory gate (**Version sync gate**) to prevent release/app-version drift.

## [1.0.0] - 2026-03-05

### Added
- Initial iOS app with CoreML + Vision image classification flow (`Resnet50`).
- XCTest target and baseline test automation.

### Changed
- Progressive CI stabilization and stricter quality enforcement across PR-4 to PR-14.
