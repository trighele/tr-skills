# CLAUDE.md — working notes for this repo

Read this first when picking the work back up. It records what this tree is, how it fits together, and — most importantly — **which behaviours are deliberate customizations**, so a future edit doesn't quietly revert one.

## What this repo is

A curated fork of [Matt Pocock's skills](https://github.com/mattpocock/skills), cut down from ~42 skills to 13 and reworked to match how Tom engineers. This repo is the **source of truth**; it's destined to become a git repo he can clone to any machine.

Layout is flat and deliberate: `skills/tr-<name>/SKILL.md`, one folder per skill, no category directories. That maps one-to-one onto `~/.claude/skills/`, so installing is a copy.

## The flow

```
/tr-setup-skills → /tr-grill-with-docs → /tr-to-spec → /tr-to-tickets → /tr-implement (per ticket) → /tr-cleanup-local
```

**Context hygiene rule** (stated in `tr-ask-tom`, `tr-grill-with-docs`, `tr-to-tickets`, `tr-implement`): grill → spec → tickets stays in **one unbroken context window** so all three build on the same thinking; `/clear` between every ticket, because each ticket is self-contained by construction.

## Skill inventory

| Skill | Purpose | Invocation | Calls |
| --- | --- | --- | --- |
| `tr-ask-tom` | Router over the tree | user | — |
| `tr-setup-skills` | Per-repo config: tracker + domain docs | user | — |
| `tr-setup-devcontainer` | Per-machine `.devcontainer/` | user | — |
| `tr-grill-with-docs` | Interview + domain docs | user | `tr-grilling`, `tr-domain-modeling` |
| `tr-grilling` | Interview primitive | model | — |
| `tr-domain-modeling` | Terminology + ADRs | model | — |
| `tr-to-spec` | Conversation → spec | user | — |
| `tr-to-tickets` | Spec → tickets | user | — |
| `tr-implement` | Ticket → code | user | `tr-tdd`, `tr-code-review` |
| `tr-cleanup-local` | Close out a finished feature | user | `tr-domain-modeling` |
| `tr-tdd` | Red-green-refactor | model | `tr-codebase-design` |
| `tr-code-review` | Standards + Spec review | model | — |
| `tr-codebase-design` | Deep-module vocabulary | model | — |

"user" = `disable-model-invocation: true`, reachable only by typing `/tr-<name>`.

`tr-setup-skills` writes `docs/agents/issue-tracker.md` and `docs/agents/domain.md` into the *target* repo; `tr-to-spec`, `tr-to-tickets`, `tr-code-review`, and `tr-cleanup-local` all read them. That's the only shared state between skills.

## Divergences from upstream

Each of these is intentional. If you're editing a skill and something below looks like a bug, it isn't.

1. **`tr-` prefix, flat layout.** Upstream nests skills under `engineering/`, `productivity/`, `misc/`, `in-progress/`, `deprecated/`. Those folders and every skill outside the inventory above were deleted, and the survivors flattened into `skills/`. *Why:* a tree this small doesn't need taxonomy, and a flat tree copies straight into `~/.claude/skills/`.

2. **Issue trackers cut to GitHub + local markdown.** GitLab, Jira/Linear, and the freeform "describe your workflow" option are gone, along with `issue-tracker-gitlab.md`. *Why:* those are the only two Tom uses; every extra branch is a question he has to answer.

3. **Triage vocabulary removed entirely.** The `triage` skill isn't in this tree, so `triage-labels.md`, Section B of the setup skill, and the `### Triage labels` block are gone. `ready-for-agent` survives as the single status marker — a GitHub label (created on demand) or a `Status:` line locally. *Why:* a five-role label vocabulary with no skill to consume it is dead config.

4. **`tr-grilling` asks one question per turn via `AskUserQuestion`.** Upstream asks the whole frontier at once as numbered markdown. The design tree and frontier logic are unchanged — only delivery differs — and the frontier is recomputed after *every individual answer*, not per round. A text fallback (`❓` / `➡️`) remains for questions that genuinely can't be reduced to 2–4 options. *Why:* Tom focuses better on one decision at a time in the harness question box. *Watch out:* keeping the frontier is what stops one-at-a-time from becoming an aimless drip — don't simplify it away.

5. **`tr-grill-with-docs` hard-stops after the interview.** It has an explicit list of things not to do at the end (no spec, no tickets, no code, no invoking other skills) and a fixed close-out message naming `/tr-to-spec` as the next step. Upstream is a one-liner that delegates and often rolls straight into spec-writing. *Why:* the boundary between "we understand this" and "this is committed to a spec" is Tom's to cross, and it was invisible before.

6. **`tr-implement` gates on a plain-English brief.** Phase 1 produces ≤10 lines (what it does in observable terms / what it touches / how you'll see it work) and then stops for a go-ahead via `AskUserQuestion`. *Why:* tickets are dense; a short brief is how he decides whether the agent understood the ticket before it spends a session on it.

7. **`tr-implement` closes with exactly three sections.** `## Verify it yourself`, `## Not done`, `## Bugs & risks found` — and nothing else. No summary of the diff, no "what I learned". *Why:* the upstream close-out was long enough that the actionable parts got lost. The three questions that matter are: how do I check this, what did you skip, what did you notice.

8. **`tr-implement` does not commit.** Upstream commits to the current branch. *Why:* Tom reviews and commits himself.

9. **`tr-ask-tom` replaces `ask-matt`.** Rewritten rather than renamed, since the upstream router describes ~20 skills that no longer exist here. `PHASE-BOUNDARIES.md` was dropped; its one surviving rule (context hygiene) is inlined into the router and the skills it applies to.

10. **`tr-cleanup-local` is wholly new.** No upstream equivalent. Runs after the feature is built *and reviewed*: promotes anything durable from the spec and tickets into `CLAUDE.md`, then deletes the feature's `.scratch/` directory. *Why:* on a local-markdown tracker the spec and tickets are working files with no home once the work lands, and they accumulate across features. *Design points worth keeping:* it's local-tracker-only (on GitHub the tickets already live somewhere durable); promotion happens **before** deletion, because `.scratch/` is usually untracked and therefore the only copy; "nothing worth promoting" is an explicitly valid outcome, so the step can't pressure the agent into padding `CLAUDE.md` with feature changelogs; and deletion is scoped to the one confirmed feature directory, never a wholesale `.scratch/` wipe.

11. **`tr-setup-devcontainer` is wholly new.** No upstream equivalent. Ubuntu base, `~/.claude` bind-mounted whole, Claude Code installed in-container, and a heavy emphasis on **git parity** — the container showing the same history/status/branches as the host — which is the failure Tom hits most. Four reference files: `profiles.md`, `git-parity.md`, `proxy-and-certs.md`, `claude-in-container.md`.

### The `${localEnv:USERPROFILE}${localEnv:HOME}` trick

Used throughout `tr-setup-devcontainer`. Exactly one of the two variables is set on any host (Windows sets `USERPROFILE`, macOS/Linux set `HOME`), so the concatenation resolves to whichever exists and the unset one expands to empty. This is what lets a single `devcontainer.json` work on all three machines. It looks like a typo; it isn't.

## Untouched by design

`C:\Users\Tom\.claude\skills\msk-*` is a separate, older install of these skills from before this repo existed. **This repo never reads, writes, syncs to, or references it.** Leave it alone.

## Conventions when editing

- `name:` in frontmatter must equal the folder name exactly.
- User-invoked skills keep `disable-model-invocation: true`; model-invoked ones must have a `description` rich in trigger phrasing.
- Keep `agents/openai.yaml` in sync when renaming (`display_name`, and `policy.allow_implicit_invocation: false` mirrors `disable-model-invocation`).
- Cross-references in prose use the `/tr-` prefix. A bare `/grilling` or `/implement` is a bug.
- Skills are written for an agent to *act on*, not for a human to admire: imperative, specific, and explicit about what **not** to do. Where a rule exists because of a past failure, say so — that's what makes it stick.

## Verification after any change

```bash
cd skills

# 1. No references to removed skills
grep -rn "setup-matt-pocock-skills\|ask-matt\|/triage\|/wayfinder\|/prototype\|/handoff\|/grill-me\|/research\|/diagnosing-bugs\|improve-codebase-architecture\|/wizard\|/wait-what\|resolving-merge-conflicts\|msk-" .

# 2. Frontmatter name matches folder name
for d in tr-*/; do n="${d%/}"; grep -q "^name: $n$" "$d/SKILL.md" || echo "MISMATCH: $n"; done

# 3. Relative links resolve
grep -rhoE '\]\(\./[^)]+\)' tr-*/SKILL.md
```

Checks 1 and 2 must produce no output. Check 3 lists the links; confirm each target exists.

Then a live run: install into a scratch project and walk `/tr-setup-skills` → `/tr-grill-with-docs` → `/tr-to-spec` → `/tr-to-tickets` → `/tr-implement`, confirming the four behaviours that were customized (two tracker options only; one question at a time; grilling stops without writing a spec; implement briefs then reports in three sections).

## Open threads

- **Re-adding skills.** `diagnosing-bugs`, `prototype`, and `research` were deliberately cut but are the most likely to be missed. They're recoverable from upstream if a gap shows up in practice — don't re-add speculatively.
- **Distribution.** Currently raw skill folders + a copy command. Publishing as a Claude Code plugin marketplace would make installs and updates a single command; worth revisiting once the repo is on GitHub and stable.
- **Dev container validation.** The generated container hasn't been exercised on the work machine or the MacBook yet, only designed for them. The proxy/CA path in particular is written from known failure modes rather than from a verified run — expect to refine `proxy-and-certs.md` after the first real work-machine build.
