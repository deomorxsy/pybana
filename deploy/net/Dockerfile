FROM alpine:3.20 AS builder

RUN <<EOF

apk upgrade && apk update && \
    apk add nmap nmap-scripts
EOF
