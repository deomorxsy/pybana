#!/bin/sh

set_basic_auth() {


mkdir -p "$HOME/sso" && cd "$HOME/sso/" || return

if ! command -v httpasswd; then
    sudo apt install apache2-utils
elif command -v httpasswd; then

    # create auth file
    htpasswd -c auth foo

    # generate secret in the ingress-nginx namespace
    kubectl create secret generic basic-n8n-auth --from-file=auth -n=n8n

    # examine secret
    kubectl get secret basic-n8n-auth -n=n8n

    #sudo
else
    printf "\n|> unknown error!\n"
fi

# ingress manifest
(
cat <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-with-auth
  namespace: n8n
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-n8n-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - foo'
    acme.cert-manager.io/http01-edit-in-place: "true"
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
              number: 3010
EOF
) | kubectl apply -f -

# | tee ./artifacts/n8n-basic-auth.sh

}



fixingress() {




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
              # number: 3010
              number: 5678
EOF
) | kubectl apply -f -


}

n8n_installer() {




helm install n8n oci://localhost:5000/library/n8n/n8n --version 1.0.4 \
            --namespace=n8n \
            --create-namespace

helm upgrade --install n8n oci://localhost:5000/library/n8n/n8n --version 1.0.4 \
            --namespace=n8n \
            --create-namespace
}


new_setup_n8n() {

helm install n8n oci://8gears.container-registry.com/library/n8n \
    --version 1.0.6 \
    --namespace=n8n \
    --create-namespace


}

setup_n8n() {

# create artifacts directory and enter
mkdir -p ./artifacts/n8n/
cd ./artifacts/n8n || return

# fetch the oci tarball
helm pull oci://8gears.container-registry.com/library/n8n --version 1.0.4

# start OCI local private registry
docker run -d -p 5000:5000 --name registry registry:latest

# push the tarball to the local private registry
helm push ./n8n-1.0.4.tgz  oci://localhost:5000/library/n8n && \
    rm ./n8n-1.0.4.tgz && \
    printf "\n|> deleting OCI tarball...\n"

# list current files being served
curl -s -i -X GET http://registry.localhost:5000/v2/_catalog

# pull the local tarball to test the registry
helm pull oci://localhost:5000/library/n8n/n8n --version 1.0.4 && \
    ls -allhtr ./n8n-1.0.4.tgz && \
    printf "\n|> listing OCI tarball...\n"



N8N_PODS=$(kubectl get pods -n=n8n | grep n8n | awk '{print $1}' )
IS_REGISTRY_RUNNING=$(podman images | grep registry 2>&1>/dev/null)

# set container runtime
if command -v podman; then
    CONRUN="podman"
elif command -v docker; then
    CONRUN=docker
fi

# make sure the registry is running
if "$IS_REGISTRY_RUNNING"; then

    printf "\n|> found a local private registry running. Checking if n8n is intalled...\n"
    # if n8n is not installed yet, setup a standalone
    # n8n pod from local oci private registry on k8s
    #
    # there are already resources in the namespace
    if [ "$N8N_PODS" = "n8n*" ]; then
        printf "\n|> found resources in the namespace. Exiting now..."

    # there is no namespace with this name. Create if true
    elif [ "$N8N_PODS" = "No resources*" ]; then
        printf "\n|> namespace not found. Creating now..."
        # run the n8n installer function
        n8n_installer
    else
        printf "\n|> unknown error. Exiting now..."

    fi
else
    # if it was not running, start the OCI local private registry
    printf "\n|> Registry was not found. Starting it now...\n"
    "$CONRUN" run -d -p 5000:5000 --name registry registry:latest && \
            printf "\n|> Registry started.\n"


fi
# create namespace if it doesn't exist and install chart
# helm upgrade --install n8n n8n/n8n \
#     oci://8gears.container-registry.com/library/n8n \
#     --reuse-values \
#     --namespace=n8n \
#     --create-namespace


cd - || return
}

n8n_ingress() {

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ui-ingress
  namespace: n8n
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - "\${{ secrets.N8N_HOST_0 }}"
      secretName: n8n-core-tls
  rules:
    - host: "\${{ secrets.N8N_HOST_0 }}"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: n8n-service
                port:
                  number: 8080

EOF
) | kubectl apply -f -


}

n8n_apply() {

# version: latest - n8n@1.82.3
# setup n8n deployment
#


(
cat <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n-deployment
  namespace: n8n
  labels: &labels
    app: n8n
    component: deployment
spec:
  replicas: 1
  selector:
    matchLabels: *labels
  template:
    metadata:
      labels: *labels
    spec:
      containers:
      - name: n8n
        image: 8gears.container-registry.com/library/n8n
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 5678
        envFrom:
        - configMapRef:
            name: n8n-configmap
        - secretRef:
            name: n8n-secrets
        livenessProbe:
          httpGet:
            path: /healthz
            port: 5678
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5678
        resources:
          limits:
            cpu: "1.0"
            memory: "1024Mi"
          requests:
            cpu: "0.5"
            memory: "512Mi"

EOF

) | kubectl apply -f -

# tee ./deploy/k8s/n8n/deployment.yaml


(
cat <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: n8n-service
  namespace: n8n
  labels:
    app: n8n
    component: service
spec:
  type: ClusterIP
  selector:
    app: n8n
    component: deployment
  ports:
  - protocol: TCP
    name: http
    port: 80
    targetPort: 5678

EOF
) | kubectl apply -f -


#    tee ./deploy/k8s/n8n/service.yaml

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
        n8n_ingress && \
            n8n_apply && \
            setup_database
    fi

elif [ "$1" = "--version" ] || [ "$1" = "-v" ] || [ "$1" = "version" ]; then
    printf "\n|> semver: v1.0.0"

else
    printf "\n|> Invalid function name. Please specify one of the following:\n"
    print_usage
fi
