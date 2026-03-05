# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- CI hardening and quality gates were strengthened (lint, strict simulator tests, coverage gate).
- Test suite was expanded with functional and UI smoke scenarios.
- Classification architecture was split into dedicated modules for maintainability.

### Added
- Git LFS lifecycle management for CoreML model assets.
- Diagnostics artifacts and coverage reporting in CI.
- Release metadata files (`VERSION`, `CHANGELOG.md`) and release checklist docs.

## [1.0.0] - 2026-03-05

### Added
- Initial iOS app with CoreML + Vision image classification flow (`Resnet50`).
- XCTest target and baseline test automation.

### Changed
- Progressive CI stabilization and stricter quality enforcement across PR-4 to PR-14.
