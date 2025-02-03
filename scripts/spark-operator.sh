#!/bin/sh

if ! pgrep k3s; then
    systemctl start k3s.service
fi

sudo -E helm repo add spark-operator https://kubeflow.github.io/spark-operator
sudo -E helm repo update

sudo -E helm install spark-operator spark-operator/spark-operator \
    --namespace spark-operator \
    --create-namespace
