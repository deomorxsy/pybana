#!/bin/sh

backup_homolog() {

    TODAY=$(date +%F)
    TARBALL_NAME="couchdb-backup-$TODAY.tar.gz"
    # TARBALL_NAME=./artifacts/couchdb-backup-2025-06-26.tar.gz

    # PVC_UUID=$(kubectl get pv -o wide | grep couchdb | awk '{ print $1 }')
    NODE_DEST="$(kubectl get pod budibase-couchdb-0 -n budibase -o wide | awk 'NR==2{print $7}')"

    PVC_UUID=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="database-storage-budibase-couchdb-0")].metadata.name}')


    # Create tarball on homolog
    ssh -t homolog "sudo tar -czf './${TARBALL_NAME}' -C /var/lib/docker/volumes/budibase_couchdb3_data _data"

    # Copy tarball from homolog to dev environment
    scp homolog:/home/ubuntu/"$TARBALL_NAME" ./artifacts/

    # Copy tarball to acmeorg02
    scp ./artifacts/"$TARBALL_NAME" acmeorg02:/home/debian/

    # Decompress tarball into the PVC UUID directory at the openebs storage directory tree
ssh -t acmeorg02 bash <<EOF

set -e

TEMP_DIR=\$HOME/couchdb_restore_temp
mkdir -p \$TEMP_DIR
tar -xzf /home/debian/${TARBALL_NAME} -C \$TEMP_DIR

mkdir -p $HOME/anoda && \
    sudo tar -xzf ./${TARBALL_NAME} -C $HOME/anoda && \
    cp -r $HOME/anoda/_data /var/openebs/local/${PVC_UUID}"
EOF
        ssh -t acmeorg00 "kubectl delete pod -n=budibase $(kubectl get pods -n=budibase | grep couchdb | awk '{print $1}')"



}


base_install() {

helm repo add budibase https://budibase.github.io/budibase/
helm repo update
helm install --create-namespace --namespace budibase budibase budibase/budibase

# BDB_URL="http://mycouch.io:1234"
# BDB_USER="acmeorg_couch_user_1746"
# BDB_PASSWD="3ty12grf738@945g152"
# BDB_HOSTNAME="d0-budibase.acmeorg.io"

BDB_URL="\${{ secrets.DB_URL }}"
BDB_USER="\${{ secrets.BDB_USER }}"
BDB_PASSWD="\${{ secrets.BDB_PASSWD }}"
BDB_HOSTNAME="\${{ secrets.BDB_HOSTNAME }}"

kubectl delete statefulset budibase-couchdb -n budibase

kubectl delete pvc redis-data -n budibase
kubectl delete pvc minio-data -n budibase
kubectl delete pvc -n budibase --all

kubectl delete deployment minio-service -n budibase
kubectl delete deployment redis -n budibase

(
cat <<EOF
couchdb:
  persistentVolume:
    enabled: true
    storageClass: "openebs-hostpath-node2"
    url: "$BDB_URL"
    user: "$BDB_USER"
    password: "$BDB_PASSWD"
services:
  objectStore:
    storageClass: "openebs-hostpath-node2"
  redis:
    storageClass: "openebs-hostpath-node2"

EOF
) | helm upgrade -n=budibase budibase budibase/budibase \
    --set ingress.enabled=enabled \
    -f - && echo "done"
}

ingress() {

BDB_INGRESS_AUTH_USERNAME="uabds@_232dr1va"
BDB_INGRESS_AUTH_PASSWD="dhqw47g18dbq@_n31bn12v417@_"

BDB_INGRESS_AUTHFILE_PATH="/opt/budibase/auth/bdb_base_htpasswd"

# directories to be mounted on the namespace pod
sudo mkdir -p /opt/budibase/auth
sudo mkdir -p /opt/budibase/certs
sudo mkdir -p /opt/budibase/data

# Auth: generate access file with the credentials
sudo htpasswd -bBc "$BDB_INGRESS_AUTHFILE_PATH" "$BDB_INGRESS_AUTH_USERNAME" "$BDB_INGRESS_AUTH_PASSWD"

# Delete auth secret if exists and create a new with an auth key
kubectl delete secret bdb-ui-auth -n=budibase
kubectl -n=budibase create secret generic bdb-ui-auth --from-file=auth="$BDB_INGRESS_AUTHFILE_PATH"


(
cat <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: budibase-ingress
  namespace: budibase
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: bdb-ui-auth
    nginx.ingress.kubernetes.io/auth-realm: "Protected Area"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $BDB_HOSTNAME
    secretName: budibase-tls
  rules:
  - host: $BDB_HOSTNAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: proxy-service
            port:
              number: 10000
EOF
) | kubectl apply -f -

}


