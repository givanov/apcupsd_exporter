FROM alpine:3.13.2

RUN adduser -D apcupsd_exporter

USER apcupsd_exporter

ARG TARGETOS
ARG TARGETARCH

ADD _dist/${TARGETOS}-${TARGETARCH}/apcupsd_exporter /usr/local/bin/apcupsd_exporter

ENTRYPOINT ["/usr/local/bin/apcupsd_exporter"]
