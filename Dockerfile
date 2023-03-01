FROM golang:1.15-alpine3.14 AS cron-builder

ARG GO_CRON_VERSION=0.0.4
ARG GO_CRON_SHA256=6c8ac52637150e9c7ee88f43e29e158e96470a3aaa3fcf47fd33771a8a76d959

RUN apk add --no-cache curl \
 && curl -sL -o go-cron.tar.gz https://github.com/djmaze/go-cron/archive/v${GO_CRON_VERSION}.tar.gz \
 && echo "${GO_CRON_SHA256}  go-cron.tar.gz" | sha256sum -c - \
 && tar xzf go-cron.tar.gz \
 && cd go-cron-${GO_CRON_VERSION} \
 && go build \
 && mv go-cron /usr/local/bin/go-cron \
 && cd .. \
 && rm go-cron.tar.gz go-cron-${GO_CRON_VERSION} -fR

# Option #1 for mc - Compiling from scratch
FROM golang:alpine3.15 as minio

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

RUN go install github.com/minio/mc@latest

# Option #2 for mc - Copying directly from minio/mc (arm64 and amd64 only)
# FROM minio/mc as minio

FROM mikenye/youtube-dl:2023.02.17

RUN useradd -u 1001 -U -r -d /workdir youtube
COPY --from=cron-builder /usr/local/bin/* /usr/local/bin/

# Option #1 for mc - Compiling from scratch
COPY --from=minio /go/bin/mc /usr/local/bin/

# Option #2 for mc - Copying directly from minio/mc (arm64 and amd64 only)
# COPY --from=minio /usr/bin/mc /usr/local/bin/

COPY download.sh entrypoint /
RUN chown youtube:youtube /workdir

USER youtube

ENTRYPOINT ["bash", "/entrypoint"]
