# __APP_NAME__

A Python API, deployed by the unified pipeline. `pipeline.yaml` is the whole of how it is
built, tested, routed and deployed; `.github/workflows/release.yml` calls the pipeline and is
never edited.

## Layout

```
pipeline.yaml               the contract with the pipeline
.github/workflows/release.yml
pyproject.toml, uv.lock     uv workspace root: one .venv, one lock, for every Python component
apps/api/                   the api component (FastAPI) and its Dockerfile
  src/api/main.py           routes go here, on `router`
  tests/                    pytest
```

## Run it

```
uv sync
cd apps/api
uv run uvicorn api.main:app --reload --port 8000     # http://localhost:8000/healthz
uv run pytest
```

## Configuration

- **Runtime values** (anything the running process reads, secret or not) are GitHub
  **Secrets** in this repo; each reaches the container as an environment variable.
- **Build-time values** are GitHub **Variables**; each reaches every Dockerfile as a build
  argument. The API rarely needs any.

## Deploying

Merging to `main` is the deploy. A pull request builds and tests and deploys nothing. The
application answers at `http://__APP_NAME__.lan.tomrighele.com` on the home network, and
publicly too once `pipeline.yaml` says `expose: true`.

## Adding a front end later

The layout already leaves room for it: a web component goes in `apps/web` and takes the root,
and this API moves under `/api` so the two share one origin. In one commit:

1. `ROUTE_PREFIX = "/api"` in `apps/api/src/api/main.py`.
2. In `pipeline.yaml`, on the api component: `route: /api` and `health_path: /api/healthz`.
3. Add `apps/web` with its own Dockerfile, a root `package.json` workspace, and a `web`
   component in `pipeline.yaml` with no route.
