#!/bin/sh

install() {
# add chart and update helm repo database
helm repo add ilum https://charts.ilum.cloud
helm repo update

#helm install --dependency-update ilum ilum/ilum

AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"

# install mongodb
helm install ilum-mongo oci://registry-1.docker.io/bitnamicharts/mongodb \
    --namespace=ilum --create-namespace

# install minio
helm install ilum-minio ilum/minio oci://registry-1.docker.io/bitnamicharts/minio \
    --namespace=ilum \
    --create-namespace


# generate random string with dev/random
MINIO_PASSWD=$(head -c 64 /dev/urandom | tr -cd A-Za-z0-9 | head -c 20)

printf "|> minio password is: %s\n\n" "$MINIO_PASSWD"

(
cat <<EOF
rootUser: minioadmin
rootPassword: $MINIO_PASSWD

persistence:
  enabled: true
  size: 8Gi
  storageClass: openebs-hostpath
EOF
) | helm upgrade --install ilum-minio oci://registry-1.docker.io/bitnamicharts/minio \
    --namespace=ilum \
    --create-namespace \
    -f -

# install ilum-ui
helm install ilum-ui ilum/ilum-ui --dependency-update \
    --namespace=ilum \
    --create-namespace

# patch the resource to ensure it stays as ClusterIP, since
# ingress-nginx-controller is the one taking care of exposing services on bare-metal
kubectl patch svc ilum-ui -n=ilum -p '{"spec": {"type": "ClusterIP"}}'

helm install ilum-core ilum/ilum-core --dependency-update \
    --namespace=ilum \
    --create-namespace \
    --set linage.enabled=true \
    --set mongo.instances="https://bitnami.com/stack/mongodb/helm" \
    --set mongodb.enabled=true \
    --set mongodb.replicaSet.enabled=true \
    --set minio.enabled=true \
    --set airflow.enabled=true \
    --set airflow.fernetKey="$AFW_FERNET" \
    --set ilum-jupyter.enabled=true \
    --set ilum-livy-proxy.enabled=true \
    --set gitea.enabled=true \
    --set postgresql.enabled=true \
    --set kube-prometheus-stack.enabled=true \
    --set ilum-n8n.enabled=true #\
    #--debug --wait


# install the ilum-ui
# helm install ilum-ui ilum/ilum-ui -n=ilum

IMONGO_ROOTPASSWORD=$ILUM_MONGO_PROD_ROOTPASSWORD
IMONGO_USERNAME=$ILUM_MONGO_PROD_USERNAME
IMONGO_PASSWORD=$ILUM_MONGO_PROD_PASSWORD
IMONGO_DATABASE=$ILUM_MONGO_PROD_DATABASE

# architecture is either replicaset or standalone
#    --set replicaCount=3 \
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install ilum-mongodb bitnami/mongodb --version 16.4.11  -n=ilum \
    --create-namespace \
    --set architecture=standalone \
    --set persistence.enabled=true \
    --set auth.rootPassword="$IMONGO_ROOTPASSWORD" \
    --set auth.username="$IMONGO_USERNAME" \
    --set auth.password="$IMONGO_PASSWORD" \
    --set auth.database="$IMONGO_DATABASE"

# works without openebs storageclass
# error: memory to mongo process is less than total system memory "kubernetes" "helm"
helm install ilum-mongodb bitnami/mongodb --version 16.4.11  -n=ilum \
    --create-namespace \
    --set architecture=standalone \
    --set persistence.enabled=true \
    --set auth.rootPassword="$IMONGO_ROOTPASSWORD" \
    --set auth.username="$IMONGO_USERNAME" \
    --set auth.password="$IMONGO_PASSWORD" \
    --set auth.database="$IMONGO_DATABASE"


# install jupyter
helm install ilum-jupyter ilum/ilum-jupyter --version 6.3.2 -n=ilum

# install livy-proxy
helm install ilum-livy-proxy ilum/ilum-livy-proxy -n=ilum

# install kyuubi
helm install ilum-kyuubi ilum/ilum-kyuubi

# install postgres
helm install ilum-postgresql bitnami/postgresql --version 16.6.0 -n=ilum

# install gitea
helm install ilum-gitea gitea-charts/ilum-gitea -n=ilum

# install ilum-core
helm install ilum-core ilum/ilum-core --dependency-update \
    --namespace=ilum \
    --create-namespace

# Set ilum-airflow's FernetKey to the same used by the Airflow namespace deployment
AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"
# output: Fernet Key: <redacted>


ILUM_GITEA_DB_TYPE
ILUM_GITEA_USER
ILUM_GITEA_PASSWD

ILUM_MONGO_PROD_ROOTPASSWORD
ILUM_MONGO_PROD_USERNAME
ILUM_MONGO_PROD_PASSWORD
ILUM_MONGO_PROD_DATABASE

# update existing chart version
# --set mongo.uri="mongodb://ilum-mongodb.ilum.svc.cluster.local/ilum-default?directConnection=true&appName=mongosh+2.1.1" \
# due to "transaction numbers are only allowed on a replica set member or mongos",
# mongodb.replicaSet.enabled=true
# --set mongo.uri="mongodb://ilumongo_acmeorg01:sample4837614@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local/admin?replicaSet=rs0&authSource=admin&appName=mongosh+2.1.1" \
helm upgrade --install ilum-core ilum/ilum-core --dependency-update \
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
    --set mlflow.enabled=true


# set ilum-minio pod secrets
ILUM_MINIO_ROOT_USER=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-user}" | base64 -d)
ILUM_MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-password}" | base64 -d)

