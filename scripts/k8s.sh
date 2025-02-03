#!/bin/sh

ROOTFS_PATH="/"

# k8s const
KUBECONFIG="$ROOTFS_PATH"/etc/rancher/k3s/k3s.yaml
ARGOCONFIG="./deploy/argo.yaml"
HELMCONFIG="./scripts/helm.sh"
KREWCONFIG="$KJX"/sources/bin/krew-linux_amd64
ARGOCLI="$ROOTFS_PATH"/usr/bin/argocd


MNT_DIR="${{ secrets.MNT_DIR }}"
K3S_VERSION="v1.32.1+k3s1"
# nodefs
#
KUBELET_DIR="${MNT_DIR}/kubelet":-/var/lib/kubelet
sudo mkdir -pv "${KUBELET_DIR}"


# if
if ! [ -f "/usr/local/bin/k3s" ]; then
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="--kubelet-arg "root-dir=$KUBELET_DIR"" sh -
#sudo chmod 644 /etc/rancher/k3s/k3s.yaml
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

#
# Solving problems with x509 cert auth in local environments
# for userspace apps that read the configfile (kubecolor, helm3)
# sudo k3s kubectl config view --raw | tee "$HOME/.kube/config"

# setup helm3
if ! [ -f "$HELMCONFIG" ]; then
curl -fsSL -o "$HELMCONFIG" https://raw.githubusercontent.com/helm/helm/f31d4fb3aacabf6102b3ec9214b3433a3dbf1812/scripts/get-helm-3
chmod 700 "$HELMCONFIG"
$HELMCONFIG
fi



# setup the krew plugin manager for kubectl apps
# and other remote tooling i.e. kubectl-trace #
#
if ! [ -f "$KREWCONFIG" ]; then
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  mkdir -p "$KJX"/sources/bin/krew && cd "$KJX"/sources/bin/krew || return &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  cp "${KREW}" "$KREWCONFIG" &&
  cd - || return
)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi


# ===========
# setup argocd
# ===========
if ! [ -f "$ARGOCONFIG" ]; then
curl -fsSL -o "$ARGOCONFIG"  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# creaate namespace and apply config
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

IPCONFIG=""
IPV4_ADDR="localhost"

if ip -V | grep -q iproute2; then

    IPCONFIG="iproute2"
    IPV4_ADDR=$(ip a | grep 192 | awk '{print $2}' | cut -d '/' -f1)
else
    IPCONFIG="net-tools"
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
