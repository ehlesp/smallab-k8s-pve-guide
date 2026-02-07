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
  - [Declaring the resources](#declaring-the-resources)
    - [Static IP address pool](#static-ip-address-pool)
    - [Kustomize manifest](#kustomize-manifest)
  - [Deploying MetalLB](#deploying-metallb)
- [MetalLB's Kustomize project attached to this guide](#metallbs-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders on remote kubectl client](#folders-on-remote-kubectl-client)
  - [Files on remote kubectl client](#files-on-remote-kubectl-client)
- [References](#references)
  - [MetalLB](#metallb)
  - [Kustomize](#kustomize)
  - [Other contents regarding Kustomize](#other-contents-regarding-kustomize)
- [Navigation](#navigation)

## MetalLB as the load balancer of choice

You have your K3s cluster up and running, but it is missing a crucial component: a load balancer.

The previous [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file) made you disable the default one because here you will deploy a more capable and popular alternative called [MetalLB](https://metallb.io/).

## Considerations before deploying MetalLB

Before you can deploy MetalLB in your K3s cluster, there are certain points you must consider first.

### Choosing the right mode of operation for MetalLB

MetalLB can work in one of these two modes:

- [**Layer 2 (_L2_)**](https://metallb.io/concepts/layer2/).
- [**BGP**](https://metallb.io/concepts/bgp/).

The layer 2 option is the one that fits your K3s cluster, and is the most simple and straightforward mode to configure and run. BGP, on the other hand, requires a more complex setup (including network traffic routing) more appropriate for large Kubernetes clusters.

### Reserve an IP range for services

You need to reserve a range, continuous if possible, of free IP addresses in your network. MetalLB, in layer 2 mode, will then assign IPs to each service you expose directly through it. This is to avoid collisions between services that happen to use the same ports, like the widely used 80 or 443. There is also the possibility of assigning just one IP to the load balancer, but it would imply micromanaging the ports of each service you deploy in your K3s cluster.

On the other hand, remember that you have configured your cluster to use two networks, one for internal communications and other to face the external network. You only have to reserve an IP range in your external network (your LAN), since the internal communications will remain within your cluster. You have to ensure having enough IPs available for your services, something that could be problematic in your external network, since it is also where your other devices are connecting to.

You have two ways to deal with the issue of possible IP conflicts between your devices and the apps exposed to your LAN by MetalLB:

- **Assign static IPs to all devices in your LAN**\
  Doable although cumbersome since this demands the manual handling of all IP assignments in your LAN. Still, this is the one that can almost (if you also leave the dynamic IP assignment enabled, conflicts may still happen) guarantee that your devices and apps will not collide in their IP assignments. If you opt to this method, be sure of clearing a range of IPs in your router (meaning, do not assign any IP from that range to any device) that MetalLB can use freely.

- **Making your private network assign IPs from the `10.0.0.0/8` range**\
  As I already explained [back in chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-ips), for my LAN I opted to use the biggest IPv4 range available for private networks: `10.0.0.0/8`. Still, this measure only mitigates the possibility of conflict between a device and a service exposed by MetalLB (or just with another device). This also depends on how capable your LAN's router is handling IP assignments. The good thing is that you do not have to manage manually the IPs assigned to your devices.

In my case, I opted to "risk it" and stick with the dynamic IP assignment to allow devices to connect with randomized MACs, which is the default behavior nowadays.

### Ports used by MetalLB

When using the L2 operation mode, MetalLB requires the `7946` port open both in TCP and UDP in all your cluster's nodes, but only for internal communications among the MetalLB-related processes running on them. This `7946` port will be seen only in the internal network that runs through your isolated `vmbr1` bridge. Therefore, you do not have to worry about adding specific firewall rules to open this port on your K3s cluster nodes.

### Deploying from an external `kubectl` client

In the previous [chapter **G026**](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) you prepared an external `kubectl` client system for managing remotely your K3s cluster. Just don't forget to have such client ready and always use it for handling your K3s cluster. This and following chapters will assume that you're using this `kubectl` client system.

## Choosing the IP ranges for MetalLB

You have to choose an IP range on the external network your K3s cluster is connected to. This IP range should leave out the IPs already used by the K3s nodes themselves, helping you in keeping the nodes differentiated from the services deployed in them.

In this chapter, the chosen IP subrange "reserved" for MetalLB is `10.7.0.1-10.7.0.20`. It only has twenty IPs, and you may be wondering why so few. The reason is that this guide will show you how to access the services you deploy not by assigning them a specific IP, but through the Traefik ingress service already running in your K3s cluster. The main exception to this is the Traefik service itself, which needs its own external IP to be reachable to do its job. In general, you either expose services directly through an external IP assigned by the load balancer or make them reachable through the ingress service, **never in both ways at the same time**.

> [!IMPORTANT]
> **The bigger the reserved IP range, the greater the risk of having IP conflicts**\
> In a private network where IPs are dynamically assigned to devices, you want to keep the MetalLB IP range as small as possible to reduce the chance of IP conflicts.

Also notice that the IP range starts with the `10.7.0.1` address rather than with the `10.7.0.0` one. Although `10.7.0.0` is a perfectly valid IP for a device within the `10.0.0.0/8` network, I had connectivity issues that went away when I used the next IP `10.7.0.1`. I suspect this may be an issue in my current router, which could be considering any IP ending in `.0` only as an address identifying a network and not some device. Be aware of this issue if you face connectivity issues when using IPs ending in `.0`, your router or access point may not be able to handle them properly.

On the other hand, know that MetalLB links IPs to services. When MetalLB moves a service from one node to another, the IP sticks to the service. Any IP within the ranges managed by MetalLB can jump from node to node of your cluster as seen fit by the load balancer.

## Deploying MetalLB on your K3s cluster

Next, see how to deploy MetalLB using `kubectl` and [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). **Kustomize** is the official Kubernetes tool for customizing resource configuration without using templates or other techniques as is done with tools such as Helm. Kustomize is already integrated in the `kubectl` command, so you do not need to install anything else in your client system.

### Preparing the Kustomize folder structure

It is better to treat each deployment as an independent project with its own folder structure. On this regard, there is the _overlay_ model [shown in the official introduction to Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/#2-create-variants-using-overlays), but I also found [another one in this "best practices" article](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/) meant for a repository-based organization of Kustomize projects. I will base the folder structures for the Kustomize projects shown in this and upcoming chapters on what is indicated in the "best practices" article.

Therefore, begin by creating a folder structure for your MetalLB deployment files as follows:

~~~sh
$ mkdir -p $HOME/k8sprjs/metallb/resources
~~~

Notice that I have created a structure of three nested folders:

- `k8sprjs`\
  Where this MetalLB and the other Kustomize projects of this guide will be kept.

- `metallb`\
  For the MetalLB deployment Kustomize project itself.

- `resources`\
  Holds MetalLB resources' YAML declaration files.

You can use any other base path instead of `$HOME` within your `kubectl` client system.

### Declaring the resources

There are certain resources you have to declare to make MetalLB work [as specified previously in this chapter](#considerations-before-deploying-metallb). This way, MetalLB will be deployed with the right configuration right away.

#### Static IP address pool

The first resource you need to declare is the pool of public Static IP addresses you want MetalLB to use when assigning public IPs to services running in your cluster:

1. In the `resources` folder, create the files `l2-ip.l2advertisement.metallb.yaml` and `default-pool.ipaddresspool.metallb.yaml`:

    ~~~sh
    $ touch $HOME/k8sprjs/metallb/resources/{l2-ip.l2advertisement.metallb.yaml,default-pool.ipaddresspool.metallb.yaml}
    ~~~

2. In `l2-ip.l2advertisement.metallb.yaml`, specify the operation mode and pool to use:

    ~~~yaml
    # Operation mode and pool list
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement

    metadata:
      name: l2-ip
    spec:
      ipAddressPools:
      - default-pool
    ~~~

    This manifest sets a specific configuration to MetalLB:

    - The kind `L2Advertisement` sets the mode used as L2.

    - The `spec.ipAddressPool` parameter points to the pools of usable IPs. In this case it is just one named `default-pool`.

3. Declare the IP address pool in `default-pool.ipaddresspool.metallb.yaml`:

    ~~~yaml
    # Default IP address pool setup
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool

    metadata:
      name: default-pool
    spec:
      addresses:
      - 10.7.0.1-10.7.0.20
    ~~~

    This manifest configures a simple pool of static IP addresses:

    - The kind `IPAddressPool` indicates that this is a MetalLB pool of IP addresses.

    - The name is the same `default-pool` one indicated in the `l2-ip.l2advertisement.metallb.yaml`.

    - The `spec.addresses` parameter is a list of IP ranges that can be expressed in different ways. This is useful when you do not have a big continuous range of IPs available in your network. For instance, you could have configured the `default-pool` IP range as:

    ~~~yaml
    ...
    spec:
      addresses:
      - 10.7.0.1-10.7.0.10
      - 10.7.0.11-10.7.0.20
    ~~~

#### Kustomize manifest

To put together the resources declared earlier with the official manifest describing MetalLB's deployment, you can use a Kustomize manifest:

1. Create the `kustomization.yaml` file where to describe the deployment of MetalLB in Kustomize format:

    ~~~sh
    $ touch $HOME/k8sprjs/metallb/kustomization.yaml
    ~~~

2. Specify all the MetalLB resources declared in the previous steps in your new `kustomization.yaml` file:

    ~~~yaml
    # MetalLB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: metallb-system

    resources:
    - github.com/metallb/metallb/config/native?ref=v0.15.2
    - resources/l2-ip.l2advertisement.metallb.yaml
    - resources/default-pool.ipaddresspool.metallb.yaml
    ~~~

    Things to notice in this manifest:

    - Kustomize manifests are identified in Kubernetes with the `Kustomization` kind.

    - This declaration is based on the one offered [in the official MetalLB documentation](https://metallb.org/installation/#installation-with-kustomize).

    - The `namespace` for all the MetalLB resources deployed in your K3s cluster is going to be `metallb-system`. The resources in this project that already have a `namespace` specified will get it changed to this one, and those who do not have one will be set to `metallb-system` too.

    - The `resources` section lists the files describing the resources used to deploy MetalLB:

      - The first item points to the official `Kustomization` declaration of MetalLB. Notice how the url also specifies which version of MetalLB to deploy: `ref=v0.15.2`.

      - The other two items point to the local YAML files you have created previously to declare the alloted IP range for MetalLB.

3. You can check how the final deployment looks like as a YAML manifest with `kubectl`:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/metallb/ | less
    ~~~

    With the `kustomize` option, `kubectl` builds the whole deployment YAML manifest resulting from processing the `kustomization.yaml` file. Since the output can be quite long, better to append a `| less` (`less` or some other text editor of your choice) to the command for getting a paginated view of the YAML.

    The command takes a moment to finish because it has to download the MetalLB manifest first, then process and combine it with the other resource files found in your client system. When you finally see the result, you will get a quite long YAML output that embeds all of the specified resources. Furthermore, you may notice in the resulting YAML that MetalLB is prepared to look for `L2Advertisement` resources automatically, which means that you do not have to explicitly tell MetalLB which one to use.

### Deploying MetalLB

Now that you have your Kustomize project ready, you're just one command away from deploying MetalLB:

~~~sh
$ kubectl apply -k $HOME/k8sprjs/metallb/
~~~

This command automatically looks for a `kustomization.yaml` file in the folder you specify. Then, `kubectl` builds the whole deployment output like with the `kustomize` option but, instead of displaying it, `kubectl` takes that YAML and directly applies it on your Kubernetes cluster. In this case, the `kubectl` command will return an output like the following.

~~~sh
namespace/metallb-system created
customresourcedefinition.apiextensions.k8s.io/bfdprofiles.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgpadvertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgppeers.metallb.io created
customresourcedefinition.apiextensions.k8s.io/communities.metallb.io created
customresourcedefinition.apiextensions.k8s.io/ipaddresspools.metallb.io created
customresourcedefinition.apiextensions.k8s.io/l2advertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/servicebgpstatuses.metallb.io created
customresourcedefinition.apiextensions.k8s.io/servicel2statuses.metallb.io created
serviceaccount/controller created
serviceaccount/speaker created
role.rbac.authorization.k8s.io/controller created
role.rbac.authorization.k8s.io/pod-lister created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/controller created
rolebinding.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
configmap/metallb-excludel2 created
secret/metallb-webhook-cert created
service/metallb-webhook-service created
deployment.apps/controller created
daemonset.apps/speaker created
ipaddresspool.metallb.io/default-pool created
l2advertisement.metallb.io/l2-ip created
validatingwebhookconfiguration.admissionregistration.k8s.io/metallb-webhook-configuration created
~~~

The lines inform about the resources created by your deployment. They could also show sporadic warnings about deprecated apis still used by the software you're installing in your cluster.

> [!IMPORTANT]
> **The deployment in the cluster may be successful, but the deployed service may have issues**\
> Be aware that, even if you do not get a lot of warnings or, worse, errors, the deployment may not have been truly successful due to issues that go beyond what Kubernetes can detect, like configuration problems specific to the deployed service.

Give MetalLB around a couple of minutes to get ready, then check with `kubectl` that it's been deployed in your cluster.

~~~sh
$ kubectl get -n metallb-system all -o wide
NAME                              READY   STATUS    RESTARTS      AGE   IP           NODE          NOMINATED NODE   READINESS GATES
pod/controller-58fdf44d87-q6l7w   1/1     Running   1 (14m ago)   15m   10.42.1.5    k3sagent02    <none>           <none>
pod/speaker-8rrkg                 1/1     Running   0             15m   172.16.2.1   k3sagent01    <none>           <none>
pod/speaker-grsdm                 1/1     Running   0             15m   172.16.2.2   k3sagent02    <none>           <none>
pod/speaker-z6dcg                 1/1     Running   0             15m   172.16.1.1   k3sserver01   <none>           <none>

NAME                              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/metallb-webhook-service   ClusterIP   10.43.126.18   <none>        443/TCP   15m   component=controller

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE   CONTAINERS   IMAGES                            SELECTOR
daemonset.apps/speaker   3         3         3       3            3           kubernetes.io/os=linux   15m   speaker      quay.io/metallb/speaker:v0.15.2   app=metallb,component=speaker

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                               SELECTOR
deployment.apps/controller   1/1     1            1           15m   controller   quay.io/metallb/controller:v0.15.2   app=metallb,component=controller

NAME                                    DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                               SELECTOR
replicaset.apps/controller-58fdf44d87   1         1         1       15m   controller   quay.io/metallb/controller:v0.15.2   app=metallb,component=controller,pod-template-hash=58fdf44d87

~~~

The MetalLB resources are all under the `metallb-system` namespace. On the other hand, you can already see the effect on your existing services of having this load balancer running in the K3s cluster.

~~~sh
$ kubectl get svc -A
NAMESPACE        NAME                      TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
default          kubernetes                ClusterIP      10.43.0.1      <none>        443/TCP                      3d5h
kube-system      kube-dns                  ClusterIP      10.43.0.10     <none>        53/UDP,53/TCP,9153/TCP       3d5h
kube-system      traefik                   LoadBalancer   10.43.174.63   10.7.0.1      80:30512/TCP,443:32647/TCP   3d5h
metallb-system   metallb-webhook-service   ClusterIP      10.43.126.18   <none>        443/TCP                      12m
~~~

From all the services you have running at this point in your K3s cluster, the `traefik` service is the one set with the `LoadBalancer` type. Now it has an `EXTERNAL-IP` address assigned from MetalLB's `default-pool`. In particular, it has got the very first available IP (`10.7.0.1`) from the `default-pool`.

> [!NOTE]
> **Traefik makes services available through its own external IP**\
> All services configured to be accessed with a Traefik-based ingress, will be reachable only through the same Traefik external IP.
>
> In other words, you will need to associate the DNS name or hostname of any service served through Traefik to the Traefik service's IP. Do this in your client systems' host file or in your LAN DNS system.

## MetalLB's Kustomize project attached to this guide

You can find the Kustomize project for this MetalLB deployment in the following attached folder:

- [`k8sprjs/metallb`](k8sprjs/metallb/)

## Relevant system paths

### Folders on remote kubectl client

- `$HOME/k8sprjs`
- `$HOME/k8sprjs/metallb`
- `$HOME/k8sprjs/metallb/resources`

### Files on remote kubectl client

- `$HOME/k8sprjs/metallb/kustomization.yaml`
- `$HOME/k8sprjs/metallb/resources/default-pool.ipaddresspool.metallb.yaml`
- `$HOME/k8sprjs/metallb/resources/l2-ip.l2advertisement.metallb.yaml`

## References

### [MetalLB](https://metallb.io/)

- [Concepts](https://metallb.io/concepts/)
  - [MetalLB in layer 2 mode](https://metallb.io/concepts/layer2/)
  - [MetalLB in BGP mode](https://metallb.io/concepts/bgp/)
- [Installation](https://metallb.io/installation/)
- [Configuration](https://metallb.io/configuration/)

- [GitHub. MetalLB](https://github.com/metallb/metallb)

### [Kustomize](https://kustomize.io/)

- [SIG CLI.](https://kubectl.docs.kubernetes.io/)
  - [Guides](guides/)
    - [Introduction. Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
  - [Reference](https://kubectl.docs.kubernetes.io/references/)
    - [kustomization. The Kustomization File](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)

- [Kubernetes Documentation. Tasks. Manage Kubernetes Objects](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
  - [Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

- [Github. Kustomize](https://github.com/kubernetes-sigs/kustomize)

### Other contents regarding Kustomize

- [Mirantis. Blog. Kustomize Tutorial: Creating a Kubernetes app out of multiple pieces](https://www.mirantis.com/blog/introduction-to-kustomize-part-1-creating-a-kubernetes-app-out-of-multiple-pieces/)
- [OpenSource.com. Modify your Kubernetes manifests with Kustomize](https://opensource.com/article/21/6/kustomize-kubernetes)
- [Open Analytics. Kustomize Best Practices](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/)

## Navigation

[<< Previous (**G026. K3s cluster setup 09**)](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G028. K3s cluster setup 11**) >>](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md)