ILUM_MINIO_OVH_S3_ACCESS_KEY="e65032bb03f64dad84ee57d638e72a95"
ILUM_MINIO_OVH_S3_SECRET_KEY="8951d35d36ed49558bcb51ece397e7a4"
ILUM_MINIO_OVH_S3_HOST="https://s3.bhs.io.cloud.ovh.net"
ILUM_MINIO_OVH_S3_REGION="bhs"

# patch the minio s3 uri for ilum-cloud discovery
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
        spark.hadoop.fs.s3a.bucket.ilum-data.endpoint: "http://ilum-minio:9000"
        spark.hadoop.fs.s3a.bucket.ilum-data.region: "$ILUM_MINIO_OVH_S3_REGION"
        spark.hadoop.fs.s3a.bucket.ilum-data.access.key: "$ILUM_MINIO_OVH_S3_ACCESS_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.secret.key: "$ILUM_MINIO_OVH_S3_SECRET_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.path.style.access: "true"
        spark.hadoop.fs.s3a.bucket.ilum-data.fast.upload: "true"
        spark.hadoop.fs.s3a.aws.credentials.provider: "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
        spark.sql.warehouse.dir: "s3a://ilum-data/"
    storage:
      type: "s3"
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
) | helm upgrade --install ilum-core ilum/ilum-core \
    --namespace=ilum \
    -f -




# --debug --wait

# it just connects to mongo
# it satisfies the wait-for-mongo initContainer but not for ilum-core
# kubectl patch deployment ilum-core -n ilum --type='json' -p='[
#   {
#     "op": "replace",
#     "path": "/spec/template/spec/initContainers/0/command",
#     "value": [
#       "sh",
#       "-c",
#       "until mongosh \"mongodb://ilum-mongodb.ilum.svc.cluster.local/ilum-default?directConnection=true&appName=mongosh+2.1.1\" --eval '"'"'db.runCommand({ping:1})'"'"'; do echo waiting for mongo; sleep 2; done"
#     ]
#   }
# ]'

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install ilum-mongodb bitnami/mongodb --version 16.4.11  -n=ilum \
    --create-namespace \
    --set architecture=standalone \
    --set persistence.enabled=true \
    --set auth.rootPassword="sample4837614" \
    --set auth.username="ilumongo_acmeorg01" \
    --set auth.password="samplePasswd" \
    --set auth.database="ilum-default"

