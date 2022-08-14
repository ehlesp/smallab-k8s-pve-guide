# G033 - Deploying services 02 ~ Nextcloud - Part 2 - Redis cache server

In this second part of the Nextcloud guide you'll start working in the Kustomize project for the whole Nextcloud platform's setup. In particular, you'll prepare the Kustomize subproject for a Redis server that will act as the session cache component of your Nextcloud platform.

## Kustomize project folders for Nextcloud and Redis

You need a main Kustomize project for the deployment of your Nextcloud platform and, in it, you'll contain the subprojects of its components like Redis. So, you could execute the following `mkdir` command to comply with those requirements.

~~~bash
$ mkdir -p $HOME/k8sprjs/nextcloud/components/cache-redis/{configs,resources,secrets}
~~~

The main folder for the Redis Kustomize project, `cache-redis`, is named following the pattern `<component function>-<software name>` which I'll use also to name the main directories for the remaining component projects. This Redis project will have not only some resources to deploy, but also a configuration file and a secret, thus the need for the `configs`, `resources` and `secrets` subfolders.

## Redis configuration file

You need to fit Redis to your needs, and the best way is by setting its parameters in a configuration file.

1. In the `configs` subfolder of the Redis project, create a `redis.conf` file.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/cache-redis/configs/redis.conf
    ~~~

    The name `redis.conf` is the default one for the Redis configuration file.

2. Put the lines below in the `redis.conf` file.

    ~~~properties
    port 6379
    bind 0.0.0.0
    protected-mode no
    maxmemory 64mb
    maxmemory-policy allkeys-lru
    ~~~

    The parameters above mean the following.

    - `port`: the default Redis port is `6379`, specified here just for clarity.

    - `bind`: to make the Redis server listen in specific interfaces. With `0.0.0.0` listens to all available ones.
        > **BEWARE!**  
        > You don't want to put here the IP you chose for the Redis service in the previous part. It's better to leave this parameter with a "flexible" value, so you don't have to worry about putting a particular IP in several places.

    - `protected-mode`: security option for restricting Redis from listening in interfaces other than localhost. Enabled by default, is disabled with value `no`.

    - `maxmemory`: limits the memory used by the Redis server. When the limit is reached, it'll try to remove keys accordingly to the eviction policy set in the `maxmemmory-policy` parameter.

    - `maxmemory-policy`: policy for evicting keys from memory when its limit is reached. Here is set to `allkeys-lru` so it can remove any key accordingly to a LRU (Least Recently Used) algorithm.

## Redis password

You'll want to secure the access to this Nextcloud's Redis instance. To do so you can set Redis with a password, but you don't want it lying in the clear in the `redis.conf` file.

1. Create a new `redis.pwd` file in the `secrets` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/cache-redis/secrets/redis.pwd
    ~~~

2. In `redis.pwd` just type a long alphanumeric password for your Redis instance.

    ~~~properties
    Y0ur_rE3e41Ly.lOng-S3kreT_P4s5woRd-heRE!
    ~~~

    > **BEWARE!**  
    > Be **very careful** about not leaving any kind of spurious characters at the end of the password, like a line break (`\n`), to avoid unexpected odd issues when this password is used.  
    > Also notice that the password is stored as a plain text here, so be careful about who access this file.

Later in this guide, you'll see how to set this password as a secret in the corresponding `kustomization.yaml` file of this Redis Kustomize project.

## Redis Deployment resource

The next thing to do is setting up the `Deployment` resource you'll use for deploying Redis in your K3s cluster.

