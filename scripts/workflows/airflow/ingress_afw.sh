#!/bin/sh

# Configure Ingress
set_afw_ingress() {

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: airflow-ui-ingress
  namespace: airflow
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-airflow.acmeorg.io
    secretName: airflow-ui-tls
  rules:
  - host: d0-airflow.acmeorg.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: airflow-api-server
            port:
              number: 8080
EOF
) | kubectl apply -f -

# kubectl delete -f -


}
