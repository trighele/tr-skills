# tr-skills

Tom's engineering skill tree for [Claude Code](https://claude.com/claude-code). Thirteen skills, one main flow: sharpen an idea, spec it, split it, build it, clean up after it.

Adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills), trimmed to the flow I actually use and reworked to match how I like to work. See [CLAUDE.md](./CLAUDE.md) for what diverges from upstream and why.

## The flow

```
/tr-setup-skills          once per repo
        │
/tr-grill-with-docs       sharpen the idea, one question at a time
        │                 (writes CONTEXT.md + ADRs, nothing else)
/tr-to-spec               collapse the conversation into a spec
        │
/tr-to-tickets            split it into tracer-bullet tickets
        │
/tr-implement <ticket>    brief → build test-first → review → report
        │                 (/clear between tickets)
/tr-cleanup-local         promote what's durable, bin the .scratch/ files
```

Small change? Grill, then `/tr-implement` in the same window. Steps 2 and 3 exist to survive a `/clear`.

Not sure what to run? `/tr-ask-tom`.

## The skills

| Skill | What it does |
| --- | --- |
| [`tr-ask-tom`](./skills/tr-ask-tom/) | Router over this tree — which skill fits your situation |
| [`tr-setup-skills`](./skills/tr-setup-skills/) | Configure a repo: issue tracker (GitHub or local markdown) + domain doc layout |
| [`tr-setup-devcontainer`](./skills/tr-setup-devcontainer/) | Generate a `.devcontainer/` matched to the machine you're on |
| [`tr-grill-with-docs`](./skills/tr-grill-with-docs/) | Relentless interview that builds `CONTEXT.md` and ADRs as it goes |
| [`tr-grilling`](./skills/tr-grilling/) | The interview primitive: design tree, frontier, one question per turn |
| [`tr-domain-modeling`](./skills/tr-domain-modeling/) | Sharpen domain terminology; write ADRs |
| [`tr-to-spec`](./skills/tr-to-spec/) | Turn the conversation into a spec on the tracker |
| [`tr-to-tickets`](./skills/tr-to-tickets/) | Split a spec into vertical slices with blocking edges |
| [`tr-implement`](./skills/tr-implement/) | Build a ticket: brief, gate, TDD, review, three-section report |
| [`tr-tdd`](./skills/tr-tdd/) | Red-green-refactor |
| [`tr-code-review`](./skills/tr-code-review/) | Two-axis review of a diff: Standards and Spec |
| [`tr-cleanup-local`](./skills/tr-cleanup-local/) | Close out a finished feature: promote durable notes to `CLAUDE.md`, delete its `.scratch/` files |
| [`tr-codebase-design`](./skills/tr-codebase-design/) | Deep-module vocabulary: interfaces, depth, seams |

## Install

Copy the skill folders into your Claude Code skills directory:

```bash
# macOS / Linux
cp -r skills/tr-* ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse skills\tr-* $env:USERPROFILE\.claude\skills\
```

Then restart Claude Code. User-invoked skills appear as `/tr-*` slash commands.

## Credit

The core skills here are Matt Pocock's, from [mattpocock/skills](https://github.com/mattpocock/skills). The customizations, `tr-ask-tom`, `tr-setup-devcontainer`, and `tr-cleanup-local` are mine.
