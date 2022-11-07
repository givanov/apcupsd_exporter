FROM alpine:3.13.2

RUN apk --update --no-cache add ca-certificates

RUN adduser -D sparkpost-event-receiver

USER apcupsd_exporter

ADD _dist/linux-amd64/apcupsd_exporter /usr/local/bin/apcupsd_exporter

ENTRYPOINT ["/usr/local/bin/apcupsd_exporter"]