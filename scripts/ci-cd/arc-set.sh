#!/bin/sh

# Actions Runner Controller (ARC) set

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
ORG_CONFIG_URL="${ORG_CONFIG_URL:-https://default-config-url.local}"
GITHUB_PAT="\${{ secrets.GITHUB_PAT }}"


# github personal access token
if [ "$GITHUB_PAT" = "" ]; then
    GITHUB_PAT="GTHUB_PAT"
else
    GITHUB_PAT="${GITHUB_PAT:-default_token_here}"

fi



helm install "${INSTALLATION_NAME}" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set githubConfigUrl="$ORG_CONFIG_URL" \
    --set githubConfigSecret.github_token="$GITHUB_PAT" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set


get_right() {

#!/bin/sh
NAMESPACE_ONE="arc-systems"
helm upgrade --install arc \
    --namespace "${NAMESPACE_ONE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller


INSTALLATION_NAME="arc-runner-set"
NAMESPACE_TWO="arc-runners"
GITHUB_CONFIG_URL=" \${{ secrets.GITHUB_CONFIG_URL }}"
GITHUB_PAT="\${{ secrets.GITHUB_PAT }}"
helm upgrade --install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE_TWO}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    --set ghaRunner.listener="ghalistener" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller



}

