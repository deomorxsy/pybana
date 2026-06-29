#!/bin/sh

# Add chart and update base
helm repo add openebs https://openebs.github.io/openebs
helm repo update

# k describe serviceaccount openebs-pre-upgrade-hook -n=openebs
#
# kubectl get job,cronjob,deployments,statefulsets -n openebs -o yaml | grep -B5 -A5 'serviceAccountName: openebs-pre-upgrade-hook'
#
kubectl delete serviceaccount openebs-pre-upgrade-hook -n openebs
kubectl delete clusterRole openebs-pre-upgrade-hook


# Install openebs chart
helm upgrade --install openebs \
    openebs/openebs \
    --namespace openebs \
    --create-namespace \
    --set engines.replicated.mayastor.enabled=false

