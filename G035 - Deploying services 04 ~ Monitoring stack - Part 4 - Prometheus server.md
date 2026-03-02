# G035 - Deploying services 04 ~ Monitoring stack - Part 4 - Prometheus server

- [Prometheus is the core of your monitoring stack](#prometheus-is-the-core-of-your-monitoring-stack)
- [Kustomize project folders for Prometheus server](#kustomize-project-folders-for-prometheus-server)
- [Prometheus configuration files](#prometheus-configuration-files)
  - [Configuration file `prometheus.yaml`](#configuration-file-prometheusyaml)
  - [Configuration file `prometheus.rules.yaml`](#configuration-file-prometheusrulesyaml)
  - [Secret configuration file `prometheus.web.yaml`](#secret-configuration-file-prometheuswebyaml)
  - [Secret password file `basic_auth.pwd`](#secret-password-file-basic_authpwd)
- [Prometheus server persistent storage claim](#prometheus-server-persistent-storage-claim)
- [Prometheus server ServiceAccount](#prometheus-server-serviceaccount)
- [Prometheus server ClusterRole](#prometheus-server-clusterrole)
- [Prometheus server ClusterRoleBinding](#prometheus-server-clusterrolebinding)
- [Prometheus server StatefulSet](#prometheus-server-statefulset)
- [Prometheus server Service](#prometheus-server-service)
  - [Service's absolute internal FQDN](#services-absolute-internal-fqdn)
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

The core component of your monitoring stack is the Prometheus server, and this part is about readying its deployment. Some of the YAML manifests found here are based on the ones found in [this GitHub page](https://github.com/bibinwilson/kubernetes-prometheus), which were made for [this guide](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/).

## Kustomize project folders for Prometheus server

Create the folder structure of the Kustomize project for your Prometheus server:

~~~sh
$ mkdir -p $HOME/k8sprjs/monitoring/components/server-prometheus/{configs,resources,secrets}
~~~

## Prometheus configuration files

Prometheus is configured with a combination of command-line parameters and a configuration file, but it also uses other files to configure what are called "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules.

Also, to secure the access to Prometheus' API and UI, Prometheus' basic authentication feature can be enabled with yet another configuration file. This file will be deployed as a secret since it contains the list of users (with their hashed passwords) authorized to authenticate in the Prometheus instance.

### Configuration file `prometheus.yaml`

The main configuration file for Prometheus is a YAML file for configuring the scraping jobs your Prometheus server will execute. On the other hand, this file is also where you indicate to Prometheus which recording and alerting rule files to load and what alert manager services to use:

1. Create a `prometheus.yaml` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml
    ~~~

2. Enter the Prometheus configuration in the `prometheus.yaml` file:

    ~~~yaml
    # Prometheus main configuration file

    # Global settings for the Prometheus server
    global:
      scrape_interval: 20s     # How often to scrape targets by default
      evaluation_interval: 25s # How often to evaluate rules

    # Alerting rules periodically evaluated according to the global 'evaluation_interval'
    rule_files:
      - /etc/prometheus/prometheus.rules.yaml

    # Alertmanager configuration
    alerting:
      alertmanagers:
      - scheme: http
        static_configs:
        - targets:
          # - "alertmanager.monitoring.svc.homelab.cluster.:9093"

    # Scrape jobs configuration
    scrape_configs:
      # Scrapes the Kubernetes API servers for cluster health metrics
      - job_name: 'kubernetes-apiservers'
        scrape_interval: 60s
        kubernetes_sd_configs:
        - role: endpointslice
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpointslice_port_name]
          action: keep
          regex: default;kubernetes;https

      # Scrapes Kubelet metrics from each cluster node via the Kubernetes API server proxy
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
          replacement: kubernetes.default.svc.homelab.cluster.:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics

      # Scrapes pods that have specific "prometheus.io" annotations
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

      # Scrapes container resource usage metrics (cAdvisor) from nodes
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
          replacement: kubernetes.default.svc.homelab.cluster.:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

      # Scrapes services that have specific "prometheus.io" annotations
      - job_name: 'kubernetes-service-endpoints'
        scrape_interval: 45s
        kubernetes_sd_configs:
        - role: endpointslice
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
        # Excludes the Prometheus service from this scrapping job
        - source_labels: [__meta_kubernetes_service_name]
          action: drop
          regex: 'server-prometheus'

      # Static job for Kube State Metrics (cluster object state)
      - job_name: 'kube-state-metrics'
        scrape_interval: 50s
        static_configs:
        - targets: ['agent-kube-state-metrics.monitoring.svc.homelab.cluster.:8080']

      # Scrapes hardware and OS metrics from Node Exporter agents
      - job_name: 'node-exporter'
        scrape_interval: 65s
        kubernetes_sd_configs:
        - role: endpointslice
        relabel_configs:
        - source_labels: [__meta_kubernetes_endpointslice_name]
          regex: '.*node-exporter'
          action: keep

      # Self-scraping bypass using localhost
      # Avoids the Prometheus server getting 401 Unauthorized errors when scraping its own local process directly,
      # bypassing the Kubernetes Service and any RBAC proxies.
      - job_name: 'prometheus-self'
        scrape_interval: 30s
        static_configs:
          - targets: ['localhost:9090']
        # User for basic web authentication in the Prometheus server
        basic_auth:
          username: 'prometricsjob'
          # Path to the file containing the password inside the container
          password_file: '/etc/prometheus/secrets/basic_auth.pwd'
    ~~~

    There are several sections to understand in this `prometheus.yaml` file:

    - `global`\
      This section holds parameters that affects other configuration contexts of the Prometheus instance, and is also the place for setting up default values that apply to other configuration sections:

      - `scrape_interval`\
        Default scrape frequency of targets. Although this depends more on how many scraping targets you have, in general the shorter the time the bigger the hit on performance.

      - `evaluation_interval`\
        How frequently Prometheus has to evaluate recording and alerting rules. Again, you should be careful of not making this time too short, specially if you are using many or particularly complex rules, or your system's performance could degrade noticeably.

    - `rule_files`\
      List of files that hold the recording or alerting rules to apply on the Prometheus instance. The one present in this case is just an example, since this guide's Prometheus setup does not use rules.

    - `alerting`\
      This section is for configuring the connection to the Alertmanager instances where to send the alerts from this Prometheus instance. The configuration block shown in this file is just an example, since this Prometheus setup will not send alerts.

    - `scrape_configs`\
      Section where you set up the scraping targets from where your Prometheus instance will get the metrics to monitor. Each scraping target is a job with its own configuration:

      - `kubernetes-apiservers`\
        For scraping the API servers exposed by the Kubernetes system itself.

      - `kubernetes-nodes`\
        Scrapes metrics from the cluster nodes, although not directly from them but proxying the scrape through the corresponding Kubernetes API server.

        - In this job configuration, you have the address `kubernetes.default.svc.homelab.cluster.:443` set up in it, which points at the internal cluster IP of the `kubernetes` service running in the `default` namespace.

          Notice that the address has the service's complete FQDN (better for cluster performance), which includes the custom internal domain `homelab.cluster` [configured for the K3s cluster in the server node](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file).

          > [!NOTE]
          > **The last dot in the absolute FQDN is not a mistake!**\
          > It explicitly brands the FQDN as absolute, which avoids doing any searches in the cluster's internal DNS service. This technique allows calling services directly, improving your Kubernetes cluster performance.

      - `kubernetes-pods`\
        Scrapes metrics **only from pods that have been annotated with `prometheus.io` labels**.

      - `kubernetes-cadvisor`\
        Scrapes the Kubelet cAdvisor metrics.

        - As in the `kubernetes-nodes` section, here you also have a reference to the `kubernetes.default.svc.homelab.cluster.:443` address with the service's absolute FQDN.

      - `kubernetes-service-endpoints`\
        Generic scraper of metrics from `Service` resources endpoints, but **only from those annotated with `prometheus.io` labels**.

        In this job configuration, notice the rule at its end to exclude the Prometheus service from being scraped. This is because Prometheus cannot read metrics from its service just by annotating the service with the `prometheus.io` tag. It needs some extra security configuration to do so, but you can avoid it thanks to the `prometheus-self` job declared last in this configuration file.

      - `kube-state-metrics`\
        Scrapes metrics from the Kube State Metrics service [you have declared in the second part of this chapter G035](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md).

        In this job, specify the internal cluster absolute FQDN and port to connect with the Kube State Metrics service, which is `agent-kube-state-metrics.monitoring.svc.homelab.cluster.:8080`.

      - `node-exporter`\
        Scrapes metrics from the Prometheus Node Exporter [you already prepared in the previous third part](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md).

      - `prometheus-self`\
        This is the job that scrapes Prometheus' metrics directly from its localhost server process. With this job, you avoid requiring a more complex security setup just to grant Prometheus access to its own metrics through its service.

        Since this Prometheus server will have enabled its basic authentication to secure its web access, this job has to authenticate itself first before it can access the Prometheus server's metrics. This explains the need for a `basic_auth` section in this job. Notice that, while the username is indicated in this configuration file, the user's password is read from another `basic_auth.pwd` file that [you will declare later as a secret object](#secret-password-file-basic_authpwd). The user to specify here is one you will declare [in yet another secret file for configuring the web access into your Prometheus server](#secret-configuration-file-prometheuswebyaml).

      Notice that each of these scraping jobs have their own particularities, like a different `scrape_interval` or `relabel_configs` to suit their own needs. To know more about all those parameters, better check out the [official Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/).

### Configuration file `prometheus.rules.yaml`

In this guide, the `prometheus.rules.yaml` file contains a set of rules for alerts that cover the essential components of your Kubernetes cluster:

> [!NOTE]
> **Learn more about Prometheus rules in its official documentation**\
> To know more about the Prometheus rules, remember to check out the official documentation about "_[recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)_" and "_[alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)_" rules

1. Create the file `prometheus.rules.yaml` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml
    ~~~

2. Enter the alert rules in `prometheus.rules.yaml`:

    ~~~yaml
    # Alerting rules for Prometheus

    groups:
      - name: kubernetes_infrastructure_alerts
        rules:
        # Raise alert if any target is unreachable for 5 minutes
        - alert: TargetDown
          expr: up == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Target unreachable: {{ $labels.instance }}"
            description: "The target {{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

        # Raise specific alert for Prometheus self-scraping when it fails for 2 minutes
        - alert: PrometheusSelfScrapeFailed
          expr: up{job="prometheus-self"} == 0
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Prometheus cannot scrape itself"
            description: "Prometheus is failing to scrape its own /metrics endpoint on localhost. This might indicate the process is hanging or overloaded."

        # Raise alert if the Kubernetes API Server is down for 1 minute
        - alert: KubernetesApiServerDown
          expr: up{job="kubernetes-apiservers"} == 0
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "Kubernetes API Server is unreachable"
            description: "Prometheus cannot connect to the Kubernetes API Server. Cluster management and discovery might be compromised."

        # Raise alert when high memory usage detected in Prometheus for 10 minutes
        - alert: PrometheusHighMemoryUsage
          expr: (process_resident_memory_bytes{job="prometheus-self"} / 1e9) > 1
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Prometheus high memory usage"
            description: "Prometheus is consuming more than 1GB of RAM on {{ $labels.instance }}."
    ~~~

    Just a couple of things to highlight from this configuration file:

    - The `name` of each group has to be a **string unique within the file**.

    - A group can hold several rules, and each rule can have a different nature (alerting or recording). Depending on your requirements, you should carefully consider if you want to mix them together in the same file or not.

    - The alerting rules syntax has a few more parameters for recording rules.

### Secret configuration file `prometheus.web.yaml`

Enable your Prometheus' basic authentication by configuring it as indicated [in this official guide](https://prometheus.io/docs/guides/basic-auth/). This implies producing users with the `htpasswd` command [like you had to do for the Traefik dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#creating-the-user-with-htpasswd). In this case, you need to create a user for each entity requiring access to Prometheus. Those entities are yourself, the job for scraping metrics, and Grafana (which [you will prepare in the next part of this chapter **G035**](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md)):

1. In your `kubectl` client system, use the `htpasswd` command to generate three users called `promuser`, `prometricsjob` and `grafuser` with their passwords hashed out with the BCrypt encryption:

    ~~~sh
    $ htpasswd -nb -B -C 9 promuser Pu7Y0urPr0M37hEu5S3cr3tP4ssw0rdH3r3
    promuser:$2y$09$QqcimH6VRwEzBAOchdeo.OTKdXS.UHeb89s80h1JkYK3QQAGzI7tm
    $ htpasswd -nb -B -C 9 prometricsjob Pu7Y0urPr0M37hEu5JoBS3cr3tP4ssw0rdH3r3
    prometricsjob:$2y$09$6pxFrPCVn4DE9X5WYzNWLuoJM39297l0CHwJ6I9psLnS0w8RiisUC
    $ htpasswd -nb -B -C 9 grafuser pUtY0urGr4FaNAu5ErS3cr3tP4ssw0rdH3r3
    grafuser:$2y$09$oL.rm.Xn0J56/4B2uS540O/n0EAq.121WWieHirOsfiIjQzSWMhMq
    ~~~

    Do not lose the `htpasswd` outputs. It is the entry you have to put in your Prometheus basic authentication configuration.

    > [!IMPORTANT]
    > **Be careful with the value you set to the `-C` option!**\
    > This option indicates the computing time used by the BCrypt algorithm for hashing and, if you set it too high, the authentication into Prometheus could take too long or even not finish at all. The value you can type here must be between 4 and 17, and the default is 5.

2. Generate the file `prometheus.web.yaml` file in the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/secrets/prometheus.web.yaml
    ~~~

3. Specify the basic authentication configuration in `prometheus.web.yaml`:

    ~~~yaml
    # Users authorized to access Prometheus with basic authentication

    basic_auth_users:
      promuser: "$2y$09$QqcimH6VRwEzBAOchdeo.OTKdXS.UHeb89s80h1JkYK3QQAGzI7tm"
      prometricsjob: "$2y$09$6pxFrPCVn4DE9X5WYzNWLuoJM39297l0CHwJ6I9psLnS0w8RiisUC"
      grafuser: "$2y$09$oL.rm.Xn0J56/4B2uS540O/n0EAq.121WWieHirOsfiIjQzSWMhMq"
    ~~~

    The user entries in the `basic_auth_users` block above are modified versions of the strings you got from the earlier `htpasswd` commands.

    > [!NOTE]
    > **It is better to use different users for different tasks or concerns**\
    > You could argue that, in the case of the homelab built in this guide, using several users with exactly the same privileges could be a bit too much. Still, this configuration allows you to trace better which user accessed or did what.

    > [!WARNING]
    > **In the Prometheus configuration, always put hashed passwords between quotation marks to avoid unmarshaling issues**\
    > Otherwise, Prometheus will be unable to read the hash properly due to the special characters that will appear in it (like the `$` for instance).

    With this file you can enable other security options like HTTPS in your Prometheus server instance but, since your cluster already has Traefik taking care of securing web accesses with HTTPS, they are not required here.

### Secret password file `basic_auth.pwd`

The password required for the basic authentication of the job that will scrape the Prometheus server metrics must be put unencrypted in a plain text file:

1. Create an empty `basic_auth.pwd` file in the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/secrets/basic_auth.pwd
    ~~~

2. Enter the password of the user assigned to the Prometheus metrics scraping job (`prometricsjob` in this case) in `basic_auth.pwd`:

    ~~~txt
    Pu7Y0urPr0M37hEu5JoBS3cr3tP4ssw0rdH3r3
    ~~~

    > [!WARNING]
    > **The password must be entered in `basic_auth.pwd` as plain unencrypted text**\
    > Be careful of who can access this `basic_auth.pwd` file.

## Prometheus server persistent storage claim

In the [first part of this chapter **G035**](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#lvm-storage-set-up), you prepared a 10 GiB LVM PV in the `k3sagent02` for storing the Prometheus server data. Now you need to declare a persistent volume claim to connect your Prometheus server with that PV:

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

## Prometheus server ServiceAccount

[Like the Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-serviceaccount), Prometheus requires a `ServiceAccount` to run its pods. Rather than using the `default` one that will exist in the `monitoring` namespace where your monitoring stack is going to be deployed, better declare one specific for your Prometheus instance:

1. Create a `server-prometheus.serviceaccount.yaml` file in the `server-prometheus/resources/` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.serviceaccount.yaml
    ~~~

2. Declare the `ServiceAccount` for the Prometheus server in `server-prometheus.serviceaccount.yaml`:

    ~~~yaml
    # Prometheus server ServiceAccount
    apiVersion: v1
    kind: ServiceAccount

    metadata:
      name: server-prometheus
    automountServiceAccountToken: false
    ~~~

    This `ServiceAccount` is just like the one declared for [the Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-serviceaccount), down to the `automountServiceAccountToken` parameter set to `false` for hardening reasons. You will see this parameter set to `true` in the Prometheus server's `StatefulSet` declaration.

## Prometheus server ClusterRole

You need to assign a role to the `server-prometheus` service account to grant it read-only capacities. Do so by declaring a specific `ClusterRole` like this:

1. Generate the file `server-prometheus.clusterrole.yaml` within the `resources` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.clusterrole.yaml
    ~~~

2. Declare the `ClusterRole` in your new `server-prometheus.clusterrole.yaml` file:

    ~~~yaml
    # Prometheus server read-only ClusterRole to read Kubernetes metrics
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole

    metadata:
      name: server-prometheus
    rules:
    # Permissions for discovery of nodes, services, endpoints and pods
    - apiGroups: [""]
      resources:
      - nodes
      - nodes/proxy
      - nodes/metrics # Needed for Kubelet/cAdvisor metrics
      - services
      - pods
      verbs: ["get", "list", "watch"]

    # Permissions for discovery of endpoint slices
    - apiGroups: ["discovery.k8s.io"]
      resources: ["endpointslices"]
      verbs: ["get", "list", "watch"]

    # Permissions for ingresses discovery
    - apiGroups: ["networking.k8s.io"]
      resources: ["ingresses"]
      verbs: ["get", "list", "watch"]

    # Specific permissions for reading metrics directly from the API Server
    - nonResourceURLs: ["/metrics"]
      verbs: ["get"]
    ~~~

    Notice the list of `resources` and the particular `/metrics` url in `nonResourceURLs` this `ClusterRole` allows to reach. Also see that all the `verbs` indicated are related to read-only actions.

    > [!NOTE]
    > **`ClusterRole` resources are not namespaced**\
    > As its name implies, any role of this type has a cluster-wide reach. This is why namespaces do not apply to them.

## Prometheus server ClusterRoleBinding

The `ClusterRole` you have just created before is not be enforced unless you bind it to a `ServiceAccount` or a set of them. Here you are going to bind it to [the `server-prometheus` service account declared earlier](#prometheus-server-serviceaccount):

1. Produce a new `server-prometheus.clusterrolebinding.yaml` file in the `resources` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.clusterrolebinding.yaml
    ~~~

2. Declare the `ClusterRoleBinding` in `server-prometheus.clusterrolebinding.yaml`:

    ~~~yaml
    # Monitoring stack ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding

    metadata:
      name: server-prometheus
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: server-prometheus
    subjects:
    - kind: ServiceAccount
      name: server-prometheus
    ~~~

    > [!NOTE]
    > **`ClusterRoleBinding` resources are not namespaced**\
    > Like the `ClusterRole`, its binding also has cluster-wide reach.

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
          serviceAccountName: server-prometheus
          automountServiceAccountToken: true
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
            - "--web.config.file=/etc/prometheus/prometheus.web.yaml"
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
            - name: prometheus-secrets
              subPath: prometheus.web.yaml
              mountPath: /etc/prometheus/prometheus.web.yaml
            - name: prometheus-secrets
              subPath: basic_auth.pwd
              mountPath: /etc/prometheus/secrets/basic_auth.pwd
            - name: prometheus-storage
              mountPath: /prometheus
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              runAsNonRoot: true
              runAsUser: 65534
              runAsGroup: 65534
          hostAliases:
          - ip: "10.7.0.1"
            hostnames:
            - "prometheus.homelab.cloud"
          volumes:
          - name: prometheus-config
            configMap:
              name: server-prometheus-config
              defaultMode: 440
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
          - name: prometheus-secrets
            secret:
              secretName: server-prometheus-web-config
              defaultMode: 440
              items:
              - key: prometheus.web.yaml
                path: prometheus.web.yaml
              - key: basic_auth.pwd
                path: basic_auth.pwd
          - name: prometheus-storage
            persistentVolumeClaim:
              claimName: server-prometheus
    ~~~

    This `StatefulSet` declares a pod with a single container run with a non-root `65534` user (and group) with almost the same `securityContext` configuration specified for the [Forgejo server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-statefulset). Beyond those similarities, the main particularities found under the `spec.template.spec` section of this `StatefulSet` for a Prometheus server are:

    - `serviceAccountName`\
      Specifies the name of [the service account created specifically for this Prometheus server pod](#prometheus-server-serviceaccount).

    - `automountServiceAccountToken`\
      With this parameter set to true, enables this pod in particular to use the service account's token for accessing the Kubernetes API.

    - `server` container\
      There is only one container in this pod which runs the Prometheus server itself:

      - The `image` is for the version `3.9.1` of Prometheus, built on a compact distroless version of Linux.

      - The `ports` only lists the `server` one opened by the container on the port `9090`, which is the default one for Prometheus.

      - The `args` section lists important Prometheus configuration parameters:

        - `--config.file`\
          Points to the absolute path where to find the main Prometheus configuration file.

        - `--web.config.file`\
          Path to the configuration file defining how the HTTP access into Prometheus works. Remember that, in this case, [it only specifies the list of users authorized to access Prometheus through basic authentication](#secret-configuration-file-prometheuswebyaml).

        - `--storage.tsdb.path`\
          Absolute path to the folder containing the files of the Prometheus metrics database.

        - `--storage.tsdb.retention.time`\
          Specifies for how long Prometheus has to retain metrics in its database before purging them.

        - `--storage.tsdb.retention.size`\
          Delimits the storage room available to Prometheus for retaining metrics in its database. [The Prometheus documentation recommends this retention size to be 80-85% of the total available Prometheus storage space](https://prometheus.io/docs/prometheus/latest/storage/#right-sizing-retention-size).

      - `volumeMounts` section\
        Mounts the necessary Prometheus configuration files and the storage for the retained metrics database:

        - `prometheus.yaml`\
          The main Prometheus configuration file.

        - `prometheus.rules.yaml`\
          A configuration file with alert rules for Prometheus. Remember that, in this guide, it is only an "inert" placeholder example.

        - `prometheus.web.yaml`\
          The configuration file to enable the security options available in Prometheus to secure web accesses. In this case, it only enables the basic authentication of one user.

        - `basic_auth.pwd`\
          The plain text file containing the password of the user assigned to the job of reading the Prometheus server's metrics.

        - `/prometheus`\
          Folder where Prometheus will keep the files for its retained metrics database.

## Prometheus server Service

To properly enable Prometheus in your cluster, you need to create its corresponding `Service`:

1. Create a file named `server-prometheus.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml
    ~~~

2. Declare the `Service` for your Prometheus server in `server-prometheus.service.yaml`:

    ~~~yaml
    # Prometheus server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-prometheus
    annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/port:   '9090'
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - name: server
        port: 9090
        targetPort: server
        protocol: TCP
    ~~~

    This is a headless `Service` like all the others you have seen in previous chapters of this guide. Notice how this service also has the `prometheus.io` annotations to enable Prometheus to scrape its own metrics, although they are going to be ignored by the Prometheus `kubernetes-service-endpoints` job that scrapes these metrics. Instead, the Prometheus server's metrics will be scraped by a [specific `prometheus-self` job configured to connect with the Prometheus localhost server process directly](#configuration-file-prometheusyaml).

    Since they are explicitly excluded by the `kubernetes-service-endpoints` job configuration, you can leave the `prometheus.io` annotations here. They still could be used by some other tool able to read Prometheus metrics. Also, it can be considered a good practice to annotate this Prometheus service like all the others you have declared up till now for consistency.

### Service's absolute internal FQDN

As a component of the monitoring stack, this headless service is going to be placed under the `monitoring` namespace. This means that its absolute _Fully Qualified Domain Name_ (_FQDN_) will be:

~~~http
server-prometheus.monitoring.svc.homelab.cluster.
~~~

## Prometheus server's Kustomize project

After declaring all the required resources for the Prometheus server, you need to put them together under a `kustomization.yaml` file:

1. Create a `kustomization.yaml` file in the `server-prometheus` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml
    ~~~

2. Declare the `Kustomization` object for the Prometheus server setup in the `kustomization.yaml` file:

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
    - resources/server-prometheus.serviceaccount.yaml
    - resources/server-prometheus.clusterrole.yaml
    - resources/server-prometheus.clusterrolebinding.yaml
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
    - name: server-prometheus-config
      files:
      - configs/prometheus.rules.yaml
      - configs/prometheus.yaml

    secretGenerator:
    - name: server-prometheus-web-config
      files:
      - secrets/prometheus.web.yaml
      - secrets/basic_auth.pwd
    ~~~

    There is nothing special to remark from this `kustomization.yaml`, since it has parameters you have already seen in previous chapters.

### Validating the Kustomize YAML output

As usual, you must check the output of this Kustomize project:

1. Dump the YAML output with `kubectl kustomize` to a `server-prometheus.k.output.yaml` file (or just redirect the output to a text editor):

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/server-prometheus > server-prometheus.k.output.yaml
    ~~~

2. Open the `server-prometheus.k.output.yaml` and see if it is like this YAML:

    ~~~yaml
    apiVersion: v1
    automountServiceAccountToken: false
    kind: ServiceAccount
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    rules:
    - apiGroups:
      - ""
      resources:
      - nodes
      - nodes/proxy
      - nodes/metrics
      - services
      - pods
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - discovery.k8s.io
      resources:
      - endpointslices
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - networking.k8s.io
      resources:
      - ingresses
      verbs:
      - get
      - list
      - watch
    - nonResourceURLs:
      - /metrics
      verbs:
      - get
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: server-prometheus
    subjects:
    - kind: ServiceAccount
      name: server-prometheus
    ---
    apiVersion: v1
    data:
      prometheus.rules.yaml: |-
        # Alerting rules for Prometheus

        groups:
          - name: kubernetes_infrastructure_alerts
            rules:
            # Raise alert if any target is unreachable for 5 minutes
            - alert: TargetDown
              expr: up == 0
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: "Target unreachable: {{ $labels.instance }}"
                description: "The target {{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

            # Raise specific alert for Prometheus self-scraping when it fails for 2 minutes
            - alert: PrometheusSelfScrapeFailed
              expr: up{job="prometheus-self"} == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "Prometheus cannot scrape itself"
                description: "Prometheus is failing to scrape its own /metrics endpoint on localhost. This might indicate the process is hanging or overloaded."

            # Raise alert if the Kubernetes API Server is down for 1 minute
            - alert: KubernetesApiServerDown
              expr: up{job="kubernetes-apiservers"} == 0
              for: 1m
              labels:
                severity: critical
              annotations:
                summary: "Kubernetes API Server is unreachable"
                description: "Prometheus cannot connect to the Kubernetes API Server. Cluster management and discovery might be compromised."

            # Raise alert when high memory usage detected in Prometheus for 10 minutes
            - alert: PrometheusHighMemoryUsage
              expr: (process_resident_memory_bytes{job="prometheus-self"} / 1e9) > 1
              for: 10m
              labels:
                severity: warning
              annotations:
                summary: "Prometheus high memory usage"
                description: "Prometheus is consuming more than 1GB of RAM on {{ $labels.instance }}."
      prometheus.yaml: |-
        # Prometheus main configuration file

        # Global settings for the Prometheus server
        global:
          scrape_interval: 20s     # How often to scrape targets by default
          evaluation_interval: 25s # How often to evaluate rules

        # Alerting rules periodically evaluated according to the global 'evaluation_interval'
        rule_files:
          - /etc/prometheus/prometheus.rules.yaml

        # Alertmanager configuration
        alerting:
          alertmanagers:
          - scheme: http
            static_configs:
            - targets:
              # - "alertmanager.monitoring.svc.homelab.cluster.:9093"

        # Scrape jobs configuration
        scrape_configs:
          # Scrapes the Kubernetes API servers for cluster health metrics
          - job_name: 'kubernetes-apiservers'
            scrape_interval: 60s
            kubernetes_sd_configs:
            - role: endpointslice
            scheme: https
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            relabel_configs:
            - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpointslice_port_name]
              action: keep
              regex: default;kubernetes;https

          # Scrapes Kubelet metrics from each cluster node via the Kubernetes API server proxy
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
              replacement: kubernetes.default.svc.homelab.cluster.:443
            - source_labels: [__meta_kubernetes_node_name]
              regex: (.+)
              target_label: __metrics_path__
              replacement: /api/v1/nodes/${1}/proxy/metrics

          # Scrapes pods that have specific "prometheus.io" annotations
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

          # Scrapes container resource usage metrics (cAdvisor) from nodes
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
              replacement: kubernetes.default.svc.homelab.cluster.:443
            - source_labels: [__meta_kubernetes_node_name]
              regex: (.+)
              target_label: __metrics_path__
              replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor

          # Scrapes services that have specific "prometheus.io" annotations
          - job_name: 'kubernetes-service-endpoints'
            scrape_interval: 45s
            kubernetes_sd_configs:
            - role: endpointslice
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
            # Excludes the Prometheus service from this scrapping job
            - source_labels: [__meta_kubernetes_service_name]
              action: drop
              regex: 'server-prometheus'

          # Static job for Kube State Metrics (cluster object state)
          - job_name: 'kube-state-metrics'
            scrape_interval: 50s
            static_configs:
            - targets: ['agent-kube-state-metrics.monitoring.svc.homelab.cluster.:8080']

          # Scrapes hardware and OS metrics from Node Exporter agents
          - job_name: 'node-exporter'
            scrape_interval: 65s
            kubernetes_sd_configs:
            - role: endpointslice
            relabel_configs:
            - source_labels: [__meta_kubernetes_endpointslice_name]
              regex: '.*node-exporter'
              action: keep

          # Self-scraping bypass using localhost
          # Avoids the Prometheus server getting 401 Unauthorized errors when scraping its own local process directly,
          # bypassing the Kubernetes Service and any RBAC proxies.
          - job_name: 'prometheus-self'
            scrape_interval: 30s
            static_configs:
              - targets: ['localhost:9090']
            # User for basic web authentication in the Prometheus server
            basic_auth:
              username: 'prometricsjob'
              # Path to the file containing the password inside the container
              password_file: '/etc/prometheus/secrets/basic_auth.pwd'
    kind: ConfigMap
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus-config-ktb4mbm27t
    ---
    apiVersion: v1
    data:
      basic_auth.pwd: UHU3WTB1clByME0zN2hFdTVKb0JTM2NyM3RQNHNzdzByZEgzcjM=
      prometheus.web.yaml: |
        IyBVc2VycyBhdXRob3JpemVkIHRvIGFjY2VzcyBQcm9tZXRoZXVzIHdpdGggYmFzaWMgYX
        V0aGVudGljYXRpb24KCmJhc2ljX2F1dGhfdXNlcnM6CiAgcHJvbXVzZXI6ICIkMnkkMDkk
        UXFjaW1INlZSd0V6QkFPY2hkZW8uT1RLZFhTLlVIZWI4OXM4MGgxSmtZSzNRUUFHekk3dG
        0iCiAgcHJvbWV0cmljc2pvYjogIiQyeSQwOSQ2cHhGclBDVm40REU5WDVXWXpOV0x1b0pN
        MzkyOTdsMENId0o2STlwc0xuUzB3OFJpaXNVQyIKICBncmFmdXNlcjogIiQyeSQwOSRvTC
        5ybS5YbjBKNTYvNEIydVM1NDBPL24wRUFxLjEyMVdXaWVIaXJPc2ZpSWpRelNXTWhNcSI=
    kind: Secret
    metadata:
      labels:
        app: server-prometheus
      name: server-prometheus-web-config-b4cb8cdc8k
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9090"
        prometheus.io/scrape: "true"
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
          automountServiceAccountToken: true
          containers:
          - args:
            - --config.file=/etc/prometheus/prometheus.yaml
            - --web.config.file=/etc/prometheus/prometheus.web.yaml
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
            - mountPath: /etc/prometheus/prometheus.web.yaml
              name: prometheus-secrets
              subPath: prometheus.web.yaml
            - mountPath: /etc/prometheus/secrets/basic_auth.pwd
              name: prometheus-secrets
              subPath: basic_auth.pwd
            - mountPath: /prometheus
              name: prometheus-storage
          hostAliases:
          - hostnames:
            - prometheus.homelab.cloud
            ip: 10.7.0.1
          securityContext:
            fsGroup: 65534
            fsGroupChangePolicy: OnRootMismatch
          serviceAccountName: server-prometheus
          volumes:
          - configMap:
              defaultMode: 440
              items:
              - key: prometheus.yaml
                path: prometheus.yaml
              - key: prometheus.rules.yaml
                path: prometheus.rules.yaml
              name: server-prometheus-config-ktb4mbm27t
            name: prometheus-config
          - name: prometheus-secrets
            secret:
              defaultMode: 440
              items:
              - key: prometheus.web.yaml
                path: prometheus.web.yaml
              - key: basic_auth.pwd
                path: basic_auth.pwd
              secretName: server-prometheus-web-config-b4cb8cdc8k
          - name: prometheus-storage
            persistentVolumeClaim:
              claimName: server-prometheus
    ~~~

    Nothing new to highlight here. Just remember to check that all values and names are correct and that labels appear in the expected places.

## Do not deploy this Prometheus server project on its own

This Prometheus server cannot be deployed on its own because is missing several elements, such as the persistent volume required by the PVC, or the Traefik ingress that enables access to it. All the missing elements will be declared and put together with all the other components in the final part of this chapter G035.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/server-prometheus`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/monitoring/components/server-prometheus/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.rules.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/configs/prometheus.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.clusterrole.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.clusterrolebinding.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.service.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.serviceaccount.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/resources/server-prometheus.statefulset.yaml`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/secrets/basic_auth.pwd`
- `$HOME/k8sprjs/monitoring/components/server-prometheus/secrets/prometheus.web.yaml`

## References

### [Prometheus](https://prometheus.io/)

- [Docs](https://prometheus.io/docs/introduction/overview/)

  - [Prometheus Server](https://prometheus.io/docs/prometheus/latest/getting_started/)
    - [Installation](https://prometheus.io/docs/prometheus/latest/installation/)
    - [Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
      - [Recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
      - [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
      - [HTTPS and authentication](https://prometheus.io/docs/prometheus/latest/configuration/https/)
    - [Storage](https://prometheus.io/docs/prometheus/latest/storage/)
      - [Local Storage. Right-Sizing Retention Size](https://prometheus.io/docs/prometheus/latest/storage/#right-sizing-retention-size)

  - [Guides. Securing Prometheus API and UI endpoints using basic auth](https://prometheus.io/docs/guides/basic-auth/)

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

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers. Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

- [Kubernetes Documentation. Reference. Kubernetes API. Workload Resources. Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
  - [Security context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 3**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 5**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md)
