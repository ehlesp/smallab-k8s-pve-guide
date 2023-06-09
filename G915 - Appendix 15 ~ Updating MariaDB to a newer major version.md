# G915 - Appendix 15 ~ Updating MariaDB to a newer major version

MariaDB has been designed to be easily upgraded, something helpful specially when it has been containerized. The standard procedure is explained in [this official documentation page](https://mariadb.com/kb/en/upgrading-between-major-mariadb-versions/), but you won't need to do any of it since there's a much easier way available for containerized MariaDB instances such as the one you deployed in your [Nextcloud setup](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md).

## Concerns

The [official documentation](https://mariadb.com/kb/en/upgrading-between-major-mariadb-versions/) doesn't really distinguish between updating to a new minor or major version. In this guide, however, I'll be tackling specifically the update to a new _MAJOR_ version (such as jumping from version 10.y.z to 11.y.z). The main concerns you should be aware of when updating to a new major MariaDB version are the following.

- Although MariaDB is built with retrocompatibility in mind, always check the new version's upgrade notes to see if there are any **breaking changes** listed there.
- The update procedure makes, by default, a **backup** of your databases **before** executing the update itself. If you want this backup, ensure having enough free space within the storage volume where your databases are stored, since it's in the data directory where the procedure will dump the backup.
- You'll need to see the **logs** of your MariaDB's instance to monitor the update and detect any **issues** that may happen in the process.
- Once you've updated your MariaDB server, **you cannot downgrade it to a previous version**. This is because your databases will also be updated to work with the new version, and won't work properly with any previous one.

## Enabling the update procedure

Rather than executing the update (or upgrade) process yourself, you'll just enable it so it starts on its own when the MariaDB container runs.

1. You need to add up to two **optional** environmental parameters to the [MariaDB stateful set yaml file](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource), in the end of the `env` section of its `server` container. The parameters in the Nextcloud setup should look like below:

    ~~~yaml
    ...
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
        ...
      - name: MARIADB_AUTO_UPGRADE
        value: "1"
      - name: MARIADB_DISABLE_UPGRADE_BACKUP
        value: "1"
    ...
    ~~~

    See how I've given to both parameters at the bottom the same `"1"` value, but it could have been anything else. As long as it is a **non-empty** one, any value will do. But what do these parameters mean?

    - `MARIADB_AUTO_UPGRADE`: **enables** the upgrade process to run automatically on each start of the MariaDB server, a very convenient feature for containerized instances.
        - MariaDB will check if it needs to run the upgrade process **before** starting the server instance, so this implies a small delay in the server startup process.
        - The upgrade procedure creates first a backup saved as a file named `system_mysql_backup_*.sql.zst`, which you'll find at the root of your MariaDB instance's data directory (in our Nextcloud setup it was found at `/var/lib/mysql`).
            > **BEWARE!**  
            > On every update, check first that you have enough space in the storage volume for that backup!
    - `MARIADB_DISABLE_UPGRADE_BACKUP`: **disables** the backup that the upgrade process executes by default **before** doing the upgrade itself.

    > **BEWARE!**  
    > The description of these two env parameters is found at the bottom of [this official page](https://mariadb.com/kb/en/mariadb-docker-environment-variables/). Be aware that, at the moment of writing this, that information is mixed up (by mistake I presume) with the description of the previous parameter `MARIADB_INITDB_SKIP_TZINFO / MYSQL_INITDB_SKIP_TZINFO`.

2. After doing the modification, redeploy the whole Kustomize project (of Nextcloud in this case) as usual.
    - Remember that you'll have to open the log of your MariaDB's `server` container to see if any issues happen in the update process.
    - Also be aware that, if something goes wrong in the upgrade, the `server` container (and the pod that holds it) could start behaving in odd ways (like restarting itself).

## References

### _MariaDB_

- [Upgrading Between Major MariaDB Versions](https://mariadb.com/kb/en/upgrading-between-major-mariadb-versions/)
- [MariaDB Docker Environment Variables](https://mariadb.com/kb/en/mariadb-docker-environment-variables/)
- [Comment on "How to upgrade MariaDB running as a docker container"](https://stackoverflow.com/questions/68308764/how-to-upgrade-mariadb-running-as-a-docker-container#comment128212517_68309653)
- [Running mysql_upgrade in Docker?](https://stackoverflow.com/questions/40981983/running-mysql-upgrade-in-docker)

## Navigation

[<< Previous (**G914. Appendix 14**)](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G916. Appendix 16**) >>](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md)
