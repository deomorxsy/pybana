#!/bin/sh

qdrant_data_team() {

helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update

helm install my-qdrant qdrant/qdrant --version 1.14.0

helm upgrade --install qdrant qdrant/qdrant \
    --version 1.14.0 \
    --namespace=qdrant \
    --create-namespace

# The full Qdrant documentation is available at https://qdrant.tech/documentation/.
#
# To forward Qdrant's ports execute one of the following commands:
#   export POD_NAME=$(kubectl get pods --namespace qdrant -l "app.kubernetes.io/name=qdrant,app.kubernetes.io/instance=qdrant" -o jsonpath="{.items[0].metadata.name}")
#
# If you want to use Qdrant via http execute the following commands
#   kubectl --namespace qdrant port-forward $POD_NAME 6333:6333
#
# If you want to use Qdrant via grpc execute the following commands
#   kubectl --namespace qdrant port-forward $POD_NAME 6334:6334
#
# If you want to use Qdrant via p2p execute the following commands
#   kubectl --namespace qdrant port-forward $POD_NAME 6335:6335


helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update

#helm install ai-qdrant qdrant/qdrant --version 1.14.0


DQ_PASSWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)


helm upgrade --install data-qdrant qdrant/qdrant \
    --version 1.14.0 \
    --namespace=data-qdrant \
    --create-namespace \
    --set service.api_key="$DQ_PASSWD"


DQDRANT_AUTH_USERNAME="ad12321_mDriv4"
DQDRANT_AUTH_PASSWD="danda@_dsnaidn21q23d_"

AUTHFILE_PATH="/opt/registry/auth/aiqdrant_htpasswd"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/registry/auth
sudo mkdir -p /opt/registry/certs
sudo mkdir -p /opt/registry/data

# Auth: generate access file with the credentials
sudo htpasswd -bBc "$AUTHFILE_PATH" "$AIQDRANT_AUTH_USERNAME" "$AIQDRANT_AUTH_PASSWD"

# Delete auth secret if exists and create a new with an auth key
kubectl delete secret data-qdrant-ui-auth -n=data-qdrant
kubectl -n=data-qdrant create secret generic data-qdrant-ui-auth --from-file=auth="$AUTHFILE_PATH"


# Ingress setup
(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: data-qdrant-ui-ingress
  namespace: data-qdrant
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: data-qdrant-ui-auth
    nginx.ingress.kubernetes.io/auth-realm: "Protected Area"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - "d0-data-qdrant.acmeorg.io"
      secretName: "data-qdrant-ui-tls"
  rules:
    - host: "d0-data-qdrant.acmeorg.io"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: data-qdrant
                port:
                  number: 6333

EOF
) | kubectl apply -f -



}

qdrant_ui_ai_team() {

helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update

#helm install ai-qdrant qdrant/qdrant --version 1.14.0


AIQ_PASSWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)


helm upgrade --install ai-qdrant qdrant/qdrant \
    --version 1.14.0 \
    --namespace=ai-qdrant \
    --create-namespace \
    --set service.api_key="$AIQ_PASSWD"


#kubectl create secret generic ai-qdrant-ui-auth --from-literal=auth=testadm1n:idk12983y1872 -n ai-qdrant


AIQDRANT_AUTH_USERNAME="hmmasasb1"
AIQDRANT_AUTH_PASSWD="fdiahb32ubru2"

AUTHFILE_PATH="/opt/registry/auth/aiqdrant_htpasswd"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/registry/auth
sudo mkdir -p /opt/registry/certs
sudo mkdir -p /opt/registry/data

# auth-1: generate access file with the credentials
sudo htpasswd -bBc "$AUTHFILE_PATH" "$AIQDRANT_AUTH_USERNAME" "$AIQDRANT_AUTH_PASSWD"

kubectl delete secret ai-qdrant-ui-auth -n=ai-qdrant
kubectl -n ai-qdrant create secret generic ai-qdrant-ui-auth --from-file=auth="$AUTHFILE_PATH"


# Ingress setup
(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ai-qdrant-ui-ingress
  namespace: ai-qdrant
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: ai-qdrant-ui-auth
    nginx.ingress.kubernetes.io/auth-realm: "Protected Area"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - "d0-ai-qdrant.acmeorg.io"
      secretName: "ai-qdrant-ui-tls"
  rules:
    - host: "d0-ai-qdrant.acmeorg.io"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ai-qdrant
                port:
                  number: 6333

EOF
) | kubectl apply -f -

}

certs_setup() {
# comes before starting the registry

AIQDRANT_AUTH_USERNAME="${REP_AIQDRANT_AUTH_USERNAME}"
AIQDRANT_AUTH_PASSWD="${REP_AIQDRANT_AUTH_PASSWD}"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/registry/auth
sudo mkdir -p /opt/registry/certs
sudo mkdir -p /opt/registry/data

# auth-1: generate access file with the credentials
sudo htpasswd -bBc /opt/registry/auth/aiqdrant_htpasswd "${AIQDRANT_AUTH_USERNAME}" "${AIQDRANT_AUTH_PASSWD}"


(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ai-qdrant-ui-auth
  namespace: ai-qdrant
type: Opaque
data:
  htpasswd: $(base64 -w 0 < /opt/registry/auth/aiqdrant_htpasswd)
EOF
) | kubectl apply -f -

}


