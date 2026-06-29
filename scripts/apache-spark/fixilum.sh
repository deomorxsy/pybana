#!/bin/sh



sed_replace() {

sec_sed="./scripts/secrets/rep-secrets.sed"

# Get secrets from vaultwarden
rbw get $ITEM_NAME | sed 's/\\n/\n/g'

docker cp container_name ./scripts/secrets-posix.bak.sh

set -a
. "/secrets-posix.bak.sh"
set +a

if [ -f "$sec_sed" ] && [ -f ./artifacts/sso.sh ]; then

    sed -f "$sec_sed" < "./artifacts/sso.sh" > ./artifacts/replaSED-sso.sh && \
        envsubst < ./artifacts/replaSED-sso.sh > ./artifacts/unsealed-sso.sh
else
    printf "\n|> Error: secrets parsing sed script not found. Exiting now..."
fi



}

replacer() {

FUNC="rep" FILE="./scripts/apache-spark/fixilum.sh" . ./scripts/replacer.sh

}

# ilum AIO (all-in-one) deployment

# airflow fernet key
AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"

# minio
# set ilum-minio pod secrets

S3_ACCESS_KEY="$ILUM_MINIO_OVH_S3_ACCESS_KEY"
S3_SECRET_KEY="$ILUM_MINIO_OVH_S3_SECRET_KEY"
S3_HOST="$ILUM_MINIO_OVH_S3_HOST"
S3_REGION="$ILUM_MINIO_OVH_S3_REGION"

# mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless:27017,ilum-mongodb-1.ilum-mongodb-headless:27017,ilum-mongodb-2.ilum-mongodb-headless:27017/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1
# mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1

usual() {
# run ilum at the usual ilum namespace
#

if helm list -n=ilum | grep "ilum" | grep "deployed"; then
    HELM_ARG="upgrade --install"
    printf "\n======\n|> Found a previous [DEPLOYED] ilum install. Upgrading it now...\n======\n\n"
elif helm list -n=ilum | grep "ilum" | grep "failed"; then
    HELM_ARG="install"
    printf "\n======\n|> Found a previous [FAILED] ilum install. Upgrading it now...\n======\n\n"
else
    HELM_ARG="install"
    printf "\n======\n|> No ilum install detected. Installing it now...\n======\n\n"

fi


ILUM_MONGO_LOCAL_ROOTPASSWORD="$ILUM_MONGO_PROD_ROOTPASSWORD"
ILUM_MONGO_LOCAL_USERNAME="$ILUM_MONGO_PROD_USERNAME"
ILUM_MONGO_LOCAL_PASSWORD="$ILUM_MONGO_PROD_PASSWORD"
ILUM_MONGO_LOCAL_DATABASE="$ILUM_MONGO_PROD_DATABASE"

# From the mongo section at secrets
IAIO_MONGO_USER="${ILUM_MONGO_PROD_USERNAME}"
IAIO_MONGO_PASSWD="${ILUM_MONGO_PROD_PASSWORD}"

#ILUM_MONGO_URI="mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1"
ILUM_MONGO_URI="mongodb://${IAIO_MONGO_USER}:${IAIO_MONGO_PASSWD}@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1"


ILUM_USERS_LIST=$(



# Create Airflow users
ILUM_USERS_LIST_LOCAL="\${{ secrets.ILUM_USERS_LIST }}"

if [ "$ILUM_USERS_LIST_LOCAL" = "" ];

    replacer

echo "$AFW_USERS_LIST_LOCAL" | while IFS='|' read -r username fname lname role email; do

ILUM_DYN_PASSWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 10)

    #if [ "$role" = "USER" ]; then

# cat ./deploy/k8s/spark/values-security.bak.yaml


(
cat <<EOF
    - username: "${username}"
      initialPassword: "${ILUM_DYN_PASSWD}"
      roles:
        - "USER"
EOF
) >> ./deploy/k8s/spark/values-security.bak.yaml

#elif [ "$role" = "ADMIN" ]; then

#cat <<EOF
#    - username: "${username}"
#      initialPassword: "${ILUM_DYN_PASSWD}"
#      roles:
#        - "USER"
#EOF

#fi
    done

)

