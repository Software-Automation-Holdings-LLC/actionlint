ARG GOLANG_VER=latest
ARG ALPINE_VER=latest

FROM golang:${GOLANG_VER} AS builder
WORKDIR /go/src/app
COPY go.* *.go ./
COPY cmd cmd/
ENV CGO_ENABLED=0
ARG ACTIONLINT_VER=
RUN go build -v -ldflags "-s -w -X github.com/rhysd/actionlint.version=${ACTIONLINT_VER}" ./cmd/actionlint

FROM koalaman/shellcheck-alpine:stable AS shellcheck

FROM alpine:${ALPINE_VER}
COPY --from=builder /go/src/app/actionlint /usr/local/bin/
COPY --from=shellcheck /bin/shellcheck /usr/local/bin/shellcheck
# ALPINE_VER is latest, so a package pin would not track the base image. CI passes --ignore DL3018 for the same reason.
# hadolint ignore=DL3018
RUN apk add --no-cache py3-pyflakes
# alpine-baselayout's guest account is uid 405, gid 100. A name does not resolve on the host (hadolint DL3066).
USER 405:100
ENTRYPOINT ["/usr/local/bin/actionlint"]
