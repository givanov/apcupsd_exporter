ARG GOLANG_VERSION=1.22.5

FROM golang:${GOLANG_VERSION} as builder

COPY . /go/github.com/givanov/apcupsd_exporter

WORKDIR /go/github.com/givanov/apcupsd_exporter

ARG TARGETOS
ARG TARGETARCH

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} make build


FROM alpine:3.20.1

RUN adduser -D apcupsd_exporter

USER apcupsd_exporter

COPY --from=builder /go/github.com/givanov/apcupsd_exporter/bin/apcupsd_exporter /usr/local/bin/apcupsd_exporter

ENTRYPOINT ["/usr/local/bin/apcupsd_exporter"]
