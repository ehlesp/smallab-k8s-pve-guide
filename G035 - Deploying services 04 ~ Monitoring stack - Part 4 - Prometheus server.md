# G035 - Deploying services 04 ~ Monitoring stack - Part 4 - Prometheus server

- [Prometheus is the core of your monitoring stack](#prometheus-is-the-core-of-your-monitoring-stack)
- [Kustomize project folders for Prometheus server](#kustomize-project-folders-for-prometheus-server)
- [Prometheus configuration files](#prometheus-configuration-files)
  - [Configuration file `prometheus.yaml`](#configuration-file-prometheusyaml)
  - [Configuration file `prometheus.rules.yaml`](#configuration-file-prometheusrulesyaml)
- [Prometheus server persistent storage claim](#prometheus-server-persistent-storage-claim)
- [Prometheus server StatefulSet](#prometheus-server-statefulset)
- [Prometheus server Service](#prometheus-server-service)
- [Prometheus server's Kustomize project](#prometheus-servers-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Prometheus server project on its own](#do-not-deploy-this-prometheus-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Prometheus](#prometheus)
  - [Other Prometheus-related contents](#other-prometheus-related-contents)
  - [Kubernetes](#kubernetes)
- [Navigation](#navigation)

## Prometheus is the core of your monitoring stack

The core component of your monitoring stack is the Prometheus server, and you will prepare its deployment in this part. Here, you will see YAML manifests that are modified versions from the ones in [this GitHub page](https://github.com/bibinwilson/kubernetes-prometheus), which were made for [this guide](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/).

## Kustomize project folders for Prometheus server

Create the folder structure of the Kustomize project for your Prometheus server:

~~~sh
$ mkdir -p $HOME/k8sprjs/monitoring/components/server-prometheus/{resources,configs}
~~~

## Prometheus configuration files

Prometheus is configured with a combination of command-line parameters and a configuration file, but it also uses other files to configure what are called "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules.

### Configuration file `prometheus.yaml`

The configuration file for Prometheus is a YAML file for configuring the scraping jobs your Prometheus server will run. On the other hand, this file is also where you indicate to Prometheus which recording and alerting rule files to load and what alert manager services to use:

1. Create a `prometheus.yaml` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml
    ~~~

2. Enter the Prometheus configuration in the `prometheus.yaml` file:

    ~~~yaml
    # Prometheus main configuration file

    global:
      scrape_interval: 20s
      evaluation_interval: 25s

    rule_files:
    - /etc/prometheus/prometheus.rules.yaml

    alerting:
      alertmanagers:
      - scheme: http
        static_configs:
        - targets:
    #      - "alertmanager.monitoring.svc:9093"

    scrape_configs:
    - job_name: 'kubernetes-apiservers'
      scrape_interval: 60s
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

    - job_name: 'kubernetes-nodes'
      scrape_interval: 55s
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics

    - job_name: 'kubernetes-pods'
      scrape_interval: 30s
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

    - job_name: 'kubernetes-cadvisor'
      scrape_interval: 180s
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

    - job_name: 'kubernetes-service-endpoints'
      scrape_interval: 45s
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name

    - job_name: 'kube-state-metrics'
      scrape_interval: 50s
      static_configs:
      - targets: ['agent-kube-state-metrics.monitoring.svc:8080']

    - job_name: 'node-exporter'
      scrape_interval: 65s
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_endpoints_name]
        regex: '.*node-exporter'
        action: keep
    ~~~

    There are several sections to understand in this `prometheus.yaml` file:

    - `global`\
      This section holds parameters that affects other configuration contexts of the Prometheus instance, and is also the place for setting up default values that apply to other configuration sections:

      - `scrape_interval`\
        Default scrape frequency of targets. Although this depends more on how many scraping targets you have, in general the shorter the time the bigger the hit on performance.

      - `evaluation_interval`\
        How frequently Prometheus has to evaluate recording and alerting rules. Again, you should be careful of not making this time too short, specially if you are using many or particularly complex rules, or your system's performance could degrade noticeably.

    - `rule_files`\
      List of files that hold the recording or alerting rules to apply on the Prometheus instance. The one present in this case is just an example, since this guide's Prometheus setup will not use rules.

    - `alerting`\
      This section is for configuring the connection to the Alertmanager instances where to send the alerts from this Prometheus instance. The configuration block shown in this file is just an example, since this Prometheus setup will not send alerts.

    - `scrape_configs`\
      Section where you set up the scraping targets from where your Prometheus instance will get the metrics to monitor. Each scraping target is a job with its own configuration:

      - `kubernetes-apiservers`\
        For scraping the API servers exposed by the Kubernetes system itself.

      - `kubernetes-nodes`\
        Scrapes metrics from the cluster nodes, although not directly from them but proxying the scrape through the corresponding Kubernetes API server.

        - In this job configuration, you have the address `kubernetes.default.svc.:443` set up in it, which points at the internal cluster IP of the `kubernetes` service running in the `default` namespace.

      - `kubernetes-pods`\
        Scrapes metrics **only from pods that have been annotated with `prometheus.io` labels**.

      - `kubernetes-cadvisor`\
        Scrapes the Kubelet cAdvisor metrics.

        - As in the `kubernetes-nodes` section, here you also have a reference to the `kubernetes.default.svc:443` address.

      - `kubernetes-service-endpoints`\
        Generic scraper of metrics from `Service` resources endpoints, but **only from those annotated with `prometheus.io` labels**.

      - `kube-state-metrics`\
        Scrapes metrics from the Kube State Metrics service [you have declared in the second part of this chapter G035](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md).

        - In this job you have specified the internal cluster FQDN or hostname with the port to connect with the Kube State Metrics service, which is `agent-kube-state-metrics.monitoring.svc:8080`.

      - `node-exporter`\
        Scrapes metrics from the Prometheus Node Exporter [you already prepared in the previous third part](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md).

      Notice that each of these scraping jobs have their own particularities, like a different `scrape_interval` or `relabel_configs` to suit their own needs. To know more about all those parameters, better check out the [official Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).

### Configuration file `prometheus.rules.yaml`

In this guide, The `prometheus.rules.yaml` file contains just a simple example with one alerting rule to use with an Alertmanager instance:

> [!NOTE]
> **Learn more about Prometheus rules in its official documentation**\
> To know more about the Prometheus rules, remember to check out the official documentation about "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules

1. Create the file `prometheus.rules.yaml` file in the `configs` folder.

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml
    ~~~

2. Enter the  below in `prometheus.rules.yaml`.

    ~~~yaml
    # Example of alerting rule for Prometheus

    groups:
    - name: example_alert_rules_group_unique_name
      rules:
      - alert: HighRequestLatency
        expr: job:request_latency_seconds:mean5m{job="node-exporter"} > 0.5
        for: 10m
        labels:
          severity: page
        annotations:
          summary: High request latency
    ~~~

    Just a couple of things to highlight from this configuration:

    - The `name` of each group has to be a **string unique within the file**.

    - A group can hold several rules, and each rule can be of a different nature (alerting or recording). Depending on your requirements, you should carefully consider if you want to mix them together in the same file or not.

    - The alerting rules syntax has a few more parameters for recording rules.

## Prometheus server persistent storage claim

In the [first part of this chapter G035](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#lvm-storage-set-up), you have prepared a 10 GiB LVM PV in the `k3sagent02` for storing the Prometheus server data. Now you need to declare a persistent volume claim to connect your Prometheus server with that PV:

1. Create a file named `server-prometheus.persistentvolumeclaim.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.persistentvolumeclaim.yaml
    ~~~

2. Declare the `PersistentVolumeClaim` for the Prometheus server in `server-prometheus.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Prometheus server claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-prometheus
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: monitoring-ssd-prometheus-data
      resources:
        requests:
          storage: 9.8G
    ~~~

## Prometheus server StatefulSet

Since your Prometheus server will store data, you better deploy it with a `StatefulSet`:

1. Create a `server-prometheus.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.statefulset.yaml
    ~~~

2. Declare your Prometheus server's `StatefulSet` in `server-prometheus.statefulset.yaml`:

    ~~~yaml
    # Prometheus server StatefulSet for a regular pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-prometheus
    spec:
      replicas: 1
      serviceName: server-prometheus
      template:
        spec:
          securityContext:
            fsGroup: 65534
            fsGroupChangePolicy: OnRootMismatch
          containers:
          - name: server
            image: prom/prometheus:v3.9.1
            ports:
            - containerPort: 9090
              name: server
            args:
            - "--config.file=/etc/prometheus/prometheus.yaml"
            - "--storage.tsdb.path=/prometheus"
            - "--storage.tsdb.retention.time=1w"
            - "--storage.tsdb.retention.size=8GB"
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - name: prometheus-config
              subPath: prometheus.yaml
              mountPath: /etc/prometheus/prometheus.yaml
            - name: prometheus-config
              subPath: prometheus.rules.yaml
              mountPath: /etc/prometheus/prometheus.rules.yaml
            - name: prometheus-storage
              mountPath: /prometheus
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              runAsNonRoot: true
              runAsUser: 65534
              runAsGroup: 65534
          automountServiceAccountToken: false
          hostAliases:
          - ip: "10.7.0.1"
            hostnames:
            - "prometheus.homelab.cloud"
          volumes:
          - name: prometheus-config
            configMap:
              name: server-prometheus-config
              defaultMode: 420
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
          - name: prometheus-storage
            persistentVolumeClaim:
              claimName: server-prometheus
    ~~~

    This `StatefulSet` declares a pod with a single container run with a non-root `65534` user (and group) with almost the same `securityContext` configuration specified for the [Forgejo server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-statefulset). Beyond those similarities, the main particularities of this `StatefulSet` for a Prometheus server are:

    - `server` container\
      There is only one container in this pod which runs the Prometheus server itself:

      - The `image` is for the version `3.9.1` of Prometheus, built on a compact distroless version of Linux.

      - The `ports` only lists the `server` one opened by the container on the port `9090`, which is the default one for Prometheus.

      - The `args` section lists important Prometheus configuration parameters:

        - `--config.file`\
          Points to the absolute path where the main Prometheus configuration file will be found.

        - `--storage.tsdb.path`\
          Absolute path to the folder containing the files of the Prometheus metrics database.

        - `--storage.tsdb.retention.time`\
          Specifies for how long Prometheus has to retain metrics in its database before purging them.

        - `--storage.tsdb.retention.size`\
          Delimits the storage room available to Prometheus for retaining metrics in its database. [The Prometheus documentation recommends this retention size to be 80-85% of the total available Prometheus storage space](https://prometheus.io/docs/prometheus/latest/storage/#right-sizing-retention-size).

      - `volumeMounts` section\
        Mounts two Prometheus configuration files and the storage for the retained metrics database:

        - `prometheus.yaml`\
          The main Prometheus configuration file.

        - `prometheus.rules.yaml`\
          A configuration file with alert rules for Prometheus.

        - `/prometheus`\
          Folder where Prometheus will keep the files for its retained metrics database.

## Prometheus server Service

To make Prometheus usable, you need to create it's corresponding `Service` object:

1. Create a file named `server-prometheus.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml
    ~~~

2. Edit `server-prometheus.service.yaml` and put the following yaml in it.

    ~~~yaml
    # Prometheus server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-prometheus
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - name: server
        port: 9090
        targetPort: server
        protocol: TCP
    ~~~

    This is a headless `Service` like all the others you have seen in previous chapters of this guide. There is just one rather obvious detail to realize here. Since Prometheus has (or should have) direct access to its own metrics already, you do not need to label this service with `prometheus.io` annotations for granting Prometheus with access to the metrics of its own server.

    On the other hand, be aware that this service will be reachable with the FQDN `server-prometheus.monitoring`.

## Prometheus server's Kustomize project

After declaring all the required resources for the Prometheus server, you need to put them together under a `kustomization.yaml` file:

1. Create a `kustomization.yaml` file in the `server-prometheus` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the following yaml.

    ~~~yaml
    # Prometheus server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app: server-prometheus
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/server-prometheus.persistentvolumeclaim.yaml
    - resources/server-prometheus.service.yaml
    - resources/server-prometheus.statefulset.yaml

    replicas:
    - name: server-prometheus
      count: 1

    images:
    - name: prom/prometheus
      newTag: v3.9.1

    configMapGenerator:
    - name: server-prometheus
      files:
      - configs/prometheus.rules.yaml
      - configs/prometheus.yaml
    ~~~

    Nothing special to remark from this `kustomization.yaml` beyond that, since there are no secrets in this Prometheus server setup, there is no `secretGenerator` block.

### Validating the Kustomize YAML output

As in previous cases, you must check the output of this Kustomize project:

1. Dump the YAML output with `kubectl kustomize` to a `server-prometheus.k.output.yaml` file (or just redirect the output to a text editor):

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/server-prometheus > server-prometheus.k.output.yaml
    ~~~

2. Open the `server-prometheus.k.output.yaml`, it should be like this YAML:

    ~~~yaml
    apiVersion: v1
    data:
      prometheus.rules.yaml: |-
        # Example of alerting rule for Prometheus

        groups:
        - name: example_alert_rules_group_unique_name
          rules:
          - alert: HighRequestLatency
            expr: job:request_latency_seconds:mean5m{job="node-exporter"} > 0.5
            for: 10m
            labels:
              severity: page
            annotations:
              summary: High request latency
      prometheus.yaml: |-
        # Prometheus main configuration file

        global:
          scrape_interval: 20s
          evaluation_interval: 25s

        rule_files:
        - /etc/prometheus/prometheus.rules.yaml

        alerting:
          alertmanagers:
          - scheme: http
            static_configs:
            - targets:
        #      - "alertmanager.monitoring.svc:9093"

        scrape_configs:
        - job_name: 'kubernetes-apiservers'
          scrape_interval: 60s
          kubernetes_sd_configs:
          - role: endpoints
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          relabel_configs:
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            action: keep
            regex: default;kubernetes;https

        - job_name: 'kubernetes-nodes'
          scrape_interval: 55s
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs:
          - role: node
          relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/${1}/proxy/metrics

        - job_name: 'kubernetes-pods'
          scrape_interval: 30s
          kubernetes_sd_configs:
          - role: pod
          relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name

        - job_name: 'kubernetes-cadvisor'
          scrape_interval: 180s
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs:
          - role: node
          relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

        - job_name: 'kubernetes-service-endpoints'
          scrape_interval: 45s
          kubernetes_sd_configs:
          - role: endpoints
          relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (https?)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name

        - job_name: 'kube-state-metrics'
          scrape_interval: 50s
          static_configs:
          - targets: ['agent-kube-state-metrics.monitoring.svc:8080']

        - job_name: 'node-exporter'
          scrape_interval: 65s
          kubernetes_sd_configs:
          - role: endpoints
          relabel_configs:
          - source_labels: [__meta_kubernetes_endpoints_name]
            regex: '.*node-exporter'
            action: keep
    kind: ConfigMap
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus-d5ctf89456
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 9090
        protocol: TCP
        targetPort: server
      selector:
        app: server-prometheus
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.8G
      storageClassName: local-path
      volumeName: monitoring-ssd-prometheus-data
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-prometheus
      serviceName: server-prometheus
      template:
        metadata:
          labels:
            app: server-prometheus
        spec:
          automountServiceAccountToken: false
          containers:
          - args:
            - --config.file=/etc/prometheus/prometheus.yaml
            - --storage.tsdb.path=/prometheus
            - --storage.tsdb.retention.time=1w
            - --storage.tsdb.retention.size=8GB
            image: prom/prometheus:v3.9.1
            name: server
            ports:
            - containerPort: 9090
              name: server
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              runAsGroup: 65534
              runAsNonRoot: true
              runAsUser: 65534
            volumeMounts:
            - mountPath: /etc/prometheus/prometheus.yaml
              name: prometheus-config
              subPath: prometheus.yaml
            - mountPath: /etc/prometheus/prometheus.rules.yaml
              name: prometheus-config
              subPath: prometheus.rules.yaml
            - mountPath: /prometheus
              name: prometheus-storage
          hostAliases:
          - hostnames:
            - prometheus.homelab.cloud
            ip: 10.7.0.1
          securityContext:
            fsGroup: 65534
            fsGroupChangePolicy: OnRootMismatch
          volumes:
          - configMap:
              defaultMode: 420
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
              name: server-prometheus-config
            name: prometheus-config
          - name: prometheus-storage
            persistentVolumeClaim:
              claimName: server-prometheus
    ~~~

    Nothing new to highlight here. Just remember to check that all values are correct and the labels appear in the proper places.

## Do not deploy this Prometheus server project on its own

This Prometheus server cannot be deployed on its own because is missing several elements, such as the persistent volume required by the PVC and also a Traefik ingress to give access to this . All the missing elements will be declared and put together with all the other componentes in the final part of this monitoring stack deployment chapter.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/server-prometheus`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.statefulset.yaml`

## References

### [Prometheus](https://prometheus.io/)

- [Docs. Prometheus Server](https://prometheus.io/docs/prometheus/latest/getting_started/)
  - [Installation](https://prometheus.io/docs/prometheus/latest/installation/)
  - [Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
    - [Recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
    - [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
  - [Storage](https://prometheus.io/docs/prometheus/latest/storage/)
    - [Local Storage. Right-Sizing Retention Size](https://prometheus.io/docs/prometheus/latest/storage/#right-sizing-retention-size)

- [GitHub. Prometheus](https://github.com/prometheus/prometheus)

- [Docker Hub. Prometheus](https://hub.docker.com/r/prom/prometheus)

### Other Prometheus-related contents

- [DevOpsCube. How to Setup Prometheus Monitoring On Kubernetes Cluster](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
  - [GitHub. kubernetes prometheus Setup](https://github.com/techiescamp/kubernetes-prometheus/)

- [GeeksForGeeks. Kubernetes Prometheus](https://www.geeksforgeeks.org/devops/kubernetes-prometheus/)
- [PhoenixNAP. How to Install Prometheus on Kubernetes and Use It for Monitoring](https://phoenixnap.com/kb/prometheus-kubernetes)
- [MetricFire. How to deploy Prometheus on Kubernetes](https://www.metricfire.com/blog/how-to-deploy-prometheus-on-kubernetes/)
- [Medium. Codex. Reliable Kubernetes on a Raspberry Pi Cluster: Monitoring](https://medium.com/codex/reliable-kubernetes-on-a-raspberry-pi-cluster-monitoring-a771b497d4d3)
- [Sysdig. Kubernetes monitoring with Prometheus, the ultimate guide](https://www.sysdig.com/blog/kubernetes-monitoring-prometheus)
- [Sysdig. Kubernetes Monitoring with Prometheus: AlertManager, Grafana, PushGateway (part 2).](https://www.sysdig.com/blog/kubernetes-monitoring-with-prometheus-alertmanager-grafana-pushgateway-part-2)
- [GitHub. AWS. EKS Charts. Issues. prometheus: Unable to create mmap-ed active query log](https://github.com/aws/eks-charts/issues/21)
- [GitHub. Files to accompany the How deploy Prometheus on Kubernetes video](https://github.com/shevyf/prom_on_k8s_howto)

### [Kubernetes](https://kubernetes.io/docs/)

- [Tasks. Configure Pods and Containers. Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

- [Reference. Kubernetes API. Workload Resources. Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
  - [Security context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 3**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 5**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md)
