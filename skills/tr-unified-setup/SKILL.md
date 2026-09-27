---
name: tr-unified-setup
description: "Scaffold an empty repo as an app for the unified pipeline: a Python microservice, or a React front end plus a Python API. Writes pipeline.yaml, the caller workflow, Dockerfiles, and a passing test per component, so only the app's own code is left to write."
disable-model-invocation: true
---

# Unified Setup

Turn an **empty** repository into an app repo the unified pipeline can build, test and deploy on its first merge — so the only thing left to write is the application itself.

Two shapes, and only two:

| Shape | Components | What holds `/` |
| --- | --- | --- |
| **Microservice** | `api` — Python (FastAPI, uv) in `apps/api` | `api` |
| **Front end + microservice** | `web` — React (Vite, TypeScript, nginx) in `apps/web`; `api` — as above, under `/api` | `web` |

The microservice shape deliberately uses `apps/api` rather than the repo root, so adding a front end later is an addition, not a restructure.

Everything written comes from the files in [templates/](./templates/). Copy them; don't improvise a layout. They mirror the pipeline's own template and the `profile-ui` repo, which is the working reference for the two-component shape, and they were checked against the pipeline's renderer.

## What the pipeline expects (why the templates look the way they do)

Don't restate this to the user; it's here so you don't "fix" something that is deliberate.

- **`pipeline.yaml` is the entire contract** and `.github/workflows/release.yml` is copied **unchanged** — it calls `tomrighele/project_unifiedPipeline/.github/workflows/app-release.yml@v1`. Nothing else deploy-related belongs in the repo: no Compose file, no other workflow, no published ports.
- **The build context is always the repo root.** Each Dockerfile copies the workspace manifests and lock from the root; that is why there is one `uv.lock` and one `package-lock.json`, at the root, and why both must exist before a build.
- **Tests run in the component directory**: `uv run pytest` for `stack: python`, `npm ci && npm test` for `stack: node`, Node 22. `tests` stays on — each component ships with a real passing test. Never write `tests: false`.
- **The api keeps its route prefix in its own source**, because the router does not strip it. `ROUTE_PREFIX` in `apps/api/src/api/main.py` is `""` for the microservice and `"/api"` for the two-component shape. Health path is `<prefix>/healthz`; the release rolls back if it never answers 2xx.
- **Same origin, no CORS.** The front end calls the api with relative `/api/...` paths; Vite's dev proxy reproduces the router locally.
- **Variables → build arguments, Secrets → runtime environment.** A GitHub Variable is baked into the image; a Secret never is.

## Process

### 1. Check the repo is empty

