# The web component. Built with the repository root as context (the pipeline always does
# that), so the workspace manifests above this directory are part of the build and the
# hoisted node_modules resolves exactly as it does on a developer's machine.

# ---- build stage -----------------------------------------------------------
# Node 22, the version the pipeline's test job runs under, so a build and its tests agree.
FROM node:22-alpine AS build

# Build-time configuration comes from the app repo's GitHub Variables: every Variable arrives
# as a build argument, and a Secret never does. Vite only exposes names starting VITE_ to the
# bundle, and anything exposed is readable by whoever loads the page. Declare one pair per
# Variable the bundle reads:
#
# ARG VITE_EXAMPLE
# ENV VITE_EXAMPLE=${VITE_EXAMPLE}

WORKDIR /repo

# Manifests first, so a source edit does not reinstall dependencies.
COPY package.json package-lock.json ./
COPY apps/web/package.json apps/web/package.json
RUN npm ci --workspace apps/web

COPY apps/web apps/web
RUN npm run build --workspace apps/web

# ---- serving stage ---------------------------------------------------------
FROM nginx:alpine

COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf
# Only the build output crosses over; no sources, no node_modules.
COPY --from=build /repo/apps/web/dist /usr/share/nginx/html

EXPOSE 80
