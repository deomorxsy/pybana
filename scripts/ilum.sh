#!/bin/sh

# add chart and update helm repo database
sudo -E helm repo add ilum https://charts.ilum.cloud
sudo -E helm repo update

# check local k8s distro
if ! pgrep k3s; then
    systemctl start k3s.service
fi

# create namespace if it doesn't exist and install chart
sudo -E helm install ilum ilum/ilum \
    --namespace ilum \
    --create-namespace




