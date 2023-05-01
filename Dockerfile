FROM golang as builder

RUN dpkgArch="$(dpkg --print-architecture)"; \
    case "$dpkgArch" in \
        arm) ARCH='arm' ;; \
        arm64) ARCH='arm64' ;; \
        amd64) ARCH='amd64' ;; \
        386) ARCH='386' ;; \
        *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac

RUN mkdir -p /opt/rdpgw && cd /opt/rdpgw
RUN adduser --disabled-password --gecos "" --home /opt/rdpgw --uid 1001 rdpgw

RUN git clone https://github.com/cybertrol-engineering/CE.Dockerfiles.rdpgw-docker.git /app && \
    cd /app && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -tags '' -ldflags '' -o '/opt/rdpgw/rdpgw' ./cmd/rdpgw && \
    chmod +x /opt/rdpgw/rdpgw && \
    chown -R 1001 /opt/rdpgw

FROM alpine:latest

COPY --from=builder /opt/rdpgw /opt/rdpgw
COPY --from=builder /etc/passwd /etc/passwd

COPY --from=builder /etc/ssl/certs /etc/ssl/certs

USER 1001
WORKDIR /opt/rdpgw
ENTRYPOINT /opt/rdpgw/rdpgw
