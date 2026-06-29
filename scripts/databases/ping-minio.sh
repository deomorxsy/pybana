#!/bin/sh

test_minio_connection() {


docker run -d -p 5000:5000 --name registry registry:2.8.3

(
cat <<EOF

EOF
) | tee ./artifacts/minio-tester.Containerfile && \
    \ #podman build -t localhost:5000/minio-tester:latest -f ./artifacts/minio-tester.Containerfile && \
    docker compose -f ./compose.yml --progress=plain build minio_tester
    podman push localhost:5000/minio-tester:latest
    docker stop registry && echo "OKOK!!"

}
