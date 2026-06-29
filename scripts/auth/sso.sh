#!/bin/sh

# //////////////
# ==========================
# Keycloak setup
# ==========================

setup_keycloak() {


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


# create artifact directories
mkdir -p ./deploy/k8s/keycloak/

# set namespace
if ! [ -f ./deploy/k8s/keycloak/namespace.yaml ]; then
(
cat <<EOF
apiVersion: v1
kind: Namespace

metadata:
    name: keycloak

EOF
) | tee ./deploy/k8s/keycloak/namespace.yaml && \
    cat ./deploy/k8s/keycloak/namespace.yaml | kubectl apply -f -


# tee ./deploy/k8s/keycloak/namespace.yaml

else

    kubectl apply -f ./deploy/k8s/keycloak/namespace.yaml
fi

# set secrets
if ! [ -f ./deploy/k8s/keycloak/secrets.yaml ]; then
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
    password: "${RANDOM_KDBC}"
    postgres-password: "${RANDOM_KDBC_PSQL}"
type: Opaque

EOF
) | tee ./deploy/k8s/keycloak/secrets.yaml && \
    cat ./deploy/k8s/keycloak/secrets.yaml | kubectl apply -f -

else
    kubectl apply -f - ./deploy/k8s/keycloak/secrets.yaml
fi


# set kustomize
if ! [ -f ./deploy/k8s/keycloak/kustomize.yaml ]; then
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
  version: 24.7.1
  valuesInline:
    production: true
    proxy: edge

    auth:
      adminUser: "${KEYCLOAK_ADMIN}"
      existingSecret: keycloak-admin-password
      passwordSecretKey: "${KEYCLOAK_PASSWD}"

    ingress:
      enabled: true
      hostname: "keycloak.${KEYCLOAK_DOMAIN}"
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
) | tee ./deploy/k8s/keycloak/kustomize.yaml && \
    kubectl kustomize ./deploy/k8s/keycloak/ --enable-helm | kubectl apply -f -

else
    kubectl kustomize ./deploy/k8s/keycloak/ --enable-helm | kubectl apply -f -
fi

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
) | kubectl apply -f -

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
) | tee ./deploy/k8s/crossplane/kustomization.yaml &&
    kubectl kustomize ./deploy/k8s/crossplane/ --enable-helm | kubectl apply -f -

(
cat <<EOF
EOF
) | kubectl apply -f -

}



# ////////////////
# ==========================
# get some help
# ==========================
print_helper() {
    echo hmm
}

# unused
keycloak() {

kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/refs/heads/main/kubernetes/keycloak.yaml


(
cat <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: keycloak
  labels:
    app: keycloak
spec:
  ports:
    - name: http
      port: 8080
      targetPort: 8080
  selector:
    app: keycloak
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: keycloak
  labels:
    app: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:26.1.4
          args: ["start-dev"]
          env:
            - name: KEYCLOAK_ADMIN
              value: "admin"
            - name: KEYCLOAK_ADMIN_PASSWORD
              value: "admin"
            - name: KC_PROXY_HEADERS
              value: "xforwarded"
            - name: KC_HTTP_ENABLED
              value: "true"
            - name: KC_HEALTH_ENABLED
              value: "true"
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 9000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: keycloak
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - KEYCLOAK_HOST
    secretName: keycloak-ui-tls
  rules:
  - host: "${LOCAL_KEYCLOAK_DOMAIN}"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keycloak
            port:
              number: 8888
EOF
) | sed "s/KEYCLOAK_HOST/d0-keycloak.acmeorg.io/" | kubectl apply -f -


}




randogen() {

PASSWD_GEN=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)

echo "$PASSWD_GEN"
}



newingress() {


(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: keycloak
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - KEYCLOAK_HOST
    secretName: keycloak-ui-tls
  rules:
  - host: KEYCLOAK_HOST
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
) | sed "s/KEYCLOAK_HOST/d0-keycloak.acmeorg.io/" | kubectl apply -f -


}

new() {

LOCAL_KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN"
LOCAL_KEYCLOAK_PASSWD="$KEYCLOAK_PASSWD"
LOCAL_KEYCLOAK_DOMAIN=""
LOCAL_KEYCLOAK_POSTGRES_PASSWD="$KEYCLOAK_POSTGRES_PASSWD"
LOCAL_KEYCLOAK_POSTGRES_ROOTPASSWD="$KEYCLOAK_POSTGRES_ROOTPASSWD"

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create secret generic keycloak-admin-password \
  --from-literal=admin-password="${LOCAL_KEYCLOAK_PASSWD}" \
  --namespace="keycloak"
# secret/keycloak-admin-password created

kubectl create namespace keycloak

(
cat <<EOF

production: true
proxy: edge

auth:
  adminUser: "${LOCAL_KEYCLOAK_ADMIN}"
  existingSecret: keycloak-admin-password
  passwordSecretKey: ${LOCAL_KEYCLOAK_PASSWD}

ingress:
  enabled: true
  hostname: "d0-keycloak.acmeorg.io"
  path: /
  tls: true

postgresql:
  enabled: true
  auth:
    postgresPassword: "${LOCAL_KEYCLOAK_POSTGRES_PASSWD}"
    username: bn_keycloak
    password: "${LOCAL_KEYCLOAK_POSTGRES_ROOTPASSWD}"
    database: bitnami_keycloak
    existingSecret: "keycloak-admin-password"
    secretKeys:
      userPasswordKey: password
  architecture: standalone

# postgresql:
#   enabled: true
#   auth:
#     existingSecret: keycloak-db-credentials
#     password: postgres-password
#   primary:
#     persistence:
#       enabled: true
#       # storageClass: openebs-hostpath
#       # existingClaim: keycloak-postgresql

extraEnvVars:
    - name: KC_PROXY_HEADERS
      value: "xforwarded"
EOF
) | helm upgrade --install \
        keycloak bitnami/keycloak \
        --version=24.7.1 -n=keycloak \
        --create-namespace \
        -f - && \
        kubectl create secret generic keycloak-admin-password \
          --from-literal=admin-password="${KEYCLOAK_PASSWD}" \
          --namespace="keycloak" && \
          kubectl create secret generic keycloak-db-credentials \
              --from-literal=postgres-password="${LOCAL_KEYCLOAK_POSTGRES_PASSWD}" \
              --namespace=keycloak
        #-f ./kck-ingress.yaml

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: keycloak
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - KEYCLOAK_HOST
    secretName: keycloak-ui-tls
  rules:
  - host: KEYCLOAK_HOST
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
) | sed "s/KEYCLOAK_HOST/d0-keycloak.acmeorg.io/" | kubectl apply -f -


}
