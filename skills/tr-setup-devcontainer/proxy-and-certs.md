# Corporate proxy and custom CA certificates

**Work profile only.** Skip this file entirely on `windows-desktop` and `macbook`, and don't add empty proxy variables there — a defined-but-empty `HTTP_PROXY` breaks tools that check for the variable's presence rather than its value.

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
