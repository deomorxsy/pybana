#!/bin/sh

set_harbor() {

#
helm repo add harbor https://helm.goharbor.io
# helm fetch harbor/harbor --untar

helm install harbor harbor/harbor --version 1.8.3 --namespace=harbor --create-namespace

HARBOR_REGISTRY_USERNAME="acmeorg_harbor"
HARBOR_REGISTRY_PASSWD="123h29db_1A9_db1vbDUIsb@_232n"

# auth-1: generate access file with the credentials
sudo htpasswd -bBc /opt/registry/auth/harbor_htpasswd "$HARBOR_REGISTRY_USERNAME" "$HARBOR_REGISTRY_PASSWD"
# auth-2: create tls keypair (self-signed)
sudo openssl req \
    -newkey rsa:4096 \
    -nodes -sha256 \
    -keyout /opt/registry/certs/harbor_registry_domain.key \
    -x509 -days 365 \
    -out /opt/registry/certs/harbor_registry_domain.crt \
    -subj "/CN=d0-registry.acmeorg.io"

kubectl create namespace harbor || true

# create secret
# remember: secret != certificate
(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: harbor-tls
  namespace: harbor
type: Opaque
data:
  domain.crt: $(sudo cat /opt/registry/certs/harbor_registry_domain.crt | base64 -w 0)
  domain.key: $(sudo cat /opt/registry/certs/harbor_registry_domain.key | base64 -w 0)
---
apiVersion: v1
kind: Secret
metadata:
  name: registry-auth
  namespace: harbor
type: Opaque
data:
  htpasswd: $(sudo cat /opt/registry/auth/harbor_htpasswd | base64 -w 0)
EOF
) | kubectl apply -f -


# ingress resource
(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: harbor-ingress
  namespace: harbor
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # nginx.ingress.kubernetes.io/rewrite-target: /$2
    # nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8"
    # kubectl.kubernetes.io/last-applied-configuration: '{...}'
spec:
  ingressClassName: nginx
  spec:
  rules:
  - host: d0-registry.acmeorg.io
    http:
      paths:
      - backend:
          service:
            name: harbor-portal
            port:
              number: 80
        path: /
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /api/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /service/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /v2
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /chartrepo/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /c/
        pathType: Prefix

  tls:
  - hosts:
    - d0-registry.acmeorg.io
    secretName: harbor-tls
  rules:
    - host: d0-registry.acmeorg.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: harbor-portal
                port:
                  number: 80
EOF
) | kubectl apply -f -

# kubectl apply -f -


# upgrade the helm chart
(
cat <<EOF
expose:
  type: ingress
  tls:
      enabled: true
      certSource: secret
      secret:
        secretName: "harbor-tls"
        notarySecretName: "harbor-tls"
  ingress:
    hosts:
      core: "d0-registry.acmeorg.io"
      # notary: "d0-registry.acmeorg.io"
    ingressClassName: nginx
    annotations:
      # kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
    tls:
      - hosts:
          - d0-registry.acmeorg.io
        secretName: harbor-tls
# tls:
#   enabled: true
#   secretName: harbor-tls
notary:
    enabled: false
externalURL: https://d0-registry.acmeorg.io
harborAdminPassword: "dhauh19u3b12"
EOF
) | helm upgrade --install harbor harbor/harbor \
     --version 1.8.3 \
     --namespace=harbor \
     --create-namespace \
     -f - && echo "done"


}

#

generate_certs() {
# run on host
#


CERTBOT_DIR="/etc/letsencrypt/live/harbor.example.com"

sudo apt update
sudo apt install certbot

sudo certbot certonly --standalone -d harbor.example.com

ls -allhtr "$CERTBOT_DIR"

mkdir -p ./artifacts/

cp "$CERTBOT_DIR"/fullchain.pem ./artifacts/tls.cert
cp "$CERTBOT_DIR"/privkey.pem ./artifacts/tls.key

kubectl create secret tls harbor-tls --cert=tls.crt --key=tls.key -n harbor

sudo certbot --nginx -d harbor.example.com

}

certmanager_issuer() {


(
cat <<EOF
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    # dummy e-mail
    email: d0-harbor@acmeorg.com.br
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
---
# harbor-cert.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: harbor-tls
  namespace: harbor
spec:
  secretName: harbor-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: d0-registry.acmeorg.io
  dnsNames:
  - d0-registry.acmeorg.io

EOF
) | kubectl apply -f-


}

fix_ingress() {

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: harbor-ingress
  namespace: harbor
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-registry.acmeorg.io
    secretName: harbor-tls
  rules:
  - host: d0-registry.acmeorg.io
    http:
      paths:
      - backend:
          service:
            name: harbor-portal
            port:
              number: 80
        path: /
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /api/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /service/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /v2
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /chartrepo/
        pathType: Prefix
      - backend:
          service:
            name: harbor-core
            port:
              number: 80
        path: /c/
        pathType: Prefix
EOF
) | kubectl apply -f -

# kubectl delete -f -

# kubectl apply -f -

}

registry_conn() {

}
