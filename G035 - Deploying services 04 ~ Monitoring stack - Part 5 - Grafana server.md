# G035 - Deploying services 04 ~ Monitoring stack - Part 5 - Grafana server

- [Grafana is your monitoring dashboard](#grafana-is-your-monitoring-dashboard)
- [Kustomize project folders for Grafana](#kustomize-project-folders-for-grafana)
- [Grafana server persistent storage claim](#grafana-server-persistent-storage-claim)
- [Grafana server StatefulSet](#grafana-server-statefulset)
- [Grafana server Service](#grafana-server-service)
  - [Service's absolute internal FQDN](#services-absolute-internal-fqdn)
- [Grafana server Kustomize project](#grafana-server-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Grafana server project on its own](#do-not-deploy-this-grafana-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Grafana OSS](#grafana-oss)
  - [Other Grafana-related contents](#other-grafana-related-contents)
  - [Kubernetes](#kubernetes)
- [Navigation](#navigation)

## Grafana is your monitoring dashboard

Prometheus has its own dashboard for handling all its functionality and notifications, but it is not as powerful or popular as Grafana for visualizing the metrics gathered from its sources. To give your monitoring stack a Grafana-based metrics dashboard, follow this part to deploy it as a Kustomize project based on the [official installation documentation for this tool](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/).

## Kustomize project folders for Grafana

Generate the folder structure of the Kustomize project for your Grafana server setup:

~~~sh
$ mkdir -p $HOME/k8sprjs/monitoring/components/server-grafana/resources
~~~

## Grafana server persistent storage claim

You have to make available for your Grafana server the 2GiB LVM persistent volume created in the [first part of this chapter G035](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#lvm-storage-set-up). As usual, configure a persistent volume claim for connecting Grafana to it:

1. Create a file named `server-grafana.persistentvolumeclaim.yaml` under `resources/`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.persistentvolumeclaim.yaml
    ~~~

2. Declare the `PersistentVolumeClaim` for Grafana in `server-grafana.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Grafana server claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-grafana
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: monitoring-ssd-grafana-data
      resources:
        requests:
          storage: 1.9G
    ~~~

## Grafana server StatefulSet

Grafana needs to store some data, so you should deploy this observability tool with a `StatefulSet` resource:

1. Produce a `server-grafana.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for your Grafana server in `server-grafana.statefulset.yaml`:

    ~~~yaml
    # Grafana server StatefulSet for a regular pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-grafana
    spec:
      replicas: 1
      serviceName: server-grafana
      template:
        spec:
          automountServiceAccountToken: false
          securityContext:
            fsGroup: 472
            supplementalGroups:
            - 0
          containers:
          - name: server
            image: grafana/grafana-dev:12.4.0-21524955964
            imagePullPolicy: IfNotPresent
            ports:
            - name: server
              containerPort: 3000
              protocol: TCP
            readinessProbe:
              failureThreshold: 3
              successThreshold: 1
              initialDelaySeconds: 10
              periodSeconds: 30
              timeoutSeconds: 2
              httpGet:
                path: /robots.txt
                port: 3000
                scheme: HTTP
            livenessProbe:
              failureThreshold: 3
              successThreshold: 1
              initialDelaySeconds: 30
              periodSeconds: 10
              timeoutSeconds: 1
              tcpSocket:
                port: 3000
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-storage
          volumes:
            - name: grafana-storage
              persistentVolumeClaim:
                claimName: server-grafana
    ~~~

    This `StatefulSet` for your Grafana server has a number of particularities in its `spec.template.spec` block, some inherited from the YAML specified in [Grafana's Kubernetes deployment documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/#deploy-grafana-oss-on-kubernetes):

    - `automountServiceAccountToken`\
      This parameter is set to `false` here because Grafana will get the information it needs from Prometheus, not directly from the Kubernetes API.

    - `securityContext`\
      This is the same `securityContext` specified in the official Grafana documentation at the pod level of this Grafana `StatefulSet`:

      - `fsGroup`\
        Ensures that the Grafana filesystem used in the pod is going to be owned by the group identified by the GID `472`.

      - `supplementalGroups`\
        Is a list of GIDs applied to the first process run in each container of the pod. Notice that in this case it is the `root` group (GID `0`).

    - `server` container\
      Only one container is going to run in this pod.

      - The `image` is the Alpine-based version of Grafana Open Source (there is also an Enterprise edition of Grafana). The particularity here is that, [by recommendation from the Grafana documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/#run-the-grafana-main-branch), it is better to use the image from the `grafana/grafana-dev` branch rather than the main one and pick a specific tagged version like `12.4.0-21524955964`.

        This is to avoid unexpected issues when a new commit enters in the main Grafana branch that could potentially disrupt the Grafana instance running in your setup. In other words, Grafana recommends to keep total control of the version run in your Kubernetes cluster. Where possible (when version tags are available), you have already seen this criteria applied in previous deployments of this guide.

      - In `ports`, just one, named `server`, is configured to have the standard Grafana port `3000` open.

      - The `readinessProbe` and `livenessProbe` sections are mostly like the ones you have already seen in other. On one hand, the `readinessProbe` checks the `/robots.txt` `path` served by Grafana on the `port 3000` through a `HTTP` connection `scheme`. On the other, the `livenessProbe` probe is configured to get a response from the `tcpSocket` found also at the `port 3000`.

    - `volumeMounts` section\
      Only mounts the storage for Grafana's data.

      - `/var/lib/grafana`\
        Default path where Grafana stores its own data.

## Grafana server Service

Declare the `Service` object for your Grafana server like this:

1. Create a file named `server-grafana.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.service.yaml
    ~~~

2. Declare the `Service` for your Grafana server in `server-grafana.service.yaml`:

    ~~~yaml
    # Grafana server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-grafana
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port:   '3000'
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - name: server
        port: 3000
        targetPort: server
        protocol: TCP
    ~~~

    The main thing to notice in this particular headless service is that Grafana also has metrics that Prometheus can scrape. Therefore, the required annotation `prometheus.io` labels are set in the `metadata` block.

### Service's absolute internal FQDN

As a component of the monitoring stack, this headless service is going to be placed under the `monitoring` namespace. This means that its absolute _Fully Qualified Domain Name_ (_FQDN_) will be:

~~~http
server-grafana.monitoring.svc.homelab.cluster.
~~~

## Grafana server Kustomize project

With all the previous components declared, put them together in a Kustomize subproject for your Grafana setup:

1. Create a `kustomization.yaml` file in the `server-grafana` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/server-grafana/kustomization.yaml
    ~~~

2. Declare the `Kustomization` object for your Grafana server setup in `kustomization.yaml`:

    ~~~yaml
    # Grafana server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
    - pairs:
        app: server-grafana
      includeSelectors: true
      includeTemplates: true

    resources:
    - resources/server-grafana.persistentvolumeclaim.yaml
    - resources/server-grafana.service.yaml
    - resources/server-grafana.statefulset.yaml

    replicas:
    - name: server-grafana
      count: 1

    images:
    - name: grafana/grafana-dev
      newTag: 12.4.0-21524955964
    ~~~

    The only particularity to highlight from this `kustomization.yaml` is the fact that there is neither a `configMapGenerator` nor a `secretGenerator` block in it. This implies that Grafana is deployed with a default configuration.

### Validating the Kustomize YAML output

Like in previous guides, you should validate this Kustomize project's complete YAML output:

1. Execute `kubectl kustomize` redirecting its output to a `server-grafana.k.output.yaml` file (or to a text editor):

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/server-grafana > server-grafana.k.output.yaml
    ~~~

2. The resulting `server-grafana.k.output.yaml` should look as the yaml next:

    ~~~yaml
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "3000"
        prometheus.io/scrape: "true"
      labels:
        app: server-grafana
      name: server-grafana
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 3000
        protocol: TCP
        targetPort: server
      selector:
        app: server-grafana
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-grafana
      name: server-grafana
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.9G
      storageClassName: local-path
      volumeName: monitoring-ssd-grafana-data
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-grafana
      name: server-grafana
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-grafana
      serviceName: server-grafana
      template:
        metadata:
          labels:
            app: server-grafana
        spec:
          automountServiceAccountToken: false
          containers:
          - image: grafana/grafana-dev:12.4.0-21524955964
            imagePullPolicy: IfNotPresent
            livenessProbe:
              failureThreshold: 3
              initialDelaySeconds: 30
              periodSeconds: 10
              successThreshold: 1
              tcpSocket:
                port: 3000
              timeoutSeconds: 1
            name: server
            ports:
            - containerPort: 3000
              name: server
              protocol: TCP
            readinessProbe:
              failureThreshold: 3
              httpGet:
                path: /robots.txt
                port: 3000
                scheme: HTTP
              initialDelaySeconds: 10
              periodSeconds: 30
              successThreshold: 1
              timeoutSeconds: 2
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-storage
          securityContext:
            fsGroup: 472
            supplementalGroups:
            - 0
          volumes:
          - name: grafana-storage
            persistentVolumeClaim:
              claimName: server-grafana
    ~~~

    Beyond checking the correctness of all the values, names and paths, there is nothing special to say about this particular output.

## Do not deploy this Grafana server project on its own

This Grafana server cannot be deployed on its own because is missing several elements, such as the persistent volume required by the PVC, or the Traefik ingress that enables access to it. All the missing elements will be declared and put together with all the other components in the final part of this chapter G035.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/server-grafana`
- `$HOME/k8sprjs/monitoring/components/server-grafana/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/monitoring/components/server-grafana/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.service.yaml`
- `$HOME/k8sprjs/monitoring/components/server-grafana/resources/server-grafana.statefulset.yaml`

## References

### [Grafana OSS](https://grafana.com/grafana/)

- [Grafana documentation. Set up](https://grafana.com/docs/grafana/latest/setup-grafana/installation/)
  - [Install Grafana. Deploy Grafana on Kubernetes](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/)
  - [Configure a Grafana Docker image](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/)
    - [Run the Grafana main branch](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/#run-the-grafana-main-branch)

- [Docker Hub. Grafana Docker image (dev)](https://hub.docker.com/r/grafana/grafana-dev/)

- [GitHub. Grafana](https://github.com/grafana/grafana)

### Other Grafana-related contents

- [Medium. Codex. Reliable Kubernetes on a Raspberry Pi Cluster: Monitoring](https://medium.com/codex/reliable-kubernetes-on-a-raspberry-pi-cluster-monitoring-a771b497d4d3)

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Concepts. Workloads. Pods. Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
  - [Container probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers. Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

- [Kubernetes Documentation. Reference. Kubernetes API. Workload Resources. Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
  - [Lifecycle](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#lifecycle-1)
  - [Security context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 4**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 6**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md)
