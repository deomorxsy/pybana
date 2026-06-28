.PHONY: vault
vault:
	RUNNA=vault . ./scripts/secrets/replacer.sh

.PHONY: replacer
replacer:
	RUNNA=dev_client . ./scripts/replacer.sh


.PHONY: k9s
k9s:
	sudo -E k9s --kubeconfig /etc/rancher/k3s/k3s.yaml

.PHONY: airflow
airflow:
	. /scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build airflow

.PHONY: pyarrow_livy
pyarrow_livy:
	# the ccr checker function is already built-in inside the script below
	. ./scripts/build-pyarrow-livy.sh

.PHONY: sparkmagic
sparkmagic:
	. ./scripts/ccr.sh; checker; \
		docker compose -f ./compose.yml --progress=plain build sparkmagic
