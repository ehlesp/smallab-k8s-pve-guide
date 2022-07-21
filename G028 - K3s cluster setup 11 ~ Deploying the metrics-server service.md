# G028 - K3s cluster setup 11 ~ Deploying the metrics-server service

Another embedded service that was disabled in the installation of your K3s cluster was the metrics-server. This service scrapes resource usage data from your cluster nodes and offers it through its API. The problem with the embedded metrics-server, and with any other embedded service included in K3s, is that you cannot change their configuration, at least not permanently (meaning manipulation through `kubectl`), beyond what's configurable through the parameters you can set to the K3s service itself.

In particular, the embedded metrics-server comes with a default configuration that is not adequate for the setup of your K3s cluster. Since you cannot change the default configuration permanently, it's better to deploy the metrics-server independently in your cluster, but with the proper configuration already set in it.

## Checking the metrics-server's manifest

First you would need to check out the manifest used for deploying the metrics-server and see where you have to apply the required change. This also means that you have to be aware of which version you're going to deploy in your cluster. K3s `v1.22.1+k3s1` comes with the `v0.5.0` release of metrics-server but, at the time of writing this, there's already a `v0.5.2` available which is the one you'll see deployed in this guide.

> **BEWARE!**  
> As with any other software, each release of any service comes with its own particularities regarding compatibilities, in particular with the Kubernetes engine you have in your cluster. Always check that the release of a software you want to deploy in your cluster is compatible with the Kubernetes version running your cluster.

You'll find the yaml manifest for metrics-server `v0.5.2` in the **Assets** section found [at this Github release page](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.5.2). It's the `components.yaml` file. Download and open it, then look for the `Deployment` object in it. It should be as the yaml below.

~~~yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        image: k8s.gcr.io/metrics-server/metrics-server:v0.5.2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 4443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
---
~~~

