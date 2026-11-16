FROM node:24-bookworm-slim AS build
WORKDIR /build
COPY frontend/package.json frontend/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/tsconfig.json frontend/next.config.ts frontend/eslint.config.mjs ./
ENV NEXT_PUBLIC_APP_MODE=live
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run check && npm run build

FROM nginx:1.28-alpine
COPY --from=build /build/out /usr/share/nginx/html
COPY docker/demo/nginx.conf /etc/nginx/conf.d/default.conf
