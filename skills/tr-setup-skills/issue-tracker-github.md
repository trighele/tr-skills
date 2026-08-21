# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`
- **Blocking edges**: use GitHub's native issue dependencies where available — `gh api --method POST repos/<owner>/<repo>/issues/<blocked>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). Where dependencies aren't enabled, fall back to a `Blocked by: #<n>, #<n>` line at the top of the blocked issue's body.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone.

## The `ready-for-agent` label

The only label this tree uses. `/tr-to-spec` and `/tr-to-tickets` apply it to mark work as picked-up-able by `/tr-implement`. Create it on first use if it doesn't exist:

```
gh label create ready-for-agent --description "Spec'd and ready to implement" --color 0E8A16
```

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## Pull requests

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as incoming feature requests. Nothing in this skill tree reads the flag today; it's here so the convention is recorded if that changes.)_

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
