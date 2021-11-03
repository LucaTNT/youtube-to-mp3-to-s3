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

#FROM minio/mc as minio
FROM golang:1.15-alpine as minio

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

RUN  \
     apk add --no-cache git && \
     git clone https://github.com/minio/mc && cd mc && \
     go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"

FROM mikenye/youtube-dl

RUN useradd -u 1001 -U -r -d /workdir youtube
COPY --from=cron-builder /usr/local/bin/* /usr/local/bin/
COPY --from=minio /go/bin/mc /usr/local/bin/

COPY download.sh entrypoint /
RUN chown youtube:youtube /workdir

USER youtube

ENTRYPOINT ["bash", "/entrypoint"]
