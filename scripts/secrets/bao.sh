#!/bin/sh


installer() {
helm upgrade --install openbao openbao  \
    --repo https://openbao.github.io/openbao-helm \
    --namespace openbao --create-namespace

# then, init the operator
BAO_CMD1=$(
bao operator init && \
bao secrets enable -path=kvv2 kv-v2 && \
bao kv put kvv2/node0 node0_name='hmm' password='two'
)

# write the policy
BAO_CMD2=$(bao policy write myHR-ro - <<EOF
path "kvv2/data/myHR" {
capabilities = ["read"]
}
EOF
)

# exec the commands inside the pod
# passing the init and policy creation commands
kubectl exec -n openbao \
    -it "$(
    kubectl get pod -n openbao \
        -l app.kubernetes.io/name=openbao \
        -o jsonpath='{.items[0].metadata.name}' \
        )" \
        -- bash -c "$BAO_CMD1 && $BAO_CMD2"

}


# VSO (vaults secrets operator) setup
## create serviceAccount, secrets and clusterRoleBinding
vso_setup() {
cat <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: openbao-auth
  namespace: stg
---
apiVersion: v1
kind: Secret
metadata:
  name: openbao-auth
  namespace: stg
  annotations:
    kubernetes.io/service-account.name: openbao-auth
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: openbao-auth
    namespace: stg

EOF
}


add_secrets() {


kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=supersecure -n openbao
kubectl get secrets -n openbao
kubectl describe secret my-secret -n openbao

(
cat <<EOF
secrets:
  my-secret:
    type: "generic"
    source: "kubernetes"
EOF
) | tee ./deploy/k8s/bao/values.yaml


helm upgrade openbao openbao/openbao -n openbao -f values.yaml

kubectl exec -it \
    -n=openbao \
    openbao-0 -- \
    bao policy write mypolicy - \
<<EOF
path "secrets/*" {
  capabilities = ["list", "read"]
}
EOF

}

# in case of backup
migrate() {
    kubectl exec -n=openbao -it deploy/openbao -- \
        openbao kv list --recursive | while read -r key; do
            value=$(kubectl exec -n=openbao -it deploy/openbao -- \
                openbao kv get "$key" --plaintext)
            echo "{\"key\": \"$key\", \"value\": \"$value\"}"
        done > ./artifacts/openbao-secrets.json
}
