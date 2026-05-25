# Release

Cut a release: bump version, tag, trigger CI/CD (if configured), and deploy.

## Arguments

`$ARGUMENTS` format: `[bump-type]`
- **bump-type**: `major`, `minor`, or `patch`. Default: `patch`.

---

## Steps

Execute the following steps **in order**.

---

### Step 0 — Confirm release options

Use `AskUserQuestion` to confirm:
1. **Bump type** (single-select): `patch`, `minor`, `major` — pre-select whichever matches `$ARGUMENTS`.

Wait for confirmation before proceeding.

---

### Step 1 — Run local checks

Before tagging, verify the codebase builds and tests pass:

```bash
cd /Users/danielvazac/Repos/Clonka/clonka-swift/ClonkaApp
xcodebuild build -project ClonkaApp.xcodeproj -scheme ClonkaApp -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -quiet
xcodebuild test -project ClonkaApp.xcodeproj -scheme ClonkaApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet
```

If any check fails, **stop** and report the failure. Do not proceed until all checks pass.

---

### Step 2 — Bump version

```
/bump $ARGUMENTS
```

This updates version in the Xcode project and commits the change.

---

### Step 3 — Tag and push

```bash
VERSION=$(grep -m1 'MARKETING_VERSION' ClonkaApp/ClonkaApp.xcodeproj/project.pbxproj | sed 's/.*= *//;s/ *;.*//')
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push && git push --tags
```

---

### Step 4 — CI/CD (if configured)

**Option A — GitHub Actions:**
```bash
gh run list --workflow=release.yml --limit=1
gh run watch
```

If any job fails:
1. Run `gh run view --log-failed` to get failure details
2. Report the error to the user
3. **Stop** — do not proceed to deployment

**Option B — No CI/CD:**
Build locally:
```
/build
```

---

### Step 5 — Summary

Report:
- New version
- Tag pushed (`v<version>`)
- CI result (✓ all jobs passed / ✗ failed job name) — if CI is configured
- Release artifacts or URL (if applicable)
