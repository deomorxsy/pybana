#!/bin/sh

set_registry() {

(

cat <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  # local private registry
  namespace: lpr
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: registry-storage
              mountPath: /var/lib/registry
      volumes:
        - name: registry-storage
          emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: registry
  # local private registry
  namespace: lpr
spec:
  selector:
    app: registry
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
  type: ClusterIP

EOF

) | kubectl apply -f -

REGISTRY_POD=$(kubectl get pods -n=lpr | grep registry | awk '{print $1}')


}
