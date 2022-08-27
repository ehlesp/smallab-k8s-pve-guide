# G034 - Deploying services 03 ~ Gitea - Part 4 - Gitea server

The last component to setup in its own Kustomize project is the Gitea server itself.

## Considerations about the Gitea server

Gitea is a platform specialized in storing and handling Git repositories, which you can upload to Gitea through HTTP or SSH connections. Moreover, Gitea comes with a web console and embedded Prometheus-formatted metrics. All of this means that you'll run one Gitea container but with two ports opened on it.

## Gitea server Kustomize project's folders

Prepare your Gitea's Kustomize project folder tree as follows.

~~~bash
$ mkdir -p $HOME/k8sprjs/gitea/components/server-gitea/{configs,resources}
~~~

Notice that there's no `secret` folder to be created this time.

## Gitea server configuration file

Here I'll tell you about preparing just one properties file with a couple of values. The Gitea server's configuration will be done by declaring special environment variables.

### _Properties file `params.properties`_

You'll want to keep certain parameters in a `params.properties` file for convenience.

1. Create the file `params.properties` under the `configs` path.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/configs/params.properties
    ~~~

2. Set the parameters below in `params.properties`.

    ~~~properties
    cache-redis-svc-fqdn=gitea-cache-redis.gitea.svc.deimos.cluster.io
    db-postgresql-svc-fqdn=gitea-db-postgresql.gitea.svc.deimos.cluster.io
    ~~~

    The parameters set above mean the following.
    - `cache-redis-svc-fqdn`: the internal FQDN of the Redis service for Gitea.
    - `db-postgresql-svc-fqdn`: the internal FQDN of the PostgreSQL service for Gitea.

## Gitea server storage

You'll require two persistent volumes for your Gitea server.

- One PV for storing the server's data files.
- One PV to store users' Git repositories.

So you also need declaring two different claim resources, one per PV.

### _Claim for the server files PV_

1. Create a file named `data-server-gitea.persistentvolumeclaim.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/data-server-gitea.persistentvolumeclaim.yaml
    ~~~

2. Copy the yaml below in `data-server-gitea.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: data-server-gitea
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: data-gitea
      resources:
        requests:
          storage: 1.2G
    ~~~

### _Claim for the users git repositories PV_

1. Create a `repos-server-gitea.persistentvolumeclaim.yaml` file under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/repos-server-gitea.persistentvolumeclaim.yaml
    ~~~

2. Fill `repos-server-gitea.persistentvolumeclaim.yaml` with the declaration next.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: repos-server-gitea
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: repos-gitea
      resources:
        requests:
          storage: 9.3G
    ~~~

## Gitea server Stateful resource

Gitea is a server that stores data, so it needs to be deployed with a `StatefulSet` resource.

1. Create a `server-gitea.statefulset.yaml` file under the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.statefulset.yaml
    ~~~

