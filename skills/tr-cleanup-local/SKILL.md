---
name: tr-cleanup-local
description: "Close out a finished feature on a local-markdown tracker: promote anything durable from the spec and tickets into CLAUDE.md, then delete the feature's .scratch/ working files so they don't follow you into the next feature."
disable-model-invocation: true
---

# Cleanup Local

The last step of the flow, run **after** the feature is implemented and the user has reviewed it.

Two jobs, strictly in this order:

1. **Promote** — anything in the spec or tickets that a future session would need, and that isn't recorded anywhere permanent yet, goes into `CLAUDE.md`.
2. **Delete** — the feature's `.scratch/` working files, which have now served their purpose.

Order matters. The `.scratch/` files are the *only* copy of that thinking. Never delete before the promotion is written and confirmed.

## Precondition: local tracker only

Read `docs/agents/issue-tracker.md`.

- **Local markdown** → proceed.
- **GitHub** → stop. Say that the tracker is GitHub, so the spec and tickets already live somewhere durable and there's nothing local to clean up. Offer the CLAUDE.md promotion on its own if the user wants it, but do not go hunting for files to delete.

If `docs/agents/issue-tracker.md` is missing, tell the user to run `/tr-setup-skills` and stop.

## 1. Find the feature and check it's actually finished

Identify the feature directory under `.scratch/`. If the user named one, use it. If not, list what's there with each directory's ticket completion state and ask which to clean up — never guess, and never assume the most recent.

Then check it's done, and report anything that isn't:

- **Unfinished tickets** — any issue file under `.scratch/<feature>/issues/` not marked done. List them by number and title.
- **Uncommitted work** — run `git status --short`. Implementation changes still sitting in the working tree mean the review may not be over.
- **Untracked scratch files** — if `.scratch/` is gitignored or untracked (it usually is), deleting is **permanent**: there is no commit to recover from. Say this plainly.

If anything above is true, surface it and ask whether to continue. Don't refuse — the user may have good reasons — but don't proceed silently either.

## 2. Promote what's durable

Read the spec (`.scratch/<feature>/spec.md`) and every ticket, plus the actual diff of what was built (`git log` / `git diff` since the feature started). What was *built* is the authority; the spec describes what was intended, and the two can differ.

Promote only what a **future session with no memory of this feature** would need. The test for each candidate: *would not knowing this cause someone to do the wrong thing later?* If no, leave it out.

**Belongs in `CLAUDE.md`:**

- New commands — how to run, test, seed, or migrate the thing that was just built
- New modules or directories, and what each is for, when it isn't obvious from the name
- Conventions established during the build that aren't enforced by tooling
- Gotchas and constraints discovered the hard way — the "don't do X, it breaks Y" facts that cost time to learn once and should never cost it twice
- Integration points: env vars, external services, credentials the feature now needs

**Does not belong in `CLAUDE.md`:**

- A changelog or narrative of what was done — git history already holds that, and a CLAUDE.md that accretes feature summaries becomes noise that crowds out the parts agents need
- Domain terminology → that belongs in `CONTEXT.md` (`/tr-domain-modeling`)
- Architectural decisions and their rationale → those belong in an ADR under `docs/adr/`
- Anything already recorded in `CONTEXT.md`, an ADR, or `CLAUDE.md` itself
- File paths and code snippets that will go stale on the next refactor

If domain terms or hard-to-reverse decisions surfaced during implementation and never got written down, that's a real gap: write them to `CONTEXT.md` / `docs/adr/` via `/tr-domain-modeling` as part of this step. They are not `CLAUDE.md` material, but they shouldn't be lost either.

**Which file to edit:** `CLAUDE.md` if it exists, else `AGENTS.md`. If neither exists, ask which to create. Never create one when the other is already there.

Merge into the existing structure — extend the section a fact belongs in rather than appending a new one per feature. If it genuinely doesn't fit anywhere, add one well-named section.

**It is a valid outcome for nothing to be promoted.** A feature can be fully self-explanatory from its code. Say "nothing worth promoting" and move to step 3 rather than inventing content to justify the step.

## 3. Confirm, then delete

Show the user, before touching anything:

- The exact `CLAUDE.md` diff you propose (or "no changes")
- The exact list of files and directories you propose to delete
- Whether those files are recoverable from git, or gone for good

Ask for confirmation with `AskUserQuestion`: **Promote and delete** (recommended) / **Promote only, keep the files** / **Cancel**.

On confirmation, apply the CLAUDE.md edit **first**, then delete `.scratch/<feature>/` entirely.

Scope rules:

- Delete only the confirmed feature directory. Never `rm -rf .scratch` wholesale, and never touch a sibling feature directory that wasn't part of this cleanup.
- If `.scratch/` is left empty afterwards, remove the empty directory too.
- Never delete anything outside `.scratch/`. Source files, tests, docs, ADRs, and `CONTEXT.md` are all out of scope, whatever they contain.

Sweeping several finished features at once is fine when the user asks for it — run steps 1–3 per feature, and confirm the full deletion list in one go rather than one prompt per directory.

**Do not commit.** Leave the CLAUDE.md change and the deletions in the working tree for the user to review and commit, consistent with `/tr-implement`.

## 4. Report

Three lines, then stop:

```
Promoted: <what went into CLAUDE.md, or "nothing — the feature was self-explanatory">
Deleted:  <the paths removed>
Left:     <anything deliberately kept, and why — unfinished tickets, files the user chose to keep>
```
