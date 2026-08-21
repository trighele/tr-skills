---
name: tr-setup-skills
description: "Configure this repo for the TR engineering skills: set up its issue tracker and domain doc layout. Run once before first use of the other skills in this tree."
disable-model-invocation: true
---

# Setup TR Skills

Scaffold the per-repo configuration that the TR engineering skills assume:

- **Issue tracker**: where issues live. Two options only, GitHub or local markdown.
- **Domain docs**: where `CONTEXT.md` and ADRs live, and the consumer rules for reading them

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config`: is this a GitHub repo? Which one?
- `AGENTS.md` and `CLAUDE.md` at the repo root: does either exist? Is there already an `## Agent skills` section in either?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/`: does this skill's prior output already exist?
- `.scratch/`: a sign that a local-markdown issue tracker convention is already in use
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These are present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing in a few lines. Then take the two sections in order, one at a time, using `AskUserQuestion` so each is a single focused choice. Lead with the recommended answer so it can be accepted in one word, and skip a section entirely when exploration already settled it.

**Section A: Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. `/tr-to-spec`, `/tr-to-tickets`, and `/tr-code-review` read from and write to it. They need to know whether to call `gh issue create` or write a markdown file under `.scratch/`.

Exactly two choices, no others:

- **GitHub**: issues live in the repo's GitHub Issues (uses the `gh` CLI). Propose this when a `git remote` points at GitHub.
- **Local markdown**: issues live as files under `.scratch/<feature>/` in this repo. Propose this otherwise: no remote, a non-GitHub remote, or a solo project where GitHub Issues would be overhead.

If the remote points somewhere that is neither, say so plainly and default to local markdown. Do not offer GitLab, Jira, Linear, or a freeform "describe your workflow" option; this tree supports GitHub and local only.

Record the choice in `docs/agents/issue-tracker.md`.

**Section B: Domain docs.** Default to **single-context** (one `CONTEXT.md` + `docs/adr/` at the repo root). This fits almost every repo; write it without asking.

Offer **multi-context** (a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files) only when exploration found monorepo signals. Then confirm which layout they want.

### 3. Confirm and edit

Show the user a draft of:

- The `## Agent skills` block to add to whichever of `CLAUDE.md` / `AGENTS.md` is being edited (see step 4 for selection rules)
- The contents of `docs/agents/issue-tracker.md` and `docs/agents/domain.md`

Let them edit before writing.

### 4. Write

**Pick the file to edit:**

- If `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If neither exists, ask the user which one to create; don't pick for them.

Never create `AGENTS.md` when `CLAUDE.md` already exists (or vice versa); always edit the one that's already there.

If an `## Agent skills` block already exists in the chosen file, update its contents in-place rather than appending a duplicate. Don't overwrite user edits to the surrounding sections.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Then write the docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [domain.md](./domain.md): domain doc consumer rules + layout

### 5. Done

Tell the user the setup is complete and which skills will now read from these files. Mention they can edit `docs/agents/*.md` directly later; re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.

If they haven't set up a dev container for this project yet, mention `/tr-setup-devcontainer` as the other per-project setup step.
