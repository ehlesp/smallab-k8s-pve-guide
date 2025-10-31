# G018 - K3s cluster setup 01 ~ Requirements and arrangement

- [Gearing up for your K3s cluster](#gearing-up-for-your-k3s-cluster)
- [Requirements for the K3s cluster and the services to deploy in it](#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it)
  - [Rancher K3s Kubernetes cluster](#rancher-k3s-kubernetes-cluster)
  - [Seafile](#seafile)
  - [Gitea](#gitea)
  - [Kubernetes cluster monitoring stack](#kubernetes-cluster-monitoring-stack)
    - [Prometheus](#prometheus)
    - [Grafana](#grafana)
- [Arrangement of VMs and services](#arrangement-of-vms-and-services)
- [References](#references)
  - [About Kubernetes](#about-kubernetes)
  - [About Rancher K3s](#about-rancher-k3s)
  - [About Seafile](#about-seafile)
  - [About Gitea](#about-gitea)
  - [About Prometheus](#about-prometheus)
  - [About Grafana](#about-grafana)
- [Navigation](#navigation)

## Gearing up for your K3s cluster

With your Proxmox VE standalone node ready, you can start building your private cloud of services. The idea is to setup first a Kubernetes K3s cluster running on KVM virtual machines. Then, you would deploy the apps and services you want in that Kubernetes cluster.

## Requirements for the K3s cluster and the services to deploy in it

Let's go over the list of services this guide aims to run in the K3s cluster, and check their requirements. This is necessary to plan in advance how to distribute the hardware resources available in the Proxmox VE server among the virtual machines that will act as nodes of the K3s cluster.

### Rancher K3s Kubernetes cluster

[Kubernetes](https://kubernetes.io/), also known as K8s, is an open-source platform for automating deployment, scaling, and management of containerized applications. It can be run as one single node, but to have a more realistic K8s experience it's better to run a cluster of, at least, **three VMs**.

Since the virtual hardware I'm using in this guide series is rather limited, instead of using the official K8s binaries, I'll use the [Rancher K3s Kubernetes distribution](https://k3s.io/). It's a Kubernetes distribution originally designed for resource-constrained ("edge") environments. It is compact, lightweight and already comes with the minimum necessary addons to start running right away. It's [minimum hardware requirements](https://docs.k3s.io/installation/requirements#hardware) are the following.

|  Node  |   CPU   |  RAM   |
|:------:|:-------:|:------:|
| Server | 2 cores |  2 GB  |
| Agent  | 1 core  | 512 MB |

### Seafile

[Seafile](https://www.seafile.com/) is a software mainly for file syncing and sharing, so its main requirement will always be storage room for saving data. The version that this guide deploys is the Community Edition (CE), which has its own [minimal system requirements](https://manual.seafile.com/latest/setup/system_requirements/):

- RAM: 2GB.
- CPU : 2 cores with more than 2GHz.
- Database: MariaDB.
- Caching platform: Redis.

### Gitea

[Gitea](https://gitea.io/) is a lightweight self-hosted git service, so its main requirement will be storage space:

- Database: PostgreSQL (>= 12), MySQL (>= 8.0), MariaDB (>= 10.4), SQLite (builtin), and MSSQL (>= 2012 SP4).
- Git version >= 2.0.
- A functioning SSH server to make connections through SSH rather than HTTPS.
- In the official Gitea docs there's no minimum or recommended hardware requirements specified.

### Kubernetes cluster monitoring stack

For monitoring the K3s Kubernetes cluster, you will install a stack which includes **Prometheus** and **Grafana**, among other monitoring modules.

#### Prometheus

[Prometheus](https://prometheus.io/) is a popular open-source systems monitoring and alerting toolkit. There aren't minimal or recommended requirements for Prometheus, since it completely depends on how many systems Prometheus will monitor. Still, it'll need storage for saving metrics.

#### Grafana

[Grafana](https://grafana.com/) is an open source visualization and analytics platform that is commonly used to visualize Prometheus data. Grafana provides out-of-the-box support for Prometheus, so it only makes sense to use these two tools together. The [minimum hardware requirements for Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/installation/#hardware-recommendations) are:

- Database: SQLite 3, MySQL 8.0+, PostgreSQL 12+.
- RAM: 512 MiB.
- CPU: 1 core.

## Arrangement of VMs and services

Now that you have a rough idea about what each software requires, it's time to stablish a proper arrangement for them. So, in my virtual hardware of four-single-threaded cores CPU and 8 GiB of RAM, I'll go with three VMs with the hardware configuration listed next:

- **One VM with 2 vCPU and 1.50 GiB of RAM**\
  This will become the K3s **server** (_master_) node of the Kubernetes cluster.

- **Two VMs with 3 vCPU and 2 GiB of RAM**\
  These will be K3s **agent** (_worker_) nodes where most of the Kubernetes pods will run.

If your hardware setup has more RAM and cores than the one used in this guide, you can consider either putting more VMs in your system or just assigning them more RAM and vCPUs. Also, since all your VMs will run on the same host, Proxmox VE will be able to use [**KSM and Auto-Ballooning** for a more efficient and dynamic shared use of RAM among them](https://pve.proxmox.com/wiki/Dynamic_Memory_Management).

## References

### About [Kubernetes](https://kubernetes.io/)

- [Getting Started. Production Environment](https://kubernetes.io/docs/setup/production-environment/)

### About [Rancher K3s](https://k3s.io/)

- [Docs. Installation. Requirements](https://docs.k3s.io/installation/requirements#hardware)

### About [Seafile](https://www.seafile.com/)

- [Seafile Admin Manual](https://manual.seafile.com/latest/)
  - [Setup. System requirements](https://manual.seafile.com/latest/setup/system_requirements/)

### About [Gitea](https://gitea.io/)

- [Gitea. Docs. Installation](https://docs.gitea.com/category/installation)

### About [Prometheus](https://prometheus.io/)

- [Prometheus Docs - Overview](https://prometheus.io/docs/introduction/overview/)
- [How much RAM does Prometheus 2.x need for cardinality and ingestion?](https://www.robustperception.io/how-much-ram-does-prometheus-2-x-need-for-cardinality-and-ingestion)

### About [Grafana](https://grafana.com/)

- [Grafana documentation. Set up. Install Grafana. Hardware recommendations](https://grafana.com/docs/grafana/latest/setup-grafana/installation/#hardware-recommendations)
- [Grafana documentation. Set up. Install Grafana. Supported databases](https://grafana.com/docs/grafana/latest/setup-grafana/installation/#supported-databases)

## Navigation

[<< Previous (**G017. Virtual Networking**)](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G019. K3s cluster setup 02**) >>](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md)
