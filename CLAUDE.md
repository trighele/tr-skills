# CLAUDE.md — working notes for this repo

Read this first when picking the work back up. It records what this tree is, how it fits together, and — most importantly — **which behaviours are deliberate customizations**, so a future edit doesn't quietly revert one.

## What this repo is

A curated fork of [Matt Pocock's skills](https://github.com/mattpocock/skills), cut down from ~42 skills to 13, then extended with Tom's own, and reworked to match how Tom engineers. This repo is the **source of truth**; it's destined to become a git repo he can clone to any machine.

Layout is flat and deliberate: `skills/tr-<name>/SKILL.md`, one folder per skill, no category directories. That maps one-to-one onto `~/.claude/skills/`, so installing is a copy — see [INSTALL.md](./INSTALL.md) and `sync.sh`.

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
| `tr-unified-setup` | Empty repo → unified-pipeline app scaffold | user | — |
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

4. **`tr-grilling` asks in rounds, matching upstream — this was reverted, don't flip it back.** It asks the *whole frontier* in one message as numbered markdown (`❓ **Q1**` / `➡️ recommendation`), then recomputes the frontier from the answers and asks the next round. An earlier version of this fork asked one question per turn via `AskUserQuestion`; it was reverted in practice because thirteen questions became thirteen round-trips instead of about three. *Why the format:* a round has to be **answerable by number** — "1 yes, 2 the second option, 3 no because…" — which is what makes batching cheaper than one-at-a-time rather than more confusing. *Kept beyond upstream:* the explicit frontier section, and **pruning** (an answer can moot a whole queued branch, not merely unblock one). *Watch out:* the frontier is what stops the interview going exhaustive; don't simplify it away.

5. **`tr-grill-with-docs` hard-stops after the interview.** It has an explicit list of things not to do at the end (no spec, no tickets, no code, no invoking other skills) and a fixed close-out message naming `/tr-to-spec` as the next step. Upstream is a one-liner that delegates and often rolls straight into spec-writing. *Why:* the boundary between "we understand this" and "this is committed to a spec" is Tom's to cross, and it was invisible before.

6. **`tr-implement` gates on a plain-English brief.** Phase 1 produces ≤10 lines and then stops for a go-ahead via `AskUserQuestion`. *Why:* tickets are dense; a short brief is how Tom decides whether the agent understood the ticket before it spends a session on it. The brief opens with an **"In my words"** line — one sentence restating the ticket *without reusing its phrasing* — because a brief that echoes the ticket's own wording reads fine even when the ticket was misread, which defeats the whole gate.

7. **`tr-implement` closes with exactly four plain-English sections, under hard caps.** `## What you can do now` (one sentence), `## How to test it` (≤3 numbered steps), `## What I didn't finish` (≤4 bullets), `## What I noticed` (≤4 bullets) — and nothing else. Beneath the template sits a *"write it for someone who did not read the code"* block: no jargon (an explicit banned-word list), file and function names **only inside a command to paste**, never in prose, and the whole report fits on one screen. *Why the caps and the language rule exist:* the previous version already said "exactly three sections and nothing else" and it still produced a wall of implementation vocabulary that went over Tom's head. Section headings alone don't bound length or vocabulary — the caps and the banned-word list are what actually bite. *The one thing that outranks the caps* is honesty: a suite that didn't go green belongs in **What I didn't finish** with its failing output, cap or no cap.

8. **`tr-implement` does not commit.** Upstream commits to the current branch. *Why:* Tom reviews and commits himself.

9. **`tr-ask-tom` replaces `ask-matt`.** Rewritten rather than renamed, since the upstream router describes ~20 skills that no longer exist here. `PHASE-BOUNDARIES.md` was dropped; its one surviving rule (context hygiene) is inlined into the router and the skills it applies to.

10. **`tr-cleanup-local` is wholly new.** No upstream equivalent. Runs after the feature is built *and reviewed*: promotes anything durable from the spec and tickets into `CLAUDE.md`, then deletes the feature's `.scratch/` directory. *Why:* on a local-markdown tracker the spec and tickets are working files with no home once the work lands, and they accumulate across features. *Design points worth keeping:* it's local-tracker-only (on GitHub the tickets already live somewhere durable); promotion happens **before** deletion, because `.scratch/` is usually untracked and therefore the only copy; "nothing worth promoting" is an explicitly valid outcome, so the step can't pressure the agent into padding `CLAUDE.md` with feature changelogs; and deletion is scoped to the one confirmed feature directory, never a wholesale `.scratch/` wipe.

11. **`tr-setup-devcontainer` is wholly new.** No upstream equivalent. Ubuntu base, `~/.claude` bind-mounted whole, Claude Code installed in-container, and a heavy emphasis on **git parity** — the container showing the same history/status/branches as the host — which is the failure Tom hits most. Four reference files: `profiles.md`, `git-parity.md`, `proxy-and-certs.md`, `claude-in-container.md`.

12. **`tr-implement` narrates the build with one-line slice markers.** Phase 2 announces each slice as `→ <behaviour>` and nothing else — no file-edit narration, no approach explanation, no progress percentages. *Why:* the build phase used to run long and silent, so the thread of what was happening was lost by the time the report arrived. The markers are also what phase 3 summarises from.

13. **`sync.sh` / `sync.ps1` + `INSTALL.md` are wholly new.** No upstream equivalent that's supported (upstream's `link-skills.sh` is labelled maintainers-only and symlinks). Clone lives outside `~/.claude`; the script pulls, then **copies** `skills/tr-*` into `~/.claude/skills/`. *Why copies, not symlinks:* a symlink into `~/dev/tr-skills` dangles inside a dev container, because the clone isn't mounted there — only `~/.claude` is. *The `.git` rule is about `~/.claude/skills` specifically* — Claude Code keeps its own clones under `~/.claude/plugins/marketplaces/`, so a bare `find ~/.claude -name .git` is not the check. *Design points worth keeping:* the `tr-*` glob is the safety boundary, so `msk-*` and hand-written skills are never touched; **pruning** removes destination `tr-*` dirs no longer in the repo, because a renamed skill otherwise leaves an old copy still answering its slash command; and the script **refuses to create** a missing `~/.claude` rather than inventing one, since an empty one means a wrong path or an unresolved bind mount and creating it silently defers the failure.

