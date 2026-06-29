
(
cat <<EOF
---
apiVersion: v1
kind: Namespace
# Namespace specs need only a name.
metadata:
  name: kuard
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
  namespace: kuard
spec:
  selector:
    matchLabels:
      app: kuard
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - image: gcr.io/kuar-demo/kuard-amd64:1
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: kuard
  namespace: kuard
spec:
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: kuard
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kuard
  namespace: kuard
  annotations: {}
    nginx.ingress.kubernetes.io/rewrite-target: /
    # cert-manager.io/cluster-issuer: letsencrypt-prod
    # acme.cert-manager.io/http01-edit-in-place: "true"
    cert-manager.io/issuer: "letsencrypt-staging"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-kuard.acmeorg.io
    secretName: kuard-example-tls
  rules:
  - host: d0-kuard.acmeorg.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kuard
            port:
              number: 80
---
EOF
) | kubectl apply -f -
