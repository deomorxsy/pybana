#!/bin/sh

ROOTFS_PATH="/"

# k8s const
#KUBECONFIG="$ROOTFS_PATH"/etc/rancher/k3s/k3s.yaml
ARGOCONFIG="./deploy/install.yaml"
HELMCONFIG="./scripts/helm.sh"
KREWCONFIG="./artifacts/sources/bin/krew-linux_amd64"
K9S_VERSION="v0.32.7"
ARGOCLI="$ROOTFS_PATH"/usr/bin/argocd

# remote, HA k8s cluster
# full control plane distro
fcpd(){


sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p "$HOME/.kube/"
sudo kubectl config view --raw "$HOME/.kube/config"
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# set kubeconfig
KUBECONFIG="$HOME/.kube/config"


# setup calico CNI
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml

# confirm that calico pods are running
watch kubectl get pods -n calico-system > "/tmp/running-pods.txt" 2>&1

# remove taint nodes
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-

#
kubectl get nodes -o wide

}



tooling() {
# setup helm3
#if ! [ -f "$HELMCONFIG" ]; then
#curl -fsSL -o "$HELMCONFIG" https://raw.githubusercontent.com/helm/helm/f31d4fb3aacabf6102b3ec9214b3433a3dbf1812/scripts/get-helm-3
#chmod 700 "$HELMCONFIG"
#$HELMCONFIG

if ! [ -f "/usr/bin/helm" ]; then
# fetch tarball, better version control
mkdir -p ./artifacts/ && cd ./artifacts || return
wget https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz
tar -zxvf ./helm-v3.17.0-linux-amd64.tar.gz
cd - || return
cp "./artifacts/linux-amd64/helm" /usr/bin/helm
fi

#

## add k9s as TUI
mkdir -p ./artifacts/k9s && cd ./artifacts/k9s || return

### fetch a k9s release
curl -fsSLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" && \
tar -zxvf "./k9s_Linux_amd64.tar.gz"

# place k9s into the $PATH
if [ -f "./k9s" ]; then
    sudo cp ./k9s /bin/
else
    printf "\n |> Error: could not locate the k9s binary. Exiting now...\n\n"
fi


## add spark provider to the airflow image
# docker start registry

#podman pull registry:latest
#podman create --name registry-container -p 5000:5000 registry:latest
podman run -d -p 5000:5000 --name registry registry:2.7

# docker compose -f ./compose.yml --progress-plain build mock_acs && \
# docker buildx build -t localhost:5000/gembag:03 -f ${{ github.workspace }}/Dockerfile .
# change directory due to context
cd ./deploy/airflow || return
podman build -t airflow-custom:1.0.0 -f ./Dockerfile


cd - || return

#podman build -t airflow-custom-spark:1.0.0 -f ./deploy/airflow/Dockerfile


podman login
podman images
podman push --tls-verify=false localhost:5000/airflow-custom-spark:1.0.0
curl -s -i -X GET http://registry.localhost:5000/v2/_catalog



CREATE_OCI=$(podman create --name mock_afw localhost:5000/airflow-custom-spark:1.0.0 2>&1 | grep "already in use";)

# the commands below replace kind's load.
if $CREATE_OCI; then
    podman generate kube mock_acs > ../artifacts/mock_afw.yaml
    #kubectl create namespace afw_test
    kubectl apply -f ./artifacts/mock_afw.yaml -n=afw_test

# instead of relying on installing and using "kind load"
# or "podman generate kube", run alpine on a pod and
# inside of it, use podman
#(
#cat <<EOF
#apiVersion v1
#kind: Pod
#name: alpine-podman
#    namespace: default
#spec:
#    containers:
#    - name: alpine-podman
#      image:
#      command:
#      - sh
#      - c
#      - "apk add --no-cache podman && tail -f /dev/null"
#      - "
#      "docker pull registry:latest
#docker start registry
#docker compose -f ./compose.yml --progress-plain build mock_acs && \
#docker push localhost:5000/airflow-custom-spark:1.0.0 -f ./deploy/airflow/Dockerfile
#
#
#EOF
#) | tee ./deploy/podman-alpine.yaml
#
#sudo crictl create ./deploy/podman-alpine.yaml


else
    printf "\n|> Error: Could not create a writable container layer over the specified image (airflow-custom-spark:1.0.0)\n\n"
fi


## add charts

# 0. gitsync for airflow
. ./scripts/afw_gitsync.sh

# 1. bitnami sealed secrets
# helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# 1. openbao
# add chart and update helm repo database
helm repo add openbao https://openbao.github.io/openbao-helm
helm repo update

# check for repo
helm search repo openbao/openbao

# BAO_VERSION="0.8.1"
# create namespace if it doesn't exist and install chart in HA
# helm install
# helm upgrade --install openbao openbao/openbao \
#     --version="$BAO_VERSION" \
#     --set "server.ha.enabled=true" \
#     --namespace openbao \
#     --create-namespace \
#     --dry-run

helm upgrade --install openbao openbao/openbao \
    --version="$BAO_VERSION" \
    --set "server.ha.enabled=true" \
    --namespace openbao \
    --create-namespace

kubectl get pods -l app.kubernetes.io/name=openbao -n=openbao
kubectl get pods -n=openbao


# Initialize one OpenBao server with the default number of
# key shares and default key threshold:
kubectl exec -ti openbao-0 -- bao operator init

## Unseal the first openbao server until it reaches the key threshold
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 1
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 2
kubectl exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 3

# Repeat the unseal process for all OpenBao server pods.
# When all OpenBao server pods are unsealed they report READY 1/1.
kubectl get pods -l app.kubernetes.io/name=openbao


(
cat <<EOF
cluster = "infra_gitops" {
AFW_HOST_0 = "d0-airflow.driva.io"
QDRANT_HOST_0 = "d0-qdrant.driva.io"
SECRET_NAME = "airflow-webserver-tls"
NSC_VALUE = "driva-cluster-2"
}
EOF
) | tee ./artifacts/config.hcl


kubectl create secret generic openbao-storage-config \
    --from-file=config.hcl

# mount secret as extra volume,

helm install openbao openbao/openbao \
  --set='server.volumes[0].name=userconfig-openbao-storage-config' \
  --set='server.volumes[0].secret.defaultMode=420' \
  --set='server.volumes[0].secret.secretName=openbao-storage-config' \
  --set='server.volumeMounts[0].mountPath=/openbao/userconfig/openbao-storage-config' \
  --set='server.volumeMounts[0].name=userconfig-openbao-storage-config' \
  --set='server.volumeMounts[0].readOnly=true' \
  --set='server.extraArgs=-config=/openbao/userconfig/openbao-storage-config/config.hcl'


# eval to the environment
#export "$(openbao kv get "${NSC_VALUE}" | sed '/^#/d' | xargs)"
export "$(openbao kv get "NSC_VALUE")"

# parse ${ENV} -> $ENV
sed 's/\${\([^}]*\)}/$\1/g' ./deploy/airflow/values.yaml > ./artifacts/processed_test.yaml

# apply the processed
envsubst < ./artifacts/processed_test.yaml > ./artifacts/final_test.yaml

#helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug
helm upgrade --install airflow apache-airflow/airflow -n airflow -f ./artifacts/final_test.yaml --debug

#cat test.yaml \
#    | envsubst  "$(export "$(grep -v '^#' $(openbao kv get "${NSC_VALUE}") | xargs))" \
#    | "$(helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug)"

# upgrade the airflow chart now passing the values yaml
helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug


# 2. ARC (Actions Runner Controller)
. ./scripts/arc-set.sh

# 3. Airflow Controller
. ./scripts/airflowpvc.sh

# 4. ilum
. ./scripts/ilum.sh

kubectl get pods ilum-postgresql-0 \
    -n=ilum \
    -o jsonpath={.status.containerStatuses[].containerID} \
    | sed 's/docker:\/\///' && \
    echo && echo
#kubectl get pod ilum-postgresql-0 -o jsonpath={.status.containerStatuses[].containerID} | sed 's/docker:\/\///'

# setup the krew plugin manager for kubectl apps
# and other remote tooling i.e. kubectl-trace #
#
if ! [ -f "$KREWCONFIG" ]; then
(
  set -x &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  mkdir -p "./artifacts/sources/bin/krew" && cd "./artifacts/sources/bin/krew" || return &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar -zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
  #cp "${KREW}" /bin/krew &&
  cd - || return
)

# export the PATH environment variable and also redirect it to ~/.profile in order to be read
# by some shellscripts such as bash, sh, dash.
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo export "$(PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH")" >> "$HOME/.profile"

fi


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
gh repo secret set ARGOCD_PASSWD < "$($ROOTFS_PATH/bin/k3s kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)"

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
    if sed -e '/server: /{ s/s/# s/; n; a\' -e 'bash -c "sudo k3s kubectl get -n default endpoints | awk '\''NR==2 {print $2}'\''"/; }' ~/.kube/config; then \
        # send SIGINT to current bash script in execution if not authenticated
        kill -s="9" --pid="$$" #checkout $BASHPID
    fi
fi
}

print_usage() {
cat <<-END >&2
USAGE: k8s-setup [-options]
                - fcpd
                - tooling
                - help
                - version
eg,
k8s-setup -fcpd   # install k8s with kubeadm, calico, a control plane and a worker
k8s-setup -tooling  # install tooling on the control plane
k8s-setup -help  # shows this help message
k8s-setup -version # shows script version

See the man page and example file for more info.

END

}


# Check the argument passed from the command line
if [ "$1" = "" ] || [ "$1" = "-h" ]; then
    print_usage
else
    printf "\nInvalid function name. Please specify one of the following:\n"
    print_usage
fi
