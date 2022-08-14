# G035 - Deploying services 04 ~ Monitoring stack - Part 3 - Prometheus Node Exporter service

In this part you'll prepare the Kubernetes project for the Prometheus Node Exporter. You'll see that, compared to other services like the Kube State Metrics, this Node Exporter is rather simple to declare. The yamls you'll see here are adaptations based on the ones available in [this GitHub repository](https://github.com/bibinwilson/kubernetes-node-exporter), which is related [to this guide](https://devopscube.com/node-exporter-kubernetes/).

## Kustomize project folders for Prometheus Node Exporter

Start by creating the folders needed for the corresponding Kustomize project.

~~~bash
$ mkdir -p $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources
~~~

## Prometheus Node Exporter DaemonSet resource

This Prometheus Node Exporter setup won't require to store anything but, instead of using a `Deployment` resource, you'll declare its pod in a [`DaemonSet`](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/). Why? This node exporter is essentially an agent that gets metrics from the Linux subsystem of your nodes, and you want to get those statistics from all the nodes in your cluster. With a `DaemonSet` you can configure a pod to be executed in all your nodes automatically, right what you want for this service.

1. Create a file named `agent-prometheus-node-exporter.daemonset.yaml` under the `agent-prometheus-node-exporter/resources` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.daemonset.yaml
    ~~~

2. Fill the `agent-prometheus-node-exporter.daemonset.yaml` with the yaml declaration below.

    ~~~yaml
    apiVersion: apps/v1
    kind: DaemonSet

    metadata:
      name: agent-prometheus-node-exporter
    spec:
      template:
        spec:
          containers:
          - name: server
            image: prom/node-exporter:v1.3.1
            args:
            - --path.sysfs=/host/sys
            - --path.rootfs=/host/root
            - --no-collector.hwmon
            - --no-collector.wifi
            - --collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)
            - --collector.netclass.ignored-devices=^(veth.*)$
            ports:
              - containerPort: 9100
                protocol: TCP
            resources:
              limits:
                cpu: 250m
                memory: 180Mi
              requests:
                cpu: 102m
                memory: 180Mi
            volumeMounts:
            - mountPath: /host/sys
              mountPropagation: HostToContainer
              name: sys
              readOnly: true
            - mountPath: /host/root
              mountPropagation: HostToContainer
              name: root
              readOnly: true
          volumes:
          - hostPath:
              path: /sys
            name: sys
          - hostPath:
              path: /
            name: root
          tolerations:
          - effect: NoExecute
            operator: Exists
    ~~~

    This `DaemonSet` resource has some particularities.

    - `server` container: executes the Kube State Metrics service.
        - In the `args` section you have several options configured.
            - `--path.sysfs` and `--path.rootfs` indicate what are the root (`/`) and sys folder (`/sys`) paths that the agent has to monitor in the nodes. These paths are enabled in the `volumeMounts` and `volumes` sections as `hostPath` routes.
            - The `no-collector` options disable specific data collectors. In this case, the `hwmon`, which exposes hardware and sensor data, and the `wifi`, to not collect stats from wifi interfaces.
            - The last two `collector` options are just patterns that leave out, from the metrics collected, the storage devices and the virtual ethernet devices created by the Kubernetes engine for the containers.
        - The `volumes` and `volumeMounts` refer to paths from the nodes themselves, invoked with the `hostPath` declarations. The paths indicated for the hostPath volumes are correct for a Debian Linux system like the ones running your nodes, but you should be careful of validating them whenever you use some other Linux distribution.

    - `tolerations`: with this section you can allow a pod to be scheduled in nodes that have particular taints. Remember that your K3s server node was tainted to not allow any kind of workload be scheduled in it ([check the corresponding `config.yaml` file in the **G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file)). The taint is `NoExecute`, so only pods that tolerate such taint can be executed in your K3s server node, such as the one declared in this deployment resource.

## Prometheus Node Exporter Service resource

You only need to declare another resource for completing this Prometheus Node Exporter setup, a `Service`.

1. Generate an `agent-prometheus-node-exporter.service.yaml` under the `agent-prometheus-node-exporter/resources` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.service.yaml
    ~~~

2. Fill the `agent-prometheus-node-exporter.service.yaml` with the yaml declaration below.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: agent-prometheus-node-exporter
      annotations:
          prometheus.io/scrape: 'true'
          prometheus.io/port:   '9100'
    spec:
      ports:
      - name: node-exporter
        protocol: TCP
        port: 9100
        targetPort: 9100
    ~~~

    There's nothing special about this service, although notice that it does have the annotations to inform Prometheus that it can scrape metrics from this service.

