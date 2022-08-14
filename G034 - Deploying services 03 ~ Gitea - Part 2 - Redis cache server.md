# G034 - Deploying services 03 ~ Gitea - Part 2 - Redis cache server

Here you're going to setup a Redis server as a memory cache for Gitea, in a very similar way as you did for Nextcloud.

## Kustomize project folders for Gitea and Redis

First, you have to create a folder for your Gitea's main Kustomize project and, within it, a directory tree for the Redis subproject. You can do this with just one `mkdir` command.

~~~bash
$ mkdir -p $HOME/k8sprjs/gitea/components/cache-redis/{configs,resources,secrets}
~~~

## Redis configuration file

Prepare the `redis.conf` file that will specify some configuration values for your Redis server.

1. In the `configs` subfolder of the Redis project, create a `redis.conf` file.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/cache-redis/configs/redis.conf
    ~~~

2. Copy in `redis.conf` the lines below.

    ~~~properties
    port 6379
    bind 0.0.0.0
    protected-mode no
    maxmemory 64mb
    maxmemory-policy allkeys-lru
    ~~~

    The parameters are exactly the same ones you set up in the [part 2 of the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-configuration-file), go back to it if you don't remember the meaning of the values above.

## Redis password

To make your Redis instance a bit more secure, you need to set it up with a long password.

1. Create a new `redis.pwd` file in the `secrets` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/cache-redis/secrets/redis.pwd
    ~~~

2. In `redis.pwd` just type a long alphanumeric password for your Redis instance.

    ~~~properties
    Y0ur_rE3e41Ly.lOng-S3kreT_P4s5woRd-heRE!
    ~~~

    > **BEWARE!**  
    > Be **very careful** about not leaving any kind of spurious characters at the end of the password, like a line break (`\n`), to avoid unexpected odd issues when this password is used.  
    Also notice that the password is stored as a plain text here, so be careful about who access this file.

## Redis Deployment resource

Since this Redis instance will only work with data in memory, you can set it up with a `Deployment` resource.

1. Create a `cache-redis.deployment.yaml` file under the `resources` subfolder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/cache-redis/resources/cache-redis.deployment.yaml
    ~~~

2. In `cache-redis.deployment.yaml` copy the following yaml.

    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment

    metadata:
      name: cache-redis
    spec:
      replicas: 1
      template:
        spec:
          containers:
          - name: server
            image: redis:6.2-alpine
            command:
            - redis-server
            - "/etc/redis/redis.conf"
            - "--requirepass $(REDIS_PASSWORD)"
            env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            ports:
            - containerPort: 6379
            resources:
              limits:
                memory: 64Mi
            volumeMounts:
            - name: redis-config
              subPath: redis.conf
              mountPath: /etc/redis/redis.conf
          - name: metrics
            image: oliver006/redis_exporter:v1.32.0-alpine
            env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            resources:
              limits:
                memory: 32Mi
            ports:
            - containerPort: 9121
          volumes:
          - name: redis-config
            configMap:
              name: cache-redis
              defaultMode: 0444
              items:
              - key: redis.conf
                path: redis.conf
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                    - key: app
                      operator: In
                      values:
                      - server-gitea
                  topologyKey: "kubernetes.io/hostname"
    ~~~

    This `Deployment` resource is almost identical to the one described in the [part 2 of the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-deployment-resource). The only difference is in the `labelSelector` block set in the `affinity.podAffinity` section: the `key` is the same, `app`, but the value has been changed to `server-gitea`.

## Redis Service resource

To expose Redis you need a `Service` resource.

1. Generate a new file named `cache-redis.service.yaml`, also under the `resources` subfolder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/cache-redis/resources/cache-redis.service.yaml
    ~~~

2. Fill `cache-redis.service.yaml` with the content below.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: cache-redis
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9121"
    spec:
      type: ClusterIP
      ports:
      - port: 6379
        protocol: TCP
        name: server
      - port: 9121
        protocol: TCP
        name: metrics
    ~~~

    This `Service` resource is the same as the one declared [in the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource), except that it doesn't have a `clusterIP` explicitly set to a particular internal IP. And, since that cluster IP can change everytime the Service is restarted, you'll have to invoke it by its FQDN.

### _Redis `Service`'s FQDN or DNS record_

To know beforehand what DNS record will be assigned to this `Service`, be aware of the following.

