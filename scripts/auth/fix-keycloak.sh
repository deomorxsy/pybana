#!/bin/sh


create_sed() {

INPUT_SCRIPT=./scripts/fix-keycloak.sh FUNC=rep . ./scripts/replacer.sh | kubectl apply -f -

}


# netbird, keycloak, crossplane
nkc() {

LOCAL_KEYCLOAK_PASSWD="$KEYCLOAK_PASSWD"

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create namespace keycloak

kubectl create secret generic keycloak-admin-password \
  --from-literal=admin-password="$LOCAL_KEYCLOAK_PASSWD" \
  --namespace="keycloak"


RANDOM_KAP="idk1"
RANDOM_KDBC="903471298hre9qfdwvfds@rb3eqfy_"
RANDOM_KDBC_PSQL="4364@#_23124DSADSAAvdssgahmi23"
KEYCLOAK_ADMIN="4dm1n"
KEYCLOAK_PASSWD="81743r7e8fvw@@#F@&7_"
KEYCLOAK_DOMAIN="d0-keycloak.acmeorg.io"
KEYCLOAK_POSTGRES_PASSWD="HMMMAD1H3473GD8E7FRASi_@2GYEAGEYAGYE1@_G341R1"



LOCAL_RANDOM_KAP="$RANDOM_KAP"
LOCAL_RANDOM_KDBC="$RANDOM_KDBC"
LOCAL_RANDOM_KDBC_PSQL="$RANDOM_KDBC_PSQL"

LOCAL_KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN"
LOCAL_KEYCLOAK_PASSWD="$KEYCLOAK_PASSWD"
LOCAL_KEYCLOAK_DOMAIN=""
LOCAL_KEYCLOAK_POSTGRES_PASSWD="$KEYCLOAK_POSTGRES_PASSWD"


# Set keycloak secrets
(
cat <<EOF
---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-admin-password
    namespace: keycloak
stringData:
    password: "${RANDOM_KAP}"
type: Opaque

---
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-db-credentials
    namespace: keycloak
stringData:
    username: bn_keycloak
    password: "${LOCAL_RANDOM_KDBC}"
    postgres-password: "${LOCAL_RANDOM_KDBC_PSQL}"
type: Opaque
---
EOF
) | kubectl apply -f -


# =======================
# keycloak kustomization, unused
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
  version: "24.7.1"
  valuesInline:
    production: true
    proxy: edge

    auth:
      adminUser: "${LOCAL_KEYCLOAK_ADMIN}"
      existingSecret: keycloak-admin-password
      passwordSecretKey: "${LOCAL_KEYCLOAK_PASSWD}"

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
) | kubectl apply -f -


}

setup_ingress() {

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ui-ingress
  namespace: keycloak
  annotations:
   cert-manager.io/cluster-issuer: letsencrypt-prod
   nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-keycloak.acmeorg.io
    secretName: keycloak-ui-tls
  rules:
  - host: d0-keycloak.acmeorg.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keycloak
            port:
              number: 80
EOF
) | kubectl apply -f -

}




