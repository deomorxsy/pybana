#!/bin/python3

import boto3
import io
from io import BytesIO
from minio import Minio
from minio.error import S3Error
import sys
import os


DAGS_AFW_MINIO_AK = os.getenv("DAGS_AFW_MINIO_AK")
DAGS_AFW_MINIO_SK = os.getenv("DAGS_AFW_MINIO_SK")

# create client
print("Connect to ", sys.argv[1])
minio_server = str(sys.argv[1])
client = Minio(
        minio_server,
        access_key=f"{DAGS_AFW_MINIO_AK}",
        secret_key=f"{DAGS_AFW_MINIO_SK}",
        secure=False)


if __name__ == "__main__":
    print("MinIO client {}".format(client))
    buckets = client.list_buckets()
    for bucket in buckets:
        print(bucket.name, bucket.creation_date)
