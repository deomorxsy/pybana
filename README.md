### Pybana
> a k8s cluster deployment POC for Spark clusters workflow management with Airflow on k8s.

[![airflow](https://github.com/deomorxsy/pybana/actions/workflows/afw.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/afw.yml)

Featuring:
- [X] [ilum](https://github.com/ilum-cloud/doc): a Spark distribution for big data computing engine for larger-than-memory datasets, natively built for k8s
- [X] [Airflow](https://airflow.apache.org/docs/): Spark workspace management
  - ingress: using nginx
  - pvc managed by [OpenEBS](https://openebs.io/): Persistent Volume Claims so Airflow can be able to read exported DAGs (Directed Acyclic Graphs).
  - qdrant: an Open-Source Vector Database and Vector Search Engine written in Rust.
- [X] [k8s](https://kubernetes.io/docs/home/): cluster manager
  - [X] ArgoCD: a k8s controller for GitOps-based synchronization, ensuring desired state enforcement and supporting specific lifecycle hooks defined in a repository
  - [ ] ARC (Actions Runner Controller): an operator for self-hosted github runner

