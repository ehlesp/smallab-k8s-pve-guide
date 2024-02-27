# G035 - Deploying services 04 ~ Monitoring stack - Part 4 - Prometheus server

The core component of your monitoring stack is the Prometheus server, which you'll setup in this guide. Here, you'll see yamls that are modified versions from the ones in [this GitHub page](https://github.com/bibinwilson/kubernetes-prometheus), which were made for [this guide](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/).

## Kustomize project folders for Prometheus server

Create the folder structure of the Kustomize project for your Prometheus server.

~~~bash
$ mkdir -p $HOME/k8sprjs/monitoring/components/server-prometheus/{resources,configs}
~~~

## Prometheus configuration files

Prometheus is configured with a combination of command-line parameters and a configuration file, but it also uses other files to configure what are called "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules.

### _Configuration file `prometheus.yaml`_

The configuration file for Prometheus is a yaml file mainly meant for configuring the scraping jobs your Prometheus server will run. On the other hand, this file is also where you indicate to Prometheus which recording and alerting rule files to load and what alert manager services to use.

1. Create a `prometheus.yaml` file in the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml
    ~~~

2. Put the following yaml in `prometheus.yaml`.

    ~~~yaml
    # Prometheus main configuration file

    global:
      scrape_interval: 60s
      evaluation_interval: 60s

    rule_files:
      - /etc/prometheus/prometheus_alerts.rules.yaml

    alerting:
      alertmanagers:
      - scheme: http
        static_configs:
        - targets:
        #  - "mntr-alertmanager.monitoring.svc.deimos.cluster.io:9093"

    scrape_configs:
      - job_name: 'kubernetes-apiservers'
        scrape_interval: 180s
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
        scrape_interval: 120s
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
          replacement: kubernetes.default.svc.deimos.cluster.io:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics

      - job_name: 'kubernetes-pods'
        scrape_interval: 240s
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
          replacement: kubernetes.default.svc.deimos.cluster.io:443
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
        tls_config:
          insecure_skip_verify: true

      - job_name: 'kube-state-metrics'
        scrape_interval: 50s
        static_configs:
          - targets: ['mntr-agent-kube-state-metrics.monitoring.svc.deimos.cluster.io:8080']

      - job_name: 'node-exporter'
        scrape_interval: 55s
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
        - source_labels: [__meta_kubernetes_endpoints_name]
          regex: '.*node-exporter'
          action: keep
    ~~~

    Let's see the main points of this `prometheus.yaml` file.

    - `global`: this section holds parameters that affects other configuration contexts of the Prometheus instance, and is also the place for setting up default values that apply to other configuration sections.
        - `scrape_interval`: how frequently to scrape targets by default. Although this depends more on how many scraping targets you have, in general the shorter the time the bigger the hit on performance.
        - `evaluation_interval`: how frequently to evaluate recording and alerting rules. Again, you should be careful of not making this time too short, specially if you're using many or particularly complex rules, or your system's performance could degrade noticeably.

    - `rule_files`: here you list the files that hold the recording or alerting rules you want to apply on the Prometheus instance. The one present in this case is just an example, since this Prometheus setup won't use rules.

    - `alerting`: this section is for configuring the connection to the Alertmanager instances where to send the alerts from this Prometheus instance. The configuration block shown in this file is just an example, this Prometheus setup won't send alerts.

    - `scrape_configs`: the section where you set up the scraping targets from where your Prometheus instance will get the stats to monitor. Each scraping target is a job with it's own configuration.
        - `kubernetes-apiservers`: for scraping the API servers exposed by the Kubernetes system itself.
        - `kubernetes-nodes`: scrapes stats from the nodes, although not directly from them but proxying the scrape through the corresponding Kubernetes API server.
            - In this job configuration, you have the address `kubernetes.default.svc.deimos.cluster.io:443` set up in it, which points at the internal cluster IP of the `kubernetes` service running in the `default` namespace.
        - `kubernetes-pods`: scrapes metrics **from pods that have been annotated with `prometheus.io` tags**.
        - `kubernetes-cadvisor`: scrapes the Kubelet cAdvisor metrics.
            - As in the `kubernetes-nodes` section, here you also have a reference to the `kubernetes.default.svc.deimos.cluster.io:443` address.
        - `kubernetes-service-endpoints`: generic scraper of metrics from `Service` resources endpoints, but **only from those annotated with `prometheus.io` tags**.
            > **BEWARE!**  
            > In this section there's also a `tls_config` block in which the parameter `insecure_skip_verify` is set to `true`. This is necessary because, if you remember, your [Gitea server's metrics are accessible only through HTTPS](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-service-resource) and the certificate used (your wildcard one) is not valid. This means that, when Prometheus tries to scrape from Gitea's endpoint, the connection will fail if it attempts to validate the certificate.
            > This is **not** an ideal configuration, but the only available as long as you use a self-generated certificate.
        - `kube-state-metrics`: scrapes metrics from the Kube State Metrics service you defined in its related [guide](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md).
            - Notice how in this job you have specified the address with the port to connect with the Kube State Metrics service, which is `mntr-agent-kube-state-metrics.monitoring.svc.deimos.cluster.io:8080`.
        - `node-exporter`: scrapes metrics from the Prometheus Node Exporter you already prepared in the previous [guide](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md).

        Notice that each of these scraping jobs have their own particularities, like a different `scrape_interval` or `relabel_configs` to suit their own needs. To know more about all those parameters, better check out the [official Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).