- The string format for any `Service` resource's FQDN is `<metadata.name>.<namespace>.svc.<internal.cluster.domain>`.
- The namespace for all resources of the Gitea platform will be `gitea`.
- The internal cluster domain that was set back [in the **G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file) is `deimos.cluster.io`.
- All the components of the Gitea platform will also have a `gitea-` prefix added to their `metadata.name` string.

Taking all of the above into account, the correct FQDN this Service will get assigned when deployed will be like next.

~~~http
gitea-cache-redis.gitea.svc.deimos.cluster.io
~~~

## Redis Kustomize project

The last piece is the `kustomization.yaml` file that describes this Gitea's Redis service.

1. Under the `cache-redis` folder, produce a `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/cache-redis/kustomization.yaml
    ~~~

2. Fill the `kustomization.yaml` file with the following yaml.

    ~~~yaml
    # Redis setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: cache-redis

    resources:
    - resources/cache-redis.deployment.yaml
    - resources/cache-redis.service.yaml

    replicas:
    - name: cache-redis
      count: 1

    images:
    - name: redis
      newTag: 6.2-alpine
    - name: oliver006/redis_exporter
      newTag: v1.32.0-alpine

    configMapGenerator:
    - name: cache-redis
      files:
      - configs/redis.conf

    secretGenerator:
    - name: cache-redis
      files:
      - redis-password=secrets/redis.pwd
    ~~~

    This `kustomization.yaml` is exactly the same as the one you declared for [the Nextcloud's Redis service](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-kustomize-project). No value needs to be changed here.

### _Checking the Kustomize yaml output_

Now you can check out how the Kustomize output looks like for this Redis subproject.

1. Execute the `kubectl kustomize` command on the Redis Kustomize project's root folder, piped to `less` to get the output paginated.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/gitea/components/cache-redis | less
    ~~~

    Remember that you could also dump the yaml output on a file, called `cache-redis.k.output.yaml` for instance.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/gitea/components/cache-redis > cache-redis.k.output.yaml
    ~~~

2. The yaml output should be like the one next.

    ~~~yaml
    apiVersion: v1
    data:
      redis.conf: |
        port 6379
        bind 0.0.0.0
        protected-mode no
        maxmemory 64mb
        maxmemory-policy allkeys-lru
    kind: ConfigMap
    metadata:
      labels:
        app: cache-redis
      name: cache-redis-6967fc5hc5
    ---
    apiVersion: v1
    data:
      redis-password: |
        Tm9wZV90aGlzX2lzX05PVF9vbmVfb2ZfbXlfcGFzc3dvcmRzX0FuZC15b3Vfc2hvdWxkbnRfdXNl
        X3RoaXNfb25lX2VpdGhlciEK
    kind: Secret
    metadata:
      labels:
        app: cache-redis
      name: cache-redis-4dg79kf68c
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9121"
        prometheus.io/scrape: "true"
      labels:
        app: cache-redis
      name: cache-redis
    spec:
      ports:
      - name: server
        port: 6379
        protocol: TCP
      - name: metrics
        port: 9121
        protocol: TCP
      selector:
        app: cache-redis
      type: ClusterIP
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: cache-redis
      name: cache-redis
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: cache-redis
      template:
        metadata:
          labels:
            app: cache-redis
        spec:
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - server-gitea
                topologyKey: kubernetes.io/hostname
          containers:
          - command:
            - redis-server
            - /etc/redis/redis.conf
            - --requirepass $(REDIS_PASSWORD)
            env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: redis-password
                  name: cache-redis-4dg79kf68c
            image: redis:6.2-alpine
            name: server
            ports:
            - containerPort: 6379
            resources:
              limits:
                memory: 64Mi
            volumeMounts:
            - mountPath: /etc/redis/redis.conf
              name: redis-config
              subPath: redis.conf
          - env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: redis-password
                  name: cache-redis-4dg79kf68c
            image: oliver006/redis_exporter:v1.32.0-alpine
            name: metrics
            ports:
            - containerPort: 9121
            resources:
              limits:
                memory: 32Mi
          volumes:
          - configMap:
              defaultMode: 292
              items:
              - key: redis.conf
                path: redis.conf
              name: cache-redis-6967fc5hc5
            name: redis-config
    ~~~

3. If you like, you can also validate the output with `kubeval`, if you have dumped the yaml on a file

## Don't deploy this Redis project on its own

As it happened in the Nextcloud platform guide, remember that you don't want to deploy a subproject like this one on its own. You'll deploy it as component of the master Kustomize project for Gitea.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/gitea`
- `$HOME/k8sprjs/gitea/components`
- `$HOME/k8sprjs/gitea/components/cache-redis`
- `$HOME/k8sprjs/gitea/components/cache-redis/configs`
- `$HOME/k8sprjs/gitea/components/cache-redis/resources`
- `$HOME/k8sprjs/gitea/components/cache-redis/secrets`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/gitea/components/cache-redis/kustomization.yaml`
- `$HOME/k8sprjs/gitea/components/cache-redis/configs/redis.conf`
- `$HOME/k8sprjs/gitea/components/cache-redis/resources/cache-redis.deployment.yaml`
- `$HOME/k8sprjs/gitea/components/cache-redis/resources/cache-redis.service.yaml`
- `$HOME/k8sprjs/gitea/components/cache-redis/secrets/redis.pwd`

## References

### _Kubernetes_

#### **Pod scheduling**

- [Official Doc - Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Official Doc - Assign Pods to Nodes using Node Affinity](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)
- [Kubernetes API - Pod scheduling](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#scheduling)
- [STRATEGIES FOR KUBERNETES POD PLACEMENT AND SCHEDULING](https://thenewstack.io/strategies-for-kubernetes-pod-placement-and-scheduling/)
- [Implement Node and Pod Affinity/Anti-Affinity in Kubernetes: A Practical Example](https://thenewstack.io/implement-node-and-pod-affinity-anti-affinity-in-kubernetes-a-practical-example/)
- [Tutorial: Apply the Sidecar Pattern to Deploy Redis in Kubernetes](https://thenewstack.io/tutorial-apply-the-sidecar-pattern-to-deploy-redis-in-kubernetes/)
- [Amazon EKS Workshop Official Doc - Assigning Pods to Nodes](https://www.eksworkshop.com/beginner/140_assigning_pods/affinity_usecases/)

#### **Services**

- [DNS for Services](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#services)
- [Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

#### **ConfigMaps and secrets**

- [Official Doc - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Official Doc - Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [Kubernetes ConfigMaps and Secrets](https://shravan-kuchkula.github.io/kubernetes/configmaps-secrets/)
- [Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### **Environment variables**

- [Official Doc - Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [Official Doc - Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)

#### **DNS**

- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)

### _Redis_

- [Redis](https://redis.io/)
- [Redis FAQ](https://redis.io/topics/faq)
- [Redis administration](https://redis.io/topics/admin)
- [Redis on DockerHub](https://hub.docker.com/_/redis)
- [Prometheus Redis Metrics Exporter on DockerHub](https://hub.docker.com/r/oliver006/redis_exporter)
- [`redis.conf` commented example](https://gist.github.com/jeff-french/4712257)
- [Simple Redis Cache on Kubernetes with Prometheus Metrics](https://itnext.io/simple-redis-cache-on-kubernetes-with-prometheus-metrics-8667baceab6b)
- [Deploying single node redis in kubernetes environment](https://developpaper.com/deploying-single-node-redis-in-kubernetes-environment/)
- [Single server Redis](https://rpi4cluster.com/k3s/k3s-redis/)
- [Kubernetes Official Doc - Configuring Redis using a ConfigMap](https://kubernetes.io/docs/tutorials/configuration/configure-redis-using-configmap/)
- [redis-server - Man Page](https://www.mankier.com/1/redis-server)
- [Deploy and Operate a Redis Cluster in Kubernetes](https://marklu-sf.medium.com/deploy-and-operate-a-redis-cluster-in-kubernetes-94fde7853001)
- [Redis Setup on Kubernetes](https://blog.opstree.com/2020/08/04/redis-setup-on-kubernetes/)
- [Rancher Official Doc - Deploying Redis Cluster on Top of Kubernetes](https://rancher.com/blog/2019/deploying-redis-cluster/)
- [Running Redis on Multi-Node Kubernetes Cluster in 5 Minutes](https://collabnix.com/running-redis-on-kubernetes-cluster-in-5-minutes/)
- [Redis sentinel vs clustering](https://stackoverflow.com/questions/31143072/redis-sentinel-vs-clustering)

## Navigation

[<< Previous (**G034. Deploying services 03. Gitea Part 1**)](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Gitea Part 3**) >>](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md)
