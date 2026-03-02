# G910 - Appendix 10 ~ Updating PostgreSQL to a newer major version

- [Upgrading a containerized PostgreSQL server is not straightforward](#upgrading-a-containerized-postgresql-server-is-not-straightforward)
- [Concerns](#concerns)
  - [Custom image only for PostgreSQL upgrading](#custom-image-only-for-postgresql-upgrading)
  - [Beware of the storage space](#beware-of-the-storage-space)
  - [Compatibility with other software](#compatibility-with-other-software)
  - [Disabling access to the PostgreSQL instance while upgrading](#disabling-access-to-the-postgresql-instance-while-upgrading)
  - [Reconfiguring Forgejo's deployment](#reconfiguring-forgejos-deployment)
- [Upgrade procedure (for Forgejo's PostgreSQL instance)](#upgrade-procedure-for-forgejos-postgresql-instance)
  - [Stage 1. Identifying the PostgreSQL version you have and the one you want](#stage-1-identifying-the-postgresql-version-you-have-and-the-one-you-want)
  - [Stage 2. Undeploying the Forgejo platform](#stage-2-undeploying-the-forgejo-platform)
  - [Stage 3. Preparing the data folders](#stage-3-preparing-the-data-folders)
  - [Stage 4. Creating the Kustomize update project for PostgreSQL](#stage-4-creating-the-kustomize-update-project-for-postgresql)
  - [Stage 5. Configuring the PostgreSQL's Kustomize update project](#stage-5-configuring-the-postgresqls-kustomize-update-project)
  - [Stage 6. Deploying the PostgreSQL's Kustomize update project](#stage-6-deploying-the-postgresqls-kustomize-update-project)
    - [Checking the upgraded database files](#checking-the-upgraded-database-files)
  - [Stage 7. Undeploying the PostgreSQL's Kustomize update project](#stage-7-undeploying-the-postgresqls-kustomize-update-project)
  - [Stage 8. Adjusting PostgreSQL datafiles's associated configuration](#stage-8-adjusting-postgresql-datafiless-associated-configuration)
  - [Stage 9. Reconfiguring the PostgreSQL's Kustomize subproject](#stage-9-reconfiguring-the-postgresqls-kustomize-subproject)
  - [Stage 10. Redeploying the Forgejo platform](#stage-10-redeploying-the-forgejo-platform)
  - [Stage 11. Cleaning up the old data](#stage-11-cleaning-up-the-old-data)
- [Kustomize project only for updating PostgreSQL included in this guide](#kustomize-project-only-for-updating-postgresql-included-in-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
  - [Folders in the K3s agent node](#folders-in-the-k3s-agent-node)
  - [Files in the K3s agent node](#files-in-the-k3s-agent-node)
  - [Folders in the PostgreSQL upgrade container](#folders-in-the-postgresql-upgrade-container)
- [References](#references)
  - [PostgreSQL](#postgresql)
  - [Other contents about upgrading PostgreSQL to a newer major version](#other-contents-about-upgrading-postgresql-to-a-newer-major-version)
  - [Tianon Gravi's PostgreSQL upgrade Docker image](#tianon-gravis-postgresql-upgrade-docker-image)
  - [Forgejo](#forgejo)
- [Navigation](#navigation)

## Upgrading a containerized PostgreSQL server is not straightforward

PostgreSQL runs well as a containerized instance and can be upgraded easily to new minor or debug versions. However, updating it to a new _MAJOR_ version is not a straightforward affair. Still, there is a way that simplifies this process a bit, and this chapter guides you through it for the time you need to upgrade [the PostgreSQL container part of the Forgejo setup](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md).

## Concerns

When you read about the [upgrade procedure of a PostgreSQL server](https://www.postgresql.org/docs/current/upgrading.html) to a new major version, you realize that it has not been adapted for containerized environments. This raises its own set of concerns that you must factor in before you deal with the upgrade itself.

### Custom image only for PostgreSQL upgrading

To update PostgreSQL to a new major version "in place", avoiding the common method of dumping and restoring the databases, you need both the old and the new versions of the software installed in the host system. Then, you would execute the upgrade command provided **by the new version of PostgreSQL**. This updates the system tables' layout or the databases' internal data storage used in the PostgreSQL server.

If the upgrade is done by PostgreSQL's new version, why would you need the old one too? The [official documentation of the `pg_upgrade` command](https://www.postgresql.org/docs/current/pgupgrade.html) does not really clarify this point, it only says in its _Usage step 10 "Run pg_upgrade"_ that the `pg_upgrade` command requires the "specification" of both the old and the new cluster (meaning the server instances).

This particularity is what makes updating to a newer major version of PostgreSQL in Kubernetes more difficult than it should, since no official PostgreSQL container image comes with two major versions of the software. Thankfully, [Tianon Gravi](https://ram.tianon.xyz/) and other collaborators maintain a collection of [custom Docker images](https://hub.docker.com/r/tianon/postgres-upgrade/) containing exactly that: an older and a newer version of PostgreSQL. By using the right custom image, updating to a new major version of PostgreSQL in a containerized environment is less complicated.

### Beware of the storage space

Since the upgrade process could have a problem while its running, the safest way to do it is by applying it over a copy of the database files you want to upgrade. The copy mode is, in fact, the default behavior of the `pg_upgrade` command. The main concern with this method is to ensure beforehand that you have enough storage space for the new data files.

When the update is done, you will end up with two copies of your PostgreSQL database instance's data files:

- One copy runs in the previous PostgreSQL version, which you can consider the "original" one. Preserve it in case something goes wrong with the upgrade and you have to downgrade back to the old PostgreSQL version.

- One copy upgraded to run in the newer PostgreSQL version.

### Compatibility with other software

Remember to **check the compatibility** of the software (Forgejo in this case) using your PostgreSQL database with the new version you want to upgrade it to. That software may not have the proper drivers to connect to the newer version of PostgreSQL yet, or maybe it requires some deprecated or unavailable features in that more recent PostgreSQL release.

### Disabling access to the PostgreSQL instance while upgrading

While the upgrade process is running (and messing with your database), you do not want anyone or anything to try accessing your PostgreSQL server in such a critical time. So, to be sure, you will have to **stop or undeploy** the service or platform using the PostgreSQL server you are upgrading. In a properly built and managed Kubernetes setup (with Kustomize projects, for instance) this should not be much of an issue.

### Reconfiguring Forgejo's deployment

After your PostgreSQL data is updated, the last thing you will have to revise is the configuration of your Forgejo deployment. In particular, you will need to point the PostgreSQL server to the folder where the updated database files are stored.

On the other hand, you will have to revise the configuration of your PostgreSQL instance and ensure that it is compatible with the newer PostgreSQL server version you want to run in your Kubernetes cluster.

## Upgrade procedure (for Forgejo's PostgreSQL instance)

The upgrade procedure is rather elaborated, so this chapter splits it in stages. The next sections go through them to upgrade the PostgreSQL instance of the Forgejo platform deployed in the [chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md).

### Stage 1. Identifying the PostgreSQL version you have and the one you want

The trick of this upgrade procedure is the use of a particular Docker image that allows you migrate your PostgreSQL database files from their current version to the newer one. First thing to do is to identify which major PostgreSQL version you are migrating from, and which newer one you want to upgrade to:

1. In the Forgejo's setup, PostgreSQL is deployed as a `StatefulSet`. To get its current version you can use `kubectl` as follows:

    > [!IMPORTANT]
    > **This appendix's Forgejo setup uses an older major PostgreSQL version than the one deployed in the main content**\
    > The Forgejo setup has been redeployed from scratch with the previous major version of PostgreSQL instead to demonstrate the upgrade process. The exact differences between this "downgraded" deployment and [the one in the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md) are:
    >
    > - This appendix starts with a Forgejo platform running a PostgreSQL `17.8-trixie` container. This is the one to be upgraded in this appendix to PostgreSQL `18.2-trixie`.
    >
    > - While the containerized version of PostgreSQL 18 uses `/var/lib/postgresql/18/docker/` as its default data folder, PostgreSQL 17 and other previous containerized releases use `/var/lib/postgresql/data/`. These are the folders to be used as `mountPath` for the `volumeMount` declared as `postgresql-storage` in the PostgreSQL `StatefulSet`. This divergence between major releases is an important detail also taken into account in this appendix.

    ~~~sh
    $ kubectl get statefulset -n forgejo -o wide
    NAME             READY   AGE   CONTAINERS       IMAGES
    cache-valkey     1/1     36m   server,metrics   valkey/valkey:9.0-alpine,oliver006/redis_exporter:v1.80.0-alpine
    db-postgresql    1/1     36m   server,metrics   postgres:17.8-trixie,prometheuscommunity/postgres-exporter:v0.18.1
    server-forgejo   1/1     36m   server           codeberg.org/forgejo/forgejo:14.0-rootless
    ~~~

    Under the `forgejo` namespace there are three `StatefulSet`s running:

    - One for the version `9.0` of the Valkey cache server, running a sidecar pod with the version `1.80.0` of its Prometheus metrics exporter.
    - One for the version `17.8` of the PostgreSQL database server, running a sidecar pod with the version `0.18.1` of its Prometheus metrics exporter.
    - One for the version `14.0` of the Forgejo server.

    Remember or write down somewhere these versions, in particular the PostgreSQL one, since you will need them in the next steps.

    Of course, you could also open the corresponding `kustomization.yaml` files of the Forgejo and PostgreSQL components in your Forgejo Kustomize project, and see what is the value for the `images.newTag` attribute. But with the `kubectl` command you are sure of getting the current version of the images actually running in your Kubernetes cluster, which then you can compare with what you have set in your Kustomize project.

2. Discover which is the latest release of PostgreSQL. You can look it up in the official [PostgreSQL page](https://www.postgresql.org/), or see which is [the latest official Docker image](https://hub.docker.com/_/postgres). Either way, at the moment of writing this, the latest PostgreSQL version is the `18.2` one.

3. Regarding the Forgejo compatibility with PostgreSQL `18.2`, Forgejo's official documentation states in its [Database Preparation section](https://forgejo.org/docs/latest/admin/installation/database-preparation/) that its version `14` supports working with PostgreSQL version `13` and forward, implicitly including the `18.2` release.

4. Knowing that, in this scenario, you want to upgrade from PostgreSQL's `17.y` release to the `18.y` one, you can choose the right [Tianon Gravi's **postgres-upgrade** Docker image](https://hub.docker.com/r/tianon/postgres-upgrade/): the one tagged as [17-to-18](https://hub.docker.com/layers/tianon/postgres-upgrade/17-to-18/images/sha256-ebb3e0acd8cc414bee02b343b56a8f794299ff8f26f328929f035148f9a8a90b). This particular image is the one you will have to deploy in a later stage of this upgrade procedure.

### Stage 2. Undeploying the Forgejo platform

You need to undeploy your whole Forgejo setup before you can start tinkering with its PostgreSQL database. Get into your `kubectl` client and do the following:

1. Use `kubectl` to delete the kustomize-based deployment of your Forgejo instance:

    ~~~sh
    $ kubectl delete -k $HOME/k8sprjs/forgejo/
    ~~~

    > [!IMPORTANT]
    > **Undeploying the Forgejo setup does not remove its data**\
    > Remember that, **in this scenario**, this `delete` action does not affect the data itself in the PostgreSQL database nor its files. This operation only removes from your K8s cluster the Kubernetes objects created in the deployment of the Forgejo platform.

2. Check with `kubectl` that there are no resources left in the `forgejo` namespace, not even the namespace itself:

    ~~~sh
    $ kubectl describe namespaces forgejo
    Error from server (NotFound): namespaces "forgejo" not found
    ~~~

### Stage 3. Preparing the data folders

With the filesystem arrangement prepared for the Forgejo's PostgreSQL database in the [first part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#storage-mount-points-for-forgejo-containers), the data files of the database instance where left in the path `/mnt/forgejo-ssd/db/k3smnt/` of the `k3sagent01` K3s node VM.

For the containerized version `17` of PostgreSQL deployed with this appendix's Forgejo platform, that path corresponds to the `/var/lib/postgresql/data/` directory. In it, PostgreSQL has all its data and configuration files, and you will have to move them to another more convenient directory:

> [!WARNING]
> **The `mgrsys` user will not be able to manage the PostgreSQL files**\
> The `/mnt/forgejo-ssd/db/k3smnt/` path and all the files inside it are owned by the `postgres` user that runs the PostgreSQL service in the corresponding Kubernetes pod. Not even `sudo` privileges will be enough: you will need to impersonate that user to handle those files.

1. Open a shell as `mgrsys` directly into the agent node VM (`k3sagent01`) having the PostgreSQL storage mounted. Check out with `ls` the permissions on the `/mnt/forgejo-ssd/db/k3smnt/` folder:

    ~~~sh
    $ sudo ls -al /mnt/forgejo-ssd/db/k3smnt/
    total 132
    drwx------ 19  999 root             4096 Feb 22 16:39 .
    drwxr-xr-x  4 root root             4096 Feb 21 14:24 ..
    drwx------  6  999 systemd-journal  4096 Feb 22 13:40 base
    drwx------  2  999 systemd-journal  4096 Feb 22 14:17 global
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_commit_ts
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_dynshmem
    -rw-------  1  999 systemd-journal  5743 Feb 22 13:40 pg_hba.conf
    -rw-------  1  999 systemd-journal  2640 Feb 22 13:40 pg_ident.conf
    drwx------  4  999 systemd-journal  4096 Feb 22 16:39 pg_logical
    drwx------  4  999 systemd-journal  4096 Feb 22 13:40 pg_multixact
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_notify
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_replslot
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_serial
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_snapshots
    drwx------  2  999 systemd-journal  4096 Feb 22 16:39 pg_stat
    drwx------  2  999 systemd-journal  4096 Feb 22 16:39 pg_stat_tmp
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_subtrans
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_tblspc
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_twophase
    -rw-------  1  999 systemd-journal     3 Feb 22 13:40 PG_VERSION
    drwx------  4  999 systemd-journal  4096 Feb 22 14:17 pg_wal
    drwx------  2  999 systemd-journal  4096 Feb 22 13:40 pg_xact
    -rw-------  1  999 systemd-journal    88 Feb 22 13:40 postgresql.auto.conf
    -rw-------  1  999 systemd-journal 30965 Feb 22 13:40 postgresql.conf
    -rw-------  1  999 systemd-journal    87 Feb 22 14:06 postmaster.opts
    ~~~

    Realize that, from the point of view of this node's Debian OS, the owner of the PostgreSQL database files is only identified by its user ID `999`, not `postgres`. This is an oddity I already explained back in the [_Shell access into your containers_ section of the chapter **G036**](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers).

2. Since the `999` user does not exist in the `k3sagent01` system, you need a more elaborate `sudo` command to impersonate it:

    ~~~sh
    $ sudo HOME=/tmp setpriv --reuid=999 --regid=999 --clear-groups /bin/bash
    ~~~

    The `setpriv` command is a very dangerous one since it does not really check if the user 999 exists in the system:

    - With `HOME=/tmp` you set the HOME directory for the 999 user in `/tmp`.

    - The `setpriv` command changes your identity before launching the /bin/bash command. The `--reuid` and `--regid` options turn your identity into the user `999` under the group `999`. Notice that the group `999` does exists as the systemd-journal group of the `k3sagent01` system. The `--clear-groups` option essentially ensures that there is no attempt to initialize other groups.

    After entering this command, you will notice a change in the prompt:

    ~~~sh
    I have no name!@k3sagent01:~$
    ~~~

    The `I have no name!` message warns about the fact that, since the user `999` does not exist in the system, it has no name to show at the prompt like with `mgrsys`.

3. Get into the `/mnt/forgejo-ssd/db/k3smnt/` folder:

    ~~~sh
    $ cd /mnt/forgejo-ssd/db/k3smnt/
    ~~~

4. Create a new folder called `17`:

    ~~~sh
    $ mkdir 17
    ~~~

    The name is `17` because that is the major number of the PostgreSQL version deployed just for this appendix.

5. Move all PostgreSQL files and directories inside the `17` folder:

    ~~~sh
    $ mv -t 17 base/ global/ pg* post* PG_VERSION
    ~~~

    The `mv` uses `-t` option to specify the destination directory `17` first for clarity.

6. Verify that you have all the database files and folders in the `17` folder:

    ~~~sh
    $ ls -al 17
    total 132
    drwxr-xr-x 19 999 systemd-journal  4096 Feb 22 17:57 .
    drwx------  3 999 root             4096 Feb 22 17:57 ..
    drwx------  6 999 systemd-journal  4096 Feb 22 13:40 base
    drwx------  2 999 systemd-journal  4096 Feb 22 14:17 global
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_commit_ts
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_dynshmem
    -rw-------  1 999 systemd-journal  5743 Feb 22 13:40 pg_hba.conf
    -rw-------  1 999 systemd-journal  2640 Feb 22 13:40 pg_ident.conf
    drwx------  4 999 systemd-journal  4096 Feb 22 16:39 pg_logical
    drwx------  4 999 systemd-journal  4096 Feb 22 13:40 pg_multixact
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_notify
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_replslot
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_serial
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_snapshots
    drwx------  2 999 systemd-journal  4096 Feb 22 16:39 pg_stat
    drwx------  2 999 systemd-journal  4096 Feb 22 16:39 pg_stat_tmp
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_subtrans
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_tblspc
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_twophase
    -rw-------  1 999 systemd-journal     3 Feb 22 13:40 PG_VERSION
    drwx------  4 999 systemd-journal  4096 Feb 22 14:17 pg_wal
    drwx------  2 999 systemd-journal  4096 Feb 22 13:40 pg_xact
    -rw-------  1 999 systemd-journal    88 Feb 22 13:40 postgresql.auto.conf
    -rw-------  1 999 systemd-journal 30965 Feb 22 13:40 postgresql.conf
    -rw-------  1 999 systemd-journal    87 Feb 22 14:06 postmaster.opts
    ~~~

7. Create the folder structure `18/docker`:

    ~~~sh
    $ mkdir -p 18/docker
    ~~~

    In a later stage of this procedure, this is the folder where you will dump the updated database files. Notice that it is the path expected by the containerized version 18 of PostgreSQL.

8. Exit from the `999` user session:

    ~~~sh
    $ exit
    ~~~

    Here you will return to your regular administrator user `mgrsys`.

9. Verify the ownership of the relevant folders in this PostgreSQL setup:

    - For the `k3smnt` folder, `999` user and `root` group ownership:

      ~~~sh
      $ ls -al /mnt/forgejo-ssd/db
      total 28
      drwxr-xr-x 4 root root  4096 Feb 21 14:24 .
      drwxr-xr-x 5 root root  4096 Jan 20 20:27 ..
      drwx------ 4  999 root  4096 Feb 22 18:02 k3smnt
      drwx------ 2 root root 16384 Jan 20 20:27 lost+found
      ~~~

    - For the `17` and `18` folders, `999` user and `systemd-journal` group ownerships:

      ~~~sh
      $ sudo ls -al /mnt/forgejo-ssd/db/k3smnt
      total 16
      drwx------  4  999 root            4096 Feb 22 18:02 .
      drwxr-xr-x  4 root root            4096 Feb 21 14:24 ..
      drwxr-xr-x 19  999 systemd-journal 4096 Feb 22 17:57 17
      drwxr-xr-x  3  999 systemd-journal 4096 Feb 22 18:02 18
      ~~~

    - For the folder `18/docker`, `999` user and `systemd-journal` group ownership:

      ~~~sh
      $ sudo ls -al /mnt/forgejo-ssd/db/k3smnt/18
      total 12
      drwxr-xr-x 3 999 systemd-journal 4096 Feb 22 18:02 .
      drwx------ 4 999 root            4096 Feb 22 18:02 ..
      drwxr-xr-x 2 999 systemd-journal 4096 Feb 22 18:02 docker
      ~~~

    Again, remember that this `systemd-journal` coincides, due to have the same Linux group ID, with the `postgres` group running the PostgreSQL server within its Kubernetes pod.

### Stage 4. Creating the Kustomize update project for PostgreSQL

In this stage you will see how to create the Kustomize project for deploying the [Tianon Gravi's _postgres-upgrade_ Docker image](https://hub.docker.com/r/tianon/postgres-upgrade/) you need to upgrade your PostgreSQL database files. Remember that the concrete image this guide will use is the one tagged as [17-to-18](https://hub.docker.com/layers/tianon/postgres-upgrade/17-to-18/images/sha256-ebb3e0acd8cc414bee02b343b56a8f794299ff8f26f328929f035148f9a8a90b).

Instead of creating this project from scratch, you can base it on the one you already have for the PostgreSQL instance running in the Forgejo setup:

1. Copy only the PostgreSQL component's Kustomize subproject found within your Forgejo setup's main project:

    ~~~sh
    $ cp -r $HOME/k8sprjs/forgejo/components/db-postgresql $HOME/k8sprjs/postgres-upgrade
    ~~~

    Notice that the folder naming pattern is like in the main chapters of this guide, but renamed to `postgres-upgrade` for better recognition.

2. For executing the upgrade, you will not need all the files used to deploy your Forgejo's PostgreSQL instance:

    - To reduce the chance of confusion, get inside the `postgres-upgrade` folder:

      ~~~sh
      $ cd $HOME/k8sprjs/postgres-upgrade
      ~~~

    - Remove the unnecessary files with `rm`:

      ~~~sh
      $ rm configs/{dbnames.properties,initdb.sh} resources/db-postgresql.service.yaml secrets/dbusers.pwd
      ~~~

      With the command above you remove:

      - A properties file with the names of the PostgreSQL users and the Forgejo database.

      - Shell script that initialized the PostgreSQL users for the metrics exporter and for the Forgejo instance.

      - The `yaml` definition of the service that exposes the PostgreSQL port. It is not required in the upgrade process since you will not need to access the PostgreSQL server instance at all.

      - The `pwd` file with the encrypted PostgreSQL users' passwords.

    - After removing these files, the `secrets` folder can also be removed from the `postgres-upgrade` since it has been left empty:

      ~~~sh
      $ rm -r secrets
      ~~~

3. For the sake of clarity and reduce the chance of confusion with the files of the original PostgreSQL component subproject, you should also rename the files within the `resources` folder:

    ~~~sh
    $ cd $HOME/k8sprjs/postgres-upgrade/resources
    $ mv db-postgresql.persistentvolumeclaim.yaml postgres-upgrade.persistentvolumeclaim.yaml
    $ mv db-postgresql.statefulset.yaml postgres-upgrade.statefulset.yaml
    ~~~~

    Of course, renaming the files is not enough to make the deployment work later. You will reconfigure those two YAML definitions, and others, later.

4. At this point, you are missing the YAML definition of the persistent volume where to put your PostgreSQL data files. The pod where you will run the upgrade will have to access that volume to work. Copy the definition from your Forgejo Kustomize project:

    ~~~sh
    $ cp $HOME/k8sprjs/forgejo/resources/forgejo-ssd-db.persistentvolume.yaml $HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml
    ~~~

    See that the copy renames the YAML file directly so it fits the PostgreSQL upgrade project. Still, like the other resource files, you will have to reconfigure it later.

5. You also need a Kubernetes definition for the namespace that will group your deployment's resources. Copy it from your Forgejo Kustomize project and rename it like in the previous steps:

    ~~~sh
    $ cp $HOME/k8sprjs/forgejo/resources/forgejo.namespace.yaml $HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml
    ~~~

6. Verify that you have in your `postgres-upgrade` folder a file tree like the one below:

    ~~~sh
    $ tree -F $HOME/k8sprjs/postgres-upgrade
    /home/YOUR_USER_HERE/k8sprjs/postgres-upgrade/
    ├── configs/
    │   └── postgresql.conf
    ├── kustomization.yaml
    └── resources/
        ├── postgres-upgrade.namespace.yaml
        ├── postgres-upgrade.persistentvolumeclaim.yaml
        ├── postgres-upgrade.persistentvolume.yaml
        └── postgres-upgrade.statefulset.yaml

    3 directories, 6 files
    ~~~

### Stage 5. Configuring the PostgreSQL's Kustomize update project

The PostgreSQL Kustomize project you copied declares a pod in a sidecar configuration, where one container runs the PostgreSQL server instance and a second one runs the exporter agent of Prometheus metrics for that server instance. For executing the update process you do not need that exporter agent at all. You must take it out completely from this PostgreSQL Kustomize update project you are working on here. That is the main change you have to do, but not the only one:

All the changes required are listed in these steps:

1. Create the NEW file `$HOME/k8sprjs/postgres-upgrade/configs/dbdatapaths.properties` with these lines:

    ~~~properties
    postgresql-db-data-old-path=/var/lib/postgresql/data/17
    postgresql-db-data-new-path=/var/lib/postgresql/data/18/docker
    ~~~

    For the upgrade to work, you need to specify where the "old" data is and where do you want to store its "new" version. The paths declared in this new `properties` file are enabled as environmental variables in the pod's declaration you will see later.

2. Review file `$HOME/k8sprjs/postgres-upgrade/configs/postgresql.conf`:

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

    This is exactly the same file as [in the original PostgreSQL deployment](G034%20-%20Deploying%20services%2003%20~%20forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#configuration-file-postgresqlconf).

    > [|WARNING]
    > **Between major versions, options can change or be removed altogether**\
    > Always check if the options set for your software remain valid in the newer major version. An easy way to do so for PostgreSQL is by using [this page that offers a configuration comparator between versions](https://pgconfig.rustprooflabs.com/param/change/17/18).

3. Modify the file `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml`:

    ~~~yaml
    # Namespace for the postgres-upgrade project
    apiVersion: v1
    kind: Namespace

    metadata:
      name: postgres-upgrade
    ~~~

    Only one important change in this `Namespace` definition: the `metadata.name` has gone from `forgejo` to `postgres-upgrade`. The comment at the top also has been updated for clarity.

4. Modify the file `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Claim of persistent storage for the postgres-upgrade project
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
          storage: 4.5G
    ~~~

    There are only a couple of "cosmetic" changes in this `PersistentVolumeClaim` declaration:

    - The comment at the top for clarity.
    - `metadata.name`: from `db-postgresql` to `postgres-upgrade`.
    - `spec.volumeName`:  from `forgejo-ssd-db` to `postgres-upgrade`.

    Compare this YAML with the `db-forgejo.persistentvolumeclaim.yaml` file declared [in the third part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-persistent-storage-claim).

5. Modify the file `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml`:

    ~~~yaml
    # Persistent storage volume for the postgres-upgrade project
    apiVersion: v1
    kind: PersistentVolume

    metadata:
      name: postgres-upgrade
    spec:
      capacity:
        storage: 4.5G
      volumeMode: Filesystem
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      persistentVolumeReclaimPolicy: Retain
      local:
        path: /mnt/forgejo-ssd/db/k3smnt
      nodeAffinity:
        required:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - k3sagent01
    ~~~

    Here there is only another "cosmetic" change: the `metadata.name` is changed from `forgejo-ssd-db` to `postgres-upgrade`. The rest of this declaration must remain the same as it was.

    Compare this YAML with the `forgejo-ssd-db.persistentvolume.yaml` file shown [in the fifth part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20forgejo%20-%20Part%205%20-%20Complete%20forgejo%20platform.md#forgejo-platforms-persistent-volumes).

6. Modify the file `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.statefulset.yaml`:

    ~~~yaml
    # StatefulSet for the postgres-upgrade project
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: postgres-upgrade
    spec:
      replicas: 1
      serviceName: postgres-upgrade
      template:
        spec:
          initContainers:
          - name: pg-checksums
            image: tianon/postgres-upgrade:17-to-18
            command: ["/bin/sh", "-c"]
            args:
            - "/usr/lib/postgresql/17/bin/pg_checksums --pgdata /var/lib/postgresql/data/17/ --enable --progress"
            #- "/usr/lib/postgresql/17/bin/pg_checksums --disable --pgdata /var/lib/postgresql/data/17/"
            volumeMounts:
            - name: postgresql-storage
              mountPath: /var/lib/postgresql/data
          containers:
          - name: pg-upgrade
            image: tianon/postgres-upgrade:17-to-18
            ports:
            - name: pg-upgrade
              containerPort: 50432
            env:
            - name: PGDATAOLD
              valueFrom:
                configMapKeyRef:
                  name: postgres-upgrade-config
                  key: postgresql-db-data-old-path
            - name: PGDATANEW
              valueFrom:
                configMapKeyRef:
                  name: postgres-upgrade-config
                  key: postgresql-db-data-new-path
            resources:
              requests:
                cpu: "0.75"
                memory: 256Mi
            volumeMounts:
            - name: postgresql-storage
              mountPath: /var/lib/postgresql/data
            - name: postgresql-config
              readOnly: true
              subPath: postgresql.conf
              mountPath: /etc/postgresql/postgresql.conf
          volumes:
          - name: postgresql-config
            configMap:
              name: postgres-upgrade-config
              defaultMode: 444
              items:
              - key: postgresql.conf
                path: postgresql.conf
          - name: postgresql-storage
            persistentVolumeClaim:
              claimName: postgres-upgrade
    ~~~

    This `StatefulSet` declaration is the component requiring the most significant changes:

    - All the `db-postgresql` names have been changed to `postgres-upgrade`.

    - There is a new init container called `pg-checksums` using the same `tianon/postgres-upgrade` container image used for upgrading PostgreSQL. Its only function is to execute the command specified in its `args` block to apply checksums on the "old" data. This is necessary because, while PostgreSQL 17 does not enable checksums by default in its databases, PostgreSQL 18 does. Therefore, either checksums are disabled while upgrading, or they are applied before the upgrade on the data files.

      In this case, the checksums are applied with the `pg_checksums` command **from the version 17 of PostgreSQL**. This is possible because the `tianon/postgres-upgrade` container image includes the binaries of both the version 17 and 18 of PostgreSQL. The relevant thing to notice here is, to invoke the binaries from the version 17, you need to specify their full path because they are not loaded in the container's $PATH (only the binaries of the latest version 18 are).

      > [!WARNING]
      > **You cannot reapply the checksums**\
      > If you need to rerun the upgrade process, **comment out or remove the whole `initContainers` block**. Otherwise, the init container will fail.

      Alternatively, you can disable the checksums and leave them to applied by the newer PostrgreSQL server instance. To disable the checksums, replace the `pg_checksums` command in the init container with the following one instead:

      ~~~sh
      /usr/lib/postgresql/17/bin/pg_checksums --disable --pgdata /var/lib/postgresql/data/17/
      ~~~

    - The `server` container has been renamed  to `pg-upgrade`. This makes sense since this container is just for executing the `pg-upgrade` command that later will perform the upgrade of the PostgreSQL data:

      - The `image` specified is the [Tianon Gravi's custom one indicated earlier in this guide](https://hub.docker.com/layers/tianon/postgres-upgrade/17-to-18/images/sha256-ebb3e0acd8cc414bee02b343b56a8f794299ff8f26f328929f035148f9a8a90b) to upgrade from PostgreSQL 17 to 18. It is the same one used in the init container.

      - The `containerPort` here reflects the port opened by the `pg_upgrade` command when running. Its `name` has been changed from `server` to `pg-upgrade` because it is the port that the `pg-upgrade` command opens while running.

      - The `args` block has been removed.

      - The `env` block now has two particular variables:

        - `PGDATAOLD`\
          Absolute path to the folder containing your current "old" database files.

        - `PGDATANEW`\
          Absolute path to the folder where `pg_upgrade` will copy the upgraded database files.

        These environmental variables not only specify paths, they also make Tianon's image to run in copy mode to perform the update of the database files. Notice that the key specified on each variable is one of the parameters previously declared in the `dbdatapaths.properties` file.

      - In the `volumeMounts` section, the path to the `initdb.sh` script has been deleted.

    - The `metrics` container has been removed completely.

    - At the `volumes` section, the `initdb.sh` item has been removed.

    Compare this version of the `StatefulSet` with the one [in the third part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-statefulset).

7. Modify the file `$HOME/k8sprjs/postgres-upgrade/kustomization.yaml`:

    ~~~yaml
    # Setup for the postgres-upgrade project
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: postgres-upgrade

    labels:
    - pairs:
        app: postgres-upgrade
        includeSelectors: true
        includeTemplates: true

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
    newTag: 17-to-18

    configMapGenerator:
    - name: postgres-upgrade-config
    envs:
    - configs/dbdatapaths.properties
    files:
    - configs/postgresql.conf
    ~~~

    This `kustomization.yaml` file has the following modifications:

    - The `db-postgresql` string has been changed for `postgres-upgrade`.

    - Has an added `namespace` for the entire deployment.

    - In `resources` there are several changes:

        - The file that declared the service resource has been removed from the list.
        - The files declaring the namespace and the persistent volume have been added.

    - In `images` is specified the Tianon's custom image.

    - In the `configMapGenerator` there also have been a number of changes.

      - There's now an `envs` section using the properties file as source of values for environmental variables, the ones you saw declared earlier in the StatefulSet declaration.

      - Only the `postgresql.conf` remains in the `files` block.

    - The `secretGenerator` section has been removed.

    Compare this `kustomization.yaml` file with its version [at the third part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-project).

### Stage 6. Deploying the PostgreSQL's Kustomize update project

Your Kustomize project is ready but, before you deploy it, you need to know beforehand what is going to happen when you deploy it:

- First, the init container will calculate and apply the checksums on the "old" data to be upgraded from version 17 to version 18.

- Second, once the container is running Tianon's image, it will try to automatically launch the upgrade on your "old" database files (found in the `PGDATAOLD` folder) as soon as it can. As a result of this operation, this upgrade process will make an upgraded copy of the data into the `PGDATANEW` folder.

- If the upgrade is successful, it will then try to start the PostgreSQL server. This will fail with a particular error.

Also be aware that, depending on the size of the database you are upgrading and the capacity available in your Kubernetes cluster for this pod, the process may take a while or just a few seconds. On the other hand, do not forget to use the tools you have deployed in your cluster to monitor this upgrade progress. In particular, use Headlamp to monitor the objects existing in the `postgres-upgrade` namespace and see the logs produced by the `postgres-upgrade-0` pod.

To proceed with the update, open a terminal in your `kubectl` client system, then:

1. Deploy the `postgres-upgrade` project:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/postgres-upgrade
    ~~~

    > [|WARNING]
    > **The PostgreSQL upgrade process starts automatically**\
    > Keep in mind that the `postgres-upgrade-0` pod will start to execute the update on its own as soon as its able to.

    Remember to check the logs of the `postgres-upgrade-0` pod through Headlamp (which is more convenient that through `kubectl`). It is in that log where you will be able to monitor the upgrade's progress.

2. Browse into Headlamp and open the logs slide from the `postgres-upgrade-0` pod. You will have to inspect two sets of logs, one per each container running in the pod:

    - Init container `pg-checksums`:

      ~~~log
      2026-02-23T16:37:24.404386279+01:00 0/37 MB (0%) computed
      2026-02-23T16:37:24.405545012+01:00 1/37 MB (3%) computed
      2026-02-23T16:37:24.405633633+01:00 15/37 MB (42%) computed
      2026-02-23T16:37:24.405772451+01:00 24/37 MB (66%) computed
      2026-02-23T16:37:24.405839934+01:00 37/37 MB (100%) computed
      2026-02-23T16:37:24.405924259+01:00 pg_checksums: syncing data directory
      2026-02-23T16:37:24.405984823+01:00 Checksum operation completed
      2026-02-23T16:37:24.406004791+01:00 Files scanned:   2163
      2026-02-23T16:37:24.406021100+01:00 Blocks scanned:  4758
      2026-02-23T16:37:24.406038020+01:00 Files written:  1754
      2026-02-23T16:37:24.406054256+01:00 Blocks written: 4749
      2026-02-23T16:37:25.104677015+01:00 pg_checksums: updating control file
      2026-02-23T16:37:25.115616372+01:00 Checksums enabled in cluster
      ~~~

      This log reports the progress of the computation and application of the checksums on the `old` database files.

    - Container `pg-upgrade`:

      ~~~log
      2026-02-23T16:37:26.388729277+01:00 The files belonging to this database system will be owned by user "postgres".
      2026-02-23T16:37:26.388819446+01:00 This user must also own the server process.
      2026-02-23T16:37:26.388836354+01:00 
      2026-02-23T16:37:26.388853238+01:00 The database cluster will be initialized with locale "en_US.utf8".
      2026-02-23T16:37:26.388869018+01:00 The default database encoding has accordingly been set to "UTF8".
      2026-02-23T16:37:26.388885026+01:00 The default text search configuration will be set to "english".
      2026-02-23T16:37:26.389011724+01:00 
      2026-02-23T16:37:26.389043248+01:00 Data page checksums are enabled.
      2026-02-23T16:37:26.389058344+01:00 
      2026-02-23T16:37:26.389074220+01:00 fixing permissions on existing directory /var/lib/postgresql/data/18/docker ... ok
      2026-02-23T16:37:26.389090540+01:00 creating subdirectories ... ok
      2026-02-23T16:37:26.389106980+01:00 selecting dynamic shared memory implementation ... posix
      2026-02-23T16:37:26.491654905+01:00 selecting default "max_connections" ... 100
      2026-02-23T16:37:26.673583251+01:00 selecting default "shared_buffers" ... 128MB
      2026-02-23T16:37:26.810294976+01:00 selecting default time zone ... Etc/UTC
      2026-02-23T16:37:26.813185418+01:00 creating configuration files ... ok
      2026-02-23T16:37:27.941653675+01:00 running bootstrap script ... ok
      2026-02-23T16:37:29.985160014+01:00 performing post-bootstrap initialization ... ok
      2026-02-23T16:37:30.545809069+01:00 syncing data to disk ... ok
      2026-02-23T16:37:30.547200854+01:00 
      2026-02-23T16:37:30.547255526+01:00 
      2026-02-23T16:37:30.547288971+01:00 Success. You can now start the database server using:
      2026-02-23T16:37:30.547309791+01:00 
      2026-02-23T16:37:30.547333071+01:00     pg_ctl -D /var/lib/postgresql/data/18/docker -l logfile start
      2026-02-23T16:37:30.547352235+01:00 
      2026-02-23T16:37:30.547411000+01:00 initdb: warning: enabling "trust" authentication for local connections
      2026-02-23T16:37:30.547477252+01:00 initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
      2026-02-23T16:37:31.100351822+01:00 Performing Consistency Checks
      2026-02-23T16:37:31.100435187+01:00 -----------------------------
      2026-02-23T16:37:31.100461203+01:00 Checking cluster versions                                     ok
      2026-02-23T16:37:31.600350523+01:00 Checking database connection settings                         ok
      2026-02-23T16:37:31.974664253+01:00 Checking database user is the install user                    ok
      2026-02-23T16:37:31.999650144+01:00 Checking for prepared transactions                            ok
      2026-02-23T16:37:31.999744297+01:00 Checking for contrib/isn with bigint-passing mismatch         ok
      2026-02-23T16:37:31.999767781+01:00 Checking for valid logical replication slots                  ok
      2026-02-23T16:37:32.109199676+01:00 Checking for subscription state                               ok
      2026-02-23T16:37:32.422435535+01:00 Checking data type usage                                      ok
      2026-02-23T16:37:32.656032348+01:00 Checking for objects affected by Unicode update               ok
      2026-02-23T16:37:32.738626890+01:00 Checking for not-null constraint inconsistencies              ok
      2026-02-23T16:37:32.833001554+01:00 Creating dump of global objects                               ok
      2026-02-23T16:37:34.361025709+01:00 Creating dump of database schemas                             ok
      2026-02-23T16:37:34.921859374+01:00 Checking for presence of required libraries                   ok
      2026-02-23T16:37:34.948839996+01:00 Checking database user is the install user                    ok
      2026-02-23T16:37:34.973471188+01:00 Checking for prepared transactions                            ok
      2026-02-23T16:37:34.973621885+01:00 Checking for new cluster tablespace directories               ok
      2026-02-23T16:37:34.973646725+01:00 
      2026-02-23T16:37:34.973668746+01:00 If pg_upgrade fails after this point, you must re-initdb the
      2026-02-23T16:37:34.973689530+01:00 new cluster before continuing.
      2026-02-23T16:37:34.973708550+01:00 
      2026-02-23T16:37:34.973729910+01:00 Performing Upgrade
      2026-02-23T16:37:34.973750826+01:00 ------------------
      2026-02-23T16:37:34.996113638+01:00 Setting locale and encoding for new cluster                   ok
      2026-02-23T16:37:35.938935223+01:00 Analyzing all rows in the new cluster                         ok
      2026-02-23T16:37:36.290176383+01:00 Freezing all rows in the new cluster                          ok
      2026-02-23T16:37:36.402652369+01:00 Deleting files from new pg_xact                               ok
      2026-02-23T16:37:36.413171915+01:00 Copying old pg_xact to new server                             ok
      2026-02-23T16:37:36.580615196+01:00 Setting oldest XID for new cluster                            ok
      2026-02-23T16:37:37.060848365+01:00 Setting next transaction ID and epoch for new cluster         ok
      2026-02-23T16:37:37.060995835+01:00 Deleting files from new pg_multixact/offsets                  ok
      2026-02-23T16:37:37.071443944+01:00 Copying old pg_multixact/offsets to new server                ok
      2026-02-23T16:37:37.073205632+01:00 Deleting files from new pg_multixact/members                  ok
      2026-02-23T16:37:37.083711234+01:00 Copying old pg_multixact/members to new server                ok
      2026-02-23T16:37:37.261167656+01:00 Setting next multixact ID and offset for new cluster          ok
      2026-02-23T16:37:37.422338745+01:00 Resetting WAL archives                                        ok
      2026-02-23T16:37:37.921047064+01:00 Setting frozenxid and minmxid counters in new cluster         ok
      2026-02-23T16:37:38.077502015+01:00 Restoring global objects in the new cluster                   ok
      2026-02-23T16:37:43.924494539+01:00 Restoring database schemas in the new cluster                 ok
      2026-02-23T16:37:44.756724493+01:00 Copying user relation files                                   ok
      2026-02-23T16:37:44.929760509+01:00 Setting next OID for new cluster                              ok
      2026-02-23T16:37:45.910243546+01:00 Sync data directory to disk                                   ok
      2026-02-23T16:37:45.910384967+01:00 Creating script to delete old cluster                         ok
      2026-02-23T16:37:46.357899198+01:00 Checking for extension updates                                notice
      2026-02-23T16:37:46.357993711+01:00 
      2026-02-23T16:37:46.358019271+01:00 Your installation contains extensions that should be updated
      2026-02-23T16:37:46.358040775+01:00 with the ALTER EXTENSION command.  The file
      2026-02-23T16:37:46.358062783+01:00     update_extensions.sql
      2026-02-23T16:37:46.358083063+01:00 when executed by psql by the database superuser will update
      2026-02-23T16:37:46.358105072+01:00 these extensions.
      2026-02-23T16:37:46.467576891+01:00 
      2026-02-23T16:37:46.467689044+01:00 Upgrade Complete
      2026-02-23T16:37:46.467713416+01:00 ----------------
      2026-02-23T16:37:46.467736252+01:00 Some statistics are not transferred by pg_upgrade.
      2026-02-23T16:37:46.467757984+01:00 Once you start the new server, consider running these two commands:
      2026-02-23T16:37:46.467778600+01:00     /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-in-stages --missing-stats-only
      2026-02-23T16:37:46.467801005+01:00     /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-only
      2026-02-23T16:37:46.467822365+01:00 Running this script will delete the old cluster's data files:
      2026-02-23T16:37:46.467843785+01:00     ./delete_old_cluster.sh
      ~~~

      These lines inform about the progress of the upgrade process.

3. When the upgrade process finishes, the `postgres-upgrade-0` pod will end up in a state of error and will try to restart (something you can safely ignore since it will fail harmlessly). If you see the `Upgrade Complete` log line from the `pg-upgrade` container as shown before, you can consider the upgrade done:

    > [!IMPORTANT]
    > **Pay attention to the commands indicated below the `Upgrade Complete` log**\
    > Notice the recommendation right below the `Upgrade Complete` message printed in the `pg-upgrade` container's log. It is a command you would have to run from within the PostgreSQL `server` container while it is running. Also, you would have to impersonate the `postgres` service user to execute it:
    >
    > To do all this, remember the following:
    >
    > - You can access containers with a remote terminal through Headlamp very easily.
    > - You can execute commands in containers while impersonating system users with the `runuser` command. For instance: `runuser -u postgres -- /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-in-stages --missing-stats-only`

#### Checking the upgraded database files

Although the upgrade process reports itself as finished, you also want to verify that it has truly written "something" on storage. To validate this, open a remote terminal in the K8s agent node where this pod has run, the `k3sagent01` in this case. Then, obtain and compare the sizes of the contents in the old and upgraded database folders:

~~~sh
$ sudo du -sh /mnt/forgejo-ssd/db/k3smnt/{17,18}
71M     /mnt/forgejo-ssd/db/k3smnt/17
63M     /mnt/forgejo-ssd/db/k3smnt/18
~~~

There are two conclusions you can draw from the output above:

- The upgrade has certainly written something in the `18` folder, which you can also check out by doing `sudo ls -al /mnt/forgejo-ssd/db/k3smnt/18/docker/`.

- The upgrade has compacted significantly the upgraded copy of the database files.

### Stage 7. Undeploying the PostgreSQL's Kustomize update project

Once the upgrade is done, you no longer need the `postgres-upgrade` project deployed in your Kubernetes cluster. Just remove it with `kubectl` like you would do with any other deployment:

~~~sh
$ kubectl delete -k $HOME/k8sprjs/postgres-upgrade
~~~

### Stage 8. Adjusting PostgreSQL datafiles's associated configuration

The upgrade process only migrates the old database into new datafiles that run in the newer PostgreSQL major version. The process does not adapt the configuration files attached to the old datafiles. In the release 17 of PostgreSQL, there are five configuration files that have their exact equivalent in the release 18. They are located in the main folder storing the datafiles, the `17` and `18/docker` ones under the path `/mnt/forgejo-ssd/db/k3smnt` of the corresponding K3s agent node (`k3sagent01`). These configuration files are:

- `pg_hba.conf`
- `pg_ident.conf`
- `postgresql.auto.conf`
- `postgresql.conf`
- `postmaster.opts`

Some of them will present differences due to particularities of the respective PostgreSQL releases they come from. Those changes should not worry you much, although you might investigate them to be sure they will not mean you trouble later. The differences you should take care to validate are those that may appear in the newer version's `pg_hba.conf` file, since this file controls the access to the PostgreSQL instance:

> [!IMPORTANT]
> **A bad `pg_hba.conf` configuration can cripple access to your PostgreSQL database**\
> If the `pg_hba.conf` file is not properly configured, your Forgejo server instance will not be able to access its own PostgreSQL database later.

To check out and amend any relevant difference in the new `pg_hba.conf` file, do this:

1. Use `diff` to compare the old and new versions of the `pg_hba.conf` file:

    ~~~sh
    $ sudo diff /mnt/forgejo-ssd/db/k3smnt/17/pg_hba.conf /mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf
    56,57c56,57
    < # "gss", "sspi", "ident", "peer", "pam", "ldap", "radius" or "cert".
    < # Note that "password" sends passwords in clear text; "md5" or
    ---
    > # "gss", "sspi", "ident", "peer", "pam", "oauth", "ldap", "radius" or
    > # "cert".  Note that "password" sends passwords in clear text; "md5" or
    127,128d126
    <
    < host all all all scram-sha-256
    ~~~

    By default, the `diff` command only returns the differences. Above you can see that it has detected differences in a comment block and two lines existing on the 17's version side but not on the 18's version. You can safely ignore the difference in the comments, but you need to put the missing lines in the `18/docker/pg_hba.conf` file.

2. Open the `/mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf` file with vim or the text editor you may have in the `k3sagent01` VM. Remember that you have to launch your editor with `sudo`:

    ~~~sh
    sudo vim /mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf
    ~~~

3. Add the missing two lines at the end of the `/mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf` file:

    ~~~sh
    ...
    # TYPE  DATABASE        USER            ADDRESS                 METHOD

    # "local" is for Unix domain socket connections only
    local   all             all                                     trust
    # IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local   replication     all                                     trust
    host    replication     all             127.0.0.1/32            trust
    host    replication     all             ::1/128                 trust

    host all all all scram-sha-256
    ~~~

4. Compare the two `pg_hba.conf` files with `diff` again:

    ~~~sh
    $ sudo diff /mnt/forgejo-ssd/db/k3smnt/17/pg_hba.conf /mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf
    56,57c56,57
    < # "gss", "sspi", "ident", "peer", "pam", "ldap", "radius" or "cert".
    < # Note that "password" sends passwords in clear text; "md5" or
    ---
    > # "gss", "sspi", "ident", "peer", "pam", "oauth", "ldap", "radius" or
    > # "cert".  Note that "password" sends passwords in clear text; "md5" or
    ~~~

    The only difference remaining now is in the comments.

You can apply the same steps with the other configuration files, although in this appendix particular scenario it will not be necessary since they are fine as they are (with default values).

### Stage 9. Reconfiguring the PostgreSQL's Kustomize subproject

Once you have your database files upgraded to be compatible with PostgreSQL 18, it is time for you to update the Kustomize subproject of the PostgreSQL component used in your Forgejo platform. Again, remember that this appendix uses a slightly modified modified Forgejo Kustomize project, where the version of PostgreSQL used was the latest available from the major release 17.

Knowing beforehand that there is no need to adjust anything in the configuration files used in the Kustomize project, you can concentrate in making just two specific changes:

- Update the mount path of the PostgreSQL storage so it coincides with the default path used by the containerized version of PostgreSQL 18. The expected default path is `/var/lib/postgresql/18/docker`.

- Update the PostgreSQL container image to `postgres:18.2-trixie`.

In the PostgreSQL Kustomize subproject used for this appendix, these two changes would look like this:

1. In the `StatefulSet` declaration in `db-postgresql.statefulset.yaml`:

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
            image: postgres:18.2-trixie
          ...
          volumeMounts:
          - name: postgresql-storage
            mountPath: /var/lib/postgresql
          ...
    ~~~

    The two values to update are found in the `server` container. One is the `image` used, and the other is the `mountPath` of the PostgreSQL storage. The only difference between this path and the one used for the version 17 of PostgreSQL is the subpath `/data`, which is no longer used by default in the containerized version of PostgreSQL 18.

    The container will not tell the difference. The mount path will still correspond to the real path in the `k3sagent01` VM, `/mnt/forgejo-ssd/db/k3smnt`, which already contains the subpath `18/docker` containing the database files ready to use.

    On the other hand, the `...` are placeholders for the parts of this `StatefulSet` declaration that are unaffected by this change.

2. In the `Kustomization` declaration for the whole PostgreSQL component Kustomize subproject, in `kustomization.yaml`:

    ~~~yaml
    # Forgejo PostgreSQL setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    ...
    images:
    - name: postgres
      newTag: 18.2-trixie
    ...
    ~~~

    The only value to update in this `Kustomization` declaration is the `newTag` to make it point to the latest version 18 of PostgreSQL.

    Again, the `...` are placeholders for the parts of this `Kustomization` declaration that are unaffected by this change.

3. Ensure you save the changes, and do not hesitate to validate with `kubectl` the PostgreSQL Kustomize subproject to detect possible issues:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/forgejo/components/db-postgresql | less
    ~~~

    The output of this command should be mostly the same as [the one shown in the third part of the chapter **G034**](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#validating-the-kustomize-yaml-output).

### Stage 10. Redeploying the Forgejo platform

The only thing left to do is to deploy again the whole Forgejo Kustomize project. Since errors may occur, browse to Headlamp and be prepared to check the logs of the Forgejo setup pods after applying the Forgejo project:

~~~sh
$ kubectl apply -k $HOME/k8sprjs/forgejo
~~~

Give this deployment some time to finish. If all is well, your Forgejo server should be back and running as it was before, although with a newer PostgreSQL server under its hood.

### Stage 11. Cleaning up the old data

The last thing you may want to do is to free the storage space taken by the old version of your PostgreSQL's database files. This implies, of course, the removal of the entire folder holding those files:

~~~sh
$ sudo rm -rf /mnt/forgejo-ssd/db/k3smnt/17
~~~

In this appendix's scenario, remember that the folder with the old database files is the one named `17`.

## Kustomize project only for updating PostgreSQL included in this guide

You can find the Kustomize project meant **only for updating PostgreSQL databases to newer MAJOR versions** at the attached folder indicated below.

- [`k8sprjs/postgres-upgrade`](k8sprjs/postgres-upgrade/)

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME`
- `$HOME/k8sprjs/forgejo`
- `$HOME/k8sprjs/forgejo/components`
- `$HOME/k8sprjs/forgejo/components/db-postgresql`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources`
- `$HOME/k8sprjs/forgejo/resources`
- `$HOME/k8sprjs/postgres-upgrade`
- `$HOME/k8sprjs/postgres-upgrade/configs`
- `$HOME/k8sprjs/postgres-upgrade/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/forgejo/components/db-postgresql/kustomization.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/forgejo/components/db-postgresql/resources/db-postgresql.statefulset.yaml`
- `$HOME/k8sprjs/forgejo/resources/forgejo-ssd-db.persistentvolume.yaml`
- `$HOME/k8sprjs/forgejo/resources/forgejo.namespace.yaml`
- `$HOME/k8sprjs/postgres-upgrade/kustomization.yaml`
- `$HOME/k8sprjs/postgres-upgrade/configs/dbdatapaths.properties`
- `$HOME/k8sprjs/postgres-upgrade/configs/postgresql.conf`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.namespace.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolume.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/postgres-upgrade/resources/postgres-upgrade.statefulset.yaml`

### Folders in the K3s agent node

- `/mnt/forgejo-ssd/db/k3smnt`
- `/mnt/forgejo-ssd/db/k3smnt/17`
- `/mnt/forgejo-ssd/db/k3smnt/18`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker`

### Files in the K3s agent node

- `/mnt/forgejo-ssd/db/k3smnt/17/pg_hba.conf`
- `/mnt/forgejo-ssd/db/k3smnt/17/pg_ident.conf`
- `/mnt/forgejo-ssd/db/k3smnt/17/postgresql.auto.conf`
- `/mnt/forgejo-ssd/db/k3smnt/17/postgresql.conf`
- `/mnt/forgejo-ssd/db/k3smnt/17/postmaster.opts`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker/pg_hba.conf`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker/pg_ident.conf`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker/postgresql.auto.conf`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker/postgresql.conf`
- `/mnt/forgejo-ssd/db/k3smnt/18/docker/postmaster.opts`

### Folders in the PostgreSQL upgrade container

- `/var/lib/postgresql/data`
- `/var/lib/postgresql/data/17`
- `/var/lib/postgresql/data/18`
- `/var/lib/postgresql/data/18/docker`

## References

### [PostgreSQL](https://www.postgresql.org/)

- [PostgreSQL 18.2 Documentation](https://www.postgresql.org/docs/18/index.html)
  - [III. Server Administration](https://www.postgresql.org/docs/18/admin.html)
    - [18. Server Setup and Operation](https://www.postgresql.org/docs/18/runtime.html)
      - [18.6. Upgrading a PostgreSQL Cluster](https://www.postgresql.org/docs/current/upgrading.html)
        - [18.6.2. Upgrading Data via `pg_upgrade`](https://www.postgresql.org/docs/18/upgrading.html#UPGRADING-VIA-PG-UPGRADE)

  - [20. Client Authentication](https://www.postgresql.org/docs/18/client-authentication.html)
    - [20.1. The `pg_hba.conf` File](https://www.postgresql.org/docs/18/auth-pg-hba-conf.html)

  - [PostgreSQL Server Applications. pg_upgrade](https://www.postgresql.org/docs/18/pgupgrade.html)
  - [PostgreSQL Server Applications. pg_checksums](https://www.postgresql.org/docs/18/pgupgrade.html)

- [Docker. Hub. postgres (Docker Official Image)](https://hub.docker.com/_/postgres)

### Other contents about upgrading PostgreSQL to a newer major version

- [postgresql.conf comparison](https://pgconfig.rustprooflabs.com/about)
  - [Postgres Config Changes: 17 to 18](https://pgconfig.rustprooflabs.com/param/change/17/18)

- [CloudyTuts. How to Upgrade PostgreSQL in Docker and Kubernetes](https://www.cloudytuts.com/tutorials/docker/how-to-upgrade-postgresql-in-docker-and-kubernetes/)

- [StackOverflow. How to upgrade my postgres in docker container while maintaining my data? 10.3 to latest 10.x or to 12.x](https://stackoverflow.com/questions/62790302/how-to-upgrade-my-postgres-in-docker-container-while-maintaining-my-data-10-3-t)
- [StackOverflow. How do I upgrade Docker Postgresql without removing existing data?](https://stackoverflow.com/questions/46672602/how-do-i-upgrade-docker-postgresql-without-removing-existing-data)
- [SuperUser. How to upgrade software (e.g. PostgreSQL) running in a Docker container?](https://superuser.com/questions/810363/how-to-upgrade-software-e-g-postgresql-running-in-a-docker-container)

- [ArchLinux. Forums. [SOLVED] postgres: old cluster does not use data checksums...](https://bbs.archlinux.org/viewtopic.php?id=309977)

### Tianon Gravi's PostgreSQL upgrade Docker image

- [Tianon Gravi](https://ram.tianon.xyz/)
  - [GitHub. Tianon Gravi](https://github.com/tianon)

- [pg_upgrade, Docker style on GitHub](https://github.com/tianon/docker-postgres-upgrade)
  - [Issues. "old cluster does not use data checksums but the new one does"](https://github.com/tianon/docker-postgres-upgrade/issues/121)

- [Docker. Hub. tianon/postgres-upgrade](https://hub.docker.com/r/tianon/postgres-upgrade/)
  - [tianon/postgres-upgrade:17-to-18](https://hub.docker.com/layers/tianon/postgres-upgrade/17-to-18/images/sha256-ebb3e0acd8cc414bee02b343b56a8f794299ff8f26f328929f035148f9a8a90b)

### [Forgejo](https://forgejo.org/)

- [Forgejo Administrator Guide](https://forgejo.org/docs/latest/admin/)
  - [Installation. Database Preparation](https://forgejo.org/docs/latest/admin/installation/database-preparation/)

## Navigation

[<< Previous (**G909. Appendix 09**)](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**README**)](README.md) >>]