(
cat <<EOF
# Enable lineage (if you need it)
global:
  lineage:
    enabled: true

# ilum-core settings
ilum-core:
  enabled: true
  sql:
    enabled: true
  hiveMetastore:
    enabled: true
  mongo:
    uri: "${ILUM_MONGO_URI}"
    statusProbe:
    enabled: false
    image: ilum/mongodb:6.0.5
  minio:
    statusProbe:
    enabled: false
    baseUrl: "http://ilum-minio:9000"
    image: curlimages/curl:8.5.0
  security:
    type: "internal"
    internal:
      users:
        - username: "admin"
          initialPassword: "1283y143g2fdvfbs8d@bfudvfd"
          roles:
            - "ADMIN"
        - username: "4dm1n_d0_k8s_USER"
          initialPassword: "3h4923bf28vf209hf@r31_e21"
          roles:
            - "USER"
        - username: "dummy_user01"
          initialPassword: "dummy@_d01"
          roles:
            - "USER"
        - username: "dummy_user02"
          initialPassword: "dummyd02"
          roles:
            - "DATA_ENGINEER"
        - username: "dummy_user03"
          initialPassword: "dummyd03"
          roles:
            - "DATA_SCIENTIST"
        - username: "r4m0s"
          password: "ILUM_P@SSWD"
          roles:
            - "DATA_ENGINEER"
        - username: "c4br4l"
          password: "P@SSWD_3rd"
          roles:
            - "DATA_SCIENTIST"
        - username: "s0br4l"
          password: "P@SSWD_4th"
          roles:
            - "DATA_SCIENTIST"
        - username: "gr3v4"
          password: "P@SSWD_5th"
          roles:
            - "DATA_SCIENTIST"
        - username: "g4rr3t"
          password: "P@SSWD_6th"
          roles:
            - "DATA_SCIENTIST"
        - username: "r1b31r0"
          password: "das812e4g12@_uabdu2312asvf"
          roles:
          - "DATA_ENGINEER"
        - username: "4ugust0_de"
          password: "P@SSWD_8th"
          roles:
          - "DATA_SCIENTIST"
        - username: "p0rt3l4_de_mlops"
          password: "P@SSWD_9th"
          roles:
          - "DATA_SCIENTIST"
        - username: "p4zz1n1_mlops"
          password: "P@SSWD_10th"
          roles:
          - "DATA_SCIENTIST"
        - username: "th4l1t4_mlops"
          password: "P@SSWD_11th"
          roles:
          - "DATA_SCIENTIST"
        - username: "w4gn3r_cloudops"
          password: "P@SSWORD_12th"
          roles:
          - "DATA_SCIENTIST"
        - username: "p4squ4l1n1_mlops"
          password: "P@SSWORD_13th"
          roles:
          - "DATA_ENGINEER"

# MongoDB settings (our built-in MongoDB)
mongodb:
  enabled: true
  replicaSet:
    enabled: true # this one is needed
  # architecture: standalone  # Matches your standalone preference
  architecture: replicaset
  replicaCount: 3
  persistence:
    enabled: true
  auth:
    enabled: true
    rootPassword: "sample4837614"
    username: "ilumongo_acmeorg01"
    password: "samplePasswd"
    database: "ilum-default"

# MinIO settings
minio:
  enabled: true
  extraEnvVars: |
    - name: MINIO_BROWSER_REDIRECT_URL
      value: "http://ilum-minio:9001/external/minio/"
  fullnameOverride: "ilum-minio"
  defaultBuckets: "ilum-files, ilum-data, ilum-tables, ilum-mlflow"
  auth:
    rootUser: "minioadmin"
    rootPassword: "minioadmin"
  persistence:
    enabled: true
    size: 8Gi
    storageClass: openebs-hostpath
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
            - arm64

kubernetes:
    defaultCluster:
      config:
        spark.hadoop.fs.s3a.bucket.ilum-data.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"
        spark.hadoop.fs.s3a.bucket.ilum-data.endpoint: "http://ilum-minio.ilum.svc.cluster.local:9000"
        spark.hadoop.fs.s3a.bucket.ilum-data.region: "us-east-1"
        spark.hadoop.fs.s3a.bucket.ilum-data.access.key: "minioadmin"
        spark.hadoop.fs.s3a.bucket.ilum-data.secret.key: "minioadmin"
        spark.hadoop.fs.s3a.bucket.ilum-data.path.style.access: "true"
        spark.hadoop.fs.s3a.bucket.ilum-data.fast.upload: "true"
        spark.hadoop.fs.s3a.aws.credentials.provider: "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
        spark.sql.warehouse.dir: "s3a://ilum-data/"
    initClusterOnStartup: "true"
    # false by default
    upgradeClusterOnStartup: "true"
    api:
      url: "https://kubernetes.default.svc"
    container:
      image: "ilum/spark:3.5.3-delta"
    storage:
      type: "s3"
    s3:
      host: "ilum-minio"
      region: "us-east-1"
      port: 9000
      sparkBucket: ilum-files
      dataBucket: ilum-tables
      extraBuckets:
        - ilum-mlflow
        - ilum-data
      accessKey: "minioadmin"
      secretKey: "minioadmin"


# Airflow settings
airflow:
  enabled: true
  fernetKey: "$AFW_FERNET"

# ilum-jupyter settings
ilum-jupyter:
  enabled: true

# ilum-livy-proxy settings
ilum-livy-proxy:
  enabled: true

# ilum-livy-proxy settings
ilum-hive-metastore:
  enabled: true

# Gitea settings
gitea:
  enabled: true
  gitea:
    config:
      database:
        DB_TYPE: "postgres"
        USER: "ilum"
        PASSWD: "CHANGEMEPLEASE"

# PostgreSQL settings
postgresql:
  enabled: true
  fullnameOverride: ilum-postgresql
  auth:
    postgresPassword: "CHANGEMEPLEASE"
    username: ilum
    password: "CHANGEMEPLEASE"


postgresExtensions:
  enabled: true
  image: "bitnami/postgresql:16"
  pullPolicy: IfNotPresent
  imagePullSecrets: []
  host: "ilum-postgresql-hl"
  port: 5432
  databasesToCreate: marquez,airflow,metastore,mlflow,mlflow_auth,superset,gitea,n8n
  auth:
    username: ilum
    password: "CHANGEMEPLEASE"
  nodeSelector: {}
  tolerations: []
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                  - amd64
                  - arm64

# Kube Prometheus Stack settings
kube-prometheus-stack:
  enabled: true

# ilum-n8n settings
ilum-n8n:
  enabled: true

# ilum-sql settings
ilum-sql:
  enabled: true

EOF
) | helm upgrade --install ilum ilum/ilum \
     --dependency-update \
     --namespace=ilum \
     --create-namespace \
     --set ilum-ui.service.type="ClusterIP" \
     --set ilum-ui.service.nodePort="" \
     --set ilum-ui.service.clusterIP="" \
     -f - && echo "done"
