---
name: tr-grilling
description: Grill the user relentlessly about a plan, decision, or idea, one question at a time. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## The frontier

The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. A question whose answer depends on another unsettled question is not on the frontier; it waits.

Maintain the frontier internally at all times. It is what keeps the interview aimed: without it, one-at-a-time questioning degrades into an aimless drip.

## Ask one question at a time

**Ask exactly one frontier question per turn.** Never batch. The user is answering with their full attention on one decision, and that is the point.

Use the `AskUserQuestion` tool for every question:

- **One question per call.** Do not pack multiple frontier questions into a single call, even though the tool permits it.
- **Recommended answer first**, with `(Recommended)` appended to its label. You always have an opinion; lead with it so it can be accepted in one word.
- **2–4 concrete options.** Real, mutually exclusive choices, each with a one-line description of what it means or costs. The harness adds an "Other" escape hatch for free text; you don't need to.
- **Order by consequence.** When several questions sit on the frontier at once, ask the one whose answer reshapes the most of the remaining tree first.

**Fallback to text.** When a question genuinely can't be reduced to options — an open-ended "describe the failure mode you're worried about", something where enumerating choices would bias the answer — ask it as a single text question in this format and wait:

```
❓ **<question title>**: <question body, may be multiple paragraphs>

➡️ <your recommended answer>
```

Even in fallback, it's one question, then you stop and wait.

## After every answer

Recompute the frontier **after each individual answer**, not after a batch. An answer can:

- settle a decision and push the frontier outward, unblocking questions that depended on it
- **prune** questions that were queued behind it, because the branch they lived on is now moot
- reshape a queued question into a different question

Then ask the next single question from the recomputed frontier.

## Facts are your job, decisions are theirs

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, existing code), go find it; don't ask the user for anything you could look up yourself.

Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait. Keep asking the rest of the frontier meanwhile.

The _decisions_ are the user's. Put each to them and wait.

## Done

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed.

Do not act on the outcome until the user confirms you have reached a shared understanding. If a wrapper skill invoked this one, hand back to it rather than starting work.
