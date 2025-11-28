# G033 - Deploying services 02 ~ Ghost - Part 2 - Valkey cache server

- [You can use Valkey instead of Redis as caching server for Ghost](#you-can-use-valkey-instead-of-redis-as-caching-server-for-ghost)
- [Kustomize project folders for Ghost and Valkey](#kustomize-project-folders-for-ghost-and-valkey)
- [Valkey configuration file](#valkey-configuration-file)
- [Valkey ACL user list](#valkey-acl-user-list)
- [Valkey StatefulSet resource](#valkey-statefulset-resource)
- [Valkey Service resource](#valkey-service-resource)
- [Valkey Kustomize project](#valkey-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Valkey project on its own](#do-not-deploy-this-valkey-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Kubernetes](#kubernetes)
    - [Concepts](#concepts)
    - [Tasks](#tasks)
    - [Tutorials](#tutorials)
    - [Reference. Kubernetes API](#reference-kubernetes-api)
    - [Articles about pod scheduling](#articles-about-pod-scheduling)
    - [Articles about ConfigMaps and Secrets](#articles-about-configmaps-and-secrets)
  - [Valkey](#valkey)
    - [Articles about Valkey](#articles-about-valkey)
  - [Redis](#redis)
    - [Articles about Redis](#articles-about-redis)
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

    > [!NOTE]
    > **The Valkey configuration parameters are described in the official example configuration file**\
    > Each Valkey release has its own example `valkey.conf` file, and [the version this guide deploys is the 9.0 one](https://raw.githubusercontent.com/valkey-io/valkey/9.0/valkey.conf).

## Valkey ACL user list

You need to secure the access to this Valkey instance. Valkey comes with a `default` user that you could use, but it is better to declare one more specific for Ghost. Since [Valkey supports Access Control Lists](https://valkey.io/topics/acl/), you can declare the users you need in an ACL file:

1. Create a new `users.acl` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/secrets/users.acl
    ~~~

2. In `secrets/users.acl` enter the ACL rules redefining the `default` user and specifiying the user for Ghost:

    ~~~acl
    user default off ~* &* +@all >P4s5W0rd_FOr_7h3_DeF4u1t_uSEr
    user ghostcache on ~ghost:* &* allcommands >pAS2wORT_f0r_T#e_Gh05T_Us3R
    ~~~

    Each rule declared above have a different purpose in this setup:

    - `user default`\
      Valkey's `default` user comes enabled with no password by default:

      - `off`\
        Disables the `default` user, making impossible to authenticate with it in the Valkey instance. This is because only the Ghost platform will access this Valkey instance and with its own specific user, not with this `default` one.

      - `~*`\
        Indicates that this `default` user can access all the keys stored in the Valkey instance.

      - `&*`\
        Allows the `default` user to access all channels existing in the Valkey instance.

      - `+@all`\
        Enables the `default` user to use all commands.

      - `>P4s5W0rd_FOr_7h3_DeF4u1t_uSEr`\
        A clear string declaring the password for the `default` user. Although this user is disabled, is convenient not leaving it without a password to harden its access in case the user gets reenabled in the future.

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
        A clear string declaring the password for the `default` user. **Remember that the initial `>` character is not part of the password**, it is just indicating that the following string is the user's password within the rule.

    > [!WARNING]
    > **The passwords in this `secrets/users.acl` file are plain unencrypted strings**\
    > Be careful of who can access this `users.acl` file.





## Valkey StatefulSet resource

The next thing to do is setting up the `StatefulSet` resource that will install Valkey in your K3s cluster:

1. Create a `cache-valkey.deployment.yaml` file under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.deployment.yaml
    ~~~

2. Declare the `Deployment` resource for Valkey in `resources/cache-valkey.deployment.yaml`:

    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment

    metadata:
      name: cache-valkey
    spec:
      replicas: 1
      template:
        spec:
          containers:
          - name: server
            image: valkey/valkey:9.0-alpine
            command:
            - valkey-server
            - "/etc/valkey/valkey.conf"
            - "--requirepass $(VALKEY_PASSWORD)"
            env:
            - name: VALKEY_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-valkey
                  key: valkey-password
            ports:
            - containerPort: 6379
            resources:
              limits:
                cpu: "0.5"
                memory: 64Mi
            volumeMounts:
            - name: valkey-config
              subPath: valkey.conf
              mountPath: /etc/valkey/valkey.conf
          - name: metrics
            image: oliver006/redis_exporter:v1.80.0-alpine
            env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-valkey
                  key: valkey-password
            resources:
              limits:
                cpu: "0.25"
                memory: 32Mi
            ports:
            - containerPort: 9121
          volumes:
          - name: valkey-config
            configMap:
              name: cache-valkey
              defaultMode: 0444
              items:
              - key: valkey.conf
                path: valkey.conf
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                    - key: app
                      operator: In
                      values:
                      - server-seafile
                  topologyKey: "kubernetes.io/hostname"
    ~~~

    This `Deployment` resource describes the template for the pod that will contain the Valkey server and its Prometheus metrics exporter service, running each on their own containers.

    - `replicas`\
      Given the limitations of the cluster, only one instance of the Valkey pod is requested.

    - `template`\
      Describes how the pod resulting from this `Deployment` should be.

      - `spec.containers`\
        This pod template has two containers running in it, arranged in what is known as a _sidecar_ pattern:

        - Container `server`\
          Container that runs the Valkey server itself:

          - The container `image` used is the Alpine Linux variant of [the most recent 9.0 version](https://hub.docker.com/r/valkey/valkey).

          - In the `command` section you can see how the configuration file path is directly specified to the service, and also how the Valkey password is obtained from a `cache-valkey` secret (which you will declare later), then turned into an environment variable (`env` section) to be passed to the `--requirepass` option.

          - The `containerPort` is the same as the `port` set in the `valkey.conf` file.

          - The container is set with a RAM and CPU usage limit in the `resources` section.

        - Container `metrics`\
          Container that runs a service specialized in getting statistics from the Valkey server in a format that a Prometheus server can read:

          - The Docker `image` is an Alpine Linux variant of [the 1.80 version of this exporter](https://hub.docker.com/r/oliver006/redis_exporter).

          - By default, this exporter tries to connect to `redis://localhost:6379`, which fits the configuration applied to the Valkey service.

          - In the `env` section, the Valkey password is set as the `REDIS_PASSWORD` environment parameter so the exporter can pick it from the pod's environment and authenticate with it in the Valkey server.

          - It also has limited RAM and CPU `resources`, and its `containerPort` is the one used by default by the exporter and also matches the one you will see declared [in the next section within the corresponding Valkey's `Service` resource](#valkey-service-resource).

      - `spec.volumes`\
        Here the `valkey.conf` item, taken from a yet-to-be-defined `cache-valkey` [ConfigMap object](https://kubernetes.io/docs/concepts/configuration/configmap/), is declared as a volume so it can be mounted by the `server` container, under its `volumeMounts` section.

        - Notice the `defaultMode` parameter here. It sets a particular permission mode by default for the items contained in the specified `configMap` block. In this case, it sets a read-only permission for all users with mode `0444` but only for the `items` listed below it (the `valkey.conf` file in this case).

        - Know that, in the items list, the `key` parameter is the name identifying the file present inside the `ConfigMap` object, and the `path` is the relative path assigned to the item.

      - `spec.affinity`\
        The `podAffinity.requiredDuringSchedulingIgnoredDuringExecution` affinity rule will make the Valkey pod scheduled in the same node where a pod labeled with `app: server-seafile` is also created.

        This implies that the containers of the Valkey pod will not be instanced until that other pod appears in the cluster. On the other hand, the Valkey pod's containers will not be stopped when the pod they have their affinity with disappears from the cluster.

## Valkey Service resource

You have defined the pod that will execute the containers running the Valkey server and its Prometheus statistics exporter, now you need to define the `Service` resource that will give access to them:

1. Generate a new file named `cache-valkey.service.yaml`, also under the `resources` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.service.yaml
    ~~~

2. Declare the Valkey `Service` resource in `cache-valkey.service.yaml`:

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
      clusterIP: 10.43.100.2
      ports:
      - port: 6379
        protocol: TCP
        name: server
      - port: 9121
        protocol: TCP
        name: metrics
    ~~~

    This `Service` resource specifies how to access the services running in the Valkey pod's containers:

    - `metadata.annotations`\
      Two annotations required for the Prometheus data scraping service (you will see how to deploy Prometheus in a later chapter).These annotations inform Prometheus about which port to scrape for getting metrics of your Valkey service, which is data provided by the specialized metrics service that runs in the `metrics` container of the Valkey pod.

    - `spec.type`\
      By default, any `Service` resource is of type `ClusterIP`, meaning that the service is only reachable from within the cluster's internal network. You can omit this parameter altogether from the yaml when you're using this default type, although it is better to leave it specified for clarity.

    - `spec.clusterIP`\
      Where you put the chosen static cluster IP for this service.

    - `spec.ports`\
      Describe the ports open in this service. Notice how I made the `name` and `port` on each port of this `Service` to be the same as the ones already defined for the containers in the previous `Deployment` resource.

## Valkey Kustomize project

What remains to setup is the main `kustomization.yaml` file that describes the whole Valkey Kustomize project.

1. In the main `cache-valkey` folder, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/cache-valkey/kustomization.yaml
    ~~~

2. Enter the following `Kustomization` declaration in the `kustomization.yaml` file:

    ~~~yaml
    # Seafile Valkey setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app: cache-valkey
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/cache-valkey.deployment.yaml
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
    - name: cache-valkey
      files:
      - configs/valkey.conf

    secretGenerator:
    - name: cache-valkey
      files:
      - valkey-password=secrets/valkey.pwd
    ~~~

    This `kustomization.yaml` file has elements you've already seen in previous deployments, plus a few extra ones:

    - With `labels` you can set up [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to all the resources generated from this `kustomization.yaml` file. In this case, there is only one label `app: cache-valkey` to indicate that the resources declared in this Kustomize project belong to the Valkey caching server.

      The `includeSelectors` and `includeTemplates` are parameters for controlling if the labels must be also included within the `spec.selector` and `spec.template` blocks of resource declarations such as the `Deployment` one you have for your Valkey server.

    - The `replicas` section allows you to handle the number of replicas you want for deployments, overriding whatever number is already set in their base declaration. In this case you only have one deployment listed, and the value put here is the same as the one set in the `cache-valkey` deployment definition.

    - The `images` block gives you a handy way of changing the images specified within deployments, particularly useful for when you want to upgrade to newer minor versions without changing anything else from the deployment declaration.

    - There are two details to notice about the `configMapGenerator` and `secretGenerator`:

      - In the `cache-valkey`'s definition, the file `secrets/valkey.pwd` is renamed to `valkey-password`, which is the key expected within the `cache-valkey` deployment definition.

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
    kind: ConfigMap
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-g48dg5ktt4
    ---
    apiVersion: v1
    data:
      valkey-password: |
        WTB1cl9yRTNlNDFMeS5sYWzDsWpmbMOxa2FlcnV0YW9uZ3ZvYW46YcOxb2RrbzM0OTQ4dX
        lPbmctUzNrcmVUX1A0czV3b1JkLWhlUkUhCg==
    kind: Secret
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey-5m6ckg5cd4
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
      clusterIP: 10.43.100.2
      ports:
      - name: server
        port: 6379
        protocol: TCP
      - name: metrics
        port: 9121
        protocol: TCP
      selector:
        app: cache-valkey
      type: ClusterIP
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: cache-valkey
      name: cache-valkey
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: cache-valkey
      template:
        metadata:
          labels:
            app: cache-valkey
        spec:
          affinity:
            podAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - server-seafile
                topologyKey: kubernetes.io/hostname
          containers:
          - command:
            - valkey-server
            - /etc/valkey/valkey.conf
            - --requirepass $(VALKEY_PASSWORD)
            env:
            - name: VALKEY_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: valkey-password
                  name: cache-valkey-5m6ckg5cd4
            image: valkey/valkey:9.0-alpine
            name: server
            ports:
            - containerPort: 6379
            resources:
              limits:
                cpu: "0.5"
                memory: 64Mi
            volumeMounts:
            - mountPath: /etc/valkey/valkey.conf
              name: valkey-config
              subPath: valkey.conf
          - env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: valkey-password
                  name: cache-valkey-5m6ckg5cd4
            image: oliver006/redis_exporter:v1.80.0-alpine
            name: metrics
            ports:
            - containerPort: 9121
            resources:
              limits:
                cpu: "0.25"
                memory: 32Mi
          volumes:
          - configMap:
              defaultMode: 292
              items:
              - key: valkey.conf
                path: valkey.conf
              name: cache-valkey-g48dg5ktt4
            name: valkey-config
    ~~~

    There are a few things to highlight in the YAML output above:

    - You might have noticed this in the previous Kustomize projects you have deployed before, but the generated YAML output has the parameters within each resource sorted alphabetically. Be aware of this when you compare this output with the files you created and your expected results.

    - The names of the `cache-valkey` config map and `cache-valkey` secret have a hash as a suffix, added by Kustomize. The hash is calculated from the content of the renamed resources.

    - Another detail to notice is how the label `app: cache-valkey` appears not only as label in the `metadata` section of all the resources, but Kustomize has also set it as `selector` both in the `Service` and the `Deployment` resources definitions.

    - There's also a particularity that might seem odd. The `defaultMode` of the `valkey-config` volume is shown as `292` instead of the `0444` value you set in the Deployment resource definition. It's not a mistake, just a particularity of the Kustomize generation. The file will have the permission mode set as it is specified in the original `Deployment` resource.

3. If you installed the `kubeconform` command in your `kubectl` client system (as explained in the [G026 guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#validate-kubernetes-configuration-files-with-kubeconform)), you can validate the Kustomize output with it. So, assuming you have dumped the output in a `cache-valkey.k.output.yaml` file, execute the following:

    ~~~sh
    $ kubeconform -summary cache-valkey.k.output.yaml 
    Summary: 4 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
    ~~~

    Notice the `-summary` option in the shell command above. It is what makes the `kubeconform` command print a results summary when it finishes.

    > [!NOTE]
    > **`kubeconform` does not produce an output when the input is valid**\
    > With a completely valid input as in this case and no option specified, `kubeconform` does not print anything in the shell.
    >
    > On the other hand, `kubeconform` (at least, in the version `0.7.0` installed with this guide) is not yet able to understand Kustomize projects and ends up finding errors in them.

## Do not deploy this Valkey project on its own

Although you technically can deploy this Valkey Kustomize project, wait until you have all the components and the main Seafile Kustomize project ready. Then, you will deploy the whole lot at once with just one `kubectl` command.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/seafile`
- `$HOME/k8sprjs/ghost/components`
- `$HOME/k8sprjs/ghost/components/cache-valkey`
- `$HOME/k8sprjs/ghost/components/cache-valkey/configs`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources`
- `$HOME/k8sprjs/ghost/components/cache-valkey/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/cache-valkey/kustomization.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/configs/valkey.conf`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.deployment.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/resources/cache-valkey.service.yaml`
- `$HOME/k8sprjs/ghost/components/cache-valkey/secrets/valkey.pwd`

## References

### [Kubernetes](https://kubernetes.io/docs/)

#### [Concepts](https://kubernetes.io/docs/concepts/)

- [Overview. Objects in Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
  - [Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)

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

#### Articles about pod scheduling

- [TheNewStack. Strategies for Kubernetes Pod Placement and Scheduling](https://thenewstack.io/strategies-for-kubernetes-pod-placement-and-scheduling/)
- [TheNewStack. Implement Node and Pod Affinity/Anti-Affinity in Kubernetes: A Practical Example](https://thenewstack.io/implement-node-and-pod-affinity-anti-affinity-in-kubernetes-a-practical-example/)
- [TheNewStack. Tutorial: Apply the Sidecar Pattern to Deploy Redis in Kubernetes](https://thenewstack.io/tutorial-apply-the-sidecar-pattern-to-deploy-redis-in-kubernetes/)

#### Articles about ConfigMaps and Secrets

- [Opensource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

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

## Navigation

[<< Previous (**G033. Deploying services 02. Seafile Part 1**)](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%201%20-%20Outlining%20setup,%20arranging%20storage%20and%20choosing%20service%20IPs.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Seafile Part 3**) >>](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md)
