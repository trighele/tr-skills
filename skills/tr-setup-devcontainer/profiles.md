# Host profiles

Three machines, one `devcontainer.json`. Most differences are absorbed by `${localEnv:USERPROFILE}${localEnv:HOME}` (see [claude-in-container.md](./claude-in-container.md)); what's left is listed per profile.

The base is always **Ubuntu**: `mcr.microsoft.com/devcontainers/base:ubuntu` unless the stack has a better-matched official image (`typescript-node`, `python`, `go`), all of which are Ubuntu underneath anyway.

## Detection signals

| Signal | Work | Windows desktop | MacBook |
| --- | --- | --- | --- |
| `HTTP_PROXY` / `HTTPS_PROXY` set | ✅ usually | ❌ | ❌ |
| `npm config get cafile` non-default | ✅ usually | ❌ | ❌ |
| `$USERPROFILE` set | ✅ | ✅ | ❌ |
| `$HOME` set (and no `USERPROFILE`) | ❌ | ❌ | ✅ |
| `uname -m` | `x86_64` | `x86_64` | `arm64` |

Proxy or CA signals are the strongest discriminator — a Windows host with either is the work machine, not the desktop. Confirm the guess with the user rather than acting on it silently.

## work (Windows, corporate)

- **The distinguishing feature is the network.** Corporate proxy and a custom root CA. Everything in [proxy-and-certs.md](./proxy-and-certs.md) applies, and only here.
- Docker Desktop on WSL2. Bind mounts from a Windows drive (`C:\`, `D:\`) into WSL2 are slow; keeping `node_modules`, `.venv`, and build output in named volumes matters more here than anywhere else.
- Platform `linux/amd64`.
- Git: `core.filemode false` and `core.autocrlf input` required (see [git-parity.md](./git-parity.md)).
- Corporate device management sometimes blocks pulling from `ghcr.io`. If a devcontainer feature fails to pull, that's the cause; fall back to installing the tool directly in the Dockerfile.

## windows-desktop (personal)

- Identical to **work** minus the entire proxy and CA section. Don't add empty `HTTP_PROXY` variables here — a defined-but-empty proxy variable breaks tools that test for presence rather than value.
- Docker Desktop on WSL2, `linux/amd64`, same bind-mount performance caveat and the same `filemode` / `autocrlf` requirements.

## macbook (Apple Silicon)

- Platform `linux/arm64`. Most official images are multi-arch and need nothing; pin `"runArgs": ["--platform=linux/amd64"]` **only** if a dependency has no arm64 build, and expect it to be slow when you do.
- Bind mounts are faster than on WSL2 but still not native — `consistency=cached` is still worth setting.
- `$HOME` is set and `$USERPROFILE` isn't, so the mount trick resolves on its own.
- `core.filemode` and `core.autocrlf` don't strictly need overriding here, but setting them costs nothing and keeps one config working on all three machines. Leave them in.

## other

Probe, report what was found, and ask which of the three profiles it most resembles. Don't invent a fourth profile without the user asking for one.

## Named volumes for build output

Worth doing on every profile, and load-bearing on the two Windows ones:

```jsonc
"mounts": [
  "source=${localWorkspaceFolderBasename}-node-modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
]
```

Adjust the target per stack (`.venv`, `target/`, `vendor/`). Never mount a volume at the workspace root — that shadows `.git` and breaks history (see [git-parity.md](./git-parity.md), cause 2). Also `chown` the volume to `vscode` in `postCreateCommand`, since a fresh named volume is created root-owned.
