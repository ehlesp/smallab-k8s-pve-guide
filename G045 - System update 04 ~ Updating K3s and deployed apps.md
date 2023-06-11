# G045 - System update 04 ~ Updating K3s and deployed apps

This guide covers the procedures for updating the K3s software that runs your Kubernetes cluster, and also how to update the apps deployed in it. To do all this, you'll need to use the `kubectl` client system you used to deploy the apps on your K3s Kubernetes cluster, so have it at hand.

## Examining your K3s Kubernetes cluster

First, you need to know what version of K3s you're running in your nodes, then compare it with the latest available version. The second step is to revise the versions of the apps you have deployed in your Kubernetes cluster, then discover which ones are **not** compatible with the new version of the K3s software. This is important because some apps use Kubernetes functionality, so if you keep them in a version too old they could stop working. Also, it can happen that one app is used by others deployed in your cluster, so you'll also have to take that detail into consideration.

### _K3s software version in your nodes_

Ideally, all your nodes should be in the same version. To check this out, you can do it remotely from your `kubectl` client system as follows.

~~~bash
$ kubectl get nodes -o wide
NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP    OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
k3sserver01   Ready    control-plane,master   231d   v1.22.3+k3s1   10.0.0.1      192.168.1.21   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.5.7-k3s2
k3sagent02    Ready    <none>                 231d   v1.22.3+k3s1   10.0.0.12     192.168.1.32   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.5.7-k3s2
k3sagent01    Ready    <none>                 231d   v1.22.3+k3s1   10.0.0.11     192.168.1.31   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.5.7-k3s2
~~~

See that this command gives you not only the version of the K3s Kubernetes engine used, but also of the container runtime. As expected in this case, the nodes have all the same versions.

- K3s Kubernetes engine: `v1.22.3+k3s1`.
- Container engine: `containerd://1.5.7-k3s2`.

> **BEWARE!**  
> The K3s software goes in parallel with the Kubernetes versions, so the `v1.22.3+k3s1` value seen before implies that this K3s software is the K3s equivalent to the `v1.22.3` version of the standard Kubernetes engine.

You can also get into each of your K3s nodes through a remote shell and execute the following command.

~~~bash
$ k3s --version
k3s version v1.22.3+k3s1 (61a2aab2)
go version go1.16.8
~~~

### _K3s' most recent version_