helm upgrade --install ilum-mongodb bitnami/mongodb --version 16.4.11  -n=ilum \
    --create-namespace \
    --set architecture=replicaset \
    --set replicaCount=3 \
    --set persistence.enabled=false \
    --set auth.rootPassword="sample4837614" \
    --set auth.username="ilumongo_acmeorg01" \
    --set auth.password="samplePasswd" \
    --set auth.database="ilum-default" \

#
# include username and password
# ilumongo_acmeorg01
# --set auth.rootPassword="sample4837614" \
# --set auth.username="ilumongo_acmeorg01" \
# --set auth.password="samplePasswd" \
# --set auth.database="ilum-default"

# MONGODB_URI=mongodb://username:password@127.0.0.1/payload-cms?authSource=admin
# kubectl patch deployment ilum-core -n ilum --type='json' -p='[
#   {
#     "op": "replace",
#     "path": "/spec/template/spec/initContainers/0/command",
#     "value": [
#       "sh",
#       "-c",
#       "until mongosh \"mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb.ilum.svc.cluster.local/ilum-default?directConnection=true&appName=mongosh+2.1.1\" --eval '"'"'db.runCommand({ping:1})'"'"'; do echo waiting for mongo; sleep 2; done"
#     ]
#   }
# ]'


# "mongodb://ilumongo_acmeorg01:samplePasswd@ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local:27017/ilum-default?replicaSet=rs0&authSource=admin&appName=mongosh+2.1.1"
# replica architecture, URI reformatted
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

# --set mongo.uri="mongodb://ilum-mongodb-0.ilum-mongodb-headless.ilum.svc.cluster.local:27017/ilum-default?replicaSet=rs0" \

# get ilum-core chart manifest
helm get manifest ilum-core -n=ilum > ./ilum-core-manifest.yaml

# ensure mongodb is going to be deployed so ilum-core can start
(
cat <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: ilum-core-mongodb # or something similar
  namespace: ilum
spec:
  ports:
  - port: 27017
    targetPort: 27017
  selector:
    app.kubernetes.io/name: mongodb
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ilum-core-mongodb # or something similar
  namespace: ilum
spec:
  # ...
  template:
    spec:
      containers:
      - name: mongodb
        image: docker.io/bitnami/mongodb:latest # or similar
        ports:
        - containerPort: 27017
#
#
EOF
) >> ./ilum-core-manifest.yaml


helm upgrade ilum-core ilum/ilum-core -n ilum --set-file files.manifest=ilum-core-manifest.yaml


(
cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  namespace: ilum
spec:
  replicas: 3 # Adjust as needed
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: ilum/mongodb:6.0.5
        command: ["mongod", "--bind_ip_all", "--replSet", "rs0"] # enable replicaSet
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
      volumes:
      - name: mongodb-data
        emptyDir: {} # Use emptyDir for ephemeral storage, or PersistentVolumeClaim for persistent storage.
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  namespace: ilum
spec:
  selector:
    app: mongodb
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
EOF
) | kubectl apply -f -

#    --reuse-values \
#    :w


# mongosh function

# now patch ingress-nginx using an externalip:
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
    -p '{"spec": {"externalIPs": ["148.113.208.78"]}}'


#
}

