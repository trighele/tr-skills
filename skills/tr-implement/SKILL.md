---
name: tr-implement
description: "Implement a piece of work based on a spec or set of tickets: brief it in plain English first, build it test-first, then report back in four short sections you can actually act on."
disable-model-invocation: true
---

# Implement

Build the work described by a spec or a ticket. Three phases, in order. Don't skip phase 1, and don't let phase 3 sprawl.

## Phase 1: Brief and gate

**Before touching any code.** Read the ticket (fetch it via `docs/agents/issue-tracker.md` if it's a reference), and read enough of the codebase to know what you're actually about to do.

Then give the user a plain-language brief. **At most ten lines**, no jargon, no layer-by-layer breakdown, no code:

```
**<Ticket ref> — <title>**

In my words: <one sentence restating the ticket WITHOUT reusing its phrasing. This is
the line that catches a misread ticket before it costs a whole session — so paraphrase,
don't echo.>

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

**Announce each slice in exactly one line before you start it:**

```
→ <the behaviour being built, in plain words>
```

Nothing else. No narration of file edits, no explanation of your approach, no progress percentages. These markers are the only running commentary, and phase 3 summarises them.

While building:

- Run typechecking regularly
- Run the single relevant test file regularly
- Run the full test suite **once**, at the end

Use the project's domain glossary vocabulary (`CONTEXT.md`) in names and test descriptions, and respect ADRs covering the area you're touching. If your work contradicts an ADR, surface it rather than silently overriding.

Once the suite is green, run `/tr-code-review` on the work.

**Do not commit.** Leave the working tree for the user to review and commit themselves.

Keep a running note of two things as you go, because phase 3 needs them and reconstructing them afterwards produces vagueness: anything you skipped or deferred, and anything that looked broken or risky in code you touched or read.

## Phase 3: Close-out report

Report back in **exactly these four sections and nothing else**:

```
## What you can do now

One sentence. The new thing a person using the app can do that they couldn't before.
No file names, no technical terms.

## How to test it

At most 3 numbered steps. Each step is either a command to copy-paste, or
"open <page>, click <thing>". After each, say what you should see if it worked.
The fastest honest path to seeing it run — not a QA script.

## What I didn't finish

Bullets, at most 4, one plain line each: what the ticket asked for that isn't there,
and why in half a sentence. Write "Nothing — it's all there." if that's true.

## What I noticed

Bullets, at most 4, one plain line each: problems in the existing code, plus anything
/tr-code-review flagged that wasn't fixed. Say what's wrong and roughly where, in words
someone who didn't write it would follow. Write "Nothing." if clean.
```

### Write it for someone who did not read the code

These rules are the point of the report. The section headings alone are not enough — the last version of this skill said "three sections and nothing else" and still produced a wall of implementation vocabulary.

- **No jargon.** Not "seam", "interface", "abstraction", "refactor", "repository", "middleware", "hook", "wire up", "plumb through". If you have to name something, name it the way the app's users would.
- **Name a file or a function only inside a command to run.** Never in prose.
- **Nothing outside the four sections.** No preamble, no restatement of the diff, no list of files changed, no summary of your approach, no "what I learned", no architecture commentary, no next steps, no offer to commit.
- **The whole report fits on one screen.** If it doesn't, you are explaining rather than reporting. Cut it.

Be honest in every section. If the suite didn't go green, that belongs in **What I didn't finish**, with the failing output, not omitted. If you cut a corner, it goes there too. A clean-looking report that isn't true costs more than a messy one that is — and honesty is the one thing that outranks the length caps above.

Then stop. Don't offer next steps, don't start the next ticket, don't ask if they want you to commit.

## Between tickets

Each ticket is self-contained by construction, so the previous ticket's context is disposable. `/clear` between tickets and start the next one fresh.
