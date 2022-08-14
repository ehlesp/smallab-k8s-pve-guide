# G035 - Deploying services 04 ~ Monitoring stack - Part 5 - Grafana

Prometheus has its own graphical web interface for handling all its functionality and notifications, but it's not as powerful or popular as Grafana for visualizing the data it gathers from its sources. Therefore, in this guide you'll declare a Grafana Kustomize deployment based on the [official installation documentation for the **Open Source** version of this tool](https://grafana.com/docs/grafana/latest/installation/kubernetes/).

## Kustomize project folders for Grafana

Generate the folder structure of the Kustomize project for your Grafana setup.

~~~bash
$ mkdir -p $HOME/k8sprjs/monitoring/components/ui-grafana/resources
~~~

## Grafana data storage

You have to make available for Grafana the 2GiB LVM persistent volume you created for it in the [first part](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#lvm-storage-set-up) of this guide. Hence, you have to configure a persistent volume claim for connecting Grafana to it.

### _Claim for the data storage PV_

1. Create a file named `data-ui-grafana.persistentvolumeclaim.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/ui-grafana/resources/data-ui-grafana.persistentvolumeclaim.yaml
    ~~~

2. Put in `data-ui-grafana.persistentvolumeclaim.yaml` the next yaml.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: data-ui-grafana
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: data-grafana
      resources:
        requests:
          storage: 1.9G
    ~~~

## Grafana Stateful resource

Grafana will store some data, so you should deploy this visualization tool with a `StatefulSet` resource.

1. Produce a `ui-grafana.statefulset.yaml` file under the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.statefulset.yaml
    ~~~

2. Copy in `ui-grafana.statefulset.yaml` the yaml declaration below.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: ui-grafana
    spec:
      replicas: 1
      serviceName: ui-grafana
      template:
        spec:
          securityContext:
            fsGroup: 472
            supplementalGroups:
            - 0
          containers:
          - name: server
            image: grafana/grafana:8.5.2
            ports:
            - containerPort: 3000
              name: http
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
              limits:
                cpu: 500m
                memory: 256Mi
            volumeMounts:
            - mountPath: /var/lib/grafana
              name: ui-grafana-storage
          volumes:
            - name: ui-grafana-storage
              persistentVolumeClaim:
                claimName: data-ui-grafana
    ~~~

    This `StatefulSet` for Grafana has a number of particularities, inherited from the yaml specified in Grafana's installation documentation.

    - `securityContext`: this section is [for narrowing some security concerns](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context) at the pod level.
        - `fsGroup` is for specifying the numerical Linux filesystem GID of a group that will be applied to all the containers within the pod.
        - `supplementalGroups` is a list of GID of groups applied to the first process run in **each** container. Notice that in this case it'll be the `root` group (GID `0`).

    - `server` container: only one container will run in this pod.
        - The `image` is for the **Open Source** version of Grafana (`grafana/grafana`), in its `8.5.2` release.

    - In `ports`, just one, named `http`, is configured for HTTP communication in the port `3000`.

        > **BEWARE!**  
        > In this setup, Grafana runs a non-secured HTTP configuration, but later you'll secure the communications to it through Traefik.

    - The `readinessProbe` and `livenessProbe` sections configure probes to check the health of the container. These are part of containers' lifecycle management capabilities of Kubernetes, so its better to check the official documentation [here](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#lifecycle-1) and [here](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes). Still, I can tell you here the main things about them.
        - `readinessProbe` probes periodically if the container is truly ready to accept requests. If not, the Kubernetes system will **remove** it from service endpoints.
        - `livenessProbe` checks frequently if the container is alive. When not, Kubernetes will **restart** it.
        - In both sections you can see that they have mostly the same parameters:
            - All the `Threshold` named ones are numerical counters.
            - All the `Seconds` named ones are timers measured in, you guessed it, seconds.
        - On the other hand, both sections have a particular subsection that tells what to probe.
            - `readinessProbe` checks the `/robots.txt` `path` served by grafana on the `port 3000` on a `HTTP` connection `scheme`.
            - `livenessProbe` tries to get a just response from the `tcpSocket` at the `port 3000`.

    - `volumeMounts` section: only mounts the storage for Grafana's data
        - `/var/lib/grafana`: path where Grafana stores its own data by default.

## Grafana Service resource

To make Grafana available, you'll require a `Service` resource for it.

1. Create a file named `ui-grafana.service.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.service.yaml
    ~~~

2. Edit `ui-grafana.service.yaml` and put the following yaml in it.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: ui-grafana
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port:   '3000'
    spec:
      type: ClusterIP
      ports:
      - port: 443
        targetPort: 3000
        protocol: TCP
        name: http
    ~~~

    As with the [Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus%20server%20service%20resource), the `Service` for Grafana is a simple one.

    - This service has `prometheus.io` annotations because Grafana also provides Prometheus metrics of itself.
        - The path is omitted because Grafana uses the standard patch `/metrics`.
        - Notice how the `port` annotated corresponds with the `targetPort` parameter of the sole port enabled in this service.

    - The type is `ClusterIP` because you want this `Service` to be reachable through Traefik so you can have your certificate applied when accessing Grafana.

    - The sole `port` listed redirects from `443` to the `https` port opened at `3000` by Grafana's container.
        > **BEWARE!**  
        > The port redirection is needed to make Grafana reachable through the standard HTTPS port `443`. Mind you that the port only doesn't make the connection secure, something you'll achieve with the Traefik IngressRoute resource configured right in the next section.

## Grafana Traefik IngressRoute resource

Since you'll make Grafana's service accessible through Traefik, create it's required `IngressRoute` as follows.

1. Under the `resources` folder, create a file called `ui-grafana.ingressroute.traefik.yaml`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.ingressroute.traefik.yaml
    ~~~

2. Put in `ui-grafana.ingressroute.traefik.yaml` the yaml below.

    ~~~yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute

    metadata:
      name: ui-grafana
    spec:
      entryPoints:
        - websecure
      tls:
        secretName: wildcard.deimos.cloud-tls
      routes:
      - match: Host(`grafana.deimos.cloud`) || Host(`gfn.deimos.cloud`)
        kind: Rule
        services:
        - name: mntr-ui-grafana
          kind: Service
          port: 443
          scheme: http
    ~~~

    This yaml is almost identical to the IngressRoute declared for the [Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-traefik-ingressroute-resource).

    - The `IngressRoute` points to the secret of your wildcard certificate, encrypting the traffic coming and going to the `ui-grafana` service.

    - You must tell Traefik what **schema** to use for communicating with your Grafana pod. Grafana is running just with HTTP, then set the `scheme` parameter set as `http`, so Traefik can make internal requests to the pod in the HTTP protocol.

    - **IMPORTANT!** As it happened with the Prometheus server's service, I've added the prefix (`mntr-`) to the `name` for invoking the grafana service (`ui-grafana`).

    > **BEWARE!**  
    > Remember to enable in your network the domains you've specified for Grafana in the `match` attribute, making them aim to the **Traefik** service's IP.

## Grafana Kustomize project

With all the previous components declared, you can work on the Kustomize project that puts this Grafana setup together.

1. Create a `kustomization.yaml` file in the `ui-grafana` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/ui-grafana/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the following yaml.

    ~~~yaml
    # Grafana setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: ui-grafana

    resources:
    - resources/data-ui-grafana.persistentvolumeclaim.yaml
    - resources/ui-grafana.ingressroute.traefik.yaml
    - resources/ui-grafana.service.yaml
    - resources/ui-grafana.statefulset.yaml

    replicas:
    - name: ui-grafana
      count: 1

    images:
    - name: grafana/grafana
      newTag: 8.5.2
    ~~~

    The only particularity to point at from this `kustomization.yaml` is the fact that there's neither `configMapGenerator` nor `secretGenerator` blocks.

### _Validating the Kustomize yaml output_

Like in previous guides, validate this Kustomize project's output.

1. Execute `kubectl kustomize` redirecting its output to a `ui-grafana.k.output.yaml` file.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/ui-grafana > ui-grafana.k.output.yaml
    ~~~

2. The resulting `ui-grafana.k.output.yaml` should look as the yaml next.

    ~~~yaml
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "3000"
        prometheus.io/scrape: "true"
      labels:
        app: ui-grafana
      name: ui-grafana
    spec:
      ports:
      - name: http
        port: 443
        protocol: TCP
        targetPort: 3000
      selector:
        app: ui-grafana
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: ui-grafana
      name: data-ui-grafana
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.9G
      storageClassName: local-path
      volumeName: data-grafana
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: ui-grafana
      name: ui-grafana
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: ui-grafana
      serviceName: ui-grafana
      template:
        metadata:
          labels:
            app: ui-grafana
        spec:
          containers:
          - image: grafana/grafana:8.5.2
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
              name: http
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
              limits:
                cpu: 500m
                memory: 256Mi
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - mountPath: /var/lib/grafana
              name: ui-grafana-storage
          securityContext:
            fsGroup: 472
            supplementalGroups:
            - 0
          volumes:
          - name: ui-grafana-storage
            persistentVolumeClaim:
              claimName: data-ui-grafana
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      labels:
        app: ui-grafana
      name: ui-grafana
    spec:
      entryPoints:
      - websecure
      routes:
      - kind: Rule
        match: Host(`grafana.deimos.cloud`) || Host(`gfn.deimos.cloud`)
        services:
        - kind: Service
          name: mntr-ui-grafana
          port: 443
          scheme: http
      tls:
        secretName: wildcard.deimos.cloud-tls
    ~~~

    Beyond checking the correctness of all the values (in particular the service name referenced with the `mntr-` prefix in the `IngressRoute`), there's nothing particularly relevant to say about this output.

## Don't deploy this Grafana project on its own

This Grafana instance cannot be deployed on its own because is missing several elements, such as the persistent volumes required by the PVCs and also the certificate in the correct namespace. As with the Nextcloud platform, you'll tie everything together in this guide's final part.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/ui-grafana`
- `$HOME/k8sprjs/monitoring/components/ui-grafana/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/monitoring/components/ui-grafana/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/ui-grafana/resources/data-ui-grafana.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.ingressroute.traefik.yaml`
- `$HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.service.yaml`
- `$HOME/k8sprjs/monitoring/components/ui-grafana/resources/ui-grafana.statefulset.yaml`

## References

### _Kubernetes_

- [PodSpec securityContext section](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context)
- [Pod Lifecycle capabilities](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#lifecycle-1)
- [Container probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

### _Grafana_

- [Grafana Dashboard](https://grafana.com/grafana/)
- [Deploy Grafana on Kubernetes](https://grafana.com/docs/grafana/v8.5/installation/kubernetes/)
- [Internal Grafana metrics](https://grafana.com/docs/grafana/v8.5/administration/view-server/internal-metrics/)
- [Grafana docker image](https://hub.docker.com/r/grafana/grafana)
- [Grafana on GitHub](https://github.com/grafana/grafana)
- [Reliable Kubernetes on a Raspberry Pi Cluster: Monitoring](https://medium.com/codex/reliable-kubernetes-on-a-raspberry-pi-cluster-monitoring-a771b497d4d3)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 4**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 6**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md)
