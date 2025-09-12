# G027 - K3s cluster setup 10 ~ Deploying the MetalLB load balancer

- [MetalLB as the load balancer of choice](#metallb-as-the-load-balancer-of-choice)
- [Considerations before deploying MetalLB](#considerations-before-deploying-metallb)
  - [Choosing the right mode of operation for MetalLB](#choosing-the-right-mode-of-operation-for-metallb)
  - [Reserve an IP range for services](#reserve-an-ip-range-for-services)
  - [Ports used by MetalLB](#ports-used-by-metallb)
  - [Deploying from an external `kubectl` client](#deploying-from-an-external-kubectl-client)
- [Choosing the IP ranges for MetalLB](#choosing-the-ip-ranges-for-metallb)
- [Deploying MetalLB on your K3s cluster](#deploying-metallb-on-your-k3s-cluster)
  - [Preparing the Kustomize folder structure](#preparing-the-kustomize-folder-structure)
  - [Setting up the configuration files](#setting-up-the-configuration-files)
  - [Deploying MetalLB](#deploying-metallb)
- [MetalLB's Kustomize project attached to this guide](#metallbs-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders on remote kubectl client](#folders-on-remote-kubectl-client)
  - [Files on remote kubectl client](#files-on-remote-kubectl-client)
- [References](#references)
  - [MetalLB](#metallb)
  - [Kustomize](#kustomize)
- [Navigation](#navigation)

## MetalLB as the load balancer of choice

You have your K3s cluster up and running, but it is missing a crucial component: a load balancer.

I told you in the previous [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file) to disable the default one because here you will deploy a more capable and popular alternative called [MetalLB](https://metallb.io/).

## Considerations before deploying MetalLB

Before you can deploy MetalLB in your K3s cluster, there are certain points you must consider first.

### Choosing the right mode of operation for MetalLB

MetalLB can work in one of these two modes:

- [**Layer 2 (_L2_)**](https://metallb.io/concepts/layer2/).
- [**BGP**](https://metallb.io/concepts/bgp/).

The layer 2 option is the one that fits your K3s cluster, and is the most simple and straightforward mode to configure and run. BGP, on the other hand, requires a more complex setup (including network traffic routing) more appropriate for large Kubernetes clusters.

### Reserve an IP range for services

You need to reserve a range, continuous if possible, of free IPs in your network. MetalLB, in layer 2 mode, will then assign IPs to each app you expose directly through it. This is to avoid collisions between services that happen to use the same ports, like the widely used 80 or 443. There is also the possibility of assigning just one IP to the load balancer, but it would imply micromanaging the ports of each service you deploy in your K3s cluster.

On the other hand, remember that you have configured your cluster to use two networks, one for internal communications and other to face the external network. You only have to reserve an IP range in your external network (your LAN), since the internal communications will remain within your cluster. You have to ensure having enough IPs available for your services, something that could be problematic in your external network, since it is also where your other devices are connecting to.

You have two ways to deal with the issue of possible IP conflicts between your devices and the apps exposed to your LAN by MetalLB:

- **Assign static IPs to all devices in your LAN**\
  Doable although cumbersome since this demands the manual handling of all IP assignments in your LAN. Still, this is the one that can almost (if you also leave the dynamic IP assignment enabled, conflicts may still happen) guarantee that your devices and apps will not collide in their IP assignments. If you opt to this method, be sure of clearing a range of IPs in your router (meaning, do not assign any IP from that range to any device) that MetalLB can use freely.

- **Making your private network assign IPs from the `10.0.0.0/8` range**\
  As I already explained [back in chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-ips), in my LAN I chose to use the biggest IPv4 range available for private networks: `10.0.0.0/8`. Still, this measure only mitigates the possibility of conflict between a device and an app exposed by MetalLB (or just with another device). This also depends on how capable your LAN's router is when handling IP assignments. The good thing is that you do not have to manually handle the IPs assigned to your devices.

In my case, I opted to "risk it" and stick with the dynamic IP assignment because of personal convenience.

### Ports used by MetalLB

When using the L2 operating mode, MetalLB requires the `7946` port open both in TCP and UDP in all the nodes of your cluster, but only for internal communications among the MetalLB-related processes running on your cluster nodes. So, this `7946` port will be seen only in the internal network that runs through your isolated `vmbr1` bridge. This means that you do not have to worry about adding specific firewall rules to open this port on your K3s cluster nodes.

### Deploying from an external `kubectl` client

In the previous [chapter **G026**](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) you prepared an external `kubectl` client system for managing remotely your K3s cluster. Just don't forget to have such client ready and always use it for handling your K3s cluster. This and following chapters will assume that you're using this `kubectl` client system.

## Choosing the IP ranges for MetalLB

You have to choose an IP range on the external network your K3s cluster is connected to. This IP range should leave out the IPs already used by the K3s nodes themselves, helping you in keeping the nodes differentiated from the services deployed in them. In this chapter, the chosen IP subrange to "reserve" for MetalLB is `10.7.0.0-10.7.0.20`. Notice that it only has twenty one IPs, enough for the small number of apps or services that are going to be exposed with external IPs in later chapters of this guide.

> [!NOTE]
> **The bigger the range, the greater the risk of having IP conflicts**\
> In a private network where IPs are dynamically assigned to devices, you want to keep the MetalLB IP range as small as possible to reduce the chance of IP conflicts.

Also bear in mind that MetalLB links IPs to services. When MetalLB moves a service from one node to another, the IP sticks to the service. Any IP within the ranges managed by MetalLB can jump from node to node of your cluster as seen fit by the load balancer.

## Deploying MetalLB on your K3s cluster

Next, I'll show you how to deploy MetalLB using `kubectl` and [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). **Kustomize** is the official Kubernetes tool for customizing resource configuration without using templates or other techniques as is done with tools such as Helm. Kustomize is already integrated in the `kubectl` command, so you don't need to install anything else in your client system.

### Preparing the Kustomize folder structure

It is better to treat each deployment as an independent project with its own folder structure. On this regard, there is the _overlay_ model [shown in the official introduction to Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/#2-create-variants-using-overlays), but also I found [another one in this "best practices" article](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/) meant for a repository-based organization of Kustomize projects. I'll base the folder structures for the Kustomize projects you'll see in this and upcoming chapters on what is indicated in the "best practices" article.

Therefore, begin by creating a folder structure for your MetalLB deployment files as follows:

~~~sh
$ mkdir -p $HOME/k8sprjs/metallb/resources
~~~

Notice that I've created a structure of three folders:

- `k8sprjs`\
  Where the MetalLB and any future Kustomize projects can be kept.

- `metallb`\
  For the MetalLB deployment Kustomize project.

- `resources`\
  Holds MetalLB resources' configuration files.

Needless to say that you could use any other base path instead of `$HOME` within your `kubectl` client system.

### Setting up the configuration files

Now you need to create the files that describe the deployment of MetalLB:

1. In the `resources` folder, create the files `l2-ip.l2advertisement.yaml` and `default-pool.ipaddresspool.yaml`:

    ~~~sh
    $ touch $HOME/k8sprjs/metallb/resources/{l2-ip.l2advertisement.yaml,default-pool.ipaddresspool.yaml}
    ~~~

2. Edit the new `l2-ip.l2advertisement.yaml` to enter the following YAML lines in it:

    ~~~yaml
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement

    metadata:
      name: l2-ip
    spec:
      ipAddressPools:
      - default-pool
    ~~~

    This YAML indicates to MetalLB the following:

    - The kind `L2Advertisement` sets the mode used as L2.

    - The `spec.ipAddressPool` parameter points to the pools of usable IPs. In this case it is just one named `default-pool`.

3. Edit the `default-pool.ipaddresspool.yaml` file and fill it with this YAML:

    ~~~yaml
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool

    metadata:
      name: default-pool
    spec:
      addresses:
      - 10.7.0.0-10.7.0.20
    ~~~

    Here you have configured a simple pool of IPs:

    - The kind `IPAddressPool` indicates that this is just a MetalLB pool of IP addresses.

    - The name is the same `default-pool` one indicated in the `l2-ip.l2advertisement.yaml`.

    - The `spec.addresses` parameter is a list of IP ranges that can be expressed in different ways. This is useful when you do not have a big continuous range of IPs available in your network. For instance, you could have configured the `default-pool` IP range as:

    ~~~yaml
    ...
    spec:
      addresses:
      - 10.7.0.0-10.7.0.10
      - 10.7.0.11-10.7.0.20
    ~~~

4. Create the `kustomization.yaml` file that describes the deployment of MetalLB in `kustomize` format.

    ~~~sh
    $ touch $HOME/k8sprjs/metallb/kustomization.yaml
    ~~~

5. Edit your new `kustomization.yaml` file, filling it with the configuration lines below.

    ~~~yaml
    # MetalLB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: metallb-system

    resources:
    - github.com/metallb/metallb/config/native?ref=v0.15.2
    - resources/l2-ip.l2advertisement.yaml
    - resources/default-pool.ipaddresspool.yaml
    ~~~

    There are a number of things to notice in the yaml above:

    - The file is based on the one offered [in the official MetalLB documentation](https://metallb.org/installation/#installation-with-kustomize).

    - The `namespace` for all the MetalLB resources deployed in your K3s cluster is going to be `metallb-system`. The resources in this project that already have a `namespace` specified will get it changed to this one, and those who doesn't have one will be set to this one too.

    - The `resources` section lists the files describing the resources used to deploy MetalLB:

      - The first item points to the official kustomization file of MetalLB. Notice how the url also specifies which version of MetalLB to deploy: `ref=v0.15.2`.

      - The other two items point to the local YAML files you have configured previously to define the alloted IP range for MetalLB.

6. You can check how the final deployment would look as a manifest yaml with `kubectl`.

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/metallb/ | less
    ~~~

    With the `kustomize` option, `kubectl` builds the whole deployment YAML manifest resulting from processing the `kustomization.yaml` file. Since the output can be quite long, it's better to append a `| less` to the command for getting a paginated view of the YAML.

    The command takes a moment to finish because it has to download the MetalLB manifests first, then process and combine it with the other resource files found in your client system. When you finally see the result, you'll get a quite long YAML output that embeds all the specified resources. Furthermore, you may notice in the resulting YAML that MetalLB is prepared to look for `L2Advertisement` resources automatically, which means that you do not have to explicitly tell MetalLB which one to use:

### Deploying MetalLB

Now that you have your Kustomize project ready, you're just one command away from deploying MetalLB:

~~~sh
$ kubectl apply -k $HOME/k8sprjs/metallb/
~~~

This command will look for a `kustomization.yaml` file in the folder you tell it to process. Then, it builds the whole deployment output like with the `kustomize` option but, instead of displaying it, `kubectl` takes that YAML and directly applies it on your Kubernetes cluster. In this case, the `kubectl` command will return an output like the following.

~~~sh
namespace/metallb-system created
serviceaccount/controller created
serviceaccount/speaker created
Warning: policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
podsecuritypolicy.policy/controller created
podsecuritypolicy.policy/speaker created
role.rbac.authorization.k8s.io/config-watcher created
role.rbac.authorization.k8s.io/controller created
role.rbac.authorization.k8s.io/pod-lister created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/config-watcher created
rolebinding.rbac.authorization.k8s.io/controller created
rolebinding.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
configmap/config created
deployment.apps/controller created
daemonset.apps/speaker created
~~~

The lines are merely informative about the resources created by your deployment, or sporadic warnings about deprecated apis still used by the software you're installing in your cluster. So, if you don't see a lot of warnings or just errors, the deployment can be considered successful like in the output above.

Finally, you can check out how the MetalLB service is running in your cluster.

~~~sh
$ kubectl get pods -n metallb-system 
NAME                          READY   STATUS    RESTARTS   AGE
controller-7dcc8764f4-2bc78   1/1     Running   0          9m48s
speaker-28nbv                 1/1     Running   0          9m48s
speaker-2x2x5                 1/1     Running   0          9m47s
~~~

The MetalLB resources are all under the `metallb-system` namespace, such as its pods. On the other hand, you can already see in your services the effects of having this load balancer available.

~~~sh
$ kubectl get svc -A
NAMESPACE     NAME         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
default       kubernetes   ClusterIP      10.43.0.1      <none>         443/TCP                      122m
kube-system   kube-dns     ClusterIP      10.43.0.10     <none>         53/UDP,53/TCP,9153/TCP       122m
kube-system   traefik      LoadBalancer   10.43.110.37   192.168.1.41   80:30963/TCP,443:32446/TCP   11m
~~~

From all the services you have running at this point in your K3s cluster, the `traefik` service is the one set with the `LoadBalancer` type. Now it has an `EXTERNAL-IP` from the `default` address pool set in the MetalLB configmap. In particular, it has got the very first available IP in the `default` pool.

## MetalLB's Kustomize project attached to this guide

You can find the Kustomize project for this MetalLB deployment in the following attached folder:

- `k8sprjs/metallb`

## Relevant system paths

### Folders on remote kubectl client

- `$HOME/k8sprjs`
- `$HOME/k8sprjs/metallb`
- `$HOME/k8sprjs/metallb/configs`

### Files on remote kubectl client

- `$HOME/k8sprjs/metallb/kustomization.yaml`
- `$HOME/k8sprjs/metallb/configs/config`

## References

### [MetalLB](https://metallb.io/)

- [Concepts](https://metallb.io/concepts/)
  - [MetalLB in layer 2 mode](https://metallb.io/concepts/layer2/)
  - [MetalLB in BGP mode](https://metallb.io/concepts/bgp/)
- [Installation](https://metallb.io/installation/)
- [MetalLB Configuration](https://metallb.io/configuration/)

- [MetalLB on GitHub](https://github.com/metallb/metallb)

- [Install and configure MetalLB as a load balancer for Kubernetes](https://blog.inkubate.io/install-and-configure-metallb-as-a-load-balancer-for-kubernetes/)
- [Running metallb in Layer 2 mode](https://www.shashankv.in/kubernetes/metallb-layer2-mode/)
- [K8S AND METALLB: A LOADBALANCER FOR ON-PREM DEPLOYMENTS](https://starkandwayne.com/blog/k8s-and-metallb-a-loadbalancer-for-on-prem-deployments/)
- [Kubernetes Metal LB for On-Prem / BareMetal Cluster in 10 minutes](https://medium.com/@JockDaRock/kubernetes-metal-lb-for-on-prem-baremetal-cluster-in-10-minutes-c2eaeb3fe813)
- [Configure MetalLB In Layer 2 Mode](https://docs.bitnami.com/kubernetes/infrastructure/metallb/administration/configure-layer2-mode/)
- [K3s – lightweight kubernetes made ready for production – Part 1](https://digitalis.io/blog/kubernetes/k3s-lightweight-kubernetes-made-ready-for-production-part-1/)
- [How to Build a Multi-Master Kubernetes Cluster on VMware with MetalLB](https://platform9.com/blog/how-to-build-a-multi-master-cluster-on-vmware-with-metallb/)

### Kustomize

- [Introduction to Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [The Kustomization File](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)
- [Kustomize on Github](https://github.com/kubernetes-sigs/kustomize)
- [Kustomize Tutorial: Creating a Kubernetes app out of multiple pieces](https://www.mirantis.com/blog/introduction-to-kustomize-part-1-creating-a-kubernetes-app-out-of-multiple-pieces/)
- [Modify your Kubernetes manifests with Kustomize](https://opensource.com/article/21/6/kustomize-kubernetes)
- [Kustomize Best Practices](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/)

## Navigation

[<< Previous (**G026. K3s cluster setup 09**)](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G028. K3s cluster setup 11**) >>](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md)
