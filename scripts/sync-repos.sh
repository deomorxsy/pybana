#!/bin/sh

DEST_DIR="../forks/pybana_commits/"
CURRENT_DIR=$(basename "$PWD")


normal() {

CURR_DIR_USER="deomorxsy"
CURR_DIR_REPO="pybana"

DEST_DIR_USER="acmeorg"
DEST_DIR_REPO="pybana"

    find "$DEST_DIR" -type f -exec sed -i "s|$CURR_DIR_USER/$CURR_DIR_REPO|$DEST_DIR_USER/$DEST_DIR_REPO|g" {} +

}

airflow() {

CURR_DIR_REPO="pybana"

if [ "$CURRENT_DIR" = "$CURR_DIR_REPO" ]; then
# Overall compose
cp ./compose.yml "$DEST_DIR"

# Airflow related
cp -r ./deploy/k8s/airflow/   "$DEST_DIR"/deploy/k8s/
cp ./scripts/airflowpvc.sh "$DEST_DIR"/scripts/
cp ./scripts/afw_gitsync.sh "$DEST_DIR"/scripts/

printf "\n\n========\n|> Repositories synchronized with success.\n\n"

else
    printf "\n\n|> Wrong directory! Change to the root of the repository first. Exiting now...\n\n"
fi

normal

}
