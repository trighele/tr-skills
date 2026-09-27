# __APP_NAME__

A React front end and a Python API, deployed together by the unified pipeline.
`pipeline.yaml` is the whole of how they are built, tested, routed and deployed;
`.github/workflows/release.yml` calls the pipeline and is never edited.

## Layout

```
pipeline.yaml               the contract with the pipeline
.github/workflows/release.yml
package.json, package-lock.json   npm workspace root: one node_modules for the front end
pyproject.toml, uv.lock     uv workspace root: one .venv for the api
scripts/dev.mjs             runs both components together
apps/web/                   the web component (Vite + React + TypeScript, nginx in the image)
  src/                      the app; tests sit beside what they test (*.test.tsx, Vitest)
apps/api/                   the api component (FastAPI)
  src/api/main.py           routes go here, on `router`; every one lives under /api
  tests/                    pytest
```

## Run it

```
npm install
uv sync
npm run dev          # http://localhost:5173, with the api under /api on the same origin
npm test             # front end: typecheck + Vitest
cd apps/api && uv run pytest
```

## One origin, no CORS

The front end holds `/` and the api holds `/api`, on the same hostname. The browser calls the
api with relative paths (`fetch('/api/...')`) and never needs a base URL: behind the router on
the target, and behind Vite's dev proxy locally, it is the same origin. The api keeps the
`/api` prefix in its own routes, because the router does not strip it.

## Configuration

- **Runtime values** (anything the running api reads, secret or not) are GitHub **Secrets** in
  this repo; each reaches the containers as an environment variable.
- **Build-time values** are GitHub **Variables**; each reaches every Dockerfile as a build
  argument. A value the React bundle needs is a Variable named `VITE_...`, declared as an
  `ARG`/`ENV` pair in `apps/web/Dockerfile`. It ends up in the bundle, readable by anyone, so
  never put a secret there.

## Deploying

Merging to `main` is the deploy. A pull request builds and tests and deploys nothing. The
application answers at `http://__APP_NAME__.lan.tomrighele.com` on the home network, and
publicly too once `pipeline.yaml` says `expose: true`.
