# G035 - Deploying services 04 ~ Monitoring stack - Part 3 - Prometheus Node Exporter service

- [The Prometheus Node Exporter is simpler to deploy](#the-prometheus-node-exporter-is-simpler-to-deploy)
- [Kustomize project folders for Prometheus Node Exporter](#kustomize-project-folders-for-prometheus-node-exporter)
- [Prometheus Node Exporter DaemonSet](#prometheus-node-exporter-daemonset)
- [Prometheus Node Exporter Service](#prometheus-node-exporter-service)
  - [Service's absolute internal FQDN](#services-absolute-internal-fqdn)
- [Prometheus Node Exporter Kustomize project](#prometheus-node-exporter-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Prometheus Node Exporter project on its own](#do-not-deploy-this-prometheus-node-exporter-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Prometheus Node Exporter](#prometheus-node-exporter)
  - [Other contents about Prometheus Node Exporter](#other-contents-about-prometheus-node-exporter)
  - [Kubernetes](#kubernetes)
    - [DaemonSet](#daemonset)
    - [Pods Scheduling](#pods-scheduling)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
    - [About DaemonSets](#about-daemonsets)
    - [About pods scheduling](#about-pods-scheduling)
- [Navigation](#navigation)

## The Prometheus Node Exporter is simpler to deploy

This part covers the preparation of the Kustomize project for the Prometheus Node Exporter. Compared to other services like the Kube State Metrics, this Node Exporter is less complex to declare. The YAML manifests declared here are adaptations based on the ones shown in [this article by Ichlaw posted in Medium](https://medium.com/@lchlaw/tutorial-run-prometheus-node-exporter-using-daemon-set-for-kubernetes-service-discovery-c38421d548ed) and [this other one found in GeeksForGeeks](https://www.geeksforgeeks.org/devops/setup-prometheus-node-exporter-on-kubernetes/).

## Kustomize project folders for Prometheus Node Exporter

Start by creating the folders needed for the corresponding Kustomize project:

~~~sh
$ mkdir -p $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources
~~~

## Prometheus Node Exporter DaemonSet

The Prometheus Node Exporter service does not require to store anything but, instead of using a `Deployment` resource, you will declare its pod in a [`DaemonSet`](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/). This is because the node exporter is essentially an agent that gets metrics from the Linux subsystem of the Kubernetes cluster nodes, and you want to get those values from all your K3s cluster's nodes. With a `DaemonSet` you can replicate a pod in all your nodes automatically, right what you want for this service:

1. Create a file named `agent-prometheus-node-exporter.daemonset.yaml` under the `agent-prometheus-node-exporter/resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.daemonset.yaml
    ~~~

2. Declare the DaemonSet for the Prometheus Node Exporter in the `agent-prometheus-node-exporter.daemonset.yaml` file:

    ~~~yaml
    # Prometheus Node Exporter DaemonSet for a regular pod
    apiVersion: apps/v1
    kind: DaemonSet

    metadata:
      name: agent-prometheus-node-exporter
    spec:
      template:
        spec:
          containers:
          - name: metrics
            image: prom/node-exporter:v1.10.2
            args:
            - --path.sysfs=/host/sys
            - --path.rootfs=/host/root
            - --no-collector.hwmon
            - --no-collector.wifi
            - --collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)
            - --collector.netclass.ignored-devices=^(veth.*)$
            ports:
            - containerPort: 9100
              name: metrics
              protocol: TCP
            resources:
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
          - effect: NoSchedule
            operator: Exists
    ~~~

    This `DaemonSet` resource has some particularities in its `spec.template.spec` block:

    - `metrics` container:\
      Executes the Prometheus Node Exporter service:

      - In the `args` section you have several options configured:

        - `--path.sysfs` and `--path.rootfs` indicate what are the root (`/`) and sys folder (`/sys`) paths that the agent has to monitor in the nodes. These paths are enabled in the `volumeMounts` and `volumes` sections as `hostPath` routes.

        - The `no-collector` options disable specific data collectors. In this case, the `hwmon`, which exposes hardware and sensor data, and the `wifi`, to not collect stats from wifi interfaces.

        - The last two `collector` options are just patterns that leave out, from the metrics collected, the storage devices and the virtual Ethernet devices created by the Kubernetes engine for the containers.

      - The `volumes` and `volumeMounts` refer to paths from the K3s cluster nodes themselves, invoked with the `hostPath` declarations. The paths indicated for the `hostPath` volumes are correct for a Debian Linux system like the ones running your nodes, but you should be careful of validating them whenever you use some other Linux distribution.

    - `tolerations`:\
      As it was specified in the [Kube State Metrics deployment](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-deployment), you need this section to allow the Prometheus Node Exporter pod to be scheduled in nodes that have the `NoSchedule` taint. Remember that [your K3s server node is tainted to not allow any kind of workload being scheduled in it](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file).

## Prometheus Node Exporter Service

Declare the necessary `Service` resource for completing this Prometheus Node Exporter setup:

1. Generate an `agent-prometheus-node-exporter.service.yaml` under the `agent-prometheus-node-exporter/resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.service.yaml
    ~~~

2. Declare the `Service` in `agent-prometheus-node-exporter.service.yaml`:

    ~~~yaml
    # Prometheus Node Exporter headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: agent-prometheus-node-exporter
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port:   '9100'
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - name: metrics
        protocol: TCP
        port: 9100
        targetPort: metrics
    ~~~

    There is nothing special about this service. Just notice that it does have the annotations to inform Prometheus that it can scrape metrics from this service.

### Service's absolute internal FQDN

As a component of the monitoring stack, this headless service is going to be placed under the `monitoring` namespace. This means that its absolute _Fully Qualified Domain Name_ (_FQDN_) will be:

~~~http
agent-prometheus-node-exporter.monitoring.svc.homelab.cluster.
~~~

## Prometheus Node Exporter Kustomize project

The last thing to declare is the `Kustomization` manifest for this Prometheus Node Exporter project:

1. Create a `kustomization.yaml` file in the `agent-prometheus-node-exporter` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/kustomization.yaml
    ~~~

2. Declare your `Kustomization` manifest in the `kustomization.yaml` file:

    ~~~yaml
    # Prometheus Node Exporter setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
    - pairs:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
      includeSelectors: true
      includeTemplates: true

    resources:
    - resources/agent-prometheus-node-exporter.daemonset.yaml
    - resources/agent-prometheus-node-exporter.service.yaml

    images:
    - name: prom/node-exporter
      newTag: v1.10.2
    ~~~

    The `labels` are the same ones declared [in one of the articles used as reference for this guide](https://medium.com/@lchlaw/tutorial-run-prometheus-node-exporter-using-daemon-set-for-kubernetes-service-discovery-c38421d548ed). Something else you can notice is that there is no `replicas` section. The `DaemonSet` itself takes care automatically of putting one replica of the generated pod on each cluster node.

### Validating the Kustomize YAML output

Proceed now to validate the Kustomize project for your Prometheus Node Exporter service.

1. Dump the output of this Kustomize project in a file named `agent-prometheus-node-exporter.k.output.yaml` (or redirect it to your preferred text editor):

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter > agent-prometheus-node-exporter.k.output.yaml
    ~~~

2. Open the `agent-prometheus-node-exporter.k.output.yaml` file and compare your resulting YAML output with the one below:

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
      clusterIP: None
      ports:
      - name: metrics
        port: 9100
        protocol: TCP
        targetPort: metrics
      selector:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: node-exporter
      type: ClusterIP
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
            - --no-collector.hwmon
            - --no-collector.wifi
            - --collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)
            - --collector.netclass.ignored-devices=^(veth.*)$
            image: prom/node-exporter:v1.10.2
            name: metrics
            ports:
            - containerPort: 9100
              name: metrics
              protocol: TCP
            resources:
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
          - effect: NoSchedule
            operator: Exists
          volumes:
          - hostPath:
              path: /sys
            name: sys
          - hostPath:
              path: /
            name: root
    ~~~

    There is nothing new in this output for you this far in the guide. Just be sure that all values are correct and the labels appear where they should.

## Do not deploy this Prometheus Node Exporter project on its own

This Prometheus Node Exporter is a component part of a bigger project yet to be completed: your monitoring stack. Wait until reaching the final part of this chapter G035 where you will have every component ready for deploying in your cluster.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.daemonset.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-prometheus-node-exporter/resources/agent-prometheus-node-exporter.service.yaml`

## References

### Prometheus Node Exporter

- [GitHub. Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [Docker. Hub. Prometheus Node Exporter container image](https://hub.docker.com/r/prom/node-exporter)

- [Prometheus. Docs. Guides](https://prometheus.io/docs/guides/)
  - [Monitoring Linux host metrics with the Node Exporter](https://prometheus.io/docs/guides/node-exporter/)

### Other contents about Prometheus Node Exporter

- [Medium. Ichlaw. Tutorial: Run Prometheus Node Exporter using Daemon Set for Kubernetes Service Discovery](https://medium.com/@lchlaw/tutorial-run-prometheus-node-exporter-using-daemon-set-for-kubernetes-service-discovery-c38421d548ed)
- [GeeksForGeeks. Setup Prometheus Node Exporter on Kubernetes](https://www.geeksforgeeks.org/devops/setup-prometheus-node-exporter-on-kubernetes/)

### [Kubernetes](https://kubernetes.io/docs/)

#### DaemonSet

- [Concepts. Workloads. Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
  - [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

#### Pods Scheduling

- [Concepts. Scheduling, Preemption and Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/)
  - [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

### Other Kubernetes-related contents

#### About DaemonSets

- [K8s: Deployments vs StatefulSets vs DaemonSets](https://medium.com/stakater/k8s-deployments-vs-statefulsets-vs-daemonsets-60582f0c62d4)
- [Difference between daemonsets and deployments](https://stackoverflow.com/questions/53888389/difference-between-daemonsets-and-deployments)

#### About pods scheduling

- [Theodo. Working with taints and tolerations in Kubernetes](https://www.theodo.com/en-fr/blog/working-with-taints-and-tolerations-in-kubernetes)
- [GitHub. K3s. Issues. Node taint k3s-controlplane=true:NoExecute](https://github.com/k3s-io/k3s/issues/1401)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 2**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 4**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md)
