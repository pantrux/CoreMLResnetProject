# Release Checklist

## Preconditions

- [ ] All required checks are green (`build-test-and-lint`)
- [ ] `CHANGELOG.md` updated (`[Unreleased]` + release notes)
- [ ] `VERSION` updated with semantic version (`x.y.z`, optional `-prerelease` y `+build`)
- [ ] Metadata iOS sincronizada desde `VERSION` (`python3 scripts/version_sync.py --mode sync`)
- [ ] PR review comments from bots/humans triaged

## Release Steps

1. Update `VERSION`, move relevant notes from `## [Unreleased]` to a dated version section in `CHANGELOG.md`, and keep an empty `## [Unreleased]` header in place (required by CI gate).
2. Sync iOS metadata from `VERSION`:
   ```bash
   python3 scripts/version_sync.py --mode sync
   ```
3. Merge release PR into `main`.
4. Create annotated git tag:
   ```bash
   git tag -a v$(cat VERSION) -m "Release v$(cat VERSION)"
   git push origin v$(cat VERSION)
   ```
5. Publish release notes using `CHANGELOG.md` section.

## Post-Release

- [ ] Open follow-up PR to prepare next cycle (`[Unreleased]` housekeeping)
- [ ] Confirm CI still green on `main`
- [ ] Verify model assets availability through Git LFS
