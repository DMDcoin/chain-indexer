# syntax=docker/dockerfile:1

FROM node:22-alpine@sha256:1314fb30ec37592d5845e5a160d522c0e680972aa534549940b8d73bde88481a AS build

WORKDIR /app

COPY package.json package-lock.json ./

# none of the dependencies need their install scripts
RUN npm ci --ignore-scripts --no-audit --no-fund

COPY tsconfig.json ./
COPY src ./src

RUN npm run build \
    && npm prune --omit=dev --ignore-scripts --no-audit --no-fund

FROM node:22-alpine@sha256:1314fb30ec37592d5845e5a160d522c0e680972aa534549940b8d73bde88481a

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
