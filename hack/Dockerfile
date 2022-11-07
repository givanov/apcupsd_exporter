FROM alpine:3.13.2

RUN apk --update --no-cache add ca-certificates

RUN adduser -D sparkpost-event-receiver

USER apcupsd_exporter

ARG TARGETOS
ARG TARGETARCH

ADD _dist/${TARGETOS}-${TARGETARCH}/apcupsd_exporter /usr/local/bin/apcupsd_exporter

ENTRYPOINT ["/usr/local/bin/apcupsd_exporter"]