pyspark_job_kubeflow() {
# submit pyspark script through a yaml (kubeflow only)

if ! [ -f "./deploy/k8s/spark/spark-pyspark-job.yaml" ]; then

PYSPARK_FILE="./artifacts/submit-pyspark.yaml"
(
cat <<EOF
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: pyspark-job
  namespace: ilum
spec:
  type: Python
  pythonVersion: "3"
  pythonFile: "local:///dags/main.py"
  mainApplicationFile: "local:///opt/spark/examples/src/main/python/pi.py"
  driver:
    cores: 1
    memory: "1g"
    serviceAccount: spark
  executor:
    cores: 1
    instances: 1
    memory: "1g"
  sparkConf:
    "spark.executor.instances": "2"
    "spark.kubernetes.container.image": "gcr.io/spark-operator/spark:v3.1.1"
    spark.ui.port: "4045"
    spark.eventLog.enabled: "true"
    spark.eventLog.dir: "hdfs://hdfs-namenode-1:8020/spark/spark-events"
  restartPolicy:
    type: Never
EOF
) | kubectl apply -f -
# ) | tee "$PYSPARK_FILE" && \
#     kubectl apply -f $PYSPARK_FILE
#     #rm "$PYSPARK_FILE"



#sed 's/\${{ secrets.MY_SECRET_KEY }}/$MY_SECRET_KEY/g' ./example.txt
sed 's/\${{ secrets.MY_SECRET_KEY }}/$MY_SECRET_KEY/g' "$PYSPARK_FILE" | kubectl exec -n=openbao -it openbao-0 -- bao

fi
}


