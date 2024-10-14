FROM alekzonder/puppeteer:latest AS pwaicons
USER root
WORKDIR /opt/
COPY rogue-thi-app/public/favicon.svg .
RUN mkdir ./splash && npx pwa-asset-generator --no-sandbox=true --path-override '/' --xhtml --dark-mode favicon.svg ./splash/

FROM node:21

WORKDIR /opt/next

ARG NEXT_PUBLIC_HACKERMAN_FLAGS
ARG NEXT_PUBLIC_GUEST_ONLY
ARG NEXT_PUBLIC_THI_API_MODE
ARG NEXT_PUBLIC_THI_API_KEY
ARG NEXT_PUBLIC_NEULAND_GRAPHQL_ENDPOINT

ENV NEXT_PUBLIC_HACKERMAN_FLAGS $NEXT_PUBLIC_HACKERMAN_FLAGS
ENV NEXT_PUBLIC_GUEST_ONLY $NEXT_PUBLIC_GUEST_ONLY
ENV NEXT_PUBLIC_THI_API_MODE $NEXT_PUBLIC_THI_API_MODE
ENV NEXT_PUBLIC_THI_API_KEY $NEXT_PUBLIC_THI_API_KEY
ENV NEXT_PUBLIC_NEULAND_GRAPHQL_ENDPOINT $NEXT_PUBLIC_NEULAND_GRAPHQL_ENDPOINT

COPY rogue-thi-app/package.json rogue-thi-app/package-lock.json ./
RUN npm install
COPY rogue-thi-app/ .

COPY --from=pwaicons /opt/splash/ public/

RUN curl --output-dir data/ https://assets.neuland.app/generated/spo-grade-weights.json
RUN curl --output-dir data/ https://assets.neuland.app/generated/room-distances.json
RUN curl --output-dir data/ https://assets.neuland.app/generated/ical-courses.json

RUN npm run build

ENV NODE_ENV=production

USER node
EXPOSE 3000
CMD ["npm", "start"]

FROM alekzonder/puppeteer:latest AS pwaicons
USER root
WORKDIR /opt/
COPY rogue-thi-app/public/favicon.svg .
RUN mkdir ./splash && npx pwa-asset-generator --no-sandbox=true --path-override '/' --xhtml --dark-mode favicon.svg ./splash/

FROM oven/bun:alpine AS base

# Stage 1: Install dependencies
FROM base AS deps
WORKDIR /opt/next
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

# Stage 2: Build the application
FROM base AS builder
WORKDIR /opt/next

ARG NEXT_PUBLIC_HACKERMAN_FLAGS
ARG NEXT_PUBLIC_GUEST_ONLY
ARG NEXT_PUBLIC_THI_API_MODE
ARG NEXT_PUBLIC_THI_API_KEY

ENV NEXT_PUBLIC_HACKERMAN_FLAGS $NEXT_PUBLIC_HACKERMAN_FLAGS
ENV NEXT_PUBLIC_GUEST_ONLY $NEXT_PUBLIC_GUEST_ONLY
ENV NEXT_PUBLIC_THI_API_MODE $NEXT_PUBLIC_THI_API_MODE
ENV NEXT_PUBLIC_THI_API_KEY $NEXT_PUBLIC_THI_API_KEY

ENV NEXT_TELEMETRY_DISABLED 1

COPY --from=deps /app/node_modules ./node_modules
COPY rogue-thi-app/ .

COPY --from=pwaicons /opt/splash/ public/
RUN curl --output-dir data/ https://assets.neuland.app/generated/spo-grade-weights.json
RUN curl --output-dir data/ https://assets.neuland.app/generated/room-distances.json
RUN curl --output-dir data/ https://assets.neuland.app/generated/ical-courses.json

RUN bun run build

# Stage 3: Production server
FROM base AS runner
WORKDIR /opt/next
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED 1

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["bun", "run", "server.js"]