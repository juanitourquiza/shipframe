---
name: generate-readme
description: Generate a project README.md following the ShipFrame team-ready standard. Scans the current codebase to detect the tech stack, project purpose, and available commands, then produces a complete, structured README. Use when starting a new project or when a README is missing or outdated.
allowed-tools: AskUserQuestion Glob Read Grep Write
effort: medium
---

# generate-readme

Generate a `README.md` file following the ShipFrame team-ready standard. Scan the project to auto-detect as much as possible, then ask only what cannot be inferred.

---

## Step 1 — Gather project context

Scan the project root to detect the tech stack and structure. Use Glob and Read tools — do not guess.

**Detect:**

- **Language & runtime:** `package.json`, `composer.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pubspec.yaml`
- **Framework:** check dependencies in `package.json` for `next`, `react`, `vue`, `nuxt`, `express`, `fastify`, `laravel` (via `composer.json`), etc.
- **Database:** look for `prisma`, `drizzle-orm`, `typeorm`, `mongoose`, `pg`, `mysql2`, `sqlite3`, `@supabase`, `pgsql` in dependency files or config files
- **Package manager:** `pnpm-lock.yaml` → pnpm, `yarn.lock` → Yarn, `bun.lockb` → Bun, `package-lock.json` → npm
- **Build tools:** `vite.config.*`, `webpack.config.*`, `turbo.json`
- **Container/infra:** `Dockerfile`, `docker-compose.*`
- **CI/CD:** `.github/workflows/`
- **Dev commands:** read `package.json` scripts section, `Makefile`, or `composer.json` scripts

Read these files if they exist:
- `package.json`
- `composer.json`
- `README.md` (first 50 lines — to avoid overwriting intentional content)
- `.env.example` (keys only, never values)

---

## Step 2 — Ask the user for missing information

After scanning, ask only for information that could not be inferred from the codebase. Use `AskUserQuestion` with a single call covering all needed fields at once (1–4 questions max).

Always ask:
1. **Project name + repository clone URL** — if not clear from `package.json`, `composer.json`, or folder name
2. **Short project description** — one sentence explaining what the project does
3. **Credentials/config location** — where developers get environment variable values (e.g. Passbolt, 1Password, a shared drive link — never hardcode actual values)
4. **Contact info** — Project Manager name + email, Tech Lead name + email

Only ask for stack details if they genuinely could not be detected.

---

## Step 3 — Generate README.md

If `README.md` already exists and contains non-placeholder content, ask for confirmation before overwriting and preserve any clearly intentional hand-written sections.

Write `README.md` at the project root using the template below. Fill every section with real detected values. Use placeholder text only where data is unavailable and mark it with `<!-- TODO: fill in -->`.
Rules:
- Use the project's actual logo if `public/` or `assets/` contains an `.svg` or image with "logo" in the name; otherwise omit the `<img>` tag.
- List only the stack components actually detected — do not invent extras.
- Commands table: list only commands that exist in `package.json` scripts, `Makefile`, or `composer.json` scripts. Do not fabricate commands.
- Keep the tone professional but friendly, matching the example format.
- Never include sensitive values (passwords, API keys, tokens).

---

### README.md template

````markdown
<div align="center">
<img src="./public/<logo-file>" alt="icon">
<h3>
 <project-name> 🚀 ShipFrame
</h3>


   <a href="#-stack">
        Stack
    </a>
    <span>&nbsp;✦&nbsp;</span>
    <a href="#-getting-started">
        Getting Started
    </a>
    <span>&nbsp;✦&nbsp;</span>
   <a href="#-useful-commands">
        Commands
    </a>
    <span>&nbsp;✦&nbsp;</span>
    <a href="#-contribution">
        How to contribute
    </a>
    <span>&nbsp;✦&nbsp;</span>
    <a href="#-deployment">
        How to do a deployment
    </a>
    <span>&nbsp;✦&nbsp;</span>
    <a href="#-contact">
        Contact
    </a>
</div>


## 🛠️ Stack

To start working with <project-name> you will need to have some tools previously installed.

#### Prerequisites

-   SO: OSX, Linux, Windows with WSL2
<!-- List only prerequisites that are genuinely required based on detected stack -->
-   [**<Runtime & version>**](<official-url>)
-   [**<Package manager>**](<official-url>)
-   [**<Database>**](<official-url>)

#### Technical Information

<!-- List only what was detected -->
-   [**<Framework & version>**](<official-url>)
-   [**<Key library>**](<official-url>)
-   [**<Container/infra tool>**](<official-url>)

## 🧑‍💻 Getting Started

1. **Clone** this repository.

```bash
git clone git@github.com:<org>/<repo>.git
```

2. Copy the `.env.example` file to `.env` and set all the necessary environment values.

```bash
cp .env.example .env
```

You can find the credentials in [<credentials-location>](<credentials-url-if-provided>). If you don't have access, please [contact](#-contact) your Project Manager or Tech Lead.

3. Install the dependencies.

<!-- Adapt to the detected package manager and language -->
```bash
<install command>
```

4. <!-- Add any additional required setup steps detected from README or scripts, e.g. key generation, migrations, seed -->

5. Run the development server.

```bash
<dev command>
```

## 🖥️ Useful Commands

| | Command | Action |
| :-- | :----------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
<!-- List only commands that exist in scripts -->
| ⚙️ | `<command>` | <what it does> |

> Commands used in this project are from <tooling>. <!-- Add a relevant cheatsheet link if applicable -->

## 🧠 Contribution

There are some "rules" to follow if you want to contribute to this project.

#### Branch Naming

To start contributing you will need to create a branch from your development branch following these steps:

1. Identify the ticket of your task in [ClickUp](https://app.clickup.com/31625254/home).

2. Once you identify the ticket, note its ID (found in the URL or in the left corner of the modal).

3. Our branch naming convention is based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary) followed by the ClickUp task ID:

-   **fix**: patches a bug (correlates with PATCH in Semantic Versioning).
-   **feat**: introduces a new feature (correlates with MINOR in Semantic Versioning).
-   **hotfix**: patches a bug live in PRODUCTION (promote to production ASAP).

Branch name format: `feat/CU-[ClickUp task ID]-[optional-detail]`
Examples: `feat/CU-86aydqtf5-Login` or `feat/CU-86aydqtf6`

#### Descriptive Commits

Make commits referencing the ClickUp ID: `feat/CU-[ID] Task title`

#### Create a PR

Include the following in your Pull Request description:

-   **Explanation of Unrelated Changes:** If there are changes unrelated to the ticket, explain why they were included.
-   **Screenshots:** Attach screenshots of screens that changed to facilitate visual review.
-   **Other tickets affected:** If the changes affect other tickets, list them and leave a comment on those tickets with the PR URL.

> **IMPORTANT:** Never add sensitive information to the repository (passwords, API keys, etc.)

> **REMEMBER:** Keep PRs as small and focused as possible.

## 🚀 Deployment

<!-- Describe the CI/CD pipeline detected or ask the user to fill this in -->
We use CI/CD for deployments. To deploy, merge an approved PR to the correct branch:

-   **`<environment>`** environment → merge PR to `<branch>` branch.

## 📞 Contact

For support or questions, please contact:

Project Manager: <a href="mailto:<pm-email>"><pm-name></a>

Tech Lead: <a href="mailto:<tl-email>"><tl-name></a>
````

---

## Step 4 — Write the file and confirm

Write the completed `README.md` to the project root.

Then report:
- What was auto-detected vs. what the user provided
- Any sections left with `<!-- TODO: fill in -->` placeholders and why
- Reminder not to commit sensitive values

Do not continue or suggest further steps after reporting.
