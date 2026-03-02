# G034 - Deploying services 03 ~ Forgejo - Part 2 - Valkey cache server

- [Valkey can be the cache server of Forgejo](#valkey-can-be-the-cache-server-of-forgejo)
- [Kustomize project folders for Forgejo and Valkey](#kustomize-project-folders-for-forgejo-and-valkey)
- [Valkey configuration file](#valkey-configuration-file)
- [Valkey secrets](#valkey-secrets)
  - [Valkey ACL user list](#valkey-acl-user-list)
  - [User for Prometheus metrics exporter](#user-for-prometheus-metrics-exporter)
- [Valkey persistent storage claim](#valkey-persistent-storage-claim)
- [Valkey StatefulSet](#valkey-statefulset)
- [Valkey Service](#valkey-service)
  - [Valkey Service's FQDN](#valkey-services-fqdn)
- [Valkey Kustomize project](#valkey-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Valkey project on its own](#do-not-deploy-this-valkey-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Valkey](#valkey)
  - [Redis](#redis)
    - [Other Redis-related contents](#other-redis-related-contents)
  - [Kubernetes](#kubernetes)
    - [Pods and containers](#pods-and-containers)
    - [ConfigMaps](#configmaps)
    - [Labels](#labels)
    - [Services](#services)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
    - [About services](#about-services)
    - [About pod scheduling](#about-pod-scheduling)
    - [About port names](#about-port-names)
    - [About ConfigMaps and Secrets](#about-configmaps-and-secrets)
    - [About CPU requests and limits](#about-cpu-requests-and-limits)
- [Navigation](#navigation)

## Valkey can be the cache server of Forgejo

Like with the Ghost platform, you can improve Forgejo's performance by setting up Valkey as its caching server. Furthermore, deploying Valkey in the Forgejo setup is done like you did [for the Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md).

## Kustomize project folders for Forgejo and Valkey

First, you have to create a folder for your Forgejo's main Kustomize project and, within it, a directory tree for the Valkey subproject. You can do this with just one `mkdir` command:

~~~sh
$ mkdir -p $HOME/k8sprjs/forgejo/components/cache-valkey/{configs,resources,secrets}
~~~

## Valkey configuration file

Prepare the `valkey.conf` file specifying the configuration values for your Forgejo's Valkey server:

1. In the `configs` subfolder of the Valkey project, create a `valkey.conf` file:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/configs/valkey.conf
    ~~~

2. Copy in `valkey.conf` the lines below:

    ~~~properties
    # Custom Valkey configuration
    bind 0.0.0.0
    protected-mode no
    port 6379
    maxmemory 64mb
    maxmemory-policy allkeys-lru
    aclfile /etc/valkey/users.acl
    dir /data
    ~~~

    The parameters are exactly the same ones set up in the [part 2 of the Ghost deployment procedure](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-configuration-file).

## Valkey secrets

As in the Ghost case, securing the access to this Valkey instance requires setting up two users stored in a secret resource within your Kubernetes cluster.

> [!NOTE]
> **Your K3s Kubernetes cluster encrypts secrets automatically**\
> Remember that [your K3s cluster's server node has the option for encrypting secrets at rest(`secrets-encryption`) enabled already](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file), avoiding having them stored as clear text within the cluster.

### Valkey ACL user list

The [Access Control List](https://valkey.io/topics/acl/) declared here configures the `default` user and one specific for Forgejo:

1. Create a new `users.acl` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/secrets/users.acl
    ~~~

2. In `secrets/users.acl` enter the ACL rules redefining the `default` user and specifying the user for Forgejo:

    ~~~acl
    user default on ~* &* +@all >P4s5W0rd_FOr_7h3_DeF4u1t_uSEr
    user forgejocache on ~forgejo:* &* allcommands >pAS2wOrD_f0r_The_F0rgEJ0_Us3R
    ~~~

    > [!WARNING]
    > **The passwords in this `secrets/users.acl` file are plain unencrypted strings**\
    > Be careful of who can access this `users.acl` file.

### User for Prometheus metrics exporter

The Valkey instance for Forgejo will have its own Prometheus metrics exporter module. This module uses the `default` Valkey user to access the metrics from the Valkey instance. [As it happened in the Ghost's case](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#user-for-prometheus-metrics-exporter), you have to duplicate the default user's information to make it available as environment variables for this exporter module:

1. Create a `default_user_env.properties` under the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/secrets/default_user_env.properties
    ~~~

2. Enter the `default` user's name and password in `secrets/default_user_env.properties` as environment variables:

    ~~~properties
    REDIS_USER=default
    REDIS_PASSWORD=P4s5W0rd_FOr_7h3_DeF4u1t_uSEr
    ~~~

    > [!WARNING]
    > **The password in this `secrets/default_user_env.properties` file is a plain unencrypted string**\
    > Be careful of who can access this `default_user_env.properties` file.

## Valkey persistent storage claim

To link Forgejo's Valkey instance with the persistent volume that will be declared in the last part of this procedure, you need to declare a `PersistentVolumeClaim` resource:

1. Create a `cache-valkey.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.persistentvolumeclaim.yaml
    ~~~

2. Declare Valkey's `PersistentVolumeClaim` in the `resources/cache-valkey.persistentvolumeclaim.yaml` file:

    ~~~yaml
    # Forgejo Valkey claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: cache-valkey
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: forgejo-ssd-cache
      resources:
        requests:
          storage: 2.8G
    ~~~

## Valkey StatefulSet

Since Forgejo's Valkey instance stores state, it has to be deployed with a `StatefulSet`:

1. Create a `cache-valkey.statefulset.yaml` file under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` resource for the Valkey instance in `resources/cache-valkey.statefulset.yaml`:

    ~~~yaml
    # Forgejo Valkey StatefulSet for a sidecar server pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: cache-valkey
    spec:
      replicas: 1
      serviceName: cache-valkey
      template:
        spec:
          containers:
          - name: server
            image: valkey/valkey:9.0-alpine
            command:
            - valkey-server
            - "/etc/valkey/valkey.conf"
            ports:
            - name: server
              containerPort: 6379
            resources:
              requests:
                cpu: "0.5"
                memory: 64Mi
            volumeMounts:
            - name: valkey-storage
              mountPath: /data
            - name: valkey-config
              readOnly: true
              subPath: valkey.conf
              mountPath: /etc/valkey/valkey.conf
            - name: valkey-acl
              readOnly: true
              subPath: users.acl
              mountPath: /etc/valkey/users.acl
          - name: metrics
            image: oliver006/redis_exporter:v1.80.0-alpine
            envFrom:
            - secretRef:
                name: cache-valkey-exporter-user
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
            ports:
            - name: metrics
              containerPort: 9121
          volumes:
          - name: valkey-storage
            persistentVolumeClaim:
              claimName: cache-valkey
          - name: valkey-config
            configMap:
              name: cache-valkey-config
              defaultMode: 444
              items:
              - key: valkey.conf
                path: valkey.conf
          - name: valkey-acl
            secret:
              secretName: cache-valkey-acl
              defaultMode: 444
              items:
              - key: users.acl
                path: users.acl
    ~~~

    You may notice that this declaration is identical to [the `StatefulSet` resource declared for the Ghost's Valkey instance](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-statefulset). This is not going to be an issue since the whole Forgejo's setup will be deployed in its own distinct `forgejo` namespace in the final part of this deployment procedure.

## Valkey Service

Declare the `Service` object required for Forgejo's Valkey `StatefulSet` pod:

1. Generate a new file named `cache-valkey.service.yaml`, also under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.service.yaml
    ~~~

2. Declare the Valkey `Service` resource in `resources/cache-valkey.service.yaml`:

    ~~~yaml
    # Forgejo Valkey headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: cache-valkey
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9121"
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - port: 6379
        targetPort: server
        protocol: TCP
        name: server
      - port: 9121
        targetPort: metrics
        protocol: TCP
        name: metrics
    ~~~

    Again, this `Service` object is exactly [like the one declared for the Ghost Valkey instance](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service).

### Valkey Service's FQDN

Since the whole Forgejo setup will be deployed in the `forgejo` namespace, the absolute FQDN of the Valkey service is going to be this one:

~~~txt
cache-valkey.forgejo.svc.homelab.cluster.
~~~

## Valkey Kustomize project

Now declare the main `kustomization.yaml` file that describes the whole Forgejo's Valkey Kustomize subproject:

1. In the main `cache-valkey` folder, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/cache-valkey/kustomization.yaml
    ~~~

2. Enter the following `Kustomization` declaration in the `kustomization.yaml` file:

    ~~~yaml
    # Forgejo Valkey setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
    - pairs:
        app: cache-valkey
      includeSelectors: true
      includeTemplates: true

    resources:
    - resources/cache-valkey.persistentvolumeclaim.yaml
    - resources/cache-valkey.statefulset.yaml
    - resources/cache-valkey.service.yaml

    replicas:
    - name: cache-valkey
      count: 1

    images:
    - name: valkey/valkey
      newTag: 9.0-alpine
    - name: oliver006/redis_exporter
      newTag: v1.80.0-alpine

    configMapGenerator:
    - name: cache-valkey-config
      files:
      - configs/valkey.conf

    secretGenerator:
    - name: cache-valkey-exporter-user
      envs:
      - secrets/default_user_env.properties
    - name: cache-valkey-acl
      files:
      - secrets/users.acl
    ~~~

    This `kustomization.yaml` file is exactly the same as the one you declared for [Ghost's Valkey deployment](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-kustomize-project).

### Validating the Kustomize YAML output

With all the necessary resources declared for your Forgejo Valkey instance, review the YAML resulting from the Forgejo Valkey's Kustomize subproject:

1. Execute the `kubectl kustomize` command on the Forgejo Valkey Kustomize subproject's root folder, piped to `less` (or your text editor of choice) to get the output paginated:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/forgejo/components/cache-valkey | less
    ~~~

2. The resulting YAML should be like this one:

    ~~~yaml
    apiVersion: v1
    data:
      valkey.conf: |-
        # Custom Valkey configuration
        bind 0.0.0.0
        protected-mode no
        port 6379
        maxmemory 64mb
        maxmemory-policy allkeys-lru
        aclfile /etc/valkey/users.acl
        dir /data
    kind: ConfigMap
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-config-c86dc4fh5d
    ---
    apiVersion: v1
    data:
      users.acl: |
        dXNlciBkZWZhdWx0IG9uIH4qICYqICtAYWxsID5QNHM1VzByZF9GT3JfN2gzX0RlRjR1MX
        RfdVNFcgp1c2VyIGZvcmdlam9jYWNoZSBvbiB+Zm9yZ2VqbzoqICYqIGFsbGNvbW1hbmRz
        ID5wQVMyd09yRF9mMHJfVGhlX0YwcmdFSjBfVXMzUg==
    kind: Secret
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-acl-9d8g27k94b
    type: Opaque
    ---
    apiVersion: v1
    data:
      REDIS_PASSWORD: UDRzNVcwcmRfRk9yXzdoM19EZUY0dTF0X3VTRXI=
      REDIS_USER: ZGVmYXVsdA==
    kind: Secret
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-exporter-user-6mdd99ft8d
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9121"
        prometheus.io/scrape: "true"
      labels:
        app: cache-valkey
      name: cache-valkey
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 6379
        protocol: TCP
        targetPort: server
      - name: metrics
        port: 9121
        protocol: TCP
        targetPort: metrics
      selector:
        app: cache-valkey
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2.8G
      storageClassName: local-path
      volumeName: forgejo-ssd-cache
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: cache-valkey
      serviceName: cache-valkey
      template:
        metadata:
          labels:
            app: cache-valkey
        spec:
          containers:
          - command:
            - valkey-server
            - /etc/valkey/valkey.conf
            image: valkey/valkey:9.0-alpine
            name: server
            ports:
            - containerPort: 6379
              name: server
            resources:
              requests:
                cpu: "0.5"
                memory: 64Mi
            volumeMounts:
            - mountPath: /data
              name: valkey-storage
            - mountPath: /etc/valkey/valkey.conf
              name: valkey-config
              readOnly: true
              subPath: valkey.conf
            - mountPath: /etc/valkey/users.acl
              name: valkey-acl
              readOnly: true
              subPath: users.acl
          - envFrom:
            - secretRef:
                name: cache-valkey-exporter-user-6mdd99ft8d
            image: oliver006/redis_exporter:v1.80.0-alpine
            name: metrics
            ports:
            - containerPort: 9121
              name: metrics
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
          volumes:
          - name: valkey-storage
            persistentVolumeClaim:
              claimName: cache-valkey
          - configMap:
              defaultMode: 444
              items:
              - key: valkey.conf
                path: valkey.conf
              name: cache-valkey-config-c86dc4fh5d
            name: valkey-config
          - name: valkey-acl
            secret:
              defaultMode: 444
              items:
              - key: users.acl
                path: users.acl
              secretName: cache-valkey-acl-9d8g27k94b
    ~~~

## Do not deploy this Valkey project on its own

This Valkey setup is missing one critical element, the persistent volume it needs to store its working directory data. Do not confuse it with the claim you have configured for your Valkey cache server. That persistent volume and other elements are going to be declared in the main Kustomize project you will declare in the final part of this Forgejo deployment procedure. Until then, do not deploy this Valkey subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/forgejo`
- `$HOME/k8sprjs/forgejo/components`
- `$HOME/k8sprjs/forgejo/components/cache-valkey`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/configs`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/resources`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/forgejo/components/cache-valkey/kustomization.yaml`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/configs/valkey.conf`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.service.yaml`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/resources/cache-valkey.statefulset.yaml`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/secrets/default_user_env.properties`
- `$HOME/k8sprjs/forgejo/components/cache-valkey/secrets/users.acl`

## References

### [Valkey](https://valkey.io/)

- [Documentation by Topic](https://valkey.io/topics/)
  - [The Valkey server](https://valkey.io/topics/server/)
  - [ACL](https://valkey.io/topics/acl/)
  - [Cluster tutorial](https://valkey.io/topics/cluster-tutorial/)

- [Docker Hub. Valkey](https://hub.docker.com/r/valkey/valkey)
- [Docker Hub. Prometheus Valkey & Redis Metrics Exporter](https://hub.docker.com/r/oliver006/redis_exporter)

- [GitHub. Valkey. Example `valkey.conf` for Valkey 9.0](https://raw.githubusercontent.com/valkey-io/valkey/9.0/valkey.conf)

### [Redis](https://redis.io/)

- [Docs](https://redis.io/docs/latest/)

#### Other Redis-related contents

- [rpi4cluster. K3s Kubernetes. Redis](https://rpi4cluster.com/k3s-redis/)
- [Daniel Cushing. Simple Redis Cache on Kubernetes with Prometheus Metrics](https://itnext.io/simple-Redis-cache-on-kubernetes-with-prometheus-metrics-8667baceab6b)
- [Mark Lu. Deploy and Operate a Redis Cluster in Kubernetes](https://marklu-sf.medium.com/deploy-and-operate-a-redis-cluster-in-kubernetes-94fde7853001)
- [Suse Rancher Blog. Deploying Redis Cluster on Top of Kubernetes](https://www.suse.com/c/rancher_blog/deploying-redis-cluster-on-top-of-kubernetes/)
- [StackOverflow. Redis sentinel vs clustering](https://stackoverflow.com/questions/31143072/redis-sentinel-vs-clustering)

### [Kubernetes](https://kubernetes.io/docs/)

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

#### Pods and containers

- [Kubernetes Documentation. Concepts. Scheduling, Preemption and Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/)
  - [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Assign Pods to Nodes using Node Affinity](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

- [Kubernetes Documentation. Reference. Kubernetes API. Workload Resources](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/)
  - [Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
    - [Scheduling](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#scheduling)

#### ConfigMaps

- [Kubernetes Documentation. Concepts. Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Kubernetes Documentation. Tutorials. Configuration](https://kubernetes.io/docs/tutorials/configuration/)
  - [Configuring Redis using a ConfigMap](https://kubernetes.io/docs/tutorials/configuration/configure-redis-using-configmap/)

#### Labels

- [Kubernetes Documentation. Concepts. Overview. Objects in Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
  - [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

#### Services

- [Kubernetes Documentation. Concepts. Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/)
  - [Service. Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

### Other Kubernetes-related contents

#### About services

- [GeeksForGeeks. Kubernetes Headless Service](https://www.geeksforgeeks.org/devops/kubernetes-headless-service/)

#### About pod scheduling

- [TheNewStack. Strategies for Kubernetes Pod Placement and Scheduling](https://thenewstack.io/strategies-for-kubernetes-pod-placement-and-scheduling/)
- [TheNewStack. Implement Node and Pod Affinity/Anti-Affinity in Kubernetes: A Practical Example](https://thenewstack.io/implement-node-and-pod-affinity-anti-affinity-in-kubernetes-a-practical-example/)
- [TheNewStack. Tutorial: Apply the Sidecar Pattern to Deploy Redis in Kubernetes](https://thenewstack.io/tutorial-apply-the-sidecar-pattern-to-deploy-redis-in-kubernetes/)

#### About port names

- [StackOverflow. Is there any way to disable or increase port name length in Kubernetes?](https://stackoverflow.com/questions/73330773/is-there-any-way-to-disable-or-increase-port-name-length-in-kubernetes)

#### About ConfigMaps and Secrets

- [Opensource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### About CPU requests and limits

- [Baeldung. CPU Requests and Limits in Kubernetes](https://www.baeldung.com/ops/kubernetes-cpu-requests-limits)
- [DEV. Kubernetes CPU Limits: The Silent Killer of Performance (And How to Fix It)](https://dev.to/naveens16/kubernetes-cpu-limits-the-silent-killer-of-performance-and-how-to-fix-it-20d1)

## Navigation

[<< Previous (**G034. Deploying services 03. Forgejo Part 1**)](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Forgejo Part 3**) >>](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md)
