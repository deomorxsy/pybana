FROM alpine:3.20 AS builder

WORKDIR /app/
COPY ./* /app/

RUN <<EOF

apk upgrade && apk update && \
    apk add perl perl-dev build-base curl perl-app-cpanminus

# install the dependencies
cpanm Spreadsheet::ParseExcel

# call the script
. ./scripts/tableReader.pl

EOF
