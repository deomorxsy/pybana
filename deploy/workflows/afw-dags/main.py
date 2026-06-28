#!/bin/python3

import sys
import os
import base64

from operator import add

# sparkSession is built atop of Spark's SQL.
from pyspark import SparkConf, SparkContext, random
from pyspark.sql import SparkSession

# import sparkwrapper
from spark_wrapper.spark_wrapper import SparkWrapper
from dotenv import load_dotenv
load_dotenv()

# get AWS environment variables
ak = os.getenv("AWS_ACCESS_KEY")
sk = os.getenv("AWS_SECRET_KEY")
ep = os.getenv("AWS_ENDPOINT_URL")

# get postgres environment variables
pg_user = os.getenv("PG_USER")
pg_pwd = os.getenv("PG_PWD")
pg_host = os.getenv("PG_HOST")
pg_port = os.getenv("PG_PORT")
pg_db = os.getenv("PG_DB")


sw = SparkWrapper(num_cores=1, memory_gb=2) \
    .set_s3_conf(ak, sk, ep) \
    .set_pg_conf(pg_user, pg_pwd, pg_host, pg_port, pg_db)

spark = sw.create_session()
# %%
df = spark.read.parquet('s3a://s3.bhs.io.cloud.ovh.net/ ')
# df = spark.read.parquet('s3a://acmelake/sites/silver/whois/brazil/')
df.show()
# %%
# postgres
schema_table = "redes_sociais.linkedins_crawleados"
df = sw.read_pg(schema_table=schema_table)
df.show()


def afw():
    conf = SparkConf().setAppName("AirflowRDDGenerator").setMaster("local[*]")
    sc = SparkContext(conf=conf)

    # create data sample as a list
    data = ["Apache Airflow", "k8s", "spark rdd", "data processing"]

    # create RDD from list
    rdd = sc.parallelize(data)

    # transform RDD to uppercase
    trans_rdd = rdd.map(lambda x: x.upper())

    # collect and print results
    result = trans_rdd.collect()
    result = trans_rdd.collect()
    print("Transformed RDD data:")
    for line in result:
        print(line)

    sc.stop()


# maps the
def f(_: int) -> float:
    x = random() * 2 - 1
    y = random() * 2 - 1
    return 1 if x ** 2 + y ** 2 <= 1 else 0


def session(user, passwd):
    spark = SparkSession \
            .builder \
            .remote("sc://${{ secrets.ILUM_HOST_0 }}:443") \
            .config() \
            .config("spark.hadoop.fs.s3a.access.key", user) \
            .config("spark.hadoop.fs.s3a.secret.key", passwd) \
            .config("spark.driver.extraJavaOptions",
                    (f"-Dhttp.auth.preference=basic"
                     f"-Dbasic.auth.username={user}"
                     f"-Dbasic.auth.password={passwd}")) \
            .appName("PythonPi") \
            .getOrCreate()

    # rdd = spark.sparkContext.textFile
    partitions = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    n = 100000 * partitions

    rdd_count = spark.sparkContext \
        .parallelize(
            range(1, n + 1), partitions
            ).map(f).reduce(add)

    print(f"Pi is roughly {4.0 * (rdd_count / n)}")


def main():
    print("Cell 1")
    # %%
    print("This is cell 2!")
    # %%
    print("This is the last cell!")

    # credentials
    username = "${{ secrets.SPARK_USER }}"
    password = "${{ secrets.SPARK_PASSWD }}"

    # encode in basic auth format
    auth_header = base64.b64encode(f"{username}:{password}".encode()).decode()


if __name__ == "__main__":
    main()
