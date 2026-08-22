# Corporate proxy and custom CA certificates

**Work profile only.** Skip this file entirely on `windows-desktop` and `macbook`, and don't add empty proxy variables there — a defined-but-empty `HTTP_PROXY` breaks tools that check for the variable's presence rather than its value.

## First: check whether the image already handles it

Before adding anything from this file, look. A base image pulled *from* a corporate registry has usually been built by the same platform team that runs the TLS inspection, and already carries the CA and the env vars:

```bash
docker run --rm <image> sh -c 'ls /usr/local/share/ca-certificates/; env | grep -iE "ca_|cert|proxy|index"'
```

Entries like `mmc`, `zscaler.com`, or a pre-set `NODE_EXTRA_CA_CERTS` / `REQUESTS_CA_BUNDLE` / `PIP_INDEX_URL` mean the *env var* half of this file is already handled, and a `containerEnv` block that overrides a working value is worse than dead weight.

**But do not conclude the certificates themselves are handled.** Presence of a file named `zscaler.com/ZscalerRootCertificate.crt` proves nothing — see the next section. The only proof is a handshake.

## Verify by fingerprint, never by subject

The nastiest version of this failure: the image ships a certificate with exactly the right *subject* and the wrong *key*, because the tenant's root was re-keyed after the image was built. Everything looks correct and nothing works.

```
image ships:  CN=Zscaler Root CA   sha1 D7:2F:47:D8:74:20:E3:F0:...
host trusts:  CN=Zscaler Root CA   sha1 0D:23:EE:8F:0F:05:60:B9:...
```

So compare fingerprints against the host store, not names:

```bash
# in the container
openssl x509 -in /usr/local/share/ca-certificates/<vendor>/<file>.crt -noout -fingerprint -sha1
```

```powershell
# on the host
Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -match 'Zscaler|MMC|Falcon' |
  Select-Object Thumbprint, Subject, NotAfter
```

Also expect **more than one** inspecting CA. A host may run both a network proxy (Zscaler) and an endpoint agent (CrowdStrike Falcon), each with its own root, and the image may carry one, the other, or neither. Enumerate the host store rather than assuming a single corporate root.

The decisive test, which takes one command:

```bash
echo | openssl s_client -connect api.anthropic.com:443 -servername api.anthropic.com 2>/dev/null \
  | grep -E "^ *[0-9] s:|Verify return code"
```

`Verify return code: 21 (unable to verify the first certificate)` with a depth-0 subject of `O = Zscaler Inc.` means the inspecting root is missing or mismatched, regardless of what is sitting in the cert directory.

## Prefer exporting the live host store over a checked-in cert

A `.crt` committed to the repo — or pasted into a file by hand — goes stale the moment anything is re-keyed, and the failure it produces looks nothing like "your certificate is out of date". If the project already has a bootstrap script ([machine-local-config.md](./machine-local-config.md)), have it read the host trust store on every run and write the results to a gitignored `.devcontainer/certs/`:

```powershell
Get-ChildItem Cert:\LocalMachine\Root, Cert:\CurrentUser\Root |
  Where-Object { $_.NotAfter -gt (Get-Date) } | Sort-Object Thumbprint -Unique |
  ForEach-Object { [Convert]::ToBase64String($_.RawData) }
```

```bash
# macOS equivalent
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain
security find-certificate -a -p /Library/Keychains/System.keychain
```

Export **everything the host trusts** rather than grepping for known corporate names. A filter that misses one cert produces a baffling failure, the list differs per machine, and these are roots the host already trusts anyway. Expect a few hundred on Windows — that is normal and harmless.

Two mechanical details:

- **One certificate per file.** `update-ca-certificates` reads only `*.crt` and only the *first* PEM block in each, so a concatenated bundle silently loses everything after the first cert. This is the single most common way a hand-made bundle "installs" and still fails.
- **Delete stale `*.crt` on each run**, or a revoked or re-keyed cert lingers in the image forever.

Commit a `.gitkeep` in the certs directory and gitignore only `certs/*.crt`. `COPY ./certs/ ...` fails the build if the directory does not exist, and a fresh clone has no exports yet.

Equally, a work host may have **no proxy at all**: check `HTTP_PROXY` and `npm config get cafile` rather than assuming. TLS inspection via an installed root CA and an explicit HTTP proxy are separate things, and a Zscaler-style deployment often needs neither variable set. Only what's actually missing should be added.

## The symptom

