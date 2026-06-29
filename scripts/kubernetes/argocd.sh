#!/bin/sh


fix_argo() {

# Delete previous ClusterRoles
if ! kubectl delete ClusterRole argocd-server argocd-applicationset-controller argocd-application-controller; then
    echo "One or more ClusterRole resources for argocd were not found."
fi
echo "Successfully deleted argocd ClusterRoles"

# Delete previous CustomResourceDefinitions
if ! kubectl delete crd appprojects.argoproj.io applicationsets.argoproj.io applications.argoproj.io; then
    echo "One or more CustomResourceDefinition resources for argocd were not found."
fi
echo "Sucessfully deleted argocd CustomResourceDefinitions"

if ! kubectl delete ClusterRoleBinding argocd-application-controller argocd-applicationset-controller argocd-server; then
    echo "One or more ClusterRoleBinding resources for argocd were not found."
fi
echo "Successfully deleted argocd ClusterRoleBindings."

# add ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update


kubectl create namespace argocd

# ArgoCD
ARGO_USERNAME="argoadmin"
ARGO_PASSWD="$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 10)"
OPENSSL_HOSTNAME="d0-argo.acmeorg.io"
ARGO_ADMPASSWD="${REP_ARGO_ADMPASSWD}"

ARGO_LOCAL_USERNAME="${ARGO_USERNAME}"
ARGO_LOCAL_PASSWD="${ARGO_PASSWD}"
ARGO_LOCAL_ADMPASSWD="${ARGO_ADMPASSWD}"

# auth-1: generate access file with the credentials
sudo htpasswd -bBc /opt/registry/auth/argo_htpasswd "$ARGO_LOCAL_USERNAME" "$ARGO_LOCAL_PASSWD"
# auth-2: create tls keypair (self-signed)
sudo openssl req \
    -newkey rsa:4096 \
    -nodes -sha256 \
    -keyout /opt/registry/certs/argo_domain.key \
    -x509 -days 365 \
    -out /opt/registry/certs/argo_domain.crt \
    -subj "/CN=${OPENSSL_HOSTNAME}"


kubectl create namespace argo || true

# create secret
# remember: secret != certificate
(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argo-tls
  namespace: argocd
type: Opaque
data:
  domain.crt: $(sudo cat /opt/registry/certs/argo_domain.crt | base64 -w 0)
  domain.key: $(sudo cat /opt/registry/certs/argo_domain.key | base64 -w 0)
---
apiVersion: v1
kind: Secret
metadata:
  name: argo-auth
  namespace: argocd
type: Opaque
data:
  htpasswd: $(sudo cat /opt/registry/auth/argo_htpasswd | base64 -w 0)
EOF
) | kubectl apply -f -


helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 8.1.3 \
  --set server.service.type=ClusterIP \
  --set configs.secret.argocdServerAdminPassword="${ARGO_LOCAL_ADMPASSWD}"

#
# ====
#


}

setup_argo() {

# ===========
# setup argocd
# ===========
if ! [ -f "$ARGOCONFIG" ]; then
#curl -fsSL -o "$ARGOCONFIG"  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
wget -P ./deploy/ https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# create namespace and apply config
kubectl create namespace argocd
kubectl apply -n argocd -f "$ARGOCONFIG"
#or
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#

# argocd CLI
if ! [ -f "$ARGOCLI" ]; then
cd ./artifacts || return
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v2.7.3/argocd-linux-amd64
sudo cp ./argocd-linux-amd64 "$ROOTFS_PATH/usr/bin/argocd"
sudo chmod 555 "$ROOTFS_PATH/usr/bin/argocd"
#sudo install -m 555 ./argocd-linux-amd64 /usr/bin/argocd
rm ./argocd-linux-amd64
cd - || return


fi

# cluster ip of argocd below
# sudo k3s kubectl get svc -n argocd | grep argocd-server | awk 'NR==1 {print $3}'

# port-forward the argocd webserver
kubectl port-forward svc/argocd-server -n argocd 8080:443
#kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

#IPCONFIG=""
IPV4_ADDR="localhost"

if ip -V | grep -q iproute2; then

    #IPCONFIG="iproute2"
    IPV4_ADDR=$(ip a | grep 192 | awk '{print $2}' | cut -d '/' -f1)
else
    #IPCONFIG="net-tools"
    if command -v ifconfig; then
        ifconfig | grep 192 | awk '{print $2}' | cut -d '/' -f1
    else
        apt-get update && \
        apt-get install net-tools
        IPV4_ADDR=$(ifconfig | grep 192 | awk '{print $2}' | cut -d '/' -f1)
    fi

fi

# set argocd server URI URL, username and password using github as secret store provider
gh repo secret set ARGOCD_SERVER < "$IPV4_ADDR:8080"
gh repo secret set ARGOCD_USERNAME < "admin"
gh repo secret set ARGOCD_PASSWD < "$("$ROOTFS_PATH"/bin/k3s kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)"

# developing/testing use case only, hence the insecure flag below
argocd login "$ARGOCD_SERVER" --username="$ARGOCD_USERNAME" --password="$ARGOCD_PASSWD" --insecure

# check argocd login
argo_agui=$(argocd account get-user-info \
    --server="$(sudo k3s kubectl get svc -n argocd | \
        grep argocd-server | awk 'NR==1 {print $3}')" | awk '{print $3}')

# if account get-user-info isn't set, #TODO
if echo "$argo_agui" | grep -q "false"; then
    # add cluster to argocd if authenticated
    argocd cluster add "$(sudo k3s kubectl config current-context)" | grep -q "rpc error" && \
    if sed -e '/server: /{ s/s/# s/; n; a\' \
        -e 'bash -c "sudo k3s kubectl get -n default endpoints | awk '\''NR==2 {print $2}'\''"/; }' ~/.kube/config; then \
        # send SIGINT to current bash script in execution if not authenticated
        kill -s="9" --pid="$$" #checkout $BASHPID
    fi
fi


}
