#!/bin/sh
setup() {

# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm repo update

# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install k8s-dashboard \
    kubernetes-dashboard/kubernetes-dashboard \
    --create-namespace \
    --namespace k8s-dashboard

}

fix_ingress() {

# Basic auth
DASHBOARD_AUTH_USERNAME="${REP_DASHBOARD_AUTH_USERNAME}"
DASHBOARD_AUTH_PASSWD="${REP_DASHBOARD_AUTH_PASSWD}"

DASH_AUTHFILE_PATH="/opt/dashboard/auth/dashboard_base_htpasswd"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/dashboard/auth
sudo mkdir -p /opt/dashboard/certs
sudo mkdir -p /opt/dashboard/data

# Auth: generate access file with the credentials
sudo htpasswd -bBc "$DASH_AUTHFILE_PATH" "$DASHBOARD_AUTH_USERNAME" "$DASHBOARD_AUTH_PASSWD"

# Delete auth secret if exists and create a new with an auth key
kubectl delete secret dashboard-ui-auth -n=k8s-dashboard
kubectl -n=k8s-dashboard create secret generic dashboard-ui-auth --from-file=auth="$DASH_AUTHFILE_PATH"


(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: k8s-dashboard-web
  namespace: k8s-dashboard
  annotations:
    # nginx.ingress.kubernetes.io/auth-type: basic
    # nginx.ingress.kubernetes.io/auth-secret: dashboard-ui-auth
    # nginx.ingress.kubernetes.io/auth-realm: "Protected Area"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-dashboard.acmeorg.io

    secretName: k8s-dashboard-tls
  rules:
  - host: d0-dashboard.acmeorg.io
    http:
      paths:
      - path: /
        # pathType: Prefix
        pathType: ImplementationSpecific
        backend:
          service:
            name: k8s-dashboard-kong-proxy
            port:
              number: 443
EOF
) | kubectl apply -f -

}




create_user() {

(
cat <<EOF
# create ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: k8s-dashboard
---
# create clusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: k8s-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: k8s-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"
type: kubernetes.io/service-account-token
EOF
) | kubectl apply -f -

#

# after creating the serviceaccount, create token
kubectl -n k8s-dashboard create token admin-user

# kubectl -n k8s-dashboard create token admin-fellipe

# get token saved on the secret
kubectl get secret admin-user -n k8s-dashboard -o jsonpath="{.data.token}" | base64 -d

    }
