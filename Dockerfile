FROM --platform=$BUILDPLATFORM golang:alpine3.21 AS builder

ARG TARGETARCH
ARG TARGETVARIANT
ARG GO_CRON_VERSION=0.0.4
ARG GO_CRON_SHA256=6c8ac52637150e9c7ee88f43e29e158e96470a3aaa3fcf47fd33771a8a76d959

ENV GOPATH=/go
ENV CGO_ENABLED=0
ENV GO111MODULE=on

RUN apk add --no-cache curl \
 && curl -fsL -o go-cron.tar.gz https://github.com/djmaze/go-cron/archive/v${GO_CRON_VERSION}.tar.gz \
 && echo "${GO_CRON_SHA256}  go-cron.tar.gz" | sha256sum -c - \
 && tar xzf go-cron.tar.gz \
 && cd go-cron-${GO_CRON_VERSION} \
 && GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go build \
 && mv go-cron /usr/local/bin/go-cron \
 && cd .. \
 && rm go-cron.tar.gz go-cron-${GO_CRON_VERSION} -fR

# Option #1 for mc - Compiling from scratch
# (cross-compiling makes `go install` drop the binary under a $GOOS_$GOARCH
# subdirectory instead of /go/bin directly, so relocate it explicitly)
RUN GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} go install github.com/minio/mc@latest \
 && find /go/bin -name mc -exec mv {} /go/bin/mc \;

# Option #2 for mc - Copying directly from minio/mc (arm64 and amd64 only)
# FROM minio/mc as minio

FROM mikenye/youtube-dl:latest_nohealthcheck

RUN useradd -u 1001 -U -r -d /workdir youtube
COPY --from=builder /usr/local/bin/go-cron /usr/local/bin/
COPY --from=builder /go/bin/mc /usr/local/bin/

COPY download.sh entrypoint /
RUN chown youtube:youtube /workdir

USER youtube

ENTRYPOINT ["bash", "/entrypoint"]
