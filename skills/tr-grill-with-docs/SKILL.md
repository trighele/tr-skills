---
name: tr-grill-with-docs
description: A relentless round-by-round interview to sharpen a plan or design, building the project's domain docs (CONTEXT.md and ADRs) as it goes. Stops at the end of the interview; it never writes a spec.
disable-model-invocation: true
---

# Grill with Docs

The first step of the main flow. Sharpen a rough idea into a shared understanding, and leave a paper trail in the repo while doing it.

## How to run it

Run a `/tr-grilling` session as the interview: design tree, frontier, **the whole frontier asked as one numbered round**, then the next round spun off the answers. All of that skill's rules apply here unchanged.

Alongside it, run `/tr-domain-modeling` continuously. As terms get settled and hard-to-reverse decisions get made during the interview, record them **inline, as they happen**:

- A term that needed pinning down, or an overloaded word doing two jobs → update `CONTEXT.md`.
- A decision that will be expensive to reverse → write an ADR under `docs/adr/`.

Don't defer this to the end. The docs are a by-product of the conversation, written while the reasoning is still in view.

## Hard stop at the end

When the frontier empties, **this skill is over**. Its only outputs are `CONTEXT.md` and ADR updates, written during the interview.

Explicitly, at the end of the interview you do **not**:

- write a spec, a plan document, a design doc, or a summary file
- create tickets or issues
- write, edit, or refactor any code
- invoke `/tr-to-spec`, `/tr-to-tickets`, `/tr-implement`, or any other skill
- begin "just sketching" an implementation

Even if the design now feels obvious and the next step seems mechanical, stop. The boundary between "we understand this" and "we have committed it to a spec" is the user's to cross, and they cross it by typing the next command.

## Close-out message

End with exactly this shape, and nothing after it:

```
## What we settled
<a short recap: the decisions made, in the order they were made. Bullets, not prose.>

## Docs updated
<the files touched: CONTEXT.md terms added or sharpened, ADRs written. "None" if nothing rose to that level.>

## Still open
<anything deliberately parked as out of scope or deferred. "Nothing" if the frontier truly emptied.>

Grilling complete. Run `/tr-to-spec` when you're ready to turn this into a spec.
```

Keep the whole close-out short enough to read without scrolling. Then wait.

## Context hygiene

Everything from here to `/tr-to-tickets` should stay in **one unbroken context window**, so the grilling, the spec, and the tickets all build on the same thinking. Don't clear or compact after this skill finishes. If the window is getting long, this close-out is a clean phase boundary to `/compact` at, but continuing is cheaper and loses nothing.
