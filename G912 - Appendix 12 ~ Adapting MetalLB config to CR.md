# G912 - Appendix 12 ~ Adapting MetalLB config to CR

The MetalLB software, from its `0.13.0` version onwards, has stopped supporting configmaps as a valid method of configuration. You can see the announcement in this [Backward Compatibility note on the official MetalLB page](https://metallb.universe.tf/#backward-compatibility). This means that the configmap-based configuration set in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md) is now completely invalid for MetalLB version `0.13.0` and beyond. In the note, they offer a convertion tool for transforming configmaps to CRs (Custom Resources), which are now the only supported way of configuring MetalLB. But this approach presents with a couple of problems for the setup used in this guide series.

- The tool is executed with docker, but that's a tool not contemplated in this guide.
- There are issues with the convertion tool, [as reported in this issue thread](https://github.com/metallb/metallb/issues/1473) or [this other one](https://github.com/metallb/metallb/issues/1495).

Thankfully, someone else used an equivalent metallb setup and shared [in this article](https://tech.aufomm.com/convert-metallb-configinline-to-crs-for-layer-2-protocol/) the converted configuration. Based on this, I've prepared the following modification to the MetalLB kustomize project created in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md).

1. Create a `resources` folder within your MetalLB kustomize project.

    ~~~bash
    $ mkdir $HOME/k8sprjs/metallb/resources
    ~~~

2. In the `resources` folder, create the files `l2-ip.l2advertisement.yaml` and `default-pool.ipaddresspool.yaml`.

    ~~~bash
    $ touch $HOME/k8sprjs/metallb/resources/{l2-ip.l2advertisement.yaml,default-pool.ipaddresspool.yaml}
    ~~~

3. In the file `l2-ip.l2advertisement.yaml` copy the following yaml.

    ~~~yaml
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement

    metadata:
      name: l2-ip
    spec:
      ipAddressPools:
      - default-pool
    ~~~

    This indicates to MetalLB the following.
    - The kind `L2Advertisement` sets the **protocol** used as L2. This is the equivalent of the `protocol` parameter in the `config` file you used for configuring MetalLB.
    - The `spec.ipAddressPool` parameter points to the pools of ips to be used, in this case just one named `default-pool`.

4. Edit now the `default-pool.ipaddresspool.yaml` file, so it has the content below.

    ~~~yaml
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool

    metadata:
      name: default-pool
    spec:
      addresses:
      - 192.168.1.41-192.168.1.80
    ~~~

    Here you've configured a simple pool of ips.
    - The kind `IPAddressPool` indicates that this is just a MetalLB pool of IP addresses.
    - The name is the same `default-pool` one indicated in the `l2-ip.l2advertisement.yaml`.
    - The `spec.addresses` list is the equivalent to the `addresses` parameter you had in the `config` file used previously as a configmap.

5. Modify the `kustomization.yaml` file of your MetalLB kustomize project so it looks like below.

    ~~~yaml
    # MetalLB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: metallb-system

    resources:
    - github.com/metallb/metallb/config/native?ref=v0.13.3
    - resources/l2-ip.l2advertisement.yaml
    - resources/default-pool.ipaddresspool.yaml
    ~~~

    In this `kustomization.yaml` file there's no longer a `configMapGenerator` section, as it was configured in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#setting-up-the-configuration-files). Now there are only resources: the one for deploying the MetalLB service, and the other two you've just created for configuring the IP pool to use with MetalLB.

6. Check the output of this kustomize project as usual.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/metallb/ | less
    ~~~

    The resources you manually created will be inside the yaml, just look for them by their metadata `name`. You'll may notice that MetalLB is "wired" to look for `L2Advertisement` resources automatically, which means that you don't have to explicitly tell MetalLB which one to use.

7. Apply the kustomize project to your cluster.

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/metallb
    ~~~

8. Give MetalLB a couple of minutes or so to get ready, then check with `kubectl` that it's been deployed in your cluster.

    ~~~bash
    $ kubectl get -n metallb-system all -o wide
    NAME                              READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
    pod/controller-55cd7dbf96-vrx29   1/1     Running   0          20m   10.42.1.214   k3sagent01   <none>           <none>
    pod/speaker-lllm5                 1/1     Running   0          20m   10.0.0.11     k3sagent01   <none>           <none>
    pod/speaker-2nxf7                 1/1     Running   0          19m   10.0.0.12     k3sagent02   <none>           <none>

    NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
    service/webhook-service   ClusterIP   10.43.137.211   <none>        443/TCP   20m   component=controller

    NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE    CONTAINERS   IMAGES                            SELECTOR
    daemonset.apps/speaker   2         2         2       2            2           kubernetes.io/os=linux   232d   speaker      quay.io/metallb/speaker:v0.13.3   app=metallb,component=speaker

    NAME                         READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES                               SELECTOR
    deployment.apps/controller   1/1     1            1           232d   controller   quay.io/metallb/controller:v0.13.3   app=metallb,component=controller

    NAME                                    DESIRED   CURRENT   READY   AGE    CONTAINERS   IMAGES                               SELECTOR
    replicaset.apps/controller-55cd7dbf96   1         1         1       20m    controller   quay.io/metallb/controller:v0.13.3   app=metallb,component=controller,pod-template-hash=55cd7dbf96
    replicaset.apps/controller-7dcc8764f4   0         0         0       232d   controller   quay.io/metallb/controller:v0.11.0   app=metallb,component=controller,pod-template-hash=7dcc8764f4
    ~~~

    Notice that, at the end of the output above, there's an older `0.11.0` MetalLB controller still listed but not really running since its not ready (it has `0` containers in `READY` state).

9. If you had created a config map as I explained in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md)), you'll have to remove it manually from your cluster with `kubectl`.

    - First, confirm that it exists within the `metallb-system` namespace.

        ~~~bash
        $ kubectl get -n metallb-system cm
        NAME               DATA   AGE
        kube-root-ca.crt   1      232d
        config             1      232d
        ~~~

        It's the resource named `config`. Remember that you can see its contents with `kubectl` too.

        ~~~bash
        $ kubectl get -n metallb-system cm config -o yaml
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
          annotations:
            kubectl.kubernetes.io/last-applied-configuration: |
              {"apiVersion":"v1","data":{"config":"address-pools:\n- name: default\n  protocol: layer2\n  addresses:\n  - 192.168.1.41-192.168.1.80\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"config","namespace":"metallb-system"}}
          creationTimestamp: "2021-11-28T13:24:03Z"
          name: config
          namespace: metallb-system
          resourceVersion: "2334"
          uid: 07eeb0be-ec96-440c-ad46-25da43f6b04c
        ~~~

    - Remove it from your cluster.

        ~~~bash
        $ kubectl delete -n metallb-system cm config
        configmap "config" deleted
        ~~~

        Confirm that's gone.

        ~~~bash
        $ kubectl get -n metallb-system cm
        NAME               DATA   AGE
        kube-root-ca.crt   1      232d
        ~~~

## References

### _MetalLB configmap conversion to CRs_

- [Backward Compatibility note](https://metallb.universe.tf/#backward-compatibility)
- [Convert Metallb configInline to CRs for Layer 2 Protocol](https://tech.aufomm.com/convert-metallb-configinline-to-crs-for-layer-2-protocol/)
- [Heads up: breaking changes in 0.13.2](https://github.com/metallb/metallb/issues/1473)
- [CR Converstion tool, failed to generate resources: invalid aggregation length 24](https://github.com/metallb/metallb/issues/1495)
- [Problem with Kustomize installation resource for Metallb 0.13.z native bgp implementation](https://github.com/metallb/metallb/issues/1524)
