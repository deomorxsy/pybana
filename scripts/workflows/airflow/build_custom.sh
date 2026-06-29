#!/bin/sh

# Debug custom image for Airflow (qdrant + spark providers)
custom_runner_debug() {

CCR_MODE="checker" . ./scripts/ccr.sh && docker run --user root --rm -it --entrypoint=/bin/bash apache/airflow:3.0.2


}


# Build custom image for airflow
custom_build() {

COMPOSE_PATH="./compose.yml"
HARBOR_NAMESPACE="airflow-custom"
HARBOR_HOSTNAME="d0-registry.acmeorg.io"
IMAGE_TO_PUSH="$HARBOR_HOSTNAME/$HARBOR_NAMESPACE/airflow-custom_spark-qdrant:latest"

# login into Harbor private registry
if checker; then
    if ! docker login "$HARBOR_HOSTNAME"; then
        echo "|> Error: could not login into he harbor private registry."
    fi
fi

# Build, tag and push custom image
if [ "${PWD}" = "$HOME/cluster/pybana" ] && [ -f "$COMPOSE_PATH" ]; then


    # Build custom airflow image
    if ! ( checker && docker compose -f "$COMPOSE_PATH" --progress=plain build --no-cache airflow ) ; then
        echo "|> Error: could not build the airflow image from the $COMPOSE_PATH file."
        #return 1
    else
        echo "|> Finished."
    fi
fi

     # Tag custom airflow image
     if ! ( checker && docker tag localhost:5000/airflow-custom_spark-qdrant:latest "$IMAGE_TO_PUSH" ); then
         echo "|> Error: could not tag the airflow image."
         # return 1
     fi

     # Push custom airflow image
     if ! ( checker && docker login $HARBOR_HOSTNAME --username admin && docker push $IMAGE_TO_PUSH ); then
         echo "|> Error: could not push image to the Harbor registry."
         return 1
     fi

}

