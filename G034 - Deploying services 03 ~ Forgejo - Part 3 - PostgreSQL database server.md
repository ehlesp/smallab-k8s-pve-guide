# G034 - Deploying services 03 ~ Forgejo - Part 3 - PostgreSQL database server

- [Forgejo can use PostgreSQL as database](#forgejo-can-use-postgresql-as-database)
- [PostgreSQL Kustomize project's folders](#postgresql-kustomize-projects-folders)
- [PostgreSQL configuration files](#postgresql-configuration-files)
  - [Configuration file `postgresql.conf`](#configuration-file-postgresqlconf)
  - [Properties file `dbnames.properties`](#properties-file-dbnamesproperties)
  - [Initializer shell script `initdb.sh`](#initializer-shell-script-initdbsh)
- [PostgreSQL passwords](#postgresql-passwords)
- [PostgreSQL persistent storage claim](#postgresql-persistent-storage-claim)
- [PostgreSQL StatefulSet](#postgresql-statefulset)
- [PostgreSQL Service](#postgresql-service)
  - [Valkey Service's FQDN](#valkey-services-fqdn)
- [PostgreSQL Kustomize project](#postgresql-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this PostgreSQL project on its own](#do-not-deploy-this-postgresql-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [PostgreSQL](#postgresql)
    - [Other PostgreSQL-related contents](#other-postgresql-related-contents)
  - [Kubernetes](#kubernetes)
- [Navigation](#navigation)

## Forgejo can use PostgreSQL as database

Forgejo is compatible with MariaDB but, instead of essentially repeating [the configuration used for the Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md), it is more interesting to show you how similar can be, from a Kubernetes point of view, the configuration of a different database. Therefore, this part explains how to configure the deployment a PostgreSQL instance for your Forgejo platform.

## PostgreSQL Kustomize project's folders

Create the corresponding Kustomize subproject's directory tree for this component of your Forgejo platform.

~~~sh
$ mkdir -p $HOME/k8sprjs/forgejo/components/db-postgresql/{configs,resources,secrets}
~~~

## PostgreSQL configuration files

You need some configuration files where to set certain parameters for PostgreSQL.

### Configuration file `postgresql.conf`

The `postgresql.conf` is where you can set the parameters for PostgreSQL.

1. Create a `postgresql.conf` in the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/configs/postgresql.conf
    ~~~

2. Set the PostgreSQL configuration in `configs/postgresql.conf`:

    ~~~properties
    # Extension libraries loading
    shared_preload_libraries = 'pg_stat_statements'

    # Connection settings
    listen_addresses = '0.0.0.0'
    port = 5432
    max_connections = 100
    superuser_reserved_connections = 3

    # Memory
    shared_buffers = 128MB
    work_mem = 8MB
    hash_mem_multiplier = 2.0
    maintenance_work_mem = 16MB

    # Logging
    log_destination = 'stderr'
    logging_collector = off
    log_min_messages = 'INFO'
    log_error_verbosity = 'DEFAULT'
    log_connections = on
    log_disconnections = on
    log_hostname = off

    # pg_stat_statements extension library
    compute_query_id = on
    pg_stat_statements.max = 10000
    pg_stat_statements.track = all
    ~~~

    The parameters set above mean the following:

    - `shared_preload_libraries`\
      Preloads at server start the listed libraries. In this case, only the [`pg_stat_statements` extension library](https://www.postgresql.org/docs/current/pgstatstatements.html) is preloaded to help in tracking of planning and execution statistics of all SQL statements executed by the PostgreSQL server.

    - `listen_addresses`\
      Indicates which network interfaces this server will listen through. The `0.0.0.0` address makes this PostgreSQL instance listen through all the IPv4 interfaces it has available.

    - `port`\
      Port where the PostgreSQL server listen to requests. Here it has the default value, `5432`.

    - `max_connections`\
      The maximum number of concurrent connections allowed on this PostgreSQL server. Here is set with the default value, `100`.

    - `superuser_reserved_connections`\
      Maximum number of simultaneous connections of PostgreSQL superusers allowed on this server. Set with the default value, `3`.

    - `shared_buffers`\
      How much memory this server can use for shared memory buffers. Here set with the default value, `128MB`.

    - `work_mem`\
      Maximum memory that can be used by a query operation before writing to a temporary disk file. Careful with this value, since it works in tandem with the parameter `hash_mem_multiplier` for hash-based operations.

    - `hash_mem_multiplier`\
      Used to compute the maximum amount of memory that database hash-based operations can use. As it name implies, it multiplies the value in `work_mem` to set the top memory limit for hash-based operations.

    - `maintenance_work_mem`\
      Maximum amount of memory allowed for database maintenance operations. This value can be multiplied by the value of another parameter called `autovacuum_max_workers` when the automatic vacuuming operation is executed.

    - `log_destination`\
      Where you want to dump this server logs. The default value is `stderr`.

    - `logging_collector`\
      A PostgreSQL feature that collects in the background logs dumped in `stderr`. Unless you are specifically saving those logs in files outside the PostgreSQL server container, leave this feature disabled with the `off` value.

    - `log_min_messages`\
      To indicate up to what message level gets printed as server log.

    - `log_error_verbosity`\
      How verbose you want the error messages. Careful with the verbosity, since it can affect your server's performance.

    - `log_connections`\
      For logging the connection attempts to the server.

    - `log_disconnections`\
      Logs the session terminations.

    - `log_hostname`\
      When enabled, the server tries to get the hostname of the IPs connecting to it. That hostname resolution can result in a noticeable performance loss, so it is better to have it disabled.

    - `compute_query_id`\
      Enables in-core computation of a query identifier. Required to be `on` for the `pg_stat_statements` extension.

    - `pg_stat_statements.max`\
      Maximum number of statements tracked by the `pg_stat_statements` extension.

    - `pg_stat_statements.track`\
      Controls which statements are counted by the `pg_stat_statements` module.

    > [!NOTE]
    > **Learn more about these parameters in the PostgreSQL official documentation**\
    > To know more about the parameters above and many others available in PostgreSQL, check the [official documentation about Server Configuration](https://www.postgresql.org/docs/current/runtime-config.html) and [the `pg_stat_statements` module](https://www.postgresql.org/docs/current/pgstatstatements.html).

### Properties file `dbnames.properties`

You need to load in your PostgreSQL container some names as variables. Better keep them all together in a single file which you can load as a `ConfigMap` later:

1. Create a `dbnames.properties` file under the `configs` path:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/configs/dbnames.properties
    ~~~

2. Copy the following parameter lines into `configs/dbnames.properties`:

    ~~~properties
    postgresql-db-name=forgejo_db
    postgresql-superuser-name=postgres
    forgejo-username=forgejodb
    prometheus-exporter-username=prom_metrics
    ~~~

    The key-value pairs above mean the following:

    - `postgresql-db-name`\
      A PostgreSQL server always initializes with an empty database named `postgres`, but you can make the server generate another one if you give it a different name such as `forgejo_db`.

    - `postgresql-superuser-name`\
      The default superuser in a PostgreSQL server is named `postgres`, but you could change it for any other.

    - `forgejo-username`\
      Name of the regular user for Forgejo.

    - `prometheus-exporter-username`\
      Name for the Prometheus metrics exporter user.

    > [!IMPORTANT]
    > **Careful with the characters you use in these names**\
    > Stick to lowercase alphanumeric characters plus the underscore (`_`)  to avoid issues, [in particular with the `initdb.sh` shell script explained next](#initializer-shell-script-initdbsh).

### Initializer shell script `initdb.sh`

You need to initialize your PostgreSQL server with the following:

- A regular user for Forgejo that has all the privileges on the Forgejo database running on your PostgreSQL server. This user also must have a schema (an entity akin to a namespace in PostgreSQL) where to write tables in the database.

- Enable the `pg_stat_statements` module to make certain stats from the Forgejo database accessible for the Prometheus metrics exporter.

- A regular user and a special schema in the Forgejo database for the Prometheus metrics exporter.

You can do it all in one initializer shell script:

1. Create an `initdb.sh` file in the `configs` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/configs/initdb.sh
    ~~~

2. Enter the script in the `configs/initdb.sh` file:

    ~~~sh
    #!/usr/bin/env bash
    echo ">>> Initializing PostgreSQL server"
    set -e

    echo ">>> Creating user and schema ${POSTGRESQL_FORGEJO_USERNAME} for Forgejo"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE USER ${POSTGRESQL_FORGEJO_USERNAME} WITH PASSWORD '${POSTGRESQL_FORGEJO_PASSWORD}';
        CREATE SCHEMA AUTHORIZATION ${POSTGRESQL_FORGEJO_USERNAME};
        ALTER USER ${POSTGRESQL_FORGEJO_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_FORGEJO_USERNAME};
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_FORGEJO_USERNAME};
    EOSQL


    echo ">>> Enabling the pg_stat_statements module on database ${POSTGRES_DB}"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE EXTENSION pg_stat_statements;
    EOSQL


    echo ">>> Creating user and schema ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} for PostgreSQL Prometheus metrics exporter"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} WITH PASSWORD '${POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD}';
        CREATE SCHEMA AUTHORIZATION ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME},pg_catalog;
        GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        GRANT pg_monitor to ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
    EOSQL
    ~~~

    > [!NOTE]
    > **This custom `initdb.sh` script is based on a few others**\
    > These are the scripts used as references to build the `initdb.sh` script shown above:
    >
    > - The one shown at the [Initialization scripts section](https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts) of the PostgreSQL Docker image README.
    >
    > - [The SQL scripts about "running as non-superuser" shown in the Postgres exporter Docker image's readme](https://github.com/prometheus-community/postgres_exporter#running-as-non-superuser).

    The environment parameters that appear in the `initdb.sh` above mean the following:

    - `POSTGRES_USER`\
      The PostgreSQL superuser's name which, in a default installation, is set to `postgres`.

    - `POSTGRES_DB`\
      The PostgreSQL database's name to access.

    - `POSTGRESQL_FORGEJO_USERNAME`\
      Name for Forgejo's database user.

    - `POSTGRESQL_FORGEJO_PASSWORD`\
      Password for Forgejo's database user.

    - `POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME`\
      Name for the Prometheus metrics exporter user. It is also used as the name of the schema created for metrics within Forgejo's database.

    - `POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD`\
      Password for the Prometheus metrics exporter user.

## PostgreSQL passwords

There are three passwords you need to stablish for your PostgreSQL users.

- The PostgreSQL superuser's password.
- The Forgejo database user's password.
- The Prometheus metrics exporter user's password.

Put them all as variables in the same properties file, to be loaded later as variables of a `Secret` resource:

1. Create a `dbusers.pwd` file under the `secrets` path:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/secrets/dbusers.pwd
    ~~~

2. Enter the passwords in `secrets/dbusers.pwd`:

    ~~~properties
    postgresql-superuser-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_s4pEruZ3r!
    forgejo-user-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_f0R6ejO_uZ3r!
    prometheus-exporter-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_3xP0rTeR_uZ3r!
    ~~~

    > [!WARNING]
    > **The passwords in this `secrets/dbusers.pwd` file are unencrypted strings**\
    > Be careful of who can access this `dbusers.pwd` file.

## PostgreSQL persistent storage claim

Declare here the `PersistentVolumeClaim` (_PVC_) that claims the `PersistentVolume` to be declared in the last part of this Forgejo deployment procedure:

1. Create a `db-postgresql.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.persistentvolumeclaim.yaml
    ~~~

2. Declare the `PersistentVolumeClaim` object in `resources/db-postgresql.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Forgejo PostgreSQL claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: db-postgresql
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: forgejo-ssd-db
      resources:
        requests:
          storage: 4.5G
    ~~~

    If you went back and compared this PVC resource with the one declared for MariaDB in the [part 3 of the Ghost deployment procedure](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-persistent-storage-claim), you would notice that they are essentially the same. Just remember here that the specifications you declare in the YAML manifest must match the ones available in the PV you claim with this PVC.

## PostgreSQL StatefulSet

Since you already know that databases are better deployed as `StatefulSet` objects, let's create one for your PostgreSQL server:

1. Create a `db-postgresql.statefulset.yaml` in the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` in `resources/db-postgresql.statefulset.yaml`:

    ~~~yaml
    # Forgejo PostgreSQL StatefulSet for a sidecar server pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: db-postgresql
    spec:
      replicas: 1
      serviceName: db-postgresql
      template:
        spec:
          containers:
          - name: server
            image: postgres:18.1-trixie
            ports:
            - name: server
              containerPort: 5432
            args:
            - "-c"
            - "config_file=/etc/postgresql/postgresql.conf"
            env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: postgresql-superuser-name
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: postgresql-superuser-password
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: postgresql-db-name
            - name: POSTGRESQL_FORGEJO_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: forgejo-username
            - name: POSTGRESQL_FORGEJO_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: forgejo-user-password
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: prometheus-exporter-username
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: prometheus-exporter-password
            resources:
              requests:
                cpu: "0.75"
                memory: 256Mi
            volumeMounts:
            - name: postgresql-storage
              mountPath: /var/lib/postgresql
            - name: postgresql-config
              readOnly: true
              subPath: postgresql.conf
              mountPath: /etc/postgresql/postgresql.conf
            - name: postgresql-config
              readOnly: true
              subPath: initdb.sh
              mountPath: /docker-entrypoint-initdb.d/initdb.sh
          - name: metrics
            image: prometheuscommunity/postgres-exporter:v0.18.1
            ports:
            - name: metrics
              containerPort: 9187
            env:
            - name: DATA_SOURCE_DB
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: postgresql-db-name
            - name: DATA_SOURCE_URI
              value: "localhost:5432/$(DATA_SOURCE_DB)?sslmode=disable"
            - name: DATA_SOURCE_USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: prometheus-exporter-username
            - name: DATA_SOURCE_PASS
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: prometheus-exporter-password
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
          volumes:
          - name: postgresql-config
            configMap:
              name: db-postgresql-config
              defaultMode: 444
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: postgresql.conf
                path: postgresql.conf
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: db-postgresql
    ~~~

    The `StatefulSet` above is pretty much like [the one you made for the MariaDB server of the Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset). The differences are essentially in the values set and the environment variables used, and more in particular in the containers' declarations:

    - `template.spec.containers`\
      Two containers are set in a sidecar configuration within the pod:

      - Container `server`\
        Holds the PostgreSQL server instance.

        - The `image` of PostgreSQL is based on Debian Trixie.

        - There's an `args` section with a couple of arguments for this container:

          - `"-c"`\
            Is an option of the postgres service, used for specifying configuration options at runtime.

          - `"config_file=/etc/postgresql/postgresql.conf"`\
            The `config_file` option is for setting an alternative custom configuration file for the PostgreSQL server. In this case, it is the `postgresql.conf` file configured previously that has to be put in the `/etc/postgresql` path.

            > [!IMPORTANT]
            > **It is not possible to directly change the default `postgresql.conf` file that exists under the default data path `/var/lib/postgresql`**\
            > Trying to do so provokes a `Read-only file system` error that does not allow the container to start. The same happens with any other configuration file you might consider customize within that `/var/lib/postgresql` path.

        - At the `env` section:

          - The `POSTGRES_USER` and `POSTGRES_PASSWORD` variables are expected by PostgreSQL to set the superuser's name and password. The `POSTGRES_USER` is defined here also to make it available for the `initdb.sh` script.

          - The `POSTGRES_DB` is the name of the database you want to create initially in your PostgreSQL. This variable is also used in the initialization script.

            > [!NOTE]
            > No matter what, there will be always a `postgres` database created in your PostgreSQL server.

          - The `POSTGRESQL_FORGEJO_USERNAME`, `POSTGRESQL_FORGEJO_PASSWORD`, `POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME` and `POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD` variables are for the `initdb.sh` script.

        - The `volumeMounts` section has three mount points:

          - MountPath `/var/lib/postgresql`\
            Mounts the volume claimed by `postgresql-storage` in the default data folder of PostgreSQL.

          - MountPath `/etc/postgresql/postgresql.conf`\
            Your `postgresql.conf` file is mounted in the container path `/etc/postgresql`, as it has been specified at the `args` section of this `server` container.

          - MountPath `/docker-entrypoint-initdb.d/initdb.sh`\
            To make the PostgreSQL container execute initializer scripts, you can put them in the `/docker-entrypoint-initdb.d` path (as you had to do in the MariaDB container of the Nextcloud platform). This line mounts your `initdb.sh` shell script in that folder.

      - Container `metrics`\
        The Prometheus metrics exporter service related to the PostgreSQL server.

        - The `image` of this exporter does not indicate [on what Linux Distribution runs](https://hub.docker.com/r/prometheuscommunity/postgres-exporter).

        - The `env` block has four environment variables that inject values this `metrics` container requires to connect with the PostgreSQL server:

          - `DATA_SOURCE_DB` contains the name of the database to connect to. **Prometheus metrics exporter does not read nor know this environment variable**. It is just for injecting the database name in the connection URL set in the `DATA_SOURCE_URI`.

          - `DATA_SOURCE_URI` defines the URI to connect to the database identified by the `DATA_SOURCE_DB` present in the PostgreSQL server.

            > [!NOTE]
            > **Notice how the URI in this setup points to a localhost address**\
            > This is appropriate because the `metrics` container is running in the same PostgreSQL pod as the `server` container.

          - `DATA_SOURCE_USER` and `DATA_SOURCE_PASS` specify the user and password in the PostgreSQL server for this exporter.

## PostgreSQL Service

You need a `Service` named `db-postgresql` for the previous `StatefulSet`:

1. Create a file named `db-postgresql.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.service.yaml
    ~~~

2. Declare the Service in `resources/db-postgresql.service.yaml`:

    ~~~yaml
    # Forgejo PostgreSQL headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: db-postgresql
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9187"
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - port: 5432
        targetPort: server
        protocol: TCP
        name: server
      - port: 9187
        targetPort: metrics
        protocol: TCP
        name: metrics
    ~~~

    This is just another `ClusterIP` service, like the one you have [declared previously for the Valkey server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service).

### Valkey Service's FQDN

Like the Valkey service, this PostgreSQL service is going to be deployed in the `forgejo` namespace. Therefore, its absolute FQDN will be:

~~~txt
db-postgresql.forgejo.svc.homelab.cluster.
~~~

## PostgreSQL Kustomize project

Produce the main `kustomization.yaml` file for this PostgreSQL Kustomize subproject:

1. Under `db-postgresql`, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/db-postgresql/kustomization.yaml
    ~~~

2. Declare the Kustomize manifest in `kustomization.yaml`:

    ~~~yaml
    # Forgejo PostgreSQL setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
    - pairs:
        app: db-postgresql
      includeSelectors: true
      includeTemplates: true

    resources:
    - resources/db-postgresql.persistentvolumeclaim.yaml
    - resources/db-postgresql.service.yaml
    - resources/db-postgresql.statefulset.yaml

    replicas:
    - name: db-postgresql
      count: 1

    images:
    - name: postgres
      newTag: 18.1-trixie
    - name: prometheuscommunity/postgres-exporter
      newTag: v0.18.1

    configMapGenerator:
    - name: db-postgresql-config
      envs:
      - configs/dbnames.properties
      files:
      - configs/initdb.sh
      - configs/postgresql.conf

    secretGenerator:
    - name: db-postgresql-secrets
      envs:
      - secrets/dbusers.pwd
    ~~~

    This Kustomize manifest is like other `kustomization.yaml` files you have seen before in this guide. For instance, you can compare it with the one for [the MariaDB server of your Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-project).

### Validating the Kustomize YAML output

As usual, check the output of the declared Kustomize project and see that the values are all correct:

1. Execute `kubectl kustomize` and pipe the YAML output to a text editor like `less` or dump it on a file:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/forgejo/components/db-postgresql | less
    ~~~

2. Your YAML output should look like this:

    ~~~yaml
    apiVersion: v1
    data:
      forgejo-username: forgejodb
      initdb.sh: |-
        #!/usr/bin/env bash
        echo ">>> Initializing PostgreSQL server"
        set -e

        echo ">>> Creating user and schema ${POSTGRESQL_FORGEJO_USERNAME} for Forgejo"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            CREATE USER ${POSTGRESQL_FORGEJO_USERNAME} WITH PASSWORD '${POSTGRESQL_FORGEJO_PASSWORD}';
            CREATE SCHEMA AUTHORIZATION ${POSTGRESQL_FORGEJO_USERNAME};
            ALTER USER ${POSTGRESQL_FORGEJO_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_FORGEJO_USERNAME};
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_FORGEJO_USERNAME};
        EOSQL


        echo ">>> Enabling the pg_stat_statements module on database ${POSTGRES_DB}"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            CREATE EXTENSION pg_stat_statements;
        EOSQL


        echo ">>> Creating user and schema ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} for PostgreSQL Prometheus metrics exporter"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            CREATE USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} WITH PASSWORD '${POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD}';
            CREATE SCHEMA AUTHORIZATION ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
            ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME},pg_catalog;
            GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
            GRANT pg_monitor to ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        EOSQL
      postgresql-db-name: forgejo_db
      postgresql-superuser-name: postgres
      postgresql.conf: |-
        # Extension libraries loading
        shared_preload_libraries = 'pg_stat_statements'

        # Connection settings
        listen_addresses = '0.0.0.0'
        port = 5432
        max_connections = 100
        superuser_reserved_connections = 3

        # Memory
        shared_buffers = 128MB
        work_mem = 8MB
        hash_mem_multiplier = 2.0
        maintenance_work_mem = 16MB

        # Logging
        log_destination = 'stderr'
        logging_collector = off
        log_min_messages = 'INFO'
        log_error_verbosity = 'DEFAULT'
        log_connections = on
        log_disconnections = on
        log_hostname = off

        # pg_stat_statements extension library
        compute_query_id = on
        pg_stat_statements.max = 10000
        pg_stat_statements.track = all
      prometheus-exporter-username: prom_metrics
    kind: ConfigMap
    metadata:
      labels:
        app: db-postgresql
      name: db-postgresql-config-58kdgmtt5g
    ---
    apiVersion: v1
    data:
      forgejo-user-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfZjBSNmVqT191WjNyIQ==
      postgresql-superuser-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfczRwRXJ1WjNyIQ==
      prometheus-exporter-password: bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfM3hQMHJUZVJfdVozciE=
    kind: Secret
    metadata:
      labels:
        app: db-postgresql
      name: db-postgresql-secrets-7m2t9f4d49
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9187"
        prometheus.io/scrape: "true"
      labels:
        app: db-postgresql
      name: db-postgresql
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 5432
        protocol: TCP
        targetPort: server
      - name: metrics
        port: 9187
        protocol: TCP
        targetPort: metrics
      selector:
        app: db-postgresql
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: db-postgresql
      name: db-postgresql
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 4.5G
      storageClassName: local-path
      volumeName: forgejo-ssd-db
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: db-postgresql
      name: db-postgresql
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: db-postgresql
      serviceName: db-postgresql
      template:
        metadata:
          labels:
            app: db-postgresql
        spec:
          containers:
          - args:
            - -c
            - config_file=/etc/postgresql/postgresql.conf
            env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  key: postgresql-superuser-name
                  name: db-postgresql-config-58kdgmtt5g
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: postgresql-superuser-password
                  name: db-postgresql-secrets-7m2t9f4d49
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql-config-58kdgmtt5g
            - name: POSTGRESQL_FORGEJO_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: forgejo-username
                  name: db-postgresql-config-58kdgmtt5g
            - name: POSTGRESQL_FORGEJO_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: forgejo-user-password
                  name: db-postgresql-secrets-7m2t9f4d49
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-postgresql-config-58kdgmtt5g
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-postgresql-secrets-7m2t9f4d49
            image: postgres:18.1-trixie
            name: server
            ports:
            - containerPort: 5432
              name: server
            resources:
              requests:
                cpu: "0.75"
                memory: 256Mi
            volumeMounts:
            - mountPath: /var/lib/postgresql
              name: postgresql-storage
            - mountPath: /etc/postgresql/postgresql.conf
              name: postgresql-config
              readOnly: true
              subPath: postgresql.conf
            - mountPath: /docker-entrypoint-initdb.d/initdb.sh
              name: postgresql-config
              readOnly: true
              subPath: initdb.sh
          - env:
            - name: DATA_SOURCE_DB
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql-config-58kdgmtt5g
            - name: DATA_SOURCE_URI
              value: "localhost:5432/$(DATA_SOURCE_DB)?sslmode=disable"
            - name: DATA_SOURCE_USER
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-postgresql-config-58kdgmtt5g
            - name: DATA_SOURCE_PASS
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-postgresql-secrets-7m2t9f4d49
            image: prometheuscommunity/postgres-exporter:v0.18.1
            name: metrics
            ports:
            - containerPort: 9187
              name: metrics
            resources:
              requests:
                cpu: "0.25"
                memory: 16Mi
          volumes:
          - configMap:
              defaultMode: 444
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: postgresql.conf
                path: postgresql.conf
              name: db-postgresql-config-58kdgmtt5g
            name: postgresql-config
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: db-postgresql
    ~~~

## Do not deploy this PostgreSQL project on its own

This PostgreSQL setup is missing the `PersistentVolume` it needs to store data. Do not confuse it with the claim you have configured here for your PostgreSQL server. The corresponding `PersistentVolume` and other remaining elements to be declared in the main Kustomize project you will prepare in the final part of this Forgejo deployment procedure.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/forgejo`
- `$HOME/k8sprjs/forgejo/components`
- `$HOME/k8sprjs/forgejo/components/db-postgresql`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/configs`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/forgejo/components/db-postgresql/kustomization.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/configs/dbnames.properties`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/configs/initdb.sh`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/configs/postgresql.conf`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.service.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.statefulset.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/secrets/dbusers.pwd`

## References

### [PostgreSQL](https://www.postgresql.org/)

- [PostgreSQL 18.1 Documentation](https://www.postgresql.org/docs/18/index.html)
  - [Chapter 19. Server Configuration](https://www.postgresql.org/docs/18/runtime-config.html)
    - [19.2. File Locations](https://www.postgresql.org/docs/18/runtime-config-file-locations.html)

  - [Part VI. Reference](https://www.postgresql.org/docs/18/reference.html)
    - [SQL Commands](https://www.postgresql.org/docs/18/sql-commands.html)
      - [ALTER ROLE](https://www.postgresql.org/docs/18/sql-alterrole.html)
      - [CREATE ROLE](https://www.postgresql.org/docs/18/sql-createrole.html)

  - [Appendix F. Additional Supplied Modules and Extensions](https://www.postgresql.org/docs/18/contrib.html)
    - [F.32. pg_stat_statements — track statistics of SQL planning and execution](https://www.postgresql.org/docs/18/pgstatstatements.html)

- [Docker Hub. PostgreSQL](https://hub.docker.com/_/postgres)
- [GitHub. PostgreSQL 18 Trixie Docker image Dockerfile](https://github.com/docker-library/postgres/blob/master/18/trixie/Dockerfile)
- [GitHub. PostgreSQL Docker image README](https://github.com/docker-library/docs/blob/master/postgres/README.md)

- [GitHub. PostgreSQL Server Exporter](https://github.com/prometheus-community/postgres_exporter)
- [Docker Hub. PostgreSQL Server Exporter](https://hub.docker.com/r/prometheuscommunity/postgres-exporter)

#### Other PostgreSQL-related contents

- [Several9s. Architecture and Tuning of Memory in PostgreSQL Databases](https://severalnines.com/database-blog/architecture-and-tuning-memory-postgresql-databases)
- [Microsoft Blog for PostgreSQL. How to configure Postgres log settings](https://techcommunity.microsoft.com/blog/adforpostgresql/how-to-configure-postgres-log-settings/1214716)
- [Medium. Sylia CHIBOUB. Monitoring PostgreSQL Databases using Postgres exporter along with Prometheus and Grafana.](https://schh.medium.com/monitoring-postgresql-databases-using-postgres-exporter-along-with-prometheus-and-grafana-1d68209ca687)

- [Stack Exchange. Database Administrators](https://dba.stackexchange.com/)
  - [PostgreSQL and default Schemas](https://dba.stackexchange.com/questions/40488/postgresql-and-default-schemas)

- [Stack Overflow](https://stackoverflow.com/)
  - [Kubernetes PostgreSQL: How do I store config files elsewhere than the data directory?](https://stackoverflow.com/questions/61745199/kubernetes-postgresql-how-do-i-store-config-files-elsewhere-than-the-data-direc)
  - [How to customize the configuration file of the official PostgreSQL Docker image?](https://stackoverflow.com/questions/30848670/how-to-customize-the-configuration-file-of-the-official-postgresql-docker-image)
  - [How to change Postgresql max_connections config via Kubernetes statefulset environment variable?](https://stackoverflow.com/questions/56515367/how-to-change-postgresql-max-connections-config-via-kubernetes-statefulset-envir)
  - [chown: changing ownership of '/data/db': Operation not permitted](https://stackoverflow.com/questions/51200115/chown-changing-ownership-of-data-db-operation-not-permitted)
  - [Postgis pg_stat_statements errors](https://stackoverflow.com/questions/68185097/postgis-pg-stat-statements-errors)
  - [pg_stat_statements enabled, but the table does not exist](https://stackoverflow.com/questions/31021174/pg-stat-statements-enabled-but-the-table-does-not-exist)

- [GitHub. Docker-library. Postgres](github.com/docker-library/postgres/)
  - [Pull requests](https://github.com/docker-library/postgres/pulls)
    - [Change PGDATA in 18+ to /var/lib/postgresql/MAJOR/docker](https://github.com/docker-library/postgres/pull/1259)
  - [Issues](https://github.com/docker-library/postgres/issues)
    - [chown: changing ownership of ‘/var/lib/postgresql/data’: Operation not permitted, when running in kubernetes with mounted "/var/lib/postgres/data" volume](https://github.com/docker-library/postgres/issues/361)

- [Neon. PostgreSQL Tutorial](https://neon.com/postgresql/tutorial)
  - [Advanced](https://neon.com/postgresql/postgresql-advanced)
    - [PostgreSQL Create Function Statement](https://neon.com/postgresql/postgresql-plpgsql/postgresql-create-function)
    - [Dollar-Quoted String Constants](https://neon.com/postgresql/postgresql-plpgsql/dollar-quoted-string-constants)

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define a Command and Arguments for a Container. Run a command in a shell](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell)

## Navigation

[<< Previous (**G034. Deploying services 03. Forgejo Part 2**)](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Forgejo Part 4**) >>](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md)
