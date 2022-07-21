# G034 - Deploying services 03 ~ Gitea - Part 3 - PostgreSQL database server

Gitea is compatible with MariaDB but, instead of essentially repeating [the configuration used for the Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md), I thought it would be more interesting to show you how similar can be, from a Kubernetes point of view, the configuration of a different database. So, here you'll see how to configure a PostgreSQL instance for your Gitea platform.

## PostgreSQL Kustomize project's folders

Create the corresponding Kustomize subproject's directory tree for this component of your Gitea platform.

~~~bash
$ mkdir -p $HOME/k8sprjs/gitea/components/db-postgresql/{configs,resources,secrets}
~~~

## PostgreSQL configuration files

You need some configuration files where to set certain parameters for PostgreSQL.

### _Configuration file `postgresql.conf`_

The `postgresql.conf` is where you can set the parameters for PostgreSQL.

1. Create a `postgresql.conf` in the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/configs/postgresql.conf
    ~~~

2. Add to `postgresql.conf` the next configuration.

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

    Above I've set just a bunch of the many parameters available for tuning PostgreSQL.

    - `shared_preload_libraries`: to list shared libraries to be preloaded at server start.

    - `listen_addresses`: indicates through which network interfaces this server will listen. With `0.0.0.0` it'll listen only through all the IPv4 ones it has available.

    - `port`: port where PostgreSQL listen to requests. Here it has the default value, `5432`.

    - `max_connections`: the maximum number of concurrent connections to this PostgreSQL server. Here set with the default value, `100`.

    - `superuser_reserved_connections`: maximum number of simultaneous connections of the superuser to this server. Set with the default value, `3`.

    - `shared_buffers`: how much memory this server can use for shared memory buffers. Here set with the default value, `128MB`.

    - `work_mem`: maximum memory that can be used by a query operation before writing to a temporary disk file. Careful with this value, since it works in tandem with the parameter `hash_mem_multiplier` for hash-based operations.

    - `hash_mem_multiplier`: used to compute the maximum amount of memory that database hash-based operations can use. As it name implies, it multiplies the value in `work_mem` to set the top memory limit for hash-based operations.

    - `maintenance_work_mem`: maximum amount of memory allowed for database maintenance operations. This value can be multiplied by another parameter called `autovacuum_max_workers` when the automatic vacuuming operation is executed.

    - `log_destination`: where you want to dump this server logs. The default value is `stderr`.

    - `logging_collector`: a PostgreSQL feature that collect in the background logs dumped in `stderr`. Unless you're specifically saving those logs in files outside the PostgreSQL server container, you won't use this feature.

    - `log_min_messages`: to indicate up to what message level gets printed as server log.

    - `log_error_verbosity`: how verbose you want the error messages. Careful with the verbosity, since it can affect your server's performance.

    - `log_connections`: for logging the connection attempts to the server.

    - `log_disconnections`: logs the session terminations.

    - `log_hostname`: when enabled, the server will try to get the hostname of the IPs connecting to it. That hostname resolution can result in a noticeable performance loss, so its better to be sure of having it disabled.

    - `compute_query_id`: enables in-core computation of a query identifier. Required `on` for the `pg_stat_statements` extension.

    - `pg_stat_statements.max`: maximum number of statements tracked by the `pg_stat_statements` extension.

    - `pg_stat_statements.track`: controls which statements are counted by the `pg_stat_statements` module.

    To know more about the parameters above and many others available in PostgreSQL, check the [official documentation about Server Configuration](https://www.postgresql.org/docs/14/runtime-config.html) and [the `pg_stat_statements` module](https://www.postgresql.org/docs/14/pgstatstatements.html).

### _Properties file `dbnames.properties`_

You need to load in your PostgreSQL container some names as variables, so you'll prefer to keep them together in a file and load it as a `ConfigMap` later.

1. Create a `dbnames.properties` file under the `configs` path.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/configs/dbnames.properties
    ~~~

2. Copy the following parameter lines into `dbnames.properties`.

    ~~~properties
    postgresql-db-name=gitea
    postgresql-superuser-name=postgres
    gitea-username=gitea
    prometheus-exporter-username=prom_metrics
    ~~~

    The key-value pairs above mean the following.

    - `postgresql-db-name`: a PostgreSQL server always initializes with an empty database named `postgres`, but you can make it generate another one if you give it a different name such as `gitea`.

    - `postgresql-superuser-name`: the default superuser in a PostgreSQL server is named `postgres`, but you could change it for any other.

    - `gitea-username`: name of the regular user for Gitea.

    - `prometheus-exporter-username`: name for the Prometheus metrics exporter user.

### _Initializer shell script `initdb.sh`_

You need to initialize your PostgreSQL server with the following:

- A regular user for Gitea that has all the privileges on the Gitea database running on your PostgreSQL server.

- Enable an extra module to get certain stats, from the Gitea database, for the Prometheus metrics exporter.

- A regular user and a special schema in the Gitea database for the Prometheus metrics exporter.

Let's do it all in one initializer shell script.

1. Create an `initdb.sh` file in the `configs` directory.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/configs/initdb.sh
    ~~~

2. Fill the `initdb.sh` file with the following shell script.

    ~~~bash
    #!/bin/bash
    echo ">>> Initializing PostgreSQL server"
    set -e

    echo ">>> Creating user ${POSTGRESQL_GITEA_USERNAME} for Gitea"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE ROLE ${POSTGRESQL_GITEA_USERNAME} WITH LOGIN PASSWORD '${POSTGRESQL_GITEA_PASSWORD}';
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_GITEA_USERNAME};
    EOSQL


    echo ">>> Enabling [pg_stat_statements] module on database ${POSTGRES_DB}"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        CREATE EXTENSION pg_stat_statements;
    EOSQL

    echo ">>> Creating user and schema ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} for PostgreSQL Prometheus metrics exporter"
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        -- To use IF statements, hence to be able to check if the user exists before
        -- attempting creation, we need to switch to procedural SQL (PL/pgSQL)
        -- instead of standard SQL.
        -- More: https://www.postgresql.org/docs/14/plpgsql-overview.html
        -- To preserve compatibility with <9.0, DO blocks are not used; instead,
        -- a function is created and dropped.
        CREATE OR REPLACE FUNCTION __tmp_create_user() returns void as
        '
        BEGIN
          IF NOT EXISTS (
                  SELECT                       -- SELECT list can stay empty for this
                  FROM   pg_catalog.pg_user
                  WHERE  usename = ''${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}'') THEN
            CREATE USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
          END IF;
        END;
        ' language plpgsql;

        SELECT __tmp_create_user();
        DROP FUNCTION __tmp_create_user();

        ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} WITH PASSWORD '${POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD}';
        ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME},pg_catalog;

        -- If deploying as non-superuser (for example in AWS RDS), uncomment the GRANT
        -- line below and replace <MASTER_USER> with your root user.
        -- GRANT ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO <MASTER_USER>;
        CREATE SCHEMA IF NOT EXISTS ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        GRANT USAGE ON SCHEMA ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

        CREATE OR REPLACE FUNCTION get_pg_stat_activity() RETURNS SETOF pg_stat_activity AS
        ' SELECT * FROM pg_catalog.pg_stat_activity; '
        LANGUAGE sql
        VOLATILE
        SECURITY DEFINER;

        CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity
        AS
          SELECT * from get_pg_stat_activity();

        GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

        CREATE OR REPLACE FUNCTION get_pg_stat_replication() RETURNS SETOF pg_stat_replication AS
        ' SELECT * FROM pg_catalog.pg_stat_replication; '
        LANGUAGE sql
        VOLATILE
        SECURITY DEFINER;

        CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication
        AS
          SELECT * FROM get_pg_stat_replication();

        GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

        CREATE OR REPLACE FUNCTION get_pg_stat_statements() RETURNS SETOF pg_stat_statements AS
        ' SELECT * FROM public.pg_stat_statements; '
        LANGUAGE sql
        VOLATILE
        SECURITY DEFINER;

        CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements
        AS
          SELECT * FROM get_pg_stat_statements();

        GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
    EOSQL
    ~~~

    This script is a combination of a few others:

    - The one shown at the [Initialization scripts section](https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts) of the PostgreSQL Docker image README.

    - [The SQL script about "running as non-superuser" shown in the Postgres exporter Docker image's readme](https://github.com/prometheus-community/postgres_exporter#running-as-non-superuser).

    The environment parameters that appear in the `initdb.sh` above mean the following.

    - `POSTGRES_USER`: the PostgreSQL superuser's name which, in a default installation, is set to `postgres`.
    - `POSTGRES_DB`: the PostgreSQL database's name to access.
    - `POSTGRESQL_GITEA_USERNAME`: name for Gitea database's user.
    - `POSTGRESQL_GITEA_PASSWORD`: password for Gitea database's user.
    - `POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME`: name for the Prometheus metrics exporter user. It's also used as the name of the schema created for metrics within Gitea's database.
    - `POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD`: password for the Prometheus metrics exporter user.

## PostgreSQL passwords

There are three passwords you need to stablish for your PostgreSQL users.

- The PostgreSQL superuser's password.
- The Gitea database user's password.
- The Prometheus metrics exporter user's password.

Put them all as variables in the same properties file, to be loaded later as variables of a Secret resource.

1. Create a `dbusers.pwd` file under the `secrets` path.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/secrets/dbusers.pwd
    ~~~

2. Fill `dbusers.pwd` with the following lines.

    ~~~properties
    postgresql-superuser-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_s4pEruZ3r!
    gitea-user-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_gI7eA_uZ3r!
    prometheus-exporter-password=l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_3xP0rTeR_uZ3r!
    ~~~

    The passwords in this file must be typed as plain unencrypted text, so be careful of who accesses this file.

## PostgreSQL storage

Here you'll declare a persistent volume claim (PVC) on the persistent volume (PV declared in the last part of this Gitea guide) required for this PostgreSQL setup.

1. Create a `db-postgresql.persistentvolumeclaim.yaml` file under the `resources` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.persistentvolumeclaim.yaml
    ~~~

2. Copy the yaml manifest below into `db-postgresql.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: db-postgresql
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: db-gitea
      resources:
        requests:
          storage: 3.5G
    ~~~

    If you went back and compared this PVC resource with the one declared for MariaDB in the [part 3 of the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-storage), you'll notice that they're essentially the same. Just remember here that the specifications you set in spec must match the ones available in the PV you claim with this PVC.

## PostgreSQL StatefulSet resource

You know already that databases are better deployed with stateful set resources, so let's create one for your PostgreSQL server.

1. Create a `db-postgresql.statefulset.yaml` in the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.statefulset.yaml
    ~~~

2. Put in `db-postgresql.statefulset.yaml` the next resource description.

    ~~~yaml
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
            image: postgres:14.1-bullseye
            ports:
            - containerPort: 5432
            args:
            - "-c"
            - "config_file=/etc/postgresql/postgresql.conf"
            env:
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: postgresql-superuser-name
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql
                  key: postgresql-superuser-password
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: postgresql-db-name
            - name: POSTGRESQL_GITEA_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: gitea-username
            - name: POSTGRESQL_GITEA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql
                  key: gitea-user-password
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: prometheus-exporter-username
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql
                  key: prometheus-exporter-password
            resources:
              limits:
                memory: 320Mi
            volumeMounts:
            - name: postgresql-storage
              mountPath: /var/lib/postgresql/data
            - name: postgresql-config
              subPath: postgresql.conf
              mountPath: /etc/postgresql/postgresql.conf
            - name: postgresql-config
              subPath: initdb.sh
              mountPath: /docker-entrypoint-initdb.d/initdb.sh
          - name: metrics
            image: wrouesnel/postgres_exporter:latest
            ports:
            - containerPort: 9187
            env:
            - name: DATA_SOURCE_USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql
                  key: prometheus-exporter-username
            - name: DATA_SOURCE_PASS
              valueFrom:
                secretKeyRef:
                  name: db-postgresql
                  key: prometheus-exporter-password
            - name: DATA_SOURCE_URI
              value: "localhost:5432/?sslmode=disable"
            - name: PG_EXPORTER_AUTO_DISCOVER_DATABASES
              value: 'true'
            resources:
              limits:
                memory: 32Mi
          volumes:
          - name: postgresql-config
            configMap:
              name: db-postgresql
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: postgresql.conf
                path: postgresql.conf
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: db-postgresql
    ~~~

    The `StatefulSet` above is pretty much like [the one you made for the MariaDB server of the Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource). The differences are essentially in the values set and the environment variables used, and more in particular in the containers' declarations.

    - `template.spec.containers`: two containers are set in the pod as sidecars.
        - Container `server`: the PostgreSQL server instance.

            - The `image` of PostgreSQL is based on Debian Bullseye.

            - There's an `args` section with a couple of arguments for this container.
                - `"-c"`: is an option of the postgres service, used for specifying configuration options at runtime.
                - `"config_file=/etc/postgresql/postgresql.conf"`: the `config_file` option is for setting an alternative custom configuration file for the PostgreSQL server. In this case, it will be the `postgresql.conf` file you configured previously, and you'll put in the `/etc/postgresql` path.

                    This is necessary because you won't be able to change directly the default `postgresql.conf` file that exists in the default data path `/var/lib/postgresql/data`. Trying to do so will provoke a `Read-only file system` error that won't allow the container to start. The same goes for any other configuration file you might consider customize within that `/var/lib/postgresql/data` path.

            - At the `env` section.
                - The `POSTGRES_USER` and `POSTGRES_PASSWORD` variables are expected by PostgreSQL to set the superuser's name and password. The `POSTGRES_USER` is defined here also to make it available for the `initdb.sh` script.
                - The `POSTGRES_DB` is the name of the database you want to create initially in your PostgreSQL. This variable's also used in the initialization script.
                    > **BEWARE!**  
                    > No matter what, there will be always a `postgres` database created in your PostgreSQL server.
                - The `POSTGRESQL_GITEA_USERNAME`, `POSTGRESQL_GITEA_PASSWORD`, `POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME` and `POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD` variables are for the `initdb.sh` script.

            - The `volumeMounts` section has three mount points.
                - MountPath `/var/lib/postgresql/data`: mounts the volume claimed by `postgresql-storage` in the default data folder of PostgreSQL.
                - MountPath `/etc/postgresql/postgresql.conf`: your `postgresql.conf` file will be mounted in the container path `/etc/postgresql`, as it has been specified at the `args` section of this `server` container.
                - MountPath `/docker-entrypoint-initdb.d/initdb.sh`: to make the PostgreSQL container execute initializer scripts, you can put them in the `/docker-entrypoint-initdb.d` path (as you had to do in the MariaDB container of the Nextcloud platform). This line mounts your `initdb.sh` shell script in that folder.

        - Container `metrics`: the Prometheus metrics exporter service related to the PostgreSQL server.
            - The `image` of this exporter doesn't have detailed [on what Linux Distribution runs](https://hub.docker.com/r/wrouesnel/postgres_exporter).
            - The `env` block has four variables that are all directly used by this container. The `DATA_SOURCE_USER` and `DATA_SOURCE_PASS` specify the user and password in the PostgreSQL server for this exporter, `DATA_SOURCE_URI` indicates the URI to connect to the database server and `PG_EXPORTER_AUTO_DISCOVER_DATABASES` is an option that enables this metrics exporter to autodetect the databases present in the PostgreSQL server.

## PostgreSQL Service resource

You need a `Service` named `db-postgresql` for the previous `StatefulSet`.

1. Create a file named `db-postgresql.service.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.service.yaml
    ~~~

2. Edit `db-postgresql.service.yaml` and put the following yaml in it.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9187"
      name: db-postgresql
    spec:
      type: ClusterIP
      ports:
      - port: 5432
        protocol: TCP
        name: server
      - port: 9187
        protocol: TCP
        name: metrics
    ~~~

    This is just another `ClusterIP` service, like the one you've [declared previously for the Redis server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource). And, like that Redis service, you'll have to invoke this PostgreSQL service by its FQDN.

### _PosgreSQL `Service`'s FQDN or DNS record_

[The same particularities that determined the Redis service's DNS record](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-services-fqdn-or-dns-record) apply to this PostgreSQL `Service`'s internal FQDN, which should be as follows.

~~~http
gitea-db-postgresql.gitea.svc.deimos.cluster.io
~~~

## PostgreSQL Kustomize project

Let's produce now the the main `kustomization.yaml` file for this PostgreSQL Kustomize project.

1. Under `db-postgresql`, create a `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8sprjs/gitea/components/db-postgresql/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the yaml definition below.

    ~~~yaml
    # PostgreSQL setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: db-postgresql

    resources:
    - resources/db-postgresql.persistentvolumeclaim.yaml
    - resources/db-postgresql.service.yaml
    - resources/db-postgresql.statefulset.yaml

    replicas:
    - name: db-postgresql
      count: 1

    images:
    - name: postgres
      newTag: 14.1-bullseye
    - name: wrouesnel/postgres_exporter
      newTag: latest

    configMapGenerator:
    - name: db-postgresql
      envs:
      - configs/dbnames.properties
      files:
      - configs/initdb.sh
      - configs/postgresql.conf

    secretGenerator:
    - name: db-postgresql
      envs:
      - secrets/dbusers.pwd
    ~~~

    Here there's nothing that you haven't seen in previous `kustomization.yaml` files, specially if you compare with the one for [the MariaDB server of your Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-project).

### _Checking the Kustomize yaml output_

As usual, check the output of this Kustomize project and see that the values are all correct.

1. Execute `kubectl kustomize` and pipe the yaml output on the `less` command or dump it on a file.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/gitea/components/db-postgresql | less
    ~~~

2. Your yaml output should be like next.

    ~~~yaml
    apiVersion: v1
    data:
      gitea-username: gitea
      initdb.sh: |
        #!/bin/bash
        echo ">>> Initializing PostgreSQL server"
        set -e

        echo ">>> Creating user ${POSTGRESQL_GITEA_USERNAME} for Gitea"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            CREATE ROLE ${POSTGRESQL_GITEA_USERNAME} WITH LOGIN PASSWORD '${POSTGRESQL_GITEA_PASSWORD}';
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_GITEA_USERNAME};
        EOSQL


        echo ">>> Enabling [pg_stat_statements] module on database ${POSTGRES_DB}"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            CREATE EXTENSION pg_stat_statements;
        EOSQL

        echo ">>> Creating user and schema ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} for PostgreSQL Prometheus metrics exporter"
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            -- To use IF statements, hence to be able to check if the user exists before
            -- attempting creation, we need to switch to procedural SQL (PL/pgSQL)
            -- instead of standard SQL.
            -- More: https://www.postgresql.org/docs/14/plpgsql-overview.html
            -- To preserve compatibility with <9.0, DO blocks are not used; instead,
            -- a function is created and dropped.
            CREATE OR REPLACE FUNCTION __tmp_create_user() returns void as
            '
            BEGIN
              IF NOT EXISTS (
                      SELECT                       -- SELECT list can stay empty for this
                      FROM   pg_catalog.pg_user
                      WHERE  usename = ''${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}'') THEN
                CREATE USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
              END IF;
            END;
            ' language plpgsql;

            SELECT __tmp_create_user();
            DROP FUNCTION __tmp_create_user();

            ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} WITH PASSWORD '${POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD}';
            ALTER USER ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} SET SEARCH_PATH TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME},pg_catalog;

            -- If deploying as non-superuser (for example in AWS RDS), uncomment the GRANT
            -- line below and replace <MASTER_USER> with your root user.
            -- GRANT ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO <MASTER_USER>;
            CREATE SCHEMA IF NOT EXISTS ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
            GRANT USAGE ON SCHEMA ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
            GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

            CREATE OR REPLACE FUNCTION get_pg_stat_activity() RETURNS SETOF pg_stat_activity AS
            ' SELECT * FROM pg_catalog.pg_stat_activity; '
            LANGUAGE sql
            VOLATILE
            SECURITY DEFINER;

            CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity
            AS
              SELECT * from get_pg_stat_activity();

            GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_activity TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

            CREATE OR REPLACE FUNCTION get_pg_stat_replication() RETURNS SETOF pg_stat_replication AS
            ' SELECT * FROM pg_catalog.pg_stat_replication; '
            LANGUAGE sql
            VOLATILE
            SECURITY DEFINER;

            CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication
            AS
              SELECT * FROM get_pg_stat_replication();

            GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_replication TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};

            CREATE OR REPLACE FUNCTION get_pg_stat_statements() RETURNS SETOF pg_stat_statements AS
            ' SELECT * FROM public.pg_stat_statements; '
            LANGUAGE sql
            VOLATILE
            SECURITY DEFINER;

            CREATE OR REPLACE VIEW ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements
            AS
              SELECT * FROM get_pg_stat_statements();

            GRANT SELECT ON ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME}.pg_stat_statements TO ${POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME};
        EOSQL
      postgresql-db-name: gitea
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
      name: db-postgresql-2m294k4k9m
    ---
    apiVersion: v1
    data:
      gitea-user-password: |
        bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfZ0k3ZUFfdVozciEK
      postgresql-superuser-password: |
        bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfczRwRXJ1WjNyIQo=
      prometheus-exporter-password: |
        bDBuRy5QbDRpbl9UM3h0X3NFa1JldF9wNHM1d09SRC1Gb1JfM3hQMHJUZVJfdVozciEK
    kind: Secret
    metadata:
      labels:
        app: db-postgresql
      name: db-postgresql-2gmd96742m
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
      ports:
      - name: server
        port: 5432
        protocol: TCP
      - name: metrics
        port: 9187
        protocol: TCP
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
          storage: 3.5G
      storageClassName: local-path
      volumeName: db-gitea
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
                  name: db-postgresql-2m294k4k9m
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: postgresql-superuser-password
                  name: db-postgresql-2gmd96742m
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql-2m294k4k9m
            - name: POSTGRESQL_GITEA_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: gitea-username
                  name: db-postgresql-2m294k4k9m
            - name: POSTGRESQL_GITEA_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: gitea-user-password
                  name: db-postgresql-2gmd96742m
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-postgresql-2m294k4k9m
            - name: POSTGRESQL_PROMETHEUS_EXPORTER_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-postgresql-2gmd96742m
            image: postgres:14.1-bullseye
            name: server
            ports:
            - containerPort: 5432
            resources:
              limits:
                memory: 320Mi
            volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgresql-storage
            - mountPath: /etc/postgresql/postgresql.conf
              name: postgresql-config
              subPath: postgresql.conf
            - mountPath: /docker-entrypoint-initdb.d/initdb.sh
              name: postgresql-config
              subPath: initdb.sh
          - env:
            - name: DATA_SOURCE_USER
              valueFrom:
                configMapKeyRef:
                  key: prometheus-exporter-username
                  name: db-postgresql-2m294k4k9m
            - name: DATA_SOURCE_PASS
              valueFrom:
                secretKeyRef:
                  key: prometheus-exporter-password
                  name: db-postgresql-2gmd96742m
            - name: DATA_SOURCE_URI
              value: localhost:5432/?sslmode=disable
            - name: PG_EXPORTER_AUTO_DISCOVER_DATABASES
              value: "true"
            image: wrouesnel/postgres_exporter:latest
            name: metrics
            ports:
            - containerPort: 9187
            resources:
              limits:
                memory: 32Mi
          volumes:
          - configMap:
              items:
              - key: initdb.sh
                path: initdb.sh
              - key: postgresql.conf
                path: postgresql.conf
              name: db-postgresql-2m294k4k9m
            name: postgresql-config
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: db-postgresql
    ~~~

3. Remember that, if you dumped the Kustomize output into a yaml file, you can validate it with `kubeval`.

## Don't deploy this PostgreSQL project on its own

This PostgreSQL setup is missing the persistent volume it needs to store data and which you must not confuse with the claim you've configured for your PostgreSQL server. The PV and other elements will be declared in the main Kustomize project you'll prepare in the final part of this guide.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/gitea`
- `$HOME/k8sprjs/gitea/components`
- `$HOME/k8sprjs/gitea/components/db-postgresql`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs`
- `$HOME/k8sprjs/gitea/components/db-postgresql/resources`
- `$HOME/k8sprjs/gitea/components/db-postgresql/secrets`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/gitea/components/db-postgresql/kustomization.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs/dbnames.properties`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs/initdb_exporter_user.sh`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs/initdb_gitea.sh`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs/postgresql.conf`
- `$HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.service.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.statefulset.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/secrets/dbusers.pwd`

## References

### _Kubernetes_

- [Run a command in a shell](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell)

### _PostgreSQL_

- [Official PostgreSQL site](https://www.postgresql.org/)
- [Server Configuration](https://www.postgresql.org/docs/14/runtime-config.html)
- [File Locations](https://www.postgresql.org/docs/current/runtime-config-file-locations.html)
- [PostgreSQL official Docker image](https://hub.docker.com/_/postgres)
- [PostgreSQL Docker image README](https://github.com/docker-library/docs/blob/master/postgres/README.md)
- [PostgreSQL 14 Dockerfile](https://github.com/docker-library/postgres/blob/3bb48045b4dc5df24bf2271c679f7a4e9efcbe6e/14/bullseye/Dockerfile)
- [PostgreSQL Prometheus metrics exporter](https://github.com/prometheus-community/postgres_exporter)
- [Architecture and Tuning of Memory in PostgreSQL Databases](https://severalnines.com/database-blog/architecture-and-tuning-memory-postgresql-databases)
- [How To Start Logging With PostgreSQL](https://logtail.com/tutorials/how-to-start-logging-with-postgresql/)
- [How to configure Postgres log settings](https://techcommunity.microsoft.com/t5/azure-database-for-postgresql/how-to-configure-postgres-log-settings/ba-p/1214716)
- [PostgresSQL Server Exporter](https://hub.docker.com/r/wrouesnel/postgres_exporter)
- [PostgresSQL Server Exporter on GitHub](https://github.com/prometheus-community/postgres_exporter)
- [Monitoring PostgreSQL Databases using Postgres exporter along with Prometheus and Grafana.](https://schh.medium.com/monitoring-postgresql-databases-using-postgres-exporter-along-with-prometheus-and-grafana-1d68209ca687)
- [CREATE ROLE](https://www.postgresql.org/docs/14/sql-createrole.html)
- [ALTER ROLE](https://www.postgresql.org/docs/14/sql-alterrole.html)
- [PostgreSQL and default Schemas](https://dba.stackexchange.com/questions/40488/postgresql-and-default-schemas)
- [Kubernetes PostgreSQL: How do I store config files elsewhere than the data directory?](https://stackoverflow.com/questions/61745199/kubernetes-postgresql-how-do-i-store-config-files-elsewhere-than-the-data-direc)
- [How to customize the configuration file of the official PostgreSQL Docker image?](https://stackoverflow.com/questions/30848670/how-to-customize-the-configuration-file-of-the-official-postgresql-docker-image)
- [How to change Postgresql max_connections config via Kubernetes statefulset environment variable?](https://stackoverflow.com/questions/56515367/how-to-change-postgresql-max-connections-config-via-kubernetes-statefulset-envir)
- [chown: changing ownership of '/data/db': Operation not permitted](https://stackoverflow.com/questions/51200115/chown-changing-ownership-of-data-db-operation-not-permitted)
- [chown: changing ownership of ‘/var/lib/postgresql/data’: Operation not permitted, when running in kubernetes with mounted "/var/lib/postgres/data" volume](https://github.com/docker-library/postgres/issues/361)
- [PostgreSQL Create Function Statement](https://www.postgresqltutorial.com/postgresql-create-function/)
- [Dollar-Quoted String Constants](https://www.postgresqltutorial.com/dollar-quoted-string-constants/)
- [Extension library module `pg_stat_statements`](https://www.postgresql.org/docs/14/pgstatstatements.html)
- [Postgis pg_stat_statements errors](https://stackoverflow.com/questions/68185097/postgis-pg-stat-statements-errors)
- [pg_stat_statements enabled, but the table does not exist](https://stackoverflow.com/questions/31021174/pg-stat-statements-enabled-but-the-table-does-not-exist)
