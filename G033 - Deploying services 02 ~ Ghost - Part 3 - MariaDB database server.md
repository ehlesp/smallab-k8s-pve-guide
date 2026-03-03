# G033 - Deploying services 02 ~ Ghost - Part 3 - MariaDB database server

- [You can use MariaDB instead of MySQL as database server for Ghost](#you-can-use-mariadb-instead-of-mysql-as-database-server-for-ghost)
- [MariaDB Kustomize subproject's folders](#mariadb-kustomize-subprojects-folders)
- [MariaDB configuration files](#mariadb-configuration-files)
  - [Configuration file `my.cnf`](#configuration-file-mycnf)
  - [Properties file `dbnames.properties`](#properties-file-dbnamesproperties)
  - [Initializer shell script `initdb.sh`](#initializer-shell-script-initdbsh)
- [MariaDB passwords](#mariadb-passwords)
- [MariaDB persistent storage claim](#mariadb-persistent-storage-claim)
- [MariaDB StatefulSet](#mariadb-statefulset)
- [MariaDB Service](#mariadb-service)
  - [MariaDB Service's FQDN](#mariadb-services-fqdn)
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
    - [ConfigMaps](#configmaps)
    - [Storage](#storage)
    - [StatefulSets](#statefulsets)
    - [Environment variables](#environment-variables)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
    - [About Kubernetes storage](#about-kubernetes-storage)
    - [About ConfigMaps and Secrets](#about-configmaps-and-secrets)
- [Navigation](#navigation)

## You can use MariaDB instead of MySQL as database server for Ghost

Ghost indicates in its official documentation to use [MySQL](https://www.mysql.com/), but [MariaDB](https://mariadb.com/) is a perfectly compatible and open source alternative you can use as Ghost's database.

## MariaDB Kustomize subproject's folders

Since the MariaDB database is just another component of your Ghost platform, you have to put its corresponding folders within the `ghost/components` path you already created in [the previous chapter about the Valkey cache server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#kustomize-project-folders-for-ghost-and-valkey).

~~~sh
$ mkdir -p $HOME/k8sprjs/ghost/components/db-mariadb/{configs,resources,secrets}
~~~

Like the Valkey server, MariaDB also has configurations, secrets and resources in its Kustomize setup.

## MariaDB configuration files

The MariaDB deployment requires a number of adjustments that are better handled in different configuration files.

### Configuration file `my.cnf`

The `my.cnf` file is the default configuration file for MariaDB, where you can adjust its parameters to better fit your setup:

1. Create a `my.cnf` file in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/configs/my.cnf
    ~~~

2. Set the following configuration in your `configs/my.cnf` file:

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

    - The [`skip_name_resolve`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#skip_name_resolve) forces MariaDB to use only IPs for connections, avoiding wasting time in resolving hostnames first. Since MariaDB is going to be served through a Kubernetes `Service` object, the name resolution is handled by the K3s cluster itself thanks to its CoreDNS service. Ghost will call that MariaDB `Service` to use its database.

    - The values set in the [`max_connections`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#max_connections) and [`thread_cache_size`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#thread_cache_size) parameters are considered for a low usage scenario where just a very small number of clients are expected to access the database.

    - The character set `utf8mb4` specified in the `default-character-set`, [`character_set_server`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#character_set_server) and [`collation_server`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#collation_server) parameters is the most adequate one for modern applications like Ghost. The main advantage of `utf8mb4` is that it accommodates a much wider set of characters than `utf8` or others. As a downside, be aware that `utf8mb4` databases take up more storage space since their characters are "bigger".

    - The [`tmp_table_size`](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables#tmp_table_size) limits how large temporary tables can grow in memory.

    - The engine used by default in MariaDB is InnoDB, and has its own set of parameters grouped together in the `my.cnf` file for clarity:

      - The [`innodb_buffer_pool_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_buffer_pool_size) parameter sets the size of the buffer pool in memory, which is recommended to be around the 80% of the memory available for the MariaDB server.

      - The [`innodb_io_capacity`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_io_capacity) and [`innodb_io_capacity_max`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_io_capacity_max) parameters are related to the I/O capacity of the underlying storage. Here they are increased from their default values to fit better the SSD volume used for storing Ghost's MariaDB database.

      - The [`innodb_log_buffer_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_log_buffer_size) parameter affect how MariaDB's redo log feature works. The bigger the buffer, the larger the transactions that MariaDB can execute without hitting storage before committing them.

      - The [`innodb_log_file_size`](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables#innodb_log_file_size) limits the size of MariaDB's redo log file.

### Properties file `dbnames.properties`

There are a few names you need to specify in your database setup. Those names are values that are better loaded as variables in your MariaDB server container rather than being hardcoded in the MariaDB server configuration:

1. Create a `dbnames.properties` file under the `configs` path:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/configs/dbnames.properties
    ~~~

2. Copy the following parameter lines into `configs/dbnames.properties`:

    ~~~properties
    ghost-db-name=ghost-db
    ghost-username=ghostdb
    prometheus-exporter-username=promexp
    ~~~

    The three key-value pairs above mean this:

    - `ghost-db-name`\
      Name for the Ghost database.

    - `ghost-username`:\
      Name for the user associated to the Ghost database.

    - `prometheus-exporter-username`\
      Name for the Prometheus metrics exporter user.

### Initializer shell script `initdb.sh`

The Prometheus metrics exporter system you are going to include in your MariaDB server deployment requires its own user to access certain statistical data from the MariaDB instance. You have already configured its name as a variable in the previous `dbnames.properties` file, but you also need to create the user within the MariaDB installation. The problem is that MariaDB can only create one user in its initial run, but you also have to create the user Ghost needs to work with its own database.

To solve this conflict, you can use a initializer shell script that creates that extra user you need in the MariaDB database:

1. Create a `initdb.sh` file in the `configs` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/configs/initdb.sh
    ~~~

2. Fill the `configs/initdb.sh` file with the following shell script:

    ~~~sh
    #!/bin/sh
    echo ">>> Creating user for MariaDB Prometheus metrics exporter"
    mysql -u root -p$MYSQL_ROOT_PASSWORD --execute \
    "CREATE USER '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PROMETHEUS_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
    GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost';
    FLUSH privileges;"
    ~~~

    This is an SQL script, executed by a MariaDB-provided `mysql` shell command, that creates the required user for the Prometheus metrics exporter. Notice how, instead of putting raw values, environment variables (`MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD`) are used as placeholders for the username and password values for the Prometheus metrics exporter's user. Those variables are to be declared within the `StatefulSet` resource manifest you will declare later in this chapter.

## MariaDB passwords

There is a number of passwords you need to set up in the MariaDB installation:

- For the MariaDB root user.
- For the Ghost database user.
- For the Prometheus metrics exporter user.

For convenience, declare all of these passwords as variables in the same properties file, so they can be turned into a `Secret` resource later:

1. Create a `dbusers.pwd` file under the `secrets` path:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/secrets/dbusers.pwd
    ~~~

2. Specify your passwords as key-value pairs in `secrets/dbusers.pwd`:

    ~~~properties
    root-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_rOo7_uZ3r!
    ghost-user-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_6h0sT_uZ3r!
    prometheus-exporter-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_3xP0rTeR_uZ3r!
    ~~~

    > [!WARNING]
    > **The passwords have to be put in `dbusers.pwd` as plain unencrypted text**\
    > Be careful of who can access this `dbusers.pwd` file.

## MariaDB persistent storage claim

[As you saw when declaring Valkey's storage](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-storage), you need to declare a `PersistentVolumeClaim` to enable access to the persistent volume (to be declared in the last part of this Ghost deployment procedure) storing the MariaDB instance's data:

1. Create a `db-mariadb.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml
    ~~~

2. Declare Ghost's `PersistentVolumeClaim` in the `resources/db-mariadb.persistentvolumeclaim.yaml` file:

    ~~~yaml
    # Ghost MariaDB claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: db-mariadb
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: ghost-ssd-db
      resources:
        requests:
          storage: 6.5G
    ~~~

    This persistent volume claim is exactly like the one for the Valkey server, although with its own `metadata.name`, different claimed volume in `spec.volumeName` and adjusted capacity in `spec.resources.requests.storage`.

## MariaDB StatefulSet

Since MariaDB is a program whose main purpose is to store _state_ (meaning data), its deployment must be declared as a `StatefulSet`:

1. Create a `db-mariadb.statefulset.yaml` in the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for your Ghost's MariaDB server in `resources/db-mariadb.statefulset.yaml`:

    ~~~yaml
    # Ghost MariaDB StatefulSet for a sidecar server pod
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
            - name: server
              containerPort: 3306
            env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb-config
                  key: ghost-db-name
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb-passwords
                  key: root-password
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb-config
                  key: ghost-username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb-passwords
                  key: ghost-user-password
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb-config
                  key: prometheus-exporter-username
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb-passwords
                  key: prometheus-exporter-password
            resources:
              requests:
                cpu: "0.75"
                memory: 256Mi
            volumeMounts:
            - name: mariadb-config 
              subPath: my.cnf
              mountPath: /etc/mysql/my.cnf
              readOnly: true
            - name: mariadb-config 
              subPath: initdb.sh
              mountPath: /docker-entrypoint-initdb.d/initdb.sh
              readOnly: true
            - name: mariadb-storage
              mountPath: /var/lib/mysql
          - name: metrics
            image: prom/mysqld-exporter:v0.18.0
            ports:
            - name: metrics
              containerPort: 9104
            args:
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
                  name: db-mariadb-config
                  key: prometheus-exporter-username
            - name: MYSQLD_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb-passwords
                  key: prometheus-exporter-password
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
          volumes:
          - name: mariadb-storage
            persistentVolumeClaim:
              claimName: db-mariadb
          - name: mariadb-config
            configMap:
              name: db-mariadb-config
              defaultMode: 444
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: my.cnf
                path: my.cnf
    ~~~

    If you compare this `StatefulSet` [with Valkey's](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-statefulset-resource) you will find many similarities, but also several differences:

    - `template.spec.containers`\
      Like in the Valkey case, two containers are set in the pod as sidecars.

      - Container `server` holds the MariaDB server instance:

        - The `image` of MariaDB here is based on the [Noble Numbat version (24.04 LTS) of Ubuntu](https://releases.ubuntu.com/noble/).

        - The `env` section contains several environment parameters. The ones with the `MYSQL_` prefix are directly recognized by the MariaDB server. The `MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD` are meant only for the `initdb.sh` initializer script. Notice how the values of these environment parameters are taken from a `db-mariadb-password` secret and a `db-mariadb-config` config map you will declare later in the corresponding Kustomize declaration for this MariaDB subproject.

        - The `volumeMounts` contains three mount points:

          - MountPath `/etc/mysql/my.cnf`\
            The default path where MariaDB has its `my.cnf` file. This `my.cnf` file is the one you created before, and you will put it later in the `db-mariadb` config map resource.

          - MountPath `/docker-entrypoint-initdb.d/initdb.sh`\
            The path `/docker-entrypoint-initdb.d` is a special one within the MariaDB container, prepared to execute (in alphabetical order) any shell or SQL scripts you put in here just the first time this container is executed. This way you can initialize databases or create extra users, as your `initdb.sh` script does. You will also include `initdb.sh` in the `db-mariadb` config map resource.

          - MountPath `/var/lib/mysql`\
            This is the default data folder of MariaDB. It is where the volume `mariadb-storage`'s filesystem is going to be mounted into.

      - Container `metrics` is for the Prometheus metrics exporter service related to the MariaDB server:

        - The `image` of this metrics exporter service does not clearly states [what Linux distribution is based on](https://hub.docker.com/r/prom/mysqld-exporter).

        - In `args` are set a number of parameters meant for the command launching the Prometheus metrics exporter service in the container. Pay attention to the last two arguments:

          - `mysqld.address` indicates the URL and port of the MariaDB server instance to the Prometheus metrics exporter. In this case, it specifies the default address for clarity.

          - `mysqld.username` is for specifying the username the exporter has to use to connect with the MariaDB instance. Here, its value is provided by the `MARIADB_PROMETHEUS_EXPORTER_USERNAME` environment variable **declared in the `env` section of this `metrics` container**, not by the one set in the previous `server` container. They have the same name just because their purpose also happens to be the same, although in different containers.

        - In the `env` list you have two environment variables. On one hand, the `MARIADB_PROMETHEUS_EXPORTER_USERNAME`, already explained in the description of the `mysqld.username` argument. On the other, the  `MYSQLD_EXPORTER_PASSWORD` is the environment parameter where the Prometheus metrics exporter expects to find its MariaDB user's password.

    - `template.spec.volumes`\
      Declares the storage volumes to be used in the pod described in this template:

      - With name `mariadb-storage`\
        The `PersistentVolumeClaim` named `db-mariadb` is enabled as a volume called `mariadb-storage`.

      - With name `mariadb-config`\
        The `my.cnf` and `initdb.sh` files are enabled here as volumes. The files will have the permission mode `444` by default in the container that mounts them.

## MariaDB Service

The previous `StatefulSet` requires a `Service` named `db-mariadb` to run, so you need to declare it:

1. Create a file named `db-mariadb.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.service.yaml
    ~~~

2. Declare the `Service` exposing your Ghost's MariaDB instance in `resources/db-mariadb.service.yaml`:

    ~~~yaml
    # Ghost MariaDB headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: db-mariadb
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9104"
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - port: 3306
        targetPort: server
        protocol: TCP
        name: server
      - port: 9104
        targetPort: metrics
        protocol: TCP
        name: metrics
    ~~~

    See that this `Service` is headless since the `spec.clusterIP` is `None`, implying that you have to call it by its FQDN. Also, this service's `port` numbers correspond with the ones configured as `containerPorts` in the MariaDB's `StatefulSet`, although the `targetPort` parameters makes them independent from the configuration set in the pod's containers.

### MariaDB Service's FQDN

According to what is explained [for the Valkey headless service's FQDN](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-services-fqdn), the absolute FQDN for this MariaDB headless service will be:

~~~txt
db-mariadb.ghost.svc.homelab.cluster.
~~~

Your Ghost platform will invoke its MariaDB service with this absolute FQDN for best performance.

## MariaDB Kustomize project

Now you have to create the main `kustomization.yaml` file describing your Ghost MariaDB Kustomize subproject:

1. Under `db-mariadb`, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/db-mariadb/kustomization.yaml
    ~~~

2. Declare the `Kustomization` for your Ghost's MariaDB instance in `kustomization.yaml`:

    ~~~yaml
    # Ghost MariaDB setup
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
    - name: db-mariadb-config
      envs:
      - configs/dbnames.properties
      files:
      - configs/initdb.sh
      - configs/my.cnf

    secretGenerator:
    - name: db-mariadb-passwords
      envs:
      - secrets/dbusers.pwd
    ~~~

    This `kustomization.yaml` is very similar to the one you did for the Valkey instance, with the main difference being in the generator sections:

    - The `configMapGenerator` sets up one `ConfigMap` resource called `db-mariadb-config`. When generated, it will map the two archives specified under `files` and all the key-value pairs included in the file referenced in `envs`.

    - The `secretGenerator` prepares one `Secret` resource named `db-mariadb-passwords` that only contains the key-value sets within the file pointed at in its `envs` section.

### Checking the Kustomize YAML output

At this point, you can verify with `kubectl` that the Kustomize project for Ghost's MariaDB in stance gives you the proper YAML output:

1. Execute `kubectl kustomize` and pipe the YAML output to the `less` command or other text editor, or dump it into a file:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/ghost/components/db-mariadb | less
    ~~~

2. Check if your Kustomize YAML output is like the one below:

    ~~~yaml
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
      name: db-mariadb-config-t9c84t7h62
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
      name: db-mariadb-passwords-dtt9d6h2b9
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
          storage: 6.5G
      storageClassName: local-path
      volumeName: ghost-ssd-db
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
                  key: ghost-db-name
                  name: db-mariadb-config-t9c84t7h62
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: root-password
                  name: db-mariadb-passwords-dtt9d6h2b9
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  key: ghost-username
                  name: db-mariadb-config-t9c84t7h62
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: ghost-user-password
                  name: db-mariadb-passwords-dtt9d6h2b9
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-config-t9c84t7h62
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-passwords-dtt9d6h2b9
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
                  name: db-mariadb-passwords-dtt9d6h2b9
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
              defaultMode: 444
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: my.cnf
                path: my.cnf
              name: db-mariadb-config-t9c84t7h62
            name: mariadb-config
    ~~~

    Pay particular attention to the `ConfigMap` and `Secret` resources declared in the output:

    - Their names have a hash as a suffix appended to their names.

    - The `db-mariadb-config` config map has the `initdb.sh` and `my.cnf` loaded in it (filenames as keys and their full contents as values), and the key-value pairs found in `dbnames.properties` are set independently.

    - The `db-mariadb-passwords` secret has the values set in the `dbusers.pwd` file obfuscated in base64 encoding.

3. Remember that, if you dumped the Kustomize output into a YAML file, you can validate it with `kubeconform`.

## Do not deploy this MariaDB project on its own

This MariaDB setup is missing the persistent volume for storing data that you must not confuse with the claim you have configured for your MariaDB server. That PV and other elements are going to be declared in the main Kustomize project you will declare in the final part of this Ghost deployment procedure. Until then, do not deploy this MariaDB subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/db-mariadb`
- `$HOME/k8sprjs/ghost/components/db-mariadb/configs`
- `$HOME/k8sprjs/ghost/components/db-mariadb/resources`
- `$HOME/k8sprjs/ghost/components/db-mariadb/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/db-mariadb/kustomization.yaml`
- `$HOME/k8sprjs/ghost/components/db-mariadb/configs/dbnames.properties`
- `$HOME/k8sprjs/ghost/components/db-mariadb/configs/initdb.sh`
- `$HOME/k8sprjs/ghost/components/db-mariadb/configs/my.cnf`
- `$HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.service.yaml`
- `$HOME/k8sprjs/ghost/components/db-mariadb/resources/db-mariadb.statefulset.yaml`
- `$HOME/k8sprjs/ghost/components/db-mariadb/secrets/dbusers.pwd`

## References

### [MariaDB](https://mariadb.org)

- [MariaDB Server Documentation](https://mariadb.com/docs/server)

  - [Server Management. Deployment. Configuring MariaDB. Advanced Configuration](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/mariadb-performance-advanced-configurations)
    - [Configuring MariaDB for Optimal Performance](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/configuring-mariadb/mariadb-performance-advanced-configurations/configuring-mariadb-for-optimal-performance)

  - [Server Management. Variables and Modes](https://mariadb.com/docs/server/server-management/variables-and-modes)
    - [Server System Variables](https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables)

  - [Server Usage. Storage Engines. InnoDB](https://mariadb.com/docs/server/server-usage/storage-engines/innodb)
    - [InnoDB Buffer Pool](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-buffer-pool)
    - [InnoDB System Variables](https://mariadb.com/docs/server/server-usage/storage-engines/innodb/innodb-system-variables)

  - [Reference. Data Types. String Data Types. Character Sets and Collations](https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets)
    - [Setting Character Sets and Collations](https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets/setting-character-sets-and-collations)

- [Docker Hub. MariaDB](https://hub.docker.com/_/mariadb)

#### MySQL Server Exporter

- [GitHub. MySQL Server Exporter](https://github.com/prometheus/mysqld_exporter)
- [Docker Hub. MySQL Server Prometheus Exporter](https://hub.docker.com/r/prom/mysqld-exporter)

- [Tencent Cloud. Documentation. Tencent Kubernetes Engine. Practical Tutorial. Monitoring](https://www.tencentcloud.com/document/product/457/38366)
  - [Using Prometheus to Monitor MySQL and MariaDB](https://www.tencentcloud.com/document/product/457/38553)

### [Kubernetes](https://kubernetes.io/docs/)

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

#### ConfigMaps

- [Kubernetes Documentation. Concepts. Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

#### Storage

- [Kubernetes Blog. 2018. Local Persistent Volumes for Kubernetes Goes Beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)

- [Kubernetes Documentation. Concepts. Storage](https://kubernetes.io/docs/concepts/storage/)
  - [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
    - [local](https://kubernetes.io/docs/concepts/storage/volumes/#local)
  - [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
    - [Reserving a PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume)
    - [Reclaiming](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)
  - [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
    - [Local](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)

- [Kubernetes Documentation. Reference. Kubernetes API. Config and Storage Resources](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/)
  - [PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
  - [PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)

#### StatefulSets

- [Kubernetes Documentation. Concepts. Workloads. Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
  - [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### Environment variables

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

### Other Kubernetes-related contents

#### About Kubernetes storage

- [Rancher K3s. Add-Ons. Volumes and Storage](https://docs.k3s.io/add-ons/storage)
  - [Setting up the Local Storage Provider](https://docs.k3s.io/add-ons/storage#setting-up-the-local-storage-provider)

- [GitHub. Rancher. Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

- [GitHub. K3s. Issue. Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)

- [StackOverflow. Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)

- [GitHub. Helm. Issue. distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)

#### About ConfigMaps and Secrets

- [OpenSource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

## Navigation

[<< Previous (**G033. Deploying services 02. Ghost Part 2**)](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Ghost Part 4**) >>](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md)
