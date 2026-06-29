#!/bin/sh


auth_registry() {

GET_SECRETS=$(kubectl get secrets regcred -n=airflow 2>&1 | grep regcred | awk '{print $1}')
SEC_SED="/home/debian/cluster/pybana/scripts/secrets/rep-secrets.sed"

REG_CRED_PATH="/home/debian/cluster/pybana/artifacts"

REG_USERNAME="$HARBOR_REG_USERNAME"
REG_PASSWD="$HARBOR_REG_PASSWD"
REG_MAIL="$HARBOR_REG_MAIL"

kubectl create secret docker-registry regcred \
  --docker-server=d0-registry.acmeorg.io \
  --docker-username="$REG_USERNAME" \
  --docker-password="$REG_PASSWD" \
  --docker-email="$REG_MAIL"  \
  --namespace=airflow

}

build_push_registry() {

(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: registry-auth
  namespace: airflow
type: Opaque
data:
  htpasswd: $(sudo cat /opt/registry/auth/harbor_htpasswd | base64 -w 0)
EOF
) | kubectl apply -f -


if [ "$PWD" = "/home/debian" ]; then
    mkdir -p ./cluster/pybana
    cd ./cluster/pybana || return

    . ./scripts/workflows/airflow/build_custom.sh
fi

}

# set values for Apache Airflow with gitsync
# so you can synchronize DAG deploys based on
# custom repository hook triggers
set_airflow_gitsync(){

SEC_SED="/home/debian/cluster/pybana/scripts/secrets/rep-secrets.sed"
AFW_WEBSERVER_SK="$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
GITSYNC_SECRET_NAME="airflow-ssh-git-secret"

# generate ssh keypair
SSH_PK_PATH="/home/debian/cluster/artifacts/.ssh/afw_gitsync"

# AFW_IMAGE_TO_PULL="d0-registry.acmeorg.io/airflow-custom/airflow-custom_spark-qdrant"
AFW_IMAGE_TO_PULL="d0-registry.acmeorg.io/airflow-custom/airflow-custom_spark-qdrant@sha256:af225ac7c2fa9a19ba403c67d8d7ed7c3e2ac91336599abce0c4e29aaf281297"
COMPANY_REPOSITORY="git@github.com:acmeorg/pybana.git"
AFW_LOCAL_WEBSERVER_ADM="\${{ secrets.AFW_WEBSERVER_ADM }}"
AFW_LOCAL_WEBSERVER_PASSWD="\${{ secrets.AFW_WEBSERVER_PASSWD }}"



AFW_LOCAL_WEBSERVER_ADM="$AFW_WEBSERVER_ADM"
AFW_LOCAL_WEBSERVER_PASSWD="$AFW_WEBSERVER_PASSWD"



# Add helm chart repository
sudo -E helm repo add apache-airflow https://airflow.apache.org
sudo -E helm repo update


if ! [ -f "$SSH_PK_PATH" ]; then
mkdir -p ./cluster/artifacts/.ssh/
ssh-keygen -t ed25519 \
    -C "airflow gitsync deploy" \
    -f "$SSH_PK_PATH" \
    -N ''
else
    echo "|> A previous SSH keypair exists at the path. Either review or delete to continue."
fi


# Create airflow namespace
kubectl create namespace airflow

# Create the k8s secret in the airflow namespace
if ! kubectl create secret \
    generic "$GITSYNC_SECRET_NAME" \
    --from-file=gitSshKey="$SSH_PK_PATH" \
    -n airflow; then

printf "\n\n|> Could not create airflow secret! Exiting now...\n"
fi

# Create PVC
(
cat <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dags-volume
  namespace: airflow
  labels:
    app.kubernetes.io/managed-by: "Helm"
  annotations:
    meta.helm.sh/release-name: "airflow"
    meta.helm.sh/release-namespace: "airflow"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: openebs-hostpath-node2
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: airflow-logs
  namespace: airflow
  labels:
    app.kubernetes.io/managed-by: "Helm"
  annotations:
    meta.helm.sh/release-name: "airflow"
    meta.helm.sh/release-namespace: "airflow"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: openebs-hostpath-node2
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-dynamic
provisioner: openebs.io/local
volumeBindingMode: Immediate
reclaimPolicy: Delete
EOF
) | kubectl apply -f -



(
cat <<EOF

repo: \${{ secrets.AFW_SSH_REPO_URI }}
EOF
) | sed -f "$SEC_SED"

# Create airflow values.yaml if it does not exist
#if [ -f "$AIRFLOW_VALUES" ] && ! grep "gitSync" < "$AIRFLOW_VALUES"; then


# Create storageclass
(
cat <<EOF
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-dynamic
provisioner: openebs.io/local
volumeBindingMode: Immediate
reclaimPolicy: Delete
EOF
) | kubectl apply -f -



# Deploy it with helm
(
cat <<EOF

webserverSecretKey: "${AFW_WEBSERVER_SK}"

images:
  gitSync:
    repository: registry.k8s.io/git-sync/git-sync
    tag: v4.3.0
    pullPolicy: IfNotPresent

dags:
  persistence:
    enabled: true
    existingClaim: dags-volume
  gitSync:
    enabled: true
    repo: "${COMPANY_REPOSITORY}"
    branch: main
    rev: HEAD
    depth: 1
    # the number of consecutive failures allowed before aborting
    maxFailures: 0
    subPath: "./dags/"
    sshKeySecret: airflow-ssh-git-secret
    knownHosts: |
        github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=

webserver:
  defaultUser:
    enabled: true
    username: "${AFW_LOCAL_WEBSERVER_ADM}"
    email: airflowadmin@example.com
    firstName: Air
    lastName: Flow
    password: "${AFW_LOCAL_WEBSERVER_PASSWD}"

logs:
  persistence:
    annotations: {}
    enabled: true
    existingClaim: airflow-logs
    size: 6Gi
    storageClassName: openebs-hostpath-node2

postgresql:
  persistence:
    storageClassName: openebs-dynamic
redis:
  persistence:
    storageClassName: openebs-dynamic


EOF
) | sed -f "$SEC_SED" > ./artifacts/airflow-gitsync.sh && \
    envsubst < ./artifacts/airflow-gitsync.sh > ./artifacts/UAG_sync.sh && \
    helm upgrade --install airflow apache-airflow/airflow \
     --version 1.18.0 \
     --dependency-update \
     --namespace=airflow \
     --create-namespace \
     --atomic \
     -f ./artifacts/UAG_sync.sh
     #--debug \

}

