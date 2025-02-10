#!/bin/sh

# add repo
rudo -E helm repo add apache-airflow https://airflow.apache.org
sudo -E helm repo update

helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --create-namespace \
  --reuse-values \
  --set dags.persistence.enabled=true \
  --set dags.persistence.existingClaim=dags-volume \
  --set dags.gitSync.enabled=true

# --set dags.gitSync.enabled=false

