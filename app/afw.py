# system utils
import sys
import time
from datetime import datetime, timedelta

# afw DAG syntax
from airflow import DAG
from airflow.decorators import dag, task

# import operators
from airflow.operators.empty import EmptyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.providers.cncf.kubernetes.sensors.spark_kubernetes import SparkKubernetesSensor

# qdrant
from airflow.providers.qdrant.hooks.qdrant import QdrantHook

# weekly deploys
@dag(
    dag_id='test_perm_dag',
    schedule_interval='@weekly',
    start_date=datetime(2024, 1, 31),
    catchup=False,
    tags=['test', 'permission']
)
def test_dag():
    @task.bash
    def test():
        return 'python /opt/airflow/dags/airflow_test/main.py'
    test()

test_dag()

# daily dag deploys
with DAG(
        dag_id="my_dag_name",
        start_date=datetime.datetime(2024, 1, 31),
        schedule="@daily",
):
    EmptyOperator(task_id="task")


# the k8s spark operator deploys
spark_k8s_task = SparkKubernetesOperator(
    task_id='n-spark-on-k8s-airflow',
    trigger_rule="all_success",
    depends_on_past=False,
    retries=0,
    application_file='spark-k8s.yaml',
    namespace="spark-apps",
    kubernetes_conn_id="kubernetes_default",
    do_xcom_push=True,
    dag=dag
)

spark_k8s_task

# submit to the operator
@task.bash
def run_after_loop() -> str:
    return "echo https://airflow.apache.org/"
runt_this = run_after_loop()



@task.bash
def submit_pyspark(pyspark_script_path) -> str:
    # return fstring (formatted string literal)
    return f""" \
mkdir -p ./artifacts/ && \
cat <<EOF
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: pyspark-job
  namespace: default
spec:
  type: Python
  pythonVersion: "3"
  pythonFile: "{}"gs://your-bucket/path/to/your-pyspark-script.py
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
  restartPolicy:
    type: Never
EOF | tee ./artifacts/spark-pyspark-job.yaml && \
        kubectl apply -f ./artifacts/spark-pyspark-job.yaml
"""


pss_path="./app/main.py"
