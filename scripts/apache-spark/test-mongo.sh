#!/bin/sh

AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"

helm install ilum-core ilum/ilum-core --dependency-update \
    --namespace=mongo-connector \
    --create-namespace \
    --set linage.enabled=true \
    --set mongo.instances="https://bitnami.com/stack/mongodb/helm" \
    --set mongodb.enabled=true \
    --set mongodb.replicaSet.enabled=false \
    --set minio.enabled=true \
    --set airflow.enabled=true \
    --set airflow.fernetKey="$AFW_FERNET" \
    --set ilum-jupyter.enabled=true \
    --set ilum-livy-proxy.enabled=true \
    --set gitea.enabled=true \
    --set postgresql.enabled=true \
    --set kube-prometheus-stack.enabled=true \
    --set ilum-n8n.enabled=true #\
    #--debug --wait


helm install mongo bitnami/mongodb \
    --namespace=mongo-connector \
    --create-namespace \
    --set replicaSet.enabled=true \
    --set replicaSet.name=rs0 \
    --set replicaSet.useHostnames=true \
    --set mongodbDatabase=ilum-default \
    --set auth.enabled=false


helm install mongo bitnami/mongodb --version 16.4.11  \
    --namespace=mongo-connector \
    --create-namespace \
    --set architecture=standalone \
    --set persistence.enabled=false \
    --set auth.rootPassword="sample4837614" \
    --set auth.username="ilumongo_acmeorg01" \
    --set auth.password="samplePasswd" \
    --set auth.database="ilum-default"

