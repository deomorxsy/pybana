#!/bin/sh

JUPYTER_LIVY_TOKEN=""
curl -X GET -H "Authorization: token ${JUPYTER_LIVY_TOKEN}" "https://d0-jupyter.acme.io/api/kernels/lab?token=${JUPYTER_LIVY_TOKEN}"


