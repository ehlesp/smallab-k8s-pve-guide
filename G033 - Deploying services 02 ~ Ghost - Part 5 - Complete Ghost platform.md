# G033 - Deploying services 02 ~ Ghost - Part 5 - Complete Ghost platform

- [Putting together the whole Ghost platform](#putting-together-the-whole-ghost-platform)
- [Create a folder for the pending Ghost platform resources](#create-a-folder-for-the-pending-ghost-platform-resources)
- [Persistent volumes](#persistent-volumes)
- [TLS certificate](#tls-certificate)
- [Traefik IngressRoute for enabling HTTPS access to the Ghost platform](#traefik-ingressroute-for-enabling-https-access-to-the-ghost-platform)
  - [Ghost Namespace resource](#ghost-namespace-resource)
- [Main Kustomize project for the Ghost platform](#main-kustomize-project-for-the-ghost-platform)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [Navigation](#navigation)

## Putting together the whole Ghost platform

This is the final part of the Ghost platform deployment procedure. Here you will declare:

- The persistent volumes to be claimed by all components.
- The TLS certificate for encrypting client communications with the Ghost platform.
- The Traefik ingress resource that enables HTTPS access to the Ghost platform.
- The common namespace for the whole Ghost platform's Kubernetes setup.

You will put all these elements together with the components Kustomize subprojects you have already created in a single main Kustomize project. Furthermore, this part will also show you how to check out your Ghost platform and its containers.

## Create a folder for the pending Ghost platform resources

The elements still missing in this Ghost platform deployment are all resources. Therefore, start by creating a folder where to put their YAML declarations together under the root folder of the Ghost platform Kustomize project:

~~~sh
$ mkdir -p $HOME/k8sprjs/ghost/resources
~~~

## Persistent volumes

A `PersistentVolume` is the Kubernetes resource for enabling in your K3s cluster the LVM storage volumes you arranged in [the first part of this Ghost deployment procedure](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agent-node):

1. You need to create three different persistent volumes, so prepare a new YAML for each of them:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/resources/{ghost-ssd-cache,ghost-ssd-db,ghost-hdd-srv}.persistentvolume.yaml
    ~~~

2. Declare the persistent volume for the Valkey cache server instance in `ghost-ssd-cache.persistentvolume.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolume

    metadata:
      name: ghost-ssd-cache
    spec:
      capacity:
        storage: 2.8G
      volumeMode: Filesystem
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      persistentVolumeReclaimPolicy: Retain
      local:
        path: /mnt/ghost-ssd/cache/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
    ~~~

3. Declare the persistent volume for the MariaDB server instance in `ghost-ssd-db.persistentvolume.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolume

    metadata:
      name: ghost-ssd-db
    spec:
      capacity:
        storage: 6.5G
      volumeMode: Filesystem
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      persistentVolumeReclaimPolicy: Retain
      local:
        path: /mnt/ghost-ssd/db/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
    ~~~

3. Declare the persistent volume for the Ghost server instance in `ghost-hdd-srv.persistentvolume.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolume

    metadata:
      name: ghost-hdd-srv
    spec:
      capacity:
        storage: 9.3G
      volumeMode: Filesystem
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      persistentVolumeReclaimPolicy: Retain
      local:
        path: /mnt/ghost-hdd/srv/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
    ~~~

All these `PersistentVolume` declarations use exactly the same parameters:

- In the `metadata` section, the `name` strings are the same ones set in the claims you declared for the MariaDB and Seafile servers.

- In the `spec` section there are a number or particularities:

  - The `spec.capacity.storage` is a decimal number in gigabytes (`G`). Internally the decimal value will be converted to megabytes (`M`). Be sure of not assigning more capacity than is really available in the underlying storage, something you can check on the node with `df -h`.

  > [!IMPORTANT]
  > **Be careful with the units you use in Kubernetes**\
  > It is not the same typing **1G** (1000M) than **1Gi** (1024 Mi). Check out [this Stackoverflow question about the matter](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g) for further clarification.

  - The `spec.volumeMode` is set to `Filesystem` because the underlying LVM volume has been formatted with an ext4 filesystem. The alternative value is `Block`, and its valid only for raw (unformatted) volumes connected through storage plugins that support that format (`local-path` doesn't).

  - The `spec.accessModes` list has just the `ReadWriteOnce` value to ensure that only one pod (hence the `Once` part) has read and write access to the volume.

  - The `spec.storageClassName` is a parameter that indicates what storage profile (a particular set of properties) to use with the persistent volume. Remember that you only have one available in your K3s cluster, `local-path`, so that is the one you have to use.

    > [!IMPORTANT]
    > **Mind the value you set in the `storageClassName` parameter**\
    > If you leave the `storageClassName` parameter unset, its value will be set internally to the default one (`local-path` in a K3s cluster). On the other hand, if the value is the empty string (`storageClassName: ""`), this leaves the volume with no storage class assigned at all.

  - The `spec.persistentVolumeReclaimPolicy` parameter is about the reclaim policy to apply to this persistent volume. When all the persistent volume claims that required this volume are deleted from the cluster, the system must know what to do with this storage.

    - There are only two policies to use here: `Retain` or `Delete`.

    - Left unset, it will be set to whatever reclaim policy is set in the storage class. The `local-path` has it on `Delete`.

    - `Retain` deletes the persistent volume from the cluster but not the associated storage asset. This means that whatever data was stored there will be preserved.

    - `Delete` deletes both the persistent volume and the associated storage asset, but only if the volume plugin/storage provisioner used supports it. In the case of the Rancher [local-path-provisioner](https://github.com/rancher/local-path-provisioner) used in K3s (associated with the `local-path` storage class), it will automatically clean up the contents stored in the volume.

  - In `spec.local.path` is where you specify the **absolute path**, within the node's filesystem, where you want to mount this volume. Notice how, in all the PVs, it has the path to their corresponding `k3smnt` folder you already left prepared in your `k3sagent02` VM.

  - The `spec.nodeAffinity` block restricts to which node in the cluster a persistent volume will be binded to. Since the storage used in this guide's setup is local, you have to ensure with this set of parameters that the persistent volume is assigned to the node where the storage space truly exists. This affinity configuration would not be necessary in the case of using a distributed storage system.

    In the YAML declarations above, you can see how in all the PVs there is only one node affinity rule that looks for the hostname of the node (the `key` in the `matchExpressions` section), and checks if it is `In` (the `operator` parameter) the list of admitted `values`. Since the `k3sagent02` node is the only one with the storage ready for those volumes, its hostname is the only value in the list.

## TLS certificate

To encrypt the communications between your Ghost platform and its clients, you need a TLS certificate [like the one created previously in the deployment of Headlamp back in the chapter **G031**](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#deploying-headlamp).

1. Create a `ghost.homelab.cloud-tls.certificate.cert-manager.yaml` file under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/resources/ghost.homelab.cloud-tls.certificate.cert-manager.yaml
    ~~~

2. Declare the certificate in `resources/ghost.homelab.cloud-tls.certificate.cert-manager.yaml`:

    ~~~yaml
    # Certificate for Ghost
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: ghost.homelab.cloud-tls
    spec:
      isCA: false
      secretName: ghost.homelab.cloud-tls
      duration: 2190h # 3 months
      renewBefore: 168h # Certificates must be renewed some time before they expire (7 days)
      dnsNames:
        - ghost.homelab.cloud
        - ghostadmin.homelab.cloud
      ipAddresses:
        - 10.7.0.3
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      issuerRef:
        name: homelab.cloud-intm-ca01-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    This certificate is adjusted to work with the DNS name and external IP address the Ghost server ([the same load balancer IP assigned to its `Service` resource in the previous part](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-service-resource)) will have in the local network. It also includes [the alternative DNS name configured in the Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-configuration-file) for accessing the Admin API.

## Traefik IngressRoute for enabling HTTPS access to the Ghost platform

Rather than just allow access directly to the Ghost platform through its `Service`, better handle it with a Traefik `IngressRoute`. This will allow you to provide a proper HTTPS access that uses [the TLS certificate you have declared in the previous section](#tls-certificate). Also, this `IngressRoute` will have a `Middleware` enabling a white list of IPs restricting access to the Ghost Admin API path:

1. Create the `ghost.homelab.cloud.ingressroute.traefik.yaml` and  files in the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/resources/{ghost.homelab.cloud.ingressroute,ghostadmin.ipwhitelist.middleware}.traefik.yaml
    ~~~

2. Declare the Traefik `Middleware` object that will contain the IP white list in `resources/ghostadmin.ipwhitelist.middleware.traefik.yaml`:

    ~~~yaml
    apiVersion: traefik.io/v1alpha1
    kind: Middleware

    metadata:
      name: ghostadmin.ipwhitelist
    spec:
      ipWhiteList:
        sourceRange:
        - 10.0.0.0/24
    ~~~

    The IP white list declared in this Traefik middleware is just an example that you must adapt to fit your particular local network setup. Remember that this white list is only for restricting clients from your local network to access your Ghost server Admin API. This white list will not affect in any way the internal networking of this guide's K3s cluster.

3. Declare the Traefik `IngressRoute` object in `resources/ghost.homelab.cloud.ingressroute.traefik.yaml`:

    ~~~yaml
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute

    metadata:
      name: ghost.homelab.cloud
    spec:
      entryPoints:
      - websecure
      routes:
      - kind: Rule
        match: Host(`ghost.homelab.cloud`)
        services:
        - kind: Service
          name: server-ghost
          passHostHeader: true
          port: server
          scheme: http
      - kind: Rule
        match: Host(`ghostadmin.homelab.cloud`) && PathPrefix(`/ghost/api/admin`)
        middlewares:
        - name: ghostadmin.ipwhitelist
        services:
        - kind: Service
          name: server-ghost
          passHostHeader: true
          port: server
          scheme: http
      tls:
        secretName: ghost.homelab.cloud-tls
    ~~~

    This ingress configures two HTTPS routes into the Ghost platform:

    - The `spec.entryPoints` only enables the websecure (HTTPS) access to the routes declared below.

    - There are two routes enabled in `spec.routes`:

      - The first `Rule` enables the route into the Ghost platform for regular users that only want to use the platform.

      - The second `Rule` is for enabling access to the [Ghost platform's Admin API](https://docs.ghost.org/admin-api). [According to the official Ghost documentation](https://docs.ghost.org/admin-api#base-url), the base URL of this Admin API is composed of the admin domain (the DNS name `ghostadmin.homelab.cloud` in this case) and the path `/ghost/api/admin`.

        Also see in this second rule how it invokes the `ghostadmin.ipwhitelist` middleware for enabling the IP white list restricting which clients can access this Ghost Admin API route.

      - Both rules invoke the same `server-ghost` service and call its port by name (which was `server`). Also enable forwarding the client's Host header to the Ghost server with the `passHostHeader` option and specify that requests have the http `scheme`.

    - The TLS certificate is set in the `tls.secretName` parameter.

### Ghost Namespace resource

To avoid naming conflicts with any other resources you could have running in your K3s cluster, it is better to put all the components of your Ghost platform under their own exclusive namespace:

1. Since a `Namespace` is also a Kubernetes resource, create a file for it under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/resources/ghost.namespace.yaml
    ~~~

2. Declare the `Namespace` resource in `resources/ghost.namespace.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: Namespace

    metadata:
      name: ghost
    ~~~

    As you see above, the `Namespace` is one of the simplest resources you can declare in a Kubernetes cluster.

## Main Kustomize project for the Ghost platform

With every required element declared or configured, now you need to put everything together under a single main Kustomize project:

1. Create a `kustomization.yaml` file under the root `ghost` folder of the Ghost platform's deployment project:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/kustomization.yaml
    ~~~

2. Declare the main Kustomize project in `kustomization.yaml`:

    ~~~yaml
    # Ghost platform setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: ghost

    labels:
      - pairs:
          platform: ghost
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/ghost-hdd-srv.persistentvolume.yaml
    - resources/ghost-ssd-cache.persistentvolume.yaml
    - resources/ghost-ssd-db.persistentvolume.yaml
    - resources/ghost.homelab.cloud-tls.certificate.cert-manager.yaml
    - resources/ghostadmin.ipwhitelist.middleware.traefik.yaml
    - resources/ghost.homelab.cloud.ingressroute.traefik.yaml
    - resources/ghost.namespace.yaml
    - components/cache-valkey
    - components/db-mariadb
    - components/server-ghost
    ~~~

    Be aware of the following details:

    - The `ghost` namespace is applied to all the resources coming out of this Kustomize project, except the `Namespace` resource itself.

    - The `labels` will brand all the resources part of this Kustomize project with a `platform` label. Remember that you already set an `app` label within each component.

    - In the `resources` list you have yaml files and also the directories of the components you have configured in the previous parts of this guide.

      > [!NOTE]
      > **Kustomize projects can be added as resources**\
      > You can add directories as resources only if they have a `kustomization.yaml` inside that can be read by Kustomize. In other words, you can list Kustomize projects as resources for another Kustomize project.

3. As usual, check the Kustomize YAML output for this project. Since this particular output is going to be particularly long, it may be better to dump it into a file such as `ghost.k.output.yaml`:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/ghost > ghost.k.output.yaml
    ~~~

4. Open the `ghost.k.output.yaml` file and compare your resulting YAML output with this one:

    ~~~yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        platform: ghost
      name: ghost
    ---
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
        platform: ghost
      name: cache-valkey-config-c86dc4fh5d
      namespace: ghost
    ---
    apiVersion: v1
    data:
      ghost-db-name: ghost-db
      ghost-username: ghostdb
      initdb.sh: |-
        #!/bin/sh
        echo ">>> Creating user for MariaDB Prometheus metrics exporter"
        mysql -u root -p$MYSQL_ROOT_PASSWORD --execute \
        "CREATE USER '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PROMETHEUS_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
        GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost';
        FLUSH privileges;"
      my.cnf: |-
        [client]
        default-character-set = utf8mb4

        [server]
        # General parameters
        skip_name_resolve = ON
        max_connections = 50
        thread_cache_size = 50
        character_set_server = utf8mb4
        collation_server = utf8mb4_general_ci
        tmp_table_size = 64M

        # InnoDB storage engine parameters
        innodb_buffer_pool_size = 256M
        innodb_io_capacity = 2000
        innodb_io_capacity_max = 3000
        innodb_log_buffer_size = 32M
        innodb_log_file_size = 256M
      prometheus-exporter-username: promexp
    kind: ConfigMap
    metadata:
      labels:
        app: db-mariadb
        platform: ghost
      name: db-mariadb-config-t9c84t7h62
      namespace: ghost
    ---
    apiVersion: v1
    data:
      GHOST_CONTENT: /home/nonroot/app/ghost/content
      GHOST_INSTALL: /home/nonroot/app/ghost
      NODE_ENV: production
    kind: ConfigMap
    metadata:
      labels:
        app: server-ghost
        platform: ghost
      name: server-ghost-env-vars-9ggkgtdt7b
      namespace: ghost
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
        platform: ghost
      name: cache-valkey-acl-k2bm2h5fgk
      namespace: ghost
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
        platform: ghost
      name: cache-valkey-exporter-user-4thcmd49m2
      namespace: ghost
    type: Opaque
    ---
    apiVersion: v1
    data:
      ghost-user-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfNmgwc1RfdVozciE=
      prometheus-exporter-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfM3hQMHJUZVJfdVozciE=
      root-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1Jfck9vN191WjNyIQ==
    kind: Secret
    metadata:
      labels:
        app: db-mariadb
        platform: ghost
      name: db-mariadb-passwords-8g2hdgch72
      namespace: ghost
    type: Opaque
    ---
    apiVersion: v1
    data:
      config.production.json: |
        ewogICJ1cmwiOiAiaHR0cHM6Ly9naG9zdC5ob21lbGFiLmNsb3VkIiwKICAiYWRtaW4iOi
        B7CiAgICAidXJsIjogImh0dHBzOi8vZ2hvc3RhZG1pbi5ob21lbGFiLmNsb3VkIgogIH0s
        CiAgInNlcnZlciI6IHsKICAgICJob3N0IjogIjAuMC4wLjAiLAogICAgInBvcnQiOiAyMz
        Y4CiAgfSwKICAibG9nZ2luZyI6IHsKICAgICJ0cmFuc3BvcnRzIjogWwogICAgICAgICJz
        dGRvdXQiCiAgICBdCiAgfSwKICAibWFpbCI6IHsKICAgICJ0cmFuc3BvcnQiOiAiU01UUC
        IsCiAgICAiZnJvbSI6ICJpbmZvQGdob3N0LmhvbWVsYWIuY2xvdWQiLAogICAgIm9wdGlv
        bnMiOiB7CiAgICAgICJzZXJ2aWNlIjogIkdvb2dsZSIsCiAgICAgICJob3N0IjogInNtdH
        AuZ21haWwuY29tIiwKICAgICAgInBvcnQiOiA0NjUsCiAgICAgICJzZWN1cmUiOiB0cnVl
        LAogICAgICAiYXV0aCI6IHsKICAgICAgICAidXNlciI6ICJ5b3VyX2dob3N0X2VtYWlsQG
        dtYWlsLmNvbSIsCiAgICAgICAgInBhc3MiOiAiWTB1cl82aE81dF9lTTQxbF9QNFNzdnZv
        UmQiCiAgICAgIH0KICAgIH0KICB9LAogICJhZGFwdGVycyI6IHsKICAgICJjYWNoZSI6IH
        sKICAgICAgIlJlZGlzIjogewogICAgICAgICJob3N0IjogImNhY2hlLXZhbGtleS5naG9z
        dCIsCiAgICAgICAgInBvcnQiOiA2Mzc5LAogICAgICAgICJ1c2VybmFtZSI6ICJnaG9zdG
        NhY2hlIiwKICAgICAgICAicGFzc3dvcmQiOiAicEFTMndPUlRfZjByX1QjZV9HaDA1VF9V
        czNSIiwKICAgICAgICAia2V5UHJlZml4IjogImdob3N0OiIsCiAgICAgICAgInR0bCI6ID
        M2MDAsCiAgICAgICAgInJldXNlQ29ubmVjdGlvbiI6IHRydWUsCiAgICAgICAgInJlZnJl
        c2hBaGVhZEZhY3RvciI6IDAuOCwKICAgICAgICAiZ2V0VGltZW91dE1pbGxpc2Vjb25kcy
        I6IDUwMDAsCiAgICAgICAgInN0b3JlQ29uZmlnIjogewogICAgICAgICAgInJldHJ5Q29u
        bmVjdFNlY29uZHMiOiAxMCwKICAgICAgICAgICJsYXp5Q29ubmVjdCI6IHRydWUsCiAgIC
        AgICAgICAiZW5hYmxlT2ZmbGluZVF1ZXVlIjogdHJ1ZSwKICAgICAgICAgICJtYXhSZXRy
        aWVzUGVyUmVxdWVzdCI6IDMKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJnc2NhbiI6IH
        sKICAgICAgICAiYWRhcHRlciI6ICJSZWRpcyIsCiAgICAgICAgInR0bCI6IDQzMjAwLAog
        ICAgICAgICJyZWZyZXNoQWhlYWRGYWN0b3IiOiAwLjksCiAgICAgICAgImtleVByZWZpeC
        I6ICJnaG9zdDpnc2Nhbi4iCiAgICAgIH0sCiAgICAgICJpbWFnZVNpemVzIjogewogICAg
        ICAgICJhZGFwdGVyIjogIlJlZGlzIiwKICAgICAgICAidHRsIjogODY0MDAsCiAgICAgIC
        AgInJlZnJlc2hBaGVhZEZhY3RvciI6IDAuOTUsCiAgICAgICAgImtleVByZWZpeCI6ICJn
        aG9zdDppbWFnZVNpemVzLiIKICAgICAgfSwKICAgICAgImxpbmtSZWRpcmVjdHNQdWJsaW
        MiOiB7CiAgICAgICAgImFkYXB0ZXIiOiAiUmVkaXMiLAogICAgICAgICJ0dGwiOiA3MjAw
        LAogICAgICAgICJyZWZyZXNoQWhlYWRGYWN0b3IiOiAwLjksCiAgICAgICAgImtleVByZW
        ZpeCI6ICJnaG9zdDpsaW5rUmVkaXJlY3RzUHVibGljLiIKICAgICAgfSwKICAgICAgInBv
        c3RzUHVibGljIjogewogICAgICAgICJhZGFwdGVyIjogIlJlZGlzIiwKICAgICAgICAidH
        RsIjogMTgwMCwKICAgICAgICAicmVmcmVzaEFoZWFkRmFjdG9yIjogMC43LAogICAgICAg
        ICJrZXlQcmVmaXgiOiAiZ2hvc3Q6cG9zdHNQdWJsaWMuIgogICAgICB9LAogICAgICAic3
        RhdHMiOiB7CiAgICAgICAgImFkYXB0ZXIiOiAiUmVkaXMiLAogICAgICAgICJ0dGwiOiA5
        MDAsCiAgICAgICAgInJlZnJlc2hBaGVhZEZhY3RvciI6IDAuOCwKICAgICAgICAia2V5UH
        JlZml4IjogImdob3N0OnN0YXRzLiIKICAgICAgfSwKICAgICAgInRhZ3NQdWJsaWMiOiB7
        CiAgICAgICAgImFkYXB0ZXIiOiAiUmVkaXMiLAogICAgICAgICJ0dGwiOiAzNjAwLAogIC
        AgICAgICJyZWZyZXNoQWhlYWRGYWN0b3IiOiAwLjgsCiAgICAgICAgImtleVByZWZpeCI6
        ICJnaG9zdDp0YWdzUHVibGljLiIKICAgICAgfQogICAgfQogIH0sCiAgImhvc3RTZXR0aW
        5ncyI6IHsKICAgICJsaW5rUmVkaXJlY3RzUHVibGljQ2FjaGUiOiB7CiAgICAgICJlbmFi
        bGVkIjogdHJ1ZQogICAgfSwKICAgICJwb3N0c1B1YmxpY0NhY2hlIjogewogICAgICAiZW
        5hYmxlZCI6IHRydWUKICAgIH0sCiAgICAic3RhdHNDYWNoZSI6IHsKICAgICAgImVuYWJs
        ZWQiOiB0cnVlCiAgICB9LAogICAgInRhZ3NQdWJsaWNDYWNoZSI6IHsKICAgICAgImVuYW
        JsZWQiOiB0cnVlCiAgICB9CiAgfSwKICAiZGF0YWJhc2UiOiB7CiAgICAiY2xpZW50Ijog
        Im15c3FsIiwKICAgICJjb25uZWN0aW9uIjogewogICAgICAiaG9zdCI6ICJkYi1tYXJpYW
        RiLmdob3N0IiwKICAgICAgInVzZXIiOiAiZ2hvc3RkYiIsCiAgICAgICJwYXNzd29yZCI6
        ICJsMG5HLlBsNGluX1QzeHRfc0VrUmV0X3A0czV3T1JELUZvUl82aDBzVF91WjNyISIsCi
        AgICAgICJkYXRhYmFzZSI6ICJnaG9zdC1kYiIsCiAgICAgICJwb3J0IjogIjMzMDYiCiAg
        ICB9CiAgfSwKICAicHJvY2VzcyI6ICJsb2NhbCIsCiAgInBhdGhzIjogewogICAgImNvbn
        RlbnRQYXRoIjogIi9ob21lL25vbnJvb3QvYXBwL2dob3N0L2NvbnRlbnQiCiAgfQp9
    kind: Secret
    metadata:
      labels:
        app: server-ghost
        platform: ghost
      name: server-ghost-config-fg789722ch
      namespace: ghost
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
        platform: ghost
      name: cache-valkey
      namespace: ghost
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
        platform: ghost
      type: ClusterIP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9104"
        prometheus.io/scrape: "true"
      labels:
        app: db-mariadb
        platform: ghost
      name: db-mariadb
      namespace: ghost
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 3306
        protocol: TCP
        targetPort: server
      - name: metrics
        port: 9104
        protocol: TCP
        targetPort: metrics
      selector:
        app: db-mariadb
        platform: ghost
      type: ClusterIP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: server-ghost
        platform: ghost
      name: server-ghost
      namespace: ghost
    spec:
      loadBalancerIP: 10.7.0.3
      ports:
      - name: server
        port: 2368
        protocol: TCP
        targetPort: server
      selector:
        app: server-ghost
        platform: ghost
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      labels:
        platform: ghost
      name: ghost-hdd-srv
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 9.3G
      local:
        path: /mnt/ghost-hdd/srv/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
      persistentVolumeReclaimPolicy: Retain
      storageClassName: local-path
      volumeMode: Filesystem
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      labels:
        platform: ghost
      name: ghost-ssd-cache
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 2.8G
      local:
        path: /mnt/ghost-ssd/cache/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
      persistentVolumeReclaimPolicy: Retain
      storageClassName: local-path
      volumeMode: Filesystem
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      labels:
        platform: ghost
      name: ghost-ssd-db
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 6.5G
      local:
        path: /mnt/ghost-ssd/db/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent02
      persistentVolumeReclaimPolicy: Retain
      storageClassName: local-path
      volumeMode: Filesystem
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: cache-valkey
        platform: ghost
      name: cache-valkey
      namespace: ghost
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 2.8G
      storageClassName: local-path
      volumeName: ghost-ssd-cache
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: db-mariadb
        platform: ghost
      name: db-mariadb
      namespace: ghost
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 6.5G
      storageClassName: local-path
      volumeName: ghost-ssd-db
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-ghost
        platform: ghost
      name: server-ghost
      namespace: ghost
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.3G
      storageClassName: local-path
      volumeName: ghost-hdd-srv
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: cache-valkey
        platform: ghost
      name: cache-valkey
      namespace: ghost
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: cache-valkey
          platform: ghost
      serviceName: cache-valkey
      template:
        metadata:
          labels:
            app: cache-valkey
            platform: ghost
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
                name: cache-valkey-exporter-user-4thcmd49m2
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
              secretName: cache-valkey-acl-k2bm2h5fgk
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: db-mariadb
        platform: ghost
      name: db-mariadb
      namespace: ghost
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: db-mariadb
          platform: ghost
      serviceName: db-mariadb
      template:
        metadata:
          labels:
            app: db-mariadb
            platform: ghost
        spec:
          containers:
          - env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  key: ghost-db-name
                  name: db-mariadb-config-t9c84t7h62
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: root-password
                  name: db-mariadb-passwords-8g2hdgch72
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  key: ghost-username
                  name: db-mariadb-config-t9c84t7h62
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: ghost-user-password
                  name: db-mariadb-passwords-8g2hdgch72
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-config-t9c84t7h62
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-passwords-8g2hdgch72
            image: mariadb:11.8-noble
            name: server
            ports:
            - containerPort: 3306
              name: server
            resources:
              requests:
                cpu: "0.75"
                memory: 256Mi
            volumeMounts:
            - mountPath: /etc/mysql/my.cnf
              name: mariadb-config
              readOnly: true
              subPath: my.cnf
            - mountPath: /docker-entrypoint-initdb.d/initdb.sh
              name: mariadb-config
              readOnly: true
              subPath: initdb.sh
            - mountPath: /var/lib/mysql
              name: mariadb-storage
          - args:
            - --collect.auto_increment.columns
            - --collect.binlog_size
            - --collect.engine_innodb_status
            - --collect.global_status
            - --collect.global_variables
            - --collect.info_schema.clientstats
            - --collect.info_schema.innodb_metrics
            - --collect.info_schema.innodb_tablespaces
            - --collect.info_schema.innodb_cmp
            - --collect.info_schema.innodb_cmpmem
            - --collect.info_schema.processlist
            - --collect.info_schema.query_response_time
            - --collect.info_schema.tables
            - --collect.info_schema.tablestats
            - --collect.info_schema.schemastats
            - --collect.info_schema.userstats
            - --collect.perf_schema.eventsstatements
            - --collect.perf_schema.eventsstatementssum
            - --collect.perf_schema.eventswaits
            - --collect.perf_schema.file_events
            - --collect.perf_schema.file_instances
            - --collect.perf_schema.indexiowaits
            - --collect.perf_schema.tableiowaits
            - --collect.perf_schema.tablelocks
            - --collect.perf_schema.replication_group_member_stats
            - --collect.perf_schema.replication_applier_status_by_worker
            - --collect.slave_hosts
            - --mysqld.address=localhost:3306
            - --mysqld.username=$(MARIADB_PROMETHEUS_EXPORTER_USERNAME)
            env:
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-config-t9c84t7h62
            - name: MYSQLD_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-passwords-8g2hdgch72
            image: prom/mysqld-exporter:v0.18.0
            name: metrics
            ports:
            - containerPort: 9104
              name: metrics
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
          volumes:
          - name: mariadb-storage
            persistentVolumeClaim:
              claimName: db-mariadb
          - configMap:
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: my.cnf
                path: my.cnf
              name: db-mariadb-config-t9c84t7h62
            name: mariadb-config
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-ghost
        platform: ghost
      name: server-ghost
      namespace: ghost
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-ghost
          platform: ghost
      serviceName: server-ghost
      template:
        metadata:
          labels:
            app: server-ghost
            platform: ghost
        spec:
          automountServiceAccountToken: false
          containers:
          - envFrom:
            - configMapRef:
                name: server-ghost-env-vars-9ggkgtdt7b
            image: ghcr.io/sredevopsorg/ghost-on-kubernetes:main
            livenessProbe:
              failureThreshold: 1
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
                path: /ghost/api/admin/site/
                port: server
              initialDelaySeconds: 30
              periodSeconds: 300
              successThreshold: 1
              timeoutSeconds: 3
            name: server
            ports:
            - containerPort: 2368
              name: server
              protocol: TCP
            readinessProbe:
              failureThreshold: 3
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
                path: /ghost/api/admin/site/
                port: server
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 3
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 65532
            volumeMounts:
            - mountPath: /home/nonroot/app/ghost/content
              name: ghost-storage
            - mountPath: /home/nonroot/app/ghost/config.production.json
              name: ghost-config
              readOnly: true
              subPath: config.production.json
            - mountPath: /tmp
              name: tmp
          initContainers:
          - command:
            - /bin/sh
            - -c
            - |
              set -e

              export DIRS='files logs apps themes data public settings images media'
              echo 'Check if base dirs exists, if not, create them'
              echo "Directories to check: $DIRS"
              for dir in $DIRS; do
                if [ ! -d $GHOST_CONTENT/$dir ]; then
                  echo "Creating $GHOST_CONTENT/$dir directory"
                  mkdir -pv $GHOST_CONTENT/$dir || echo "Error creating $GHOST_CONTENT/$dir directory"
                fi
                chown -Rfv 65532:65532 $GHOST_CONTENT/$dir && echo "chown ok on $dir" || echo "Error changing ownership of $GHOST_CONTENT/$dir directory"
              done
              exit 0
            env:
            - name: GHOST_CONTENT
              valueFrom:
                configMapKeyRef:
                  key: GHOST_CONTENT
                  name: server-ghost-env-vars-9ggkgtdt7b
            image: docker.io/busybox:stable-musl
            name: permissions-fix
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
            volumeMounts:
            - mountPath: /home/nonroot/app/ghost/content
              name: ghost-storage
              readOnly: false
          volumes:
          - name: ghost-storage
            persistentVolumeClaim:
              claimName: server-ghost
          - name: ghost-config
            secret:
              defaultMode: 420
              items:
              - key: config.production.json
                path: config.production.json
              secretName: server-ghost-config-fg789722ch
          - emptyDir:
              sizeLimit: 64Mi
            name: tmp
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      labels:
        platform: ghost
      name: ghost.homelab.cloud-tls
      namespace: ghost
    spec:
      dnsNames:
      - ghost.homelab.cloud
      - ghostadmin.homelab.cloud
      duration: 2190h
      ipAddresses:
      - 10.7.0.3
      isCA: false
      issuerRef:
        group: cert-manager.io
        kind: ClusterIssuer
        name: homelab.cloud-intm-ca01-issuer
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      renewBefore: 168h
      secretName: ghost.homelab.cloud-tls
    ---
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      labels:
        platform: ghost
      name: ghost.homelab.cloud
      namespace: ghost
    spec:
      entryPoints:
      - websecure
      routes:
      - kind: Rule
        match: Host(`ghost.homelab.cloud`)
        services:
        - kind: Service
          name: server-ghost
          passHostHeader: true
          port: server
          scheme: http
      - kind: Rule
        match: Host(`ghostadmin.homelab.cloud`) && PathPrefix(`/ghost/api/admin`)
        middlewares:
        - name: ghostadmin.ipwhitelist
        services:
        - kind: Service
          name: server-ghost
          passHostHeader: true
          port: server
          scheme: http
      tls:
        secretName: ghost.homelab.cloud-tls
    ---
    apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      labels:
        platform: ghost
      name: ghostadmin.ipwhitelist
      namespace: ghost
    spec:
      ipWhiteList:
        sourceRange:
        - 10.0.0.0/24
    ~~~

    The most important thing here is to verify that the resources that get their names modified by Kustomize with an autogenereated suffix, in particular `ConfigMaps` and `Secrets`, are invoked by their modified name wherever they are used in this setup. Remember that Kustomize will not change the names if they have been put in non-standard Kubernetes parameters, and it might be possible that Kustomize may not even touch values in certain particular standard ones.

    On the other hand, notice how Kustomize has grouped all the resources together according to their kind and ordered them alphabetically by `metadata.name`. Also see how the `ghost` namespace has been set in all resources except in the `PersistentVolume` ones because those in particular are not namespaced.

5. If you are satisfied with the final YAML, apply the Ghost platform Kustomize project to your cluster:

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/ghost
    ~~~

6. Right after applying the Kustomize project, check how the deployment is going for the components of your Ghost platform:

    ~~~bash
    $ kubectl -n ghost get pv,pvc,cm,secret,deployment,replicaset,statefulset,pod,svc -o wide
    ~~~

    Below you can see a possible output from the `kubectl` command above:

    ~~~sh
    NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE   VOLUMEMODE
    persistentvolume/ghost-hdd-srv     9300M      RWO            Retain           Bound    ghost/server-ghost   local-path     <unset>                          5s    Filesystem
    persistentvolume/ghost-ssd-cache   2800M      RWO            Retain           Bound    ghost/cache-valkey   local-path     <unset>                          5s    Filesystem
    persistentvolume/ghost-ssd-db      6500M      RWO            Retain           Bound    ghost/db-mariadb     local-path     <unset>                          5s    Filesystem

    NAME                                 STATUS    VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE   VOLUMEMODE
    persistentvolumeclaim/cache-valkey   Bound     ghost-ssd-cache   2800M      RWO            local-path     <unset>                 6s    Filesystem
    persistentvolumeclaim/db-mariadb     Pending   ghost-ssd-db      0                         local-path     <unset>                 6s    Filesystem
    persistentvolumeclaim/server-ghost   Bound     ghost-hdd-srv     9300M      RWO            local-path     <unset>                 6s    Filesystem

    NAME                                         DATA   AGE
    configmap/cache-valkey-config-c86dc4fh5d     1      9s
    configmap/db-mariadb-config-t9c84t7h62       5      9s
    configmap/kube-root-ca.crt                   1      9s
    configmap/server-ghost-env-vars-9ggkgtdt7b   3      8s

    NAME                                           TYPE                DATA   AGE
    secret/cache-valkey-acl-k2bm2h5fgk             Opaque              1      9s
    secret/cache-valkey-exporter-user-4thcmd49m2   Opaque              2      9s
    secret/db-mariadb-passwords-8g2hdgch72         Opaque              3      9s
    secret/ghost.homelab.cloud-tls                 kubernetes.io/tls   3      6s
    secret/server-ghost-config-k6b85fg6bb          Opaque              1      9s

    NAME                            READY   AGE   CONTAINERS       IMAGES
    statefulset.apps/cache-valkey   1/1     9s    server,metrics   valkey/valkey:9.0-alpine,oliver006/redis_exporter:v1.80.0-alpine
    statefulset.apps/db-mariadb     0/1     9s    server,metrics   mariadb:11.8-noble,prom/mysqld-exporter:v0.18.0
    statefulset.apps/server-ghost   0/1     8s    server           ghcr.io/sredevopsorg/ghost-on-kubernetes:main

    NAME                 READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
    pod/cache-valkey-0   2/2     Running   0          10s   10.42.1.171   k3sagent02   <none>           <none>
    pod/db-mariadb-0     0/2     Pending   0          10s   <none>        <none>       <none>           <none>
    pod/server-ghost-0   0/1     Running   0          9s    10.42.1.172   k3sagent02   <none>           <none>

    NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE   SELECTOR
    service/cache-valkey   ClusterIP      None            <none>        6379/TCP,9121/TCP   12s   app=cache-valkey,platform=ghost
    service/db-mariadb     ClusterIP      None            <none>        3306/TCP,9104/TCP   12s   app=db-mariadb,platform=ghost
    service/server-ghost   LoadBalancer   10.43.107.239   10.7.0.3      2368:32429/TCP      12s   app=server-ghost,platform=ghost
    ~~~

    There are a number of details about this Ghost platform deployment you must realize, based on this `kubectl` output:

    - First are the persistent volumes with all their details. Notice how the values under the `CAPACITY` column are in megabytes (`M`), although those sizes were specified in gigabytes (`G`) in the yaml description. Also see how there's no information about to which node are the volumes associated to. The status `Bound` means that the volume has been claimed, so its not free at the moment.

    - Right below the persistent volumes you got the persistent volume claims, and all of them appear with `Bound` status and with the name of the `VOLUME` they're bounded to. And, as it happened with the PVs, the PVCs' requested `CAPACITY` is shown in megabytes (`M`) rather than gigabytes (`G`).

    - The `Deployment` resource for Redis appears indicating that 1 out of 1 required `ReplicaSet`s are `READY`, among other details.

    - What comes out of a `Deployment` resource is a `ReplicaSet`, like the one named `nxcd-cache-redis-68984788b7`. See how the name has an hexadecimal number as a suffix, which is added by Kubernetes automatically. This replica set will give its name to the pods that come out of to it. On the other hand, notice instead of using one `READY` column like in its parent `Deployment` resource, it has a `DESIRED`, `CURRENT` and `READY` to tell you about how many of its pods are running.

    - The `StatefulSet`s appear with their names as they are in their yaml descriptions, next to other values that inform you of the pods they have running (`READY` column) and a few other related details.

    - The resources are apparently fine, and all the expected pods are accounted for and with `Running` in their `STATUS` column. But if, for some reason, a pod is missing some resource they need, they'll remain in `ContainerCreating` or `Pending` status till they get what they require to run.
        - For instance, let's suppose the wildcard certificate's secret is not available in the `nextcloud` namespace yet. This would force the `nxcd-server-apache-nextcloud-0` pod to wait with `ContainerCreating` status till that resource becomes available in the namespace.

        > **BEWARE!**  
        > Remember that, probably due to a bug related to the graceful shutdown feature in the particular K3s version you've installed in this guide series (`v1.22.3+k3s1`), after a reboot the pods may not appear with status `Running` but `Terminated`.

    - Notice a particularity about how pods are named.
        - The pods from regular Deployment resources (such as `nxcd-cache-redis-68984788b7-npjz9`) get their _unique_ name from their parent replica set combined with an autogenerated string.
        - The pods from stateful sets (`nxcd-db-mariadb-0` and `nxcd-server-apache-nextcloud-0` in this case) get their names from their parent stateful set, plus a number as a suffix. When a stateful set requires to run more than one replica, each generated pod will have a different but consecutive number. Check more about stateful sets behaviour [in the official Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

    - At the `Service` resources list, you can see that all services have their cluster IP and the one for the Nextcloud server also has the expected external IP for accessing the platform later. On the other hand, notice that the pods also have an IP which is on a different internal cluster subnet.

    - Finally, see how the pods are all assigned to the `k3sagent02` node of your K3s cluster, due mainly to the rules of affinity applied to the persistent volumes. Services that store data (_state_) have to be deployed where their storage is available. Redis, on the other hand, has its affinity to the Nextcloud server itself, so it ended being deployed in the same node too.
















## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/ghost`
- `$HOME/k8sprjs/ghost/components`
- `$HOME/k8sprjs/ghost/components/cache-valkey`
- `$HOME/k8sprjs/ghost/components/db-mariadb`
- `$HOME/k8sprjs/ghost/components/server-ghost`
- `$HOME/k8sprjs/ghost/resources`

### Files in `kubectl` client system





## Navigation

[<< Previous (**G033. Deploying services 02. Ghost Part 4**)](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Gitea Part 1**) >>](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md)