# ===============================
# Configure UI
# ===============================
ilum_ui() {

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
        - "\${{ secrets.ILUM_HOST_0 }}"
      secretName: ilum-ui-tls
  rules:
    - host: "\${{ secrets.ILUM_HOST_0 }}"
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

create_users() {

#data_team

helm upgrade \
    --set ilum-core.security.internal.users[0].username=admin \
	--set ilum-core.security.internal.users[0].password=adminPassword \
	--set ilum-core.security.internal.users[0].roles[0]=ADMIN \
	--set ilum-core.security.internal.users[1].username=user \
	--set ilum-core.security.internal.users[1].password=userPassword \
	--set ilum-core.security.internal.users[1].roles[0]=USER \
	--reuse-values ilum ilum/ilum -n=ilum



}
jupyter_ui() {

# create secret for ilum-jupyter
htpasswd -c auth-jpy jpy
kubectl create secret generic jpy-auth --from-file=auth-jpy -n=ilum
kubectl get secret jpy-auth -o yaml -n=ilum

# create secret for ilum-core
htpasswd -c auth-ilum-core aic_sample
kubectl create secret generic ic-auth --from-file=auth-jpy -n=ilum
kubectl get secret jpy-auth -o yaml -n=ilum


(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilum-jupyter-ui-ingress
  namespace: ilum
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: jpy-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - foo'
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - "\${{ secrets.ILUM_JUPYTER_HOST }}"
    secretName: ilum-jupyter-ui-tls
  rules:
  - host: "\${{ secrets.ILUM_JUPYTER_HOST }}"
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

#| tee ./artifacts/jupyter-deploy.yaml && \
#    kubectl apply -f ./artifacts/jupyter-deploy.yaml
# | kubectl apply -f -
# "kubecl delete -f -" to delete

# create users for jupyter
#

# deploy jupyter ui ingress
echo
}


# ===============================
# Authentication && Authorization
# ===============================
spark_auth_nginx() {

    # This sparkSession will be requested to the ingress-nginx-controller, exposed with an externalIP.
    # the ingress-nginx-controller will route this to the ilum-core ingress resource since
    # nginx is its ingressClass.
    echo
}

# connect via vscode or jupyter
pyspark_session() {



# create secret for ilum-core
htpasswd -c auth-ilum-core aic_sample
kubectl create secret generic pyspark-ic-auth --from-file=auth-ilum-core -n=ilum
kubectl get secret pyspark-ic-auth -o yaml -n=ilum

# ic = ilum-core

(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilum-core-ingress
  namespace: ilum
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # this ssl-redirect being true is default for TLS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    nginx.ingress.kubernetes.io/rewrite-target: /

    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: pyspark-ic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - Ilum Core with pySpark'
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - "\${{ secrets.ILUM_JUPYTER_HOST }}"
    secretName: ilum-core-tls
  rules:
  - host: "\${{ secrets.ILUM_JUPYTER_HOST }}"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ilum-core
            port:
              number: 15002
EOF
) | kubectl apply -f -

# check if the jupyter ingress is working as intended
echo
}


deploy_unsafe() {

    # create secret for ilum-core
htpasswd -c auth-ilum-core aic_sample
kubectl create secret generic pyspark-ic-auth --from-file=auth-ilum-core -n=ilum
kubectl get secret pyspark-ic-auth -o yaml -n=ilum


(
cat <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ilum-core-ingress
  namespace: ilum
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # this ssl-redirect being true is default for TLS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    nginx.ingress.kubernetes.io/rewrite-target: /

    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: pyspark-ic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - Ilum Core with pySpark'
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - "d0-ilum-core.acmeorg.io"
    secretName: ilum-core-tls
  rules:
  - host: "d0-ilum-core.acmeorg.io"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ilum-core
            port:
              number: 15002
EOF
) | kubectl apply -f -

}

gitea_config() {


(
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
    name: ilum-git-credentials
    namespace: ilum
    annotations:
        kubectl.kubernetes.io/last-applied-configuration: "{}"
stringData:
    username: "admin-1"
    password: "1232141"
    postgres-password: "adsadsadas"
type: Opaque

EOF
) | kubectl apply -f -


}


minio_storage() {

# set minio s3 storage PVC
# using openebs and hostpath pv

# 1. make sure the minio image version is latest
echo





# set ilum-minio pod secrets
ILUM_MINIO_ROOT_USER=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-user}" | base64 -d)
ILUM_MINIO_ROOT_PASSWORD=$(kubectl get secret --namespace ilum ilum-minio -o jsonpath="{.data.root-password}" | base64 -d)

ILUM_MINIO_OVH_S3_ACCESS_KEY="e65032bb03f64dad84ee57d638e72a95"
ILUM_MINIO_OVH_S3_SECRET_KEY="8951d35d36ed49558bcb51ece397e7a4"
ILUM_MINIO_OVH_S3_HOST="https://s3.bhs.io.cloud.ovh.net"
ILUM_MINIO_OVH_S3_REGION="bhs"

# patch the minio s3 uri for ilum-cloud discovery
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
        spark.hadoop.fs.s3a.bucket.ilum-data.endpoint: "http://ilum-minio:9000"
        spark.hadoop.fs.s3a.bucket.ilum-data.region: "$ILUM_MINIO_OVH_S3_REGION"
        spark.hadoop.fs.s3a.bucket.ilum-data.access.key: "$ILUM_MINIO_OVH_S3_ACCESS_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.secret.key: "$ILUM_MINIO_OVH_S3_SECRET_KEY"
        spark.hadoop.fs.s3a.bucket.ilum-data.path.style.access: "true"
        spark.hadoop.fs.s3a.bucket.ilum-data.fast.upload: "true"
        spark.hadoop.fs.s3a.aws.credentials.provider: "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
        spark.sql.warehouse.dir: "s3a://ilum-data/"
    storage:
      type: "s3"
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



# (
# cat <<EOF
# airflow:
#   enabled: false
#   fullnameOverride: "ilum-airflow"
#   useStandardNaming: true
#   images:
#     airflow:
#       repository: "ilum/airflow"
#       tag: 2.9.3
# executor: "LocalKubernetesExecutor"
# extraEnv: |
#   - name: AIRFLOW__API__AUTH_BACKENDS
#     value: "airflow.api.auth.backend.default"
#   - name: MINIO_USERNAME
#     value: "minioadmin"
#   - name: MINIO_PASSWORD
#     value: "minioadmin"
#   - name: MINIO_ENDPOINT
#       value: "http://ilum-minio:9000"
# logging:
#   remote_logging: "True"
#   remote_base_log_folder: s3://ilum-data/airflow/logs
#   encrypt_s3_logs: False
#   remote_log_conn_id: ilum-minio
#
# mlflow:
#   externalS3:
#   host: "ilum-minio"
#   port: 9000
#   useCredentialsInSecret: true
#   existingSecret: "ilum-minio"
#   existingSecretAccessKeyIDKey: "root-user"
#   existingSecretKeySecretKey: "root-password"
#   protocol: "http"
#   bucket: "ilum-mlflow"
#
# ilum-hive-metastore:
#   enabled: false
#   postgresql:
#     image: "bitnami/postgresql:16"
#     host: "ilum-postgresql-hl"
#     port: 5432
#     database: metastore
#     auth:
#       username: ilum
#       password: "CHANGEMEPLEASE"
#
#   storage:
#     metastore:
#       warehouse: "s3a://ilum-data/"
#     type: "s3"
#     s3:
#       host: "ilum-minio"
#       port: 9000
#       accessKey: "minioadmin"
#       secretKey: "minioadmin"
#
# loki:
#   nameOverride: ilum-loki
#   monitoring:
#     selfMonitoring:
#       enabled: false
#       grafanaAgent:
#         installOperator: false
#       lokiCanary:
#         enabled: false
#   test:
#     enabled: false
#   loki:
#     auth_enabled: false
#     storage:
#       bucketNames:
#         chunks: ilum-files
#         ruler: ilum-files
#         admin: ilum-files
#       type: s3
#       s3:
#         endpoint: http://ilum-minio:9000
#         region: us-east-1
#         secretAccessKey: minioadmin
#         accessKeyId: minioadmin
#         s3ForcePathStyle: true
#         insecure: true
#     compactor:
#       retention_enabled: true
#       deletion_mode: filter-and-delete
#       shared_store: s3
#     limits_config:
#       allow_deletes: true
#
# trino:
#   enabled: false
#   nameOverride: ilum-trino
#   coordinatorNameOverride: ilum-trino-coordinator
#   workerNameOverride: ilum-trino-worker
#   server:
#     workers: 1
#   catalogs:
#     ilum-delta: |
#       connector.name=delta_lake
#       delta.metastore.store-table-metadata=true
#       delta.register-table-procedure.enabled=true
#       hive.metastore.uri=thrift://ilum-hive-metastore:9083
#       fs.native-s3.enabled=true
#       s3.endpoint=http://ilum-minio:9000
#       s3.region=us-east-1
#       s3.path-style-access=true
#       s3.aws-access-key=minioadmin
#       s3.aws-secret-key=minioadmin
#
# EOF
#) | helm upgrade --install upgrade --install ilum-core ilum/ilum-core \
#    -f -


}


connect_mongo() {
#mongodb://mongo.ilum.svc.cluster.local:27017/ilum-default?directConnection=true\&appName=mongosh+2.1.1 --eval 'db.runCommand({ping:1})'

kubectl describe deployment -n=ilum ilum-core
kubectl get deployment -n=ilum ilum-core -o yaml > ./new-mongosh-connection.yaml

# - until mongosh mongodb://mongo.ilum.svc.cluster.local:27017/ilum-default?directConnection=true\&appName=mongosh+2.1.1 --eval 'db.runCommand({ping:1})'

}



new_namespace() {

(
cat <<EOF
apiVersion: v1
kind: Namespace

metadata:
    name: ilum-final

EOF
) | kubectl apply -f -


helm repo add ilum https://charts.ilum.cloud
helm repo update

#helm install --dependency-update ilum ilum/ilum

AFW_FERNET="$(echo Fernet Key: "$(kubectl get secret --namespace airflow airflow-fernet-key -o jsonpath="{.data.fernet-key}" | base64 --decode)" | awk '{print $3}')"


helm upgrade --install ilum-core ilum/ilum-core --version 6.3.2 --dependency-update \
    --namespace=ilum-final \
    --create-namespace \
    --set minio.enabled=true \
    --set airflow.enabled=true \
    --set ilum-jupyter.enabled=true \
    --set ilum-livy-proxy.enabled=true \
    -f ./default-values.yaml


}
