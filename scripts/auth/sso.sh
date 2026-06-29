#!/bin/sh

# //////////////
# ==========================
# Keycloak setup
# ==========================

setup_keycloak() {

# create artifact directories
mkdir -p ./artifacts/keycloak/

# set namespace
(
cat <<EOF
apiVersion: v1
kind: Namespace

metadata:
    name: keycloak

EOF
) | tee ./artifacts/keycloak/namespace.yaml

# set secrets
(
cat <<EOF
---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-admin-password
    namespace: keycloak
stringData:
    password: "\${{ secrets.RANDOM_KAP }}"
type: Opaque
---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-db-credentials
    namespace: keycloak
stringData:
    username: bn_keycloak
    password: "\${{ secrets.RANDOM_KDBC }}"
    postgres-password: "\${{ secrets.RANDOM_KDBC_POSTGRES }}"
type: Opaque

EOF
) | tee ./artifacts/keycloak/secrets.yaml

# set kustomize
(
cat <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: keycloak

resources:
    - namespace.yaml
    - secrets.yaml

helmCharts:
- name: keycloak
  releaseName: keycloak
  namespace: keycloak
  repo: https://github.com/bitnami/charts
  version: 24.3.0
  valuesInline:
    production: true
    proxy: edge

    auth:
        adminUser: "\${{ secrets.KEYCLOAK_CHART_ADMIN }}"
        existingSecret: keycloak-admin-password
        passwordSecretKey: "\${{ secrets.KEYCLOAK_CHART_PASSWD }}"

    ingress:
        enabled: true
        hostname: "keycloak.\${{ secrets.KEYCLOAK_DOMAIN }}"
        path: /
        tls: true

    postgresql:
        enabled: true
        auth:
            existingSecret:
        primary:
            persistence:
                enabled: true
                existingClaim: keycloak-postgresql


EOF
) | tee ./artifacts/keycloak/kustomize.yaml && \
    cd ./artifacts/keycloak || return && \
    kubectl kustomize . --enable-helm | kubectl apply -f - && \
    cd - || return

# eof
}


# ////////////////
# ==========================
# Crossplane setup
# ==========================

setup_crossplane() {

(
cat <<EOF
apiVersion: v1
kind: Namespace

metadata:
    name: crossplane

EOF
) | tee ./artifacts/keycloak-namespace.yaml

(
cat <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: crossplane

resources:
    - namespace.yaml

helmCharts:
- name: crossplane
releaseName: crossplane
namespace: crossplane
repo:
version: 1.19.0

EOF
) | tee ./artifacts/keycloak-namespace.yaml

(
cat <<EOF
EOF
) | tee ./artifacts/keycloak-namespace.yaml

}

# ////////////////
# ==========================
# replace actions workflow
# syntax with shellscript
# variable expansion
#
# ARC -> ArgoCD context
# ==========================
sed_replace() {

sed -e 's/\${{ secrets.AFW_UI_PASSWD }}/$AFW_UI_PASSWD/g' \
    -e \
    < "./artifacts/afw-user-create.sh"

}


# ////////////////
# ==========================
# get some help
# ==========================
print_helper() {
}