This skill only scaffolds an empty repo. Look at the working directory. These may already be there and are left alone: `.git/`, `README.md` (replaced — say so), `LICENSE`, `.gitignore` (merged, not replaced), `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `docs/`, `.claude/`, `.devcontainer/`, `.scratch/`.

Anything else — above all `pipeline.yaml`, `apps/`, `package.json`, `pyproject.toml`, or any source code — means **stop**. Say what you found and that this skill doesn't retrofit existing code. Don't offer to do it anyway.

Then check the tools: `uv` always; `node` and `npm` for the front-end shape; `docker` is optional (it only gates the build check in step 5). A missing required tool is a stop, naming the install.

### 2. Ask one round

One `AskUserQuestion` call, three questions, recommended option first:

1. **Shape** — "Microservice (Python API only)" or "Front end + microservice (React + Python API)". No recommendation; this is the user's call.
2. **Name** — the app's `name:`. Offer the directory name, lowercased and hyphenated, as the recommended option. It must be a DNS label: lowercase letters, digits, hyphens, not starting or ending with a hyphen. It becomes `<name>.lan.tomrighele.com` and prefixes every image and volume, and can't be renamed later without becoming a new app — say that in the option description. If a typed name isn't a valid label, say why and ask again.
3. **Exposure** — "Internal only (Recommended)" or "Public on `<name>.tomrighele.com`".

Ask nothing else. Versions, frameworks, ports and layout are decided by the templates.

### 3. Write the files

Copy from `templates/`, then replace every `__APP_NAME__` with the name, and `__ROUTE_PREFIX__` with nothing for the microservice (the line reads `ROUTE_PREFIX = ""`) or with `/api` for front end + microservice.

In the templates a leading `dot-` stands for `.` — `dot-gitignore` → `.gitignore`, `dot-dockerignore` → `.dockerignore`, `dot-github/` → `.github/`. They're stored that way so the skill tree's own git doesn't treat them as its config.

| Source | Destination | Shape |
| --- | --- | --- |
| `templates/api/**` | repo root, same relative paths | both |
| `templates/web/**` | repo root, same relative paths | front end + microservice only |
| `templates/pipeline-service.yaml` | `pipeline.yaml` | microservice |
| `templates/pipeline-fullstack.yaml` | `pipeline.yaml` | front end + microservice |
| `templates/readme-service.md` | `README.md` | microservice |
| `templates/readme-fullstack.md` | `README.md` | front end + microservice |

If the user chose public, uncomment `# expose: true` in `pipeline.yaml`. Touch nothing else in it.

If a `.gitignore` already existed, append the template's lines that aren't already in it rather than overwriting.

`.github/workflows/release.yml` is copied byte for byte. Don't reformat it, rename the job, or add triggers.

### 4. Lock the dependencies

The Dockerfiles install from the lock files with `--frozen` / `npm ci`, so they must exist:

- `uv sync` at the repo root → writes `uv.lock` and `.venv`.
- Front end + microservice: `npm install` at the repo root → writes `package-lock.json` and the root `node_modules`.

Don't pin, bump or add dependencies beyond the templates'. If a template version no longer resolves, report it rather than picking another.

### 5. Prove it works

Run exactly what the pipeline will run, from the component directories:

- `apps/api`: `uv run pytest`
- `apps/web` (front end + microservice): `npm ci && npm test`

If Docker is available, build each component the way the pipeline does — context is the root — then run it and fetch its health path:

```
docker build -f apps/api/Dockerfile -t <name>-api:scaffold .
docker run -d --rm -p 18000:8000 --name <name>-api-check <name>-api:scaffold
curl -fsS http://localhost:18000<prefix>/healthz      # retry for a few seconds while it starts
docker stop <name>-api-check

docker build -f apps/web/Dockerfile -t <name>-web:scaffold .     # front end + microservice
docker run -d --rm -p 18080:80 --name <name>-web-check <name>-web:scaffold
curl -fsS http://localhost:18080/
docker stop <name>-web-check
```

Remove the `:scaffold` images afterwards. No Docker → skip, and say so in the close-out.

Anything red is reported with its output. Don't paper over it by editing a test or the pipeline contract.

### 6. Close out

Say, in this order and nothing more:

1. The shape and name, and the files written, as a short tree.
2. The checks: tests green per component; Docker build and health check passed, or skipped and why.
3. **Where the code goes**: api routes on `router` in `apps/api/src/api/main.py`; front end in `apps/web/src/`.
4. **Before the first merge** — as a checklist:
   - Create the repo **inside the `tomrighele` org, Private** (a public repo in an org with a self-hosted runner is a way onto the deploy target), and push.
   - Runtime values → **Secrets**; build-time values → **Variables** (a React value is a `VITE_` Variable plus an `ARG`/`ENV` in `apps/web/Dockerfile`).
   - Open a PR: it builds and tests, and the deploy job shows *skipped* — that's the gate working. Merging to `main` deploys.
   - Then `http://<name>.lan.tomrighele.com` from the home network.
5. One line: if the repo isn't configured for the rest of the flow yet, `/tr-setup-skills` next, and `/tr-setup-devcontainer` if it needs a container.

## Don't

- **Don't run on a non-empty repo.** No retrofitting, no merging into existing source.
- **Don't commit, `git init`, create the GitHub repo, or set Secrets/Variables.** Tom does those; the close-out tells him how.
- **Don't write `tests: false`**, a `test_command`, a Compose file, `ports:`, or a second workflow.
- **Don't edit the caller workflow** or change its `@v1` pin.
- **Don't add application features.** The scaffold is a health endpoint, one page that shows it, and one test each. Stop there.
- **Don't swap the stack** (Next.js, Flask, pnpm, Poetry, CRA …) because it seems better. The pipeline's `stack` values and the Dockerfiles assume exactly these.

## Keeping the templates current

`templates/api/dot-github/workflows/release.yml` and both `pipeline-*.yaml` files are copies of the unified pipeline's `template/` directory, adapted per shape. When that template changes — a new field, a new `@v2` tag — update these by hand. The skill has no way to notice drift on its own.
