---
name: wiki-query
description: Answer questions from the active project wiki by reading the index and relevant wiki pages.
allowed-tools: Read Glob
effort: low
---

# wiki-query

Smart search in any LLM wiki vault.

Implements the QUERY flow of the LLM Wiki pattern: find information
in the wiki quickly and precisely, without unnecessary traversal.

Works with any vault that follows the standard LLM wiki structure,
regardless of the topic (a course, a project, personal notes, etc.).

---

## Step 0 — Discover the wiki

Before searching, locate the wiki in the current directory.
Look for a `wiki/` folder containing an `index.md` file. This file
is the master catalog and the mandatory entry point.

If `wiki/index.md` is not found, check if there is a `CLAUDE.md` at the
root — it may indicate where the wiki is or what the main folder is called.

If there is no wiki, tell the user: "I can't find a wiki in this folder.
Would you like me to create one?" (and if so, use the wiki-forge skill).

---

## Step 1 — Scan the index

Read `wiki/index.md`. This file lists all wiki pages with a one-line
summary each, organized by category (the wiki subdirectories).

From the index, identify the 1-3 pages most relevant to the user's question.
The key: the index already tells you what each page contains.
You don't need to open all of them — only the ones that fit.

---

## Step 2 — Read the relevant pages

Open only the pages identified in the previous step. Each page has:

- **YAML frontmatter**: tags, type, sources, dates — useful for filtering
- **Content**: the text with the information
- **Wikilinks** `[[page-name]]`: links to related pages

If a page references another via wikilink and that reference seems important
to complete the answer, open it too. But don't chain long read sequences —
2-3 pages are usually enough.

---

## Step 3 — Synthesize and answer

Answer the user's question citing the wiki pages consulted.
Natural and direct format. At the end, include the sources as references:

> Sources: [[page-name-1]], [[page-name-2]]

---

## When to go to the original sources

Many wikis have a `raw/` folder with raw materials
(transcripts, articles, original documents). These are immutable.

Only go to `raw/` if:

- The user asks for an exact verbatim quote
- The wiki doesn't have enough detail to answer
- You need to verify something specific

Pages in the `sources/` subfolder of the wiki are summaries of each
original source — they work as a bridge between the processed wiki and
the raw material. Check them first before going directly to `raw/`.

---

## What NOT to do

- **Do not grep or launch agents**. The index exists precisely
  to avoid brute-force searches. Use it.
- **Do not read all pages "just in case"**. Read the index, identify
  the relevant ones, and go directly.
- **Do not answer without consulting the wiki**. The purpose of this skill
  is that the answer comes from the pages, not from general knowledge.
- **Do not invent information**. If it's not in the wiki, say so clearly.
  You can suggest the user ingest new information with wiki-forge.
