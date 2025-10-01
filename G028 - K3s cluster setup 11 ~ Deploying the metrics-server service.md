# G028 - K3s cluster setup 11 ~ Deploying the metrics-server service

- [Deploy a metric-server service that you can fully configure](#deploy-a-metric-server-service-that-you-can-fully-configure)
- [Checking the metrics-server's manifest](#checking-the-metrics-servers-manifest)
- [Deployment of metrics-server](#deployment-of-metrics-server)
- [Checking the metrics-server service](#checking-the-metrics-server-service)
- [Metrics-server's Kustomize project attached to this guide](#metrics-servers-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders on remote kubectl client](#folders-on-remote-kubectl-client)
  - [Files on remote kubectl client](#files-on-remote-kubectl-client)
- [References](#references)
  - [Kubernetes](#kubernetes)
  - [Kubernetes Metrics Server](#kubernetes-metrics-server)
  - [Related to Kubernetes Metrics Server](#related-to-kubernetes-metrics-server)
- [Navigation](#navigation)

## Deploy a metric-server service that you can fully configure

The other embedded service disabled in your K3s cluster deployment is the metrics-server. This service scrapes resource usage data from your cluster nodes and offers it through its API. The problem with the embedded metrics-server, and with any other embedded service included in K3s, is that you cannot change their configuration directly. You can adjust what's configurable through the parameters you can set to the K3s service itself, or make manual temporary changes through `kubectl`.

In particular, the embedded metrics-server comes with a default configuration that is not adequate for the setup of your K3s cluster. Since you cannot change the default configuration permanently, it is better to deploy the metrics-server independently in your cluster, but with the proper configuration already set in it.

## Checking the metrics-server's manifest

First you would need to check out the manifest used for deploying the metrics-server and see where you have to apply the required change. This also means that you have to be aware of which version you're going to deploy in your cluster. K3s `v1.33.4+k3s1` comes with the `v0.8.0` release of metrics-server which is, at the time of writing this, the latest version available.

> [!IMPORTANT]
> **Ensure the service's version is compatible with your cluster's Kubernetes version**\
> Each release of any service comes with its own particularities regarding compatibilities, in particular with your cluster's Kubernetes engine. Always check that the release of a software you want to deploy in your cluster is compatible with the Kubernetes version running your cluster.

Download the `components.yaml` manifest for metrics-server `v0.8.0` from the **Assets** section found [at this Github release page](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.8.0). Open it and look for the `Deployment` object declared in it:

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
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
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
        - containerPort: 10250
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
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          seccompProfile:
            type: RuntimeDefault
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

This is the object you need to modify to adapt metrics-server to your particular cluster setup. You also have to take some values from the yaml manifest used to deploy this service embedded in K3s, a yaml you can find in [the K3s GitHub page](https://github.com/k3s-io/k3s/blob/master/manifests/metrics-server/metrics-server-deployment.yaml).

## Deployment of metrics-server

As you did with MetalLB in the [previous **G027** chapter](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#deploying-metallb-on-your-k3s-cluster), you are going to use a Kustomize project to deploy the metrics-server in your cluster:

1. In your `kubectl` client system, create a folder structure for the Kustomize project:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/metrics-server/patches
    ~~~

    In the command above you can see that, inside the `metrics-server` folder, I have created a `patches` one. The idea is to patch the default configuration of the service by adding a couple of parameters.

2. Create a new `metrics-server.deployment.patch.yaml` file under the `patches` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/metrics-server/patches/metrics-server.deployment.patch.yaml
    ~~~

    This file will contain only the patch to modify the metrics-server deployment object.

3. Declare in `metrics-server.deployment.patch.yaml` the patch for the metrics-server deployment:

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
          containers:
          - name: metrics-server
            args:
            - --cert-dir=/tmp
            - --secure-port=10250
            - --kubelet-preferred-address-types=InternalIP
            - --kubelet-use-node-status-port
            - --metric-resolution=15s
            - --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
    ~~~

    This patch only contains the necessary information to identify the resource to be patched and the properties to add or change:

    - `tolerations`\
      This section has been taken directly [from the `Deployment` object K3s uses](https://github.com/k3s-io/k3s/blob/master/manifests/metrics-server/metrics-server-deployment.yaml) to deploy its embedded metrics-server. These [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) will make the metrics-server pod to be scheduled or not (`effect: "NoSchedule"`) in nodes that are tainted with those keys.

      For instance, since the server node is tainted with `"k3s-controlplane=true:NoExecute"` it will not run a pod for the metrics-server service (nor for other regular apps or services).

    - `args`\
      Under this section are configured certain parameters that affect how the metric-server service runs:

      - `--cert-dir`\
        The directory where the TLS certs are located for this service. Here set to a temporary folder, proper for a containerized service.

      - `--secure-port`\
        The port on which to serve HTTPS with authentication and authorization. Here is set to the same one used to connect to kubelets.

      - `--kubelet-preferred-address-types`\
        Priority of node address types used when determining an address for connecting to a particular node. In your K3s cluster's case, the only one that is really needed is the internal IP.

        By only setting the `InternalIP` value, you ensure that metrics-server only communicates through the isolated secondary network you have in your setup.

      - `--kubelet-use-node-status-port`\
        When enabled, it makes the metrics-server check the status port (`10250` by default) that a kubelet process opens in the node where it runs.

      - `--metric-resolution`\
        How long the metric-server will retain the last metrics scraped from the kubelets. By default is one minute.

      - `tls-cipher-suites`\
        Comma-separated list of cipher suites admitted for the server. The list specified in the yaml snippet is the one K3s applies to deploy its embedded metric-server service.

      > [!NOTE]
      > [These and other metric-server flags are explained in this help document](https://github.com/kubernetes-sigs/metrics-server/blob/master/docs/command-line-flags.txt).

    > [!IMPORTANT]
    > **Review this patch whenever you update the metrics-server!**\
    > Every time you update the metrics-server service in your setup, do not forget to see how the patched values look in the official deployment declaration of the newer version you deploy. Otherwise, you could end up having errors due to using deprecated arguments or incorrect values.

4. Create the `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/metrics-server/kustomization.yaml
    ~~~

5. Fill the `kustomization.yaml` file like this:

    ~~~yaml
    # Metrics server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml

    patches:
    - path: patches/metrics-server.deployment.patch.yaml
    ~~~

    Notice that:

    - In the `resources` list you have the URL to the `components.yaml` file, although you could reference here the downloaded file too.

    - The `patches` section is where you specify all the patches you want to apply over the resources you deploy in the Kustomize project. This section supports different ways to declare and apply patches on resources, [check them out in its official Kubernetes documentation](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/). The method used here is probably the cleanest one, since it only needs specifying the path to the patch file.

6. Test the Kustomize project with `kubectl`:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/metrics-server | less
    ~~~

    In the output, look for the `Deployment` object and ensure that the `args` parameters and the `tolerations` section are set as expected:

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
            - --secure-port=10250
            - --kubelet-preferred-address-types=InternalIP
            - --kubelet-use-node-status-port
            - --metric-resolution=15s
            - --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
            image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
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
            - containerPort: 10250
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
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 1000
              seccompProfile:
                type: RuntimeDefault
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
          volumes:
          - emptyDir: {}
            name: tmp-dir
    ---
    ~~~

7. Apply the Kustomize project to finally deploy metrics-server in your cluster:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/metrics-server/
    ~~~

8. After a minute or so, check if the metrics-server pod and service are running:

    ~~~sh
    $ kubectl get pods,svc -n kube-system | grep metrics
    pod/metrics-server-5f87696c77-j7zgd           1/1     Running     0          41s
    service/metrics-server   ClusterIP      10.43.50.63    <none>        443/TCP                      41s
    ~~~

    You should get two lines regarding metrics-server. Also notice that the metrics-server is set in the `kube-system` namespace.

## Checking the metrics-server service

To see the resource usage values scraped by metrics-server, you have to use the `kubectl top` command. You can get values both from nodes and pods:

- Get values from nodes with `kubectl top node`:

    ~~~sh
    $ kubectl top node
    NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
    k3sagent01    64m          2%       561Mi           28%         
    k3sagent02    69m          3%       516Mi           26%         
    k3sserver01   156m         7%       785Mi           54% 
    ~~~

- Get values from pods with `kubectl top pods`, although always specifying a namespace (remember, pods are namespaced in Kubernetes):

    ~~~sh
    $ kubectl top pods -A
    NAMESPACE        NAME                                      CPU(cores)   MEMORY(bytes)   
    kube-system      coredns-64fd4b4794-phpd5                  5m           14Mi            
    kube-system      local-path-provisioner-774c6665dc-bzp9n   1m           8Mi             
    kube-system      metrics-server-5f87696c77-j7zgd           7m           18Mi            
    kube-system      traefik-c98fdf6fb-z87fh                   1m           28Mi            
    metallb-system   controller-58fdf44d87-kfc2f               5m           24Mi            
    metallb-system   speaker-jqcxt                             12m          24Mi            
    metallb-system   speaker-v7qkb                             12m          24Mi            
    metallb-system   speaker-xfqft                             13m          61Mi 
    ~~~

    Here the `top pod` command has a `-A` option to get the metrics from pods running in all namespaces of the cluster.

To see all the options available for both `top` commands, use the `--help` option.

## Metrics-server's Kustomize project attached to this guide

You can find the Kustomize project for this metrics-server deployment in the following attached folder:

- `k8sprjs/metrics-server`

## Relevant system paths

### Folders on remote kubectl client

- `$HOME/k8sprjs`
- `$HOME/k8sprjs/metrics-server`
- `$HOME/k8sprjs/metrics-server/patches`

### Files on remote kubectl client

- `$HOME/k8sprjs/metrics-server/kustomization.yaml`
- `$HOME/k8sprjs/metrics-server/patches/metrics-server.deployment.patch.yaml`

## References

### [Kubernetes](https://kubernetes.io/)

- [Reference. Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
  - [kustomization. patches](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/)

- [Kubernetes Documentation. Concepts](https://kubernetes.io/docs/concepts/)
  - [Scheduling, Preemption and Eviction. Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

- [Kubernetes Documentation. Reference](https://kubernetes.io/docs/reference/)
  - [Well-Known Labels, Annotations and Taints](https://kubernetes.io/docs/reference/labels-annotations-taints/)

### [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

- [Kubernetes Metrics Server v0.8.0 release](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.8.0)
- [Configuration](https://github.com/kubernetes-sigs/metrics-server#configuration)
- [command-line-flags.txt](https://github.com/kubernetes-sigs/metrics-server/blob/master/docs/command-line-flags.txt)
- [Metrics server issue with hostname resolution of kubelet and apiserver unable to communicate with metric-server clusterIP](https://github.com/kubernetes-sigs/metrics-server/issues/131)

### Related to Kubernetes Metrics Server

- [K3s v1.33.4+k3s1 release](https://github.com/k3s-io/k3s/releases/tag/v1.33.4%2Bk3s1)

- [How To Install Metrics Server on a Kubernetes Cluster](https://computingforgeeks.com/how-to-deploy-metrics-server-to-kubernetes-cluster/)

- [How to troubleshoot metrics-server on kubeadm?](https://stackoverflow.com/questions/57137683/how-to-troubleshoot-metrics-server-on-kubeadm)

- [[learner] Debugging issue with metrics-server](https://www.reddit.com/r/kubernetes/comments/ktuour/learner_debugging_issue_with_metricsserver/)

- [The case of disappearing metrics in Kubernetes](https://dev.to/shyamala_u/the-case-of-disappearing-metrics-in-kubernetes-1kdh)

- [Query on kubernetes metrics-server metrics values](https://stackoverflow.com/questions/55684789/query-on-kubernetes-metrics-server-metrics-values)

## Navigation

[<< Previous (**G027. K3s cluster setup 10**)](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G029. K3s cluster setup 12**) >>](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md)
