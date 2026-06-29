# k8s cluster
s/\${{ secrets.ACMEORG_CLUSTER_0 }}/$ACMEORG_CLUSTER_0/g
s/\${{ secrets.ACMEORG_CLUSTER_2 }}/$ACMEORG_CLUSTER_2/g

# Mongo

# Minio
s/\${{ secrets.ILUM_MINIO_ROOT_USER }}/$ILUM_MINIO_ROOT_USER/g
s/\${{ secrets.ILUM_MINIO_ROOT_PASSWORD }}/$ILUM_MINIO_ROOT_PASSWORD/g
s/\${{ secrets.ILUM_MINIO_OVH_S3_ACCESS_KEY }}/$ILUM_MINIO_OVH_S3_ACCESS_KEY/g
s/\${{ secrets.ILUM_MINIO_OVH_S3_SECRET_KEY }}/$ILUM_MINIO_OVH_S3_SECRET_KEY/g
s/\${{ secrets.ILUM_MINIO_OVH_S3_HOST }}/$ILUM_MINIO_OVH_S3_HOST/g
s/\${{ secrets.ILUM_MINIO_OVH_S3_REGION }}/$ILUM_MINIO_OVH_S3_REGION/g

# Airflow
s/\${{ secrets.AFW_HOST_0 }}/$AFW_HOST_0/g
s/\${{ secrets.AFW_UI_PASSWD }}/$AFW_UI_PASSWD/g
s/\${{ secrets.AFW_SECRET_NAME }}/$AFW_SECRET_NAME/g
s/\${{ secrets.AFW_BASE_ADM }}/$AFW_BASE_ADM/g
s/\${{ secrets.AFW_BASE_ADM_PASSWD }}/$AFW_BASE_ADM_PASSWD/g
s/\${{ secrets.AFW_USERS_LIST }}/$AFW_USERS_LIST/g
s/\${{ secrets.AFW_SAMPLE_LIST }}/$AFW_SAMPLE_LIST/g
s/\${{ secrets.AFW_SAMPLE_PASSWD }}/$AFW_SAMPLE_PASSWD/g
s/\${{ secrets.AFW_IMG_TAG }}/$AFW_IMG_TAG/g
s/\${{ secrets.AFW_REGISTRY_TAG }}/$AFW_REGISTRY_TAG/g

# DAGS for Airflow
s/\${{ secrets.DAGS_AWS_ACCESS_KEY }}/$DAGS_AWS_ACCESS_KEY/g
s/\${{ secrets.DAGS_AWS_SECRET_KEY }}/$DAGS_AWS_SECRET_KEY/g
s/\${{ secrets.DAGS_AWS_ENDPOINT_URL }}/$DAGS_AWS_ENDPOINT_URL/g

# DAGs Postgres
s/\${{ secrets.DAGS_AFW_PG_USER }}/$DAGS_AFW_PG_USER/g
s/\${{ secrets.DAGS_AFW_PG_PWD }}/$DAGS_AFW_PG_PWD/g
s/\${{ secrets.DAGS_AFW_PG_HOST }}/$DAGS_AFW_PG_HOST/g
s/\${{ secrets.DAGS_AFW_PG_PORT }}/$DAGS_AFW_PG_PORT/g
s/\${{ secrets.DAGS_AFW_PG_DB }}/$DAGS_AFW_PG_DB/g
s/\${{ secrets.DAGS_AFW_PG_SCHEMA }}/$DAGS_AFW_PG_SCHEMA/g

# DAGs Parquet
s/\${{ secrets.DAGS_PARQUET_S3_URI }}/$DAGS_PARQUET_S3_URI/g

# DAGs SparkSession
s/\${{ secrets.DAGS_AFW_SPARKSESSION_USER }}/$DAGS_AFW_SPARKSESSION_USER/g
s/\${{ secrets.DAGS_AFW_SPARKSESSION_PASSWD }}/$DAGS_AFW_SPARKSESSION_PASSWD/g

# DAGs Minio
s/\${{ secrets.DAGS_AFW_MINIO_AK }}/$DAGS_AFW_MINIO_AK/g
s/\${{ secrets.DAGS_AFW_MINIO_SK }}/$DAGS_AFW_MINIO_SK/g

# Openbao Setup
s/\${{ secrets.OB_VAULT_TOKEN }}/$OB_VAULT_TOKEN/g
s/\${{ secrets.OP_POST_DATA_PASSWD }}/$OP_POST_DATA_PASSWD/g

# Qdrant setup
s/\${{ secrets.QDRANT_HOST_0 }}/$QDRANT_HOST_0/g

# Ilum
s/\${{ secrets.ILUM_HOST_0 }}/$ILUM_HOST_0/g
s/\${{ secrets.ILUM_CORE_0 }}/$ILUM_CORE_0/g

# Jupyter
s/\${{ secrets.ILUM_JUPYTER_HOST_0 }}/$ILUM_JUPYTER_HOST_0/g
s/\${{ secrets.ILUM_JUPYTERHUB_TOKEN }}/$ILUM_JUPYTERHUB_TOKEN/g

# Host scope
s/\${{ secrets.NSC_VALUE }}/$NSC_VALUE/g
s/\${{ secrets.AFW_SSH_REPO_URI }}/$AFW_SSH_REPO_URI/g
s/\${{ secrets.GITSYNC_SECRET_NAME }}/$GITSYNC_SECRET_NAME/g

