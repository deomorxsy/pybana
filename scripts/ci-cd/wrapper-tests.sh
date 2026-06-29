#!/bin/sh

# Github Token PAT
GITHUB_PAT="${secrets_GITHUB_PAT}"

pip install "git+https://${GT_PAT}@github.com/acmeorg/pybana.git@main#subdirectory=dags"
