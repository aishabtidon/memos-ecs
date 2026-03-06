FROM node:20-alpine AS frontend-build
RUN apk add --no-cache libc6-compat


RUN corepack enable


WORKDIR /app/memos

COPY app/memos/web/package.json app/memos/web/pnpm-lock.yaml ./web/

RUN cd web && pnpm install --frozen-lockfile

COPY app/memos/ ./

RUN cd web && pnpm run release



FROM golang:1.25-alpine3.22 AS backend-build

RUN apk add --no-cache git ca-certificates

WORKDIR /app/memos


COPY app/memos/go.mod app/memos/go.sum ./
RUN go mod download


COPY app/memos/ ./

COPY --from=frontend-build /app/memos/server/router/frontend/dist ./server/router/frontend/dist

RUN go build -ldflags="-s -w" -o /out/memos ./cmd/memos



FROM alpine:3.20 AS runtime

RUN apk add --no-cache ca-certificates \
  && addgroup -S memos \
  && adduser -S -G memos -u 10001 memos

WORKDIR /usr/local/memos

COPY --from=backend-build /out/memos ./memos

RUN mkdir -p /var/opt/memos && chown -R memos:memos /var/opt/memos

USER memos

ENV MEMOS_MODE=prod
ENV MEMOS_PORT=5230

EXPOSE 5230

ENTRYPOINT ["./memos"]
CMD ["--data", "/var/opt/memos"]
