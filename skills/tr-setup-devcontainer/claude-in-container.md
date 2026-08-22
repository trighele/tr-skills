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

On a **docker-compose-based** devcontainer, put this mount in the compose file's `volumes:` instead — `${localEnv:}` does not work in compose, so drive the path from a generated `.env` and guard it with `${HOST_HOME:?...}`. See [machine-local-config.md](./machine-local-config.md).

## Install Claude Code

Prefer the **Dockerfile** over `postCreateCommand` when Node is already in the image: it is cached across rebuilds, and installing as root lands the binary on `PATH` for the non-root user (check `npm config get prefix` — a prefix of `/usr` or `/usr/local` is what makes this work).

```bash
npm install -g @anthropic-ai/claude-code
```

If the project doesn't use Node at all, add the Node feature anyway purely for the CLI:

```jsonc
"features": {
  "ghcr.io/devcontainers/features/node:1": { "version": "lts" }
}
```

**Never let this fail the build.** Terminate the install with `|| echo WARN...` so a registry problem doesn't cost the whole image, and report the CLI's presence in `postCreateCommand` instead.

### On a corporate registry, the plain install usually fails

Two independent blocks, and the second one defeats the obvious workaround:

1. **Artifactory's remote-repo retrieval delay.** Mirrors are commonly configured to withhold artifacts younger than ~2 days. Claude Code ships very frequently, so `@latest` is often inside that window and 403s:
   `npm error 403 Forbidden - GET .../@anthropic-ai/claude-code/-/claude-code-X.Y.Z.tgz`,
   usually preceded by `npm notice Artifact was created 1 days ago, which is less than the configured delay of 2 days`.
2. **The public registry is blocked at the network layer.** `--registry=https://registry.npmjs.org` returns a Zscaler block page, which npm reports as `invalid json response body ... Unexpected token '<'` — a confusing error that has nothing to do with npm.

Package **metadata is not delayed**, only tarballs. So query the metadata and install the newest release old enough to have been cached:

```bash
npm install -g @anthropic-ai/claude-code && exit 0   # try latest first

candidates=$(node -e '
  const { execSync } = require("node:child_process");
  const times = JSON.parse(execSync("npm view @anthropic-ai/claude-code time --json", {encoding:"utf8"}));
  const cutoff = Date.now() - 3 * 864e5;
  console.log(Object.entries(times)
    .filter(([v]) => /^\d+\.\d+\.\d+$/.test(v))
    .filter(([, t]) => new Date(t).getTime() < cutoff)
    .sort((a, b) => new Date(b[1]) - new Date(a[1]))
    .slice(0, 5).map(([v]) => v).join(" "));')

for v in $candidates; do npm install -g "@anthropic-ai/claude-code@$v" && exit 0; done
```

Keep this in a shared `.devcontainer/install-claude-code.sh` rather than inline, especially with more than one image — see the multi-container notes in [machine-local-config.md](./machine-local-config.md) for getting one script into two build contexts.

A failing `npm install -g` is *not* always a CA cert problem — check for the 403/delay notice before reaching for [proxy-and-certs.md](./proxy-and-certs.md).

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
