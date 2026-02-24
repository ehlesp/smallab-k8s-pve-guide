# G909 - Appendix 09 ~ Updating MariaDB to a newer major version

- [Upgrading a containerized MariaDB to a new major version is easy](#upgrading-a-containerized-mariadb-to-a-new-major-version-is-easy)
- [Concerns](#concerns)
- [Enabling the update procedure](#enabling-the-update-procedure)
- [References](#references)
  - [MariaDB](#mariadb)
  - [Other contents about upgrading the MariaDB container](#other-contents-about-upgrading-the-mariadb-container)
- [Navigation](#navigation)

## Upgrading a containerized MariaDB to a new major version is easy

MariaDB has been designed to be easily upgraded, something helpful specially when it has been containerized. The standard Linux procedure is explained in [this official documentation page](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/platform-specific-upgrade-guides/upgrading-on-linux/upgrading-between-major-mariadb-versions), but you will not need to follow it. There is a much easier way available for containerized MariaDB instances like the one in your [Ghost setup](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md).

## Concerns

The main concerns you should be aware of when updating to a new major MariaDB version are:

- Although MariaDB is designed to backwards compatible, always check the new version's upgrade notes to find out if there are any breaking changes announced there.

- The update procedure makes, by default, a backup of your databases before executing the update itself. If you want this backup, ensure having enough free space within the storage volume where your databases are stored: the update procedure will dump the backup in your MariaDB server's data directory.

- You will need to see the logs of your MariaDB instance to monitor the update and detect any issues that may happen in the process.

- The update procedure also updates the databases stored in the MariaDB instance. In other words, the databases in your MariaDB server will be adapted to work with the newer version.

  - Downgrading your MariaDB server once updated [is technically possible](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/platform-specific-upgrade-guides/upgrading-on-linux/upgrading-between-major-mariadb-versions#downgrading) but dangerous. Doing it involves deleting MariaDB's own system tables among other details, so better avoid it if possible.

## Enabling the update procedure

Rather than executing the update (or upgrade) process yourself, just enable it so it starts on its own when the MariaDB container runs:

1. You need to add up to two optional environment variables to the [MariaDB `StatefulSet` declaration](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset), in the end of the `env` section of its `server` container. The parameters in the Nextcloud setup should look like below:

    ~~~yaml
    ...
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
        ...
      - name: MARIADB_AUTO_UPGRADE
        value: "1"
      - name: MARIADB_DISABLE_UPGRADE_BACKUP
        value: "1"
    ...
    ~~~

    The two new parameters at the bottom have the same `"1"` value, but it could have been anything else. As long as it is a non-empty one, any value will do:

    - `MARIADB_AUTO_UPGRADE`\
      Enables the upgrade process to run automatically on each start of the MariaDB server. This is a very convenient feature for containerized instances:

      - MariaDB will check if it needs to run the upgrade process before starting the server instance. This check implies a small delay in the server startup process.

      - The upgrade procedure creates first a backup saved as a file named `system_mysql_backup_*.sql.zst`, which you will find at the root of your MariaDB instance's data directory (in the Ghost setup it is found at `/var/lib/mysql`).

        > [!IMPORTANT]
        > **Check the storage space available in your MariaDB instance**\
        > On every update, check first that you have enough space in the associated storage volume for that backup!

    - `MARIADB_DISABLE_UPGRADE_BACKUP`\
      Disables the backup the upgrade process executes by default before doing the upgrade itself.

    > [!NOTE]
    > [MariaDB's official documentation of these environment variables is here](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/mariadb-server-docker-official-image-environment-variables#mariadb_auto_upgrade-mariadb_disable_upgrade_backup).

2. After modifying the MariaDB deployment, redeploy the whole Kustomize project (of Ghost in this case) as usual:

    - Remember that you will have to open the log of your MariaDB's `server` container to see if any issues happen in the update process.

    - Also be aware that, if something goes wrong in the upgrade, the MariaDB `server` container (and the pod that holds it) could start behaving in odd ways (like restarting itself).

## References

### [MariaDB](https://mariadb.com/)

- [MariaDB Documentation. Server Management](https://mariadb.com/docs/server/server-management)
  - [Deployment. Upgrading MariaDB. Platform Specific Upgrade Guides. Upgrading on Linux](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/platform-specific-upgrade-guides/upgrading-on-linux/upgrading-between-major-mariadb-versions)
    - [Downgrading](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/platform-specific-upgrade-guides/upgrading-on-linux/upgrading-between-major-mariadb-versions#downgrading)
  - [Automated Deployment & Administration. MariaDB Containers](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb)
    - [MariaDB Server Docker Official Image Environment Variables](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/mariadb-server-docker-official-image-environment-variables)
      - [MARIADB_AUTO_UPGRADE / MARIADB_DISABLE_UPGRADE_BACKUP](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/mariadb-server-docker-official-image-environment-variables#mariadb_auto_upgrade-mariadb_disable_upgrade_backup)

### Other contents about upgrading the MariaDB container

- [StackOverflow. How to upgrade MariaDB running as a docker container. Comment by danblack](https://stackoverflow.com/questions/68308764/how-to-upgrade-mariadb-running-as-a-docker-container#comment128212517_68309653)
- [StackOverflow. Running mysql_upgrade in Docker?](https://stackoverflow.com/questions/40981983/running-mysql-upgrade-in-docker)

## Navigation

[<< Previous (**G908. Appendix 08**)](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G910. Appendix 10**) >>](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md)
