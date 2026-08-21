# Claude Code in the container

The goal: open a container on any machine and have the same global skills, settings, and login already there.

## Mount `~/.claude` whole

Not just `skills/`. The whole directory carries settings, auth, and history, so there's no second login and no drift between what the host sees and what the container sees.

```jsonc
"mounts": [
  "source=${localEnv:USERPROFILE}${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached"
]
```

`${localEnv:USERPROFILE}${localEnv:HOME}` resolves correctly on every host because exactly one of the two variables is set: `USERPROFILE` on Windows, `HOME` on macOS and Linux. The unset one expands to an empty string. This is what lets one `devcontainer.json` work on all three machines without editing.

**It's a read-write mount, deliberately.** Session state, history, and any skill the container writes land back on the host. The trade-off is that a container can also modify host Claude state — acceptable here, since these are all the same person's machines.

**Ownership.** The mount arrives owned by the host UID, which usually isn't `vscode` (UID 1000 in most Ubuntu images, which happens to match on macOS and WSL2 often enough that this mostly just works). If Claude can't write its state, fix ownership in `postCreateCommand` rather than changing the container user:

```bash
sudo chown -R vscode:vscode /home/vscode/.claude 2>/dev/null || true
```

The `|| true` matters: on some Docker backends the bind mount ignores `chown`, and that's fine — it means the UIDs already lined up.

## Install Claude Code

In `postCreateCommand`, after Node is available:

```bash
npm install -g @anthropic-ai/claude-code
```

If the project doesn't use Node at all, add the Node feature anyway purely for the CLI:

```jsonc
"features": {
  "ghcr.io/devcontainers/features/node:1": { "version": "lts" }
}
```

On the **work profile**, this install runs through the corporate proxy — see [proxy-and-certs.md](./proxy-and-certs.md). A failing `npm install -g` here is almost always a CA cert problem, not a Claude problem.

## VS Code extension

```jsonc
"customizations": {
  "vscode": {
    "extensions": ["anthropic.claude-code"]
  }
}
```

## Don't add a firewall

Anthropic's reference dev container includes an egress-allowlist firewall script. It's deliberately left out here: the container boundary is the isolation, and on the work machine an egress firewall layered on top of a corporate proxy is a genuinely painful thing to debug. If it's ever wanted, it's an addition to make consciously, not a default.

## Verify

Inside the container:

```bash
claude --version
ls ~/.claude/skills          # should list the host's skills
```

If `~/.claude/skills` is empty, the mount didn't resolve — check that exactly one of `USERPROFILE` / `HOME` was set on the host when VS Code launched, and that the path it points at actually contains `.claude`.
