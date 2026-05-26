# Bump Version

Bump the project version across all relevant files.

## Arguments

`$ARGUMENTS` should be `major`, `minor`, or `patch`. Default to `patch` if omitted.

## Steps

Working directory: `/Users/danielvazac/Repos/Clonka/clonka-swift/ClonkaApp`

### 1. Read current version

Read the current `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from the Xcode project:

```bash
grep -r 'MARKETING_VERSION' ClonkaApp.xcodeproj/project.pbxproj | head -1
```

### 2. Bump version

Update `MARKETING_VERSION` in `ClonkaApp.xcodeproj/project.pbxproj` (all occurrences):
- `patch` → 1.2.3 → 1.2.4
- `minor` → 1.2.3 → 1.3.0
- `major` → 1.2.3 → 2.0.0

Also increment `CURRENT_PROJECT_VERSION` (build number) by 1.

### 3. Commit

```bash
git commit -am "chore: bump version to v<new-version>"
```

Report old → new version.
