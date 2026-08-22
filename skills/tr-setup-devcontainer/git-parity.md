# Git parity: making container git match host git

The most common complaint: git inside the dev container doesn't show the same history, branches, or status as git on the host. Every cause below is a real one, and more than one can be true at once. Apply all of the fixes; they don't conflict.

## Cause 1: the workspace isn't the host's repo at all

**By far the most likely cause of "different history".**

VS Code offers two ways to open a project in a container:

- **"Reopen in Container"** — bind-mounts the folder you already have. Same `.git`, same everything. ✅
- **"Clone Repository in Container Volume"** — makes a **brand-new clone** into a Docker volume. Different `.git`, different reflog, none of your local branches, none of your uncommitted work. ❌

If the container was ever created the second way, its git history *legitimately* differs from the host's, because it is a different clone. No config fixes that; reopen the local folder in a container instead.

Make the bind mount explicit so it can't be created the wrong way by accident:

```jsonc
"workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
"workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached"
```

## Cause 2: a volume mount is shadowing `.git`

A performance-oriented mount can hide part of the tree. Anything mounted at or above the repo root replaces what's underneath it.

Check the `mounts` array: no entry may target the workspace folder or `.git`. Mounting `node_modules`, `.venv`, or `target/` into a named volume is fine and encouraged — mounting the workspace root is not.

## Cause 3: dubious ownership

The container user's UID rarely matches the host file owner, so git refuses to operate on the repo and prints "detected dubious ownership in repository". Depending on the command, this looks like empty output rather than a clear error, which reads as "history is missing".

Fix in the Dockerfile so it applies to every rebuild:

```dockerfile
RUN git config --system --add safe.directory '*'
```

Scoping it to `*` is deliberate here: the workspace path varies per project, and this is a single-user development container.

## Cause 4: every file shows as modified (Windows hosts)

Two independent causes, both producing a `git status` full of changes that aren't real. Both need fixing.

**File mode.** Windows has no Unix permission bits, so a bind-mounted tree reports different modes to Linux git than the index recorded:

```dockerfile
RUN git config --system core.filemode false
```

**Line endings.** If the host has `core.autocrlf=true`, the working tree holds CRLF while container git expects LF, and the entire tree reads as rewritten:

```dockerfile
RUN git config --system core.autocrlf input
```

Also commit a `.gitattributes` at the repo root so the normalization is a property of the repo rather than of each machine's config:

```gitattributes
* text=auto eol=lf
*.png binary
*.jpg binary
*.ico binary
*.pdf binary
*.woff2 binary
*.sh text eol=lf
*.bat text eol=crlf
*.cmd text eol=crlf
```

If the repo has *already* been committed with mixed endings, adding `.gitattributes` alone won't settle it — the index needs renormalizing once, on the host, with `git add --renormalize .` followed by a commit. Flag this to the user rather than doing it silently: it touches every file and belongs in its own commit.

## Cause 5: identity and credentials didn't come across

History shows up, but commits are attributed to `vscode@container` and pushes fail.

**Identity** — mount the host `.gitconfig` read-only:

```jsonc
"mounts": [
  "source=${localEnv:USERPROFILE}${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig-host,type=bind,readonly"
]
```

Then in `postCreateCommand`, pull just the identity across rather than inheriting the host's whole config (which may name Windows-only helpers and credential managers that don't exist in the container):

```bash
git config --global user.name  "$(git config -f ~/.gitconfig-host --get user.name)"
git config --global user.email "$(git config -f ~/.gitconfig-host --get user.email)"
```

`${localEnv:USERPROFILE}${localEnv:HOME}` is a deliberate trick: exactly one of the two is set on any given host, so the concatenation resolves to whichever exists. Use it wherever a home-directory path is needed and the profile should not be hard-coded.

**Better, when you already have a bootstrap script** (see [machine-local-config.md](./machine-local-config.md)): skip the mount and pass the identity as environment variables the bootstrap read on the host.

```bash
# post-create.sh — values come from the generated, gitignored .env
if [ -n "${GIT_USER_NAME:-}" ];  then git config --global user.name  "$GIT_USER_NAME";  fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then git config --global user.email "$GIT_USER_EMAIL"; fi
```

This drops a file bind mount whose failure mode is nasty: if the source path is wrong, Docker silently creates an empty **directory** at `~/.gitconfig-host`, and `git config -f` on a directory fails in a way that reads as "the host had no identity". Nothing is lost by switching — push credentials come from the extension's forwarding either way.

**SSH keys** — VS Code forwards the host SSH agent automatically when an agent is running. Confirm with `ssh-add -l` inside the container. If the host agent isn't running, that's a host-side fix (`Start-Service ssh-agent` on Windows, `ssh-add --apple-use-keychain` on macOS), not a container one.

**GitHub HTTPS** — install the `github-cli` feature and run `gh auth login` once inside the container, or let the mounted `~/.claude` and a mounted `~/.config/gh` carry the token.

## Cause 6: git is too old

Ubuntu's stock git lags well behind, and older versions lack `safe.directory` entirely — which turns cause 3 into a hard wall. Use the feature with the PPA:

```jsonc
"features": {
  "ghcr.io/devcontainers/features/git:1": { "ppa": true },
  "ghcr.io/devcontainers/features/github-cli:1": {}
}
```

## Verification

Run all of these in the container and on the host, and diff the output. Identical is the only pass:

```bash
git log --oneline -5
git status --short --branch
git branch -a
git remote -v
git config --get user.email
```

`git status` is the sharpest of these — if the container shows hundreds of modified files and the host shows none, it's cause 4.
