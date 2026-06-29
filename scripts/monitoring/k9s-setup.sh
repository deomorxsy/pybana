#!/bin/sh

KUBECONFIG="$HOME/.kube/config"


runk9s() {
if [ -f "$KUBECONFIG" ]; then
        sudo -E k9s --kubeconfig "$KUBECONFIG"
else
        printf "|> %s not found. Creating now." "$KUBECONFIG"

        #sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo kubectl config view --raw "$HOME/.kube/config"
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

fi
}


if [ "$1" = "k9s" ]; then
        runk9s
else
        printf "\nInvalid function name. Please specify one of the following: ...k9s\n"
fi



