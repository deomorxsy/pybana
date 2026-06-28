#!/bin/python3

# depends on ilum-core being exposed

import os
import sys
from random import random
from operator import add

from pyspark.sql import SparkSession

user = os.getenv("DAGS_AFW_SPARKSESSION_USER")
passwd = os.getenv("DAGS_AFW_SPARKSESSION_PASSWD")

cluster_ip = os.getenv("DRIVA_CLUSTER_0")


if __name__ == "__main__":
    spark = SparkSession \
        .builder \
        .remote(f"sc://{cluster_ip}:6443") \
        .config("spark.kubernetes.namespace", "ilum") \
        .config("spark.driver.extraJavaOptions",
                (f"-Dhttp.auth.preference=basic"
                 f"-Dbasic.auth.username={user}"
                 f"-Dbasic.auth.password={passwd}")) \
        .appName("PythonPi") \
        .getOrCreate()

# .config("spark.hadoop.fs.s3a.access.key", user) \
# .config("spark.hadoop.fs.s3a.secret.key", passwd) \

    partitions = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    n = 100000 * partitions

    def f(_: int) -> float:
        x = random() * 2 - 1
        y = random() * 2 - 1
        return 1 if x ** 2 + y ** 2 <= 1 else 0

    count = spark.sparkContext \
        .parallelize(range(1, n + 1), partitions).map(f).reduce(add)

    print("Pi is roughly %f" % (4.0 * count / n))

    spark.stop()
