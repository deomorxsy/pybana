#!/bin/python3

from pyspark.sql.types import StringType, ArrayType, LongType, StructField, StructType, IntegerType, BooleanType, DateType
from pyspark.sql.window import Window
from pyspark import SparkConf
from unicodedata import normalize
import pyspark.sql.functions as F
import re
import datetime
import sqlalchemy
import s3fs
import pandas as pd
from unidecode import unidecode
import papermill as pm

import os

# import sparkwrapper
from spark_wrapper import SparkWrapper
# from spark_wrapper.spark_wrapper import SparkWrapper
from dotenv import load_dotenv
load_dotenv()


# Set AWS environment variables
ak = os.getenv("DAGS_AWS_ACCESS_KEY")
sk = os.getenv("DAGS_AWS_SECRET_KEY")
ep = os.getenv("DAGS_AWS_ENDPOINT_URL")

# Set postgres environment variables
pg_user = os.getenv("DAGS_AFW_PG_USER")
pg_pwd = os.getenv("DAGS_AFW_PG_PWD")
pg_host = os.getenv("DAGS_AFW_PG_HOST")
pg_port = os.getenv("DAGS_AFW_PG_PORT")
pg_db = os.getenv("DAGS_AFW_PG_DB")
pg_schema_table = os.getenv("DAGS_AFW_PG_SCHEMA")

# Parquet URI
parquet_uri = os.getenv("DAGS_PARQUET_S3_URI")

sw = SparkWrapper(num_cores=1, memory_gb=2) \
    .set_s3_conf(ak, sk, ep) \
    .set_pg_conf(pg_user, pg_pwd, pg_host, pg_port, pg_db)

spark = sw.create_session()

input_path="./sparkmagic_livy.ipynb"


# %%
df = spark.read.parquet(parquet_uri)
df.show()
# %%
# postgres
schema_table = pg_schema_table
df = sw.read_pg(schema_table=schema_table)
df.show()