This is the object you'll need to modify to adapt metrics-server to your particular cluster setup. Some of the values will also be taken from the yaml manifest used by K3s to deploy this service, a yaml you'll find in [the K3s GitHub page](https://github.com/k3s-io/k3s/blob/master/manifests/metrics-server/metrics-server-deployment.yaml).

## Deployment of metrics-server

As you did with MetalLB in the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#deploying-metallb-on-your-k3s-cluster), you're going to use a Kustomize project to deploy the metrics-server in your cluster.

1. In your kubectl client system, create a folder structure for the Kustomize project.

    ~~~bash
    $ mkdir -p $HOME/k8sprjs/metrics-server/patches
    ~~~

    In the command above you can see that, inside the metrics-server folder, I've created a `patches` one. The idea is to patch the default configuration of the service by adding a couple of parameters.

2. Create a new `metrics-server.deployment.containers.args.patch.yaml` file under the `patches` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/metrics-server/patches/metrics-server.deployment.containers.args.patch.yaml
    ~~~

    Notice the structure of this yaml file's name. It has the pattern below.

    ~~~bash
    <metadata.name>.<kind>.[extra_details].[...].yaml
    ~~~

    You can use any other pattern that suits you, but try to keep the same one so the yaml files in your Kustomize projects have names that hint you about what's inside of them.

3. Fill `metrics-server.deployment.containers.args.patch.yaml` with the following yaml.

    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: metrics-server
      namespace: kube-system
    spec:
      template:
        spec:
          tolerations:
          - key: "CriticalAddonsOnly"
            operator: "Exists"
          - key: "node-role.kubernetes.io/control-plane"
            operator: "Exists"
            effect: "NoSchedule"
          - key: "node-role.kubernetes.io/master"
            operator: "Exists"
            effect: "NoSchedule"
          containers:
          - name: metrics-server
            args:
            - --cert-dir=/tmp
            - --secure-port=4443
            - --kubelet-preferred-address-types=InternalIP
            - --kubelet-use-node-status-port
            - --metric-resolution=15s
    ~~~

    See how the yaml manifest contains the neccesary information to identify the resource to be patched, up to the container's name, and only the values to add or modify.

    - The `tolerations` section has been taken directly [from the Deployment object K3s uses](https://github.com/k3s-io/k3s/blob/master/manifests/metrics-server/metrics-server-deployment.yaml) to deploy metrics-server. These [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) will make the metrics-server pod to be scheduled or not (`effect: "NoSchedule"`) in nodes that are tainted with those keys. For instance, remember that the server node is tainted with `"k3s-controlplane=true:NoExecute"` which restricts what pods can run on it, also excluding the metrics-server one.

    - `--cert-dir`: apparently, a directory for certificates, although I haven't found a proper explanation for this parameter.

    - `--secure-port`: the https port used to connect to the metrics-server server.

    - `--kubelet-preferred-address-types`: indicates the priority of node address types used when determining an address for connecting to a particular node. In your cluster's case, the only one that is really needed is the internal IP, so that's the only option specified. The possible values are `Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP`.

    - `--kubelet-use-node-status-port`: I haven't found a proper explanation for this parameter, but by the name it seems that makes the metrics-server check the status port (`10250` by default) that a kubelet process opens in the node where it runs.

    - `--metric-resolution`: the metrics-server service will scrape the resource usage stats from the kubelets every this time interval. By default, it's 60 seconds.

    Notice that the parameters in the `args` list are exactly the same as in the original `components.yaml` file, except for the `kubelet-preferred-address-types`. This one is set just with the `InternalIP` value to ensure that metrics-server only communicates through the isolated secondary network you have in your setup.

4. Create the `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8sprjs/metrics-server/kustomization.yaml
    ~~~

5. Put the following content in the `kustomization.yaml` file.

    ~~~yaml
    # Metrics server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.2/components.yaml

    patchesStrategicMerge:
    - patches/metrics-server.deployment.containers.args.patch.yaml
    ~~~

    Notice the following.

    - There's an `apiVersion` and a `kind` parameter specified in this `kustomization.yaml` file, unlike the one you used for deploying the MetalLB service. I haven't found an explanation about why these two parameters can be omitted for this kind of object.

    - In the `resources` list you have the URL to the `components.yaml` file, although you could reference here the downloaded file too.

    - The `patchesStrategicMerge` section is probably the simplest way to patch in Kustomize, [read about it here](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patchesstrategicmerge/). See how the `metrics-server.deployment.containers.args.patch.yaml` file is listed as the sole patch to apply here.

6. Test the Kustomize project with kubectl.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/metrics-server | less
    ~~~

    In the output, look for the `Deployment` object. It should have the `args` parameters and the `tolerations` set as below.

    ~~~yaml
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        k8s-app: metrics-server
      name: metrics-server
      namespace: kube-system
    spec:
      selector:
        matchLabels:
          k8s-app: metrics-server
      strategy:
        rollingUpdate:
          maxUnavailable: 0
      template:
        metadata:
          labels:
            k8s-app: metrics-server
        spec:
          containers:
          - args:
            - --cert-dir=/tmp
            - --secure-port=4443
            - --kubelet-preferred-address-types=InternalIP
            - --kubelet-use-node-status-port
            - --metric-resolution=15s
            image: k8s.gcr.io/metrics-server/metrics-server:v0.5.2
            imagePullPolicy: IfNotPresent
            livenessProbe:
              failureThreshold: 3
              httpGet:
                path: /livez
                port: https
                scheme: HTTPS
              periodSeconds: 10
            name: metrics-server
            ports:
            - containerPort: 4443
              name: https
              protocol: TCP
            readinessProbe:
              failureThreshold: 3
              httpGet:
                path: /readyz
                port: https
                scheme: HTTPS
              initialDelaySeconds: 20
              periodSeconds: 10
            resources:
              requests:
                cpu: 100m
                memory: 200Mi
            securityContext:
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 1000
            volumeMounts:
            - mountPath: /tmp
              name: tmp-dir
          nodeSelector:
            kubernetes.io/os: linux
          priorityClassName: system-cluster-critical
          serviceAccountName: metrics-server
          tolerations:
          - key: CriticalAddonsOnly
            operator: Exists
          - effect: NoSchedule
            key: node-role.kubernetes.io/control-plane
            operator: Exists
          - effect: NoSchedule
            key: node-role.kubernetes.io/master
            operator: Exists
          volumes:
          - emptyDir: {}
            name: tmp-dir
    ---
    ~~~

7. Apply this Kustomize project to finally deploy metrics-server in your cluster.

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/metrics-server/
    ~~~

8. After a minute or so, check if the metrics-server pod and service is running.

    ~~~bash
    $ kubectl get pods,svc -n kube-system | grep metrics
    pod/metrics-server-5b45cf8dbb-nv477          1/1     Running      0               5m12s
    service/metrics-server   ClusterIP      10.43.133.41   <none>         443/TCP                      5m13s
    ~~~

    You should get two lines regarding metrics-server. Also notice that the metrics-server is set in the `kube-system` namespace.

## Checking the metrics-server service

To see the resource usage values scraped by metrics-server, you have to use the `kubectl top` command. You can get values from nodes and from pods.

- Get values from nodes with `kubectl top node`.

    ~~~bash
    $ kubectl top node 
    NAME          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
    k3sagent01    200m         5%     347Mi           17%
    k3sagent02    166m         4%     335Mi           21%
    k3sserver01   351m         8%     647Mi           49%
    ~~~

- Get values from pods with `kubectl top pods`, although always specifying a namespace (remember, pods are namespaced in Kubernetes).

    ~~~bash
    $ kubectl top pods -A
    NAMESPACE        NAME                                     CPU(cores)   MEMORY(bytes)   
    kube-system      coredns-85cb69466-9l6ws                  6m           11Mi            
    kube-system      local-path-provisioner-64ffb68fd-zxm2v   1m           7Mi             
    kube-system      metrics-server-5b45cf8dbb-nv477          15m          16Mi            
    kube-system      traefik-74dd4975f9-tdv42                 2m           18Mi            
    metallb-system   controller-7dcc8764f4-gskm7              1m           6Mi             
    metallb-system   speaker-6rrwf                            10m          10Mi            
    metallb-system   speaker-kntk2                            16m          10Mi
    ~~~

    In this case the `top pod` command has a `-A` option to get pods running in all namespaces of a cluster.

To see all the options available for both `top` commands, use the `--help` option.

## Metrics-server's Kustomize project attached to this guide series

You can find the Kustomize project for this metrics-server deployment in the following attached folder.

- `k8sprjs/metrics-server`

## Relevant system paths

### _Folders on remote kubectl client_

- `$HOME/k8sprjs`
- `$HOME/k8sprjs/metrics-server`
- `$HOME/k8sprjs/metrics-server/patches`

### _Files on remote kubectl client_

- `$HOME/k8sprjs/metrics-server/kustomization.yaml`
- `$HOME/k8sprjs/metrics-server/patches/metrics-server.deployment.containers.args.patch.yaml`

## References

### _Kubernetes Metrics Server_

- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Kubernetes Metrics Server v0.5.2 release](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.5.2)
- [K3s v1.22.3+k3s1 release](https://github.com/k3s-io/k3s/releases/tag/v1.22.3+k3s1)
- [Install Metrics Server on a Kubernetes Cluster](https://computingforgeeks.com/how-to-deploy-metrics-server-to-kubernetes-cluster/)
- [How to troubleshoot metrics-server on kubeadm?](https://stackoverflow.com/questions/57137683/how-to-troubleshoot-metrics-server-on-kubeadm)
- [[learner] Debugging issue with metrics-server](https://www.reddit.com/r/kubernetes/comments/ktuour/learner_debugging_issue_with_metricsserver/)
- [Metrics server issue with hostname resolution of kubelet and apiserver unable to communicate with metric-server clusterIP](https://github.com/kubernetes-sigs/metrics-server/issues/131)
- [The case of disappearing metrics in Kubernetes](https://dev.to/shyamala_u/the-case-of-disappearing-metrics-in-kubernetes-1kdh)
- [Kubernetes Metrics Server. Configuration](https://github.com/kubernetes-sigs/metrics-server#configuration)
- [Query on kubernetes metrics-server metrics values](https://stackoverflow.com/questions/55684789/query-on-kubernetes-metrics-server-metrics-values)
- [Kubernetes Pod Created with hostNetwork](https://docs.datadoghq.com/security_platform/default_rules/kubernetes-pod-created-with-hostnetwork/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
