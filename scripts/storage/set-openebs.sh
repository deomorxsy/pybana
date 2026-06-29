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

(
cat <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-hostpath-node2
provisioner: openebs.io/local
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: false
allowedTopologies:
  - matchLabelExpressions:
      - key: kubernetes.io/hostname
        values:
          # - $NSC_VALUE
          - "acmeorg-cluster-2"

EOF
) | kubectl apply -f -



# Install openebs chart
helm upgrade --install openebs \
    openebs/openebs \
    --namespace openebs \
    --create-namespace \
    --set engines.replicated.mayastor.enabled=false

# enable mayastor if configuring NFS through that
