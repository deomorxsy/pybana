#!/bin/sh


## add charts

parse_secrets() {
# parse ${ENV} -> $ENV
sed 's/\${\([^}]*\)}/$\1/g' ./deploy/airflow/values.yaml > ./artifacts/processed_test.yaml

# apply the processed
envsubst < ./artifacts/processed_test.yaml > ./artifacts/final_test.yaml

#helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug
helm upgrade --install airflow apache-airflow/airflow -n airflow -f ./artifacts/final_test.yaml --debug

#cat test.yaml \
#    | envsubst  "$(export "$(grep -v '^#' $(openbao kv get "${NSC_VALUE}") | xargs))" \
#    | "$(helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug)"

# upgrade the airflow chart now passing the values yaml
helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug
}



airflow() {
# 0. gitsync for airflow
. ./scripts/afw_gitsync.sh
}

secrets(){

# bitnami sealed secrets
# helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# openbao
# add chart and update helm repo database
helm repo add openbao https://openbao.github.io/openbao-helm
helm repo update

# check for repo
helm search repo openbao/openbao

 BAO_VERSION="0.8.1"
# create namespace if it doesn't exist and install chart in HA
 helm upgrade --install openbao openbao/openbao \
     --version="$BAO_VERSION" \
     --set "server.ha.enabled=true" \
     --namespace openbao \
     --create-namespace \
#     --dry-run


# get pods
kubectl get pods -l app.kubernetes.io/name=openbao -n=openbao
kubectl get pods -n=openbao


# Initialize one OpenBao server with the default number of
# key shares and default key threshold:
kubectl exec -ti openbao-0 -- bao operator init

## Unseal the first openbao server until it reaches the key threshold
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 1
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 2
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 3

# Repeat the unseal process for all OpenBao server pods.
# When all OpenBao server pods are unsealed they report READY 1/1.
kubectl get pods -l app.kubernetes.io/name=openbao


# create config.hcl with variables. These will be configmap


kubectl create secret generic openbao-storage-config \
    --from-file=config.hcl

# mount secret as extra volume,
helm install openbao openbao/openbao \
  --set='server.volumes[0].name=userconfig-openbao-storage-config' \
  --set='server.volumes[0].secret.defaultMode=420' \
  --set='server.volumes[0].secret.secretName=openbao-storage-config' \
  --set='server.volumeMounts[0].mountPath=/openbao/userconfig/openbao-storage-config' \
  --set='server.volumeMounts[0].name=userconfig-openbao-storage-config' \
  --set='server.volumeMounts[0].readOnly=true' \
  --set='server.extraArgs=-config=/openbao/userconfig/openbao-storage-config/config.hcl'


# eval to the environment
#export "$(openbao kv get "${{ secrets.NSC_VALUE }}" | sed '/^#/d' | xargs)"
export "$(openbao kv get "${{ secrets.NSC_VALUE }}")"

}

## 4. ilum
ilum(){

# 4. ilum
. ./scripts/ilum.sh

kubectl get pods ilum-postgresql-0 \
    -n=ilum \
    -o jsonpath='{.status.containerStatuses[].containerID}' \
    | sed 's/docker:\/\///' && \
    echo && echo
#kubectl get pod ilum-postgresql-0 -o jsonpath={.status.containerStatuses[].containerID} | sed 's/docker:\/\///'

}

# 2. ARC (Actions Runner Controller)

arc_selhosted() {
. ./scripts/arc-set.sh
}

airflow_setup() {
# 3. Airflow Controller
. ./scripts/airflowpvc.sh

helm rollback airflow 1 -n airflow
helm ls -n airflow



}


kubectl_plugins(){
echo
}

