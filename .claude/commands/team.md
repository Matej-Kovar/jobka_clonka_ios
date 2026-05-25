# Start Agent Team

Coordinate a team of Claude Code teammates to work on the project in parallel.

> **Prerequisite**: Agent teams must be enabled. If not already set, add to `~/.claude/settings.json`:
> ```json
> { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
> ```

---

## Step 1 — Understand the Work

Read the user's request (the argument passed to `/team`, or the current conversation context) to determine:
- What issues/features need to be worked on
- Which layers/modules are affected
- How much parallelism is possible

If no specific task is given, ask: `"What do you want the team to work on?"`

---

## Step 2 — Choose Teammates

Read all files in the `teams/` folder. Each file defines one role — its `model` and `scope` are in the YAML frontmatter at the top.

Build the role table from those files:

| Role | Model | Scope |
|------|-------|-------|
| *(read from teams/*.md frontmatter)* | | |

**Team size guideline**: 3 teammates for most tasks; up to 5 for large cross-layer work.
Always include `explorer` (haiku, cheap) when the affected area is unfamiliar — spawn it first.

Pick only roles whose scope overlaps with the current work.

---

## Step 3 — Create a Worktree

Before any code changes, create a Git worktree so all team work stays off `master`.

1. Derive a short description from the task (e.g., `add-auth`, `fix-session-leak`).

2. **Commit and push master first** — from `[PROJECT_ROOT]`:
   - Commit any pending changes (skip if already clean):
     ```bash
     git add -A && git commit -m "wip: ..."
     ```
   - Push to remote so the worktree starts from the latest `origin/master`:
     ```bash
     git push
     ```

3. Create the worktree from `[PROJECT_ROOT]`:
   ```bash
   git worktree add [PROJECT_ROOT]-<short-description> -b wt/<short-description> origin/master
   ```

4. Use the `EnterWorktree` tool to switch into the new worktree directory.

5. All subsequent work (task creation, teammate spawning, file edits) happens inside this worktree.

Record the worktree path — you will need it for teammate spawn prompts and cleanup.

---

## Step 4 — Create the Team

```
TeamCreate team-name="[project]-YYYYMMDD"
```

---

## Step 5 — Break Work into Tasks

Create tasks before spawning teammates. Each task must:
- Touch only one layer/module (no cross-layer tasks)
- Have a clear deliverable ("implement X", "write tests for Y", "fix bug Z")
- List its blockers if order matters

**Task size**: roughly 30–90 minutes of work.

```
TaskCreate title="..." description="..." assignee="[role]"
TaskCreate title="..." description="..." assignee="[role]"
```

---

## Step 6 — Spawn Teammates

For each teammate, read the corresponding `teams/[role].md` file and use it as the spawn prompt. Substitute `[TASKS]` with the actual task list assigned to that role.

```
SendMessage to teammate: [full content of teams/[role].md with [TASKS] filled in]
```

---

## Step 7 — Monitor and Coordinate

While teammates work:
- Check the task list periodically: `TaskList`
- Read teammate messages as they arrive
- If a teammate is blocked on another's output, relay via `SendMessage`
- Update tasks if scope changes: `TaskUpdate`
- Redirect teammates who are going off-track

**Do NOT** do implementation work yourself while teammates are running.

---

## Step 8 — Integration (MANDATORY before shutdown)

When all tasks show `completed`, run the full check suite from inside the worktree:

```
[TODO: full test/check command — filled in by @init]
```

**If anything fails**: keep the relevant teammate alive, send them the failure output, wait for the fix, then re-run. Only proceed when all checks pass.

After all checks pass, **merge the worktree back to master**:

```bash
# 1. Commit all work inside the worktree
git add -A && git commit -m "feat: <description>"

# 2. Switch back to the main repo root
cd [PROJECT_ROOT]

# 3. Merge the worktree branch
git merge wt/<short-description>

# 4. Verify the merge
git branch --merged master | grep wt/
```

If merge conflicts arise, preserve intent from both sides — never blindly pick one side. Re-run the check suite after resolving.

- Review `git diff --stat` to confirm scope
- `/push` when satisfied

---

## Step 9 — Clean Up

Shut down teammates first, then delete the team:

```
TeamDelete team-name="[project]-YYYYMMDD"
```

Then remove the worktree and branch:

```bash
git worktree remove [PROJECT_ROOT]-<short-description>
git branch -d wt/<short-description>
```

Do not close the session until worktree removal is confirmed complete.
