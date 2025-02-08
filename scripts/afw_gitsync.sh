#!/bin/sh

# set values for Apache Airflow with gitsync
# so you can synchronize DAG deploys based on
# custom repository hook triggers
afw_gs(){

VAL="./deploy/airflow/values.yaml"
SECRET_NAME="airflow-ssh-git-agent"
SSH_PK_PATH="./artifacts/.ssh/afw_gitsync"

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

# upgrade the airflow chart now passing the values yaml
helm upgrade --install airflow apache-airflow/airflow -n airflow -f "$VAL" --debug

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
    afw_gs
    printf "Setting Airflow with gitSync..."
else
    printf "\nInvalid function name. Please specify one of the following:\n"
    print_usage
fi
