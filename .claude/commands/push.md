# Commit and Push

Stage, commit, and push all current changes to the remote.

## Steps

Working directory: `[PROJECT_ROOT]`

### 1. Inspect current state

Run in parallel:
```
git status
git diff
git log --oneline -5
```

### 2. Stage changes

Add modified and new files relevant to the current work. Prefer naming files explicitly over `git add -A`. Never stage:
- `.env` or files containing secrets
- Build artifacts (`target/`, `dist/`, `*.exe`, `*.apk`, `__pycache__/`)
- IDE/editor state (`.idea/`, `.vscode/`, `*.user`)

If untracked files look unrelated to the current task, skip them and note it in the commit message.

### 3. Commit

Write a concise imperative commit message (≤72 chars subject line) that explains *why*, not just *what*. Follow the style of recent commits shown in step 1.

```
git commit -m "$(cat <<'EOF'
<subject line>

<optional body if needed>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 4. Push

```
git push
```

If the push is rejected (diverged remote), show the error and ask the user whether to rebase or force-push. **Do not force-push without explicit confirmation.**

### 5. Report

Print the commit hash and subject line, plus the push result:
```
✓ 3fa1c2d  feat: add test suite (79 tests across 4 crates)
✓ pushed to origin/master
```
