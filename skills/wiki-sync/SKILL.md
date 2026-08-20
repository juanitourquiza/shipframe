---
name: wiki-sync
description: Sync the project wiki with source changes since origin/main, updating docs and the wiki operation log.
allowed-tools: Read Write Edit Bash
effort: medium
---

# wiki-sync

Incrementally updates the wiki based on what changed in the source repos
since the last sync. Reads only the diff — never re-scans everything.

Output messages to the user in the same language as the wiki (see wiki-conventions.md).

---

## Step 0 — Load conventions and config

Read two files:

1. `.claude/wiki-conventions.md` — authoritative source for all wiki standards.
   Every wiki edit must follow those conventions exactly.

2. `wiki/sync-config.md` — list of source repos and file impact patterns.
   This file defines which repos to sync and which file patterns have wiki impact.

If `wiki/sync-config.md` doesn't exist, abort:
> "wiki/sync-config.md not found. Run /wiki-init to configure repos, or create it manually."

Parse `wiki/sync-config.md` to extract:
- `REPOS`: list of `{ name, path }` objects from the Repositorios table
- `IMPACT_PATTERNS`: per-repo list of file glob patterns with wiki impact
- `NO_IMPACT_PATTERNS`: list of patterns to ignore

If `REPOS` is empty or "(ninguno)", inform the user:
> "No source repos configured in wiki/sync-config.md. Nothing to sync."
Then stop.

---

## Step 1 — Read the sync state

Read `wiki/sync.md`. It contains the last synced commit hash for each repo.

Format expected:
```
# Wiki Sync State

| Repo | Last synced hash | Date |
|------|-----------------|------|
| repo-name | abc1234 | YYYY-MM-DD |
```

If `wiki/sync.md` doesn't exist, treat all repos as first-time syncs.
Use `git -C [path] rev-parse --short origin/main` to get the current origin/main as a baseline,
then run a full scan of recently modified files instead of a diff.

---

## Step 2 — Compute the diff for each repo

For each repo in `REPOS`, first fetch the latest remote state:

```bash
git -C [repo.path] fetch origin main 2>/dev/null
```

Then compute the diff against `origin/main`:

```bash
git -C [repo.path] log [last-hash]..origin/main --name-status --pretty=format:"" 2>/dev/null
```

Where `[last-hash]` comes from `wiki/sync.md` for that repo.
If the repo has no entry in sync.md (first sync), use an empty diff and
treat the full file list as Added.

Status letters: `A` = Added, `M` = Modified, `D` = Deleted, `R<score>` = Renamed.

If all diffs are empty across all repos:
> "Everything is up to date. No changes since last sync."
Then stop — do not modify anything.

---

## Step 3 — Classify each changed file

For each changed file, check against the patterns in `wiki/sync-config.md`:

**Has wiki impact** — matches a pattern in `IMPACT_PATTERNS` for its repo.

**No wiki impact** — matches a pattern in `NO_IMPACT_PATTERNS`, or matches
none of the impact patterns.

Group files by: has-impact vs no-impact. Only process the has-impact group.

---

## Step 4 — Apply changes to the wiki

Follow conventions loaded in Step 0 for all edits.

### Added (`A`) or Modified (`M`)

1. Read the file from the repo.
2. Identify which wiki page(s) cover it (`wiki/index.md` as reference).
3. Update those pages — amplify, do not rewrite. Add or adjust only what
   the changed file introduces; preserve everything else.
4. If no page covers this file and it introduces a meaningful new concept,
   create a new wiki page following the format in `wiki-conventions.md`.
5. Update `wiki/index.md` if a new page was created.

### Deleted (`D`)

1. Identify wiki page(s) that document this file.
2. Whole page is about this file → delete the wiki page.
3. File is one part of a larger page → remove only that section.
4. Remove deleted page from `wiki/index.md`.
5. Find all `[[wikilinks]]` pointing to the deleted page and fix them.

### Renamed (`R`)

1. Cosmetic rename (path change only): update path references, no content change.
2. Semantic rename (purpose changed): treat as Delete + Add.
3. If a wiki page was named after the old file, rename it and update
   `wiki/index.md` and all inbound wikilinks.

### After all changes

Scan modified pages for `[[wikilinks]]` that don't resolve to an existing
`.md` file. Fix any ghost links before proceeding.

---

## Step 5 — Update sync state

For each repo, get the current `origin/main` hash:

```bash
git -C [repo.path] rev-parse --short origin/main 2>/dev/null
git -C [repo.path] log -1 origin/main --pretty=format:"%s" 2>/dev/null
```

Overwrite `wiki/sync.md` with the new hashes and today's date:

```markdown
# Wiki Sync State

| Repo | Last synced hash | Date |
|------|-----------------|------|
| [repo.name] | [new-hash] | YYYY-MM-DD |
```

---

## Step 6 — Create sync log file

Create `wiki/logs/YYYY-MM-DD.md` (today's date).
If the file already exists (multiple syncs today), append to it.

```markdown
# Sync — YYYY-MM-DD

## Resumen

[For each repo:]
- [repo.name]: `<old-hash>` → `<new-hash>` (<N> commits)

## Cambios en la wiki

### Páginas actualizadas
- `ruta/pagina.md` — descripción breve de qué cambió

### Páginas creadas
- `ruta/pagina.md` — motivo

### Páginas eliminadas
- `ruta/pagina.md` — motivo

## Archivos del diff con impacto wiki (<N> de <total>)

| Archivo | Repo | Estado | Acción tomada |
|---------|------|--------|---------------|
| `path/to/file` | repo-name | M | Actualizado `wiki/pagina.md` |

## Archivos sin impacto wiki (<N> ignorados)

`tests/SomeTest.php`, `composer.lock`, ...
```

---

## Step 7 — Report to the user

```
Wiki sync complete.

[For each repo:]
[repo.name]: <old-hash> → <new-hash>  (<N> files changed)

Wiki changes:
  Updated:  page-a, page-b
  Created:  page-c          (if any)
  Deleted:  page-d          (if any)

Log: wiki/logs/YYYY-MM-DD.md

Ignored (no wiki impact): tests/SomeTest.php, composer.lock, ...
```

---

## What NOT to do

- Do not re-read the entire codebase. Only read files listed in the diff.
- Do not rewrite wiki pages from scratch — amplify existing content.
- Do not delete a wiki page just because one of its source files changed.
  Only delete when the entire concept it documents was removed.
- Do not update `wiki/sync.md` if the sync failed or was aborted partway.
- Do not ask for confirmation before applying changes.
- Do not invent conventions. All standards come from `.claude/wiki-conventions.md`.
- Do not hardcode repo paths or file patterns — always read from `wiki/sync-config.md`.
