# G027 - K3s cluster setup 10 ~ Deploying the MetalLB load balancer

You've got your K3s cluster up and running, but it's missing a crucial component: a load balancer. I told you in the previous [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file) to disable the default one because here you'll deploy a more capable and popular alternative called [MetalLB](https://metallb.universe.tf/).

## Considerations before deploying MetalLB

Before you can deploy MetalLB in your K3s cluster, there are certain points you must consider first.

> **BEWARE!**  
> The configuration shown here is only valid for MetalLB versions **previous** to the `0.13.0` release. From that version onwards, the configuration has to be set in a different way. This doesn't meant that this whole guide is invalid, is just a change in how the configuration is specified to MetalLB. I'll remind you about this issue later in this guide, so you can apply the proper correction if you're using the `0.13.0` or superior version of MetalLB.

### _Choosing the right mode of operation for MetalLB_

MetalLB can work in one of two modes: [**layer 2**](https://metallb.universe.tf/concepts/layer2/) or [**BGP**](https://metallb.universe.tf/concepts/bgp/). The layer 2 option is the one that fits your K3s cluster, and is the most simple and straightforward to configure and run. BGP, on the other hand, requires a more complex setup (including network traffic routing) more appropriate for large Kubernetes clusters.

### _Reserve an IP range for services_

You need to have a range, a continuous one if possible, of free IPs in your network. MetalLB, in layer 2 mode, will then assign IPs to each app you expose directly through it. This is to avoid collisions between services that happen to use the same ports, like the widely used 80 or 443. There's also the possibility of assigning just one IP to the load balancer, but it would imply micromanaging the ports of each service you deploy in your K3s cluster.

On the other hand, remember that you've setup your cluster to use two networks, one for internal communications and other to face the external network. You'll only have to reserve an IP range in your external network, since the internal communications will remain within your cluster. You'll have to ensure having enough IPs available for your services, something that could be problematic in your external network, since it's also where your other devices are connecting to. So, if you haven't done it already at this point, organize your external network by assigning static IPs to all your devices, and clear a range of IPs that MetalLB can then use freely.

### _Ports used by MetalLB_

MetalLB requires the `7946` port open both in TCP and UDP in all the nodes of your cluster, but only for internal communications among the MetalLB-related processes running on your cluster nodes. So, this `7946` port will be seen only in the internal network that runs through your isolated `vmbr1` bridge. This means that you don't have to worry about adding specific firewall rules to open this port on your K3s cluster nodes.

### _Deploying from an external `kubectl` client_

In the previous [**G026** guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) you've seen how to prepare an external `kubectl` client system for managing remotely your K3s cluster. Just don't forget to have such client ready and **always** use it for handling your K3s cluster. This guide and the following ones will assume that you're using this `kubectl` client system.

## Choosing the IP ranges for MetalLB

You have to choose an IP range on the external network your K3s cluster is connected to. This IP range should leave out the IPs already used by the K3s nodes themselves, helping you in keeping the nodes differentiated from the services deployed in them. Also bear in mind that MetalLB links IPs to services, so when MetalLB moves a service from one node to another, the IP sticks to the service. So, any IP within the ranges managed by MetalLB can jump from node to node of your cluster as seen fit by the load balancer.

In the external network `192.168.1.0` used in this guide series, all the VMs created previously don't go over the IP `192.168.1.40`. Assuming that all other devices (including the Proxmox VE host) have IPs beyond `192.168.1.100`, this means that a continuous IP range available for MetalLB starts at `192.168.1.41` and can end at `192.168.1.100`.

## Deploying MetalLB on your K3s cluster

Next, I'll show you how to deploy MetalLB using `kubectl` and [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/). **Kustomize** is the official Kubernetes tool for customizing resource configuration without using templates or other techniques as is done with tools such as Helm. Kustomize is already integrated in the `kubectl` command, so you don't need to install anything else in your client system.

### _Preparing the Kustomize folder structure_

It's better to treat each deployment as an independent project with its own folder structure. On this regard, there's the _overlay_ model [shown in the official introduction to Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/#2-create-variants-using-overlays), but also I found [another one in this "best practices" article](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/) meant for a repository-based organization of Kustomize projects. I'll base the folder structures for the Kustomize projects you'll see in this and upcoming guides on what is indicated in that article.

Therefore, create a folder structure for your MetalLB deployment files as follows.

~~~bash
$ mkdir -p $HOME/k8sprjs/metallb/configs
~~~

Notice that I've created a structure of three folders:

- `k8sprjs`: where the MetalLB and any future Kustomize projects can be kept.
- `metallb`: for the MetalLB deployment Kustomize project.
- `configs`: to hold MetalLB configuration files.

Also, needless to say that you could use any other base path instead of `$HOME` in your kubectl client system.

### _Setting up the configuration files_

Now you need to create the files that describe the deployment of MetalLB.

1. MetalLB reads its configuration from a particular configuration file called `config`, so create a new empty one in the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/metallb/configs/config
    ~~~

2. Edit the new `config` and put the following yaml lines in it.

    ~~~yaml
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.41-192.168.1.80
    ~~~

    Above you can see how a pool of IPs named `default` is defined to operate with the `layer2` protocol and has a concrete IP range defined under the `addresses` parameter, corresponding with what you've seen detailed previously in this guide.

    Alternatively, you could have an address pool that include several different IP ranges, something useful if you don't have a big continuous range of IPs available in your network. For instance, you could have configured the range in the `default` pool as:

    ~~~yaml
    ...
    addresses:
    - 192.168.1.41-192.168.1.60
    - 192.168.1.61-192.168.1.80
    ~~~

3. Next, you need to create the `kustomization.yaml` file that describes the deployment of MetalLB in `kustomize` format.

    ~~~bash
    $ touch $HOME/k8sprjs/metallb/kustomization.yaml
    ~~~

4. Edit your new `kustomization.yaml` file, filling it with the configuration lines below.

    ~~~yaml
    # MetalLB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: metallb-system

    resources:
    - github.com/metallb/metallb//manifests?ref=v0.11.0

    configMapGenerator:
    - name: config
      files:
      - configs/config
      options:
        disableNameSuffixHash: true
    ~~~

    There are a number of things to notice in the yaml above.

    - The file is based on the one offered [in the official MetalLB documentation](https://metallb.org/installation/#installation-with-kustomize).

    - The `namespace` for all the MetalLB resources deployed in your K3s cluster is going to be `metallb-system`. The resources in this project that already have a `namespace` specified will get it changed to this one, and those who doesn't have one will be set to this one too.

    - In the `resources` section you see that no manifest is called directly there, but a github url with a reference to a concrete MetalLB version: `ref=v0.11.0`.

    - MetalLB requires a `ConfigMap` resource with a certain IP range configuration set in it. Instead of just creating that config map with a yaml manifest, a `configMapGenerator` is used here.
        - This Kustomize functionality allows you to generate one or more Kubernetes config map resources based on particular configurations on each one of them. There's also a [`secretGenerator` functionality](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/secretgenerator/) with has the same options as the [`configMapGenerator` one](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/).
        - In this case, there's only one config map resource configured, the one required by MetalLB for running properly.
        - This config map will be named `config` and will include the contents of the `config` file you created before in the `configs` subfolder.
        - The `disableNameSuffixHash` option is for disabling the default behavior of Kustomize regarding names of config maps and secrets. It adds a suffix to the name of those resources, a hash calculated from their contents like in `config-58565bck2t`. This can be problematic because certain apps don't expect such suffix, hence cannot find their config maps or secrets. MetalLB expects the generated config map `metadata.name` to be just the `config` string, making the use of this `disableNameSuffixHash` option necessary here.

    > **BEWARE!**  
    > From the version `0.13.0` onwards, is **not** possible to configure MetalLB with configmaps as shown here. The config map has to be transformed into custom resources (or CRs), something indicated in this official [Backward Compatibility note](https://metallb.universe.tf/#backward-compatibility). Check the [guide G912 - Appendix 12](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md) to see how to adapt the MetalLB kustomize project you've created here.

5. You can check how the final deployment would look as a manifest yaml with `kubectl`.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/metallb/ | less
    ~~~

    With the `kustomize` option, `kubectl` builds the whole deployment yaml manifest resulting from processing the `kustomization.yaml` file. Since the output can be quite long, it's better to append a `| less` to the command for getting a paginated view of the yaml.

    The command takes a moment to finish because it has to download the MetalLB manifests first, then process and combine them with the configuration file in your client system. When you finally see the result, you'll get a quite long yaml output in which you'll find the `config` file embedded as a `ConfigMap` resource like shown below.

    ~~~yaml
    ---
    apiVersion: v1
    data:
      config: |
        address-pools:
        - name: default
          protocol: layer2
          addresses:
          - 192.168.1.41-192.168.1.80
    kind: ConfigMap
    metadata:
      name: config
      namespace: metallb-system
    ---
    ~~~

### _Deploying MetalLB_

Now that you have the configuration files ready, you're just one command away from deploying MetalLB.

~~~bash
$ kubectl apply -k $HOME/k8sprjs/metallb/
~~~

This command will look for a `kustomization.yaml` file in the folder you tell it to process. Then, it builds the whole deployment output like with the `kustomize` option but, instead of displaying it, `kubectl` takes that yaml and directly applies it on your Kubernetes cluster. In this case, the `kubectl` command will return an output like the following.

~~~bash
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

~~~bash
$ kubectl get pods -n metallb-system 
NAME                          READY   STATUS    RESTARTS   AGE
controller-7dcc8764f4-2bc78   1/1     Running   0          9m48s
speaker-28nbv                 1/1     Running   0          9m48s
speaker-2x2x5                 1/1     Running   0          9m47s
~~~

The MetalLB resources are all under the `metallb-system` namespace, such as its pods. On the other hand, you can already see in your services the effects of having this load balancer available.

~~~bash
$ kubectl get svc -A
NAMESPACE     NAME         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
default       kubernetes   ClusterIP      10.43.0.1      <none>         443/TCP                      122m
kube-system   kube-dns     ClusterIP      10.43.0.10     <none>         53/UDP,53/TCP,9153/TCP       122m
kube-system   traefik      LoadBalancer   10.43.110.37   192.168.1.41   80:30963/TCP,443:32446/TCP   11m
~~~

From all the services you have running at this point in your K3s cluster, the `traefik` service is the one set with the `LoadBalancer` type. Now it has an `EXTERNAL-IP` from the `default` address pool set in the MetalLB configmap. In particular, it has got the very first available IP in the `default` pool.

## MetalLB's Kustomize project attached to this guide series

You can find the Kustomize project for this MetaLB deployment in the following attached folder.

- `k8sprjs/metallb`

> **BEWARE!**  
> The main `kustomization.yaml` file has the configuration shown here, but also the only one valid from MetalLB `v0.13.0` onwards, although commented out. Be mindful of which one you want to deploy.

## Relevant system paths

### _Folders on remote kubectl client_

- `$HOME/k8sprjs`
- `$HOME/k8sprjs/metallb`
- `$HOME/k8sprjs/metallb/configs`

### _Files on remote kubectl client_

- `$HOME/k8sprjs/metallb/kustomization.yaml`
- `$HOME/k8sprjs/metallb/configs/config`

## References

### _MetalLB_

- [MetalLB official webpage](https://metallb.universe.tf/)
- [MetalLB Installation](https://metallb.universe.tf/installation/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)
- [MetalLB on GitHub](https://github.com/metallb/metallb)
- [Install and configure MetalLB as a load balancer for Kubernetes](https://blog.inkubate.io/install-and-configure-metallb-as-a-load-balancer-for-kubernetes/)
- [Running metallb in Layer 2 mode](https://www.shashankv.in/kubernetes/metallb-layer2-mode/)
- [K8S AND METALLB: A LOADBALANCER FOR ON-PREM DEPLOYMENTS](https://starkandwayne.com/blog/k8s-and-metallb-a-loadbalancer-for-on-prem-deployments/)
- [Kubernetes Metal LB for On-Prem / BareMetal Cluster in 10 minutes](https://medium.com/@JockDaRock/kubernetes-metal-lb-for-on-prem-baremetal-cluster-in-10-minutes-c2eaeb3fe813)
- [Configure MetalLB In Layer 2 Mode](https://docs.bitnami.com/kubernetes/infrastructure/metallb/administration/configure-layer2-mode/)
- [K3s – lightweight kubernetes made ready for production – Part 1](https://digitalis.io/blog/kubernetes/k3s-lightweight-kubernetes-made-ready-for-production-part-1/)
- [How to Build a Multi-Master Kubernetes Cluster on VMware with MetalLB](https://platform9.com/blog/how-to-build-a-multi-master-cluster-on-vmware-with-metallb/)

### _Kustomize_

- [Introduction to Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [The Kustomization File](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)
- [Kustomize on Github](https://github.com/kubernetes-sigs/kustomize)
- [Kustomize Tutorial: Creating a Kubernetes app out of multiple pieces](https://www.mirantis.com/blog/introduction-to-kustomize-part-1-creating-a-kubernetes-app-out-of-multiple-pieces/)
- [Modify your Kubernetes manifests with Kustomize](https://opensource.com/article/21/6/kustomize-kubernetes)
- [Kustomize Best Practices](https://www.openanalytics.eu/blog/2021/02/23/kustomize-best-practices/)

## Navigation

[<< Previous (**G026. K3s cluster setup 09**)](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G028. K3s cluster setup 11**) >>](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md)
