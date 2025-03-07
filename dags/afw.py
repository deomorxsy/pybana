# system utils
import sys
import time
from datetime import datetime, timedelta

# afw DAG syntax
from airflow import DAG
from airflow.decorators import dag, task
from airflow.models import dagbag

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
        start_date=datetime(2024, 1, 31),
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
    run_this = run_after_loop()


@task.bash
def submit_pyspark(pyspark_script_path) -> str:
    foo = "./deploy/spark/spark-pyspark-job.yaml"
    # return fstring (formatted string literal)
    return f"kubectl apply -f {foo}"


pss_path = "./app/main.py"
