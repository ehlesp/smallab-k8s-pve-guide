# G033 - Deploying services 02 ~ Seafile - Part 3 - MariaDB database server

- [You can use MariaDB instead of MySQL as database server for Seafile](#you-can-use-mariadb-instead-of-mysql-as-database-server-for-seafile)
- [MariaDB Kustomize subproject's folders](#mariadb-kustomize-subprojects-folders)
- [MariaDB configuration files](#mariadb-configuration-files)
  - [Configuration file `my.cnf`](#configuration-file-mycnf)
  - [Properties file `dbnames.properties`](#properties-file-dbnamesproperties)
  - [Initializer shell script `initdb.sh`](#initializer-shell-script-initdbsh)
- [MariaDB passwords](#mariadb-passwords)
- [MariaDB storage](#mariadb-storage)
- [MariaDB StatefulSet resource](#mariadb-statefulset-resource)
- [MariaDB Service resource](#mariadb-service-resource)
- [MariaDB Kustomize project](#mariadb-kustomize-project)
  - [Checking the Kustomize YAML output](#checking-the-kustomize-yaml-output)
- [Do not deploy this MariaDB project on its own](#do-not-deploy-this-mariadb-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [MariaDB](#mariadb)
    - [MySQL Server Exporter](#mysql-server-exporter)
  - [Kubernetes](#kubernetes)
    - [ConfigMaps and Secrets](#configmaps-and-secrets)
    - [Related contents about ConfigMaps and Secrets](#related-contents-about-configmaps-and-secrets)
    - [Storage](#storage)
    - [Related contents about Kubernetes storage](#related-contents-about-kubernetes-storage)
    - [StatefulSets](#statefulsets)
    - [Environment variables](#environment-variables)
- [Navigation](#navigation)

## You can use MariaDB instead of MySQL as database server for Seafile

Seafile specifies in its official documentation to use [MySQL](https://www.mysql.com/), but [MariaDB](https://mariadb.com/) is a perfectly compatible and open source alternative you can use as Seafile's database.

## MariaDB Kustomize subproject's folders

Since the MariaDB database is just another component of your Seafile platform, you have to put its corresponding folders within the `seafile/components` path you already created in [the previous chapter about the Valkey cache server](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#kustomize-project-folders-for-seafile-and-valkey).

~~~bash
$ mkdir -p $HOME/k8sprjs/seafile/components/db-mariadb/{configs,resources,secrets}
~~~

Like Valkey, MariaDB also has configurations, secrets and resources files making up its Kustomize setup.

## MariaDB configuration files

The MariaDB deployment requires a number of adjustments that are better handled in different configuration files.

> [!NOTE]
> **There is no recommended database configuration for Seafile**\
> [Seafile's official documentation](https://manual.seafile.com/latest/) does not offer any hint nor recommendation about how to configure its database. The configuration files shown in the following subsections are just my take based on previous experience with a similar platform and what I have learned in other sources.

### Configuration file `my.cnf`

The `my.cnf` is the default configuration file for MariaDB, where you can adjust its parameters to better fit your setup:

1. Create a `my.cnf` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/configs/my.cnf
    ~~~

2. Set the following configuration in your `my.cnf` file:

    ~~~properties
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
    ~~~

    This `my.cnf` file makes the MariaDB instance fit for the resources-constrained environment of the K3s agent node in which the database is going to run:

    - The [`skip_name_resolve`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#skip_name_resolve) forces MariaDB to use only IPs for connections, avoiding wasting time in resolving hostnames first. This is particularly useful in this Kubernetes-based Seafile setup, since it will be configured to call the database directly with its internal cluster IP.

    - The values set in the [`max_connections`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#max_connections) and [`thread_cache_size`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#thread_cache_size) parameters are considered for a low usage scenario where just a very small number of clients will access the database.

    - The character set `utf8mb4` specified in the `default-character-set`, [`character_set_server`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#character_set_server) and [`collation_server`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#collation_server) parameters is the most adequate one for modern applications like Seafile. The main advantage of `utf8mb4` is that it accommodates a much wider set of characters than `utf8` or others. On the other hand, `utf8mb4` databases take up more storage space since their characters are "bigger".

    - The [`tmp_table_size`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#tmp_table_size) limits how large temporary tables can grow in memory.

    - The engine used by default in MariaDB is InnoDB, and has its own set of parameters put together in the `my.cnf` file for clarity:

      - The [`innodb_buffer_pool_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_buffer_pool_size) parameter sets the size of the buffer pool in memory, which is recommended to be around the 80% of the memory available for the MariaDB server.

      - The [`innodb_io_capacity`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_io_capacity) and [`innodb_io_capacity_max`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_io_capacity_max) parameters are related to the I/O capacity of the underlying storage. Here they are increased from their default values to fit better the SSD volume used for storing Seafile's MariaDB database.

      - The [`innodb_log_buffer_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_log_buffer_size) parameter affect how MariaDB's redo log feature works. The bigger the buffer, the larger the transactions that MariaDB can execute without hitting storage before committing them.

      - The [`innodb_log_file_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_log_file_size) limits the size of MariaDB's redo log file.

### Properties file `dbnames.properties`

There are a few names you need to specify in your database setup. Those names are values that are better loaded as variables in your MariaDB server container rather than being hardcoded in the MariaDB server configuration:

1. Create a `dbnames.properties` file under the `configs` path:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/configs/dbnames.properties
    ~~~

2. Copy the following parameter lines into `dbnames.properties`:

    ~~~properties
    seafile-db-name=seafile-db
    seafile-username=seafile
    prometheus-exporter-username=exporter
    ~~~

    The three key-value pairs above mean this:

    - `seafile-db-name`\
      Name for the Seafile database.

    - `seafile-username`:\
      Name for the user associated to the Seafile database.

    - `prometheus-exporter-username`\
      Name for the Prometheus metrics exporter user.

### Initializer shell script `initdb.sh`

The Prometheus metrics exporter system you will include in your MariaDB server deployment requires its own user to access certain statistical data from your MariaDB instance. You have already configured its name as a variable in the previous `dbnames.properties` file, but you also need to create the user within the MariaDB installation. The problem is that MariaDB can only create one user in its initial run, and you need also to create the user Seafile needs to work with its own database.

To solve this issue, you can use a initializer shell script that creates that extra user you need in the MariaDB database:

1. Create a `initdb.sh` file in the `configs` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/configs/initdb.sh
    ~~~

2. Fill the `initdb.sh` file with the following shell script:

    ~~~sh
    #!/bin/sh
    echo ">>> Creating user for MariaDB Prometheus metrics exporter"
    mysql -u root -p$MYSQL_ROOT_PASSWORD --execute \
    "CREATE USER '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PROMETHEUS_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
    GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost';
    FLUSH privileges;"
    ~~~

    This is an SQL script, executed by a MariaDB-provided `mysql` shell command, that creates the required user for the Prometheus metrics exporter. Notice how, instead of putting raw values, environment variables (`MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD`) are used as placeholders for several values. Those variables will be defined within the `Deployment` resource definition you will declare later in this chapter.

## MariaDB passwords

There is a number of passwords you need to set up in the MariaDB installation:

- For the MariaDB root user.
- For the Seafile database user.
- For the Prometheus metrics exporter user.

For convenience, declare all of these passwords as variables in the same properties file, so they can be turned into a `Secret` resource later:

1. Create a `dbusers.pwd` file under the `secrets` path:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/secrets/dbusers.pwd
    ~~~

2. Fill `dbusers.pwd` with the following variables:

    ~~~properties
    root-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_rOo7_uZ3r!
    seafile-user-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_S34f1L3_uZ3r!
    prometheus-exporter-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_3xP0rTeR_uZ3r!
    ~~~

    > [!WARNING]
    > **The passwords have to be put in `dbusers.pwd` as plain unencrypted text**\
    > Be careful of who can access this `dbusers.pwd` file.

## MariaDB storage

Storage in Kubernetes has essentially two sides: enabling storage as persistent volumes (PVs), and the claims (PVCs) on each of those persistent volumes. For your Seafile's MariaDB instance you need one persistent volume, declared in the last part of this Seafile guide, and the claim on that particular PV that is declared next:

1. A persistent volume claim is a resource, so create a `db-mariadb.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml
    ~~~

2. Declare Seafile's `PersistentVolumeClaim` in the `db-mariadb.persistentvolumeclaim.yaml` file:

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: db-mariadb
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: db-seafile
      resources:
        requests:
          storage: 3.5G
    ~~~

    There are a few details to understand from the PVC above:

    - The `spec.accessModes` is specified. This is mandatory in a claim and it cannot demand a mode that's not enabled in the persistent volume itself.

    - The `spec.storageClassName` is a parameter that indicates what storage profile (a particular set of properties) to use with the persistent volume. K3s comes with just the `local-path` included by default, something you can check out on your own K3s cluster with `kubectl`.

      ~~~sh
      $ kubectl get storageclass
      NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
      local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  63d
      ~~~

    - The `spec.volumeName` is the name of the persistent volume, in the same namespace, this claim binds itself to.

    - In a claim is also mandatory to specify how much storage is requested, hence the need to put the `spec.resources.requests.storage` parameter there. Be careful of not requesting more space than what's available in the volume.

    - Needless to say, but the persistent volume related to this claim must correspond to the values set here.

## MariaDB StatefulSet resource

Instead of using a `Deployment` resource to put MariaDB in your Kubernetes cluster, you will use a `StatefulSet` instead. Stateful sets are meant for deploying apps or services that store data (_state_) permanently, as databases such as MariaDB do:

1. Create a `db-mariadb.statefulset.yaml` in the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for your Seafile's MariaDB server in `db-mariadb.statefulset.yaml`:

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: db-mariadb
    spec:
      replicas: 1
      serviceName: db-mariadb
      template:
        spec:
          containers:
          - name: server
            image: mariadb:11.8-noble
            ports:
            - containerPort: 3306
            env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: seafile-db-name
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: root-password
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: seafile-username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: seafile-user-password
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: prometheus-exporter-username
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: prometheus-exporter-password
            resources:
              limits:
                memory: 320Mi
            volumeMounts:
            - name: mariadb-config 
              subPath: my.cnf
              mountPath: /etc/mysql/my.cnf
            - name: mariadb-config 
              subPath: initdb.sh
              mountPath: /docker-entrypoint-initdb.d/initdb.sh
            - name: mariadb-storage
              mountPath: /var/lib/mysql
          - name: metrics
            image: prom/mysqld-exporter:v0.18.0
            ports:
            - containerPort: 9104
            args:
            - --collect.info_schema.tables
            - --collect.info_schema.innodb_tablespaces
            - --collect.info_schema.innodb_metrics
            - --collect.global_status
            - --collect.global_variables
            - --collect.slave_status
            - --collect.info_schema.processlist
            - --collect.perf_schema.tablelocks
            - --collect.perf_schema.eventsstatements
            - --collect.perf_schema.eventsstatementssum
            - --collect.perf_schema.eventswaits
            - --collect.auto_increment.columns
            - --collect.binlog_size
            - --collect.perf_schema.tableiowaits
            - --collect.perf_schema.indexiowaits
            - --collect.info_schema.userstats
            - --collect.info_schema.clientstats
            - --collect.info_schema.tablestats
            - --collect.info_schema.schemastats
            - --collect.perf_schema.file_events
            - --collect.perf_schema.file_instances
            - --collect.perf_schema.replication_group_member_stats
            - --collect.perf_schema.replication_applier_status_by_worker
            - --collect.slave_hosts
            - --collect.info_schema.innodb_cmp
            - --collect.info_schema.innodb_cmpmem
            - --collect.info_schema.query_response_time
            - --collect.engine_tokudb_status
            - --collect.engine_innodb_status
            env:
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: prometheus-exporter-username
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: prometheus-exporter-password
            - name: DATA_SOURCE_NAME
              value: "$(MARIADB_PROMETHEUS_EXPORTER_USERNAME):$(MARIADB_PROMETHEUS_EXPORTER_PASSWORD)@(localhost:3306)/"
            resources:
              limits:
                memory: 32Mi
          volumes:
          - name: mariadb-config
            configMap:
              name: db-mariadb
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: my.cnf
                path: my.cnf
          - name: mariadb-storage
            persistentVolumeClaim:
              claimName: db-mariadb
    ~~~

    If you compare this `StatefulSet` [with the Valkey's `Deployment` of the previous chapter](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-deployment-resource) you will find many similarities, but also several differences:

    - `serviceName`\
      Links this `StatefulSet` to a `Service`.

      > [!IMPORTANT]
      > A `StatefulSet` can only be linked to an **already existing** `Service`.

    - `template.spec.containers`\
      Like in the Valkey case, two containers are set in the pod as sidecars.

      - Container `server` holds the MariaDB server instance:

        - The `image` of MariaDB here is based on the [Noble Numbat version (24.04 LTS) of Ubuntu](https://releases.ubuntu.com/noble/).

        - The `env` section contains several environment parameters. The ones with the `MYSQL_` prefix are directly recognized by the MariaDB server. The `MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD` are meant only for the `initdb.sh` initializer script. Notice how the values of these environment parameters are taken from a `db-mariadb` secret and a `db-mariadb` config map you'll declare later.

        - The `volumeMounts` contains three mount points.

          - MountPath `/etc/mysql/my.cnf`\
            The default path where MariaDB has its `my.cnf` file. This `my.cnf` file is the one you created before, and you'll load it later in the `db-mariadb` config map resource.

          - MountPath `/docker-entrypoint-initdb.d/initdb.sh`\
            The path `/docker-entrypoint-initdb.d` is a special one within the MariaDB container, prepared to execute (in alphabetical order) any shell or SQL scripts you put in here just the **first time** this container is executed. This way you can initialize databases or create extra users, as your `initdb.sh` script does. You'll also include `initdb.sh` in the `db-mariadb` config map resource.

          - MountPath `/var/lib/mysql`\
            This is the default data folder of MariaDB. It is where the volume `mariadb-storage`'s filesystem will be mounted into.

      - Container `metrics` is for the Prometheus metrics exporter service related to the MariaDB server:

        - The `image` of this exporter is not clear [on what Linux Distribution is based](https://hub.docker.com/r/prom/mysqld-exporter), although probably is Debian.

        - In `args` are set a number of parameters meant for the command launching the service in the container.

        - In `env` you have the environment parameters `MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD` you already saw in the definition of the MariaDB container.

          They are defined here so the next environment parameter, `DATA_SOURCE_NAME`, can use them. This last parameter is required for the Prometheus metrics exporter service to connect to the MariaDB instance with its own user (the one created by the `initdb.sh` script that initializes MariaDB). Also see how the URL it connects to is `localhost:3306`, because the two containers are running in the same pod.

    - `template.spec.volumes`\
      Declares the storage volumes to be used in the pod described in this template:

      - With name `mariadb-config`\
        The `my.cnf` and `initdb.sh` files are enabled here as volumes. The files will have the permission mode `644` by default in the container that mounts them.

      - With name `mariadb-storage`\
        The `PersistentVolumeClaim` named `db-mariadb` is enabled as a volume called `mariadb-storage`.

## MariaDB Service resource

The previous `StatefulSet` requires a `Service` named `db-mariadb` to run, so you need to declare it:

1. Create a file named `db-mariadb.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.service.yaml
    ~~~

2. Declare the `Service` exposing your Seafile's MariaDB instance in `db-mariadb.service.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: db-mariadb
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9104"
    spec:
      type: ClusterIP
      clusterIP: 10.43.100.3
      ports:
      - port: 3306
        protocol: TCP
        name: server
      - port: 9104
        protocol: TCP
        name: metrics
    ~~~

    The main details to notice in this `Service` declaration is that the cluster IP is the one chosen beforehand and the `port` numbers correspond with the ones configured as `containerPorts` in the MariaDB's `StatefulSet`.

## MariaDB Kustomize project

Now you have to create the main `kustomization.yaml` file describing your Seafile MariaDB Kustomize project:

1. Under `db-mariadb`, create a `kustomization.yaml` file.

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/db-mariadb/kustomization.yaml
    ~~~

2. Declare the `Kustomization` for your Seafile's MariaDB instance in `kustomization.yaml`:

    ~~~yaml
    # Seafile MariaDB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app: db-mariadb
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/db-mariadb.persistentvolumeclaim.yaml
    - resources/db-mariadb.service.yaml
    - resources/db-mariadb.statefulset.yaml

    replicas:
    - name: db-mariadb
      count: 1

    images:
    - name: mariadb
      newTag: 11.8-noble
    - name: prom/mysqld-exporter
      newTag: v0.18.0

    configMapGenerator:
    - name: db-mariadb
      envs:
      - configs/dbnames.properties
      files:
      - configs/initdb.sh
      - configs/my.cnf

    secretGenerator:
    - name: db-mariadb
      envs:
      - secrets/dbusers.pwd
    ~~~

    This `kustomization.yaml` is very similar to the one you did for the Valkey instance, with the main difference being in the generator sections:

    - The `configMapGenerator` sets up one `ConfigMap` resource called `db-mariadb`. When generated, it will map the two archives specified under `files` and all the key-value pairs included in the file referenced in `envs`.

    - The `secretGenerator` prepares one `Secret` resource named `db-mariadb` that only contains the key-value sets within the file pointed at in its `envs` section.

### Checking the Kustomize YAML output

At this point, you can verify with `kubectl` that the Kustomize project for Seafile's MariaDB in stance gives you the proper YAML output:

1. Execute `kubectl kustomize` and pipe the yaml output on the `less` command or dump it on a file.

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/seafile/components/db-mariadb | less
    ~~~

2. See that your yaml output is like the one below.

    ~~~yaml
    apiVersion: v1
    data:
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
      prometheus-exporter-username: exporter
      seafile-db-name: seafile-db
      seafile-username: seafile
    kind: ConfigMap
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb-dfftc7f67m
    ---
    apiVersion: v1
    data:
      prometheus-exporter-password: |
        bmd1ZXVlaTVpdG52Ym52amhha29hb3BkcGRrY25naGZ1ZXI5MzlrZTIwMm1mbWZ2bHNvc2QwM2Zr
        ZDkyM2zDsQo=
      root-password: |
        MDk0ODM1bXZuYjg5MDM4N212Mmk5M21jam5yamhya3Nkw7Fzb3B3ZWpmZ212eHNvZWRqOTNkam1k
        bDI5ZG1qego=
      seafile-user-password: |
        bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfUzM0ZjFMM191WjNyIQo=
    kind: Secret
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb-gf5d78c5b2
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9104"
        prometheus.io/scrape: "true"
      labels:
        app: db-mariadb
      name: db-mariadb
    spec:
      clusterIP: 10.43.100.3
      ports:
      - name: server
        port: 3306
        protocol: TCP
      - name: metrics
        port: 9104
        protocol: TCP
      selector:
        app: db-mariadb
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 3.5G
      storageClassName: local-path
      volumeName: db-seafile
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: db-mariadb
      serviceName: db-mariadb
      template:
        metadata:
          labels:
            app: db-mariadb
        spec:
          containers:
          - env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  key: seafile-db-name
                  name: db-mariadb-dfftc7f67m
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: root-password
                  name: db-mariadb-gf5d78c5b2
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  key: seafile-username
                  name: db-mariadb-dfftc7f67m
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: seafile-user-password
                  name: db-mariadb-gf5d78c5b2
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-dfftc7f67m
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-gf5d78c5b2
            image: mariadb:11.8-noble
            name: server
            ports:
            - containerPort: 3306
            resources:
              limits:
                memory: 320Mi
            volumeMounts:
            - mountPath: /etc/mysql/my.cnf
              name: mariadb-config
              subPath: my.cnf
            - mountPath: /docker-entrypoint-initdb.d/initdb.sh
              name: mariadb-config
              subPath: initdb.sh
            - mountPath: /var/lib/mysql
              name: mariadb-storage
          - args:
            - --collect.info_schema.tables
            - --collect.info_schema.innodb_tablespaces
            - --collect.info_schema.innodb_metrics
            - --collect.global_status
            - --collect.global_variables
            - --collect.slave_status
            - --collect.info_schema.processlist
            - --collect.perf_schema.tablelocks
            - --collect.perf_schema.eventsstatements
            - --collect.perf_schema.eventsstatementssum
            - --collect.perf_schema.eventswaits
            - --collect.auto_increment.columns
            - --collect.binlog_size
            - --collect.perf_schema.tableiowaits
            - --collect.perf_schema.indexiowaits
            - --collect.info_schema.userstats
            - --collect.info_schema.clientstats
            - --collect.info_schema.tablestats
            - --collect.info_schema.schemastats
            - --collect.perf_schema.file_events
            - --collect.perf_schema.file_instances
            - --collect.perf_schema.replication_group_member_stats
            - --collect.perf_schema.replication_applier_status_by_worker
            - --collect.slave_hosts
            - --collect.info_schema.innodb_cmp
            - --collect.info_schema.innodb_cmpmem
            - --collect.info_schema.query_response_time
            - --collect.engine_tokudb_status
            - --collect.engine_innodb_status
            env:
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-dfftc7f67m
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-gf5d78c5b2
            - name: DATA_SOURCE_NAME
              value: $(MARIADB_PROMETHEUS_EXPORTER_USERNAME):$(MARIADB_PROMETHEUS_EXPORTER_PASSWORD)@(localhost:3306)/
            image: prom/mysqld-exporter:v0.18.0
            name: metrics
            ports:
            - containerPort: 9104
            resources:
              limits:
                memory: 32Mi
          volumes:
          - configMap:
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: my.cnf
                path: my.cnf
              name: db-mariadb-dfftc7f67m
            name: mariadb-config
          - name: mariadb-storage
            persistentVolumeClaim:
              claimName: db-mariadb
    ~~~

    Pay particular attention to the `ConfigMap` and `Secret` resources declared in the output.

    - Their names have a hash as a suffix appended to their names.

    - The `db-mariadb` config map has the `initdb.sh` and `my.cnf` loaded in it (filenames as keys and their full contents as values), and the key-value pairs found in `dbnames.properties` are set independently.

    - The `db-mariadb` secret has all the key-value pairs set in the `dbusers.pwd` but with the particularity that the values have been automatically encoded in base64.

3. Remember that, if you dumped the Kustomize output into a YAML file, you can validate it with `kubeconform`.

## Do not deploy this MariaDB project on its own

This MariaDB setup is missing one critical element, the persistent volume it needs to store data and which you must not confuse with the claim you've configured for your MariaDB server. That PV and other elements will be declared in the main Kustomize project you will declare in the final part of this Seafile deployment procedure. Till then, do not deploy this MariaDB subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/seafile/components/db-mariadb`
- `$HOME/k8sprjs/seafile/components/db-mariadb/configs`
- `$HOME/k8sprjs/seafile/components/db-mariadb/resources`
- `$HOME/k8sprjs/seafile/components/db-mariadb/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/seafile/components/db-mariadb/kustomization.yaml`
- `$HOME/k8sprjs/seafile/components/db-mariadb/configs/dbnames.properties`
- `$HOME/k8sprjs/seafile/components/db-mariadb/configs/initdb.sh`
- `$HOME/k8sprjs/seafile/components/db-mariadb/configs/my.cnf`
- `$HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.service.yaml`
- `$HOME/k8sprjs/seafile/components/db-mariadb/resources/db-mariadb.statefulset.yaml`
- `$HOME/k8sprjs/seafile/components/db-mariadb/secrets/dbusers.pwd`

## References

### [MariaDB](https://mariadb.org)

- [Docker Hub. MariaDB](https://hub.docker.com/_/mariadb)

- [Server Management. Deployment. Configuring MariaDB. Advanced Configuration](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/mariadb-performance-advanced-configurations)
  - [Configuring MariaDB for Optimal Performance](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/mariadb-performance-advanced-configurations/configuring-mariadb-for-optimal-performance)

- [Server Management. Variables and Modes](https://mariadb.com/docs/server/server-management/variables-and-modes)
  - [Server System Variables](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables)

- [Server Usage. Storage Engines. InnoDB](https://mariadb.com/docs/server/server-usage/storage-engines/innodb)
  - [InnoDB Buffer Pool](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-buffer-pool)
  - [InnoDB System Variables](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables)

- [Reference. Data Types. String Data Types. Character Sets and Collations](https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets)
  - [Setting Character Sets and Collations](https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets/setting-character-sets-and-collations)

#### MySQL Server Exporter

- [GitHub. MySQL Server Exporter](https://github.com/prometheus/mysqld_exporter)
- [Docker Hub. MySQL Server Prometheus Exporter](https://hub.docker.com/r/prom/mysqld-exporter)

- [Tencent Cloud. Documentation. Tencent Kubernetes Engine. Practical Tutorial. Monitoring](https://www.tencentcloud.com/document/product/457/38366)
  - [Using Prometheus to Monitor MySQL and MariaDB](https://www.tencentcloud.com/document/product/457/38553)

### [Kubernetes](https://kubernetes.io/docs/)

#### ConfigMaps and Secrets

- [Kubernetes Documentation. Concepts. Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

#### Related contents about ConfigMaps and Secrets

- [OpenSource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### Storage

- [Kubernetes Blog. 2018. Local Persistent Volumes for Kubernetes Goes Beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)

- [Kubernetes Documentation. Concepts. Storage](https://kubernetes.io/docs/concepts/storage/)
  - [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
    - [local](https://kubernetes.io/docs/concepts/storage/volumes/#local)
  - [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
    - [Reserving a PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume)
    - [Reclaiming Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)
  - [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
    - [Local](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)

- [Kubernetes Documentation. Reference. Kubernetes API. Config and Storage Resources](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/)
  - [PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
  - [PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)

#### Related contents about Kubernetes storage

- [Rancher K3s. Add-Ons. Volumes and Storage](https://docs.k3s.io/add-ons/storage)
  - [Setting up the Local Storage Provider](https://docs.k3s.io/add-ons/storage#setting-up-the-local-storage-provider)

- [GitHub. Rancher. Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

- [GitHub. K3s. Issue. Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)

- [StackOverflow. Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)

- [GitHub. Helm. Issue. distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)

#### StatefulSets

- [Kubernetes Documentation. Concepts. Workloads. Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
  - [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### Environment variables

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

## Navigation

[<< Previous (**G033. Deploying services 02. Seafile Part 2**)](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Seafile Part 4**) >>](G033)