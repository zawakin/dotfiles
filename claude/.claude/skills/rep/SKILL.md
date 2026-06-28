---
name: rep
description: Rename a word across a whole git project, safely. The rep CLI finds every place a name appears (inside files and in file/folder names) and changes it to a new name in one careful, checkable pass, instead of hand-editing each file or running risky find-and-replace scripts. It works step by step (scan -> plan -> apply -> residual -> status) so you can see what will change before it changes, and check afterward that the old name is fully gone. Use it when the user wants to rename the same thing everywhere in a repo: a variable or function name, a package/library name, a namespace, an environment variable, or a directory.
allowed-tools: Bash(rep*), Bash(git*), Read, Grep
---

# rep — safe repo-wide rename / token migration

`rep` renames a word everywhere in a project, the safe way. Think of it as a very
careful "find and replace" for an entire codebase: it only touches files that git
already tracks, it shows you the plan before changing anything, and it can prove
afterward that the old name is gone. Every command prints machine-readable JSON,
so always pass `--json` and decide what to do next based on the exit code.

It works in five steps — look first, decide, then change, then double-check:

```text
scan -> plan -> apply -> residual -> status
( find )  ( decide )  ( change )  ( verify )  ( where am I? )
```

## Before you start

- Be inside a git repository (`rep` exits `3` otherwise).
- `apply` requires a **clean tracked tree** (commit or stash first; exit `4` if
  dirty). Untracked files are never touched.
- Mappings are **explicit and literal** — no regex, no auto case handling. Add
  one `--map FROM=TO` per case variant.

## Workflow

### 1. Scan — measure and discover case variants

```bash
rep scan <old-token> --case-insensitive --json
```

Read `content.variants` (e.g. `oldname`, `OldName`, `OLDNAME`) and
`paths.matched_*`. The variants tell you exactly which mappings to write.

### 2. Build the mappings

One mapping per variant found, mapping each to its corresponding new form:

```bash
rep plan \
  --map oldname=newname \
  --map OldName=NewName \
  --map OLDNAME=NEWNAME \
  --rename-paths \
  --json
```

- Add `--rename-paths` only if `scan` reported path matches you want renamed.
- Omit it to change file **contents** only.
- `plan` never modifies the working tree; it writes artifacts under
  `.rep/plans/<plan_id>/` and prints the `plan_id`.

If `plan` exits `2`, the mappings matched nothing — re-check the tokens.
If it exits `6`, there is a path conflict (target exists, two sources collide,
or a case-only rename) — adjust the mappings or resolve the target first.

### 3. Review (optional)

Inspect `.rep/plans/<plan_id>/summary.json` and `content-preview.txt` to confirm
the intended changes.

### 4. Apply

```bash
rep apply --plan <plan_id> --json
```

Guarded by repo/HEAD match, clean-tree, and per-file hash checks. On failure the
exit code says why: `4` dirty tree (commit/stash, retry), `5` stale plan (HEAD
moved — re-plan), `6` path conflict, `7` file changed since plan (re-plan).

### 5. Residual — prove the old token is gone

```bash
rep residual <old-token> --case-insensitive --json
# or, against every mapping FROM in a plan:
rep residual --plan <plan_id> --json
```

`passed: true` (exit `0`) means no occurrences in tracked content or paths.
Exit `8` means residual found — inspect `content.files` / `paths.files`.

### 6. Status

```bash
rep status --json
```

Reports `none` / `planned` / `applied` / `failed` plus the active plan and a
suggested next command.

## Exit codes

```text
0 success            5 stale plan          9 apply failed
1 general error      6 path conflict       10 invalid arguments
2 no matches         7 file hash mismatch
3 not a git repo     8 residual found
4 tracked tree dirty
```

## Recovery

`rep` has no `undo`. Because it only touches tracked files on a clean tree,
revert with git:

```bash
git reset --hard HEAD   # discard an applied change
```

## Notes

- `.rep/` is always excluded and cannot be re-included.
- Scope with `--include GLOB` / `--exclude GLOB` (repeatable).
- For agents: `--json` is the contract — both success and failure print JSON;
  the exit code drives control flow.
