# tr-skills

Tom's engineering skill tree for [Claude Code](https://claude.com/claude-code). Fourteen skills, one main flow: sharpen an idea, spec it, split it, build it, clean up after it.

Adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills), trimmed to the flow I actually use and reworked to match how I like to work. See [CLAUDE.md](./CLAUDE.md) for what diverges from upstream and why.

## The flow

```
/tr-setup-skills          once per repo
        │
/tr-grill-with-docs       sharpen the idea, a round of questions at a time
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
| [`tr-unified-setup`](./skills/tr-unified-setup/) | Scaffold an empty repo as a unified-pipeline app: Python microservice, or React front end + Python API |
| [`tr-grill-with-docs`](./skills/tr-grill-with-docs/) | Relentless interview that builds `CONTEXT.md` and ADRs as it goes |
| [`tr-grilling`](./skills/tr-grilling/) | The interview primitive: design tree, frontier, a round of questions at a time |
| [`tr-domain-modeling`](./skills/tr-domain-modeling/) | Sharpen domain terminology; write ADRs |
| [`tr-to-spec`](./skills/tr-to-spec/) | Turn the conversation into a spec on the tracker |
| [`tr-to-tickets`](./skills/tr-to-tickets/) | Split a spec into vertical slices with blocking edges |
| [`tr-implement`](./skills/tr-implement/) | Build a ticket: brief, gate, TDD, review, plain-English report |
| [`tr-tdd`](./skills/tr-tdd/) | Red-green-refactor |
| [`tr-code-review`](./skills/tr-code-review/) | Two-axis review of a diff: Standards and Spec |
| [`tr-cleanup-local`](./skills/tr-cleanup-local/) | Close out a finished feature: promote durable notes to `CLAUDE.md`, delete its `.scratch/` files |
| [`tr-codebase-design`](./skills/tr-codebase-design/) | Deep-module vocabulary: interfaces, depth, seams |

## Install

Clone once per machine, then sync:

```bash
git clone https://github.com/trighele/tr-skills.git ~/dev/tr-skills
cd ~/dev/tr-skills && ./sync.sh --no-pull
```

Restart Claude Code and the user-invoked skills appear as `/tr-*` slash commands.

To refresh later — on any machine — `./sync.sh` pulls and installs in one step. On Windows without Git Bash, use `.\sync.ps1`.

See [INSTALL.md](./INSTALL.md) for the details, including how this works inside a dev container (short answer: sync on the host, the container sees it through the `~/.claude` mount).

## Credit

The core skills here are Matt Pocock's, from [mattpocock/skills](https://github.com/mattpocock/skills). The customizations, `tr-ask-tom`, `tr-setup-devcontainer`, `tr-unified-setup`, and `tr-cleanup-local` are mine.
