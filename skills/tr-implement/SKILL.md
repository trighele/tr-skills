---
name: tr-implement
description: "Implement a piece of work based on a spec or set of tickets: brief it in plain English first, build it test-first, then report back in three lines you can actually act on."
disable-model-invocation: true
---

# Implement

Build the work described by a spec or a ticket. Three phases, in order. Don't skip phase 1, and don't let phase 3 sprawl.

## Phase 1: Brief and gate

**Before touching any code.** Read the ticket (fetch it via `docs/agents/issue-tracker.md` if it's a reference), and read enough of the codebase to know what you're actually about to do.

Then give the user a plain-language brief. **At most ten lines**, no jargon, no layer-by-layer breakdown, no code:

```
**<Ticket ref> — <title>**

What this does: <1–2 sentences, in terms of behaviour the user can observe. Not "adds a
repository method"; rather "lets a signed-in customer see their balance on the accounts page".>

Touches: <3–5 bullets max, named as areas or files, not a file tree>

How you'll see it work: <the one command to run or thing to click that demonstrates it>
```

If reading the ticket surfaced a genuine problem with it — an ambiguity, a contradiction with an ADR, a dependency that isn't done — say so in one or two lines under the brief. Don't pad it out.

Then **stop** and ask for a go-ahead with `AskUserQuestion`:

- **Start** (Recommended)
- **Adjust scope first** — something in the brief is wrong or too broad
- **Skip this ticket**

Do not begin implementation until the answer comes back. If the user adjusts, revise the brief and ask again.

## Phase 2: Build

Drive `/tr-tdd` where possible, at pre-agreed seams. Prefer existing seams; use the highest seam available.

While building:

- Run typechecking regularly
- Run the single relevant test file regularly
- Run the full test suite **once**, at the end

Use the project's domain glossary vocabulary (`CONTEXT.md`) in names and test descriptions, and respect ADRs covering the area you're touching. If your work contradicts an ADR, surface it rather than silently overriding.

Once the suite is green, run `/tr-code-review` on the work.

**Do not commit.** Leave the working tree for the user to review and commit themselves.

Keep a running note of two things as you go, because phase 3 needs them and reconstructing them afterwards produces vagueness: anything you skipped or deferred, and anything that looked broken or risky in code you touched or read.

## Phase 3: Close-out report

Report back in **exactly these three sections and nothing else**. No preamble, no "what I learned", no architecture commentary, no restatement of the diff, no list of files changed (the diff already says that).

```
## Verify it yourself

The exact commands to run, copy-pasteable, and what you should see when they pass.
If there's a UI step, say which page and what to click. Two or three steps at most —
the fastest honest path to seeing it work, not an exhaustive QA script.

## Not done

Anything the ticket asked for that was skipped, deferred, or only partially built, and
why in half a sentence each. Write "Nothing — the ticket landed complete." if that's true.

## Bugs & risks found

Problems noticed in existing code while working on this, plus anything `/tr-code-review`
flagged that wasn't fixed. One line each: what it is and where. Write "None." if clean.
```

Be honest in every section. If the suite didn't go green, that belongs in **Not done** with the failing output, not omitted. If you cut a corner, it goes in **Not done**. A clean-looking report that isn't true costs more than a messy one that is.

Then stop. Don't offer next steps, don't start the next ticket, don't ask if they want you to commit.

## Between tickets

Each ticket is self-contained by construction, so the previous ticket's context is disposable. `/clear` between tickets and start the next one fresh.
