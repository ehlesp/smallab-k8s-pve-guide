# G033 - Deploying services 02 ~ Ghost - Part 2 - Valkey cache server

- [You can use Valkey instead of Redis as caching server for Ghost](#you-can-use-valkey-instead-of-redis-as-caching-server-for-ghost)
- [Kustomize project folders for Ghost and Valkey](#kustomize-project-folders-for-ghost-and-valkey)
- [Valkey configuration file](#valkey-configuration-file)
- [Valkey secrets](#valkey-secrets)
  - [Valkey ACL user list](#valkey-acl-user-list)
  - [User for Prometheus metrics exporter](#user-for-prometheus-metrics-exporter)
- [Valkey storage](#valkey-storage)
- [Valkey StatefulSet resource](#valkey-statefulset-resource)
- [Valkey Service resource](#valkey-service-resource)
- [Valkey Kustomize project](#valkey-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Valkey project on its own](#do-not-deploy-this-valkey-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Valkey](#valkey)
    - [Articles about Valkey](#articles-about-valkey)
  - [Redis](#redis)
    - [Articles about Redis](#articles-about-redis)
  - [Kubernetes](#kubernetes)
    - [Concepts](#concepts)
    - [Tasks](#tasks)
    - [Tutorials](#tutorials)
    - [Reference. Kubernetes API](#reference-kubernetes-api)
    - [Articles about services](#articles-about-services)
    - [Articles about pod scheduling](#articles-about-pod-scheduling)
    - [Articles about container ports](#articles-about-container-ports)
    - [Articles about ConfigMaps and Secrets](#articles-about-configmaps-and-secrets)
    - [Articles about CPU requests and limits](#articles-about-cpu-requests-and-limits)
- [Navigation](#navigation)

## You can use Valkey instead of Redis as caching server for Ghost

This second part of the Ghost deployment procedure is where you begin working with the Kustomize project for the whole platform's setup. In particular, you will start by preparing the Kustomize subproject of the caching server for Ghost. The official Ghost documentation mentions [Redis](https://redis.io/), but it is possible to use [Valkey](https://valkey.io/) instead.

## Kustomize project folders for Ghost and Valkey

You need a main Kustomize project for the deployment of your Ghost platform. In it, you will contain the subprojects for components like Valkey. Start by executing the following `mkdir` command to create the necessary project folder structure for this part:

~~~sh
$ mkdir -p $HOME/k8sprjs/ghost/components/cache-valkey/{configs,resources,secrets}
~~~

The main folder for the Valkey Kustomize subproject, `cache-valkey`, is named following the pattern `<component function>-<software name>` this guide will use also to name the root directories for the remaining component subprojects. There are also a `configs`, a `resources` and a `secrets` subfolders to better differentiate the files declaring the Kubernetes resources from those related to configurations or secret.

## Valkey configuration file

You need to fit Valkey to your needs, and the best way is by setting its parameters in a configuration file:

1. In the `configs` subfolder of the Valkey project, create a `valkey.conf` file:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/configs/valkey.conf
    ~~~

    The name `valkey.conf` is the default one for the Valkey configuration file.

2. Enter the custom configuration for Valkey in the `configs/valkey.conf` file:

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

    The parameters above mean the following:

    - `bind`\
      To make the Valkey server listen in specific interfaces. With `0.0.0.0` it listens to all available ones.

      > [!NOTE]
      > **Do not specify here the cluster IP you chose for the Valkey service**\
      > It is better to leave this parameter with a "flexible" value to avoid worrying about putting a particular IP in several places.

    - `protected-mode`\
      Security option for restricting Valkey from listening in interfaces other than localhost. Enabled by default, is disabled with value `no` so Valkey can listen through the interface that will have the service cluster IP assigned.

    - `port`\
      The default Valkey port is `6379`, specified here just for clarity.

    - `maxmemory`\
      Limits the memory used by the Valkey server. When the limit is reached, it'll try to remove keys accordingly to the eviction policy set in the `maxmemmory-policy` parameter.

    - `maxmemory-policy`\
      Policy for evicting keys from memory when the `maxmemory` limit is reached. Here is set to `allkeys-lru` so it can remove any key accordingly to an LRU (Least Recently Used) algorithm.

    - `aclfile`\
      Path to the file containing the Access Control List (ACL) specifying the users authorized to use this Valkey instance. The path specified is the default one, but it is specified here as a reminder of where it is.

      [This ACL file is specified in the next section](#valkey-acl-user-list).

    - `dir`\
      This is the working directory of Valkey where it stores its own database and logs (when configured to be stored). The `/data` path is the one alredy set in the container image of Valkey, so it is specified here as a reminder of where this working directory is.

    > [!NOTE]
    > **The Valkey configuration parameters are described in the official example configuration file**\
    > Each Valkey release has its own example `valkey.conf` file, and [the version this guide deploys is the 9.0 one](https://raw.githubusercontent.com/valkey-io/valkey/9.0/valkey.conf).

## Valkey secrets

To secure the access to this Valkey instance you need to create a couple of users that have to be stored as secret resources in your Kubernetes cluster.

> [!NOTE]
> **Your K3s Kubernetes cluster encrypts secrets automatically**\
> Remember that [your K3s cluster's server node has the option for encrypting secrets at rest(`secrets-encryption`) enabled already](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file), avoiding having them stored as clear text within the cluster.

### Valkey ACL user list

Valkey comes with a `default` user that you could use, but it is better to declare one more specific for Ghost. Since [Valkey supports Access Control Lists](https://valkey.io/topics/acl/), you can declare the users you need in an ACL file:

1. Create a new `users.acl` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/secrets/users.acl
    ~~~

2. In `secrets/users.acl` enter the ACL rules redefining the `default` user and specifiying the user for Ghost:

    ~~~acl
    user default on ~* &* +@all >P4s5W0rd_FOr_7h3_DeF4u1t_uSEr
    user ghostcache on ~ghost:* &* allcommands >pAS2wORT_f0r_T#e_Gh05T_Us3R
    ~~~

    Each rule declared above have a different purpose in this setup:

    - `user default`\
      Valkey's `default` user comes enabled with no password by default:

      - `on`\
        Enables the `default` user to allow authenticating with it in the Valkey instance. This user will be used by the Prometheus metrics exporter module that will run in the same pod together with your Valkey instance.

      - `~*`\
        Indicates that this `default` user can access all the keys stored in the Valkey instance.

      - `&*`\
        Allows the `default` user to access all channels existing in the Valkey instance.

      - `+@all`\
        Enables the `default` user to use all commands.

      - `>P4s5W0rd_FOr_7h3_DeF4u1t_uSEr`\
        A clear string specifying the password for the `default` user. This user does not have a password by default, so it is better to harden it with one.

        Also notice the initial `>` character: **it is not part of the password string**, is just the indication that the string is the user's password in the rule.

    - `user ghostcache`\
      Declares a specific `ghostcache` user meant only for the Ghost platform:

      - `on`\
        Enables the `ghostcache` user for authentication in the Valkey instance.

      - `~ghost:*`\
        Restricts what keys the `ghostcache` user can access to only those having the `ghost:` prefix.

      - `&*`\
        Allows the `ghostcache` user to access all channels existing in the Valkey instance.

      - `allcommands`\
        Alias for the `+@all` option. Enables the `ghostcache` user to use all commands.

      - `>pAS2wORT_f0r_T#e_Gh05T_Us3R`\
        A clear string specifying the password for the `ghostcache` user. **Remember that the initial `>` character is not part of the password**, it is just indicating that the following string is the user's password within the rule.

    > [!WARNING]
    > **The passwords in this `secrets/users.acl` file are plain unencrypted strings**\
    > Be careful of who can access this `users.acl` file.

### User for Prometheus metrics exporter

Running in the same pod as the Valkey server, there is going to be a Prometheus metrics exporter module that will use the `default` Valkey user to access the metrics from the Valkey instance. The problem is that you have to duplicate the default user's information to make it available for this exporter module as environment variables:

1. Create a `default_user_env.properties` under the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/secrets/default_user_env.properties
    ~~~

2. Enter the `default` user's name and password in the `secrets/default_user_env.properties` as environment variables:

    ~~~properties
    REDIS_USER=default
    REDIS_PASSWORD=P4s5W0rd_FOr_7h3_DeF4u1t_uSEr
    ~~~

    This file declares two environment variables that the Prometheus metrics exporter module recognizes:

    - `REDIS_USER`\
      The name of the user, in this case Valkey's `default` one.

    - `REDIS_PASSWORD`\
      The user's password string, in this case it must be the same one previously specified for the `default` user in the ACL file.

    > [!WARNING]
    > **The password in this `secrets/default_user_env.properties` file is a plain unencrypted string**\
    > Be careful of who can access this `default_user_env.properties` file.

## Valkey storage

Storage in Kubernetes has two sides: enabling storage as persistent volumes (PVs), and the claims (PVCs) on each of those persistent volumes. For your Ghost's Valkey instance you need one persistent volume (to be declared in the last part of this Ghost deployment procedure), and the claim on that particular PV. See next how to declare the `PersistentVolumeClaim` resource for your Valkey instance:

1. A persistent volume claim is a resource, so create a `db-mariadb.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.persistentvolumeclaim.yaml
    ~~~

2. Declare Seafile's `PersistentVolumeClaim` in the `resources/cache-valkey.persistentvolumeclaim.yaml` file:

    ~~~yaml

    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: cache-valkey
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: ghost-ssd-cache
      resources:
        requests:
          storage: 2.8G
    ~~~

    There are a few details to understand from the PVC above:

    - The `spec.accessModes` is specified. This is mandatory in a claim and it cannot demand a mode that is not enabled in the persistent volume (_PV_) itself.

    - The `spec.storageClassName` is a parameter that indicates what storage profile (a particular set of properties) to use with the PV. K3s comes with just the `local-path` included by default, something you can check out on your own K3s cluster with `kubectl`:

      ~~~sh
      $ kubectl get storageclass
      NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
      local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  63d
      ~~~

    - The `spec.volumeName` is the name of the persistent volume this claim binds itself to.

    - In a claim is also mandatory to specify how much storage is requested, hence the need to put the `spec.resources.requests.storage` parameter there. Be careful of not requesting more space than what is truly available in the volume.

    > [!IMPORTANT]
    > **The persistent volume and its claim must correlate**\
    > The persistent volume related to this PVC must correspond to the values set here.

## Valkey StatefulSet resource

The next thing to do is setting up the `StatefulSet` resource that will deploy Valkey in your K3s cluster. It has to be a `StatefulSet` rather than a `Deployment` because stateful sets are the resources meant for deploying in Kubernetes apps or services that persist data (their _state_) in a persistent storage. Valkey could be run purely on memory, but it would force it to repopulate its database every time, leading to some delay when booting up:

1. Create a `cache-valkey.statefulset.yaml` file under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` resource for the Valkey instance in `resources/cache-valkey.statefulset.yaml`:

    ~~~yaml
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
              defaultMode: 0444
              items:
              - key: valkey.conf
                path: valkey.conf
          - name: valkey-acl
            secret:
              secretName: cache-valkey-acl
              defaultMode: 0444
              items:
              - key: users.acl
                path: users.acl
    ~~~

    This `StatefulSet` resource describes the template for the pod that will contain the Valkey server and its Prometheus metrics exporter service, each running on their own containers:

    - `replicas`\
      Given the limitations of the cluster, only one replica of the Valkey pod is requested.

    - `serviceName`\
      Links the pod deployed by this `StatefulSet` to a headless `Service`.

      > [!IMPORTANT]
      > **The pod gets a predictable hostname within the cluster**\
      > Check out the [section about the corresponding `Service` resource](#valkey-service-resource) for more information. In particular, read about the `spec.clusterIP` parameter to understand how the pod's predictable hostname looks like.

    - `template`\
      Describes how the pod resulting from this `StatefulSet` should be:

      - `spec.containers`\
        This pod template has two containers running in it, arranged in what is known as a _sidecar_ pattern:

        - Container `server`\
          Container that runs the Valkey server itself:

          - The container `image` used is the Alpine Linux variant of [the most recent 9.0 version](https://hub.docker.com/r/valkey/valkey).

          - In the `command` section you can see how the configuration file path is directly specified to the service.

          - The `containerPort` is the same as the `port` set in the `valkey.conf` file. It has a `name` that allows invoking this port by name rather than by port number directly.

          - The `resources.requests` declares a minimum requirement of CPU and memory resources to grant to the container when it starts. If the container needs more resources, the Kubernetes control plane will take care of assign them if they are available.

          > [!NOTE]
          > **It is better to set minimum requirements, not upper limits**\
          > [According to this article](https://dev.to/naveens16/kubernetes-cpu-limits-the-silent-killer-of-performance-and-how-to-fix-it-20d1), setting upper usage limits affects negatively the performance of apps or services and leads to a waste of unused resources. It is better to leave the Kubernetes control plane to handle the bursts of activity that may happen in the cluster.

          - The `volumeMounts` indicate which volumes are to be mounted in the Valkey container:

            - `valkey-storage` enables the storage volume for Valkey's `/data` working directory.

            - `valkey-config` enables the volume containing Valkey's configuration file.

            - `valkey-acl` enables the file where the Valkey users are declared in an ACL.

            Notice how in the `valkey-config` and `valkey-acl` entries there is a `readOnly` option enabled to ensure those configuration files remain unchanged in the container.

        - Container `metrics`\
          Container that runs a service specialized in getting statistics from the Valkey server in a format that a Prometheus server can read:

          - The Docker `image` is an Alpine Linux variant of this exporter's [1.80 version](https://hub.docker.com/r/oliver006/redis_exporter).

          - By default, this exporter tries to connect to `redis://localhost:6379`, which fits the configuration applied to the Valkey service.

          - In the `envFrom` section, the `cache-valkey-exporter-user` `Secret` resource contains the `default_user_env.properties` file where the `default` username and password are declared for this Prometheus metrics exporter. [You will declare the `Secret` in the Kustomize declaration for this Ghost's Valkey subproject](#valkey-kustomize-project).

          - This container also has minimum requirements of RAM and CPU `resources`. Its `containerPort` has a `name` too, and its number is the one used by default by the exporter, matching the one you will see declared [in the next section within the corresponding Valkey's `Service` resource](#valkey-service-resource).

      - `spec.volumes`\
        This section declares the volumes that can be mounted in the pod. In particular, here are enabled all the volumes mounted in the Valkey container:

        - `cache-valkey-storage`\
          Invokes the `cache-valkey` `PersistentVolumeClaim` declared earlier for enabling the persistent storage that will contain Valkey's working data.

        - `valkey-config`\
          Enables the `valkey.conf` file that is kept in a yet-to-be-defined `cache-valkey-config` [`ConfigMap` object](https://kubernetes.io/docs/concepts/configuration/configmap/) as a volume so it can be mounted by the `server` container in its `volumeMounts` section.

        - `valkey-acl`\
          Enables the `users.acl` file being kept in a yet-to-be-defined `cache-valkey-acl` `Secret` object as a volume so it can be mounted by the `server` container in its `volumeMounts` section.

        Pay attention to the `defaultMode` parameter in the `valkey-config` and `valkey-acl` entries. It sets a particular permission mode by default for the items contained in them. In both cases, the parameter sets a read-only permission for all users with mode `0444` but only for the listed `items`.

        Also know that, in the items list, the `key` parameter is the name identifying the file present inside the `ConfigMap` or `Secret` object, and the `path` is the relative path assigned to the item.

## Valkey Service resource

You have declared the pod that will execute the containers running the Valkey server and its Prometheus statistics exporter, now you need to define the `Service` resource that will give access to them:

1. Generate a new file named `cache-valkey.service.yaml`, also under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.service.yaml
    ~~~

2. Declare the Valkey `Service` resource in `resources/cache-valkey.service.yaml`:

    ~~~yaml
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

    This `Service` resource specifies how to access the services running in the Valkey pod's containers:

    - `metadata.annotations`\
      Two annotations required for the Prometheus data scraping service (you will see how to deploy Prometheus in a later chapter).These annotations inform Prometheus about which port to scrape for getting metrics of your Valkey service, which is data provided by the specialized metrics service that runs in the `metrics` container of the Valkey pod.

    - `spec.type`\
      By default, any `Service` resource is of type `ClusterIP`, meaning that the service is only reachable from within the cluster's internal network. You can omit this parameter altogether from the YAML when you are using this default type.

    - `spec.clusterIP`\
      `StatefulSets` are limited to use [headless services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services), which are services with no **cluster** IP assigned (which explains the `None` value here). The Valkey service becomes reachable within the cluster through a predictable hostname granted by the DNS service (CoreDNS in your K3s cluster) already running in the Kubernetes cluster. This hostname is constructed following the following template:

      ~~~txt
      <service name>.<namespace>
      ~~~

      In the case of the Valkey service the hostname would be `cache-valkey.ghost`, and you will use it to make the Ghost platform connect with its Valkey instance.

    - `spec.ports`\
      Describe the ports open in this service. Notice how I made the `name` and `port` on each port of this `Service` to match the ones already defined for the containers in the previous `Deployment` resource.

      Also see how the `targetPort` parameters invoke the ports in the containers by name, not by number. This technique allows you to change the port number in the containers without affecting this `Service` declaration.

## Valkey Kustomize project

What remains to declare is the main `kustomization.yaml` file that describes the whole Valkey Kustomize subproject:

1. In the main `cache-valkey` folder, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/kustomization.yaml
    ~~~

2. Enter the following `Kustomization` declaration in the `kustomization.yaml` file:

    ~~~yaml
    # Ghost Valkey setup
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

    This `kustomization.yaml` file has elements you've already seen in previous deployments, plus a few extra ones:

    - With `labels` you can set up [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to all the resources generated from this `kustomization.yaml` file. In this case, there is only one label `app: cache-valkey` to indicate that the resources declared in this Kustomize project belong to the Valkey caching server.

      The `includeSelectors` and `includeTemplates` are parameters for controlling if the labels must be also included within the `spec.selector` and `spec.template` blocks of resource declarations such as the `Deployment` one you have for your Valkey server.

    - The `replicas` section allows you to handle the number of replicas you want for deployments, overriding whatever number is already set in their base declaration. In this case you only have one deployment listed, and the value put here is the same as the one set in the `cache-valkey` deployment definition.

    - The `images` block gives you a handy way of changing the images specified within the `StatefulSet` resource, particularly useful for when you want to upgrade to newer minor versions without changing anything else from the deployment declaration.

    - There are two details to notice about the `configMapGenerator` and `secretGenerator`:

      - The `cache-valkey-exporter-user` turns the values declared in the `secrets/default_user_env.properties` into environment variables that can be loaded in any container that invokes this secret.

      - None of these generator blocks have the `disableNameSuffixHash` option enabled, because the name of the resources they generate is only used in standard Kubernetes parameters that are recognized by Kustomize.

### Validating the Kustomize YAML output

With everything in place, you can check out the YAML resulting from the Seafile Valkey' Kustomize subproject:

1. Execute the `kubectl kustomize` command on the Valkey Kustomize subproject's root folder, piped to `less` to get the output paginated:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/ghost/components/cache-valkey | less
    ~~~

    Alternatively, you could just dump the YAML output on a file, called `cache-valkey.k.output.yaml` for instance.

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/ghost/components/cache-valkey > cache-valkey.k.output.yaml
    ~~~

2. The resulting YAML should look like this one:

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
        RfdVNFcgp1c2VyIGdob3N0Y2FjaGUgb24gfmdob3N0OiogJiogYWxsY29tbWFuZHMgPnBB
        UzJ3T1JUX2Ywcl9UI2VfR2gwNVRfVXMzUg==
    kind: Secret
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-acl-bcc5gh9d6g
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
      volumeName: ghost-ssd-cache
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
              defaultMode: 292
              items:
              - key: valkey.conf
                path: valkey.conf
              name: cache-valkey-config-c86dc4fh5d
            name: valkey-config
          - name: valkey-acl
            secret:
              defaultMode: 292
              items:
              - key: users.acl
                path: users.acl
              secretName: cache-valkey-acl-bcc5gh9d6g
    ~~~

    There are a few things to highlight in the YAML output above:

    - You might have noticed this in the previous Kustomize projects you have deployed before, but the generated YAML output has the parameters within each resource sorted alphabetically. Be aware of this when you compare this output with the files you created and your expected results.

    - The names of the `cache-valkey-config` config map, `cache-valkey-acl` and `cache-valkey-exporter-user` secrets have a hash as a suffix, added by Kustomize. The hash is calculated from the content of the renamed resources.

    - Both `cache-valkey-exporter-user` and `cache-valkey-acl` secrets are printed obfuscated in base64 format, but in different ways:

      - Since the `cache-valkey-exporter-user` secret is a set of environment variables, only their values are obfuscated.

      - The `cache-valkey-acl` secret is declared as a file, so its whole content is printed obfuscated.

    - Another detail to notice is how the label `app: cache-valkey` appears not only as label in the `metadata` section of all the resources, but Kustomize has also set it as `selector` both in the `Service` and the `StatefulSet` resources declarations.

    - There's also a particularity that might seem odd. The `defaultMode` of the `valkey-config` and `valkey-acl` volumes is shown as `292` instead of the `0444` value set in the `StatefulSet` resource declaration. It is not a mistake, just the way the permission value is translated into Kubernetes. The file will have the permission mode set as it is specified in the original `Deployment` resource.

3. If you installed the `kubeconform` command in your `kubectl` client system (as explained in the [G026 guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#validate-kubernetes-configuration-files-with-kubeconform)), you can validate the Kustomize output with it. So, assuming you have dumped the output in a `cache-valkey.k.output.yaml` file, execute the following:

    ~~~sh
    $ kubeconform -summary cache-valkey.k.output.yaml 
    Summary: 6 resources found in 1 file - Valid: 6, Invalid: 0, Errors: 0, Skipped: 0
    ~~~

    Notice the `-summary` option in the shell command above. It is what makes the `kubeconform` command print a results summary when it finishes.

    > [!NOTE]
    > **`kubeconform` does not produce an output when the input is valid**\
    > With a completely valid input as in this case and no option specified, `kubeconform` does not print anything in the shell.
    >
    > On the other hand, `kubeconform` (at least, in the version `0.7.0` installed with this guide) is not yet able to understand Kustomize projects and ends up finding errors in them.

## Do not deploy this Valkey project on its own

This Valkey setup is missing one critical element, the persistent volume it needs to store its working directory data. Do not confuse it with the claim you have configured for your Valkey cache server. That PV and other elements will be declared in the main Kustomize project you will declare in the final part of this Ghost deployment procedure. Until then, do not deploy this Valkey subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/ghost`
- `$HOME/k8sprjs/ghost/components`
- `$HOME/k8sprjs/ghost/components/cache-valkey`
- `$HOME/k8sprjs/ghost/components/cache-valkey/configs`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources`
- `$HOME/k8sprjs/ghost/components/cache-valkey/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/cache-valkey/kustomization.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/configs/valkey.conf`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.service.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.statefulset.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/secrets/default_user_env.properties`
- `$HOME/k8sprjs/ghost/components/cache-valkey/secrets/users.acl`

## References

### [Valkey](https://valkey.io/)

- [Documentation by Topic](https://valkey.io/topics/)
  - [The Valkey server](https://valkey.io/topics/server/)
  - [ACL](https://valkey.io/topics/acl/)
  - [Cluster tutorial](https://valkey.io/topics/cluster-tutorial/)

- [Docker Hub. Valkey](https://hub.docker.com/r/valkey/valkey)
- [Docker Hub. Prometheus Valkey & Redis Metrics Exporter](https://hub.docker.com/r/oliver006/redis_exporter)

- [GitHub. Example `valkey.conf` for Valkey 9.0](https://raw.githubusercontent.com/valkey-io/valkey/9.0/valkey.conf)

#### Articles about Valkey

- [XDA Developers. I set up a Valkey Cache with Nextcloud, and it fixed my biggest complaint](https://www.xda-developers.com/set-up-valkey-cache-with-nextcloud-it-fixed-my-biggest-complaint/)

### [Redis](https://redis.io/)

- [Redis FAQ](https://redis.io/topics/faq)
- [Redis administration](https://redis.io/topics/admin)

#### Articles about Redis

- [rpi4cluster. K3s Kubernetes Redis](https://rpi4cluster.com/k3s-redis/)
- [Medium. Simple Redis Cache on Kubernetes with Prometheus Metrics](https://itnext.io/simple-Redis-cache-on-kubernetes-with-prometheus-metrics-8667baceab6b)
- [Medium. Deploy and Operate a Redis Cluster in Kubernetes](https://marklu-sf.medium.com/deploy-and-operate-a-redis-cluster-in-kubernetes-94fde7853001)
- [Suse Rancher Blog. Deploying Redis Cluster on Top of Kubernetes](https://www.suse.com/c/rancher_blog/deploying-redis-cluster-on-top-of-kubernetes/)
- [StackOverflow. Redis sentinel vs clustering](https://stackoverflow.com/questions/31143072/redis-sentinel-vs-clustering)

### [Kubernetes](https://kubernetes.io/docs/)

#### [Concepts](https://kubernetes.io/docs/concepts/)

- [Overview. Objects in Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
  - [Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

- [Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/)
  - [Service. Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)

- [Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Scheduling, Preemption and Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/)
  - [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

#### [Tasks](https://kubernetes.io/docs/tasks/)

- [Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Assign Pods to Nodes using Node Affinity](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

- [Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

#### [Tutorials](https://kubernetes.io/docs/tutorials/)

- [Configuration](https://kubernetes.io/docs/tutorials/configuration/)
  - [Configuring Redis using a ConfigMap](https://kubernetes.io/docs/tutorials/configuration/configure-redis-using-configmap/)

#### [Reference. Kubernetes API](https://kubernetes.io/docs/reference/kubernetes-api/)

- [Workload Resources](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/)
  - [Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
    - [Scheduling](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#scheduling)

#### Articles about services

- [GeeksForGeeks. Kubernetes Headless Service](https://www.geeksforgeeks.org/devops/kubernetes-headless-service/)

#### Articles about pod scheduling

- [TheNewStack. Strategies for Kubernetes Pod Placement and Scheduling](https://thenewstack.io/strategies-for-kubernetes-pod-placement-and-scheduling/)
- [TheNewStack. Implement Node and Pod Affinity/Anti-Affinity in Kubernetes: A Practical Example](https://thenewstack.io/implement-node-and-pod-affinity-anti-affinity-in-kubernetes-a-practical-example/)
- [TheNewStack. Tutorial: Apply the Sidecar Pattern to Deploy Redis in Kubernetes](https://thenewstack.io/tutorial-apply-the-sidecar-pattern-to-deploy-redis-in-kubernetes/)

#### Articles about container ports

- [StackOverflow. Is there any way to disable or increase port name length in Kubernetes?](https://stackoverflow.com/questions/73330773/is-there-any-way-to-disable-or-increase-port-name-length-in-kubernetes)

#### Articles about ConfigMaps and Secrets

- [Opensource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### Articles about CPU requests and limits

- [Baeldung. CPU Requests and Limits in Kubernetes](https://www.baeldung.com/ops/kubernetes-cpu-requests-limits)
- [DEV. Kubernetes CPU Limits: The Silent Killer of Performance (And How to Fix It)](https://dev.to/naveens16/kubernetes-cpu-limits-the-silent-killer-of-performance-and-how-to-fix-it-20d1)

## Navigation

[<< Previous (**G033. Deploying services 02. Ghost Part 1**)](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup,%20arranging%20storage%20and%20choosing%20service%20IPs.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Ghost Part 3**) >>](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md)
