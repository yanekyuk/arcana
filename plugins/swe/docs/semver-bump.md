# Semver Version Bump Procedure

This is a shared reference used by all orchestrator agents. Each orchestrator specifies its own default bump type when invoking this procedure.

## 1. Detect version manifest

Search the project root for a version manifest, checking in order:

- `package.json` — `"version": "X.Y.Z"`
- `Cargo.toml` — `version = "X.Y.Z"` under `[package]`
- `pyproject.toml` — `version = "X.Y.Z"` under `[project]` or `[tool.poetry]`
- `setup.cfg` — `version = X.Y.Z` under `[metadata]`
- `build.gradle` / `build.gradle.kts` — `version = "X.Y.Z"`
- `version.txt` — entire file content is the version string

If no version manifest is found, skip the version bump entirely.

## 2. Determine bump type

Apply [Semantic Versioning 2.0.0](https://semver.org) rules:

1. **Check handoff for explicit directive** — if the handoff frontmatter contains `version-bump: major|minor|patch|none`, use that.
2. **Otherwise use the orchestrator's default** (passed to this procedure).
3. **Adjust for pre-1.0** — if the current version is `0.x.y`:
   - MAJOR changes become MINOR bumps (`0.x.0 → 0.(x+1).0`)
   - MINOR and PATCH stay as-is
4. **Adjust for breaking changes** — if the diff introduces incompatible API changes (removed public functions, changed signatures, renamed exports), escalate to MAJOR regardless of the default.

Bump categories:
- **MAJOR** (`X.0.0`) — incompatible API changes
- **MINOR** (`x.Y.0`) — backward-compatible new functionality
- **PATCH** (`x.y.Z`) — backward-compatible bug fixes

## 3. Apply the bump

Edit the version string in the manifest file. Reset lower components (MAJOR resets minor and patch to 0; MINOR resets patch to 0).

## 4. Commit

```bash
git add <manifest-file>
git commit -m "chore: bump version to <new-version>"
```
