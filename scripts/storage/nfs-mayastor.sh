#!/bin/sh
#
# depends-on: ./scripts/storage/set-openebs.sh

# add the CSI driver for NFS
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

# Install csi-driver-nfs
helm upgrade --install csi-driver-nfs \
    csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --version 4.11.0 \
    --set controller.replicas=2 \
    --set controller.runOnControlPlane=true \
    --set externalSnapshotter.enabled=false \
    --atomic


# Check CSI deployment
# kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/instance=csi-driver-nfs" --watch


# Create namespace for the openebs nfs-server
kubectl create namespace nfs-mayastor

# Create PVC for the NFS Mayastor
(
cat <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-server-claim
  namespace: nfs-mayastor
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: openebs-single-replica
EOF
) | kubectl apply -f -


# Deploy the rest of the resources
(
cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
  namespace: nfs-mayastor
spec:
  replicas: 1
  selector:
    matchLabels:
      role: nfs-server
  template:
    metadata:
      labels:
        role: nfs-server
    spec:
      volumes:
      - name: nfs-vol
        persistentVolumeClaim:
          claimName: nfs-server-claim
      restartPolicy: Always
      containers:
      - name: nfs-server
        image: itsthenetwork/nfs-server-alpine
        env:
        - name: SHARED_DIRECTORY
          value: /nfsshare
        ports:
          - name: nfs
            containerPort: 2049
        securityContext:
          privileged: true
          capabilities:
            add:
              - SYS_ADMIN
        livenessProbe:
          tcpSocket:
            port: 2049
          initialDelaySeconds: 10
          periodSeconds: 20
        readinessProbe:
          tcpSocket:
            port: 2049
          initialDelaySeconds: 5
          periodSeconds: 10
        volumeMounts:
          - mountPath: /nfsshare
            name: nfs-vol
EOF
) | kubectl apply -f -




# Create service for the NFS Server
(
cat <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nfs-service
  namespace: nfs-mayastor
spec:
  type: ClusterIP
  # clusterIP: "None"
  selector:
    role: nfs-server
  ports:
    - name: nfs
      port: 2049
      targetPort: 2049
      protocol: TCP

EOF
) | kubectl apply -f -



# For airflow

# PV
#
(
cat <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-server-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: "nfs-service.nfs-mayastor.svc.cluster.local"
    path: /export/dags/
  storageClassName: openebs-rwx

EOF
) | kubectl apply -f -

# PVC
(
cat <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dags-pvc
  namespace: airflow
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: openebs-rwx
  resources:
    requests:
      storage: 1Gi

EOF
) | kubectl apply -f -






