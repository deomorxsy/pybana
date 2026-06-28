from datetime import datetime

# import DAG to use the syntax 'with DAG(...)'
# and EmptyOperator for tasks.
from airflow import DAG
from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator


# =================
# DAG1 is defined with a @dag decorator.
@dag(
    dag_id="dag_gerada_pelo_decorator",
    start_date=datetime(2021, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=['decorator-style']
)
def generate_dag():
    """Esta DAG é definida usando a sintaxe de decorador."""
    EmptyOperator(task_id="task_no_decorator")


# =================
# generate_dag is a function to instantiate
# a DAG and register the instantiation in airflow.
generate_dag()

# =================
# DAG2 is defined with a the syntax 'with'.
# this syntax is called a context manager.
with DAG(
    dag_id="my_daily_dag",
    start_date=datetime(2021, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=['with-style']
):



TASK_NOWITH = EmptyOperator(task_id="task_nowith")