Almost every failure on the work machine looks the same: `npm install`, `apt-get update`, `pip install`, or `git clone` dies with a TLS error — `SELF_SIGNED_CERT_IN_CHAIN`, `unable to get local issuer certificate`, `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `certificate verify failed`.

The cause is always the same: corporate TLS inspection re-signs traffic with an internal root CA that the host trusts and the fresh container doesn't. Two things must be true inside the container — traffic goes through the proxy, and the internal root CA is trusted — and the second is what's usually missing.

## Get the CA certificate

Export the corporate root CA from the host as PEM (`-----BEGIN CERTIFICATE-----`), typically from the Windows certificate store or from whatever `npm config get cafile` already points at on the host. Save it to `.devcontainer/certs/corporate-root-ca.crt`.

**Ask before deciding whether it's committed.** A corporate root CA is not a secret — it's a public certificate — but many organizations still treat it as internal. Default to `.gitignore`-ing `.devcontainer/certs/` and documenting where to fetch it in the project README; commit it only if the user says the repo is internal and they want a zero-setup clone. If it is gitignored, the Dockerfile's `COPY` must tolerate its absence.

## Install it in the image

```dockerfile
# Tolerates an absent certs/ directory: the glob matches nothing and the
# trailing directory argument keeps COPY valid.
COPY certs*/ /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

That covers anything using the system trust store (apt, curl, git). Toolchains that ship their own bundle need pointing at it explicitly:

```jsonc
"containerEnv": {
  "NODE_EXTRA_CA_CERTS": "/etc/ssl/certs/ca-certificates.crt",
  "REQUESTS_CA_BUNDLE": "/etc/ssl/certs/ca-certificates.crt",
  "SSL_CERT_FILE":      "/etc/ssl/certs/ca-certificates.crt",
  "CURL_CA_BUNDLE":     "/etc/ssl/certs/ca-certificates.crt",
  "GIT_SSL_CAINFO":     "/etc/ssl/certs/ca-certificates.crt"
}
```

`update-ca-certificates` merges the corporate CA into `ca-certificates.crt`, so pointing every tool at that one bundle keeps public CAs working too. Pointing them at the bare `corporate-root-ca.crt` instead would trust *only* the corporate CA and break everything else — a common and confusing mistake.

`NODE_EXTRA_CA_CERTS` is the one that unblocks `npm install -g @anthropic-ai/claude-code`. If Claude Code fails to install on this machine and nowhere else, this is why.

## Pass the proxy through

Inherit from the host rather than hard-coding, so the same file works everywhere:

```jsonc
"containerEnv": {
  "HTTP_PROXY":  "${localEnv:HTTP_PROXY}",
  "HTTPS_PROXY": "${localEnv:HTTPS_PROXY}",
  "NO_PROXY":    "${localEnv:NO_PROXY}",
  "http_proxy":  "${localEnv:HTTP_PROXY}",
  "https_proxy": "${localEnv:HTTPS_PROXY}",
  "no_proxy":    "${localEnv:NO_PROXY}"
}
```

Both cases are needed — different tools read different ones, and there's no convention that covers both.

Add container-internal addresses to `NO_PROXY` so service-to-service traffic doesn't get routed out and back: `localhost,127.0.0.1,::1,host.docker.internal,.internal`.

**apt during build** doesn't read `containerEnv` — that only applies at run time. If `apt-get update` fails during the image build, the proxy has to be passed as a build arg and written into `/etc/apt/apt.conf.d/`:

```jsonc
"build": { "args": { "HTTP_PROXY": "${localEnv:HTTP_PROXY}", "HTTPS_PROXY": "${localEnv:HTTPS_PROXY}" } }
```

```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
RUN if [ -n "$HTTP_PROXY" ]; then \
      printf 'Acquire::http::Proxy "%s";\nAcquire::https::Proxy "%s";\n' "$HTTP_PROXY" "$HTTPS_PROXY" \
        > /etc/apt/apt.conf.d/99proxy; \
    fi
```

## Verify

The real test is a tool actually reaching the network, not a `curl` to a public host:

```bash
npm ping
git ls-remote origin
pip download --no-deps --dest /tmp pip   # if Python is in the stack
apt-get update                            # sudo
```

If `curl https://example.com` works but `npm ping` fails, the proxy is fine and the CA bundle env vars are the problem. If both fail, it's the proxy.

## What not to do

Never resolve this with `NODE_TLS_REJECT_UNAUTHORIZED=0`, `npm config set strict-ssl false`, `git config http.sslVerify false`, or `PIP_TRUSTED_HOST`. They disable verification rather than fixing trust, they silently persist into the project's committed config, and they hide the next real certificate problem. If a TLS error survives everything above, the CA export is wrong or incomplete — go back and re-export it, including any intermediate certificates in the chain.