1. Create a `cache-redis.deployment.yaml` file under the `resources` subfolder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/cache-redis/resources/cache-redis.deployment.yaml
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
                      - server-nextcloud
                  topologyKey: "kubernetes.io/hostname"
    ~~~

    This `Deployment` resource describes the template for the pod that will contain the Redis server and its Prometheus metrics exporter service, running each on their own containers.

    - `replicas`: given the limitations of the cluster, only one instance of the Redis pod is requested.

    - `template`: describes how the pod resulting from this `Deployment` should be.

        - `spec.containers`: this pod template has two containers running in it, arranged in what's known as a _sidecar_ pattern.
            - Container `server`: container that runs the Redis server itself.
                - The Docker `image` used is the Alpine Linux variant of [the most recent 6.2 version](https://hub.docker.com/_/redis).
                - In the `command` section you can see how the the configuration file path is indicated to the service, and also how the Redis password is obtained from a `cache-redis` secret (which you'll declare later), then turned into an environment variable (`env` section) to be passed to the `--requirepass` option.
                - The `containerPort` is the same as the one set in the `redis.conf` file.
                - The container is set with a RAM usage limit in the `resources` section.
            - Container `metrics`: container that runs a service specialized in getting statistics from the Redis server in a format that Prometheus can read.
                - The Docker `image` is an Alpine Linux variant of [the 1.32 version of this exporter](https://hub.docker.com/r/oliver006/redis_exporter).
                - By default it tries to connect to `redis://localhost:6379`, which fits the configuration applied to the Redis service.
                - In the `env` section, the Redis password is set so the exporter can authenticate in the Redis server.
                - It also has limited RAM `resources` and its `containerPort` matches the one specified in the template's `metadata.annotations`.

        - `spec.volumes`: here only the `redis.conf` item, taken from a yet-to-be-defined `cache-redis` configmap object, is declared as a volume so it can be mounted by the `server` container, under its `volumeMounts` section.
          - Notice here the `defaultMode` parameter, which sets to the items contained in the specified configMap a particular permission mode by default. In this case, it sets a read-only permission for all users with mode `0444` but only for the `items` listed below it (the `redis.conf` file in this case).
          - Know that, in the items list, the `key` parameter is the name identifying the file inside the config map, and the `path` is the relative filename given to the item as volume.

        - `spec.affinity`: the `requiredDuringSchedulingIgnoredDuringExecution` affinity rule will make the Redis pod scheduled in the same node where a pod labeled with `app: server-nextcloud` is also created. This implies that the containers of the Redis pod won't be instanced until that other pod appears in the cluster. On the other hand, the Redis pod's containers won't be stopped when the pod they have the affinity with dissapears from the cluster.

## Redis Service resource

You have defined the pod that will execute the containers running the Redis server and its Prometheus statistics exporter, now you need to define the `Service` resource that will give access to them.

1. Generate a new file named `cache-redis.service.yaml`, also under the `resources` subfolder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/cache-redis/resources/cache-redis.service.yaml
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
      clusterIP: 10.43.100.1
      ports:
      - port: 6379
        protocol: TCP
        name: server
      - port: 9121
        protocol: TCP
        name: metrics
    ~~~

    The Service resource defines how to access the Redis pod services.

    - `metadata.annotations`: two annotations required for the Prometheus data scraping service (you'll see how to deploy Prometheus in a later guide).These annotations inform Prometheus about which port to scrape for getting metrics of your Redis service, which is data provided by the specialized metrics service that runs in the second container of the Redis pod.

    - `spec.type`: by default, any `Service` resource is of type `ClusterIP`, meaning that the service is only reachable from within the cluster's internal network. You can omit this parameter altogether from the yaml when you're using the default type.

    - `spec.clusterIP`: where you put the chosen static cluster IP for this service.

    - `spec.ports`: describe the ports open in this service. Notice how I made the `name` and `port` on each port of this `Service` to be the same as the ones already defined for the containers in the previous `Deployment` resource.

## Redis Kustomize project

What remains to setup is the main `kustomization.yaml` file that describes the whole Redis Kustomize project.

1. In the main `cache-redis` folder, create a `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/cache-redis/kustomization.yaml
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

    This `kustomization.yaml` file has elements you've already seen in previous deployments, plus a few extra ones.

    - With the `commonLabels` you can set up labels to all the resources generated from this `kustomization.yaml` file. In this case the label is `app: cache-redis`.

    - The `replicas` section allows you to handle the number of replicas you want for deployments, overriding whatever number already set in their base definition. In this case you only have one deployment listed, and the value put here is the same as the one set in the `cache-redis` deployment definition.

    - The `images` block gives you a handy way of changing the images specified within deployments, particularly useful for when you want to upgrade to newer versions.

    - There are two details to notice about the `configMapGenerator` and `secretGenerator`:
      - In the `cache-redis`'s definition, the file `secrets/redis.pwd` is renamed to `redis-password`, which is the key expected within the `cache-redis` deployment definition.
      - None of these generator blocks have the `disableNameSuffixHash` option enabled, because the name of the resources they generate is only used in standard Kubernetes parameters that are recognized by Kustomize.

### _Validating the Kustomize yaml output_

With everything in place, you can check out the yaml resulting from the Redis' Kustomize project.

1. Execute the `kubectl kustomize` command on the Redis Kustomize project's root folder, piped to `less` to get the output paginated.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/cache-redis | less
    ~~~

    Alternatively, you could just dump the yaml output on a file, called `cache-redis.k.output.yaml` for instance.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/cache-redis > cache-redis.k.output.yaml
    ~~~

2. The resulting yaml should look like the one next.

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
        WTB1cl9yRTNlNDFMeS5sYWzDsWpmbMOxa2FlcnV0YW9uZ3ZvYW46YcOxb2RrbzM0OTQ4dX
        lPbmctUzNrcmVUX1A0czV3b1JkLWhlUkUhCg==
    kind: Secret
    metadata:
      labels:
        app: cache-redis
      name: cache-redis-bh9d296g5k
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
      clusterIP: 10.43.100.1
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
                    - server-nextcloud
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
                  name: cache-redis-bh9d296g5k
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
                  name: cache-redis-bh9d296g5k
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

    A few things to highlight in the yaml output above.
    - You might have noticed this in the previous Kustomize projects you've deployed before, but the generated yaml output has the parameters within each resource sorted alphabetically. Be aware of this when you compare this output with the files you created and your expected results.

    - The names of the `cache-redis` config map and `cache-redis` secret have a hash as a suffix, added by Kustomize. The hash is calculated from the content of the renamed resources.

    - Another detail to notice is how the label `app: cache-redis` appears not only as label in the `metadata` section of all the resources, but Kustomize has also set it as `selector` both in the `Service` and the `Deployment` resources definitions.

    - There's also a particularity that might seem odd. The `defaultMode` of the `redis-config` volume is shown as `292` instead of the `0444` value you set in the Deployment resource definition. It's not a mistake, just a particularity of the Kustomize generation. The file will have the permission mode set as it is specified in the original `Deployment` resource.

3. On the other hand, if you installed the `kubeval` command in your kubectl client system (as explained in the [G026 guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md)), you can validate the Kustomize output with it. So, assuming you have dumped the output in a `cache-redis.k.output.yaml` file, you can execute the following.

    ~~~bash
    $ kubeval cache-redis.k.output.yaml 
    PASS - cache-redis.kustomize.output.yaml contains a valid ConfigMap (cache-redis)
    PASS - cache-redis.kustomize.output.yaml contains a valid Secret (cache-redis)
    PASS - cache-redis.kustomize.output.yaml contains a valid Service (cache-redis)
    PASS - cache-redis.kustomize.output.yaml contains a valid Deployment (cache-redis)
    ~~~

    At this `kubeval`'s output, you can see that prints one line per validated resource and, in this case, all of them `PASS` as valid resources.

## Don't deploy this Redis project on its own

Although you technically can deploy this Redis Kustomize project, wait until you have all the components and the main Nextcloud project ready. Then, you'll deploy the whole lot at once with just one `kubectl` command.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud`
- `$HOME/k8sprjs/nextcloud/components`
- `$HOME/k8sprjs/nextcloud/components/cache-redis`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/configs`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/resources`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/secrets`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/cache-redis/kustomization.yaml`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/configs/redis.conf`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/resources/cache-redis.deployment.yaml`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/resources/cache-redis.service.yaml`
- `$HOME/k8sprjs/nextcloud/components/cache-redis/secrets/redis.pwd`

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

[<< Previous (**G033. Deploying services 02. Nextcloud Part 1**)](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Nextcloud Part 3**) >>](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md)
