# syntax=docker/dockerfile:1

FROM node:22-alpine@sha256:0e1754758c2df4cfa3e68d59e2e1b7374bb7fd9ea6328eaaacf15cc934af8202 AS build

WORKDIR /app

COPY package.json package-lock.json ./

# none of the dependencies need their install scripts
RUN npm ci --ignore-scripts --no-audit --no-fund

COPY tsconfig.json ./
COPY src ./src

RUN npm run build \
    && npm prune --omit=dev --ignore-scripts --no-audit --no-fund

FROM node:22-alpine@sha256:0e1754758c2df4cfa3e68d59e2e1b7374bb7fd9ea6328eaaacf15cc934af8202

LABEL org.opencontainers.image.title="chain-indexer" \
      org.opencontainers.image.licenses="AGPL-3.0-only"

ENV NODE_CONFIG_DIR=/app/config

WORKDIR /app

COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY config/default.json ./config/default.json
COPY --chmod=0755 entrypoint.sh ./entrypoint.sh

# working directory for the files created at runtime (.mnemonic, .mainaddress)
RUN mkdir -p /var/lib/chain-indexer && chown node:node /var/lib/chain-indexer

USER node

WORKDIR /var/lib/chain-indexer

ENTRYPOINT ["/app/entrypoint.sh"]
