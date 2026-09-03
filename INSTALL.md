# Installing and refreshing tr-skills

The short version: **clone the repo once per machine, then `./sync.sh` whenever you want the latest.**

```bash
cd ~/dev/tr-skills && ./sync.sh
```

That pulls and installs in one step.

## The shape

```
~/dev/tr-skills/              the clone — this is the only place .git lives
        │  ./sync.sh   (pull + copy)
        ▼
~/.claude/skills/tr-*/        plain copies
```

The skills are **copied**, not symlinked, and the clone lives outside `~/.claude`. That is deliberate:

- **Nothing git-shaped ends up under `~/.claude/skills`.** No nested repo, no `.git` for Claude Code or a parent repo to trip over. (Claude Code does keep its own clones under `~/.claude/plugins/marketplaces/` — those are its business, not ours.)
- **Copies survive a bind mount.** A symlink pointing at `~/dev/tr-skills` is a dangling link inside a dev container, because the clone isn't mounted there. A copy just works.

The cost is that a `git pull` alone doesn't install anything — you run `sync.sh`, which does both.

## First time on a machine

```bash
git clone https://github.com/trighele/tr-skills.git ~/dev/tr-skills
cd ~/dev/tr-skills
./sync.sh --no-pull
```

Then restart Claude Code. The user-invoked skills show up as `/tr-*` slash commands.

`~/dev/tr-skills` is a suggestion, not a requirement — the script finds the repo from its own location, so clone it wherever you like.

**On Windows**, either run `./sync.sh` from Git Bash, or use the PowerShell twin:

```powershell
cd ~\dev\tr-skills
.\sync.ps1
```

Both scripts do exactly the same thing. If PowerShell blocks the script, run it as
`powershell -ExecutionPolicy Bypass -File .\sync.ps1`.

## Refreshing

```bash
cd ~/dev/tr-skills && ./sync.sh
```

Then restart Claude Code — it reads skills at startup, so a running session won't see the change.

Flags:

| | |
| --- | --- |
| `./sync.sh` | pull, then install |
| `./sync.sh --no-pull` | install what's already checked out (use after local edits) |
| `CLAUDE_SKILLS_DIR=/somewhere ./sync.sh` | install somewhere else, for testing |

### What the script will and won't touch

- It installs every `skills/tr-*` directory, replacing whatever was there.
- It **prunes** any `tr-*` in the destination that no longer exists in the repo, and prints each removal. Without this, a renamed skill leaves its old copy behind still answering to the old slash command.
- It touches **nothing** that isn't named `tr-*`. Your `msk-*` skills, hand-written skills and plugins are left exactly as they are.
- It refuses to run if `~/.claude` doesn't exist rather than creating it, because an empty `~/.claude` almost always means the path is wrong — or, in a container, that the bind mount didn't resolve. Creating it silently turns that into "my skills vanished" three steps later.

## In a dev container

**Run `sync.sh` on the host. There is no container-side step.**

`/tr-setup-devcontainer` mounts the whole of `~/.claude` into the container:

```jsonc
"mounts": [
  "source=${localEnv:USERPROFILE}${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
]
```

So the skills you install on the host are the skills the container sees — the same files, live. Sync on the host, then reload the window (or `/exit` and relaunch Claude Code inside the container) to pick up the change.

The clone at `~/dev/tr-skills` is **not** mounted — the container's workspace is your project, not this repo — which is why the sync itself has to run host-side.

### Optional: syncing from inside the container

If you'd rather not switch to a host terminal, mount the clone too:

```jsonc
"mounts": [
  "source=${localEnv:USERPROFILE}${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached",
  "source=${localEnv:USERPROFILE}${localEnv:HOME}/dev/tr-skills,target=/home/vscode/tr-skills,type=bind,consistency=cached"
]
```

Then `cd ~/tr-skills && ./sync.sh` works inside the container, and lands in the same host `~/.claude` via the first mount.

`${localEnv:USERPROFILE}${localEnv:HOME}` resolves on every host because exactly one of the two is set — `USERPROFILE` on Windows, `HOME` on macOS and Linux — and the unset one expands to empty. It looks like a typo; it isn't. See `skills/tr-setup-devcontainer/claude-in-container.md`.

## Troubleshooting

**A `/tr-*` command doesn't exist after syncing.** Claude Code loads skills at startup. Restart it.

**Changes don't show up in the container.** Check the mount resolved: `ls ~/.claude/skills` inside the container should list the same `tr-*` directories as the host. If it's empty, the `${localEnv:...}` path didn't resolve on the host when VS Code launched.

**`git pull` fails with divergent branches.** The script uses `--ff-only` on purpose — it will not silently merge over local edits. Either commit and push your changes, or stash them, then re-run.

**You edited a skill locally and want to test it.** `./sync.sh --no-pull` installs the working tree without pulling.

## Alternative: ship it as a Claude Code plugin

Not set up, but worth knowing about. A plugin manifest (`.claude-plugin/plugin.json` + `marketplace.json`) in this repo would make it:

```
/plugin marketplace add trighele/tr-skills
/plugin install tr-skills
/plugin update tr-skills
```

No clone, no script, nothing under `~/.claude` to manage. Upstream ships this way. The catch is namespacing — skills become `/tr-skills:tr-implement` rather than `/tr-implement` — and the plugin copy is read-only, so local tinkering means going back to the clone anyway. Left as an open question in [CLAUDE.md](./CLAUDE.md).