### _Configuration file `prometheus.rules.yaml`_

This yaml file you'll see next is just a simple example with one alerting rule to use with an Alertmanager instance. To know more about the Prometheus rules, remember to check out the official documentation about "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules.

1. Create the file `prometheus.rules.yaml` file in the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml
    ~~~

2. Put the yaml below in `prometheus.rules.yaml`.

    ~~~yaml
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

    Just a couple of things to highlight from the yaml above.

    - The `name` of each group has to be a string unique **within** the file.
    - A group can hold several rules, and each rule could be of a different nature (alerting or recording). Depending on your requirements, you should consider carefully if you want to mix them together in the same file or not.
    - The alerting rules syntax has a few more parameters than that for recording rules.

## Prometheus server storage

In the [first part](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#lvm-storage-set-up) of this guide, you've prepared a 10 GiB LVM PV in the `k3sagent02` meant for the Prometheus server data. Then, you need to declare a persistent volume claim to connect your Prometheus server with that PV.

### _Claim for the server files PV_

1. Create a file named `data-server-prometheus.persistentvolumeclaim.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/data-server-prometheus.persistentvolumeclaim.yaml
    ~~~

2. Copy the yaml below in `data-server-prometheus.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: data-server-prometheus
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: data-prometheus
      resources:
        requests:
          storage: 9.8G
    ~~~

## Prometheus server StatefulSet resource

Since you'll store some data with your Prometheus server, you'll better deploy it as a `StatefulSet` resource.

1. Create a `server-prometheus.statefulset.yaml` file under the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.statefulset.yaml
    ~~~

2. Copy the yaml declaration below in `server-prometheus.statefulset.yaml`.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-prometheus
    spec:
      replicas: 1
      serviceName: server-prometheus
      template:
        spec:
          containers:
          - name: server
            image: prom/prometheus:v2.35.0
            ports:
            - containerPort: 9090
              name: http
            args:
            - "--storage.tsdb.retention.time=12h"
            - "--config.file=/etc/prometheus/prometheus.yaml"
            - "--storage.tsdb.path=/prometheus"
            resources:
              requests:
                cpu: 500m
                memory: 256Mi
              limits:
                cpu: 1000m
                memory: 512Mi
            volumeMounts:
            - name: server-prometheus-config
              subPath: prometheus.yaml
              mountPath: /etc/prometheus/prometheus.yaml
            - name: server-prometheus-config
              subPath: prometheus.rules.yaml
              mountPath: /etc/prometheus/prometheus.rules.yaml
            - name: server-prometheus-storage
              mountPath: /prometheus
          securityContext:
            fsGroup: 65534
            runAsUser: 65534
            runAsGroup: 65534
            runAsNonRoot: true
          volumes:
          - name: server-prometheus-config
            configMap:
              name: server-prometheus
              defaultMode: 420
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
          - name: server-prometheus-storage
            persistentVolumeClaim:
              claimName: data-server-prometheus
    ~~~

    There are just a few things to highlight in this `StatefulSet`.

    - `server` container: there's only one container in this pod.

        - The `image` is for the version `2.35.0` of Prometheus, built on a compact Linux distribution.

        - The `ports` only lists the `http` one opened by the container on the port `9090`.

            > **BEWARE!**  
            > In this setup, the Prometheus server runs a non-secured HTTP configuration. This is no problem because you'll secure the connections to it through Traefik later.

        - In `args` there are three important parameters:
            - `--storage.tsdb.retention.time`: specifies for how long Prometheus has to keep the metrics in its database before purging them.
            - `--config.file`: points to the absolute path where the config file for Prometheus is stored.
            - `--storage.tsdb.path`: absolute path to the folder containing the files of the Prometheus' metrics database.

        - `securityContext`: unlike other containers you've seen in previous guides of this series, the Prometheus container needs some particular security attributes defined in a [`securityContext` section](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context), as in the yaml above, to allow it to access its persistent volume.
            - `fsGroup`: changes the persistent volume's group ownership to the indicated GID, which in this case is `65534`. Within the Prometheus container, `65534` is translated to the `nobody` group, while from the perspective of the Debian K3s agent node running the container `65534` is the group called `nogroup`.
            - `runAsUser`: forces the container to run under a different user than the one specified by its image. The user is specified by its UID, which in this case is `65534` that equals to `nobody`. This user's name is the same both within the Prometheus container and for the Debian K3s agent node running it.
            - `runAsGroup`: forces the container to run with the group indicated by the GID, not the one indicated by its image. In the yaml, the mandated group is the `nobody`/`nogroup` one, with the GID `65534`.
            - `runAsNonRoot`: forces the container to run with a non-root user. This makes the Kubernetes engine validates that the container doesn't run with the UID `0` (the `root` one). If it tried to run with `root`, the container would fail to start.

        - `volumeMounts` section: mounts two Prometheus config files and the storage for the metrics database.
            - `prometheus.yaml`: the main Prometheus configuration file.
            - `prometheus.rules.yaml`: a file with alert rules for Prometheus.
            - `/prometheus`: folder that'll store the files for the Prometheus' metrics database.

## Prometheus server Service resource

To make Prometheus usable, you need to create it's corresponding `Service` resource.

1. Create a file named `server-prometheus.service.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml
    ~~~

2. Edit `server-prometheus.service.yaml` and put the following yaml in it.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: server-prometheus
    spec:
      type: ClusterIP
      ports:
      - port: 443
        targetPort: 9090
        protocol: TCP
        name: http
    ~~~

    This `Service` declaration is simple but serves its purpose.
    - Unlike in the Nextcloud or Gitea cases, here the Prometheus service is not of type `LoadBalancer` but `ClusterIP`. This is because you'll make this `Service` accesible through Traefik.
    - In the `metadata` section there are no `prometheus.io` annotations.
    - There's only one `port` listed, and it redirects from `443` to the same unsecured `http` port listening at `9090` in the Prometheus' server container.

        > **BEWARE!**  
        > The port redirection is meant to make the Prometheus server reachable through the standard HTTPS port `443`. Mind you that the port only doesn't make the connection secure, something you'll achieve with a Traefik IngressRoute resource later.

### _Prometheus Server `Service`'s FQDN or DNS record_

Since in this monitoring stack you'll have a Grafana interface connected with this Prometheus server, you better know early what FQDN this service will have in the cluster, following (again) the same criteria [as with the Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-services-fqdn-or-dns-record). The DNS record should be as the one below.

~~~http
mntr-server-prometheus.monitoring.svc.deimos.cluster.io
~~~

## Prometheus server Traefik IngressRoute resource

To make the Prometheus server's service reachable only through HTTPS from outside the Kubernetes cluster, let's set up a Traefik IngressRoute just for that.

1. Generate a new file named `server-prometheus.ingressroute.traefik.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.ingressroute.traefik.yaml
    ~~~

2. Edit `server-prometheus.ingressroute.traefik.yaml` and put the following yaml in it.

    ~~~yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute

    metadata:
      name: server-prometheus
    spec:
      entryPoints:
        - websecure
      tls:
        secretName: wildcard.deimos.cloud-tls
      routes:
      - match: Host(`prometheus.deimos.cloud`) || Host(`prm.deimos.cloud`)
        kind: Rule
        services:
        - name: mntr-server-prometheus
          kind: Service
          port: 443
          scheme: http
    ~~~

    The yaml above is like the one describing the access to the Traefik Dashboard, back in the [**G031** guide](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#enabling-the-ingressroute).

    - The `IngressRoute` points (`tls.secretName` parameter) to the secret of your wildcard certificate, encrypting the traffic coming and going to the `server-prometheus` service.

    - You must tell Traefik what **schema** to use for communicating with your Prometheus server. Since the Prometheus container is running just with HTTP, use the `scheme` parameter set as `http`, so Traefik can make internal requests in the HTTP protocol to the pod.

    - **IMPORTANT!** Notice how I've specified the name of the prometheus server service (`server-prometheus`), adding the prefix (`mntr-`) that this resource will have when the whole monitoring stack is deployed. This is necessary because Kustomize doesn't modify values of parameters that are not Kubernetes standard. In this case, Kustomize won't add the prefix to that particular `services.name` value in the resulting output of the global Kustomize project for this monitoring stack.

    > **BEWARE!**  
    > Remember that you'll need to enable in your network the domains you specify in the `IngressRoute`, in the `match` attribute, although also remembering that they'll have to point to the **Traefik** service's IP.

## Prometheus server's Kustomize project

After declaring all the required resources, you need to tie all them up in a `kustomization.yaml` file.

1. Create a `kustomization.yaml` file in the `server-prometheus` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the following yaml.

    ~~~yaml
    # Prometheus server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-prometheus

    resources:
    - resources/data-server-prometheus.persistentvolumeclaim.yaml
    - resources/server-prometheus.ingressroute.traefik.yaml
    - resources/server-prometheus.service.yaml
    - resources/server-prometheus.statefulset.yaml

    replicas:
    - name: server-prometheus
      count: 1

    images:
    - name: prom/prometheus
      newTag: v2.35.0

    configMapGenerator:
    - name: server-prometheus
      files:
      - configs/prometheus.rules.yaml
      - configs/prometheus.yaml
    ~~~

    Nothing special to remark from this `kustomization.yaml` beyond that there's no `secretGenerator` block.

### _Validating the Kustomize yaml output_

As in previous cases, you must check the output of this Kustomize project.

1. Dump the yaml output with `kubectl kustomize` to a `server-prometheus.k.output.yaml` file.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/server-prometheus > server-prometheus.k.output.yaml
    ~~~

2. Open the `server-prometheus.k.output.yaml`, it should be like the yaml below.

    ~~~yaml
    apiVersion: v1
    data:
      prometheus.rules.yaml: |-
        groups:
        - name: example_alert_rule_unique_name
          rules:
          - alert: HighRequestLatency
            expr: job:request_latency_seconds:mean5m{job="node-exporter"} > 0.5
            for: 10m
            labels:
              severity: page
            annotations:
              summary: High request latency
      prometheus.yaml: |
        # Prometheus main configuration file

        global:
          scrape_interval: 60s
          evaluation_interval: 60s

        rule_files:
          - /etc/prometheus/prometheus_alerts.rules.yaml

        alerting:
          alertmanagers:
          - scheme: http
            static_configs:
            - targets:
            #  - "mntr-alertmanager.monitoring.svc.deimos.cluster.io:9093"

        scrape_configs:
          - job_name: 'kubernetes-apiservers'
            scrape_interval: 180s
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
            scrape_interval: 120s
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
              replacement: kubernetes.default.svc.deimos.cluster.io:443
            - source_labels: [__meta_kubernetes_node_name]
              regex: (.+)
              target_label: __metrics_path__
              replacement: /api/v1/nodes/${1}/proxy/metrics

          - job_name: 'kubernetes-pods'
            scrape_interval: 240s
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
              replacement: kubernetes.default.svc.deimos.cluster.io:443
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
            tls_config:
              insecure_skip_verify: true

          - job_name: 'kube-state-metrics'
            scrape_interval: 50s
            static_configs:
              - targets: ['mntr-agent-kube-state-metrics.monitoring.svc.deimos.cluster.io:8080']

          - job_name: 'node-exporter'
            scrape_interval: 55s
            kubernetes_sd_configs:
              - role: endpoints
            relabel_configs:
            - source_labels: [__meta_kubernetes_endpoints_name]
              regex: 'node-exporter'
              action: keep
    kind: ConfigMap
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus-6mdmdtddbk
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    spec:
      ports:
      - name: http
        port: 443
        protocol: TCP
        targetPort: 9090
      selector:
        app: server-prometheus
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-prometheus
      name: data-server-prometheus
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.8G
      storageClassName: local-path
      volumeName: data-prometheus
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
          containers:
          - args:
            - --storage.tsdb.retention.time=12h
            - --config.file=/etc/prometheus/prometheus.yaml
            - --storage.tsdb.path=/prometheus
            image: prom/prometheus:v2.35.0
            name: server
            ports:
            - containerPort: 9090
              name: http
            resources:
              limits:
                cpu: 1000m
                memory: 512Mi
              requests:
                cpu: 500m
                memory: 256Mi
            volumeMounts:
            - mountPath: /etc/prometheus/prometheus.yaml
              name: server-prometheus-config
              subPath: prometheus.yaml
            - mountPath: /etc/prometheus/prometheus.rules.yaml
              name: server-prometheus-config
              subPath: prometheus.rules.yaml
            - mountPath: /prometheus
              name: server-prometheus-storage
          securityContext:
            fsGroup: 65534
            runAsGroup: 65534
            runAsNonRoot: true
            runAsUser: 65534
          volumes:
          - configMap:
              defaultMode: 420
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
              name: server-prometheus-6mdmdtddbk
            name: server-prometheus-config
          - name: server-prometheus-storage
            persistentVolumeClaim:
              claimName: data-server-prometheus
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    spec:
      entryPoints:
      - websecure
      routes:
      - kind: Rule
        match: Host(`prometheus.deimos.cloud`) || Host(`prm.deimos.cloud`)
        services:
        - kind: Service
          name: mntr-server-prometheus
          port: 443
          scheme: http
      tls:
        secretName: wildcard.deimos.cloud-tls
    ~~~

    Nothing to highlight here, just remember to check that the values are correct (in particular the service name referenced with the `mntr-` prefix in the `IngressRoute`) and the labels appear in the proper places.

## Don't deploy this Prometheus server project on its own

This Prometheus server cannot be deployed on its own because is missing several elements, such as the persistent volumes required by the PVCs and also the certificate in the correct namespace. As with the Nextcloud platform, you'll tie everything together in this guide's final part.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/server-prometheus`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/data-server-prometheus.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.ingressroute.traefik.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.statefulset.yaml`

## References

### _Kubernetes_

- [Pod Spec. Security Context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)

### _Prometheus_

- [Prometheus](https://prometheus.io/)
- [Prometheus's Docker image](https://hub.docker.com/r/prom/prometheus)
- [Prometheus on GitHub](https://github.com/prometheus/prometheus)
- [Prometheus configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Prometheus recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Prometheus alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [How to Setup Prometheus Monitoring On Kubernetes Cluster](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
- [Prometheus yamls from "How to Setup" guide](https://github.com/bibinwilson/kubernetes-prometheus)
- [How to deploy Prometheus on Kubernetes](https://www.metricfire.com/blog/how-to-deploy-prometheus-on-kubernetes/)
- [Files to accompany the How deploy Prometheus on Kubernetes](https://github.com/shevyf/prom_on_k8s_howto)
- [Reliable Kubernetes on a Raspberry Pi Cluster: Monitoring](https://medium.com/codex/reliable-kubernetes-on-a-raspberry-pi-cluster-monitoring-a771b497d4d3)
- [Kubernetes monitoring with Prometheus, the ultimate guide](https://sysdig.com/blog/kubernetes-monitoring-prometheus/)
- [Kubernetes monitoring with Prometheus, the ultimate guide](https://sysdig.com/blog/kubernetes-monitoring-prometheus/)
- [Kubernetes Monitoring with Prometheus: AlertManager, Grafana, PushGateway (part 2)](https://sysdig.com/blog/kubernetes-monitoring-with-prometheus-alertmanager-grafana-pushgateway-part-2/)
- [prometheus: Unable to create mmap-ed active query log](https://github.com/aws/eks-charts/issues/21)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 3**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 5**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md)
