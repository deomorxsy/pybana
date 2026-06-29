#!/bin/sh

# ilum AIO (all-in-one) deployment

# airflow fernet key
AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"

# minio
# set ilum-minio pod secrets
ILUM_MINIO_ROOT_USER=$(kubectl get secret --namespace=fixilum ilum-minio -o jsonpath="{.data.root-user}" | base64 -d)
ILUM_MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace=fixilum ilum-minio -o jsonpath="{.data.root-password}" | base64 -d)

ILUM_MINIO_OVH_S3_ACCESS_KEY="redacted_s3_access_key"
ILUM_MINIO_OVH_S3_SECRET_KEY="redacted_s3_secret_key"
ILUM_MINIO_OVH_S3_HOST="https://s3.bhs.io.cloud.ovh.net"
ILUM_MINIO_OVH_S3_REGION="bhs"

GITEA_DEFAULT_PASSWD="redacted_gitea_passwd"

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
    upgradeClusterOnStartup: "false"
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
        PASSWD: "$GITEA_DEFAULT_PASSWD"

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
) | helm upgrade --install ilum ilum/ilum \
     --dependency-update \
     --namespace=fixilum \
     --create-namespace \
     -f - && echo "done"


kubectl patch deployment ilum-core -n fixilum --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/initContainers/0/command",
    "value": [
      "sh",
      "-c",
      "until mongosh \"mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&appName=mongosh+2.1.1\" --eval '"'"'db.runCommand({ping:1})'"'"'; do echo waiting for mongo; sleep 2; done"
    ]
  }
]'