# helm "$HELM_ARG" ilum ilum/ilum \
}

custom() {
# run ilum at the fixilum custom namespace

if helm list -n=fixilum | grep ilum ; then
    HELM_ARG="upgrade --install"
    printf "\n======\n|> Found a previous ilum install on the fixilum namespace. Upgrading it now...\n======\n\n"
else
    HELM_ARG="install"
    printf "\n======\n|> No ilum install detected on the fixilum namespace. Installing it now...\n======\n\n"

fi

(
cat <<EOF
# Enable lineage (if you need it)
global:
  lineage:
    enabled: true

# ilum-core settings
ilum-core:
  enabled: true
  sql:
    enabled: true
  hiveMetastore:
    enabled: true
  mongo:
    uri: "mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1"
    # uri: "mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb.fixilum.svc.cluster.local/ilum-default?directConnection=true&appName=mongosh+2.1.1"
    statusProbe:
    enabled: false
    image: ilum/mongodb:6.0.5
  minio:
    statusProbe:
    enabled: false
    baseUrl: "http://ilum-minio:9000"
    image: curlimages/curl:8.5.0


# MongoDB settings (our built-in MongoDB)
mongodb:
  enabled: true
  replicaSet:
    enabled: true # this one is needed
  # architecture: standalone  # Matches your standalone preference
  architecture: replicaset
  replicaCount: 3
  persistence:
    enabled: true
  auth:
    enabled: true
    rootPassword: "sample4837614"
    username: "ilumongo_acmeorg01"
    password: "samplePasswd"
    database: "ilum-default"

# MinIO settings
minio:
  enabled: true
  extraEnvVars: |
    - name: MINIO_BROWSER_REDIRECT_URL
      value: "http://ilum-minio:9001/external/minio/"
  fullnameOverride: "ilum-minio"
  defaultBuckets: "ilum-files, ilum-data, ilum-tables, ilum-mlflow"
  auth:
    rootUser: "minioadmin"
    rootPassword: "minioadmin"
  persistence:
    enabled: true
    size: 8Gi
    storageClass: openebs-hostpath
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
            - arm64

kubernetes:
    defaultCluster:
      config:
        spark.hadoop.fs.s3a.bucket.ilum-data.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"
        spark.hadoop.fs.s3a.bucket.ilum-data.endpoint: "http://ilum-minio.fixilum.svc.cluster.local:9000"
        spark.hadoop.fs.s3a.bucket.ilum-data.region: "us-east-1"
        spark.hadoop.fs.s3a.bucket.ilum-data.access.key: "minioadmin"
        spark.hadoop.fs.s3a.bucket.ilum-data.secret.key: "minioadmin"
        spark.hadoop.fs.s3a.bucket.ilum-data.path.style.access: "true"
        spark.hadoop.fs.s3a.bucket.ilum-data.fast.upload: "true"
        spark.hadoop.fs.s3a.aws.credentials.provider: "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
        spark.sql.warehouse.dir: "s3a://ilum-data/"
    initClusterOnStartup: "true"
    # false by default
    upgradeClusterOnStartup: "true"
    api:
      url: "https://kubernetes.default.svc"
    container:
      image: "ilum/spark:3.5.3-delta"
    storage:
      type: "s3"
    s3:
      host: "ilum-minio"
      region: "us-east-1"
      port: 9000
      sparkBucket: ilum-files
      dataBucket: ilum-tables
      extraBuckets:
        - ilum-mlflow
        - ilum-data
      accessKey: "minioadmin"
      secretKey: "minioadmin"

# Airflow settings
airflow:
  enabled: true
  fernetKey: "$AFW_FERNET"

# ilum-jupyter settings
ilum-jupyter:
  enabled: true

# ilum-livy-proxy settings
ilum-livy-proxy:
  enabled: true

# ilum-livy-proxy settings
ilum-hive-metastore:
  enabled: true

# Gitea settings
gitea:
  enabled: true
  gitea:
    config:
      database:
        DB_TYPE: "postgres"
        USER: "ilum"
        PASSWD: "dsdsadsadsa21321g8d123"

# PostgreSQL settings
postgresql:
  enabled: true

# Kube Prometheus Stack settings
kube-prometheus-stack:
  enabled: true

# ilum-n8n settings
ilum-n8n:
  enabled: true

# ilum-sql settings
ilum-sql:
  enabled: true

EOF
) | helm "$HELM_ARG" ilum ilum/ilum \
     --dependency-update \
     --namespace=fixilum \
     --create-namespace \
     -f - && echo "done"


# ILUM_JUPYTERHUB_TOKEN="dba@dsadas_wqewdwq@ufs"

kubectl patch deployment ilum-jupyter -n=ilum --type='json' -p='[
   {
     "op": "replace",
     "path": "/spec/template/spec/containers/0/command",
     "value": [
       "sh",
       "-c",
       "set -ex; exec start-notebook.sh --ServerApp.base_url='/external/jupyter/' --IdentityProvider.token='"dba@dsadas_wqewdwq@ufs"' \"$@\";\n"
     ]
   }
 ]'
