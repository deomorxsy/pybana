#!/bin/sh

# ======================
# set keycloak namespace
# ======================
(
cat <<EOF
apiVersion: v1
kind: Namespace

metadata:
    name: keycloak

EOF
) | tee ./keycloak-namespace.yaml && \
    kubectl apply -f ./keycloak-namespace.yaml

# ====================
# set keycloak secrets
# ===================
(
cat <<EOF
---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-admin-password
    namespace: keycloak
stringData:
    password: "idk1"
type: Opaque

---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-db-credentials
    namespace: keycloak
stringData:
    username: bn_keycloak
    password: "${REP_KEYCLOAK_DB_STRINGDATA_CREDS}"
    postgres-password: "${REP_KEYCLOAK_DB_STRINGDATA_POSTGRES_PASSWORD}"
type: Opaque
---
EOF
) | tee ./keycloak-secrets.yaml && \
    kubectl apply -f ./keycloak-secrets.yaml




# =======================
# keycloak kustomization
# =======================
(
cat <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: keycloak

resources:
    - keycloak-namespace.yaml
    - keycloak-secrets.yaml

helmCharts:
- name: keycloak
  releaseName: keycloak
  namespace: keycloak
  repo: https://charts.bitnami.com/bitnami
  version: 24.4.13
  valuesInline:
    production: true
    proxy: edge

    auth:
      adminUser: "${HELMCHART_KEYCLOAK_AUTH_ADMINUSER}"
      existingSecret: keycloak-admin-password
      passwordSecretKey: "${HELMCHART_KEYCLOAK_AUTH_PSK}"

    # hostname: keycloak.something
    ingress:
      enabled: true
      hostname: "d0-keycloak.acmeorg.io"
      path: /
      tls: true

    postgresql:
      enabled: true
      auth:
        existingSecret: keycloak-db-credentials
      primary:
        persistence:
          enabled: true
          existingClaim: keycloak-postgresql
EOF
) | tee ./kustomization.yaml && \
    kubectl kustomize . --enable-helm | kubectl apply -f - && \
        rm ./keycloak-secrets.yaml && rm ./keycloak-namespace.yaml

# ==================
# set crossplane
# ==================
# (
# cat <<EOF
# ---
# apiVersion: v1
# kind: Namespace
#
# metadata:
#     name: crossplane
# ---
# apiVersion: kustomize.config.k8s.io/v1beta1
# kind: Kustomization
# namespace: crossplane
#
# resources:
#     - namespace.yaml
#
# helmCharts:
# - name: crossplane
# releaseName: crossplane
# namespace: crossplane
# repo:
# version: 1.19.0
# ---
#
# EOF
# ) | tee ./crossplane-setup && \
#     kubectl apply -f -