# Prepare NFS storage RWX for other DAG private repositories
dag_pvc() {

(
cat <<EOF
# pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: airflow-dags-nfs-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: nfs-service.nfs-mayastor.svc.cluster.local
    path: /nfsshare
  persistentVolumeReclaimPolicy: Retain
---
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: airflow-dags-rwx
  namespace: airflow
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  volumeName: airflow-dags-nfs-pv
EOF
) | kubectl apply -f -

}

debug_users() {

AFW_WEBSERVER_ADM="\${{ secrets.AFW_WEBSERVER_ADM }}"
AFW_WEBSERVER_PASSWD="\${{ secrets.AFW_WEBSERVER_PASSWD }}"



helm upgrade --install \
    airflow apache-airflow/airflow \
    -n airflow \
    -f "$VAL" --debug \
    --create-namespace

# get an user
kubectl exec -n=airflow \
    airflow-worker-0 -- \
    airflow users create \
    --username "$AFW_BASE_ADM:\${{ secrets.AFW_BASE_ADM }}" \
    --password "$AFW_BASE_ADM_PASSWD:\${{ secrets.AFW_BASE_ADM_PASSWD }}" \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email admin@example.org



}




utils() {

# list containers inside a pod
# kubectl get pods POD_NAME_HERE -o jsonpath='{.spec.containers[*].name}'

# execute command into worker pod ( worker | worker-log-groomer )
# Defaulted container "worker" out of: worker, worker-log-groomer, wait-for-airflow-migrations (init)
kubectl exec -n=airflow \
    airflow-worker-0 worker -- \
    bash -c 'ls -l'

#kubectl exec --stdin --tty airflow-worker-0 worker -- /bin/bash -n=airflow

# get a shell into a specific container under the pod
kubectl exec -n=airflow --stdin --tty airflow-worker-0 worker -- /bin/bash

# execute a command into a specific container under the pod
kubectl exec -n=airflow airflow-worker-0 -c worker-log-groomer -- bash -c 'ls -l'

kubectl get pods airflow-worker-0 \
    -o jsonpath='{.spec.containers[*].name}' \
    -n=airflow && \
    echo && echo

}


print_usage() {
cat <<-END >&2
USAGE: . ./scripts/afw_gitsync.sh [-options]
                - set
eg,
setvpn -set   # set values for Apache Airflow with gitsync so you can synchronize DAG deploys based on custom repository hook triggers

END

}




if [ "$1" = "set" ] || [ "$1" = "--set" ] || [ "$1" = "-set" ] ; then
    afw_gs "$1" "$2"
    printf "Setting Airflow with gitSync..."
else
    printf "\nInvalid function name. Please specify one of the following:\n"
    print_usage
fi
