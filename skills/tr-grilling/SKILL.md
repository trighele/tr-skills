---
name: tr-grilling
description: Grill the user relentlessly about a plan, decision, or idea, a round of questions at a time. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## The frontier

The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. A question whose answer depends on another question — including one still open in the current round — is not on the frontier; it belongs to a later round.

Maintain the frontier internally at all times. It is what keeps the interview aimed rather than exhaustive.

## Work the tree in rounds

**Ask the whole frontier in one round.** Number each question and attach your recommended answer. Then stop and wait for the answers before the next round.

```
❓ **Q1** — **<question title>**: <question body, may be several paragraphs, and may lay out options>

➡️ <your recommended answer>
```

- **Answerable by number** is the goal. The user should be able to reply "1 yes, 2 the second option, 3 no because…" instead of quoting your questions back. Word each question so that works.
- **Always recommend.** You have an opinion; state it so a whole round can be accepted in a few words.
- **Order by consequence** within the round: the question that reshapes the most of the remaining tree goes first.
- **Watch the wording trap.** Phrase the question so that agreeing with your recommendation isn't answering "no" to the question as asked.

Thirteen questions typically land in about three rounds rather than thirteen exchanges. That is the point.

## After every round

Recompute the frontier. An answer can:

- settle a decision and push the frontier outward, unblocking questions that depended on it
- **prune** questions queued behind it, because the branch they lived on is now moot
- reshape a queued question into a different question

Then ask the next round from the recomputed frontier.

## Facts are your job, decisions are theirs

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, existing code), go find it — dispatch a sub-agent if it's slow. Don't ask the user for anything you could look up yourself.

Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait. Ask the rest of the round now.

The _decisions_ are the user's. Put them to the user and wait.

## Done

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed.

Do not act on the outcome until the user confirms you have reached a shared understanding. If a wrapper skill invoked this one, hand back to it rather than starting work.
