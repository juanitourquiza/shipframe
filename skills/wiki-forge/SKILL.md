---
name: wiki-forge
description: Converts any collection of documents into an interconnected LLM knowledge wiki following the Karpathy LLM Wiki pattern. Ingests transcripts, reports, PDFs, articles, and notes — transforming them into markdown pages with wikilinks, YAML frontmatter, and a navigable index. Supports SETUP, INGEST, LINT, and MERGE operations.
allowed-tools: Read Write Edit Glob Bash AskUserQuestion
effort: high
---

# wiki-forge

Transforms raw documents into living knowledge wikis.

Core idea: the LLM reads sources once, extracts knowledge, and organizes it
into interlinked markdown pages that grow richer with each new source.
Knowledge accumulates — it is not re-derived on every query.

---

## The 4 operations

SETUP → INGEST (batch) → LINT → repeat.
For queries, use `/wiki-query`.

---

## SETUP — Create a new vault


Before creating anything, understand the project. If the user provides material
without explanation, infer from the content — acting beats asking.
If there is genuine ambiguity, ask only what is essential:

- **Domain** (what is this about?)
- **Source types** (what material will be ingested?)
- **Language** (detect from the material if not specified)

With that:

1. Create the folder structure (see Architecture below).
2. Move the user's sources into `raw/`.
3. Generate `WIKI.md` at the root — use `templates/wiki/wiki-md-template.md`
   substituting all `{{}}` placeholders.
4. Generate `.claude/wiki-conventions.md` — use
   `templates/wiki/conventions-template.md` substituting `{{VAULT_NAME}}` and
   `{{LANGUAGE}}` with the vault's values.
5. Create empty `wiki/index.md` and `wiki/log.md`.

> **Tip:** For a guided setup that asks all the right questions, use `/wiki-init` instead.

### Vault architecture

```
vault-name/
├── CLAUDE.md                    ← Orientation: structure, sources, skills
├── .claude/
│   └── wiki-conventions.md     ← Wiki standards: format, language, wikilinks
├── raw/                        ← Original sources — IMMUTABLE
│   └── [user structure]
├── wiki/
│   ├── index.md                ← Master catalog
│   ├── log.md                  ← Operation history
│   ├── logs/                   ← One file per sync (/wiki-sync)
│   ├── sources/                ← One summary per ingested source
│   └── [categories]/           ← Subdirectories adapted to the domain
```

### Detecting source structure

Analyze how the sources are organized before ingesting:

| Corpus structure | `sources/` granularity |
|---|---|
| Course with modules and lessons | One source page per module |
| Periodic meetings | One page per meeting or sprint |
| Slack / Discord channel | One page per thread or topic |
| Collection of articles / PDFs | One page per document |
| Standalone YouTube videos | One page per video |
| Loose notes | Group by topic or one per note |

Each `sources/` page must include wikilinks to all raw files it covers —
this connects the originals to the wiki graph.

---

## INGEST — Process sources

### Step 0 — Load conventions

Read `.claude/wiki-conventions.md`. All pages created or modified in this
operation must follow those conventions without exception.

### Steps

1. Read the source in full from `raw/`.
2. Classify the type (transcript, report, meeting, article, notes...).
3. Extract domain entities — the content dictates what to extract:
   concepts, techniques, tools, people, decisions, data, relationships.
4. Create or update wiki pages:
   - Always one page in `sources/` with wikilinks to the raw files it covers.
   - Thematic pages in the corresponding categories.
   - If a page already exists: extend with new content, do not duplicate.
5. Link densely with `[[wikilinks]]` — follow the rules in
   `wiki-conventions.md` (minimum count, distribution, no broken links).
6. Update `wiki/index.md`.
7. Log in `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] ingest | Source name
   - Pages created: X
   - Pages updated: Y
   - Entities extracted: brief list
   ```

### Rules by source type

- **Transcripts** (YouTube, courses, podcasts): clean filler words.
  Extract logical structure, not temporal. Preserve practical examples.
- **Meetings**: preserve who said what if relevant. Extract
  decisions, action items, and context.
- **Reports / PDFs**: respect the document structure. Extract
  quantitative data, conclusions, recommendations.
- **Web articles**: distinguish facts from opinions. Record author, date, and URL.
- **User notes**: high-priority primary source. Integrate
  respecting the original intent.

### Batch ingest

1. List everything in `raw/`.
2. Order: chronological, by complexity, or by conceptual dependencies
   (basics first so foundational concepts exist before advanced ones).
3. Process one at a time, updating index and log after each.
4. When done, run LINT.

### Delegating to subagents

Follow the delegation instructions in `.claude/wiki-conventions.md` exactly.
Include all 4 mandatory elements in each subagent prompt.

---

## LINT — Maintenance

### Step 0 — Load conventions

Read `.claude/wiki-conventions.md` before running any check.

### Checklist (run all and report concrete numbers)

1. **Frontmatter**: 100% of pages with the exact 5 fields defined in
   `wiki-conventions.md`. Fix any that fail.
2. **Language**: 100% of pages in the language defined in `wiki-conventions.md`.
   Fix any in a different language.
3. **Ghost links**: 0 broken wikilinks. List all `[[wikilink]]` targets
   and verify they exist as `.md` files. Create missing pages or fix links.
4. **Density**: all thematic pages with at least 8 wikilinks distributed
   throughout the body. Fix those below threshold.
5. **Incoming links**: all thematic pages with at least 5 incoming links.
   Add links from related pages if needed.
6. **Raw linked**: all files in `raw/` referenced from at least
   one page in `sources/`.
7. **Orphans**: wiki pages with no incoming links — connect them or delete them.
8. **Gaps**: concepts mentioned repeatedly without their own page — create them.

Log results in `wiki/log.md` with the check numbers.

---

## MERGE — Connect wikis

If there are multiple vaults:

1. List the wikis and their domains.
2. Identify shared entities.
3. Create inter-vault links or propose consolidation.
4. Do not mix the `raw/` folders of different projects.
