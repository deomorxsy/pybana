#!/bin/sh

#ociImage="localhost:5000/pyarrow_livy:latest"

. ./scripts/ccr.sh; checker &&
    docker compose -f ./compose.yml --progress=plain build pyarrow_livy
    # docker compose -f ./compose.yml --progress=plain build --no-cache pyarrow_livy
    #docker push "$ociImage"
    #docker run -it --name arrowlivy -d "$ociImage"
    #docker cp arrowlivy:/app/artifacts/art1.txt ./artifacts/art1.txt
