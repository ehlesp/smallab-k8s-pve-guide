# G033 - Deploying services 02 ~ Nextcloud - Part 3 - MariaDB database server

The Nextcloud platform needs a database and MariaDB is the database engine chosen for this task.

## MariaDB Kustomize project's folders

Since the MariaDB database is just another component of your Nextcloud platform, you'll have to put its corresponding folders within the `nextcloud/components` path you created already in [the previous Redis guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md).

~~~bash
$ mkdir -p $HOME/k8sprjs/nextcloud/components/db-mariadb/{configs,resources,secrets}
~~~

Like Redis, MariaDB also has configurations, secrets and resources files making up its Kustomize setup.

## MariaDB configuration files

The MariaDB deployment requires a lot of adjustments that have to be handled in configuration files.

### _Configuration file `my.cnf`_

The `my.cnf` is the default configuration file for MariaDB. In it you can adjust many parameters of this database engine, something you'll need to do in this case.

1. Create a `my.cnf` file in the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/configs/my.cnf
    ~~~

2. Edit `my.cnf` to put in it the configuration below.

    ~~~properties
    [server]
    skip_name_resolve = 1
    innodb_buffer_pool_size = 224M
    innodb_flush_log_at_trx_commit = 2
    innodb_log_buffer_size = 32M
    query_cache_type = 1
    query_cache_limit = 2M
    query_cache_min_res_unit = 2k
    query_cache_size = 64M
    slow_query_log = 1
    slow_query_log_file = /var/lib/mysql/slow.log
    long_query_time = 1
    innodb_io_capacity = 2000
    innodb_io_capacity_max = 3000

    [client-server]
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mariadb.conf.d/

    [client]
    default-character-set = utf8mb4

    [mysqld]
    character_set_server = utf8mb4
    collation_server = utf8mb4_general_ci
    transaction_isolation = READ-COMMITTED
    binlog_format = ROW
    log_bin = /var/lib/mysql/mysql-bin.log
    expire_logs_days = 7
    max_binlog_size = 100M
    innodb_file_per_table=1
    innodb_read_only_compressed = OFF
    tmp_table_size= 32M
    max_heap_table_size= 32M
    max_connections=512
    ~~~

    The `my.cnf` above is a modified version of an example found [in the official Nexcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/linux_database_configuration.html#configuring-a-mysql-or-mariadb-database).

    - This configuration fits the requirements of transaction isolation level (`READ-COMMITED`) and binlog format (`ROW`) demanded by Nextcloud.

    - The `innodb_buffer_pool_size` parameter preconfigures the size of the buffer pool in memory, which should have between the 60% and the 80% of the RAM available for MariaDB.

    - The `innodb_io_capacity` and `innodb_io_capacity_max` parameters are related to the I/O capacity of the underlying storage. Here they've been increased from their default values to fit better the ssd volume used for storing the MariaDB data.

    - The character set configured is `utf8mb4`, which is wider than the regular `utf8` one.

    - Nextcloud uses table compression, but writing in such format comes disabled by default since MariaDB 10.6. To enable it, the `innodb_read_only_compressed` parameter has to be set as `OFF`.

    - With `max_connections`, it limits the maximum connections that can connect to the instance.

### _Properties file `dbnames.properties`_

There are a few names you need to specify in your database setup. Those names are values that you want to load as variables in the server container rather than typing them directly on MariaDB's configuration.

1. Create a `dbnames.properties` file under the `configs` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/configs/dbnames.properties
    ~~~

2. Copy the following parameter lines into `dbnames.properties`.

    ~~~properties
    nextcloud-db-name=nextcloud-db
    nextcloud-username=nextcloud
    prometheus-exporter-username=exporter
    ~~~

    The three key-value pairs above mean the following.

    - `nextcloud-db-name`: name for the Nexcloud's database.
    - `nextcloud-username`: name for the user associated to the Nextcloud's database.
    - `prometheus-exporter-username`: name for the Prometheus metrics exporter user.

### _Initializer shell script `initdb.sh`_

The Prometheus metrics exporter system you'll include in the MariaDB's deployment requires its own user to access certain statistical data from your MariaDB instance. You've already configured its name as a variable in the previous `dbnames.properties` file, but you also need to create the user within the MariaDB installation. The problem is that MariaDB can only create one user in its initial run, and you need also to create the user Nextcloud needs to work with its own database.

To solve this issue, you can use a initializer shell script that creates that extra user you need in the MariaDB database.

1. Create a `initdb.sh` file in the `configs` directory.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/configs/initdb.sh
    ~~~

2. Fill the `initdb.sh` file with the following shell script.

    ~~~bash
    #!/bin/sh
    echo ">>> Creating user for Mysql Prometheus metrics exporter"
    mysql -u root -p$MYSQL_ROOT_PASSWORD --execute \
    "CREATE USER '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PROMETHEUS_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
    GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost';
    FLUSH privileges;"
    ~~~

    See that the script what in fact does is execute some SQL code through a `mysql` command to create the required user. And notice how, instead of putting raw values, environmental variables (`MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD`) are used as placeholders for several values. Those variables will be defined within the Deployment resource definition you'll prepare later in this guide.

## MariaDB passwords

There's a number of passwords you need to set up in the MariaDB installation.

- The MariaDB root user's password.
- The Nextcloud database user's password.
- The Prometheus metrics exporter user's password.

For convenience, let's declare all these passwords as variables in the same properties file, so they can be turned into a Secret resource later.

1. Create a `dbusers.pwd` file under the `secrets` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/secrets/dbusers.pwd
    ~~~

2. Fill `dbusers.pwd` with the following variables.

    ~~~properties
    root-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_rOo7_uZ3r!
    nextcloud-user-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_nEx7k1OuD_uZ3r!
    prometheus-exporter-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_3xP0rTeR_uZ3r!
    ~~~

    The passwords have to be put here as plain unencrypted text, so be careful of who accesses this file.

## MariaDB storage

Storage in Kubernetes has essentially two sides: the enablement of storage as persistent volumes (PVs), and the claims (PVCs) on each of those persistent volumes. For MariaDB you'll need one persistent volume, which you'll declare in the last part of this Nextcloud guide, and the claim on that particular PV.

1. A persistent volume claim is a resource, so create a `db-mariadb.persistentvolumeclaim.yaml` file under the `resources` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml
    ~~~

2. Copy the yaml manifest below into `db-mariadb.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: db-mariadb
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: db-nextcloud
      resources:
        requests:
          storage: 3.5G
    ~~~

    There are a few details to understand from the PVC above.

    - The `spec.accessModes` is specified. This is mandatory in a claim and it cannot demand a mode that's not enabled in the persistent volume itself.

    - The `spec.storageClassName` is a parameter that indicates what storage profile (a particular set of properties) to use with the persistent volume. K3s comes with just the `local-path` included by default, something you can check out on your own K3s cluster with `kubectl`.

        ~~~bash
        $ kubectl get storageclass
        NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
        local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  10d
        ~~~

    - The `spec.volumeName` is the name of the persistent volume, in the same namespace, this claim binds itself to.

    - In a claim is also mandatory to specify how much storage is requested, hence the need to put the `spec.resources.requests.storage` parameter there. Be careful of not requesting more space than what's available in the volume.

    - Needless to say, but the persistent volume related to this claim must correspond to the values set here.

## MariaDB StatefulSet resource

Instead of using a Deployment resource to put MariaDB in your Kubernetes cluster, you'll use a **StatefulSet**. Stateful sets are meant for deploying apps or services that store data (_state_) permanently, as databases such as MariaDB do.

1. Create a `db-mariadb.statefulset.yaml` in the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.statefulset.yaml
    ~~~

2. Put in `db-mariadb.statefulset.yaml` the next resource description.

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
            image: mariadb:10.6-focal
            ports:
            - containerPort: 3306
            env:
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: nextcloud-db-name
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: root-password
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: nextcloud-username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: nextcloud-user-password
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
            image: prom/mysqld-exporter:v0.13.0
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

    If you compare this `StatefulSet` with Redis' `Deployment` you'll find many similarities regarding parameters, but there are also several differences.

    - `serviceName`: links this `StatefulSet` to a `Service`.
        > **BEWARE!**  
        > A `StatefulSet` can only be linked to an **already existing** `Service`.

    - `template.spec.containers`: like in the Redis case, two containers are set in the pod as sidecars.

        - Container `server`: the MariaDB server instance.
            - The `image` of MariaDB here is based on the Focal Fossa version (20.04 LTS) of Ubuntu.
            - The `env` section contains several environment parameters. The ones with the `MYSQL_` prefix are directly recognized by the MariaDB server. The `MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD` are meant only for the `initdb.sh` initializer script. Notice how the values of these environment parameters are taken from a `db-mariadb` secret and a `db-mariadb` config map you'll declare later.
            - The `volumeMounts` contains three mount points.
                - MountPath `/etc/mysql/my.cnf`: the default path where MariaDB has its `my.cnf` file. This `my.cnf` file is the one you created before, and you'll load it later in the `db-mariadb` config map resource.
                - MountPath `/docker-entrypoint-initdb.d/initdb.sh`: the path `/docker-entrypoint-initdb.d` is a special one within the MariaDB container, prepared to execute (in alphabetical order) any shell or SQL scripts you put in here just the **first time** this container is executed. This way you can initialize databases or create extra users, as your `initdb.sh` script does. You'll also include `initdb.sh` in the `db-mariadb` config map resource.
                - MountPath `/var/lib/mysql`: this is the default data folder of MariaDB. It's where the volume `mariadb-storage`'s filesystem will be mounted into.

        - Container `metrics`: the Prometheus metrics exporter service related to the MariaDB server.
            - The `image` of this exporter is not clear [on what Linux Distribution is based](https://hub.docker.com/r/prom/mysqld-exporter), although probably is Debian.
            - In `args` are set a number of parameters meant for the command launching the service in the container.
            - In `env` you have the environment parameters `MARIADB_PROMETHEUS_EXPORTER_USERNAME` and `MARIADB_PROMETHEUS_EXPORTER_PASSWORD` you already saw in the definition of the MariaDB container. They're defined here so the next environment parameter, `DATA_SOURCE_NAME`, can use them. This last parameter is required for this Prometheus metrics service to connect to the MariaDB instance with its own user (the one created by the `initdb.sh` script that initializes MariaDB). Also see how the URL it connects to is `localhost:3306`, because the two containers are running in the same pod.

    - `template.spec.volumes`: sets the storage volumes that are to be used in the pod described in this template.
        - With name `mariadb-config`: the `my.cnf` and `initdb.sh` files are enabled here as volumes. The files will have the permission mode `644` by default in the container that mounts them.
        - With name `mariadb-storage`: here the `PersistentVolumeClaim` named `db-mariadb` is enabled as a volume called `mariadb-storage`.

## MariaDB Service resource

The previous `StatefulSet` requires a `Service` named `db-mariadb` to run, so you need to declare it.

1. Create a file named `db-mariadb.service.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.service.yaml
    ~~~

2. Edit `db-mariadb.service.yaml` and put the following yaml in it.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9104"
      name: db-mariadb
    spec:
      type: ClusterIP
      clusterIP: 10.43.100.2
      ports:
      - port: 3306
        protocol: TCP
        name: server
      - port: 9104
        protocol: TCP
        name: metrics
    ~~~

    The main things to notice here is that the cluster IP is the one you've chosen beforehand and the `port` numbers correspond with the ones configured as `containerPorts` in the MariaDB's `StatefulSet`.

## MariaDB Kustomize project

Now you have to create the main `kustomization.yaml` file describing your MariaDB Kustomize project.

1. Under `db-mariadb`, create a `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/db-mariadb/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the yaml definition below.

    ~~~yaml
    # MariaDB setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: db-mariadb

    resources:
    - resources/db-mariadb.persistentvolumeclaim.yaml
    - resources/db-mariadb.service.yaml
    - resources/db-mariadb.statefulset.yaml

    replicas:
    - name: db-mariadb
      count: 1

    images:
    - name: mariadb
      newTag: 10.6-focal
    - name: prom/mysqld-exporter
      newTag: v0.13.0

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

    This `kustomization.yaml` is very similar to the one you did for Redis, with the main difference being in the generator sections.

    - The `configMapGenerator` sets up one `ConfigMap` resource called `db-mariadb`. When generated, it'll contain the two archives specified under `files` and all the key-value pairs included in the file referenced in `envs`.

    - The `secretGenerator` prepares one `Secret` resource named `db-mariadb` that only contains the key-value sets within the file pointed at in the `envs` section.

### _Checking the Kustomize yaml output_

At this point, you can verify with `kubectl` that the Kustomize project for MariaDB gives you the proper yaml output.

1. Execute `kubectl kustomize` and pipe the yaml output on the `less` command or dump it on a file.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/db-mariadb | less
    ~~~

2. See that your yaml output is like the one below.

    ~~~yaml
    apiVersion: v1
    data:
      initdb.sh: |
        #!/bin/sh
        echo ">>> Creating user for Mysql Prometheus metrics exporter"
        mysql -u root -p$MYSQL_ROOT_PASSWORD --execute \
        "CREATE USER '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_PROMETHEUS_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
        GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MARIADB_PROMETHEUS_EXPORTER_USERNAME}'@'localhost';
        FLUSH privileges;"
      my.cnf: |
        [server]
        skip_name_resolve = 1
        innodb_buffer_pool_size = 224M
        innodb_flush_log_at_trx_commit = 2
        innodb_log_buffer_size = 32M
        query_cache_type = 1
        query_cache_limit = 2M
        query_cache_min_res_unit = 2k
        query_cache_size = 64M
        slow_query_log = 1
        slow_query_log_file = /var/lib/mysql/slow.log
        long_query_time = 1
        innodb_io_capacity = 2000
        innodb_io_capacity_max = 3000

        [client-server]
        !includedir /etc/mysql/conf.d/
        !includedir /etc/mysql/mariadb.conf.d/

        [client]
        default-character-set = utf8mb4

        [mysqld]
        character_set_server = utf8mb4
        collation_server = utf8mb4_general_ci
        transaction_isolation = READ-COMMITTED
        binlog_format = ROW
        log_bin = /var/lib/mysql/mysql-bin.log
        expire_logs_days = 7
        max_binlog_size = 100M
        innodb_file_per_table=1
        innodb_read_only_compressed = OFF
        tmp_table_size= 32M
        max_heap_table_size= 32M
        max_connections=512
      nextcloud-db-name: nextcloud-db
      nextcloud-username: nextcloud
      prometheus-exporter-username: exporter
    kind: ConfigMap
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb-88gc2m5h46
    ---
    apiVersion: v1
    data:
      nextcloud-user-password: |
        cTQ4OXE1NjlnYWRmamzDsWtqcXdpb2VrbnZrbG5rd2VvbG12bGtqYcOxc2RnYWlvcGgyYXNkZmFz
        a2RrbmZnbDIK
      prometheus-exporter-password: |
        bmd1ZXVlaTVpdG52Ym52amhha29hb3BkcGRrY25naGZ1ZXI5MzlrZTIwMm1mbWZ2bHNvc2QwM2Zr
        ZDkyM2zDsQo=
      root-password: |
        MDk0ODM1bXZuYjg5MDM4N212Mmk5M21jam5yamhya3Nkw7Fzb3B3ZWpmZ212eHNvZWRqOTNkam1k
        bDI5ZG1qego=
    kind: Secret
    metadata:
      labels:
        app: db-mariadb
      name: db-mariadb-dg5cm45947
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
      clusterIP: 10.43.100.2
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
      volumeName: db-nextcloud
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
                  key: nextcloud-db-name
                  name: db-mariadb-88gc2m5h46
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: root-password
                  name: db-mariadb-dg5cm45947
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-username
                  name: db-mariadb-88gc2m5h46
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: nextcloud-user-password
                  name: db-mariadb-dg5cm45947
            - name: MARIADB_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-mariadb-88gc2m5h46
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-dg5cm45947
            image: mariadb:10.6-focal
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
                  name: db-mariadb-88gc2m5h46
            - name: MARIADB_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-mariadb-dg5cm45947
            - name: DATA_SOURCE_NAME
              value: $(MARIADB_PROMETHEUS_EXPORTER_USERNAME):$(MARIADB_PROMETHEUS_EXPORTER_PASSWORD)@(localhost:3306)/
            image: prom/mysqld-exporter:v0.13.0
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
              name: db-mariadb-88gc2m5h46
            name: mariadb-config
          - name: mariadb-storage
            persistentVolumeClaim:
              claimName: db-mariadb
    ~~~

    Pay particular attention to the `ConfigMap` and `Secret` resources declared in the output.

    - Their names have a hash as a suffix appended to their names.

    - The `db-mariadb` config map has the `initdb.sh` and `my.cnf` loaded in it (filenames as keys and their full contents as values), and the key-value pairs found in `dbnames.properties` are set independently.

    - The `db-mariadb` secret has all the key-value pairs set in the `dbusers.pwd` but with the particularity that the values have been automatically encoded in base64.

3. Remember that, if you dumped the Kustomize output into a yaml file, you can validate it with `kubeval`.

## Don't deploy this MariaDB project on its own

This MariaDB setup is missing one critical element, the persistent volume it needs to store data and which you must not confuse with the claim you've configured for your MariaDB server. That PV and other elements will be declared in the main Kustomize project you'll prepare in the final part of this guide. Till then, don't deploy this setup of MariaDB.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/db-mariadb`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/configs`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/resources`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/secrets`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/db-mariadb/kustomization.yaml`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/configs/dbnames.properties`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/configs/initdb.sh`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/configs/my.cnf`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.service.yaml`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/resources/db-mariadb.statefulset.yaml`
- `$HOME/k8sprjs/nextcloud/components/db-mariadb/secrets/dbusers.pwd`

## References

### _Kubernetes_

#### **ConfigMaps and secrets**

- [Official Doc - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Official Doc - Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [Kubernetes ConfigMaps and Secrets](https://shravan-kuchkula.github.io/kubernetes/configmaps-secrets/)
- [Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### **Storage**

- [Official Doc - Local Storage Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)
- [Official Doc - Local Persistent Volumes for Kubernetes Goes Beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)
- [Official Doc - Reserving a PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume)
- [Official Doc - Local StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)
- [Official Doc - Reclaiming Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)
- [Kubernetes API - PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
- [Kubernetes API - PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)
- [Kubernetes Persistent Volumes, Claims, Storage Classes, and More](https://cloud.netapp.com/blog/kubernetes-persistent-storage-why-where-and-how)
- [Rancher K3s - Setting up the Local Storage Provider](https://rancher.com/docs/k3s/latest/en/storage/)
- [K3s local path provisioner on GitHub](https://github.com/rancher/local-path-provisioner)
- [Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)
- [Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)
- [distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)
- [Kubernetes Mounting Volumes in Pods. Mount Path Ownership and Permissions](https://kb.novaordis.com/index.php/Kubernetes_Mounting_Volumes_in_Pods#Mount_Path_Ownership_and_Permissions)

#### **StatefulSets**

- [Official Doc](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### **Environment variables**

- [Official Doc - Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [Official Doc - Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)

### _MariaDB_

- [MariaDB](https://mariadb.com/)
- [MariaDB on DockerHub](https://hub.docker.com/_/mariadb?tab=description&page=1&ordering=last_updated)
- [MySQL Server Exporter on GitHub](https://github.com/prometheus/mysqld_exporter)
- [MySQL Server Prometheus Exporter](https://hub.docker.com/r/prom/mysqld-exporter)
- [Using Prometheus to Monitor MySQL and MariaDB](https://intl.cloud.tencent.com/document/product/457/38553)
- [Server System Variables](https://mariadb.com/kb/en/server-system-variables/)
- [Configuring MariaDB with Option Files](https://mariadb.com/kb/en/configuring-mariadb-with-option-files/)
- [Add another user to MySQL in Kubernetes](https://stackoverflow.com/questions/50373869/add-another-user-to-mysql-in-kubernetes)
- [Initialize a fresh instance of Mariadb](https://github.com/helm/charts/issues/13122)
- [using environment variables in docker-compose mounted files for initializing mysql](https://stackoverflow.com/questions/68411534/using-environment-variables-in-docker-compose-mounted-files-for-initializing-mys)
- [How to initialize mysql container when created on Kubernetes?](https://stackoverflow.com/questions/45681780/how-to-initialize-mysql-container-when-created-on-kubernetes)
- [import mysql data to kubernetes pod](https://stackoverflow.com/questions/40166149/import-mysql-data-to-kubernetes-pod/50877213#50877213)
- [Binary Log Formats](https://mariadb.com/kb/en/binary-log-formats/)
- [How to Enable and Use Binary Log in MySQL/MariaDB](https://snapshooter.com/learn/mysql/enable-and-use-binary-log-mysql)
- [How to Change a Default MySQL/MariaDB Data Directory in Linux](https://www.tecmint.com/change-default-mysql-mariadb-data-directory-in-linux/)
- [`mysql` Command-line Client](https://mariadb.com/kb/en/mysql-command-line-client/)
- [How to see/get a list of MySQL/MariaDB users accounts](https://www.cyberciti.biz/faq/how-to-show-list-users-in-a-mysql-mariadb-database/)
- [Introduction to four key MariaDB client commands](https://mariadb.com/resources/blog/introduction-to-four-key-mariadb-client-commands/)
- [How to fix Nextcloud 4047 InnoDB refuses to write tables with ROW_FORMAT=COMPRESSED or KEY_BLOCK_SIZE](https://techoverflow.net/2021/08/17/how-to-fix-nextcloud-4047-innodb-refuses-to-write-tables-with-row_formatcompressed-or-key_block_size/)
- [Mariadb 10.6 won't allow writing in compressed innodb by default](https://myhub.eu.org/article/16/mariadb-10-6-wont-allow-writing-in-compressed-innodb-by-default/)
- [Configuring MariaDB for Optimal Performance](https://mariadb.com/kb/en/configuring-mariadb-for-optimal-performance/)
- [15 Useful MySQL/MariaDB Performance Tuning and Optimization Tips](https://www.tecmint.com/mysql-mariadb-performance-tuning-and-optimization/)
- [Analyze MySQL Performance](http://mysql.rjweb.org/doc.php/mysql_analysis)
- [Setup innodb_io_capacity](https://dba.stackexchange.com/questions/258931/setup-innodb-io-capacity)

### _Nextcloud_

- [Database configuration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/linux_database_configuration.html)

## Navigation

[<< Previous (**G033. Deploying services 02. Nextcloud Part 2**)](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Nextcloud Part 4**) >>](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md)
