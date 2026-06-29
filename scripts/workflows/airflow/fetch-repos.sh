dev_fetch_repos() {

SSH_PK_PATH="./artifacts/.ssh/repos"
mkdir -p $SSH_PK_PATH
mkdir -p "./artifacts/forks"

(
cat <<EOF
bi-service="git@github.com:acmeorg/bi-service.git"
conversation-history-repository="git@github.com:acmeorg/conversation-history-repository.git"
EOF
) | tee ./artifacts/simple-repos.txt

# export RBW_SESSION=$(rbw unlock --raw)
while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | tr -d '"' | xargs)
    echo "$key: $value"

    cd ./artifacts/forks/ || return
    git clone "$value"

    cd ./artifacts/forks/ || return
    tar -czf "./${key}.tar.gz" "./${key}"
    ssh acmeorg00 -n "mkdir -p /home/debian/dag-forks/"

    scp "./${key}.tar.gz" acmeorg00:"/home/debian/dag-forks/" && \
        ssh acmeorg00 -t "
            cd /home/debian/dag-forks/ || return
            if ! tar -xvf ./${key}.tar.gz; then
                echo 'Could not  decompress ${key} tarball'
            fi
            echo '${key} tarball decompressed with success.'

            GS_PODS=$(kubectl get pods -n airflow -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{range .spec.containers[*]}{.name}{'\t'}{end}{'\n'}" | \
                grep git-sync | \
                awk '{ print $1 }')

            while IFS='\n' read -r pod; do
                kubectl cp ./bi-service.tar.gz ./conversation-history-repository.tar.gz $pod:/opt/airflow/dags/repo/dags/services/ -c=git-sync -n=airflow
                kubectl cp ./conversation-history-repository.tar.gz $pod:/opt/airflow/dags/repo/dags/services/ -c=git-sync -n=airflow
            done << EOF
            $GS_PODS
            EOF

        "
    cd - || return

done < "./artifacts/simple-repos.txt"

scp -r ./ acmeorg00:/home/debian/secrets-posix.sh && \
    ssh acmeorg00 -t "
        set -a && \
        source /home/debian/secrets-posix.sh && \
        set +a && \
        rm /home/debian/secrets-posix.sh
    "

}

fetch_repos() {

SSH_PK_PATH="./cluster/artifacts/.ssh/acmeorg-repos"
mkdir -p $SSH_PK_PATH

#AFW_REPO_LIST=""
(
cat <<EOF
bi-service="git@github.com:acmeorg/bi-service.git"
conversation-history-repository="git@github.com:acmeorg/conversation-history-repository.git"
EOF
) | tee ./cluster/artifacts/simple-repos.txt

# export RBW_SESSION=$(rbw unlock --raw)
while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | tr -d '"' | xargs)
    echo "$key: $value"

    KEY_PATH="$SSH_PK_PATH/$key"
    # Generate ssh keypair
    ssh-keygen -t ed25519 \
        -C "airflow gitsync deploy" \
        -f "$KEY_PATH" \
        -N ''
done < "./cluster/artifacts/simple-repos.txt" | \
    sed ':a;N;$!ba;s/\n/\\n/g'


PK_SUBDIRS="$(find "$SSH_PK_PATH"/*.pub)"

for item in $PK_SUBDIRS; do
    gh repo deploy-key add "$item"
done

}