### _Prometheus Node Exporter `Service`'s FQDN or DNS record_

You'll need to know beforehand the FQDN for this service within your cluster, so deduce it the same way as [you've done already for the Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-services-fqdn-or-dns-record). The value you should obtain should be like the string next.

~~~http
mntr-agent-prometheus-node-exporter.monitoring.svc.deimos.cluster.io
~~~

## Prometheus Node Exporter Kustomize project

The last thing to declare is the `kustomization.yaml` file for this Kustomization project.

1. Create a `kustomization.yaml` file in the `agent-prometheus-node-exporter` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/kustomization.yaml
    ~~~

2. Copy the yaml next in `kustomization.yaml`.

    ~~~yaml
    # Prometheus Node Exporter setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: node-exporter

    resources:
    - resources/agent-prometheus-node-exporter.daemonset.yaml
    - resources/agent-prometheus-node-exporter.service.yaml

    images:
    - name: prom/node-exporter
      newTag: v1.3.1
    ~~~

    The labels you see in `commonLabels` also appear in the resources declared in [the project I'm using as reference](https://github.com/bibinwilson/kubernetes-node-exporter). Something else you'll notice is that there's no `replicas` section: the `DaemonSet` itself will take care automatically of putting one replica of this pod on each cluster node.

### _Validating the Kustomize yaml output_

Proceed now to validate the Kustomize project for your Prometheus Node Exporter service.

1. Dump the output of this Kustomize project in a file named `agent-prometheus-node-exporter.k.output.yaml`.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter > agent-prometheus-node-exporter.k.output.yaml
    ~~~

2. Open the `agent-prometheus-node-exporter.k.output.yaml` file and compare your resulting yaml output with the one below.

    ~~~yaml
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9100"
        prometheus.io/scrape: "true"
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
      name: agent-prometheus-node-exporter
    spec:
      ports:
      - name: node-exporter
        port: 9100
        protocol: TCP
        targetPort: 9100
      selector:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
    ---
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
      name: agent-prometheus-node-exporter
    spec:
      selector:
        matchLabels:
          app.kubernetes.io/component: exporter
          app.kubernetes.io/name: node-exporter
      template:
        metadata:
          labels:
            app.kubernetes.io/component: exporter
            app.kubernetes.io/name: node-exporter
        spec:
          containers:
          - args:
            - --path.sysfs=/host/sys
            - --path.rootfs=/host/root
            - --no-collector.wifi
            - --no-collector.hwmon
            - --collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)
            - --collector.netclass.ignored-devices=^(veth.*)$
            image: prom/node-exporter:v1.3.1
            name: server
            ports:
            - containerPort: 9100
              protocol: TCP
            resources:
              limits:
                cpu: 250m
                memory: 180Mi
              requests:
                cpu: 102m
                memory: 180Mi
            volumeMounts:
            - mountPath: /host/sys
              mountPropagation: HostToContainer
              name: sys
              readOnly: true
            - mountPath: /host/root
              mountPropagation: HostToContainer
              name: root
              readOnly: true
          tolerations:
          - effect: NoExecute
            operator: Exists
          volumes:
          - hostPath:
              path: /sys
            name: sys
          - hostPath:
              path: /
            name: root
    ~~~

    There's nothing in this output you haven't seen before in this guide series. Just be sure that the values are correct and the labels appear where they should.

## Don't deploy this Prometheus Node Exporter project on its own

My usual reminder. This component is part of a bigger project yet to be completed: your monitoring stack. Wait till you have every component ready for deploying in your cluster.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.daemonset.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.service.yaml`

## References

### _Kubernetes_

- [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [K8s: Deployments vs StatefulSets vs DaemonSets](https://medium.com/stakater/k8s-deployments-vs-statefulsets-vs-daemonsets-60582f0c62d4)
- [Difference between daemonsets and deployments](https://stackoverflow.com/questions/53888389/difference-between-daemonsets-and-deployments)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Working with taints and tolerations in Kubernetes](https://www.padok.fr/en/blog/add-taint-nodes-tolerations)
- [Node taint k3s-controlplane=true:NoExecute](https://github.com/k3s-io/k3s/issues/1401)

### _Prometheus Node Exporter_

- [Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/)
- [Prometheus Node Exporter on GitHub](https://github.com/prometheus/node_exporter)
- [How to Setup Prometheus Node Exporter on Kubernetes](https://devopscube.com/node-exporter-kubernetes/)
- [Prometheus Node Exporter yamls from "How to Setup" guide](https://github.com/bibinwilson/kubernetes-node-exporter)
- [Prometheus Node Exporter's Docker image](https://hub.docker.com/r/prom/node-exporter)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 2**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 4**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md)
