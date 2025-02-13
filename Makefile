.PHONY: k9s
k9s:
	sudo -E k9s --kubeconfig /etc/rancher/k3s/k3s.yaml

airflow:
	. ../kjx-headless/scripts/ccr.sh; checker; \
	docker compose -f ./compose.yml --progress=plain build airflow
