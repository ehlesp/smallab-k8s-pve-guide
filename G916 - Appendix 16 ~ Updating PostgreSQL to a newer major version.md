# G916 - Appendix 16 ~ Updating PostgreSQL to a newer major version

PostgreSQL runs well as a containerized instance and can be upgraded easily to new minor or debug versions. However, updating it to a new _MAJOR_ version is not a straightforward affair. Still, there's a way that simplifies this process a bit, and I'll show it to you in this guide.

## Concerns

When you read about the [upgrade procedure of a PostgreSQL server](https://www.postgresql.org/docs/current/upgrading.html) to a new major version, you realize that it hasn't been adapted to work in a containerized environment. This raises its own set of concerns that you must factor in before you deal with the upgrade itself.

### _Custom image only for PostgreSQL upgrading_

To update PostgreSQL to a new major version "in place", avoiding the common method of dumping and restoring the databases, you need both the old and the new versions of the software installed in the host system. Then, you would execute the upgrade command provided by the **new** version of PostgreSQL. This updates the system tables' layout or the databases' internal data storage used in the PostgreSQL server.

If the upgrade is done by PostgreSQL's new version, why would you need the old one too? It's not detailed by the [official documentation of the `pg_upgrade` command](https://www.postgresql.org/docs/current/pgupgrade.html), it only says that the `pg_upgrade` command requires the "specification" of both the old and the new cluster (meaning the server instances) for some unspecified technical reasons.

This particularity is what makes updating to a newer major version of PostgreSQL in Kubernetes more difficult than it should, since no **official** PostgreSQL container image comes with two versions of the software. Thankfully, [Tianon Gravi](https://github.com/tianon) and other collaborators maintain a collection of [custom Docker images](https://hub.docker.com/r/tianon/postgres-upgrade/) containing exactly that: an older and a newer version of PostgreSQL. By using the right custom image, updating to a new major version of PostgreSQL is less complicated.

### _Beware of the storage space_

Since the upgrade process could have a problem while its running, the safest way to do it is by applying it over a copy of the database files you want to upgrade. The copy mode is, in fact, the default behavior of the `pg_upgrade` command. The main concern with this method is to ensure **beforehand** that you have enough storage space for the new data files.

When the update is done, you'll end up with **two copies** of your PostgreSQL database instances' data files, the old and the new versions.

### _Compatibility with other software_

Remember to check the **compatibility** of the software that's using your PostgreSQL database with the new version you want to upgrade it to. That software may not have the proper drivers to connect to the newer version of PostgreSQL yet, or maybe it requires some special features deprecated or unavailable in that more recent PostgreSQL release.

### _Disabling access to the PostgreSQL instance while upgrading_

While the upgrade process is running (and messing with your data), you don't want anyone or anything to try accessing your PostgreSQL server in such a critical time. So, to be sure, you'll have to **stop or undeploy** the service or platform using the PostgreSQL server you're upgrading. In a properly built and managed Kubernetes setup (with Kustomize projects, for instance) this shouldn't be much of an issue.

### _Reconfiguring Gitea's deployment_

After your PostgreSQL data is updated, the last thing you'll need to revise is the configuration of your Gitea deployment. In particular, you'll need to point the PostgreSQL server to the folder where the updated database files are stored.

On the other hand, you'll have to revise the configuration of your PostgreSQL instance and ensure that it's compatible with the newer PostgreSQL server version you want to run in your Kubernetes cluster.

## Upgrade procedure (for Gitea's PostgreSQL instance)

The upgrade procedure is rather elaborated, so I've organized it around several distinct **stages**. You'll see how I go through them while upgrading the PostgreSQL instance of the Gitea platform deployed in the [G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md).

### _Stage 1. Identifying the PostgreSQL version you have and the one you want_

The trick of this upgrade procedure is the use of a particular Docker image that allows you migrate your PostgreSQL database files from the current version they're in to the **next** newer one. So, the very first thing to do is to identify which major PostgreSQL version you're migrating from, and which one you want to reach.

1. In the Gitea's setup, PostgreSQL is deployed as a stateful set. So, to get its current version you can use `kubectl` as follows.

    ~~~bash
    $ kubectl get statefulset -n gitea -o wide
    NAME                  READY   AGE    CONTAINERS   IMAGES
    gitea-db-postgresql   1/1     253d   server       postgres:14.6-bullseye
    gitea-server-gitea    1/1     253d   server       gitea/gitea:1.17.4
    ~~~

    Under the `gitea` namespace there are two stateful sets, one executing the `1.17.4` release of Gitea and other running a `14.6-bullseye` version of PostgreSQL server. Remember or write down somewhere these versions, since you'll need them in the next steps.

    Of course, you could open the corresponding `kustomization.yaml` files of the Gitea and PostgreSQL components in your Gitea Kustomize project, and see what's the value for the `images.newTag` attribute. But with the `kubectl` command you're sure of getting the **current version** of the images running in your K8s cluster, which then you could compare with what you have set in your Kustomize project.

2. Discover which is the newest version of PostgreSQL. You could do it in the official [PostgreSQL page](https://www.postgresql.org/), or looking up directly the Docker image with the latest version. Either way, at the moment I'm writing this, the latest PostgreSQL version is the `15.3` one.

3. Regarding the Gitea compatibility with PostgreSQL `15.3`, the official documentation states in its [Database Preparation section](https://docs.gitea.io/en-us/database-prep/) that Gitea supports working with PostgreSQL version 10 and forward, implicitly including the `15.3` version.

    > **BEWARE!**  
    > Gitea's official web site doesn't offer an option to view the documentation for older versions, so here I'll assume that the database compatibility is the same for the `1.17.4` version of Gitea as for its latest release (`1.19.3` at the time of writing this).

4. Knowing that, in this scenario, you want to upgrade from PostgreSQL's `14.y` release to the `15.y` one, you can choose the right [Tianon Gravi's **postgres-upgrade** Docker image](https://hub.docker.com/r/tianon/postgres-upgrade/): the one tagged as [14-to-15](https://hub.docker.com/layers/tianon/postgres-upgrade/14-to-15/images/sha256-18da581c7839388bb25fd3f8b3170b540556ef3eb69d9afcc0662fcaa52d864e?context=explore).

    Remember or save the link to this particular image because it's the one you'll have to deploy in a later stage of this upgrade procedure.

### _Stage 2. Undeploying the Gitea platform_

You need to undeploy your whole Gitea setup before you can start tinkering with its PostgreSQL database, so get into your `kubectl` client and do the following.

1. Get into your Gitea kustomize project's root folder.

    ~~~bash
    $ cd $HOME/k8sprjs/gitea/
    ~~~

2. Use `kubectl` to delete the kustomize-based deployment of your Gitea instance.

    ~~~bash
    $ kubectl delete -k .
    ~~~

    > **BEWARE!**  
    > Remember that, **in this case**, this `delete` action doesn't affect the data itself in the PostgreSQL database nor its files. This operation only removes from your K8s cluster the Kubernetes entities created by the Gitea deployment.

3. Check with `kubectl` that there are no resources left in the `gitea` namespace, not even the namespace itself.

    ~~~bash
    $ kubectl describe namespaces gitea
    Error from server (NotFound): namespaces "gitea" not found
    ~~~

    If the namespace is still there, it means that something went wrong in the previous `delete` step. Check out which resources remain with commands like the following ones.

    ~~~bash
    $ kubectl get deployments.apps -A
    $ kubectl get pods -A
    $ kubectl get svc -A
    ~~~

### _Stage 3. Preparing the data folders_

With the folder arrangement prepared for the Gitea's PostgreSQL database in the [first part of the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#storage-mount-points-for-gitea-containers), the data files of the database instance where left in the path `/mnt/gitea-ssd/db/k3smnt/`. For this update to work cleanly, you'll need to create a new folder within the `k3smnt` directory where to move **all** those database files into that folder.

> **BEWARE!**  
> The `/mnt/gitea-ssd/db/k3smnt/` path and all its files inside are owned by the `postgres` user that runs the PostgreSQL service in the corresponding Kubernetes pod. Not even your `sudo` privileges will be enough, you'll need to impersonate that user to handle those files.

1. Open a shell as `mgrsys` directly into the agent node (`k3sagent01` in the guide) that has the PostgreSQL storage mounted. Check out with `ls` the permissions on the `/mnt/gitea-ssd/db/k3smnt/` folder.

    ~~~bash
    $ sudo ls -al /mnt/gitea-ssd/db/k3smnt/
    total 132
    drwx------ 19 systemd-coredump root              4096 May 29 21:22 .
    drwxr-xr-x  4 root             root              4096 Aug  5  2022 ..
    drwx------  6 systemd-coredump systemd-coredump  4096 Aug  5  2022 base
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 20:51 global
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_commit_ts
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_dynshmem
    -rw-------  1 systemd-coredump systemd-coredump  4821 Aug  5  2022 pg_hba.conf
    -rw-------  1 systemd-coredump systemd-coredump  1636 Aug  5  2022 pg_ident.conf
    drwx------  4 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_logical
    drwx------  4 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_multixact
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_notify
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_replslot
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_serial
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_snapshots
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_stat
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_stat_tmp
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_subtrans
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_tblspc
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_twophase
    -rw-------  1 systemd-coredump systemd-coredump     3 Aug  5  2022 PG_VERSION
    drwx------  3 systemd-coredump systemd-coredump  4096 Sep 21  2022 pg_wal
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_xact
    -rw-------  1 systemd-coredump systemd-coredump    88 Aug  5  2022 postgresql.auto.conf
    -rw-------  1 systemd-coredump systemd-coredump 28835 Aug  5  2022 postgresql.conf
    -rw-------  1 systemd-coredump systemd-coredump    87 May 29 20:50 postmaster.opts
    ~~~

    Notice that, from the **point of view** of this node's Debian OS, the owner of the PostgreSQL database files is called `systemd-coredump`, not `postgres`. This is an oddity I already explained back in the [_Shell access into your containers_ section of the **G036** guide](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers).

2. Impersonate the `systemd-coredump` user with `sudo`.

    ~~~bash
    $ sudo -S -u systemd-coredump /bin/bash -l
    ~~~

3. Get into the `/mnt/gitea-ssd/db/k3smnt/` folder.

    ~~~bash
    $ cd /mnt/gitea-ssd/db/k3smnt/
    ~~~

4. Create a new folder called `14`.

    ~~~bash
    $ mkdir 14
    ~~~

    The name is `14` because that's the **major** number of the PostgreSQL version configured for deployment in the [third part of the Gitea guides](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md).

5. Move all **other** files and directories inside the `14` folder.

    ~~~bash
    $ mv -t 14 base/ global/ pg* post* PG_VERSION
    ~~~

    See that I've used the -t option to specify the destination directory `14` first for clarity.

6. Verify that you have all the database files and folders in the `14` folder.

    ~~~bash
    $ ls -al 14
    total 132
    drwxr-xr-x 19 systemd-coredump systemd-coredump  4096 May 29 22:46 .
    drwx------  4 systemd-coredump root              4096 May 29 22:51 ..
    drwx------  6 systemd-coredump systemd-coredump  4096 Aug  5  2022 base
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 20:51 global
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_commit_ts
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_dynshmem
    -rw-------  1 systemd-coredump systemd-coredump  4821 Aug  5  2022 pg_hba.conf
    -rw-------  1 systemd-coredump systemd-coredump  1636 Aug  5  2022 pg_ident.conf
    drwx------  4 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_logical
    drwx------  4 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_multixact
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_notify
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_replslot
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_serial
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_snapshots
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_stat
    drwx------  2 systemd-coredump systemd-coredump  4096 May 29 21:22 pg_stat_tmp
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_subtrans
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_tblspc
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_twophase
    -rw-------  1 systemd-coredump systemd-coredump     3 Aug  5  2022 PG_VERSION
    drwx------  3 systemd-coredump systemd-coredump  4096 Sep 21  2022 pg_wal
    drwx------  2 systemd-coredump systemd-coredump  4096 Aug  5  2022 pg_xact
    -rw-------  1 systemd-coredump systemd-coredump    88 Aug  5  2022 postgresql.auto.conf
    -rw-------  1 systemd-coredump systemd-coredump 28835 Aug  5  2022 postgresql.conf
    -rw-------  1 systemd-coredump systemd-coredump    87 May 29 20:50 postmaster.opts
    ~~~

7. Create a new folder called `15`.

    ~~~bash
    $ mkdir 15
    ~~~

    In a later stage of this procedure, this is the folder you'll tell the PostgreSQL upgrade process to dump the updated database files into.

8. Exit from the `systemd-coredump` user session.

    ~~~bash
    $ exit
    ~~~

    Here you'll return to your regular administrator user `mgrsys`.

9. Adjust the ownership of the folder `/mnt/gitea-ssd/db/k3smnt` with `chown`.

    ~~~bash
    $ sudo chown systemd-coredump:root /mnt/gitea-ssd/db/k3smnt
    ~~~

    The `k3smnt` folder will remain the mount point for the volume where the database files are stored, and the `postgres` user that runs all the PostgreSQL services in the Kubernetes container also needs permissions over that `k3smnt` directory. Otherwise, it won't be able to access the folder with the database's datafiles.

10. Verify that the changed ownership is as expected.

    - For the `k3smnt` folder, `systemd-coredump` user **and** `root` group ownership.

        ~~~bash
        $ ls -al /mnt/gitea-ssd/db
        total 28
        drwxr-xr-x 4 root             root  4096 Aug  5  2022 .
        drwxr-xr-x 4 root             root  4096 Aug  5  2022 ..
        drwx------ 4 systemd-coredump root  4096 May 29 22:51 k3smnt
        drwx------ 2 root             root 16384 Aug  5  2022 lost+found
        ~~~

    - For the `14` and `15` folders, `systemd-coredump` user **and** group ownerships.

        ~~~bash
        $ sudo ls -al /mnt/gitea-ssd/db/k3smnt/
        total 16
        drwx------  4 root             root             4096 May 29 22:51 .
        drwxr-xr-x  4 root             root             4096 Aug  5  2022 ..
        drwxr-xr-x 19 systemd-coredump systemd-coredump 4096 May 29 22:46 14
        drwxr-xr-x  2 systemd-coredump systemd-coredump 4096 May 29 22:51 15
        ~~~

        Again, remember that this `systemd-coredump` will correspond, due to have the same Linux user ID, to the `postgres` user running the PostgreSQL server in the Kubernetes pod.

### _Stage 4. Creating the Kustomize update project for PostgreSQL_

In this stage you'll see how to create the Kustomize project for deploying the [Tianon Gravi's **postgres-upgrade** Docker image](https://hub.docker.com/r/tianon/postgres-upgrade/) you need to upgrade your PostgreSQL database files. Remember that the concrete image this guide will use is the one tagged as [14-to-15](https://hub.docker.com/layers/tianon/postgres-upgrade/14-to-15/images/sha256-18da581c7839388bb25fd3f8b3170b540556ef3eb69d9afcc0662fcaa52d864e?context=explore).

Instead of creating this project from scratch, you can base it on the one you already have for the PostgreSQL instance running in the Gitea setup.

1. Copy **only** the PostgreSQL component's Kustomize subproject found within your Gitea setup's main project.

    ~~~bash
    $ cp -r $HOME/k8sprjs/gitea/components/db-postgresql $HOME/k8sprjs/postgres-upgrade
    ~~~

    Notice that the folder path pattern is the same as in the other guides, and that I've renamed the copied folder to `postgres-upgrade` to make it easily recognizable.

2. For executing the upgrade, you won't need all the files used to deploy your Gitea's PostgreSQL instance, so remove the unnecessary ones.

    - To reduce the chance of confusion, get inside the `postgres-upgrade` folder.

        ~~~bash
        $ cd $HOME/k8sprjs/postgres-upgrade
        ~~~

    - Remove the unnecessary files with `rm` as follows.

        ~~~bash
        $ rm configs/dbnames.properties configs/initdb_exporter_user.sh configs/initdb_gitea.sh resources/db-postgresql.service.yaml secrets/dbusers.pwd
        ~~~

        With the command above you remove:
        
        - A properties file with the names of the PostgreSQL users and the Gitea database.
        - Shell scripts that created the PostgreSQL users for the metrics exporter and for the Gitea instance.
        - The `yaml` definition of the service that exposes the PostgreSQL port, which is not required in the upgrade process since you won't need to access the PostgreSQL server instance at all.
        - The `pwd` file with the encrypted PostgreSQL users' passwords.

3. For the sake of clarity and reduce the chance of confusion with the files of the original PostgreSQL component subproject, you should also rename the files within the `resources` folder.

    ~~~bash
    $ cd $HOME/k8sprjs/postgres-upgrade/resources
    $ mv db-postgresql.persistentvolumeclaim.yaml postgres-upgrade.persistentvolumeclaim.yaml
    $ mv db-postgresql.statefulset.yaml postgres-upgrade.statefulset.yaml
    ~~~~

    Of course, renaming the files is not enough to make the deployment work later. You'll reconfigure those two yaml definitions, and others, later.

4. At this point, you're missing the yaml definition of the persistent volume where to put your PostgreSQL data files. The pod where you'll run the upgrade will have to access that volume to work. Copy the definition from your Gitea Kustomize project.

    ~~~bash
    $ cp $HOME/k8sprjs/gitea/resources/db-gitea.persistentvolume.yaml $HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml
    ~~~

    See that I've renamed the copy directly so it fits the PostgreSQL upgrade project but, like the other resource files, you'll have to reconfigure it later.

5. You also need a Kubernetes definition for the namespace that will group your deployment's resources. Copy it from your Gitea Kustomize project and rename it like in the previous steps.

    ~~~bash
    $ cp $HOME/k8sprjs/gitea/resources/gitea.namespace.yaml $HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml
    ~~~

6. Verify that you have in your `postgres-upgrade` folder a file tree like the one below.

    ~~~bash
    $ tree -F $HOME/k8sprjs/postgres-upgrade
    /home/YOUR_USER_HERE/WS/k8sprjs/postgres-upgrade
    ├── configs
    │   └── postgresql.conf
    ├── kustomization.yaml
    └── resources
        ├── postgres-upgrade.namespace.yaml
        ├── postgres-upgrade.persistentvolumeclaim.yaml
        ├── postgres-upgrade.persistentvolume.yaml
        └── postgres-upgrade.statefulset.yaml

    2 directories, 6 files
    ~~~

### _Stage 5. Configuring the PostgreSQL's Kustomize update project_

The PostgreSQL Kustomize project you copied declares a pod in a sidecar configuration, where one container runs the PostgreSQL server instance and a second one runs the exporter agent of Prometheus metrics for that server instance. For executing the update process you don't need that exporter agent at all, so you must take it out completely from this PostgreSQL Kustomize update project you're working on here. That's the main change you have to do, but not the only one.

Next, I show you what has changed in the project after applying the required modifications.

1. NEW file `$HOME/k8sprjs/postgres-upgrade/configs/dbdatapaths.properties`.

    ~~~properties
    postgresql-db-data-old-path=/var/lib/postgresql/data/14
    postgresql-db-data-new-path=/var/lib/postgresql/data/15
    ~~~

    > **BEWARE!**  
    > You have to create this `dbdatapaths.properties` file and fill it as shown above.

    For the upgrade to work, you need to specify where the "old" data is and where do you want to store its "new" version. The paths declared in this `properties` file are enabled as environmental variables in the pod's declaration you'll see later.

2. File `$HOME/k8sprjs/postgres-upgrade/configs/postgresql.conf`.

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

    This is exactly the same file as [in the original PostgreSQL deployment](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#configuration-file-postgresql-conf). In this migration from **major** version 14 to 15 of PostgreSQL, there's no need to change any option from this `postgresql.conf` file.

    > **BEWARE!**  
    > Between major versions, options can change or be removed altogether. Always check if the options set for your software remain valid in the newer version. An easy way to do so for PostgreSQL is by using [this page that offers a configuration comparator between versions](https://pgconfig.rustprooflabs.com/param/change/14/15).

3. File `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: Namespace

    metadata:
      name: postgres-upgrade
    ~~~

    Only one change in this `Namespace` definition, the `metadata.name` has gone from `gitea` to `postgres-upgrade`.

4. File `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: postgres-upgrade
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: postgres-upgrade
      resources:
        requests:
          storage: 3.5G
    ~~~

    There are only a couple of "cosmetic" changes in the yaml above.

    - `metadata.name`: from `db-postgresql` to `postgres-upgrade`.
    - `spec.volumeName`: from `db-gitea` to `postgres-upgrade`.

    These modifications are meant to ensure that every resource is named after the Kustomize project they're in. Compare this with the original file shown [in the third part of the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgreSQL-storage).

5. File `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml`. 

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolume

    metadata:
      name: postgres-upgrade
    spec:
      capacity:
        storage: 3.5G
      volumeMode: Filesystem
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      persistentVolumeReclaimPolicy: Retain
      local:
        path: /mnt/gitea-ssd/db/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent01
    ~~~

    Here there's only another "cosmetic" change, in which the `metadata.name` is changed from `db-gitea` to `postgres-upgrade`. The rest must remain the same, since nothing else has changed in any regard. Compare it with the `db-gitea.persistentvolume.yaml` file shown [in the fifth part of the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#persistent-volumes).

6. File `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.statefulset.yaml`. 

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: postgres-upgrade
    spec:
      replicas: 1
      serviceName: postgres-upgrade
      template:
        spec:
          containers:
          - name: server
            image: tianon/postgres-upgrade:14-to-15
            ports:
            - containerPort: 50432
            resources:
              limits:
                memory: 320Mi
            env:
            - name: PGDATAOLD
              valueFrom:
                configMapKeyRef:
                  name: postgres-upgrade
                  key: postgresql-db-data-old-path
            - name: PGDATANEW
              valueFrom:
                configMapKeyRef:
                  name: postgres-upgrade
                  key: postgresql-db-data-new-path
            volumeMounts:
            - name: postgresql-storage
              mountPath: /var/lib/postgresql/data
            - name: postgresql-config
              subPath: postgresql.conf
              mountPath: /etc/postgresql/postgresql.conf
          volumes:
          - name: postgresql-config
            configMap:
              name: postgres-upgrade
              items:
              - key: postgresql.conf
                path: postgresql.conf
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: postgres-upgrade
    ~~~

    This stateful set definition is the element that requires the most significant changes.

    - All the `db-postgresql` names have been changed to `postgres-upgrade`.
    - The `metrics` container has been removed completely.
    - At the remaining `server` container.
        - The `image` specified is the [Tianon Gravi's custom one indicated earlier in this guide](https://hub.docker.com/layers/tianon/postgres-upgrade/14-to-15/images/sha256-18da581c7839388bb25fd3f8b3170b540556ef3eb69d9afcc0662fcaa52d864e?context=explore).
        - The `containerPort` here reflects the port opened by the `pg_upgrade` command. That's the program you'll have to execute later within this container to perform the upgrade.
        - The `args` block has been removed.
        - The `env` block now has two particular variables:

            - `PGDATAOLD`: full folder path to your current "old" database files.
            - `PGDATANEW`: full path to the folder to copy the updated database files.

            These environmental variables not only specify paths, they also make Tianon's image to run in **copy mode** to perform the update of the database files. Notice that the key specified on each variable is one of the parameters declared in the `dbdatapaths.properties`.

        - In the `volumeMounts` section, the path to the `initdb.sh` script has been deleted.
    - At the `volumes` section, the `initdb.sh` item has been removed.

    Compare this version of the stateful set with the one [in the third part of the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-statefulset-resource).

7. File `$HOME/k8sprjs/postgres-upgrade/kustomization.yaml`

    ~~~yaml
    # PostgreSQL upgrade setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: postgres-upgrade

    commonLabels:
      app: postgres-upgrade

    resources:
    - resources/postgres-upgrade.namespace.yaml
    - resources/postgres-upgrade.persistentvolumeclaim.yaml
    - resources/postgres-upgrade.persistentvolume.yaml
    - resources/postgres-upgrade.statefulset.yaml

    replicas:
    - name: postgres-upgrade
      count: 1

    images:
    - name: tianon/postgres-upgrade
      newTag: 14-to-15

    configMapGenerator:
    - name: postgres-upgrade
      envs:
      - configs/dbdatapaths.properties
      files:
      - configs/postgresql.conf
    ~~~

    This `kustomization.yaml` file has the following modifications.

    - The `db-postgresql` string has been changed for `postgres-upgrade`.
    - Has an added `namespace` for the entire deployment.
    - In `resources` there are several changes:
        - The file that declared the service resource has been removed from the list.
        - The files declaring the namespace and the persistent volume have been added.
    - In `images` is specified the Tianon's custom image.
    - In the `configMapGenerator` there also have been a number of changes.
      - There's now an `envs` section using the properties file as source of values for environmental variables, the ones you saw declared earlier in the stateful set declaration.
      - Only the `postgresql.conf` remains in the `files` block.
    - The `secretGenerator` section has been removed.

    Compare this `kustomization.yaml` file with its version [at the third part of the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-project).

### _Stage 6. Deploying the PostgreSQL's Kustomize update project_

Your Kustomize project is ready but, before you deploy it, you need to know beforehand what's going to happen when you deploy it.

- First, once the container is running Tianon's image, it will try to execute the upgrade of your database files.
- If the upgrade is successful, it'll then try to start the PostgreSQL server. This will fail with a particular error.

Also, be aware that, depending on the size of the database you're upgrading and the capacity available in your Kubernetes cluster for this pod, the process may take a while or just a few seconds.

Since you want to be able to see how the upgrade goes, you'll need to prepare a couple of `kubectl` commands beforehand.

1. Reserve one shell to launch and **leave running** the command below to monitor the resources existing in the `postgres-upgrade` namespace.

    ~~~bash
    $ watch kubectl get all -n postgres-upgrade
    ~~~

    Be aware that the `get all` option don't really show every resource under the namespace, but it'll show you the pod and the most relevant resources related to it.

2. Prepare in another shell a `kubectl` command to capture the logs from the pod that will execute the upgrade.

    ~~~bash
    $ kubectl logs -f -n postgres-upgrade postgres-upgrade-0 server >> postgres-upgrade.log
    ~~~

    Notice the `-f` option, which makes the command to stream the logs outputted by the pod. Wait till the corresponding `postgres-upgrade-0` pod shows the `Running` status. Be aware that this command won't return anything since it's redirecting it's output to the `postgres-upgrade.log` file.

3. Open a third shell in your `kubectl` client system, then just deploy the `postgres-upgrade` project.

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/postgres-upgrade
    ~~~

    > **BEWARE!**  
    > Remember that the pod will start to execute the update on its own as soon as its able to.

4. When the `postgres-upgrade-0` pod fails, the `kubectl logs` command will also exit automatically. That's the moment to check out how the upgrade process went. Open the `postgres-upgrade.log` file and, if the upgrade went well, you should see the following lines at the end.

    ~~~log
    ...
    Performing Upgrade
    ------------------
    Analyzing all rows in the new cluster                       ok
    Freezing all rows in the new cluster                        ok
    Deleting files from new pg_xact                             ok
    Copying old pg_xact to new server                           ok
    Setting oldest XID for new cluster                          ok
    Setting next transaction ID and epoch for new cluster       ok
    Deleting files from new pg_multixact/offsets                ok
    Copying old pg_multixact/offsets to new server              ok
    Deleting files from new pg_multixact/members                ok
    Copying old pg_multixact/members to new server              ok
    Setting next multixact ID and offset for new cluster        ok
    Resetting WAL archives                                      ok
    Setting frozenxid and minmxid counters in new cluster       ok
    Restoring global objects in the new cluster                 ok
    Restoring database schemas in the new cluster               ok
    Copying user relation files                                 ok
    Setting next OID for new cluster                            ok
    Sync data directory to disk                                 ok
    Creating script to delete old cluster                       ok
    Checking for extension updates                              ok

    Upgrade Complete
    ----------------
    Optimizer statistics are not transferred by pg_upgrade.
    Once you start the new server, consider running:
        /usr/lib/postgresql/15/bin/vacuumdb --all --analyze-in-stages

    Running this script will delete the old cluster's data files:
        ./delete_old_cluster.sh
    ~~~

    This marks the end of the upgrade process performed by PostgreSQL's `pg_upgrade` command.

    > **BEWARE!**  
    > Notice the recommendation right below the `Upgrade Complete` message in the log above. It's a command you would have to run from within the PostgreSQL `server` container while its running. Also, you would have to impersonate the `postgres` service user to execute it.
    >
    > To do all this, remember the following.
    >
    > - You can access containers with shell terminals, as explained [here in the G036 guide](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers).
    > - You can execute commands in containers impersonating system users with the `runuser` command, as you can see done [in the step 4 of the post-update procedure applied to Nextcloud, detailed in the appendix guide 14](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#procedure).

5. If you're curious about why the `postgres-upgrade-0` pod has failed, execute the kubectl logs command again but without the streaming option and not redirecting the output to a file.

    ~~~bash
    $ kubectl logs -n postgres-upgrade postgres-upgrade-0 server
    Performing Consistency Checks
    -----------------------------
    Checking cluster versions                                   ok
    Checking database user is the install user                  ok
    Checking database connection settings                       ok
    Checking for prepared transactions                          ok
    Checking for system-defined composite types in user tables  ok
    Checking for reg* data types in user tables                 ok
    Checking for contrib/isn with bigint-passing mismatch       ok
    Creating dump of global objects                             ok
    Creating dump of database schemas                           ok

    New cluster database "gitea" is not empty: found relation "public.version"
    Failure, exiting
    ~~~

    It seems that, after executing the upgrade, the Tianon's image also tries to run the PostgreSQL instance but fails when it tries to use the upgraded (or maybe the old) database files. At the time of writing this I haven't discovered the reason for this issue, but it's not a problem since the process has generated the updated datafiles which is what matters at this point.

On the other hand, you'll also want to verify that the upgrade process has truly written "something" on storage. To check this, do the following:

1. Open a shell in the K8s agent node where this pod has run, the `k3sagent01` in this case, then impersonate the `systemd-coredump` user.

    ~~~bash
    $ sudo -S -u systemd-coredump /bin/bash -l
    ~~~

2. Get into the `/mnt/gitea-ssd/db/k3smnt/` folder.

    ~~~bash
    $ cd /mnt/gitea-ssd/db/k3smnt/
    ~~~

3. Compare the sizes of the two folders present there with the `du` command.

    ~~~bash
    $ du -sh 14 15
    73M     14
    57M     15
    ~~~

    There are two conclusions you can draw from the output above.

    - The upgrade has certainly written something in the `15` folder.
    - The upgrade has compacted significantly the updated copy of the database files.

### _Stage 7. Undeploying the PostgreSQL's Kustomize update project_

Once the upgrade is done, you don't need the `postgres-upgrade` project deployed in your K8s cluster. Just remove it with `kubectl` like you would do with any other deployment.

~~~bash
$ kubectl delete -k $HOME/k8sprjs/postgres-upgrade
~~~

### _Stage 8. Adjusting PostgreSQL datafiles's associated configuration_

The upgrade process **only** migrates the data to new datafiles, **not** the configuration attached to the old datafiles. In the release 14 of PostgreSQL, there are five configuration files that have their exact equivalent in the release 15. They are located in the main folder storing the datafiles, the `14` and `15` ones under the path `/mnt/gitea-ssd/db/k3smnt` of the corresponding K3s agent node (`k3sagent01`). These configuration files are:

- `pg_hba.conf`
- `pg_ident.conf`
- `postgresql.auto.conf`
- `postgresql.conf`
- `postmaster.opts`

Some of them will present differences due to particularities of the respective PostgreSQL releases they come from. Those changes shouldn't worry you much, although you might investigate them to be sure they won't mean trouble later. The differences you should take care to validate are those that may appear in the newer version's `pg_hba.conf` file, since this file controls the access to the PostgreSQL instance.

> **BEWARE**  
> If the `pg_hba.conf` file is not properly configured, your Gitea server instance won't be able to access its own PostgreSQL database later.

To check out and amend any relevant difference in the **new** `pg_hba.conf` file, do the following.

1. Get into your Kubernetes agent node (`k3sagent01`), then impersonate the `systemd-coredump` user.

    ~~~bash
    $ sudo -S -u systemd-coredump /bin/bash -l
    ~~~

2. Go to the `/mnt/gitea-ssd/db/k3smnt/` folder.

    ~~~bash
    $ cd /mnt/gitea-ssd/db/k3smnt/
    ~~~

3. Use `diff` to compare the old and new versions of the `pg_hba.conf` file.

    ~~~bash
    $ diff 14/pg_hba.conf 15/pg_hba.conf
    99,100d98
    <
    < host all all all scram-sha-256
    ~~~

    By default, the `diff` command only returns the differences. Above you can see that it has detected that two lines exist on the 14's version side that the 15's version doesn't have. You need to put those lines in the `15/pg_hba.conf`.

4. Since the two versions of the `pg_hba.conf` file only differ in those two lines, the fastest way to put them in the 15's version is by overwriting the new `15`'s file with the old `14`'s one. You can do this with the `cp` command.

    ~~~bash
    $ cp -i 14/pg_hba.conf 15/pg_hba.conf
    cp: overwrite '15/pg_hba.conf'? y
    ~~~ 

    Notice that I've used the `-i` option to make `cp` ask for interactive confirmation **before** overwriting the `15/pg_hba.conf` file.

5. Compare again the two files with diff.

    ~~~bash
    $ diff 14/pg_hba.conf 15/pg_hba.conf
    $
    ~~~

    It shouldn't return any output whatsoever now, as shown above.

You can apply the same steps with the other configuration files, although in this particular case it won't be necessary since they're fine as they are (with default values).

### _Stage 9. Reconfiguring the Gitea's Kustomize project_

Your updated database files are **not** in the path expected by the PostgreSQL instance of your Gitea platform. Therefore, you need to set the new path in the Kustomize project of the PostgreSQL component. Open the PostgreSQL Kustomize subproject within the Gitea's one and do the following.

1. Determine the **absolute** path to your updated database files, but from the point of view of the PostgreSQL server's container.

    Remember that the [PostgreSQL setup described in the G034 guide](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md) was using the **default** path: `/var/lib/postgresql/data`
      - This path is the container's mount point for the PostgreSQL storage volume, and its enabled in the `volumeMounts` block of the `server` container in the `db-postgresql.statefulset.yaml` file.

    The **real** path to the directory containing your updated database files is `/mnt/gitea-ssd/db/k3smnt/15`.
      - The `k3smnt` folder is the real mount point in your K8s agent node and, in the current configuration, it corresponds to the "virtual" `/var/lib/postgresql/data` path.

    Therefore, the **container's** absolute path to your updated database files is:

    ~~~bash
    /var/lib/postgresql/data/15
    ~~~

2. Let's set the path as an environmental variable of the PostgreSQL container. Start by creating a new configuration file in the PostgreSQL subproject as follows.

    ~~~bash
  	$ touch $HOME/k8sprjs/gitea/components/db-postgresql/configs/dbfilespath.properties
    ~~

3. Edit the `dbfilespath.properties` so it looks like below.

    ~~~properties
    postgresql-db-files-path=/var/lib/postgresql/data/15
    ~~~

4. Edit the `kustomization.yaml` file of the PostgreSQL subproject and do the following changes:

    - At the `images` section, update the `newTag` parameter to the newer `15.3` PostgreSQL version.

        ~~~yaml
        # PostgreSQL setup
        apiVersion: kustomize.config.k8s.io/v1beta1
        kind: Kustomization
        ...
        images:
        - name: postgres
          newTag: 15.3-bullseye
        ...
        ~~~

    - At the `envs` section of the `configMapGenerator` block, add the reference to the `dbfilespath.properties` file.

        ~~~yaml
        ...
        configMapGenerator:
        - name: db-postgresql
          envs:
          - configs/dbfilespath.properties
          - configs/dbnames.properties
        ...
        ~~~

5. Edit the `db-postgresql.statefulset.yaml` file in your PostgreSQL project to make the changes indicated next.

    - To make it coherent with the new major version, update the `image` specified to the `server` container.

        ~~~yaml
        apiVersion: apps/v1
        kind: StatefulSet

        metadata:
          name: db-postgresql
          ...
              containers:
              - name: server
                image: postgres:15.3-bullseye
              ...
        ~~~

        Since this value is replaced by the one in the `kustomization.yaml` file, this change may seem useless. Consider it some sort of reminder of that you **did** check this file when making the upgrade to a new **major** version, something usually you won't need to do when updating to minor releases.

    - Add the `env` variable called `PGDATA` to the server container.

        ~~~yaml
        apiVersion: apps/v1
        kind: StatefulSet

        metadata:
          name: db-postgresql
          ...
              containers:
              - name: server
              ...
                env:
                ...
                - name: PGDATA
                  valueFrom:
                    configMapKeyRef:
                      name: db-postgresql
                      key: postgresql-db-files-path
                ...
        ~~~

      The environmental variable `PGDATA` tells PostgreSQL where to look for its database files for when the default path is not used. Notice that the `key` is the parameter configured earlier in the `dbfilespath.properties` file.

6. Don't forget that, in this scenario, you also want to update your Gitea instance too. Since in this case it's just a switch to a new **MINOR** version, just change the reference to the Gitea image in the `kustomization.yaml` declaration of the Gitea server component's **subproject**. Remember that this file is found at `$HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml`.

    ~~~yaml
    # Gitea server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    ...
    images:
    - name: gitea/gitea
      newTag: '1.19.3'
    ...
    ~~~

    The newTag now selects the newer version `1.19.3` of Gitea.

7. Ensure you've saved all the changes done in the previous steps.

### _Stage 10. Redeploying the Gitea platform_

The only thing left to do is to deploy again the whole **Gitea** project. Since errors may occur, it's better to be ready with some `kubectl` commands prepared.

1. On one terminal, launch and **leave running** this command to monitor the resources under the `gitea` namespace.

    ~~~bash
    $ watch kubectl get all -n gitea
    ~~~

    Be aware that the `get all` option omit things, but will be enough to detect pods returning errors.

2. In another shell, prepare this other `kubectl` command.

    ~~~bash
    $ kubectl logs -f -n gitea gitea-db-postgresql-0 server >> gitea-db-postgres.log
    ~~~

    Don't execute it until the corresponding `gitea-db-postgresql-0` pod reaches the `Running` status. This command won't return anything since it's redirecting the output to the `gitea-db-postgres.log` file.

3. Finally, in a third shell, execute the deployment of your Gitea's Kustomize project.

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/gitea
    ~~~

Give this deployment some minutes to finish, since your new Gitea instance may need some minutes to finish its own update process. If all is well, your Gitea server should be back and running as it was before, although completely renewed.

If you detect problems, check the `gitea-db-postgres.log` to see if PostgreSQL has reported something odd or, if that's not enough to detect the source of the issue, remember to use the techniques explained [in the G036 guide for monitoring and diagnosis](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md) of your Kubernetes cluster.

### _Stage 11. Cleaning up the old data_

The last thing you may want to do is to free the storage space taken by the old version of your PostgreSQL's database files. This implies, of course, the removal of the entire folder holding those files.

1. Shell into your Kubernetes agent node, then impersonate the `systemd-coredump` user.

    ~~~bash
    $ sudo -S -u systemd-coredump /bin/bash -l
    ~~~

2. Get into the `/mnt/gitea-ssd/db/k3smnt/` folder.

    ~~~bash
    $ cd /mnt/gitea-ssd/db/k3smnt/
    ~~~

3. If you're sure of this action, remove the folder with the old database files.

    ~~~bash
    $ rm -rf 14
    ~~~

    In this guide's scenario, remember that the folder with the old database files was the one named `14`.

## Kustomize project only for updating PostgreSQL included in this guide series

You can find the Kustomize project meant **only for updating PostgreSQL databases to newer MAJOR versions** at the attached folder indicated below.

- `k8sprjs/postgres-upgrade`

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME`
- `$HOME/k8sprjs/gitea`
- `$HOME/k8sprjs/gitea/resources`
- `$HOME/k8sprjs/gitea/components/db-postgresql`
- `$HOME/k8sprjs/gitea/components/server-gitea`
- `$HOME/k8sprjs/postgres-upgrade`
- `$HOME/k8sprjs/postgres-upgrade/configs`
- `$HOME/k8sprjs/postgres-upgrade/resources`

### _Files in `kubectl` client system_

- `$HOME/gitea-db-postgres.log`
- `$HOME/postgres-upgrade.log`
- `$HOME/k8sprjs/gitea/resources/db-gitea.persistentvolume.yaml`
- `$HOME/k8sprjs/gitea/resources/gitea.namespace.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/kustomization.yaml`
- `$HOME/k8sprjs/gitea/components/db-postgresql/configs/dbfilespath.properties`
- `$HOME/k8sprjs/gitea/components/db-postgresql/resources/db-postgresql.statefulset.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml`
- `$HOME/k8sprjs/postgres-upgrade/kustomization.yaml`
- `$HOME/k8sprjs/postgres-upgrade/configs/dbdatapaths.properties`
- `$HOME/k8sprjs/postgres-upgrade/configs/postgresql.conf`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.statefulset.yaml`

### _Folders in the K3s agent node_

- `/mnt/gitea-ssd/db/k3smnt/`
- `/mnt/gitea-ssd/db/k3smnt/14`
- `/mnt/gitea-ssd/db/k3smnt/15`

### _Files in the K3s agent node_

- `/mnt/gitea-ssd/db/k3smnt/14/pg_hba.conf`
- `/mnt/gitea-ssd/db/k3smnt/14/pg_ident.conf`
- `/mnt/gitea-ssd/db/k3smnt/14/postgresql.auto.conf`
- `/mnt/gitea-ssd/db/k3smnt/14/postgresql.conf`
- `/mnt/gitea-ssd/db/k3smnt/14/postmaster.opts`
- `/mnt/gitea-ssd/db/k3smnt/15/pg_hba.conf`
- `/mnt/gitea-ssd/db/k3smnt/15/pg_ident.conf`
- `/mnt/gitea-ssd/db/k3smnt/15/postgresql.auto.conf`
- `/mnt/gitea-ssd/db/k3smnt/15/postgresql.conf`
- `/mnt/gitea-ssd/db/k3smnt/15/postmaster.opts`

### _Folders in the PostgreSQL container_

- `/var/lib/postgresql/data`
- `/var/lib/postgresql/data/14`
- `/var/lib/postgresql/data/15`

## References

### _PostgreSQL_

- [PostgreSQL's official page](https://www.postgresql.org/)
- [Upgrading a PostgreSQL Cluster](https://www.postgresql.org/docs/current/upgrading.html)
- [Official documentation of the `pg_upgrade` command](https://www.postgresql.org/docs/current/pgupgrade.html)
- [How to upgrade PostgreSQL from 14 to 15](https://www.kostolansky.sk/posts/upgrading-to-postgresql-15/)
- [How to Upgrade PostgreSQL in Docker and Kubernetes](https://www.cloudytuts.com/tutorials/docker/how-to-upgrade-postgresql-in-docker-and-kubernetes/)
- [How to upgrade my postgres in docker container while maintaining my data? 10.3 to latest 10.x or to 12.x](https://stackoverflow.com/questions/62790302/how-to-upgrade-my-postgres-in-docker-container-while-maintaining-my-data-10-3-t)
- [How to upgrade software (e.g. PostgreSQL) running in a Docker container?](https://superuser.com/questions/810363/how-to-upgrade-software-e-g-postgresql-running-in-a-docker-container)
- [How do I upgrade Docker Postgresql without removing existing data?](https://stackoverflow.com/questions/46672602/how-do-i-upgrade-docker-postgresql-without-removing-existing-data)
- [postgresql.conf comparison. Postgres Config Changes: 14 to 15](https://pgconfig.rustprooflabs.com/param/change/14/15)
- [PostgreSQL Docker image. Quick reference. `PGDATA` environmental variable](https://github.com/docker-library/docs/blob/master/postgres/README.md#pgdata)
- [The `pg_hba.conf` File](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)

### _Tianon Gravi's PostgreSQL upgrade Docker image_

- [pg_upgrade, Docker style on Hub Docker](https://hub.docker.com/r/tianon/postgres-upgrade/)
- [pg_upgrade, Docker style on GitHub](https://github.com/tianon/docker-postgres-upgrade)
- [Docker image version 14-to-15](https://hub.docker.com/layers/tianon/postgres-upgrade/14-to-15/images/sha256-18da581c7839388bb25fd3f8b3170b540556ef3eb69d9afcc0662fcaa52d864e?context=explore)
- [Tianon Gravi on GitHub](https://github.com/tianon)

### _Gitea_

- [Installation. Database Preparation](https://docs.gitea.io/en-us/database-prep/)

## Navigation

[<< Previous (**G915. Appendix 15**)](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md)