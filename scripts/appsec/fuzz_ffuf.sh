#!/bin/sh


HOSTNAME="$1"

fuzza_ffuf() {

    ffuf -u "$HOSTNAME" \
        -w ./wordlists/discovery/directories.txt -t 40
}
