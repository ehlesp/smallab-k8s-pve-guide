# G045 - System update 04 ~ Updating K3s and deployed apps

- [Use `kubectl` to help you when updating your K3s cluster](#use-kubectl-to-help-you-when-updating-your-k3s-cluster)
- [Examining your K3s Kubernetes cluster](#examining-your-k3s-kubernetes-cluster)
  - [K3s software version in your nodes](#k3s-software-version-in-your-nodes)
  - [K3s' most recent version](#k3s-most-recent-version)
  - [`kubectl` version](#kubectl-version)
  - [`kubectl`'s most recent version](#kubectls-most-recent-version)
  - [Deployed apps' current version](#deployed-apps-current-version)
  - [Compatibility of deployed apps with new Kubernetes runtime and among each other](#compatibility-of-deployed-apps-with-new-kubernetes-runtime-and-among-each-other)
  - [Versions correlation](#versions-correlation)
- [Updating apps and K3s](#updating-apps-and-k3s)
  - [Beware of backups](#beware-of-backups)
  - [Consider doing a backup of your K3s node VMs](#consider-doing-a-backup-of-your-k3s-node-vms)
  - [Updating the apps](#updating-the-apps)
    - [Update order of apps](#update-order-of-apps)
  - [Updating K3s](#updating-k3s)
  - [Careful with any running backups](#careful-with-any-running-backups)
  - [Backup your K3s node VMs](#backup-your-k3s-node-vms)
  - [Basic K3s update procedure](#basic-k3s-update-procedure)
  - [Automated K3s upgrade](#automated-k3s-upgrade)
  - [Updating the `kubectl` command](#updating-the-kubectl-command)
- [References](#references)
  - [K3s](#k3s)
  - [Kubernetes](#kubernetes)
  - [Apps](#apps)
  - [Containers repositories](#containers-repositories)
- [Navigation](#navigation)

## Use `kubectl` to help you when updating your K3s cluster

This chapter explains the procedures for updating the K3s software that runs your Kubernetes cluster, and also how to update the apps deployed in it. To help you in all this, ready the `kubectl` client system you used to deploy the apps on your K3s Kubernetes cluster.

## Examining your K3s Kubernetes cluster

First, you need to know what version of K3s you are running in your nodes, then compare it with the latest available version. The second step is to revise the versions of the apps you have deployed in your Kubernetes cluster, then discover which ones are not compatible with the new version of the K3s software. This is important because some apps work with the Kubernetes API directly, in particular those used for monitoring the cluster. If you keep them in a too old version they could stop working properly. Also, it can happen that one app is used by others deployed in your cluster, and you have to verify if the newer version of that particular app is still compatible with those using it.

### K3s software version in your nodes

Ideally, all your nodes should be in the same version. To check this out, you can do it remotely from your `kubectl` client system as follows:

~~~sh
$ kubectl get nodes -o wide
NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
k3sagent01    Ready    <none>                 160d   v1.33.4+k3s1   172.16.2.1    10.4.2.1      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.0.5-k3s2
k3sagent02    Ready    <none>                 160d   v1.33.4+k3s1   172.16.2.2    10.4.2.2      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.0.5-k3s2
k3sserver01   Ready    control-plane,master   160d   v1.33.4+k3s1   172.16.1.1    10.4.1.1      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.0.5-k3s2
~~~

This command gives you not only the version of the K3s Kubernetes distribution used, but also of the container runtime. As expected in this case, all the nodes have the same versions:

- K3s Kubernetes distribution: `v1.33.4+k3s1`.
- Container engine: `containerd://2.0.5-k3s2`.

> [!IMPORTANT]
> **The K3s software goes in parallel with the Kubernetes versions**\
> The `v1.33.4+k3s1` value seen before implies that this K3s software is the K3s equivalent to the `v1.33.4` version of the standard Kubernetes distribution.

You can also get into each of your K3s nodes through a remote shell and execute the following command:

~~~sh
$ k3s --version
k3s version v1.33.4+k3s1 (148243c4)
go version go1.24.5
~~~

### K3s' most recent version

The fastest way to see what is the most recent version of the K3s software is by going to the [K3s GitHub page](https://github.com/k3s-io/k3s) and see there which is the latest **stable** release. At the moment of writing this, it is the `v1.35.1+k3s1` release. Then, you should take a look to the [K3s GitHub releases page](https://github.com/k3s-io/k3s/releases) to locate any potentially breaking change between your current version and the one you want to update to. This implies reading the release information of all the versions in between.

Is also good to know which one is the latest stable release of the standard Kubernetes software. Do this by simply consulting this check [this Kubernetes `stable.txt` file](https://dl.k8s.io/release/stable.txt). It says `v1.35.1` at the moment of typing this, meaning that K3s is in sync with the official distribution.

### `kubectl` version

When you update your Kubernetes cluster, you also have to update the `kubectl` client program you use for managing it. To discover what version of this command you have, execute this in your `kubectl` client system.

~~~sh
$ kubectl version 
Client Version: v1.34.1
Kustomize Version: v5.7.1
Server Version: v1.33.4+k3s1
~~~

Take a look to the `Client version` line, that's the one indicating your `kubectl` command's current version. In this case it says `v1.34.1`, meaning that is one minor (`34`) version newer than the one (`33`) on the K3s nodes and one minor version behind the official Kubernetes distribution (`35`).

### `kubectl`'s most recent version

Since `kubectl` is the official tool for handling Kubernetes clusters, it's kept up with the Kubernetes distribution. As it has been already indicated a bit earlier, check [this Kubernetes `stable.txt` file](https://dl.k8s.io/release/stable.txt). It says `v1.35.1` at the moment of typing this, so that is also the version of `kubectl` this guide will upgrade to.

### Deployed apps' current version

The fastest way to see what version of each deployed app you have in your K3s Kubernetes cluster is by using `kubectl`:

~~~sh
$ kubectl get daemonsets,replicasets,deployment,statefulset -Ao wide | less
~~~

With the command above, you can see all the apps deployed in all namespaces. Since the output of this `kubectl` command is long, it is redirected to `less` for making it easier to read. The command's output for the K3s setup deployed in this guide looks like this:

~~~sh
NAMESPACE        NAME                                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE    CONTAINERS   IMAGES                   
         SELECTOR
metallb-system   daemonset.apps/speaker                          3         3         3       3            3           kubernetes.io/os=linux   156d   speaker      quay.io/metallb/speaker:v
0.15.2   app=metallb,component=speaker
monitoring       daemonset.apps/agent-prometheus-node-exporter   3         3         3       3            3           <none>                   12d    metrics      prom/node-exporter:v1.10.
2        app.kubernetes.io/component=exporter,app.kubernetes.io/name=node-exporter,platform=monitoring

NAMESPACE        NAME                                                 DESIRED   CURRENT   READY   AGE    CONTAINERS                IMAGES                                                   
       SELECTOR
cert-manager     replicaset.apps/cert-manager-786fb48656              1         1         1       130d   cert-manager-controller   quay.io/jetstack/cert-manager-controller:v1.19.0                app.kubernetes.io/component=controller,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cert-manager,pod-template-hash=786fb48656
cert-manager     replicaset.apps/cert-manager-cainjector-5965d694d9   1         1         1       130d   cert-manager-cainjector   quay.io/jetstack/cert-manager-cainjector:v1.19.0                app.kubernetes.io/component=cainjector,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cainjector,pod-template-hash=5965d694d9
cert-manager     replicaset.apps/cert-manager-webhook-5bf5f9c8f6      1         1         1       130d   cert-manager-webhook      quay.io/jetstack/cert-manager-webhook:v1.19.0                   app.kubernetes.io/component=webhook,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=webhook,pod-template-hash=5bf5f9c8f6
kube-system      replicaset.apps/coredns-64fd4b4794                   1         1         1       160d   coredns                   rancher/mirrored-coredns-coredns:1.12.3                         k8s-app=kube-dns,pod-template-hash=64fd4b4794
kube-system      replicaset.apps/headlamp-747b5f4d5                   1         1         1       64d    headlamp                  ghcr.io/headlamp-k8s/headlamp:latest                            k8s-app=headlamp,pod-template-hash=747b5f4d5
kube-system      replicaset.apps/local-path-provisioner-774c6665dc    1         1         1       160d   local-path-provisioner    rancher/local-path-provisioner:v0.0.31                          app=local-path-provisioner,pod-template-hash=774c6665dc
kube-system      replicaset.apps/metrics-server-5f87696c77            1         1         1       147d   metrics-server            registry.k8s.io/metrics-server/metrics-server:v0.8.0            k8s-app=metrics-server,pod-template-hash=5f87696c77
kube-system      replicaset.apps/traefik-c98fdf6fb                    1         1         1       160d   traefik                   rancher/mirrored-library-traefik:3.3.6                          app.kubernetes.io/instance=traefik-kube-system,app.kubernetes.io/name=traefik,pod-template-hash=c98fdf6fb
metallb-system   replicaset.apps/controller-58fdf44d87                1         1         1       156d   controller                quay.io/metallb/controller:v0.15.2                              app=metallb,component=controller,pod-template-hash=58fdf44d87
monitoring       replicaset.apps/agent-kube-state-metrics-7f64b7f87   1         1         1       12d    agent                     registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0   app.kubernetes.io/component=exporter,app.kubernetes.io/name=kube-state-metrics,platform=monitoring,pod-template-hash=7f64b7f87

NAMESPACE        NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS                IMAGES                                                          SELECTOR
cert-manager     deployment.apps/cert-manager               1/1     1            1           130d   cert-manager-controller   quay.io/jetstack/cert-manager-controller:v1.19.0                app.kubernetes.io/component=controller,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cert-manager
cert-manager     deployment.apps/cert-manager-cainjector    1/1     1            1           130d   cert-manager-cainjector   quay.io/jetstack/cert-manager-cainjector:v1.19.0                app.kubernetes.io/component=cainjector,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cainjector
cert-manager     deployment.apps/cert-manager-webhook       1/1     1            1           130d   cert-manager-webhook      quay.io/jetstack/cert-manager-webhook:v1.19.0                   app.kubernetes.io/component=webhook,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=webhook
kube-system      deployment.apps/coredns                    1/1     1            1           160d   coredns                   rancher/mirrored-coredns-coredns:1.12.3                         k8s-app=kube-dns
kube-system      deployment.apps/headlamp                   1/1     1            1           64d    headlamp                  ghcr.io/headlamp-k8s/headlamp:latest                            k8s-app=headlamp
kube-system      deployment.apps/local-path-provisioner     1/1     1            1           160d   local-path-provisioner    rancher/local-path-provisioner:v0.0.31                          app=local-path-provisioner
kube-system      deployment.apps/metrics-server             1/1     1            1           147d   metrics-server            registry.k8s.io/metrics-server/metrics-server:v0.8.0            k8s-app=metrics-server
kube-system      deployment.apps/traefik                    1/1     1            1           160d   traefik                   rancher/mirrored-library-traefik:3.3.6                          app.kubernetes.io/instance=traefik-kube-system,app.kubernetes.io/name=traefik
metallb-system   deployment.apps/controller                 1/1     1            1           156d   controller                quay.io/metallb/controller:v0.15.2                              app=metallb,component=controller
monitoring       deployment.apps/agent-kube-state-metrics   1/1     1            1           12d    agent                     registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0   app.kubernetes.io/component=exporter,app.kubernetes.io/name=kube-state-metrics,platform=monitoring

NAMESPACE    NAME                                 READY   AGE     CONTAINERS       IMAGES
forgejo      statefulset.apps/cache-valkey        1/1     6d17h   server,metrics   valkey/valkey:9.0-alpine,oliver006/redis_exporter:v1.80.0-alpine
forgejo      statefulset.apps/db-postgresql       1/1     6d17h   server,metrics   postgres:18.1-trixie,prometheuscommunity/postgres-exporter:v0.18.1
forgejo      statefulset.apps/server-forgejo      1/1     6d17h   server           codeberg.org/forgejo/forgejo:14.0-rootless
ghost        statefulset.apps/cache-valkey        1/1     7d      server,metrics   valkey/valkey:9.0-alpine,oliver006/redis_exporter:v1.80.0-alpine
ghost        statefulset.apps/db-mariadb          1/1     7d      server,metrics   mariadb:11.8-noble,prom/mysqld-exporter:v0.18.0
ghost        statefulset.apps/server-ghost        1/1     7d      server           ghcr.io/sredevopsorg/ghost-on-kubernetes:main
monitoring   statefulset.apps/server-grafana      1/1     12d     server           grafana/grafana-dev:12.4.0-21524955964
monitoring   statefulset.apps/server-prometheus   1/1     12d     server           prom/prometheus:v3.9.1

~~~

The column you should pay attention to is the `IMAGES` one, where you can see specified the name and version of each deployed image.

### Compatibility of deployed apps with new Kubernetes runtime and among each other

From all the apps you have seen deployed in previous guides, when you update a Kubernetes cluster, you have to worry first about those who provide internal services for your Kubernetes cluster. Those apps usually require particular functionality from the Kubernetes API, so a change in the runtime can affect them more seriously than to a regular app or service. Therefore, identify the apps which can be considered critical in your K3s cluster:

- [**Cert-manager**](https://cert-manager.io/)\
  Manager and provider of certificates, like the wildcard one you have used with some of your deployed apps.

  - [List of supported cert-manager releases](https://cert-manager.io/docs/releases/)\
    This list specifies the versions available and with what Kubernetes versions they can run.

- [**Headlamp**](https://headlamp.dev/)\
  Web console that allows you to visualize and manage, to a point, your Kubernetes cluster.

  - The project does not indicate its compatibility with the Kubernetes releases.

- [**MetalLB**](https://metallb.io/)\
  The load-balancer that manages the IPs assigned to your deployed services.

  - [In this page of requirements for running MetalLB](https://metallb.io/#requirements) is specified the minimum version of Kubernetes supported.

- [**Kubernetes Metrics Server (metrics-server)**](https://github.com/kubernetes-sigs/metrics-server)\
  Service that scrapes resource usage data from your cluster nodes and offers it through its API.

  - [This is the compatibility matrix of metrics-server](https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix).

- [**Kube State Metrics**](https://github.com/kubernetes/kube-state-metrics)\
  Deployed as a component of [the monitoring stack](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md), this service provides metrics from all the Kubernetes API objects present in a Kubernetes cluster.

  - [Here is the compatibility matrix of the kube-state-metrics](https://github.com/kubernetes/kube-state-metrics#compatibility-matrix).

As pointed out in some items from the list above, be aware of interdependencies between apps, as in the case of Headlamp relying on metrics-server or the need of the monitoring stack for the metrics provided by the Kube State Metrics service.

Regarding the rest of apps, usually they should not give you much trouble even with each other. For instance, take the case of Ghost. It has three main components: a cache-valkey server, a database, and the Ghost server. Although they are connected, these applications do not really have that strong interdependencies with each other or even with Kubernetes, which gives you more flexibility to handle their updates. Still, even with this more loose margin, eventually a component could be too old to be used by another one. For instance, a web application usually connects to a database through a specific driver, and that driver can only work with certain versions of the database. This forces you to keep the components version-paired to avoid issues.

### Versions correlation

Below is the list of the current (running in the K3s cluster) and latest stable version, at the time of this writing, of each "critical" app identified in the previous point. The list also indicates which Kubernetes release each app's version is compatible with:

- **Cert-manager**

  - current: `v1.19.0`. Compatible with Kubernetes `1.31` to `1.35`.
  - latest stable: also `v1.19.0`.

- **Headlamp**

  - current: `v0.40.1`. Unknown Kubernetes compatibility.
  - latest stable: also `v0.40.1`.

- **MetalLB**

  - current: `v0.15.2`. Compatible with Kubernetes `1.13` and later versions, although not explicitly specified in documentation.
  - latest stable: `v0.15.3`. Compatible with Kubernetes `1.13` and later versions, although not explicitly specified in documentation.

- **Kubernetes Metrics Server (metrics-server)**

  - current: `v0.8.0`. Compatible with Kubernetes `1.31` and later versions.
  - latest stable: `v0.8.1`. Compatible with Kubernetes `1.31` and later versions.

- **Kube State Metrics**

  - current: `v2.18.0`. Compatible with Kubernetes `1.33` to `1.35`.
  - latest stable: also `v2.18.0`.

Thanks to this mapping, now you know that, before upgrading your K3s software to the latest version, first you need to upgrade the `metallb` and the `metrics-server` services. The other apps either are already upgraded, or are compatible with a wider range of Kubernetes runtime versions.

## Updating apps and K3s

The first thing you have to do is to update the critical apps running in your K3s cluster. This is due to the version compatibility issue, already indicated in the previous section, between certain apps and the underlying Kubernetes runtime. If you did it the other way, you could end having old apps failing to run on a newer Kubernetes runtime they don't support.

### Beware of backups

Check first if there are backup jobs running, either in the UrBackup server or the Proxmox VE system. Only when they have finished, proceed with the update of UrBackup.

### Consider doing a backup of your K3s node VMs

Although you have the VMs covered by a scheduled backup job in Proxmox VE, you may like to have a more recent copy of them, just in case you need to restore them later. This way, you can be sure of having their most recent stable state, done right before applying the updates.

### Updating the apps

Here you have the general indications to go through when updating the apps deployed in the K3s cluster built with this guide. This guide will not go deeper than that since each update brings its own particularities and changes, although usually between minor or debug versions you should not have to do much more than incrementing the version number in the corresponding files of your Kustomize projects:

1. Check which are the current and latest stable version available, and see their compatibility with Kubernetes releases and other apps, [as you have seen before right in this chapter](#versions-correlation).

2. Read the information of all the releases between your current version and the latest one. Is not uncommon to find out that an option you are using has been deprecated, or even eliminated altogether in some newer version. This release information usually can be found in the release page or in the official page of the app.

3. Revise your app's current configuration and compare it to what is available in the latest version. Again, look for deprecated, missing or changed options.

4. Modify the Kustomize project used to deploy the app so it applies the necessary changes. Most of the times, you will not have to do more than updating the link to the new version's manifest in the main `kustomization.yaml` file, or just changing the version number of the image used. Still, be mindful of the possibility detecting changes in the app's latest documentation.

    > [!NOTE]
    > **The Docker Hub is not the only container repository**\
    > The container images for any containerized app are usually found in [dockerhub](https://hub.docker.com/), but know that other container registries exist like [Quay.io](https://quay.io/).
    >
    > Remember this because, sometimes, a project may change where they store their container images. When this happens, you will have to reflect that change in your Kustomize project.

5. When you have prepared the Kustomize project, apply it with `kubectl apply -k`, as you have done in the chapters about Kustomize deployments.

6. Check that the updated app works and that nothing has been "broken" in your K3s cluster.

#### Update order of apps

You know what steps to follow when updating any app, but what is the proper order to follow when updating them? Given the issues with their versions, you have to be careful of what you update first. Next, see a valid order to follow when updating the apps deployed in this guide's K3s cluster:

1. **cert-manager**\
    Deployment procedure found in [chapter **G029**](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md).

    - Remember that cert-manager has a plugin for `kubectl` which you also need to update. The procedure of upgrading this plugin will be almost the same as installing it, [as is explained in the chapter **G029**](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#installing-the-cert-manager-plugin-in-your-kubectl-client-system).

2. **Headlamp**\
    Deployment procedure found in [chapter **G031**](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md).

    - For this one, you created two standard Kubernetes resources to enable an administrator access. Usually, you will not need to change them but be on the lookout for changes in Headlamp that may affect how this app uses them.

3. **MetalLB**\
    Deployment procedure found in [chapter **G027**](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md).

4. **Kubernetes Metrics Server (metrics-server)**\
    Deployment procedure found in [chapter **G028**](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md).

    - For deploying this service, remember you applied a patch to adjust the default configuration to something more in line with the particularities of your K3s cluster. That patch sets particular tolerations and slightly modified arguments to the `Deployment` resource of `metrics-server`. Do not forget to check if the patch resource is valid with the new version. For instance, the patch is still valid without changes for the version `0.8.1` of metrics-server.

5. **Ghost platform**\
    Deployment procedure begins with [chapter **G033** - Deploying services 02 ~ Ghost - Part 1](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) and finishes in its [Part 5](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md).

    1. **Valkey cache server**\
        Kustomize project preparation explained in [chapter **G033** - Deploying services 02 ~ Ghost - Part 2](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md).

    2. **MariaDB server**\
        Kustomize project preparation explained in [chapter **G033** - Deploying services 02 ~ Ghost - Part 3](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md).

        > [!IMPORTANT]
        > **Upgrading MariaDB to a new major version implies upgrading its system and other tables**\
        > This is not something that happens automatically. Either you do it manually following a certain procedure, or you can configure your MariaDB instance to do it automatically for you. It is explained how to do it in the second, and much more convenient, way in the [appendix chapter 11](G911%20-%20Appendix%2011%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md).

    3. **Ghost server**\
        Kustomize project preparation explained in [chapter **G033** - Deploying services 02 ~ Ghost - Part 4](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md).

6. **Forgejo platform**\
    Deployment procedure begins with [chapter **G034** - Deploying services 03 ~ Forgejo - Part 1](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) and finishes in its [Part 5](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md).

    1. **Valkey cache server**\
        Kustomize project preparation explained in [chapter **G034** - Deploying services 03 ~ Forgejo - Part 2](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md).

    2. **PostgreSQL server**\
        Kustomize project preparation explained in [chapter **G034** - Deploying services 03 ~ Forgejo - Part 3](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md).

        > [!IMPORTANT]
        > **Updating to a new major PostgreSQL version also requires updating its system tables**\
        > The update procedure for the system tables cannot be run in an automated way by PostgreSQL itself. Since it is rather elaborated, it is explained in the [appendix chapter 12](G912%20-%20Appendix%2012%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md).

    3. **Forgejo server**\
        Kustomize project preparation explained in [chapter **G034** - Deploying services 03 ~ Forgejo - Part 4](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md).

7. **Monitoring stack**\
    Deployment procedure begins with [chapter **G035** - Deploying services 04 ~ Monitoring stack - Part 1](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) and finishes in its [Part 6](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md).

    1. **Kube State Metrics**\
        Kustomize project preparation explained in [chapter **G035** - Deploying services 04 ~ Monitoring stack - Part 2](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md).

        > [!NOTE]
        > **This service is correlated with the Kubernetes runtime version**\
        > Updating to a newer Kubernetes runtime may force you to update this service in particular.

    2. **Prometheus Node Exporter**\
        Kustomize project preparation explained in [chapter **G035** - Deploying services 04 ~ Monitoring stack - Part 3](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md).

    3. **Prometheus server**\
        Kustomize project preparation explained in [chapter **G035** - Deploying services 04 ~ Monitoring stack - Part 4](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md).

    4. **Grafana**\
        Kustomize project preparation explained in [chapter **G035** - Deploying services 04 ~ Monitoring stack - Part 5](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md).

> [!IMPORTANT]
> **Remember to update the Prometheus metric exporters deployed as sidecar containers**\
> In the Ghost, Forgejo and Monitoring stack platforms, apps like Valkey or the database servers are deployed with Prometheus exporters which need to keep their compatibility. Therefore, when you update the main component in a sidecar setup, do not forget to check if the associated Prometheus metrics exporter also has to be updated to keep compatibility.

The key thing here is to update first the critical apps, while the rest can be done in any order. Also realize that, usually, the only thing you have to do is just update the image's version number in the `kustomization.yaml` file in the Kustomize project of the app you are updating, unless the update breaks with previous versions in some way.

### Updating K3s

If at least you have updated your critical apps to a version that can work with the latest Kubernetes version available, then you can update the K3s software running your cluster. Learn here about the most simple and direct method of updating K3s, fitting for the small cluster deployed in this guide.

### Careful with any running backups

Do not forget to check first if there are backup jobs running, either in the UrBackup server or the Proxmox VE system. Only after they have finished, continue with the K3s software update.

### Backup your K3s node VMs

Like when you were updating the apps, you should consider making a backup of your K3s node VMs. Of course, if you already have a very recent backup, just proceed with this update.

### Basic K3s update procedure

This basic procedure is just about applying the same installer command you used to deploy K3s on each node (as you did back in the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md)), but with the version number updated:

1. As you have seen [earlier in this chapter](#k3s-most-recent-version), get the version numbers of K3s. What corresponds for the setup used in this guide is the following:

    - Current K3s version in the cluster nodes: `v1.33.4+k3s1`.
    - Latest K3s stable version: `v1.35.1+k3s1`.

2. Look in the [K3s GitHub Releases page](https://github.com/k3s-io/k3s/releases) for breaking changes that may have happened between your current version and the latest one that could require an adjustment in your K3s configuration:

    - Remember that, in all your cluster nodes, the K3s configuration is found under the `/etc/rancher` folder. In particular, you should check the file `/etc/rancher/k3s/config.yaml`.

    > [!IMPORTANT]
    > **Beware of breaking changes between K3s releases**\
    > You have to check the release information of all the releases between your current version and the latest one.

3. Also related to the K3s configuration, consult the K3s documentation to see if any option you are using in the configuration has been deprecated or changed:

    - [K3s Server Configuration Reference](https://docs.k3s.io/cli/server).
    - [K3s Agent Configuration Reference](https://docs.k3s.io/cli/agent).

4. Remember that you also enabled a particular a Kubernetes beta feature about graceful shutdowns in your cluster:

    - They are two parameters enabled in a `/etc/rancher/k3s/kubelet.config` file, found in all your K3s nodes.

    - The parameters are defined in the [beta1 configuration API for the Kubernetes' kubelet component](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/).

5. With everything checked, and being sure that you have your K3s configuration prepared for the update, the first node you must update is the **SERVER** (`k3sserver01`). Open a shell as `mgrsys` and execute the following:

    ~~~sh
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.35.1+k3s1" sh -s - server
    ~~~

    Notice here that you do not have to stop the k3s service running in the node. The installer already takes care of everything. Also be aware that, although the k3s service may restart, the pods running in the cluster will not be killed nor restarted.

6. Now execute the installer in each of your **AGENT** nodes (`k3sagent01` and `k3sagent02`):

    ~~~sh
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.35.1+k3s1" sh -s - agent
    ~~~

    Again, here remember that the pods running in your cluster will not be killed nor restarted by the installation process. They will just keep on running as usual.

7. To verify that all your nodes have been updated, remember that you have at least two easy ways to do so:

    - On each node, get the version of the installed k3s software:

      ~~~sh
      $ k3s --version
      k3s version v1.35.1+k3s1 (50fa2d70)
      go version go1.25.6
      ~~~

    - From your `kubectl` client system:

      ~~~sh
      $ kubectl get nodes -o wide
      NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
      k3sagent01    Ready    <none>                 160d   v1.35.1+k3s1   172.16.2.1    10.4.2.1      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.1.5-k3s1
      k3sagent02    Ready    <none>                 160d   v1.35.1+k3s1   172.16.2.2    10.4.2.2      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.1.5-k3s1
      k3sserver01   Ready    control-plane,master   160d   v1.35.1+k3s1   172.16.1.1    10.4.1.1      Debian GNU/Linux 13 (trixie)   6.12.69+deb13-amd64   containerd://2.1.5-k3s1
      ~~~

### Automated K3s upgrade

There's a more elaborated way of updating your K3s nodes, which is Kubernetes-native. It automates, up to a point, the process, although it makes more sense to use it in more complex cluster setups. With the small cluster you have built with this guide, there's little advantage on using this procedure (beyond having some practice with it).

Take a look to this method in the [official K3s documentation](https://docs.k3s.io/upgrades/automated), although you have to create a kustomize project to put everything explained there in a single and more manageable package. Also bear in mind that with your cluster, no matter what, you have to edit and launch this process manually every time you want to apply an update.

### Updating the `kubectl` command

Now that you have your K3s cluster updated, you have a mismatch between the version of your `kubectl` command and the Kubernetes server version it is connecting to. Check this out in your `kubectl` client system:

~~~sh
$ kubectl version
Client Version: v1.34.1
Kustomize Version: v5.7.1
Server Version: v1.35.1+k3s1
~~~

The `kubectl` command here is behind just by one minor version, so its well within the guaranteed compatibility of `kubectl` with the previous, current and upcoming Kubernetes stable releases. In this case, the `kubectl` command is officially compatible with the `1.33`, `1.34` and `1.35` Kubernetes releases.

To update this `kubectl` command, just repeat the steps you did [in the chapter **G026** for downloading and installing the program](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#installing-kubectl-on-your-client-system), apart from removing your old `kubectl` executable file first.

After updating your `kubectl` command, you can see the `version` output updated:

~~~sh
$ kubectl version
Client Version: v1.35.1
Kustomize Version: v5.7.1
Server Version: v1.35.1+k3s1
~~~

## References

### [K3s](https://k3s.io/)

- [Documentation](https://docs.k3s.io/)
  - [Upgrades](https://docs.k3s.io/upgrades)
    - [Manual Upgrades](https://docs.k3s.io/upgrades/manual)
    - [Automated Upgrades](https://docs.k3s.io/upgrades/automated)
  - [CLI Tools](https://docs.k3s.io/cli)
    - [k3s server](https://docs.k3s.io/cli/server)
    - [k3s agent](https://docs.k3s.io/cli/agent)

- [GitHub. K3s](https://github.com/k3s-io/k3s)
  - [Releases](https://github.com/k3s-io/k3s/releases)
    - [v1.35.1+k3s1](https://github.com/k3s-io/k3s/releases/tag/v1.35.1%2Bk3s1)

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Reference](https://kubernetes.io/docs/reference/)
  - [Configuration APIs. Kubelet Configuration (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)

- [Kubernetes latest stable release version number](https://dl.k8s.io/release/stable.txt)

### Apps

- [Cert-manager](https://cert-manager.io/)
  - [Documentation. Supported Releases](https://cert-manager.io/docs/releases/)

- [Headlamp](https://headlamp.dev/)

- [MetalLB](https://metallb.io/)
  - [Requirements](https://metallb.io/#requirements)

- [GitHub. Kubernetes Metrics Server (metrics-server)](https://github.com/kubernetes-sigs/metrics-server)
  - [Installation. Compatibility Matrix](https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix)

- [GitHub. Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
  - [Versioning. Compatibility matrix](https://github.com/kubernetes/kube-state-metrics#compatibility-matrix)

### Containers repositories

- [Docker Hub](https://hub.docker.com/)
- [Quay.io](https://quay.io/)

## Navigation

[<< Previous (**G044. System update 03**)](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G046. Cleaning up your homelab system**) >>](G046%20-%20Cleaning%20up%20your%20homelab%20system.md)
