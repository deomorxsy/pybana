### Airflow deploy on k8s

This deployment is composed by the following:
- ingress: using nginx
- pvc: Persistent Volume Claims so Airflow can be able to read exported DAGs (Directed Acyclic Graphs).
- qdrant: an Open-Source Vector Database and Vector Search Engine written in Rust.
