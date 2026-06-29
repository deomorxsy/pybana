#!/bin/sh

qdrant_data_team() {

helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update

helm install my-qdrant qdrant/qdrant --version 1.13.6

helm upgrade --install qdrant qdrant/qdrant \
    --version 1.13.6 \
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


}

qdrant_ui_ai_team() {

helm repo add qdrant https://qdrant.github.io/qdrant-helm
helm repo update

helm install ai-qdrant qdrant/qdrant --version 1.13.6

helm upgrade --install ai-qdrant qdrant/qdrant \
    --version 1.13.6 \
    --namespace=ai-qdrant \
    --create-namespace


(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: qdrant-ui-ingress
  namespace: qdrant
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - "d0-qdrant.acmeorg.io"
      secretName: qdrant-ui-tls
  rules:
    - host: "d0-qdrant.acmeorg.io"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: qdrant-ui
                port:
                  number: 8080

EOF
) | kubectl apply -f -

}
