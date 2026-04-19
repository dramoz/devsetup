# Global Claude Code Instructions

These instructions apply to **all projects** unless overridden by a project-level `CLAUDE.md`.

---

## Git — auto-commit checkpoints

After completing each discrete task or feature implementation or discrete files
updates like plans or local settings or MD files, automatically commit the
changed files with a descriptive commit message. Treat each commit as a checkpoint,
so work is never lost between steps.

Rules:
- Stage only the files that were actually changed by the task (no `git add -A`).
- Write the commit message in imperative form, one concise sentence describing
  the *what* and *why* of the change.
- Always append the co-author trailer:
  `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`
- If the repo has no `git` history yet, skip silently rather than running
  `git init` without being asked.
- Do **not** push automatically — only commit locally unless the user explicitly
  asks to push.

## Plans — keep in sync with progress

After completing each task, step, or phase described in a plan file (any `*.md`
under a `plans/` directory or named `*plan*`, `*todo*`, `*roadmap*`):
1. Mark the completed item (e.g. `[x]`) in the plan file.
2. Commit the updated plan immediately with a message like
   `Update plan: mark <step> complete`.

## Test plans — keep in sync with implementation

After a plan or feature is created or updated, check whether a corresponding
test plan exists (e.g. `plans/test_plan.md`, `TEST_PLAN.md`, or a `## Test plan`
section in the relevant plan file). If it exists, update it to reflect the new
or changed functionality. If it does not exist, create one. Commit the test plan
update together with (or immediately after) the implementation commit.

## Style — match the existing file

When editing any existing file, mirror its style before adding new content:
- Indentation (tabs vs spaces, width)
- Naming conventions (snake_case, camelCase, kebab-case, UPPER_SNAKE for constants)
- Comment style and placement (inline vs block, punctuation, tense)
- Line length and wrapping
- Blank-line rhythm between sections/functions
- Quote style (single vs double)

Only deviate from the existing style when the user explicitly asks for a
style change or when the project has a linter/formatter that enforces a
different style.

## Python best practices

Apply these when writing or editing Python files:

- **Shebang**: `#!/usr/bin/env python3` for executable scripts.
- **Formatting**: Follow PEP 8; max line length 99 characters.
- **Type hints**: Annotate all function signatures; use `from __future__ import annotations` for forward references.
- **Strings**: Prefer f-strings; avoid `%`-formatting.
- **Paths**: Use `pathlib.Path` instead of `os.path` string manipulation.
- **CLI scripts**: Use `argparse` with a `main()` entry point guarded by `if __name__ == "__main__"`.
- **File I/O**: Always use `with` statements.
- **Logging**: Use the `logging` module; never use bare `print` for diagnostic output in library code.
- **Imports**: stdlib → third-party → local, one blank line between groups.
- **Exceptions**: Catch specific exception types; avoid bare `except:`.

## Bash best practices

Apply these when writing or editing shell scripts:

- **Shebang**: `#!/bin/bash` (scripts targeting Ubuntu/Linux directly) or `#!/usr/bin/env bash` (portable).
- **Safety flags**: `set -euo pipefail` immediately after the shebang.
- **Variables**: Always quote: `"$var"`, `"${var}"`. Use `local` inside functions.
- **Conditionals**: Use `[[ … ]]` instead of `[ … ]`.
- **Command substitution**: Use `$(…)` instead of backticks.
- **Functions**: Extract repeated logic into named functions; declare variables `local`.
- **Dependency checks**: Verify required tools with `command -v <tool> >/dev/null 2>&1 || { echo "…"; exit 1; }` before using them.
- **User prompts**: Use `read -p "… (y/n)? " ok` + `[[ "${ok}" == "y" ]]` pattern (consistent with existing scripts in this repo).
- **Exit codes**: Return meaningful exit codes; use `exit 1` on fatal errors.

## Markdown best practices

Apply these when writing or editing Markdown files:

- **Headings**: Use ATX style (`#`, `##`, …); one blank line before and after each heading.
- **Code blocks**: Always specify the language identifier for fenced blocks (` ```bash `, ` ```python `, etc.).
- **Lists**: Use `-` for unordered lists; use `1.` numbering only for ordered/sequential steps.
- **Line breaks**: One blank line between paragraphs and between list items that contain multiple sentences.
- **Links**: Use reference-style links `[text][ref]` when the same URL appears more than once.
- **Tables**: Align pipe characters for readability; include a header separator row.
- **Trailing content**: No trailing spaces; end the file with a single newline.

## Skills creation

Apply these when creating or editing Claude Code skills (`SKILL.md` files):

### Required YAML frontmatter

```yaml
---
name: skill-name           # kebab-case identifier, matches the directory name
description: >             # CRITICAL — controls when Claude auto-invokes the skill.
  This skill should be used when the user asks to "<trigger phrase>",
  mentions "<keyword>", or discusses <topic area>.
version: 1.0.0             # optional but recommended
---
```

### Invocation control (add only when needed)

```yaml
disable-model-invocation: true   # user-only (side-effect skills: deploy, send, etc.)
user-invocable: false            # Claude-only (background knowledge/conventions)
allowed-tools: Read, Grep, Glob  # restrict tool access when appropriate
context: fork                    # isolate in a subagent
```

### File layout

```
.claude/skills/<name>/
├── SKILL.md            # required — main instructions
├── references/         # supporting docs Claude can link to
└── scripts/            # helper scripts called from SKILL.md
```

### Content guidelines

- Start with `## When This Skill Applies` listing concrete trigger conditions.
- Keep each skill focused on a **single domain**; avoid overlap with other skills.
- Write `description` with explicit phrases users might say — that field drives auto-invocation.
- Use `$ARGUMENTS` to pass user-supplied parameters into the skill body.
- Use `` !`command` `` syntax to inject live context (e.g., git branch, file list).
