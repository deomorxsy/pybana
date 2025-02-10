#!/bin/sh

# local, lightweight single-node k8s cluster
## minimal control plane distro
mcpd() {
MNT_DIR="/mnt/ssd/dataStore/k3s-local/local-path-provisioner/storage"
K3S_VERSION="v1.32.1+k3s1"

#KUBELET_DIR="${MNT_DIR}/kubelet":-/var/lib/kubelet
KUBELET_DIR="${MNT_DIR}/kubelet"
sudo mkdir -pv "${KUBELET_DIR}"

# imagefs: containerd has a root and state directory
#
# - https://github.com/containerd/containerd/blob/main/docs/ops.md#base-configuration
#
# containerd root -> /var/lib/rancher/k3s/agent/containerd
#
# create a soft link (symbolic link)
CONTAINERD_ROOT_DIR_OLD="/var/lib/rancher/k3s/agent"
CONTAINERD_ROOT_DIR_NEW="${MNT_DIR}/containerd-root/containerd"
sudo mkdir -p "${CONTAINERD_ROOT_DIR_OLD}"
sudo mkdir -p "${CONTAINERD_ROOT_DIR_NEW}"
sudo ln -s "${CONTAINERD_ROOT_DIR_NEW}" "${CONTAINERD_ROOT_DIR_OLD}"

# containerd state -> /run/k3s/containerd
#
CONTAINERD_STATE_DIR_OLD="/run/k3s"
CONTAINERD_STATE_DIR_NEW="${MNT_DIR}/containerd-state/containerd"
sudo mkdir -p "${CONTAINERD_STATE_DIR_OLD}"
sudo mkdir -p "${CONTAINERD_STATE_DIR_NEW}"
sudo ln -s "${CONTAINERD_STATE_DIR_NEW}" "${CONTAINERD_STATE_DIR_OLD}"

# pvs -> /var/lib/rancher/k3s/storage
#
PV_DIR_OLD="/var/lib/rancher/k3s"
PV_DIR_NEW="${MNT_DIR}/local-path-provisioner/storage"
sudo mkdir -p "${PV_DIR_OLD}"
sudo mkdir -p "${PV_DIR_NEW}"
sudo ln -s "${PV_DIR_NEW}" "${PV_DIR_OLD}"


# if
if ! [ -f "/usr/local/bin/k3s" ]; then
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="--kubelet-arg "root-dir=$KUBELET_DIR"" sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Solving problems with x509 cert auth in local environments
# for userspace apps that read the configfile (kubecolor, helm3)
# ''' sudo k3s kubectl config view --raw | tee "$HOME/.kube/config" ''',
# which dump config as root and redirect to file as normal user.
sudo k3s kubectl config view --raw > "$HOME/.kube/config"
cp /etc/rancher/k3s/k3s.yaml ~/.kube/k3s.yaml

fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
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
docker pull registry:latest
docker start registry
docker compose -f ./compose.yml --progress-plain build mock_acs && \
docker push localhost:5000/airflow-custom-spark:1.0.0 -f ./deploy/airflow/Dockerfile

#docker build -t airflow-custom-spark:1.0.0 -f ./deploy/airflow/Dockerfile

CREATE_OCI=$(docker create --name mock_acs localhost:5000/airflow-custom-spark:1.0.0 2>&1 | grep "already in use";)

# the commands below replace kind's load.
if $CREATE_OCI; then
    podman generate kube mock_acs > ./artifacts/mock_acs.yaml
    #kubectl create namespace afw_test
    kubectl apply -f ./artifacts/mock_acs.yaml -n=afw_test

# instead of relying on installing and using "kind load"
# or "podman generate kube", run alpine on a pod and
# inside of it, use podman
(
cat <<EOF
apiVersion v1
kind: Pod
name: alpine-podman
    namespace: default
spec:
    containers:
    - name: alpine-podman
      image:
      command:
      - sh
      - c
      - "apk add --no-cache podman && tail -f /dev/null"
      - "
      "docker pull registry:latest
docker start registry
docker compose -f ./compose.yml --progress-plain build mock_acs && \
docker push localhost:5000/airflow-custom-spark:1.0.0 -f ./deploy/airflow/Dockerfile


EOF
) | tee ./deploy/podman-alpine.yaml

sudo crictl create ./deploy/podman-alpine.yaml


else
    printf "\n|> Error: Could not create a writable container layer over the specified image (airflow-custom-spark:1.0.0)\n\n"
fi


## add charts

# 0. gitsync for airflow
. ./scripts/afw_gitsync.sh

# 1. bitnami sealed secrets
# helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# 2. ARC (Actions Runner Controller)
. ./scripts/arc-set.sh

# 3. Airflow Controller
. ./scripts/airflowpvc.sh

# 4. ilum
. ./scripts/ilum.sh

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
curl -fsSL -o "$ARGOCONFIG"  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# create namespace and apply config
sudo "$ROOTFS_PATH/bin/k3s" kubectl create namespace argocd
sudo "$ROOTFS_PATH/bin/k3s" kubectl apply -n argocd -f "$ARGOCONFIG"
#or
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#

# argocd CLI
if ! [ -f "$ARGOCLI" ]; then
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v2.7.3/argocd-linux-amd64
cp ./argocd-linux-amd64 "$ROOTFS_PATH/usr/bin/argocd"
chmod 555 "$ROOTFS_PATH/usr/bin/argocd"
#sudo install -m 555 ./argocd-linux-amd64 /usr/bin/argocd
rm ./argocd-linux-amd64
fi

# cluster ip of argocd below
# sudo k3s kubectl get svc -n argocd | grep argocd-server | awk 'NR==1 {print $3}'

# port-forward the argocd webserver
sudo $ROOTFS_PATH/bin/k3s kubectl port-forward svc/argocd-server -n argocd 8080:443

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
