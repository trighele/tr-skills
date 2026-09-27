# The API component. Built with the repository root as context — the pipeline always does
# that — so the uv workspace root above this directory, and its single lock file, are part of
# the build and the image installs exactly what a developer's machine resolved.

FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:0.11 /uv /usr/local/bin/uv

WORKDIR /repo

# Manifests first, so a source edit does not reinstall dependencies.
COPY pyproject.toml uv.lock ./
COPY apps/api/pyproject.toml apps/api/pyproject.toml
RUN uv sync --frozen --no-install-project --no-dev --package __APP_NAME__-api

COPY apps/api apps/api
RUN uv sync --frozen --no-dev --package __APP_NAME__-api

ENV PATH="/repo/.venv/bin:$PATH"

EXPOSE 8000

# Runtime configuration arrives as environment variables from the app repo's GitHub Secrets.
# Nothing here strips or adds a path prefix; the routes carry their own (see main.py).
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
