#!/bin/sh

# set values for Apache Airflow with gitsync
# so you can synchronize DAG deploys based on
# custom repository hook triggers
afw_gs(){

GITHUB_PAT=$1
# URI delimiter
PAT_DELIMITER=":$GITHUB_PAT"

if [ "$(pwd)" = "$HOME" ] && [ -d ./cluster/infra-gitops ]; then
cd ./cluster/infra-gitops || return
VAL="./deploy/airflow/values.yaml"
SECRET_NAME="airflow-ssh-git-agent"
SSH_PK_PATH="./artifacts/.ssh/afw_gitsync"

elif [ "$(pwd)" = "$HOME" ] && ! [ -d ./cluster/infra-gitops ]; then
    git clone "https://$GITHUB_USER$PAT_DELIMITER@github.com/$COMPANY/infra-gitops.git"
fi
# generate ssh keypair
mkdir -p ./artifacts/.ssh/
ssh-keygen -t ed25519 \
    -C "airflow gitsync deploy" \
    -f "$SSH_PK_PATH" \
    -N ''

# create airflow values.yaml if it does not exist
if [ -f "$VAL" ] && ! grep "gitSync" < "$VAL"; then

(
cat <<EOF
gitSync:
enabled: true
repo: ssh://git@github.com/deomorxsy/pybana.git
branch: main
rev: HEAD
depth: 1
# the number of consecutive failures allowed before aborting
maxFailures: 0
subPath: "./dags/"
sshKeySecret: airflow-ssh-git-secret
EOF
) | tee "./deploy/airflow/values.yaml"

fi

# create the k8s secret in the airflow namespace
kubectl create secret \
    generic "$SECRET_NAME" \
    --from-file=gitSshKey="$SSH_PK_PATH" \
    -n airflow


# check if the secret was created
kubectl get secrets -n airflow | grep "$SECRET_NAME"

# put public key on the repo's github deploy keys

# eval to the environment
export "$(openbao kv get "${NSC_VALUE}" | sed '/^#/d' | xargs)"

# parse ${ENV} -> $ENV
sed 's/\${\([^}]*\)}/$\1/g' test.yaml > processed_test.yaml

# apply the processed
envsubst < processed_test.yaml > final_test.yaml

helm upgrade --install \
    airflow apache-airflow/airflow \
    -n airflow \
    -f "$VAL" --debug \
    --create-namespace


helm upgrade --install \
    airflow apache-airflow/airflow \
    -n airflow \
    -f "$VAL" --debug \
    --create-namespace


# get an user
kubectl exec -n=airflow \
    airflow-worker-0 -- \
    airflow users create \
    --username 4dm1nafw \
    --password "MYSecure_@passwd21321421" \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email admin@example.org


# add spark dependencies
#
# enter directory due to COPY build context
cd ./deploy/airflow || return
podman build -t airflow-custom:1.0.0 -f ./Dockerfile


cd - || return


#cat test.yaml \
#    | envsubst  "$(export "$(grep -v '^#' $(openbao kv get "${NSC_VALUE}") | xargs))" \
#    | "$(helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug)"

# upgrade the airflow chart now passing the values yaml
helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug


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

# list containers inside a pod
# kubectl get pods POD_NAME_HERE -o jsonpath='{.spec.containers[*].name}'

# execute command into worker pod ( worker | worker-log-groomer )
# Defaulted container "worker" out of: worker, worker-log-groomer, wait-for-airflow-migrations (init)
kubectl exec -n=airflow \
    airflow-worker-0 worker -- \
    bash -c 'ls -l'



#kubectl exec --stdin --tty airflow-worker-0 worker -- /bin/bash -n=airflow

# get a shell into a specific container under the pod
kubectl exec -n=airflow --stdin --tty airflow-worker-0 worker -- /bin/bash

# execute a command into a specific container under the pod
kubectl exec -n=airflow airflow-worker-0 -c worker-log-groomer -- bash -c 'ls -l'

kubectl get pods airflow-worker-0 \
    -o jsonpath='{.spec.containers[*].name}' \
    -n=airflow && \
    echo && echo


}

print_usage() {
cat <<-END >&2
USAGE: . ./scripts/afw_gitsync.sh [-options]
                - set
eg,
setvpn -set   # set values for Apache Airflow with gitsync so you can synchronize DAG deploys based on custom repository hook triggers

END

}

if [ "$1" = "set" ] || [ "$1" = "--set" ] || [ "$1" = "-set" ] ; then
    afw_gs "$1" "$2"
    printf "Setting Airflow with gitSync..."
else
    printf "\nInvalid function name. Please specify one of the following:\n"
    print_usage
fi
