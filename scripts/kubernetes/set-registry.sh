#!/bin/sh

REGISTRY_NAME="registry-test"

twuni() {

kubectl create namespace $REGISTRY_NAME

helm repo add twuni https://helm.twun.io

helm upgrade --install twuni-registry twuni/docker-registry \
     --namespace="$REGISTRY_NAME" \
     --create-namespace \
     -f - && echo "done"
 }



certs_setup() {
# comes before starting the registry

REGISTRY_USERNAME="registryuser"
REGISTRY_PASSWD="registryuserpassword"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/registry/auth
sudo mkdir -p /opt/registry/certs
sudo mkdir -p /opt/registry/data

# auth-1: generate access file with the credentials
sudo htpasswd -bBc /opt/registry/auth/htpasswd "$REGISTRY_USERNAME" "$REGISTRY_PASSWD"

# auth-2: create tls keypair (self-signed)
sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /opt/registry/certs/domain.key -x509 -days 365 -out /opt/registry/certs/domain.crt

}



deploy_registry() {


# only needed when using hostpath
# so you make the deployment start
# on the same node which have those files
# being mounted as volumes of type hostpath.
kubectl get nodes -o wide
kubectl label node acmeorg-cluster-0 registry-node=true

# deployment manifest
# references the cert_setup function

# crtdom="$(cat /opt/registry/certs/domain.crt)"
# keydom="$(cat /opt/registry/certs/domain.key)"


# sudo kubectl -n=laquila-service create secret generic registry-certs \
#   --from-file=domain.crt=/opt/registry/certs/domain.crt \
#   --from-file=domain.key=/opt/registry/certs/domain.key

# sudo kubectl -n=laquila-service create secret generic registry-auth \
#   --from-file=htpasswd=/opt/registry/auth/htpasswd




(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: registry-certs
  namespace: laquila-service
type: Opaque
data:
  domain.crt: $(sudo cat /opt/registry/certs/domain.crt | base64 -w 0)
  domain.key: $(sudo cat /opt/registry/certs/domain.key | base64 -w 0)
---
apiVersion: v1
kind: Secret
metadata:
  name: registry-auth
  namespace: laquila-service
type: Opaque
data:
  htpasswd: $(sudo cat /opt/registry/auth/htpasswd | base64 -w 0)
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-same-namespace
  namespace: laquila-service
spec:
  podSelector: {}  # applies to all pods in this namespace (e.g., the registry pod)
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: laquila-service
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: registry-ingress
  namespace: laquila-service
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-registry.acmeorg.io
    secretName: registry-certs
  rules:
    - host: d0-registry.acmeorg.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: registry
                port:
                  number: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: laquila-service
  labels:
    app: registry
spec:
  replicas: 1
  selector:
    matchLabels:
        app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:3
          ports:
            - containerPort: 5000
          env:
            - name: REGISTRY_AUTH
              value: "htpasswd"
            - name: REGISTRY_AUTH_HTPASSWD_REALM
              value: "Registry Realm"
            - name: REGISTRY_AUTH_HTPASSWD_PATH
              value: "/auth/htpasswd"
            - name: REGISTRY_HTTP_TLS_CERTIFICATE
              value: "/certs/domain.crt"
            - name: REGISTRY_HTTP_TLS_KEY
              value: "/certs/domain.key"
            - name: REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED
              value: "true"
          volumeMounts:
            - name: certs-volume
              mountPath: /certs
              readOnly: true
            - name: auth-volume
              mountPath: /auth
              readOnly: true
            - name: registry-storage
              mountPath: /var/lib/registry
      volumes:
        - name: registry-storage
          emptyDir: {}
        - name: certs-volume
          secret:
            secretName: registry-certs
        - name: auth-volume
          secret:
            secretName: registry-auth
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: laquila-service
spec:
  selector:
    app: registry
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
EOF
) | kubectl apply -f -

#    kubectl apply -f -

#kubectl delete -f -

#apply -f -


}


