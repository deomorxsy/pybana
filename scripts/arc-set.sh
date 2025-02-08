#!/bin/sh

# Actions Runner Controller (ARC) set

INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
ORG_CONFIG_URL="${ORG_CONFIG_URL:-https://default-config-url.local}"

# github personal access token
if [ "$GITHUB_PAT" = "" ]; then
    GITHUB_PAT=""
else
    GITHUB_PAT="${GITHUB_PAT:-default_token_here}"

fi



helm install "${INSTALLATION_NAME}" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set githubConfigUrl="$ORG_CONFIG_URL" \
    --set githubConfigSecret.github_token="$GITHUB_PAT" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set


