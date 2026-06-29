#!/bin/sh

setup() {


# set ilum-minio pod secrets
ILUM_MINIO_ROOT_USER=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-user}" | base64 -d)
ILUM_MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-password}" | base64 -d)

ILUM_MINIO_OVH_S3_ACCESS_KEY="e65032bb03f64dad84ee57d638e72a95"
ILUM_MINIO_OVH_S3_SECRET_KEY="8951d35d36ed49558bcb51ece397e7a4"
ILUM_MINIO_OVH_S3_HOST="https://s3.bhs.io.cloud.ovh.net"
ILUM_MINIO_OVH_S3_REGION="bhs"

# patch the minio s3 uri for ilum-cloud discovery
 # storage.type: "s3" -> storage.type: "openebs-hostpath-node2"
(
cat <<EOF

ilum-core:
  minio:
    statusProbe:
      enabled: true
      baseUrl: "http://ilum-minio:9000"
      image: curlimages/curl:8.5.0
  kubernetes:
    defaultCluster:
      config:
        spark.hadoop.fs.s3a.bucket.ilum-data.impl: "org.apache.hadoop.fs.s3a.S3AFileSystem"
        spark.hadoop.fs.s3a.bucket.ilum-data.endpoint: "ilum-minio.ilum.svc.cluster.local:9000"
        spark.hadoop.fs.s3a.bucket.ilum-data.region: "$ILUM_MINIO_OVH_S3_REGION"
        spark.hadoop.fs.s3a.bucket.ilum-data.access.key: "$ILUM_MINIO_OVH_S3_ACCESS_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.secret.key: "$ILUM_MINIO_OVH_S3_SECRET_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.path.style.access: "true"
        spark.hadoop.fs.s3a.bucket.ilum-data.fast.upload: "true"
        spark.hadoop.fs.s3a.aws.credentials.provider: "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
        spark.sql.warehouse.dir: "s3a://ilum-data/"
    storage:
      type: "openebs-hostpath-node2"
    s3:
      host: "$ILUM_MINIO_OVH_S3_HOST"
      region: "$ILUM_MINIO_OVH_S3_REGION"
      port: 9000
      sparkBucket: ilum-files
      dataBucket: ilum-tables
      extraBuckets:
        - ilum-mlflow
        - ilum-data
      accessKey: "$ILUM_MINIO_OVH_S3_ACCESS_KEY"
      secretKey: "$ILUM_MINIO_OVH_S3_SECRET_KEY"

minio:
  enabled: true
  extraEnvVars: |
    - name: MINIO_BROWSER_REDIRECT_URL
      value: "http://ilum-minio:9001/external/minio/"
  fullnameOverride: "ilum-minio"
  defaultBuckets: "ilum-files, ilum-data, ilum-tables, ilum-mlflow"
  auth:
    rootUser: "$ILUM_MINIO_ROOT_USER"
    rootPassword: "$ILUM_MINIO_ROOT_PASSWORD"
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
EOF
) | helm upgrade --install ilum-core ilum/ilum-core --dependency-update \
    --namespace=ilum \
    --create-namespace \
    --set lineage.enabled=true \
    --set mongo.instances="https://bitnami.com/stack/mongodb/helm" \
    --set mongodb.enabled=true \
    --set mongo.uri="mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?authSource=ilum-default&directConnection=true" \
    --set mongodb.replicaSet.enabled=true \
    --set minio.enabled=true \
    --set kyuubi.enabled=true \
    --set kyuubi.url="http://ilum-sql-rest:10099" \
    --set airflow.enabled=true \
    --set airflow.fernetKey="$AFW_FERNET" \
    --set ilum-jupyter.enabled=true \
    --set ilum-livy-proxy.enabled=true \
    --set gitea.enabled=true \
    --set gitea.gitea.config.database.DB_TYPE="postgres" \
    --set gitea.gitea.config.database.USER="ilum" \
    --set gitea.gitea.config.database.PASSWD="dsdsadsadsa21321g8d123" \
    --set postgresql.enabled=true \
    --set kube-prometheus-stack.enabled=true \
    --set ilum-n8n.enabled=true \
    --set ilum-hive-metastore.enabled=true \
    --set ilum-core.hiveMetastore.enabled=true \
    --set ilum-sql.enabled=true \
    --set ilum-core.sql.enabled=true \
    --set global.lineage.enabled=true \
    --set superset.enabled=true \
    --set mlflow.enabled=true \
    -f -


# now the patch
#
kubectl patch deployment ilum-core -n ilum --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/initContainers/0/command",
    "value": [
      "sh",
      "-c",
      "until mongosh \"mongodb://ilumongo_acmeorg01:sample4837614@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/ilum-default?replicaSet=rs0&authSource=admin&appName=mongosh+2.1.1\" --eval '"'"'db.runCommand({ping:1})'"'"'; do echo waiting for mongo; sleep 2; done"
    ]
  }
]'

}
