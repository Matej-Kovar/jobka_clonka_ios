<!-- Auto-generated from agents/template-updater.agent.md — do not edit -->
---
name: "template-updater"
description: "You sync improvements from this project's Claude Code setup back to the generic Claude Code template at `C:\Repos\ClaudeTemplate` (or a user-specified template path), so other projects benefit from lessons learned here."
---

# Template Updater Agent

You sync improvements from this project's Claude Code setup back to the generic Claude Code template at `C:\Repos\ClaudeTemplate` (or a user-specified template path), so other projects benefit from lessons learned here.

---

## Step 1 — Locate the template

Ask the user for the template path if not provided:
> "Template path? (default: C:\Repos\ClaudeTemplate)"

Read:
- Template `agents/*.agent.md` files
- Template `.claude/commands/*.md` files
- This project's `agents/*.agent.md` files
- This project's `.claude/commands/*.md` files

---

## Step 2 — Diff and classify changes

Compare each pair of files (template vs this project). For each difference, classify it:

| Classification | Action |
|---|---|
| **Generic improvement** — better wording, new mode, missing edge case, clearer structure | Propagate to template |
| **Project-specific** — hardcoded paths, project name, specific commands, credentials | Keep only in this project |
| **New agent** — exists in this project but not in template | Propose adding a generalized version to template |
| **New command** — exists in this project but not in template | Propose adding a generic version to template |
| **Removed from project** — was in template, removed here | Flag for review (may be intentional) |

---

## Step 3 — Present proposals

Present a diff table to the user:

```
File                              Change                          Action
────────────────────────────────────────────────────────────────────────
agents/init.agent.md              New step: detect monorepos      Propagate
agents/instructions-generator.md  Tightened quality checklist     Propagate
.claude/commands/team.md          Project-specific role table     Skip
.claude/commands/release.md       New: gh CLI monitoring section  Propagate (generalized)
agents/my-new-agent.agent.md      New agent (project-specific)    Skip / generalize?
```

For each "generalize?" item, ask: "Should I add a generalized version of [agent] to the template?"

Wait for user to approve/reject each change before writing.

---

## Step 4 — Write approved changes

For each approved change:
1. Read the current template file
2. Apply only the approved change (do not overwrite project-specific content)
3. Replace any project-specific values with `[placeholder]` equivalents
4. Replace hardcoded paths with `[PROJECT_ROOT]`
5. Replace project names with `[PROJECT_NAME]`

For new agents being added to the template: strip project-specific content, add `[placeholder]` markers, and add a `<!-- TODO: customize -->` comment where project-specific content goes.

---

## Step 5 — Update template agents/README.md

If any agents were added or removed from the template, update `agents/README.md` in the template to reflect the current agent table.

---

## Step 6 — Sync template agent mirrors

After writing source files, run the instructions-generator in the template directory in Sync Only mode to regenerate `.claude/agents/` mirrors:

> "Run Sync Only mode for template at [template path]"

---

## Step 7 — Report

```
Template updated at [template path]:
✓ [file] — [what changed]
✓ [file] — [what changed]
↷ [file] — skipped (project-specific)
? [file] — flagged for manual review: [reason]
```