# Github Secrets
s/\${{ secrets.GTHUB_CONFIG_URL }}/$GTHUB_CONFIG_URL/g
s/\${{ secrets.GTHUB_PAT }}/$GTHUB_PAT/g

# Calico
s/\${{ secrets.BGP_PEER_IP }}/$BGP_PEER_IP/g
s/\${{ secrets.BGP_ASNUMBER }}/$BGP_ASNUMBER/g

# SSO keycloak + crossplane
s/\${{ secrets.RANDOM_KAP }}/$RANDOM_KAP/g
s/\${{ secrets.RANDOM_KDBC }}/$RANDOM_KDBC/g
s/\${{ secrets.RANDOM_KDBC_PSQL }}/$RANDOM_KDBC_PSQL/g

s/\${{ secrets.KEYCLOAK_ADMIN }}/$KEYCLOAK_ADMIN/g
s/\${{ secrets.KEYCLOAK_PASSWD }}/$KEYCLOAK_PASSWD/g
s/\${{ secrets.KEYCLOAK_DOMAIN }}/$KEYCLOAK_DOMAIN/g
s/\${{ secrets.KEYCLOAK_POSTGRES_PASSWD }}/$KEYCLOAK_POSTGRES_PASSWD/g

# Budibase
s/\${{ secrets.BDB_OLD_BDB_HOST }}/$BDB_OLD_BDB_HOST/g
s/\${{ secrets.BDB_URL }}/$BDB_URL/g
s/\${{ secrets.BDB_USER }}/$BDB_USER/g
s/\${{ secrets.BDB_PASSWD }}/$BDB_PASSWD/g
s/\${{ secrets.BDB_HOSTNAME }}/$BDB_HOSTNAME/g

# n8n setup
s/\${{ secrets.N8N_PERSONALIZATION_ENABLED }}/$N8N_PERSONALIZATION_ENABLED/g
s/\${{ secrets.N8N_SECURE_COOKIE }}/$N8N_SECURE_COOKIE/g
s/\${{ secrets.N8N_PAYLOAD_SIZE_MAX }}/$N8N_PAYLOAD_SIZE_MAX/g
s/\${{ secrets.N8N_TUNNEL_URL }}/$N8N_TUNNEL_URL/g
s/\${{ secrets.N8N_WEBHOOK_URL }}/$N8N_WEBHOOK_URL/g
s/\${{ secrets.N8N_EDITOR_BASE_URL }}/$N8N_EDITOR_BASE_URL/g
s/\${{ secrets.N8N_ENDPOINT_WEBHOOK_URL }}/$N8N_ENDPOINT_WEBHOOK_URL/g
s/\${{ secrets.N8N_WEBHOOK_URL }}/$N8N_WEBHOOK_URL/g
s/\${{ secrets.n8n_agr_vai }}/$n8n_agr_vai/g

# n8n configmap
s/\${{ secrets.N8N_NODE_ENV }}/$N8N_NODE_ENV/g
s/\${{ secrets.N8N_GENERIC_TIMEZONE }}/$N8N_GENERIC_TIMEZONE/g
s/\${{ secrets.N8N_WEBHOOK_TUNNEL_URL }}/$N8N_WEBHOOK_TUNNEL_URL/g

# n8n Database configurations
s/\${{ secrets.N8N_DB_TYPE }}/$N8N_DB_TYPE/g
s/\${{ secrets.N8N_DB_POSTGRESDB_USER }}/$N8N_DB_POSTGRESDB_USER/g
s/\${{ secrets.N8N_DB_POSTGRESDB_DATABASE }}/$N8N_DB_POSTGRESDB_DATABASE/g
s/\${{ secrets.N8N_DB_POSTGRESDB_HOST }}/$N8N_DB_POSTGRESDB_HOST/g
s/\${{ secrets.N8N_DB_POSTGRESDB_PORT }}/$N8N_DB_POSTGRESDB_PORT/g

# n8n in turning on basic auth
s/\${{ secrets.N8N_BASIC_AUTH_ACTIVE }}/$N8N_BASIC_AUTH_ACTIVE/g
s/\${{ secrets.N8N_BASIC_AUTH_USER }}/$N8N_BASIC_AUTH_USER/g

# N8N postgres
s/\${{ secrets.N8N_PGDATA }}/$N8N_PGDATA/g
s/\${{ secrets.N8N_POSTGRES_USER }}/$N8N_POSTGRES_USER/g
s/\${{ secrets.N8N_POSTGRES_DB }}/$N8N_POSTGRES_DB/g
s/\${{ secrets.N8N_POSTGRES_PASSWORD }}/$N8N_POSTGRES_PASSWORD/g

# nginx
s/\${{ secrets.NGINX_OLD_SERVER_NAME }}/$NGINX_OLD_SERVER_NAME/g

# spark-wrapper
s/\${{ secrets.SWRAPPER_S3_LAKE_PARQUET }}/$SWRAPPER_S3_LAKE_PARQUET/g
s/\${{ secrets.SWRAPPER_CRAWLER_EXAMPLE }}/$SWRAPPER_CRAWLER_EXAMPLE/g

# Harbor self-hosted registry
s/\${{ secrets.HARBOR_REG_USERNAME }}/$HARBOR_REG_USERNAME/g
s/\${{ secrets.HARBOR_REG_PASSWD }}/$HARBOR_REG_PASSWD/g
s/\${{ secrets.HARBOR_REG_MAIL }}/$HARBOR_REG_MAIL/g