14. **`tr-unified-setup` is wholly new.** No upstream equivalent. Scaffolds an **empty** repo as an app repo for Tom's unified pipeline (`tomrighele/project_unifiedPipeline`): one question round (shape, name, exposure), then copies `templates/`. Two shapes only — microservice (`api`, FastAPI/uv) or front end + microservice (`web` React/Vite/TS/nginx + `api` under `/api`, same origin). *Design points worth keeping:* it **refuses non-empty repos** rather than retrofitting; the microservice lives in `apps/api`, not the root, so adding a front end later is an addition rather than a restructure, and the api's path prefix is one constant (`ROUTE_PREFIX`) for the same reason; every component ships a real passing test so `tests: false` never appears; it verifies with the pipeline's own test commands and a root-context `docker build` + health probe; and it doesn't commit, `git init`, or create the GitHub repo. *The templates are hand-maintained copies* of the pipeline's `template/` (the caller workflow byte for byte, `pipeline.yaml` adapted per shape) — when the pipeline's template or its `@v1` pin changes, update `templates/` by hand. Files named `dot-*` in `templates/` become `.`-files on copy, so the tree's own git never reads them as config.

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

# 4. No one-question-at-a-time phrasing survives in the skills (divergence 4 was
#    reverted). Scoped to skills/ on purpose: divergence 4 itself records the history.
grep -rni "one question at a time\|one question per turn\|question box" .

# 5. No unprefixed skill cross-references — a bare `code-review` doesn't resolve
grep -rn '"codebase-design"\|`code-review`\|`tdd`\|`grilling`\|`implement`' .
```

Checks 1, 2, 4 and 5 must produce no output. Check 3 lists the links; confirm each target exists.

Then the installer, into a throwaway destination first:

```bash
cd ..
CLAUDE_SKILLS_DIR=/tmp/skilltest ./sync.sh --no-pull       # 14 tr-* dirs
mkdir /tmp/skilltest/tr-ghost /tmp/skilltest/msk-keepme
CLAUDE_SKILLS_DIR=/tmp/skilltest ./sync.sh --no-pull       # tr-ghost pruned, msk-keepme untouched
find ~/.claude/skills -name .git                           # must stay empty
                                                           # (~/.claude/plugins has its own .git dirs — Claude Code owns those)
```

Then a live run: install into a scratch project and walk `/tr-setup-skills` → `/tr-grill-with-docs` → `/tr-to-spec` → `/tr-to-tickets` → `/tr-implement`, confirming the customized behaviours: two tracker options only; grilling asks a numbered **round** at a time and stops without writing a spec; implement briefs (opening "In my words"), marks slices with `→`, and closes in the four plain-English sections on one screen.

## Open threads

- **Re-adding skills.** `diagnosing-bugs`, `prototype`, and `research` were deliberately cut but are the most likely to be missed. They're recoverable from upstream if a gap shows up in practice — don't re-add speculatively.
- **Distribution.** `sync.sh` / `sync.ps1` cover clone-and-refresh, documented in `INSTALL.md`. The open question is still the Claude Code plugin route (`.claude-plugin/plugin.json` + `marketplace.json`, the way upstream ships): it would drop the script entirely, at the cost of namespacing every command to `/tr-skills:tr-implement` and making the installed copy read-only. Not worth it while the skills are still being edited this often.
- **Dev container validation.** The generated container hasn't been exercised on the work machine or the MacBook yet, only designed for them. The proxy/CA path in particular is written from known failure modes rather than from a verified run — expect to refine `proxy-and-certs.md` after the first real work-machine build.
