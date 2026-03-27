# Semver Version Bump Procedure

This is a shared reference used by all orchestrator agents. Each orchestrator specifies its own default bump type when invoking this procedure.

## 1. Read versioning rules

Read the `versioning` array from `docs/swe-config.json`. Each entry is a natural-language rule string that specifies which version manifest to bump and under what conditions.

Example rules:
- `"Bump package.json version for all changes"`
- `"Bump frontend/package.json version for changes under frontend/"`
- `"Bump api/pyproject.toml version for changes under api/"`

**If the `versioning` array is empty or absent, skip the version bump entirely.**

## 2. Evaluate which rules apply

For each versioning rule:

1. Parse the rule to identify the **manifest path** and the **condition** (e.g., "changes under frontend/", "all changes", "for API changes").
2. Check the current diff (`git diff main...HEAD`) against the condition:
   - "all changes" or no condition specified -- always matches
   - "changes under <path>/" -- matches if any files in the diff are under that path
   - Domain-specific conditions (e.g., "for API changes") -- evaluate based on the diff content and handoff scope
3. Collect all matching rules. Multiple rules can match simultaneously (monorepo scenario).

If no rules match the current change, skip the version bump.

## 3. Determine bump type

For each matching rule, apply [Semantic Versioning 2.0.0](https://semver.org) rules:

1. **Check handoff for explicit directive** -- if the handoff frontmatter contains `version-bump: major|minor|patch|none`, use that.
2. **Otherwise use the orchestrator's default** (passed to this procedure).
3. **Adjust for pre-1.0** -- if the current version is `0.x.y`:
   - MAJOR changes become MINOR bumps (`0.x.0 -> 0.(x+1).0`)
   - MINOR and PATCH stay as-is
4. **Adjust for breaking changes** -- if the diff introduces incompatible API changes (removed public functions, changed signatures, renamed exports), escalate to MAJOR regardless of the default.

Bump categories:
- **MAJOR** (`X.0.0`) -- incompatible API changes
- **MINOR** (`x.Y.0`) -- backward-compatible new functionality
- **PATCH** (`x.y.Z`) -- backward-compatible bug fixes

## 4. Apply the bump

For each matching rule:

1. Read the version manifest file specified in the rule
2. Parse the current version string based on the manifest format:
   - `package.json` -- `"version": "X.Y.Z"`
   - `Cargo.toml` -- `version = "X.Y.Z"` under `[package]`
   - `pyproject.toml` -- `version = "X.Y.Z"` under `[project]` or `[tool.poetry]`
   - `setup.cfg` -- `version = X.Y.Z` under `[metadata]`
   - `build.gradle` / `build.gradle.kts` -- `version = "X.Y.Z"`
   - `version.txt` -- entire file content is the version string
3. Apply the bump. Reset lower components (MAJOR resets minor and patch to 0; MINOR resets patch to 0).
4. Write the updated version back to the manifest file.

## 5. Commit

```bash
git add <all-bumped-manifest-files>
git commit -m "chore: bump version to <new-version>"
```

If multiple manifests were bumped, list all versions in the commit message:

```bash
git add <manifest-1> <manifest-2>
git commit -m "chore: bump versions — <manifest-1> to <v1>, <manifest-2> to <v2>"
```
