#!/bin/sh


sed_replace() {

SEC_SED="./scripts/secrets/rep-secrets.sed"

# Get secrets from vaultwarden
rbw get $ITEM_NAME | sed 's/\\n/\n/g'

docker cp container_name ./scripts/secrets-posix.bak.sh

set -a
. "/secrets-posix.bak.sh"
set +a

if [ -f "$SEC_SED" ] && [ -f ./artifacts/sso.sh ]; then

    sed -f "$SEC_SED" < "./artifacts/sso.sh" > ./artifacts/replaSED-sso.sh && \
        envsubst < ./artifacts/replaSED-sso.sh > ./artifacts/unsealed-sso.sh
else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now..."
fi



}

vault_runner() {

docker network create vaultnet

if ! docker run --replace -d --name vaultwarden \
  -v vaultwarden-data:/data \
  -v ./scripts/:/app/ \
  -e ADMIN_TOKEN=supersecretadmintoken \
  --network vaultnet \
  -p 8080:80 \
  vaultwarden/server:latest; then

    echo "Starting vaultwarden container..."
fi

docker start vaultwarden

}

dev_connect() {

# docker run --rm -it --entrypoint=/bin/sh --network vaultnet alpine:3.20

apk upgrade && apk update
#apk add --no-cache \
#    vaultwarden

(
cat <<HMM
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
HMM
) > /etc/apk/repositories

apk add rbw


rbw config set email mymail
rbw config set base_url http://vaultwarden:80

# These should be mounted by the base containers
ADMIN_TOKEN=supersecretadmintoken
SECRETS_FILE="/mnt/vaultsecrets/secrets-posix.sh"
ITEM_NAME="pybana-credentials"
FIELDS=""
CONTENT=""

mkdir -p /mnt/vaultsecrets/

# export RBW_SESSION=$(rbw unlock --raw)
while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | tr -d '"' | xargs)
    echo "$key: $value"
  done < "$SECRETS_FILE" | sed ':a;N;$!ba;s/\n/\\n/g' \
      | "EDITOR=tee" rbw add "$ITEM_NAME"

  # Get secrets from vaultwarden
rbw get $ITEM_NAME | sed 's/\\n/\n/g'

set -a
. "./secrets-posix.sh"
set +a

scp ./secrets-posix.sh acmeorg00:/home/debian/secrets-posix.sh && \
    ssh acmeorg00 -t "
        set -a && \
        source /home/debian/secrets-posix.sh && \
        set +a && \
        rm /home/debian/secrets-posix.sh
    "
}

dev_client() {

vault_runner

podman run --rm -it \
    --name rbw-client \
    --network vaultnet \
    -v ./vaultsecrets:/mnt:ro \
    -v ./scripts/:/app/ \
    alpine:3.20  \
    /bin/sh -c "RUNNA=dev_connect . /app/replacer.sh"

EOF




}

check_bw() {

    if ! vaultwarden -h; then
        echo "Error: vaultwarden not installed"
    elif command -v bw; then
        curl -s -L -D - 'https://bitwarden.com/download/?app=cli&platform=linux' -o /dev/null | grep -i 'Content-Disposition'
    fi
    echo "vaultwarden was successfully loaded!"

    # if ! [ -f "$(readlink "$(which bw)")" ] || [ -f "$(readlink -f "$(which vaultwarden)" )" ]; then
    #     curl -s -L -D - 'https://bitwarden.com/download/?app=cli&platform=linux' -o /dev/null | grep -i 'Content-Disposition'
    # fi
}

bw_export() {


BW_SESSION=$(bw unlock --raw)
export BW_SESSION

ITEM_JSON=$(bw get item "acmeorg_pybana")

echo "$ITEM_JSON" | jq -r '.fields[] | "\(.name)=\()"' | while IFS='=' read -r key value;
do
    export "$key"="$value"
done

}

# Clean dangling replaced files
cleanup() {

    # find ./ \( -iname '*_rep_bak' \) -type f -exec echo {} +
    find ./ \( -iname '*_rep_bak' \) -type f -exec rm {} +
}

rep() {

INPUT_SCRIPT=$1
TMPDIR=$(/bin/busybox mktemp)

sed -f "$SEC_SED" "$INPUT_SCRIPT" > "$TMPDIR"

# Export list of secrets from Bitwarden as local environment variables
bw_export

envsubst < "$TMPDIR" > ./"$INPUT_SCRIPT"_rep_bak

chmod +x ./"${INPUT_SCRIPT}_rep_bak"

scp ./"${INPUT_SCRIPT}_rep_bak" acmeorg00:/pybana/scripts/outro/ && \
    ssh acmeorg00 -t ". /home/debian/pybana/scripts/outro/${INPUT_SCRIPT}_rep_bak"
}


print_usage() {
cat <<-END >&2
USAGE: ccr [-options]
                - checker
                - version
                - help
eg,
replacer -rep       # Replace secrets
replacer -clean     # runs qemu pointing to a custom initramfs and kernel bzImage
replacer -version   # shows script version
replacer -help      # shows this help message

See the man page and example file for more info.

END

}

# Check the argument passed from the command line
if [ -f "$INPUT_SCRIPT" ] && {
    [ "$FUNC" = "-rep" ] ||
    [ "$FUNC" = "--replace" ] ||
    [ "$FUNC" = "replace" ]
} ; then
    checker
elif {
    [ "$FUNC" = "-clean" ] ||
    [ "$FUNC" = "--clean" ] ||
    [ "$FUNC" = "clean" ]
} ; then
    cleanup



elif [ "$RUNNA" = "vault" ]; then
    if ! command -v podman; then
        vault_runner
    else
        CCR_MODE="checker" . ./scripts/ccr.sh && vault_runner
    fi

# run the vaultwarden and rbw containers
elif [ "$RUNNA" = "dev_client" ]; then
    if ! command -v podman; then
        dev_client
    else
        CCR_MODE="checker" . ./scripts/ccr.sh && dev_client
    fi
elif [ "$RUNNA" = "dev_connect" ]; then
    if ! command -v podman; then
        dev_connect
    else
        CCR_MODE="checker" . ./scripts/ccr.sh && dev_connect
    fi
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    printf "version 1.0.0"
else
    echo "Invalid function name. Please specify one of: function1, function2, function3"
    print_usage
fi

# run with:
# ; RUNNA=dev_client . ./scripts/replacer.sh


