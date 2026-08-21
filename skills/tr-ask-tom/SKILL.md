---
name: tr-ask-tom
description: Ask which TR skill or flow fits your situation. A router over the skills in this tree.
disable-model-invocation: true
---

# Ask Tom

You don't remember every skill, so ask. This tree is small on purpose: thirteen skills, one main flow, everything else feeding it.

If the user described a situation, name the one skill to run next and say why in a sentence. If they just typed the command with no context, give them the map below.

## Setup, once

- **`/tr-setup-skills`** — once per repo, before anything else. Configures the issue tracker (GitHub or local markdown) and the domain doc layout that every other skill reads from.
- **`/tr-setup-devcontainer`** — once per project per machine. Generates a `.devcontainer/` matched to the machine you're on, with `~/.claude` mounted and git history working properly inside the container.

## The main flow: idea → shipped

The route most work travels.

1. **`/tr-grill-with-docs`** — sharpen the idea by interview, one question at a time, updating `CONTEXT.md` and ADRs as terms and decisions get settled. It stops when the questions run out; it never writes a spec.
2. **`/tr-to-spec`** — collapse the conversation into a spec and publish it to the tracker. No interview, just synthesis of what you already agreed.
3. **`/tr-to-tickets`** — split the spec into tracer-bullet tickets, each a narrow but complete vertical slice, each declaring what blocks it.
4. **`/tr-implement <ticket>`** — build one ticket. Briefs you in plain English and waits for a go-ahead, builds test-first via `/tr-tdd`, reviews via `/tr-code-review`, then reports back in three sections: how to verify it, what wasn't done, what looked broken. It does not commit.
5. **`/tr-cleanup-local`** — once every ticket is built and you've reviewed the work, close the feature out: promote anything durable into `CLAUDE.md`, then delete the feature's `.scratch/` files so they don't follow you into the next feature. Local-markdown tracker only; on GitHub the spec and tickets already live somewhere durable.

**The short path:** if the change is small enough to finish in the session you're already in, go from step 1 straight to `/tr-implement`. Steps 2 and 3 exist to survive a `/clear`; skip them when nothing needs to survive one.

### Context hygiene

Keep steps 1–3 in **one unbroken context window**. The grilling, the spec, and the tickets need to build on the same thinking, so don't clear or compact between them. If the window gets long before step 3, `/compact` at a phase boundary (the end of the grilling close-out is the cleanest one) rather than pushing on with a degraded window.

Then **`/clear` between every ticket**. Each ticket is self-contained by construction, so the last one's context is disposable — and a fresh window implements better than a full one.

## Underneath the flow

Reach for these directly when the process isn't the problem.

- **`/tr-tdd`** — red-green-refactor. `/tr-implement` drives it; run it alone when you want to build one concrete behaviour test-first without a spec around it.
- **`/tr-code-review`** — two-axis review of a diff since a fixed point: **Standards** (does it follow the repo's conventions, plus a Fowler smell baseline) and **Spec** (does it do what the issue asked). `/tr-implement` runs it; run it alone to review a branch or PR.
- **`/tr-grilling`** — the interview primitive: design tree, frontier, one question per turn in the question box. `/tr-grill-with-docs` wraps it. Run it bare when you want the interview with no repo paper trail — sharpening a plan, a decision, or a piece of writing.

## Vocabulary layers

Two references that run *beneath* the others, each the source of truth for its vocabulary. Reach for them when the **words**, not the process, are what's stuck.

- **`/tr-domain-modeling`** — the project's *domain* language: challenge a fuzzy term, split an overloaded word doing three jobs, record a hard-to-reverse decision as an ADR. It's what `/tr-grill-with-docs` runs to keep `CONTEXT.md` honest.
- **`/tr-codebase-design`** — the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: a lot of behaviour behind a small interface at a clean seam. `/tr-tdd` speaks it.

## Picking between them

| Your situation | Run |
| --- | --- |
| New repo, nothing configured | `/tr-setup-skills` |
| New machine or new project, no container yet | `/tr-setup-devcontainer` |
| Rough idea, want it sharpened | `/tr-grill-with-docs` |
| Idea is sharp, want it written down | `/tr-to-spec` |
| Spec exists, too big for one session | `/tr-to-tickets` |
| Ticket ready to build | `/tr-implement` |
| Feature built and reviewed, `.scratch/` piling up | `/tr-cleanup-local` |
| One behaviour to build, no ceremony | `/tr-tdd` |
| Branch or PR to review | `/tr-code-review` |
| Stress-test thinking outside a repo | `/tr-grilling` |
| A term means two things and it's causing bugs | `/tr-domain-modeling` |
| A module's interface feels wrong | `/tr-codebase-design` |
