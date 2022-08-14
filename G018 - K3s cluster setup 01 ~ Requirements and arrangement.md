# G018 - K3s cluster setup 01 ~ Requirements and arrangement

With your Proxmox VE standalone node ready, you can start building your private cloud of services. The idea is to setup first a Kubernetes K3s cluster running on KVM virtual machines. Then, you would deploy the apps and services you want in that cluster.

## Requirements for the K3s cluster and the services to deploy in it

Let's go over the list of services I'm aiming to run in the K3s cluster, and check their requirements. This is necessary to plan in advance how to distribute the hardware resources available in the Proxmox VE server among the virtual machines that will act as nodes of the K3s cluster.

### _Rancher K3s Kubernetes cluster_

[Kubernetes](https://kubernetes.io/), also known as K8s, is an open-source platform for automating deployment, scaling, and management of containerized applications. It can be run as one single node, but to have a more realistic K8s experience it's better to run a cluster of, at least, **three** VMs.

Since the hardware I'm using in this guide series is rather limited, instead of using the official K8s binaries, I'll use the [Rancher K3s Kubernetes distribution](https://k3s.io/). It's a Kubernetes distribution designed for resource-constrained ("edge") environments, it's compact and already comes with all the necessary addons to start running right away. It's [minimum hardware requirements](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/#hardware) are the following.

- RAM: 512 MiB.
- 1 CPU.

### _Nextcloud_

[**Nextcloud**](https://nextcloud.com/) is a software for file syncing and sharing, so it's main requirement will always be storage room for saving data. Still, it has some [recommended system requirements](https://docs.nextcloud.com/server/21/admin_manual/installation/system_requirements.html) to work properly.

- Database: MySQL 8.0+ or MariaDB 10.2+.
- Webserver: Apache 2.4 with mod_php or php-fpm.
- PHP Runtime: 8.0.
- RAM: 512 MiB.

### _Gitea_

[**Gitea**](https://gitea.io/) is a lightweight self-hosted git service, so its main requirement will be storage space but [also the following](https://gogs.io/docs/installation).

- Database: MySQL (>= 5.7), PostgreSQL (>= 10), SQLite3.
- Git version >= 1.8.3.
- A functioning SSH server to make connections through SSH rather than HTTPS.
- In the official Gitea docs there's no minimum or recommended hardware requirements specified.

### _Kubernetes cluster monitoring stack_

For monitoring the K3s Kubernetes cluster, you'll install a stack which includes **Prometheus** and **Grafana**, among other monitoring modules.

#### **Prometheus**

[**Prometheus**](https://prometheus.io/) is a popular open-source systems monitoring and alerting toolkit. There aren't minimal or recommended requirementes for Prometheus, since it completely depends on how many systems Prometheus will monitor. Still, it'll need storage for saving metrics.

#### **Grafana**

[**Grafana**](https://grafana.com/) is an open source visualization and analytics platform that is commonly used to visualize Prometheus data. Grafana provides out-of-the-box support for Prometheus, so it only makes sense to use these two tools together. The minimum hardware requirements for Grafana are the ones next.

- Database: MySQL, PostgreSQL, SQLite.
- RAM: 255 MiB.
- CPU: 1 core.

## Arrangement of VMs and services

Now that we have a rough idea about what each software requires, it's time to stablish a proper arrangement for them. So, in my four-single-threaded cores CPU and 8 GiB hardware, I'll go with three VMs with the hardware configuration listed next:

- **One** VM with 2 vCPU and 1.5 GiB of RAM. This will become the K3s **server** (_master_) node of the Kubernetes cluster.

- **Two** VMs with 3 vCPU and 2 GiB of RAM. These will be K3s **agent** (_worker_) nodes where most of the Kubernetes pods will run.

If your hardware setup has more RAM and cores than mine, you can consider either putting more VMs in your system or just assigning them more RAM and vCPUs. Also, since all your VMs will run on the same host, Proxmox VE will be able to use [**KSM** for a more efficient and dynamic shared use of RAM among them](https://pve.proxmox.com/wiki/Dynamic_Memory_Management).

## References

### _Kubernetes_

- [Kubernetes](https://kubernetes.io/)

### _Rancher K3s_

- [Rancher K3s Kubernetes distribution](https://k3s.io/)

### _Nextcloud_

- [Nextcloud](https://nextcloud.com/)
- [Nextcloud system requirements](https://docs.nextcloud.com/server/21/admin_manual/installation/system_requirements.html)

### _Gogs_

- [Gogs](https://gogs.io/)
- [Gogs installation](https://gogs.io/docs/installation)

### _Prometheus_

- [Prometheus](https://prometheus.io/)
- [Prometheus Docs - Overview](https://prometheus.io/docs/introduction/overview/)
- [How much RAM does Prometheus 2.x need for cardinality and ingestion?](https://www.robustperception.io/how-much-ram-does-prometheus-2-x-need-for-cardinality-and-ingestion)

### _Grafana_

- [Grafana](https://grafana.com/)

## Navigation

[<< Previous (**G017. Virtual Networking**)](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G019. K3s cluster setup 02**) >>](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md)