# kubectl patch deployment ilum-core -n fixilum --type='json' -p='[
#   {
#     "op": "replace",
#     "path": "/spec/template/spec/initContainers/0/command",
#     "value": [
#       "sh",
#       "-c",
#       "until mongosh \"mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1\" --eval '"'"'db.runCommand({ping:1})'"'"'; do echo waiting for mongo; sleep 2; done"
#     ]
#   }
# ]'

}


print_usage() {
cat <<-END >&2
USAGE: fixilum [-options]
                - usual
                - debug
                - help
                - version
eg,
fixilum -usual   # install/upgrade fixilum at the usual ilum namespace
fixilum -debug   # install/upgrade fixilum at the custom fixilum namespace
fixilum -help    # shows this help message
fixilum -version # shows script version

See the man page and example file for more info.

END

}



jupyter_setup() {

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jupyter-ui-ingress
  namespace: ilum
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - d0-jupyter.acmeorg.io
    secretName: jupyter-ui-tls
  rules:
  - host: d0-jupyter.acmeorg.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ilum-jupyter
            port:
              number: 8888
EOF
) | kubectl apply -f -

# delete/apply accordingly
# the rewrite-target $2 is to route the request based on
# the second capture group from the path regular expression

# kubectl patch deployment ilum-jupyter -n=ilum --type='json' -p='[
#    {
#      "op": "replace",
#      "path": "/spec/template/spec/containers/0/command",
#      "value": [
#        "sh",
#        "-c",
#        "set -ex; exec start-notebook.sh --ServerApp.base_url='/external/jupyter/' --IdentityProvider.token='' \"$@\";\n"
#      ]
#    }
#  ]'

kubectl patch deployment ilum-jupyter -n=ilum --type='json' -p='[
   {
     "op": "replace",
     "path": "/spec/template/spec/containers/0/command",
     "value": [
       "sh",
       "-c",
       "set -ex; exec start-notebook.sh --ServerApp.base_url='/external/jupyter/' --IdentityProvider.token='"dba@dsadas_wqewdwq@ufs"' \"$@\";\n"
     ]
   }
 ]'


}



ilum_ui_setup() {
(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilum-ui-ingress
  namespace: ilum
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - d0-ilum.acmeorg.io
      secretName: ilum-ui-tls
  rules:
    - host: d0-ilum.acmeorg.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ilum-ui
                port:
                  number: 8080

EOF
) | kubectl apply -f -


}

# Check the argument passed from the command line
if [ "$1" = "-usual" ] || [ "$1" = "-u" ] || [ "$1" = "--usual" ] ; then
    usual
elif [ "$1" = "-debug" ] || [ "$1" = "-d" ] || [ "$1" = "--debug" ] ; then
    debug
elif [ "$1" = "-help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
elif [ "$1" = "-version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
    debug
else
    printf "\n|>Invalid function name. Please specify like this: fixilum -function1 \n|>Check available functions on the help:\n\n"
    print_usage
fi
