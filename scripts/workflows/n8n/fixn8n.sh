#!/bin/sh


initial_setup() {

# handle the chart and then ingress

(
cat <<-EOF
database:
    security:
        basicAuth:
        active: true    # If basic auth should be activated for editor and REST-API - default: false
        user: 'dr4dm1n'      # The name of the basic auth user - default: ''
        password: '374t1283@fvd3v3__243174g1'  # The password of the basic auth user - default: ''
        hash: true       # If password for basic auth is hashed - default: false
EOF
) | helm upgrade --install n8n oci://8gears.container-registry.com/library/n8n \
    --version 1.0.6 \
    --namespace=n8n \
    --create-namespace


# (
# cat <<EOF
# ---
# apiVersion: v1
# kind: Service
# metadata:
#   name: n8n-service
#   namespace: n8n
#   labels:
#     app: n8n
#     component: service
# spec:
#   type: ClusterIP
#   selector:
#     app: n8n
#     component: deployment
#   ports:
#   - protocol: TCP
#     name: http
#     port: 80
#     targetPort: 5678
#
# EOF
# ) | kubectl apply -f -



# now the ingress

(
cat <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ui-ingress
  namespace: n8n
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-n8n.acmeorg.io
    secretName: n8n-core-tls
  rules:
  - host: d0-n8n.acmeorg.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: n8n
            port:
              number: 80
EOF
) | kubectl apply -f -


# kubectl delete -f -

}




setup_database() {

#
#kubectl apply -f ./deploy/k8s/n8n/postgres*

(
cat <<EOF
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: postgres-secrets
  namespace: n8n
  labels:
    app: postgres
    component: secrets
stringData:
  PGDATA: "/var/lib/postgresql/data/pgdata"
  POSTGRES_USER: "n8n"
  POSTGRES_DB: "n8n"
  POSTGRES_PASSWORD: "n8n"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-statefulset
  namespace: n8n
  labels: &labels
    app: postgres
    component: statefulset
spec:
  serviceName: postgres-statefulset
  replicas: 1
  selector:
    matchLabels: *labels
  template:
    metadata:
      labels: *labels
    spec:
      containers:
      - name: postgres
        image: postgres:17.4
        ports:
        - name: postgres
          containerPort: 5432
        envFrom:
        - secretRef:
            name: postgres-secrets
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: n8n
  labels: &labels
    app: postgres
    component: service
spec:
  #clusterIP: None
  selector:
    app: postgres
    component: statefulset
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
EOF
) | kubectl apply -f -

}


setup_cfm_secrets(){

(
cat <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: n8n-configmap
  namespace: n8n
  labels:
    app: n8n
    component: configmap
data:
  NODE_ENV: "production"
  GENERIC_TIMEZONE: "America/Brazil"
  WEBHOOK_TUNNEL_URL: "https://d0-n8n.acmeorg.io"
  # Database configurations
  DB_TYPE: "postgresdb"
  DB_POSTGRESDB_USER: "n8n"
  DB_POSTGRESDB_DATABASE: "n8n"
  DB_POSTGRESDB_HOST: "postgres-service"
  DB_POSTGRESDB_PORT: "5432"
  # Turn on basic auth
  N8N_BASIC_AUTH_ACTIVE: "true"
  N8N_BASIC_AUTH_USER: "n8n"
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: n8n-secrets
  namespace: n8n
  labels:
    app: n8n
    component: secrets
stringData:
  # Database password
  DB_POSTGRESDB_PASSWORD: "n8n"
  # Basic auth credentials
  N8N_BASIC_AUTH_PASSWORD: "n8n"
  # Encryption key to hash all data
  N8N_ENCRYPTION_KEY: "n8n"
---


EOF
) | kubectl apply -f -

}



print_usage() {
cat <<-END >&2
USAGE: n8n [-options]
                - setup
                - help
                - version
eg,
n8n -setup   # sets up n8n on a k8s cluster, exposing
             #  the app over an nginx ingressClass
n8n -help    # shows this help message
n8n -version # shows script version

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$1" = "" ] || [ "$1" = "-h" ]; then
    print_usage

elif [ "$1" = "--setup" ] || [ "$1" = "-s" ] || [ "$1" = "setup" ]; then
    # flow: if running on Github Actions or ARC
    if [ "$GITHUB_ACTIONS" = "true" ]; then
        kubectl apply -f ./deploy/k8s/n8n/
    else
        initial_setup && \
            setup_database && \
            setup_cfm_secrets
    fi

elif [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
    printf "\n|> semver: v1.0.0"

else
    printf "\n|> Invalid function name. Please specify one of the following:\n"
    print_usage
fi
