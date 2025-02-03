#!/bin/sh

helm upgrade airflow apache-airflow/airflow \
  --namespace airflow \
  --reuse-values \
  --set dags.persistence.enabled=true \
  --set dags.persistence.existingClaim=dags-volume \
  --set dags.gitSync.enabled=false

