---
name: tr-setup-devcontainer
description: "Set up a VS Code dev container for this project, matched to the machine you're on: Ubuntu base, ~/.claude mounted so global skills come with you, and git history that actually matches the host."
disable-model-invocation: true
---

# Setup Dev Container

Generate a `.devcontainer/` for this project that behaves identically on a work Windows laptop, a personal Windows desktop, and a MacBook.

The container is always **Ubuntu**. Three things always come along:

1. The host's `~/.claude` directory, bind-mounted whole, so global skills, settings, and auth work inside the container without a second login.
2. Claude Code, installed in the container.
3. **Working git**: the same history, branches, and status you see on the host. This is the part that usually breaks, so it has its own reference file and its own verification step.

What varies between machines is mount paths, CPU architecture, and — on the work machine — a corporate proxy and custom CA certificates. That's what the host profile resolves.

## Process

### 1. Identify the host, then confirm

If the user already said which machine they're on ("I'm on my work computer"), take it and skip to confirming the details. Otherwise probe, don't ask:

- OS and architecture — `uname -a`, or on Windows the `OS` / `PROCESSOR_ARCHITECTURE` env vars. Apple Silicon means `linux/arm64` images.
- Home directory — `$USERPROFILE` on Windows, `$HOME` on macOS. This is the `~/.claude` mount source.
- Docker — `docker context ls`, `docker info`. Note WSL2 vs a native Linux VM.
- Proxy — `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` in the environment, and `npm config get proxy` / `git config --get http.proxy`. Any of these set is the strongest signal of the work profile.
- Custom CA certs — `npm config get cafile`, `git config --get http.sslCAInfo`, `NODE_EXTRA_CA_CERTS`. A non-default value means a corporate root CA is in play.
- Git identity — `git config --get user.name` / `user.email`.

Then propose the profile via `AskUserQuestion` (one question, recommended answer first): **work**, **windows-desktop**, **macbook**, or **other**. Show what you detected in the option descriptions so the confirmation is one word.

See [profiles.md](./profiles.md) for what each profile implies.

### 2. Identify the project stack

Detect, don't ask, where the repo says what it is: `package.json`, `pnpm-lock.yaml` / `yarn.lock`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `*.csproj`, `Gemfile`, `.tool-versions`, `.nvmrc`. Note versions where they're pinned — an `.nvmrc` or an `engines` field decides the Node version, don't guess one.

Ask only when the project is empty, or genuinely polyglot with no obvious primary language.

### 3. Check what's already there

If `.devcontainer/` exists, read it. **Merge, don't clobber.** Show the user a diff of what you'd change and why, and leave alone anything they clearly added deliberately (extra extensions, project-specific `postCreate` steps, forwarded ports).

Two things to check for specifically, because both fail silently:

- **`extensions` at the top level of `devcontainer.json`.** That location is deprecated and simply ignored — the extensions never install and nothing warns. Move it to `customizations.vscode.extensions`. Hand-written and older generated configs get this wrong constantly.
- **A folder-per-container layout.** A polyglot repo may already have `.devcontainer/<name>/` folders rather than a single config. That's the right shape; don't collapse it. See the multi-container section of [machine-local-config.md](./machine-local-config.md).

Also inspect the base image before writing anything against it — `docker image inspect --format '{{json .Config.Env}}'` and `docker run --rm <image> sh -c 'id <user>; ls /usr/local/share/ca-certificates'`. A corporate base image often already carries the root CA, the registry config, and an entrypoint that creates the container user at a *specific* uid. Half the work in the reference files may already be done for you, and guessing instead of checking is how you end up with a `remoteUser` that doesn't exist.

### 4. Draft

Assemble `.devcontainer/devcontainer.json` and `.devcontainer/Dockerfile` from the reference files:

- [git-parity.md](./git-parity.md) — **read this every time.** The mount rules and git config that make container git match host git. Non-negotiable, every profile.
- [claude-in-container.md](./claude-in-container.md) — the `~/.claude` mount per OS, and installing Claude Code.
- [profiles.md](./profiles.md) — per-machine paths, architecture, and Docker quirks.
- [machine-local-config.md](./machine-local-config.md) — when `${localEnv:}` isn't enough: the gitignored `.env` + `initializeCommand` bootstrap pattern that keeps host paths, base images, uid/gid and secrets out of git entirely. Read this for any **docker-compose-based** devcontainer, any repo with **more than one** container, or whenever the user asks for machine-specific setup that isn't committed.
- [proxy-and-certs.md](./proxy-and-certs.md) — **work profile only.** Corporate proxy env vars and root CA installation. Skip entirely on the other profiles; don't add empty proxy variables "just in case", because an empty `HTTP_PROXY` breaks tools that check for the variable's presence rather than its value.

Show the draft of both files before writing anything. Call out explicitly which lines came from the host profile, so it's obvious what would differ on another machine.

### 5. Write and verify

Write the files, then have the user rebuild the container ("Dev Containers: Rebuild Container"). Once it's up, run the checklist inside and report **pass/fail per line**, not a summary:

**Git parity** — run each inside the container and against the host, and compare:

```bash
git log --oneline -5
git status --short --branch
git branch -a
git remote -v
git config --get user.email
```

Identical output on both sides is the pass condition. Any divergence is a real failure — go back to [git-parity.md](./git-parity.md) and work the cause list; don't paper over it.

**Claude** — inside the container:

```bash
claude --version
ls ~/.claude/skills
```

The skills directory should show the host's skills.

**Toolchain** — don't stop at `--version`. Run the command that actually **installs dependencies**, because that is where corporate registries bite: `uv sync` / `npm install` / `dotnet restore` / `go mod download`. A container where `python --version` works and `uv sync` 401s is not a working container, and the difference only shows up if you run it.

On the work profile also confirm the network: `npm ping` and `git ls-remote origin` succeeding is the real test, not `curl` against a public host.

If a dependency install fails on credentials, find how CI supplies them (grep the workflow files for the index name) and wire the same secret through the local `.env` — see [machine-local-config.md](./machine-local-config.md). A step the user performs by hand after every rebuild is a bug in the container, not a fact of life; ask what they currently type and automate exactly that.

You can drive most of this yourself with `docker compose up -d` plus `docker compose exec`, without waiting for a VS Code rebuild. Two caveats: pass `-u <remoteUser>` because `exec` defaults to root, and on a Git Bash host prefix with `MSYS_NO_PATHCONV=1` or `-w /abs/path` gets mangled into a Windows path and fails with `Cwd must be an absolute path`.

**What you cannot verify this way:** git credential forwarding. The Dev Containers extension injects `GIT_ASKPASS` when *it* creates the container, so `git ls-remote origin` under a raw `docker compose exec` fails with "could not read Username" even when the setup is correct. Say so explicitly rather than reporting it as a failure or quietly skipping it — hand that one line to the user to confirm after their rebuild.

Report what passed and what didn't, per line. If something failed, fix it and re-verify rather than handing back a container that half works. Tear down any containers you started for testing, so VS Code creates its own cleanly.
