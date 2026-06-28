### Pybana
> a k8s deployment POC for clustering/streaming and workflow management with Spark and Airflow.

[![airflow](https://github.com/deomorxsy/pybana/actions/workflows/afw.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/afw.yml)
[![ilum](https://github.com/deomorxsy/pybana/actions/workflows/ilum.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/ilum.yml)
[![airflow](https://github.com/deomorxsy/pybana/actions/workflows/airflow.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/airflow.yml)
[![harbor](https://github.com/deomorxsy/pybana/actions/workflows/harbor.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/harbor.yml)
[![keycloak](https://github.com/deomorxsy/pybana/actions/workflows/keycloak.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/keycloak.yml)
[![netbird](https://github.com/deomorxsy/pybana/actions/workflows/netbird.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/netbird.yml)
[![arc](https://github.com/deomorxsy/pybana/actions/workflows/arc.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/arc.yml)
[![budibase](https://github.com/deomorxsy/pybana/actions/workflows/budibase.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/budibase.yml)
[![n8n](https://github.com/deomorxsy/pybana/actions/workflows/n8n.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/n8n.yml)
[![openebs](https://github.com/deomorxsy/pybana/actions/workflows/openebs.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/openebs.yml)
[![qdrant](https://github.com/deomorxsy/pybana/actions/workflows/qdrant.yml/badge.svg)](https://github.com/deomorxsy/pybana/actions/workflows/qdrant.yml)

Featuring:

- [X] [Kubernetes](https://kubernetes.io/docs/home/): cluster manager
  - [X] Private Registry: [Harbor], an open source registry that secures artifacts with policies and role-based access control, ensures images are scanned and free from vulnerabilities.
  - [X] Continuous Delivery: [ArgoCD], a k8s controller for GitOps-based synchronization, ensuring desired state enforcement and supporting specific lifecycle hooks defined in a repository
  - [ ] Continuous Integration: [ARC (Actions Runner Controller)], an operator for self-hosted github runner
- [X] [ilum](https://github.com/ilum-cloud/doc): an Apache Spark distribution for big data computing engine for larger-than-memory datasets, natively built for k8s, which acts as its cluster manager.
    - the aio chart comes with:
        - Airflow
        - n8n
        - sparkmagic/livy-proxy
        - Jupyter-Notebook
        - Gitea

 - [X] Workflows
    - [X] [Airflow](https://airflow.apache.org/docs/): workflow management and DAG scheduler for CI. Can trigger GHA/ARC.
        - ingress: using nginx
        - pvc managed by [OpenEBS](https://openebs.io/): Persistent Volume Claims so Airflow can be able to read exported DAGs (Directed Acyclic Graphs).
        - qdrant: an Open-Source Vector Database and Vector Search Engine written in Rust.
    - [X] budibase: self-hosted, low-code automating platform. [couchdb]
    - [X] n8n: a self-hosted, low-code automating platform
- [X] [openEBS] for dynamically provisioning of storage with PVC (PersistentVolumeClaims) using CAS (Container Attached Storage).
    - [X] hostpath: a RWO (ReadWriteOnce) PersistentVolume
    - [X] [Mayastor] NFS PV: makes it possible to have a shared volume mounted atop of the read-only based on NFS (Network File System).
- [X] ingress-nginx-controller: this one exposes ClusterIP services across the cluster through a Nodeport Service type.

- [X] Keycloak: for AIM (Access and Identity Management)
- [X] Crossplane: makes it possible for external authenticators outside of the scope of k8s.
- [X] Netbird: creates an encrypted tunnel for the remote connection.



### Guidelines for contributing

1. Fork this repository
2. Clone the forked repository at your profile
3. Do not commit directly on main.
4. Create a branch with the following prefix names:
    - fix: for fixes
    - chore: for organization
    - feat: for features
5. The naming in the 3rd point also is adopted for commits. Below are other names but the general idea can be reproduced from [gitmoji](https://gitmoji.dev/), with or without the emojis.
    - break: when committing probablybreak changes

### Instructions for managing the environment

1. The compose.yml at the root of the project is for builds and tests outside of k8s. Build, push the image to a registry and then pull with kubernetes.
2. The manifests are to be applied by ArgoCD, ideally in a new repository. This one is used for preprocessing ONLY, in CI steps. ARC can be leveraged.

#### Secrets management

Secrets have two main contexts:
- GHA/ARC: Github Actions, Actions Runner Workflow
- Local, development context

Ideally we should follow the steps:
1. clone the pybana repository at ```/home/debian/cluster/```.
2. There is a sed script that will be used to handle secret context switch. This variable handles it:
```sh
SEC_SED="/home/debian/cluster/pybana/scripts/rep-secrets.sed"
```
3. the second part is delegated to a shellscript defining only the secrets. This one should be managed by the manager of the infrastructure team, and be locked inside bitwarden. Then distribute the secrets for each service, and regenerate them at each task. A model for this can be found in ```./scripts/secrets/```