2. Put the yaml declaration below in `server-gitea.statefulset.yaml`.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-gitea
    spec:
      replicas: 1
      serviceName: server-gitea
      template:
        spec:
          containers:
          - name: server
            image: gitea/gitea:1.15.9
            ports:
            - containerPort: 3000
              name: https
            - containerPort: 22
              name: ssh
            env:
            - name: GITEA__server__PROTOCOL
              value: https
            - name: GITEA__server__DOMAIN
              value: gitea.deimos.cloud
            - name: GITEA__server__HTTP_ADDR
              value: 0.0.0.0
            - name: GITEA__server__ROOT_URL
              value: $(GITEA__server__PROTOCOL)://$(GITEA__server__DOMAIN)/
            - name: GITEA__server__CERT_FILE
              value: https/wildcard.deimos.cloud-tls.crt
            - name: GITEA__server__KEY_FILE
              value: https/wildcard.deimos.cloud-tls.key
            - name: GITEA__repository__ROOT
              value: /data/gitea/repos
            - name: GITEA__metrics__ENABLED
              value: "true"
            - name: GITEA__database__DB_TYPE
              value: postgres
            - name: POSTGRESQL_HOST_FQDN
              valueFrom:
                configMapKeyRef:
                  name: server-gitea
                  key: db-postgresql-svc-fqdn
            - name: GITEA__database__HOST
              value: "$(POSTGRESQL_HOST_FQDN):5432"
            - name: GITEA__database__NAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: postgresql-db-name
            - name: GITEA__database__USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: gitea-username
            - name: GITEA__database__PASSWD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql
                  key: gitea-user-password
            - name: GITEA__database__SSL_MODE
              value: disable
            - name: GITEA__cache__ENABLED
              value: "true"
            - name: GITEA__cache__ADAPTER
              value: redis
            - name: REDIS_HOST_FQDN
              valueFrom:
                configMapKeyRef:
                  name: server-gitea
                  key: cache-redis-svc-fqdn
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            - name: GITEA__cache__HOST
              value: "redis://:$(REDIS_HOST_PASSWORD)@$(REDIS_HOST_FQDN):6379/0?pool_size=100&idle_timeout=180s"
            - name: GITEA__queue__TYPE
              value: redis
            - name: GITEA__queue__CONN_STR
              value: "redis://:$(REDIS_HOST_PASSWORD)@$(REDIS_HOST_FQDN):6379/0"
            - name: GITEA__session__PROVIDER
              value: redis
            - name: GITEA__session__PROVIDER_CONFIG
              value: $(GITEA__cache__HOST)
            - name: GITEA__session__COOKIE_SECURE
              value: "true"
            - name: GITEA__session__COOKIE_NAME
              value: gitea_cookie
            - name: GITEA__log__ROUTER_LOG_LEVEL
              value: trace
            resources:
              limits:
                memory: 256Mi
            volumeMounts:
            - name: data-storage
              mountPath: /data
            - name: certificate
              subPath: wildcard.deimos.cloud-tls.crt
              mountPath: /data/gitea/https/wildcard.deimos.cloud-tls.crt
            - name: certificate
              subPath: wildcard.deimos.cloud-tls.key
              mountPath: /data/gitea/https/wildcard.deimos.cloud-tls.key
            - name: repos-storage
              mountPath: /data/gitea/repos
          volumes:
          - name: certificate
            secret:
              secretName: wildcard.deimos.cloud-tls
              items:
              - key: tls.crt
                path: wildcard.deimos.cloud-tls.crt
              - key: tls.key
                path: wildcard.deimos.cloud-tls.key
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-gitea
          - name: repos-storage
            persistentVolumeClaim:
              claimName: repos-server-gitea
    ~~~

    There are a few particularities in this `StatefulSet` in comparison with the others you've seen before.

    - `server` container: there's only one container in the pod. Since Gitea already provides Prometheus metrics, you don't need another sidecar container to run a service that provides those metrics.

        - The `image` is for the version `1.15.9` of Gitea, built on an Alpine Linux system.

        - In `ports` you have two ports declared, the `https` one to access the web interface (Gitea by default listens on the port `3000`) and the `ssh` for connecting with this Gitea server through that protocol (which uses the port `22` as the standard one).
            > **BEWARE!**  
            > The `containerPort` declarations are essentialy informative, they don't actually determine what ports are opened in a pod. That's up to the applications or services running within the pod. [Check this thread](https://stackoverflow.com/questions/57197095/why-do-we-need-a-port-containerport-in-a-kuberntes-deployment-container-definiti) to know more about this technicality.

        - `env` section: the main oddity in the variables set here is the format of those named `GITEA_`. It's a format [explained here](https://github.com/go-gitea/gitea/tree/main/contrib/environment-to-ini) that allows the Gitea in this Docker image to overwrite the corresponding configuration parameters in its default `/data/gitea/conf/app.ini` file with the values set in these variables.
            - `GITEA__server__PROTOCOL`: indicates on which protocol this Gitea server listens on.
            - `GITEA__server__DOMAIN`: the domain name for this server. As in other cases, you'll have to enable the domain in your network or directly in your client systems using the `hosts` file.
            - `GITEA__server__HTTP_ADDR`: on which IPs this server will listen on.
            - `GITEA__server__ROOT_URL`: overwrites the automatically generated public URL. The autogenerated one also includes the port after the domain, which I've removed here because you'll access this Gitea server through the a `Service` configured to use the standard HTTPS port `443`.
            - `GITEA__server__CERT_FILE`: path to the public or crt part of the certificate used for HTTPS communication. The path is relative to the value set in a `CUSTOM_PATH` variable which, in the Docker image of Gitea, is set to `/data/gitea`.
            - `GITEA__server__KEY_FILE`: path to the private key of the certificate used for HTTPS communications. Also relative to the `CUSTOM_PATH` variable.
            - `GITEA__repository__ROOT`: absolute path to the directory where the Git repositories of the users are kept.
            - `GITEA__metrics__ENABLED`: for enabling the Prometheus metrics endpoint included in the Gitea server.
            - `GITEA__database__DB_TYPE`: indicates the type of database Gitea must use.
            - `POSTGRESQL_HOST_FQDN`: variable for loading as environment variable the FQDN of the PostgreSQL server this Gitea instance will connect to.
            - `GITEA__database__HOST`: connection string to reach the database for this Gitea instance.
            - `GITEA__database__NAME`: name of the database to connect to in the database server.
            - `GITEA__database__USER`: Gitea user's name in the database.
            - `GITEA__database__PASSWD`: Gitea user's password in the database.
            - `GITEA__database__SSL_MODE`: for enabling or disabling encryption in the communication with the database.
            - `GITEA__cache__ENABLED`: for enabling the cache on the Gitea instance.
            - `GITEA__cache__ADAPTER`: depending on what caching engine you want to use, you'll have to set the proper adapter here to connect to that engine.
            - `REDIS_HOST_FQDN`: variable for loading as environment variable the FQDN of the Redis server this Gitea instance will connect to.
            - `REDIS_HOST_PASSWORD`: custom variable to load the password for connecting with the Redis server.
            - `GITEA__cache__HOST`: the full connection string to reach the cache server.
            - `GITEA__queue__TYPE`: type of queue to be used.
            - `GITEA__queue__CONN_STR`: connection string for the `redis` queue type.
            - `GITEA__session__PROVIDER`: indicates what session engine provider you want to use.
            - `GITEA__session__PROVIDER_CONFIG`: this value will vary depending on what session engine provider you uses. For Redis is the full connection string.
            - `GITEA__session__COOKIE_SECURE`: when `true`, this forces using HTTPS on all session accesses.
            - `GITEA__session__COOKIE_NAME`: name of the cookie used for the session ID.

        - `volumeMounts` section: mounts the certificate files and the two storage volumes for storing Gitea's data.
            - `/data`: the Gitea Docker image will put here contents required to run the instance.
            - `wildcard.deimos.cloud-tls.crt` and `wildcard.deimos.cloud-tls.key`: the certificate files that, for this Gitea setup, must be placed at `/data/gitea/https`.
            - `/data/gitea/repos`: folder where Gitea will store the users' Git repositories.

                > **BEWARE!**  
                > Gitea works with several paths, each with a different purpose. To know more about them, [check this FAQ question](https://docs.gitea.io/en-us/faq/#where-does-gitea-store-what-file) in the official Gitea documentation. On the other hand, be aware that, [in Gitea's Docker image](https://github.com/go-gitea/gitea/blob/v1.15.8/Dockerfile), the path `/data/gitea` is the default one for application data and custom content (like the certificate files).

## Gitea server Service resource

Now you have to produce the `Service` for your Gitea setup

1. Create a `server-gitea.service.yaml` file under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.service.yaml
    ~~~

2. Copy in `server-gitea.service.yaml` the `Service` declaration next.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: /metrics
        prometheus.io/scheme: "https"
        prometheus.io/port: "3000"
      name: server-gitea
    spec:
      type: LoadBalancer
      loadBalancerIP: 192.168.1.43
      ports:
      - port: 443
        targetPort: 3000
        protocol: TCP
        name: https
      - port: 22
        protocol: TCP
        name: ssh
    ~~~

    There are a few particularities to notice in this `Service` declaration.

    - This `Service` is of the `LoadBalancer` type, so it gets its external IP from the MetalLB load balancer in your cluster.

    - `metadata.annotations`: up till now you've put here only two `prometheus.io` annotations, `scrape` and `port`. Now here you have two more:
        - `path`: is the relative URL to the Prometheus metrics endpoint. By default it's expected to be at `/metrics`, as in this case, but if it's found in another path you'll have to specify it in this annotation.
        - `scheme`: since the connection to Gitea is secured through HTTPS, you must indicate it by setting this parameter to `https`.

    - On the other hand, it doesn't have any particular internal cluster IP specified. This means that its cluster IP may change on every run so, to reach this service internally, you'll better use its FQDN.
        > **BEWARE!**  
        > A `Service` with type `LoadBalancer` cannot have its `clusterIP` set as `None`.

    - The `https` port redirects the requests reaching the `443` port to the `3000`, because that's where the Gitea server is truly listening in its container.

    - It has exactly the same `prometheus.io` annotations that were specified in the previous `StatefulSet`. Notice how the `prometheus.io/port` annotation has the same number as in the `targetPort` of the `https` port. This seems to be the recommended thing to do, at leat according to [this article](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/).

### _Gitea `Service`'s FQDN or DNS record_

[This Gitea Service resource is under the same particularities as the Redis](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-services-fqdn-or-dns-record) and PostgreSQL services, so it's FQDN will be a very similar string.

~~~http
gitea-server-gitea.gitea.svc.deimos.cluster.io
~~~

## Gitea server's Kustomize project

Now you have to put all the Gitea parts together in a `kustomization.yaml` file.

1. Create a `kustomization.yaml` file in the `server-gitea` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the following yaml.

    ~~~yaml
    # Gitea server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-gitea

    resources:
    - resources/data-server-gitea.persistentvolumeclaim.yaml
    - resources/repos-server-gitea.persistentvolumeclaim.yaml
    - resources/server-gitea.service.yaml
    - resources/server-gitea.statefulset.yaml

    replicas:
    - name: server-gitea
      count: 1

    images:
    - name: gitea/gitea
      newTag: 1.15.9

    configMapGenerator:
    - name: server-gitea
      envs:
      - configs/params.properties
    ~~~

    The only thing to highlight in this `kustomization.yaml` is that there's no `secretGenerator` block, unlike the cases of the Redis and PostgreSQL components.

### _Validating the Kustomize yaml output_

As with the other components, you should check the output generated by this Kustomize project.

1. Generate the yaml with `kubectl kustomize` as usual.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/gitea/components/server-gitea | less
    ~~~

2. See if your yaml output matches the one below.

    ~~~yaml
    apiVersion: v1
    data:
      cache-redis-svc-fqdn: gitea-cache-redis.gitea.svc.deimos.cluster.io
      db-postgresql-svc-fqdn: gitea-db-postgresql.gitea.svc.deimos.cluster.io
    kind: ConfigMap
    metadata:
      labels:
        app: server-gitea
      name: server-gitea-hffkf88tm4
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/path: /metrics
        prometheus.io/port: "3000"
        prometheus.io/scheme: https
        prometheus.io/scrape: "true"
      labels:
        app: server-gitea
      name: server-gitea
    spec:
      loadBalancerIP: 192.168.1.43
      ports:
      - name: https
        port: 443
        protocol: TCP
        targetPort: 3000
      - name: ssh
        port: 22
        protocol: TCP
      selector:
        app: server-gitea
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-gitea
      name: data-server-gitea
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.2G
      storageClassName: local-path
      volumeName: data-gitea
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-gitea
      name: repos-server-gitea
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.3G
      storageClassName: local-path
      volumeName: repos-gitea
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-gitea
      name: server-gitea
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-gitea
      serviceName: server-gitea
      template:
        metadata:
          labels:
            app: server-gitea
        spec:
          containers:
          - env:
            - name: GITEA__server__PROTOCOL
              value: https
            - name: GITEA__server__DOMAIN
              value: gitea.deimos.cloud
            - name: GITEA__server__HTTP_ADDR
              value: 0.0.0.0
            - name: GITEA__server__ROOT_URL
              value: $(GITEA__server__PROTOCOL)://$(GITEA__server__DOMAIN)/
            - name: GITEA__server__CERT_FILE
              value: https/wildcard.deimos.cloud-tls.crt
            - name: GITEA__server__KEY_FILE
              value: https/wildcard.deimos.cloud-tls.key
            - name: GITEA__repository__ROOT
              value: /data/gitea/repos
            - name: GITEA__metrics__ENABLED
              value: "true"
            - name: GITEA__database__DB_TYPE
              value: postgres
            - name: POSTGRESQL_HOST_FQDN
              valueFrom:
                configMapKeyRef:
                  key: db-postgresql-svc-fqdn
                  name: server-gitea-hffkf88tm4
            - name: GITEA__database__HOST
              value: $(POSTGRESQL_HOST_FQDN):5432
            - name: GITEA__database__NAME
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql
            - name: GITEA__database__USER
              valueFrom:
                configMapKeyRef:
                  key: gitea-username
                  name: db-postgresql
            - name: GITEA__database__PASSWD
              valueFrom:
                secretKeyRef:
                  key: gitea-user-password
                  name: db-postgresql
            - name: GITEA__database__SSL_MODE
              value: disable
            - name: GITEA__cache__ENABLED
              value: "true"
            - name: GITEA__cache__ADAPTER
              value: redis
            - name: REDIS_HOST_FQDN
              valueFrom:
                configMapKeyRef:
                  key: cache-redis-svc-fqdn
                  name: server-gitea-hffkf88tm4
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: redis-password
                  name: cache-redis
            - name: GITEA__cache__HOST
              value: redis://:$(REDIS_HOST_PASSWORD)@$(REDIS_HOST_FQDN):6379/0?pool_size=100&idle_timeout=180s
            - name: GITEA__queue__TYPE
              value: redis
            - name: GITEA__queue__CONN_STR
              value: redis://:$(REDIS_HOST_PASSWORD)@$(REDIS_HOST_FQDN):6379/0
            - name: GITEA__session__PROVIDER
              value: redis
            - name: GITEA__session__PROVIDER_CONFIG
              value: $(GITEA__cache__HOST)
            - name: GITEA__session__COOKIE_SECURE
              value: "true"
            - name: GITEA__session__COOKIE_NAME
              value: gitea_cookie
            - name: GITEA__log__ROUTER_LOG_LEVEL
              value: trace
            image: gitea/gitea:1.15.9
            name: server
            ports:
            - containerPort: 3000
              name: https
            - containerPort: 22
              name: ssh
            resources:
              limits:
                memory: 256Mi
            volumeMounts:
            - mountPath: /data
              name: data-storage
            - mountPath: /data/gitea/https/wildcard.deimos.cloud-tls.crt
              name: certificate
              subPath: wildcard.deimos.cloud-tls.crt
            - mountPath: /data/gitea/https/wildcard.deimos.cloud-tls.key
              name: certificate
              subPath: wildcard.deimos.cloud-tls.key
            - mountPath: /data/gitea/repos
              name: repos-storage
          volumes:
          - name: certificate
            secret:
              items:
              - key: tls.crt
                path: wildcard.deimos.cloud-tls.crt
              - key: tls.key
                path: wildcard.deimos.cloud-tls.key
              secretName: wildcard.deimos.cloud-tls
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-gitea
          - name: repos-storage
            persistentVolumeClaim:
              claimName: repos-server-gitea
    ~~~

## Don't deploy this Gitea server project on its own

This Gitea server cannot be deployed on its own because is missing several elements, like the persistent volumes required by the PVCs and the certificate. As with the Nextcloud platform, you'll tie everything together in this guide's final part.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/gitea`
- `$HOME/k8sprjs/gitea/components`
- `$HOME/k8sprjs/gitea/components/server-gitea`
- `$HOME/k8sprjs/gitea/components/server-gitea/configs`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/configs/params.properties`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/data-server-gitea.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/repos-server-gitea.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.service.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.statefulset.yaml`

## References

### _Kubernetes_

- [Why do we need a port/containerPort in a Kuberntes deployment/container definition?](https://stackoverflow.com/questions/57197095/why-do-we-need-a-port-containerport-in-a-kuberntes-deployment-container-definiti)
- [Kubernetes API. Ports in containers](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports)
- [Kubernetes & Prometheus Scraping Configuration. Per-pod Prometheus Annotations](https://www.weave.works/docs/cloud/latest/tasks/monitor/configuration-k8s/#per-pod-prometheus-annotations)
- [How to Setup Prometheus Monitoring On Kubernetes Cluster](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
- [How to set up auto-discovery of Kubernetes endpoint services in Prometheus](https://www.acagroup.be/en/blog/auto-discovery-of-kubernetes-endpoint-services-prometheus/)

### _Gitea_

- [Gitea Official site](https://gitea.io/en-us/)
- [Gitea Docker image](https://hub.docker.com/r/gitea/gitea)
- [Gitea on GitHub](https://github.com/go-gitea/gitea)
- [Installation with Docker](https://docs.gitea.io/en-us/install-with-docker/)
- [Configuration Cheat Sheet](https://docs.gitea.io/en-us/config-cheat-sheet/)
- [Managing Deployments With Environment Variables](https://docs.gitea.io/en-us/install-with-docker/#managing-deployments-with-environment-variables)
- [HTTPS setup to encrypt connections to Gitea](https://docs.gitea.io/en-us/https-setup/)
- [Gitea `app.example.ini`](https://github.com/go-gitea/gitea/blob/main/custom/conf/app.example.ini)
- [Gitea Environment To Ini](https://github.com/go-gitea/gitea/tree/main/contrib/environment-to-ini)
- [Gitea command line global options](https://docs.gitea.io/en-us/command-line/#global-options)
- [Gitea Configuration Cheat Sheet](https://docs.gitea.io/en-us/config-cheat-sheet)
- [Where does Gitea store what file](https://docs.gitea.io/en-us/faq/#where-does-gitea-store-what-file)
- [Monitor Gitea with Prometheus](https://serverfault.com/questions/999413/monitor-gitea-with-prometheus)
- [Install and Configure Gitea Git Service on Kubernetes / OpenShift](https://computingforgeeks.com/install-gitea-git-service-on-kubernetes-openshift/)
- [Running Gitea on Kubernetes](https://ralph.blog.imixs.com/2021/02/25/running-gitea-on-kubernetes/)
- [Running Gitea on a Virtual Cloud Server](https://ralph.blog.imixs.com/2021/02/26/running-gitea-on-a-virtual-cloud-server/)
- [Setup a Self-Hosted Git Service with Gitea](https://dev.to/ruanbekker/setup-a-self-hosted-git-service-with-gitea-11ce)
- [gitea support HA mode for redis & postgres](https://gitanswer.com/gitea-support-ha-mode-for-redis-postgres-go-906452007)

## Navigation

[<< Previous (**G034. Deploying services 03. Gitea Part 3**)](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Gitea Part 5**) >>](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md)
