#!/bin/sh




setup_airflow() {

# Fetch secrets from environment
AFW_BASE_ADM_PASSWD="\${{secrets.AFW_BASE_ADM_PASSWD }}:afwbaseadm"
AFW_BASE_ADM_PASSWD="\${{secrets.AFW_BASE_ADM_PASSWD }}:afwbaseadmpasswd"

# Add helm chart repository
sudo -E helm repo add apache-airflow https://airflow.apache.org
sudo -E helm repo update


# helm install airflow apache-airflow/airflow --namespace airflow --debug

(
cat <<EOF
dags:
    persistence:
        enabled: "true"
        existingClaim: "dags-volume"
EOF
)

helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --create-namespace \
  --reuse-values \
  --set dags.persistence.enabled=true \
  --set dags.persistence.existingClaim=dags-volume \
  --set dags.gitSync.enabled=true

}

set_user() {
WEBAFW_POD="$(kubectl get pods -n=airflow | grep webserver | awk 'NR==1{print $1}')"

# airflow-worker-0
WORKERAFW_POD="$(kubectl get pods -n=airflow | grep worker | awk 'NR==1 {print $1}')"

kubectl exec -it "$WEBAFW_POD" -n=airflow -- airflow users list

AFW_UI_PASSWD=$(

echo "\${{ secrets.MY_SECRET_KEY }}" | sed 's/\${{ secrets.MY_SECRET_KEY }}/$MY_SECRET_KEY/g' -

)




OP_VAULT_TOKEN="\${{ secrets.OP_VAULT_TOKEN }}"


kubectl exec -it -n=openbao openbao-0 -- \
    wget \
        --header="X-Vault-Token: $OP_VAULT_TOKEN" \
        --header="Content-Type: application/json" \
        --post-data='{"data": {"password": "OpenBao123"}}' \
        http://127.0.0.1:8200/v1/secret/data/my-secret-password && \
    echo "Secret written successfully."



#bao kv list secrets


}

config_users() {

WORKERAFW_POD="$(kubectl get pods -n=airflow | grep worker | awk 'NR==1 {print $1}')"

# passwd=$(LC_ALL=C tr -dc 'A-Za-z0-9!@$&*_' < /dev/urandom | head -c 10)

# openbao save?

passwd=""
# Example: From 1 to 5
i=1
while [ "$i" -le 16 ]; do
  echo "Sequence $i"
  passwd="$passwd|$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 10)"
  i=$((i + 1))
done



# Create Airflow users
AFW_USERS_LIST="\${{ secrets.AFW_USERS_LIST }}"

echo "$AFW_USERS_LIST" | while IFS='|' read -r username fname lname role email; do

AFW_DYN_PASSWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 10)

kubectl exec -n=airflow "$WORKERAFW_POD" -c worker -- \
    airflow users create \
    --username "$username" \
    --password "$AFW_DYN_PASSWD" \
    --firstname "$fname" \
    --lastname "$lname" \
    --role "$role" \
    --email "$email"

#echo "${username}|${password}|${firstname}|${lastname}|${role}|${email}"
done

AFW_SAMPLE_LIST="
peter.parker|Peter|Parker|Admin|peter.parker@mail.com.br
"
AFW_SAMPLE_PASSWD="\${{ secrets.AFW_SAMPLE_PASSWD }}"

echo "$AFW_SAMPLE_LIST" | while IFS='|' read -r username fname lname role email; do
#password=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 10)

kubectl exec -n=airflow "$WORKERAFW_POD" -c worker -- \
    airflow users create \
    --username "$username" \
    --password "$AFW_SAMPLE_PASSWD" \
    --firstname "$fname" \
    --lastname "$lname" \
    --role "$role" \
    --email "$email"

#echo "${username}|${password}|${firstname}|${lastname}|${role}|${email}"
done

# Iterate over each user line
echo "$AFW_USERS_LIST" | while IFS='|' read -r username password fname lname role email; do
  kubectl exec -n=airflow "$WORKERAFW_POD" -c worker -- \
    airflow users create \
    --username "$username" \
    --password "$password" \
    --firstname "$fname" \
    --lastname "$lname" \
    --role "$role" \
    --email "$email"
done



# get an user
(
cat <<EOF
kubectl exec -n=airflow \
    "$WORKERAFW_POD" -c=worker -- \
    airflow users create \
    --username 4dm1nafw \
    --password "341543281_@dsadsa73849120" \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email admin@example.org
EOF
) | kubectl apply -f -


}

# Build and push Airflow custom image to registry
# spark provider
setup_spark_provider() {

# Where checker is the default OCI runtime
# that can pull from registries

AFW_IMG_TAG="\${{ secrets.AFW_IMG_TAG }}"
AFW_REGISTRY_TAG="\${{ secrets.AFW_REGISTRY_TAG }}"


checker && \
    docker build -t "$AFW_IMG_TAG" -f ./deploy/airflow/Dockerfile && \
    docker tag "$AFW_REGISTRY_TAG" "$AFW_REGISTRY_TAG" && \
    docker push "$AFW_IMG_TAG"

}


test_users() {

# get an user
(
cat <<EOF
kubectl exec -n=airflow \
    "$WORKERAFW_POD" -c=worker -- \
    airflow users create \
    --username "$AFW_BASE_ADM" \
    --password "$AFW_BASE_ADM_PASSWD" \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email admin@example.org
EOF
) | tee ./artifacts/afw-user-create.sh


check_user=$(kubectl exec -n=airflow "$WORKERAFW_POD" -c=worker -- airflow users list | grep "$AFW_BASE_ADM" | awk '{print $3}')
create_nu=$(sed 's/\${{ secrets.AFW_UI_PASSWD }}/$AFW_UI_PASSWD/g' < "./artifacts/afw-user-create.sh")

if "$check_user"; then
    # delete user, create same user with new password
    kubectl exec -n=airflow "$WORKERAFW_POD" -c=worker -- airflow users delete -u "$AFW_BASE_ADM"
    "$create_nu"
    echo "user found. Overwriting found user..."
else
    # if user does not exist, create anyway
    "$create_nu"
    echo "user not found. User being created now..."
fi

# fetch secret from openbao
#
#MYSecure_@passwd21321421



}