The fastest way to see what's the most recent version of the K3s software is by going to the [K3s GitHub page](https://github.com/k3s-io/k3s) and see there which is the latest **stable** release. When I'm writing this, is the `v1.24.2+k3s2` release. Then, you should take a look to the [K3s GitHub releases page](https://github.com/k3s-io/k3s/releases) to locate any potentially breaking change between your current version and the one you want to update to. This implies reading the release information of all the versions in between.

Is also good to know which one is the latest stable release of the standard Kubernetes software. Do this by simply consulting this check [this `stable.txt` file](https://dl.k8s.io/release/stable.txt) found in the Kubernetes GitHub site. It says `v1.24.3` at the moment of typing this, meaning that K3s is just one debug version behind the official distribution.

### _`kubectl` version_

When you update your Kubernetes cluster, you also have to update the `kubectl` client program you use for managing it. To discover what version of this command you have, execute this in your `kubectl` client system.

~~~bash
$ kubectl version 
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.4", GitCommit:"b695d79d4f967c403a96986f1750a35eb75e75f1", GitTreeState:"clean", BuildDate:"2021-11-17T15:48:33Z", GoVersion:"go1.16.10", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.3+k3s1", GitCommit:"61a2aab25eeb97c26fa3f2b177e4355a7654c991", GitTreeState:"clean", BuildDate:"2021-11-04T00:24:35Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
~~~

Take a look to the `Client version` line, that's the one indicating your `kubectl` command's current version. In particular, it's the parameter `GitVersion` the one telling you that this `kubectl` client is the release `v1.22.4`, just one debug version newer than the one on the K3s nodes.

### _`kubectl`'s most recent version_

Since `kubectl` is the official tool for handling Kubernetes clusters, it's kept up with the Kubernetes distribution. As I've already indicated a bit earlier, check [this `stable.txt` file](https://dl.k8s.io/release/stable.txt) found in the Kubernetes GitHub site. It says `v1.24.3` at the moment of typing this, so that's the version of `kubectl` this guide will upgrade to.

### _Deployed apps' current version_

The fastest way to see what version of each deployed app you have in your K3s Kubernetes cluster is by using `kubectl`.

~~~bash
$ kubectl get daemonsets,replicasets,deployment,statefulset -Ao wide | less
~~~

With the command above, you'll see all the apps deployed in all namespaces. Notice that the output of the `kubectl` command above is long, so is piped to `less` for making it easier to read. The command's output in the system used in this guide is as shown below.

~~~bash
NAMESPACE        NAME                                                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE    CONTAINERS   IMAGES                            SELECTOR
metallb-system   daemonset.apps/speaker                               2         2         2       2            2           kubernetes.io/os=linux   231d   speaker      quay.io/metallb/speaker:v0.11.0   app=metallb,component=speaker
monitoring       daemonset.apps/mntr-agent-prometheus-node-exporter   3         3         3       3            3           <none>                   27d    server       prom/node-exporter:v1.3.1         app.kubernetes.io/component=exporter,app.kubernetes.io/name=node-exporter,platform=monitoring

NAMESPACE              NAME                                                       DESIRED   CURRENT   READY   AGE    CONTAINERS                  IMAGES                                                         SELECTOR
nextcloud              replicaset.apps/nxcd-cache-redis-68984788b7                0         0         0       200d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=nextcloud,pod-template-hash=68984788b7
nextcloud              replicaset.apps/nxcd-cache-redis-8457b579c5                0         0         0       195d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=nextcloud,pod-template-hash=8457b579c5
gitea                  replicaset.apps/gitea-cache-redis-56b5454648               0         0         0       195d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=gitea,pod-template-hash=56b5454648
kube-system            replicaset.apps/reflector-5f484c4868                       0         0         0       229d   reflector                   emberstack/kubernetes-reflector:6.0.42                         app.kubernetes.io/instance=reflector,app.kubernetes.io/name=reflector,pod-template-hash=5f484c4868
kubernetes-dashboard   replicaset.apps/dashboard-metrics-scraper-c45b7869d        1         1         1       228d   dashboard-metrics-scraper   kubernetesui/metrics-scraper:v1.0.7                            k8s-app=dashboard-metrics-scraper,pod-template-hash=c45b7869d
metallb-system         replicaset.apps/controller-7dcc8764f4                      1         1         1       231d   controller                  quay.io/metallb/controller:v0.11.0                             app=metallb,component=controller,pod-template-hash=7dcc8764f4
cert-manager           replicaset.apps/cert-manager-cainjector-967788869          1         1         1       229d   cert-manager                quay.io/jetstack/cert-manager-cainjector:v1.6.1                app.kubernetes.io/component=cainjector,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cainjector,pod-template-hash=967788869
monitoring             replicaset.apps/mntr-agent-kube-state-metrics-6b6f798cbf   1         1         1       27d    server                      registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.5.0   app.kubernetes.io/component=exporter,app.kubernetes.io/name=kube-state-metrics,app.kubernetes.io/version=2.5.0,platform=monitoring,pod-template-hash=6b6f798cbf
kube-system            replicaset.apps/local-path-provisioner-64ffb68fd           1         1         1       231d   local-path-provisioner      rancher/local-path-provisioner:v0.0.20                         app=local-path-provisioner,pod-template-hash=64ffb68fd
kubernetes-dashboard   replicaset.apps/kubernetes-dashboard-576cb95f94            1         1         1       228d   kubernetes-dashboard        kubernetesui/dashboard:v2.4.0                                  k8s-app=kubernetes-dashboard,pod-template-hash=576cb95f94
cert-manager           replicaset.apps/cert-manager-55658cdf68                    1         1         1       229d   cert-manager                quay.io/jetstack/cert-manager-controller:v1.6.1                app.kubernetes.io/component=controller,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cert-manager,pod-template-hash=55658cdf68
nextcloud              replicaset.apps/nxcd-cache-redis-dc766c5cb                 1         1         1       164d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=nextcloud,pod-template-hash=dc766c5cb
gitea                  replicaset.apps/gitea-cache-redis-756f467985               1         1         1       164d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=gitea,pod-template-hash=756f467985
kube-system            replicaset.apps/coredns-85cb69466                          1         1         1       231d   coredns                     rancher/mirrored-coredns-coredns:1.8.4                         k8s-app=kube-dns,pod-template-hash=85cb69466
cert-manager           replicaset.apps/cert-manager-webhook-6668fbb57d            1         1         1       229d   cert-manager                quay.io/jetstack/cert-manager-webhook:v1.6.1                   app.kubernetes.io/component=webhook,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=webhook,pod-template-hash=6668fbb57d
kube-system            replicaset.apps/traefik-74dd4975f9                         1         1         1       231d   traefik                     rancher/mirrored-library-traefik:2.5.0                         app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik,pod-template-hash=74dd4975f9
kube-system            replicaset.apps/reflector-66d8b9f685                       1         1         1       33d    reflector                   emberstack/kubernetes-reflector:6.1.47                         app.kubernetes.io/instance=reflector,app.kubernetes.io/name=reflector,pod-template-hash=66d8b9f685
kube-system            replicaset.apps/metrics-server-5b45cf8dbb                  1         1         1       230d   metrics-server              k8s.gcr.io/metrics-server/metrics-server:v0.5.2                k8s-app=metrics-server,pod-template-hash=5b45cf8dbb

NAMESPACE              NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS                  IMAGES                                                         SELECTOR
kubernetes-dashboard   deployment.apps/dashboard-metrics-scraper       1/1     1            1           228d   dashboard-metrics-scraper   kubernetesui/metrics-scraper:v1.0.7                            k8s-app=dashboard-metrics-scraper
metallb-system         deployment.apps/controller                      1/1     1            1           231d   controller                  quay.io/metallb/controller:v0.11.0                             app=metallb,component=controller
cert-manager           deployment.apps/cert-manager-cainjector         1/1     1            1           229d   cert-manager                quay.io/jetstack/cert-manager-cainjector:v1.6.1                app.kubernetes.io/component=cainjector,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cainjector
monitoring             deployment.apps/mntr-agent-kube-state-metrics   1/1     1            1           27d    server                      registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.5.0   app.kubernetes.io/component=exporter,app.kubernetes.io/name=kube-state-metrics,app.kubernetes.io/version=2.5.0,platform=monitoring
kube-system            deployment.apps/local-path-provisioner          1/1     1            1           231d   local-path-provisioner      rancher/local-path-provisioner:v0.0.20                         app=local-path-provisioner
kubernetes-dashboard   deployment.apps/kubernetes-dashboard            1/1     1            1           228d   kubernetes-dashboard        kubernetesui/dashboard:v2.4.0                                  k8s-app=kubernetes-dashboard
cert-manager           deployment.apps/cert-manager                    1/1     1            1           229d   cert-manager                quay.io/jetstack/cert-manager-controller:v1.6.1                app.kubernetes.io/component=controller,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=cert-manager
nextcloud              deployment.apps/nxcd-cache-redis                1/1     1            1           200d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=nextcloud
gitea                  deployment.apps/gitea-cache-redis               1/1     1            1           195d   server,metrics              redis:6.2-alpine,oliver006/redis_exporter:v1.32.0-alpine       app=cache-redis,platform=gitea
kube-system            deployment.apps/coredns                         1/1     1            1           231d   coredns                     rancher/mirrored-coredns-coredns:1.8.4                         k8s-app=kube-dns
cert-manager           deployment.apps/cert-manager-webhook            1/1     1            1           229d   cert-manager                quay.io/jetstack/cert-manager-webhook:v1.6.1                   app.kubernetes.io/component=webhook,app.kubernetes.io/instance=cert-manager,app.kubernetes.io/name=webhook
kube-system            deployment.apps/traefik                         1/1     1            1           231d   traefik                     rancher/mirrored-library-traefik:2.5.0                         app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik
kube-system            deployment.apps/reflector                       1/1     1            1           229d   reflector                   emberstack/kubernetes-reflector:6.1.47                         app.kubernetes.io/instance=reflector,app.kubernetes.io/name=reflector
kube-system            deployment.apps/metrics-server                  1/1     1            1           230d   metrics-server              k8s.gcr.io/metrics-server/metrics-server:v0.5.2                k8s-app=metrics-server

NAMESPACE    NAME                                            READY   AGE    CONTAINERS       IMAGES
nextcloud    statefulset.apps/nxcd-db-mariadb                1/1     200d   server,metrics   mariadb:10.6-focal,prom/mysqld-exporter:v0.13.0
gitea        statefulset.apps/gitea-server-gitea             1/1     195d   server           gitea/gitea:1.15.9
nextcloud    statefulset.apps/nxcd-server-apache-nextcloud   1/1     200d   server,metrics   nextcloud:22.2-apache,xperimental/nextcloud-exporter:0.4.0-15-gbb88fb6
gitea        statefulset.apps/gitea-db-postgresql            1/1     195d   server,metrics   postgres:14.1-bullseye,wrouesnel/postgres_exporter:latest
monitoring   statefulset.apps/mntr-ui-grafana                1/1     27d    server           grafana/grafana:8.5.2
monitoring   statefulset.apps/mntr-server-prometheus         1/1     27d    server           prom/prometheus:v2.35.0
~~~

The column you should pay attention to is the `IMAGES` one, where you can see the name and version of each deployed image specified.

### _Compatibility of deployed apps with new Kubernetes runtime and among each other_

From all the apps you've seen deployed in previous guides, when you update a Kubernetes cluster, you have to worry first about those who provide internal services for your Kubernetes cluster. Those apps usually require particular functionality from the Kubernetes API, so a change in the runtime will affect them more seriously than to a regular app or service. Let's identify the apps which can be considered critical in your K3s cluster.

- **cert-manager**: manager and provider of certificates, like the wildcard one you've used with some of your deployed apps.
    - [List of supported cert-manager releases](https://cert-manager.io/docs/installation/supported-releases/). This list specifies the versions available and with what Kubernetes versions they can run.

- **k8sdashboard**: web console that allows you to visualize and to manage, to a point, your Kubernetes cluster.
    - The compatibility with the Kubernetes runtimes is specified in the release information, in a section called `Compatibility`. For instance, see it in the [information page about the v2.6.0 release](https://github.com/kubernetes/dashboard/releases/tag/v2.6.0).
    - This app requires a **metrics-server** instance running in the cluster.

- **metallb**: the load-balancer that manages the IPs assigned to your deployed services.
    - [In this page of requirements for running metallb](https://metallb.universe.tf/#requirements) is specified the minimum version of Kubernetes supported.

- **metrics-server**: service that scrapes resource usage data from your cluster nodes and offers it through its API.
    - [This is the compatibility matrix of metrics-server](https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix).

- **reflector**: replicates secrets and config maps through namespaces, while also keeping in sync.
    - [The list of prerequisites for reflector](https://github.com/EmberStack/kubernetes-reflector#prerequisites) indicate the minimum Kubernetes runtime supported.
    - Remember that you're using reflector in your cluster to handle the secret of a certificate managed with cert-manager.

- **kube-state-metrics**: deployed within your monitoring stack, this service provides details from all the Kubernetes API objects present in a Kubernetes cluster.
    - [Here is the compatibility matrix of kube-state-metrics](https://github.com/kubernetes/kube-state-metrics#compatibility-matrix).

As I've indicated in some items from the list above, be aware of interdependencies between apps, as in the case of the k8sdashboard relying on metrics-server or the relation between reflector and cert-manager.

Regarding the rest of apps, usually they won't give you much trouble even with each other. For instance, take the case of Nextcloud. It has three main components: a cache-redis server, a database, and the Nextcloud server that runs behind a web server. Although they're connected, these applications don't really have that strong interdependencies with each other or even with Kubernetes, which gives you more flexibility to handle their updates. Still, even with this more loose margin, eventually a component could be too old to be used by another one. For instance, a web application usually connects to a database through a specific driver, and that driver will only work with certain versions of the database. This forces you to keep the components version-paired to avoid issues.

### _Versions correlation_

Below I list the current (running in the K3s cluster) and latest **stable** version, at the time of this writing, of each "critical" app identified in the previous point, and indicate which Kubernetes release they're compatible with.

- **cert-manager**:
    - current: `v1.6.1`. Compatible with Kubernetes `1.17` to `1.22`.
    - latest stable: `v1.8.2`. Compatible with Kubernetes `1.19` to `1.24`.

- **k8sdashboard**:
    - current: `v2.4.0`. Compatible with Kubernetes `1.18` to `1.21`.
    - latest stable: `v2.6.0`. Compatible with Kubernetes `1.21` to `1.24`.

- **metallb**:
    - current: `v0.11.0`. Compatible with Kubernetes `1.13` and later versions, although not explicitly specified in documentation.
    - latest stable: `v0.13.3`. Compatible with Kubernetes `1.13` or later, although not explicitly specified in documentation.

- **metrics-server**:
    - current: `v0.5.2`. Compatible with Kubernetes `1.8` and later versions.
    - latest stable: `v0.6.1`. Compatible with Kubernetes `1.19` and later versions.

- **reflector**:
    - current: `v6.1.47`.  Compatible with Kubernetes `1.14` and later versions, although not explicitly specified in documentation.
    - latest stable: `v6.1.47`.  Compatible with Kubernetes `1.14` and later versions, although not explicitly specified in documentation.
    - Both versions are compatible with cert-manager `v1.5` and later.

- **kube-state-metrics**:
    - current: `v2.5.0`. Compatible with Kubernetes `1.22` to `1.24`.
    - latest stable: `v2.5.0`. Compatible with Kubernetes `1.22` to `1.24`.

Thanks to this mapping, now you know that, before upgrading your K3s software to the latest version, first you need to upgrade `cert-manager` and `k8sdashboard` (which is already out of its supported Kubernetes version range). The other apps either are already upgraded, or are compatible with a wider range of Kubernetes runtime versions.

## Updating apps and K3s

As I've hinted in the title of this section, the first thing you'll have to do is to update the apps running in your K3s cluster. This is due to the version compatibility issue, already indicated in the previous section, between certain apps and the underlying Kubernetes runtime. If you did it the other way, you could end having old apps failing to run on a newer Kubernetes runtime they don't support.

### _Beware of the backups_

As I've warned you in the previous _System update_ guides, check first if there are backup jobs running, either in the UrBackup server or the Proxmox VE system. Only when they've finished, proceed with the update of UrBackup.

### _Consider doing a backup of your K3s node VMs_

Although you have the VMs covered by a scheduled backup job in Proxmox VE, you may like to have a more recent copy of them, just in case you need to restore them later. This way, you'll be sure of having their most recent stable state, done right before applying the updates.

### _Updating the apps_

Next, I'll give you the general points to go through when updating the apps deployed in the K3s cluster you've built in this guide series. I won't go deeper than that since each update brings its own particularities and changes, although usually between minor or debug versions you shouldn't have to do much more than incrementing the version number in the corresponding files of your kustomize projects. So, the things to do when updating one app are.

1. Check which are the current and latest stable version available, and see their compatibility with Kubernetes releases and other apps, as you've seen before in this guide.

2. Read the information of all the releases between your current version and the latest one. It wouldn't be surprising that in some version an option you're using has been deprecated, or even eliminated altogether. This release information can be found in the GitHub page for the release or in the official page of the app.

3. Revise your app's current configuration and compare it to what is available in the latest version. Again, look for deprecated, missing or changed options.

4. Modify the kustomize project used to deploy the app so it applies the necessary changes. Most of the times, you won't have to do more than updating the link to the new version's manifest in the main `kustomization.yaml` file, or just changing the version number of the image used. Still, be mindful of the possibility of changes detected in the app's latest documentation.
    > **BEWARE!**  
    > The container images for any containerized app have been usually found in [dockerhub](https://hub.docker.com/), but know that other container registries exist like [quay.io](https://quay.io/). Remember this, because sometimes a project may change where they store their container images, and you'll have to reflect that in your kustomize project.

5. When you're sure that you've prepared the kustomize project, you can then apply it with `kubectl apply -k`, as you've done several times in previous guides.

6. Check that the app works and that nothing has been "broken" in your K3s cluster.

#### **Update order of apps**

You know what steps to follow when updating any app, but in what order do you have to update them? Given the issues with their versions, you have to be careful of what you update first. Next, I give you a valid order to follow when updating the apps deployed in the K3s cluster of this guide series.

1. **Cert-manager**: deployment procedure found in [**G029** guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md).
    - Remember that cert-manager has a plugin for `kubectl` which you'll also need to update. The procedure of upgrading this plugin will be almost the same as installing it, [as is explained in the **G029** guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#installing-the-cert-manager-plugin-in-your-kubectl-client-system).

2. **Reflector**: deployment procedure found in [concrete section of **G029** guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#deploying-reflector).

3. **K8sdashboard**: deployment procedure found in [**G030** guide](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md).
    - For this one, you created two standard Kubernetes resources to enable an administrator user. Usually, you won't need to change them but nevertheless be on the lookout for changes in k8sdashboard that may affect how this app uses them.

4. **MetalLB**: deployment procedure found in [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md).
    > **BEWARE!**  
    > From the version `0.13.0` onwards, is **not** possible to configure MetalLB with configmaps as shown in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md). Check the [guide **G912** - Appendix 12](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md) to see how to adapt your MetalLB kustomize project.

5. **Metrics-server**: deployment procedure found in [**G028** guide](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md).
    > **BEWARE!**  
    > For installing this service, remember that you had to apply a patch to adjust the default configuration to something more in line with the particularities of your K3s cluster. That patch applied particular tolerations and slightly modified arguments to the `Deployment` resource of `metrics-server`, so don't forget to check that resource in the new version to see if the patch still applies as it is. For instance, the patch is still valid as is for the version `0.6.1` of metrics-server.

6. **Nextcloud platform**: deployment procedure begins with [guide **G033** - Deploying services 02 ~ Nexcloud - Part 1](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup,%20arranging%20storage%20and%20choosing%20service%20IPs.md) and finishes with [Part 5](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md).
    1. **Redis cache server**: : configuration procedure found in [guide **G033** - Deploying services 02 ~ Nextcloud - Part 2](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md).
    2. **MariaDB server**: configuration procedure found in [guide **G033** - Deploying services 02 ~ Nextcloud - Part 3](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md).
        > **BEWARE!**  
        > When you upgrade MariaDB to a new **major** version, its system and other tables have to be updated too. This is not something that happens automatically, either you do it manually following a certain procedure or you can configure your MariaDB instance to do it automatically for you. I've explained how to do it in the second, and **much** more convenient, way in the [appendix guide 15](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md).

    3. **Nextcloud server**: configuration procedure found in [guide **G033** - Deploying services 02 ~ Nextcloud - Part 4](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md).
        > **BEWARE!**  
        > Careful when updating from one **major** Nextcloud version (such as `22.0`) to another **major** that it's **not** the immediate following one (like `24.0`). Nextcloud will fail in its upgrade process if you try such version jump, and you won't be able to downgrade either, turning your Nextcloud server instance unusable (unless you recover it manually somehow).  
        > Remember always to make your Nextcloud server instance through all the major versions. In the previous example, first you would have to apply the `23.0` version image, then the `24.0` one.

        > **BEWARE!**  
        > Updating Nextcloud implies not only putting its new binaries in place, but also adapting its own database to whatever new features it comes with. This adaptation has to be done manually with a particular command, something I've explained in the [appendix guide 14](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md). 

7. **Gitea platform**: deployment procedure begins with [guide **G034** - Deploying services 03 ~ Gitea - Part 1](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) and finishes with [Part 5](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md).
    1. **Redis cache server**: : configuration procedure found in [guide **G034** - Deploying services 03 ~ Gitea - Part 2](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md).
    2. **PostgreSQL server**: configuration procedure found in [guide **G034** - Deploying services 03 ~ Gitea - Part 3](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md).
        > **BEWARE!**  
        > After updating to a new major PostgreSQL version, you'll need to apply an update to its system tables with a procedure that cannot be run in an automated way by PostgreSQL itself. Since it's rather elaborated, I've explained it in the [appendix guide 16](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md).
    3. **Gitea server**: configuration procedure found in [guide **G034** - Deploying services 03 ~ Gitea - Part 4](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md).

8. **Monitoring stack**: deployment procedure begins with [guide **G035** - Deploying services 04 ~ Monitoring stack - Part 1](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) and finishes with [Part 6](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md).
    1. **Kube State Metrics**: : configuration procedure found in [guide **G035** - Deploying services 04 ~ Monitoring stack - Part 2](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md).
        > **BEWARE!**  
        > Updating to a newer Kubernetes runtime may force you to update this service in particular.
    2. **Prometheus Node Exporter**: configuration procedure found in [guide **G035** - Deploying services 04 ~ Monitoring stack - Part 3](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md).
    3. **Prometheus server**: configuration procedure found in [guide **G035** - Deploying services 04 ~ Monitoring stack - Part 4](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md).
    4. **Grafana**: configuration procedure found in [guide **G035** - Deploying services 04 ~ Monitoring stack - Part 5](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md).

> **BEWARE!**  
> Remember that in the Nextcloud, Gitea and Monitoring stack platforms, apps like Redis or the database servers are deployed with Prometheus exporters which need to keep their compatibility. So, if you update the Redis servers, you'll may also need to update their related exporters.

The key thing here is to update first the critical apps, while the rest can be done in any order. Also realize that, usually, the only thing you'll have to do is just update the image's version number in the `kustomization.yaml` file in the kustomize project of the app you're updating, unless the update breaks with previous versions in some way (as it has happened with Nextcloud or MetalLB).

### _Updating K3s_

If at least you've updated your critical apps to a version that can work with the latest Kubernetes runtime available, then you can update the K3s software running your cluster. Next, I'll show you the most simple and direct method of updating K3s, fitting for the small cluster deployed in this guide series.

### _Careful with any running backups_

Don't forget to check first if there are backup jobs running, either in the UrBackup server or the Proxmox VE system. Only when they've finished, keep on with the K3s software update.

### _Backup your K3s node VMs_

Like when you were updating the apps, you should consider making a backup of your K3s node VMs. Of course, if you already have a very recent backup already done by the scheduled job in Proxmox VE, you can just proceed with this update.

### _Basic K3s update procedure_

Essentially, this basic procedure is just about applying the same installer command you used to deploy K3s on each node (as you did back in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md)), but with the version number updated.

1. As you've seen [earlier in this guide](#k3s-most-recent-version), get the version numbers of K3s. What I got for the setup used in this guide was the following.
    - Current K3s version in the cluster nodes: `v1.22.3+k3s1`.
    - Latest K3s stable version: `v1.24.3+k3s1`.

2. Look in the [K3s GitHub Releases page](https://github.com/k3s-io/k3s/releases) for breaking changes that may have happened between your current version and the latest one that could require an adjustment in your K3s configuration.
    - Remember that, in all your cluster nodes, the K3s configuration is found under the `/etc/rancher` folder. In particular, you should check the file `/etc/rancher/k3s/config.yaml`.

    > **BEWARE!**  
    > You'll have to check the release information of all the releases between your current version and the latest one!

3. Also related to the K3s configuration, consult the K3s documentation to see if any option you're using in the configuration has been deprecated or changed.
    - [K3s Server Configuration Reference](https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/).
    - [K3s Agent Configuration Reference](https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config/).

4. Remember that you also enabled a particular a Kubernetes beta feature about graceful shutdowns in your cluster.
    - They are two parameters enabled in a `/etc/rancher/k3s/kubelet.config` file, found in all your K3s nodes.
    - The parameters are defined in the [beta1 configuration API for the Kubernetes' kubelet component](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/).

5. With everything checked, and being sure that you have your K3s configuration prepared for the update, the first node you must update is the **SERVER** (`k3sserver01`). Open a shell as `mgrsys` and execute the following.

    ~~~bash
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.24.3+k3s1" sh -s - server
    ~~~

    Notice that I haven't told you to stop the k3s service running in the node. The installer already takes care of everything. Also be aware that, although the k3s service may restart, the pods running in the cluster won't be killed or restarted.

6. Now execute the installer in your **AGENT** nodes (`k3sagent01` and `k3sagent02`):

    ~~~bash
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.24.3+k3s1" sh -s - agent
    ~~~

    Again, here remember that the pods running in your cluster won't be killed nor restarted by the installation process. They'll just keep on running as usual.

7. To verify that all your nodes have been updated, remember that you have at least two easy ways to do so.
    - On each node, execute this.

        ~~~bash
        $ k3s --version
        k3s version v1.24.3+k3s1 (990ba0e8)
        go version go1.18.1
        ~~~

    - From your kubectl client system.

        ~~~bash
        $ kubectl get nodes -o wide
        NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP    OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
        k3sserver01   Ready    control-plane,master   233d   v1.24.3+k3s1   10.0.0.1      192.168.1.21   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.6.6-k3s1
        k3sagent01    Ready    <none>                 233d   v1.24.3+k3s1   10.0.0.11     192.168.1.31   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.6.6-k3s1
        k3sagent02    Ready    <none>                 233d   v1.24.3+k3s1   10.0.0.12     192.168.1.32   Debian GNU/Linux 11 (bullseye)   5.10.0-16-amd64   containerd://1.6.6-k3s1
        ~~~

### _Automated K3s upgrade_

There's a more elaborated way of updating your K3s nodes, which is Kubernetes-native. It automates, up to a point, the process, although it makes more sense to use it in more complex cluster setups. With the small cluster you've built with this guide series, I'd say there's little advantage on using this procedure (beyond having some practice with it).

Take a look to this method in the [official K3s documentation](https://rancher.com/docs/k3s/latest/en/upgrades/automated/), although you'll have to create a kustomize project to put everything explained there in a single and more manageable package. Also bear in mind that with your cluster, no matter what, you'll have to edit and launch this process manually every time you want to apply an update.

### _Updating the `kubectl` command_

Now that you have your K3s cluster updated, you'll have a mismatch between the version of your `kubectl` command and the Kubernetes server version it's connecting to. Check this out in your kubectl client system.

~~~bash
$ kubectl version --short
Client Version: v1.22.4
Server Version: v1.24.3+k3s1
WARNING: version difference between client (1.22) and server (1.24) exceeds the supported minor version skew of +/-1
~~~

I've used the `--short` form of the `version` function just to show you that it's available. Either way, notice the `WARNING` message about the version difference between client and server. The `kubectl` command here is behind by two minor versions, but the compatibility of `kubectl` is only guaranteed with the previous, current and upcoming stable releases. In this case, the `kubectl` command is officially compatible with the `1.21`, `1.22` and `1.23` releases. This doesn't mean that it won't work at all with `1.24`, quite the opposite, but the further the command is from the version used in the cluster, more features will be unavailable or broken.

To update this kubectl command, just repeat the steps you did [in the **G026** guide for downloading and installing the program](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#installing-kubectl-on-your-client-system), apart from removing your old `kubectl` executable file, of course.

After updating your `kubectl` command, you'll see the `version --short` output updated.

~~~bash
$ kubectl version --short
Flag --short has been deprecated, and will be removed in the future. The --short output will become the default.
Client Version: v1.24.3
Kustomize Version: v4.5.4
Server Version: v1.24.3+k3s1
~~~

In the output above you can see several changes.

- The warning at the top telling you that the `--short` option is deprecated.
- The client (kubectl) version is updated and in sync with the server version.
- There's now a line showing also the Kustomize version, which is very different from the one of the Kubernetes engine.

## References

### _K3s_

- [K3s official page](https://k3s.io/)
- [K3s GitHub page](https://github.com/k3s-io/k3s)
- [K3s GitHub Releases page](https://github.com/k3s-io/k3s/releases)
- [Upgrading your K3s cluster](https://rancher.com/docs/k3s/latest/en/upgrades/)
- [Upgrade Basics](https://rancher.com/docs/k3s/latest/en/upgrades/basic/)
- [Automated Upgrades](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

### _Kubernetes_

- [Kubelet Configuration (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)

## Navigation

[<< Previous (**G044. System update 03**)](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G046. Cleaning the system**) >>](G046%20-%20Cleaning%20the%20system.md)
