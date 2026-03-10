# G046 - Cleaning up your homelab system

- [Save storage space by cleaning your system up](#save-storage-space-by-cleaning-your-system-up)
- [Checking your storage status](#checking-your-storage-status)
  - [Storage space status on the Proxmox VE host](#storage-space-status-on-the-proxmox-ve-host)
    - [Filesystem status on Proxmox VE host](#filesystem-status-on-proxmox-ve-host)
    - [Key directories in the `/` filesystem of the Proxmox VE host](#key-directories-in-the--filesystem-of-the-proxmox-ve-host)
    - [Systemd journal logs](#systemd-journal-logs)
  - [Storage space status on the K3s Kubernetes nodes](#storage-space-status-on-the-k3s-kubernetes-nodes)
    - [Kubernetes container logs](#kubernetes-container-logs)
    - [Images of Kubernetes containers](#images-of-kubernetes-containers)
- [Cleaning procedures](#cleaning-procedures)
  - [Procedures for cleaning up logs](#procedures-for-cleaning-up-logs)
    - [Cleaning regular `.log` files](#cleaning-regular-log-files)
    - [Pruning systemd journal logs](#pruning-systemd-journal-logs)
  - [Procedures for pruning container images](#procedures-for-pruning-container-images)
    - [Pruning container images manually](#pruning-container-images-manually)
    - [Adjusting the automated garbage collection of unused container images](#adjusting-the-automated-garbage-collection-of-unused-container-images)
- [Reminder about the `apt` updates](#reminder-about-the-apt-updates)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in the Proxmox VE host](#folders-in-the-proxmox-ve-host)
  - [Files in the Proxmox VE host](#files-in-the-proxmox-ve-host)
  - [Folders in the K3s node VMs](#folders-in-the-k3s-node-vms)
  - [Files in the K3s node VMs](#files-in-the-k3s-node-vms)
- [References](#references)
  - [Linux](#linux)
  - [K3s](#k3s)
  - [Kubernetes](#kubernetes)
- [Navigation](#navigation)

## Save storage space by cleaning your system up

Over time, any system accumulates digital "dirt" that you must get rid of, and certainly the homelab setup you have deployed with this guide is no exception for this. Cleaning that dirt frees up some of your precious storage space and, in the case of the K3s cluster nodes, slightly reduce the size of your VMs backups.

## Checking your storage status

From the point of view of storage, the homelab system built in this guide has two levels:

- **Proxmox VE host**\
  The main concerns here are logs and temporal files.

- **K3s cluster nodes**\
  Beyond logs and temporal files, Kubernetes nodes also accumulate over time old unused images that must be pruned periodically.

### Storage space status on the Proxmox VE host

From time to time, you have to get deeper in your Proxmox VE host to see how its storage capacity is truly faring.

#### Filesystem status on Proxmox VE host

In any Debian-based system such as your Proxmox VE server, remember that you can check the storage available in your filesystems with the `df` command. Open a remote shell to your Proxmox VE server and execute this `df` command:

~~~sh
Filesystem                            Size  Used Avail Use% Mounted on
udev                                  3.8G     0  3.8G   0% /dev
tmpfs                                 783M  5.0M  778M   1% /run
/dev/mapper/pve-root                   50G  5.6G   42G  12% /
tmpfs                                 3.9G   34M  3.8G   1% /dev/shm
efivarfs                              128K   16K  108K  13% /sys/firmware/efi/efivars
tmpfs                                 5.0M     0  5.0M   0% /run/lock
tmpfs                                 1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
tmpfs                                 3.9G     0  3.9G   0% /tmp
/dev/mapper/hddusb-hddusb_bkpvzdumps  551G  8.9G  514G   2% /mnt/hddusb_bkpvzdumps
/dev/mapper/hddint-hdd_templates       59G  757M   56G   2% /mnt/hdd_templates
/dev/fuse                             128M   28K  128M   1% /etc/pve
tmpfs                                 1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
tmpfs                                 783M  4.0K  783M   1% /run/user/1000
~~~

All the filesystems listed by `df` are a concern, but pay special attention to the root `/` (`/dev/mapper/pve-root`) one since it is where your Proxmox VE is installed. You do not want to ever run out of space there.

#### Key directories in the `/` filesystem of the Proxmox VE host

In this guide's setup, the `/` filesystem is where all the Proxmox VE logs, temporal and other critical files are stored. You must know which directories are those you should pay particular attention to:

- `/boot`\
  Where kernel and boot-related files are stored. Notice that the `/boot/efi` directory is just a mount point for a different filesystem meant specifically for the EFI firmware.

- `/tmp`\
  The main directory for temporal files.

- `/var/cache`\
  Directory where services running in the system can leave files for caching purposes.

- `/var/log`\
  Where the system's journal and services logs are stored.

- `/var/tmp`\
  Another directory for temporal files.

- `/var/spool`\
  Directory to leave files pending to be processed, such as outgoing mail or for printing.

To know how much space a directory is taking in your filesystem, use the `du` command. For instance, let's measure the `/var/log` folder:

~~~sh
$ sudo du -sh /var/log/
213M    /var/log/
~~~

In this case, the `/var/log` folder of this guide's Proxmox VE system fills about 213 MB of the `/` filesystem, which is just fine. Also, the `du` shown above has two particular options:

- `-s`\
  Gives a summarized total.

- `-h`\
  Prints the measurement in a human-readable format.

#### Systemd journal logs

Within the `/var/log` path there is a `journal` folder which contains the journal logs of `systemd`. In this guide's Proxmox VE system it looks like this:

~~~sh
$ ls -al /var/log/journal
total 16
drwxr-sr-x+  3 root systemd-journal 4096 Aug 15  2025 .
drwxr-xr-x  16 root root            4096 Feb 18 13:31 ..
drwxr-sr-x+  2 root systemd-journal 4096 Feb 11 11:38 b1c5982b700c47a79e790afa254b5c90
~~~

Notice how the group owner of this `journal` folder is `systemd-journal`, and that it contains a subdirectory named with an hexadecimal number which is an identifier for the system itself. The systemd journal's logs are inside this hexadecimal directory:

~~~sh
$ ls -alh /var/log/journal/b1c5982b700c47a79e790afa254b5c90/
total 200M
drwxr-sr-x+ 2 root systemd-journal 4.0K Feb 11 11:38 .
drwxr-sr-x+ 3 root systemd-journal 4.0K Aug 15  2025 ..
-rw-r-----+ 1 root systemd-journal 8.0M Aug 19  2025 system@3938c3f2d1f04a3e902046506b81af9e-0000000000000001-00063c6e407a2f8b.journal
-rw-r-----+ 1 root systemd-journal  16M Aug 26 10:13 system@3938c3f2d1f04a3e902046506b81af9e-0000000000000ba4-00063cb8d46c569f.journal
-rw-r-----+ 1 root systemd-journal  40M Sep 23 10:41 system@3938c3f2d1f04a3e902046506b81af9e-0000000000004bf1-00063d403eba34d9.journal
-rw-r-----+ 1 root systemd-journal  24M Oct  8 08:48 system@3938c3f2d1f04a3e902046506b81af9e-0000000000016a78-00063f73e5f67f5c.journal
-rw-r-----+ 1 root systemd-journal  16M Oct 21 12:54 system@3938c3f2d1f04a3e902046506b81af9e-000000000001fa56-000640a012d85c46.journal
-rw-r-----+ 1 root systemd-journal  24M Nov 21 09:32 system@3938c3f2d1f04a3e902046506b81af9e-00000000000237ac-000641a904934689.journal
-rw-r-----+ 1 root systemd-journal 8.0M Dec 10 10:53 system@3938c3f2d1f04a3e902046506b81af9e-000000000002a707-00064416a697d9de.journal
-rw-r-----+ 1 root systemd-journal  16M Dec 30 18:41 system@3938c3f2d1f04a3e902046506b81af9e-000000000002bfcf-0006459600fb4076.journal
-rw-r-----+ 1 root systemd-journal 8.0M Jan 13 11:23 system@3938c3f2d1f04a3e902046506b81af9e-0000000000031a43-0006472edf1edb55.journal
-rw-r-----+ 1 root systemd-journal  32M Jan 29 12:54 system@3938c3f2d1f04a3e902046506b81af9e-000000000003211b-000648426381052a.journal
-rw-r-----+ 1 root systemd-journal  32M Feb 18 13:38 system.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 23 10:41 user-1000@3938c3f2d1f04a3e902046506b81af9e-0000000000004fb1-00063d4347eeb8e7.journal
-rw-r-----+ 1 root systemd-journal 8.0M Feb 18 13:37 user-1000.journal
~~~

The `ls` command reports the total size of this folder as 200 MB, and notice how the journal files start by weighting 8 MB and grow in multiples of 8.

> [!IMPORTANT]
> **The `.journal` files are binaries, not regular text-based log files**\
> Do not try to open them with `less`, `vim` or any other text editor.

The proper way to manage your journal logs is with the `journalctl` command. To see how much your journal logs weight you can do the following:

~~~sh
$ sudo journalctl --disk-usage
Archived and active journals take up 199.9M in the file system.
~~~

See how `journalctl` returns a more precise measurement than the one obtained previously with `ls`. Of course, you can also compare this measuring with what `du` can tell you:

~~~sh
$ sudo du -sh /var/log/journal/
200M    /var/log/journal/
~~~

As you can see, `du` measures the size like `ls`, rounding the decimal up to the next integer value.

To see the systemd journal logs themselves, you have to use the `journalctl` command. For instance, to read all the latest logs:

~~~sh
$ sudo journalctl -r
~~~

This command shows you the logs **in reverse order**, starting from the latest one registered, in a `less`-like viewer:

~~~sh
Feb 18 13:43:33 pve sudo[51183]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Feb 18 13:43:33 pve sudo[51183]:   mgrsys : TTY=pts/0 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl -r
Feb 18 13:43:01 pve sudo[51040]: pam_unix(sudo:session): session closed for user root
Feb 18 13:43:01 pve sudo[51040]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Feb 18 13:43:01 pve sudo[51040]:   mgrsys : TTY=pts/0 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/du -sh /var/log/journal/
Feb 18 13:42:39 pve sudo[50946]: pam_unix(sudo:session): session closed for user root
Feb 18 13:42:39 pve sudo[50946]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Feb 18 13:42:39 pve sudo[50946]:   mgrsys : TTY=pts/0 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl --disk-usage
Feb 18 13:38:39 pve pvedaemon[1395]: <root@pam> successful auth for user 'mgrsys@pam'
Feb 18 13:37:30 pve sudo[49447]: pam_unix(sudo:session): session closed for user root
Feb 18 13:37:30 pve sudo[49447]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Feb 18 13:37:30 pve sudo[49447]:   mgrsys : TTY=pts/0 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/du -sh /var/log/
Feb 18 13:31:13 pve systemd[1]: Started session-4.scope - Session 4 of User mgrsys.
Feb 18 13:31:13 pve systemd[1]: Started user@1000.service - User Manager for UID 1000.
Feb 18 13:31:13 pve systemd[47655]: Startup finished in 933ms.
...
~~~

> [!NOTE]
> **Use `sudo` with `journalctl` to see all your system's journal logs**\
> To see all the journal logs produced by your system, execute the `journalctl` command with `sudo` (or `root` privileges). Otherwise, you will only see the journal logs relative **to your current user**.

### Storage space status on the K3s Kubernetes nodes

All your K3s nodes are Debian systems, just like your Proxmox VE host, so all the things explained in the previous sections about how to check the storage space and which directories you should pay attention first also apply in your K3s VMs. Therefore, from here on the explanations center around the particular Kubernetes-related things that eat your storage space in your K3s cluster nodes.

#### Kubernetes container logs

While the logs of the K3s service running on each node [are journaled](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#regular-k3s-logs-are-journaled), remember that there are other logs related to the containers running in your K3s cluster:

- `/var/lib/rancher/k3s/agent/containerd/containerd.log`\
  This log is related to the containerd engine running the containers in your K3s cluster. Since [it is rotated](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#rotating-the-containerdlog-file), it should not eat much storage space from your K3s nodes.

- `/var/log/containers/`\
  This is a folder with symbolic links to log files kept within the `/var/log/pods/` folder. This will never eat your storage space at all.

- `/var/log/pods/`\
  Holds [the logs of the containers running in the pods deployed in your K3s cluster](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#container-logs). Since these logs are removed when the pods are removed, they should not give you much trouble in your storage. Still, a long running pod could produce a good amount of logs in one session, so be aware of them.

#### Images of Kubernetes containers

The containers you deploy in your Kubernetes cluster run docker images, and these images get stored in the root ( `/` ) filesystem of any node running containers. This guide will not tell you the exact path where the images are stored, since **you must not touch them directly**. Instead, in a K3s-based Kubernetes cluster such as yours, you can use the `k3s` command to get a list of all the images downloaded in a particular node:

~~~sh
$ sudo k3s crictl images
IMAGE                                             TAG                     IMAGE ID            SIZE
codeberg.org/forgejo/forgejo                      14.0-rootless           86805b9e010ce       74.8MB
docker.io/emberstack/kubernetes-reflector         9.1.31                  46e6326b77a39       98.3MB
docker.io/grafana/grafana-dev                     12.4.0-21524955964      808005a4a1271       214MB
docker.io/library/busybox                         stable-musl             77ec00c00ce4e       877kB
docker.io/library/postgres                        18.1-trixie             019965b818886       162MB
docker.io/oliver006/redis_exporter                v1.80.0-alpine          f2b15c097d88c       7.89MB
docker.io/prom/node-exporter                      v1.10.2                 696e69e899e06       13.1MB
docker.io/prometheuscommunity/postgres-exporter   v0.18.1                 519a5596d17c9       11.7MB
docker.io/rancher/klipper-helm                    v0.9.14-build20260210   2e2c8cbfb79b8       64.1MB
docker.io/rancher/mirrored-pause                  3.6                     6270bb605e12e       301kB
docker.io/valkey/valkey                           9.0-alpine              b0c9544b30313       18MB
ghcr.io/headlamp-k8s/headlamp                     <none>                  3c35cb93898bd       98.4MB
ghcr.io/headlamp-k8s/headlamp                     latest                  2bc128cf9cf26       98.4MB
ghcr.io/headlamp-k8s/headlamp                     <none>                  64650092faefd       98.3MB
quay.io/jetstack/cert-manager-cainjector          v1.19.0                 de207db7ac36a       12.5MB
quay.io/jetstack/cert-manager-controller          v1.19.0                 27d4672019b07       23.5MB
quay.io/jetstack/cert-manager-webhook             v1.19.0                 7d60b0b895798       19.9MB
quay.io/metallb/controller                        v0.15.2                 1b258f39a2a12       31.7MB
quay.io/metallb/speaker                           v0.15.2                 1eeb60bd05864       59.8MB
quay.io/metallb/speaker                           v0.15.3                 7976d450b330f       51.4MB
~~~

The list above tells you about all the images currently stored in the node and, more importantly, how much does each of them weight. Be aware that older or redundant images may be present and could eat up a significant chunk of your storage space. Also see how the IMAGE path indicates the source repository of each image: there are those who come from `docker`, others from `quay` or `ghcr` (GitHub), and the Forgejo one from `codeberg`.

## Cleaning procedures

In general, all the elements mentioned before (logs, temporal files and container images) are all already automatically managed by your system in some way. Still, you could find the default configuration for rotation or pruning of any of those elements too lenient. Then, you may want to either adjust the rotation or pruning configuration, or know how to execute a proper cleaning manually. In this section you can learn how to do manual cleanings.

> [!IMPORTANT]
> **Be sure you do not need the elements you prune from your homelab**\
> Always be sure that you really do not need the element you are removing from your system, most in particular logs. Remember that logs are usually the only piece of information you have to identify the root of any problem you might have in your system.

### Procedures for cleaning up logs

Here you have to distinguish between the regular `.log` files and the systemd journal logs, but both cases apply in all your Debian systems (Proxmox VE host and VMs).

#### Cleaning regular `.log` files

Usually, your log files are controlled either by `logrotate` or rotated by the same application or service that writes them. For those that are under the management of `logrotate`, you can force a rotation manually if you feel it necessary:

~~~sh
$ sudo logrotate --force /path/to/service.logrotate.configuration
~~~

That command forces the rotation of the particular logs configured in the specified `/path/to/service.logrotate.configuration` file, and this may or may not free up some space in your filesystem. Also remember that you can usually find the logrotate configuration files in the `/etc/logrotate.d/` folder.

With log files not managed by `logrotate` you can try handling them manually, but be always careful of not removing the actual log files currently in use by any service. Instead, you can just empty them with a simple command:

~~~sh
$ > /var/log/theoretical.log
~~~

Since its left side is an empty input, the `>` operator in this case rewrites the entire target file on the right side with literally nothing, effectively emptying it. Reserve this trick for particularly tight situations.

#### Pruning systemd journal logs

Do not ever try to manage the systemd journal log files directly. Always use the `journalctl` command to handle the system's journal, specially when pruning them:

1. First, check the space used by your systemd journal logs:

    ~~~sh
    $ sudo journalctl --disk-usage
    Archived and active journals take up 199.9M in the file system.
    ~~~

2. If you think that the logs are taking too much space, you can "vacuum" some of them:

    ~~~sh
    $ sudo journalctl --vacuum-time=7d
    Vacuuming done, freed 0B of archived journals from /run/log/journal.
    Vacuuming done, freed 0B of archived journals from /var/log/journal.
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-0000000000000001-00063c6e407a2f8b.journal (5.2M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-0000000000000ba4-00063cb8d46c569f.journal (11.7M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-0000000000004bf1-00063d403eba34d9.journal (36.6M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/user-1000@3938c3f2d1f04a3e902046506b81af9e-0000000000004fb1-00063d4347eeb8e7.journal (4.7M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-0000000000016a78-00063f73e5f67f5c.journal (21.1M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-000000000001fa56-000640a012d85c46.journal (11.3M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-00000000000237ac-000641a904934689.journal (17.7M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-000000000002a707-00064416a697d9de.journal (6.9M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-000000000002bfcf-0006459600fb4076.journal (14.5M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-0000000000031a43-0006472edf1edb55.journal (4.6M).
    Deleted archived journal /var/log/journal/b1c5982b700c47a79e790afa254b5c90/system@3938c3f2d1f04a3e902046506b81af9e-000000000003211b-000648426381052a.journal (25M).
    Vacuuming done, freed 159.9M of archived journals from /var/log/journal/b1c5982b700c47a79e790afa254b5c90.
    ~~~

    There are several details to notice from the `journalctl` command above:

    - The option `--vacuum-time` is for removing files that contain data older than the period specified, in this case seven days (`7d`). The command has other similar options, check them out with `man journalctl`.

    - The command does the vacuuming in three different locations:

        - `/run/log/journal`\
          Used as a fallback for in-memory logging when no persistent storage is available, as in booting time.

        - `/var/log/journal/b1c5982b700c47a79e790afa254b5c90`\
          The persistent location of all the journal logs in the system.

        - `/var/log/journal`\
          The default path for journal logs, although usually it should not have any.

    - The command informs you of the files it has removed and how much space it has freed on each location.

3. Check out how much space use your journal logs after the vacuuming action:

    ~~~sh
    $ sudo journalctl --disk-usage
    Archived and active journals take up 40M in the file system.
    ~~~

    In this case, the usage has dropped from 199.9 MB to just 40 MB.

Alternatively, you can just readjust your systemd journal's configuration, making it remove those logs earlier:

1. The configuration file for systemd journals is `/etc/systemd/journald.conf` and, as usual, first you should make a backup of it:

    ~~~sh
    $ sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.orig
    ~~~

2. Open `/etc/systemd/journald.conf` with an editor to see the following content:

    ~~~sh
    #  This file is part of systemd.
    #
    #  systemd is free software; you can redistribute it and/or modify it under the
    #  terms of the GNU Lesser General Public License as published by the Free
    #  Software Foundation; either version 2.1 of the License, or (at your option)
    #  any later version.
    #
    # Entries in this file show the compile time defaults. Local configuration
    # should be created by either modifying this file (or a copy of it placed in
    # /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
    # the /etc/systemd/journald.conf.d/ directory. The latter is generally
    # recommended. Defaults can be restored by simply deleting the main
    # configuration file and all drop-ins located in /etc/.
    #
    # Use 'systemd-analyze cat-config systemd/journald.conf' to display the full config.
    #
    # See journald.conf(5) for details.

    [Journal]
    #Storage=auto
    #Compress=yes
    #Seal=yes
    #SplitMode=uid
    #SyncIntervalSec=5m
    #RateLimitIntervalSec=30s
    #RateLimitBurst=10000
    #SystemMaxUse=
    #SystemKeepFree=
    #SystemMaxFileSize=
    #SystemMaxFiles=100
    #RuntimeMaxUse=
    #RuntimeKeepFree=
    #RuntimeMaxFileSize=
    #RuntimeMaxFiles=100
    #MaxRetentionSec=0
    #MaxFileSec=1month
    #ForwardToSyslog=no
    #ForwardToKMsg=no
    #ForwardToConsole=no
    #ForwardToWall=yes
    #TTYPath=/dev/console
    #MaxLevelStore=debug
    #MaxLevelSyslog=debug
    #MaxLevelKMsg=notice
    #MaxLevelConsole=info
    #MaxLevelWall=emerg
    #MaxLevelSocket=debug
    #LineMax=48K
    #ReadKMsg=yes
    #Audit=yes
    ~~~

    Check the meaning of all the parameters in this file in the corresponding man page, `man journald.conf`.

3. For example, you can apply a simple change to just limit the logs retained to only those within one week. To specify this, uncomment the `MaxRetentionSec` parameter and edit it as follows:

    ~~~sh
    MaxRetentionSec=7day
    ~~~

    Or

    ~~~sh
    MaxRetentionSec=1week
    ~~~

4. Save the changes and exit the file.

5. Restart the systemd journal service:

    ~~~sh
    $ sudo systemctl restart systemd-journald.service
    ~~~

This way, systemd cleans up its journals automatically more frequently.

> [!NOTE]
> **Learn more about systemd journaling**\
> To know some more about clearing the journals of systemd, [check out this article](https://linuxhandbook.com/clear-systemd-journal-logs/).

### Procedures for pruning container images

The only place in your cluster setup where you have container images is in your K3s nodes. Therefore, the cleaning procedure explained in this subsection only applies to them.

It does not matter if a node is a server/master or an agent/worker, both types run containers and both need to cache their images in their root ( `/` ) filesystem to run them when required. The Kubernetes engine does [automatic garbage collection on unused containers and images](https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images), but you might find its default settings too "generous" with your storage space. This guide will show you two ways to deal with the issue of your container images eating up too much of your K3s nodes storage space, one manual and another through the configuration of the K3s Kubernetes engine.

#### Pruning container images manually

This is a straightforward procedure that you can execute in all your K3s nodes, but you must be aware that **it removes any image not currently used in a running container** within your Kubernetes cluster, regardless of its age:

1. First, use `df` to get an idea of the usage status of the filesystem where the images are stored, root ( `/` ):

    ~~~sh
    $ df -h /
    Filesystem                    Size  Used Avail Use% Mounted on
    /dev/mapper/k3snode--vg-root  9.1G  3.3G  5.4G  38% /
    ~~~

    In this case, 3.3 GB are in use in root ( `/` ), and some of that usage is due to the container images stored in the K3s node.

2. Discover which are the images stored in the node with the `k3s crictl` command:

    ~~~sh
    $ sudo k3s crictl images
    IMAGE                                                   TAG                 IMAGE ID            SIZE
    docker.io/prom/node-exporter                            v1.10.2             696e69e899e06       13.1MB
    docker.io/rancher/local-path-provisioner                v0.0.31             8309ed19e06b9       20.7MB
    docker.io/rancher/local-path-provisioner                v0.0.34             acccaf97bcb57       21.6MB
    docker.io/rancher/mirrored-coredns-coredns              1.12.3              0392ee0389032       22.4MB
    docker.io/rancher/mirrored-library-traefik              3.3.6               3a1e150bf4c56       58.3MB
    docker.io/rancher/mirrored-library-traefik              3.6.7               171247bbf2d70       52.2MB
    docker.io/rancher/mirrored-pause                        3.6                 6270bb605e12e       301kB
    quay.io/metallb/speaker                                 v0.15.2             1eeb60bd05864       59.8MB
    quay.io/metallb/speaker                                 v0.15.3             7976d450b330f       51.4MB
    registry.k8s.io/kube-state-metrics/kube-state-metrics   v2.18.0             712edf0123129       19.3MB
    registry.k8s.io/metrics-server/metrics-server           v0.8.0              b9e1e3849e070       22.5MB
    registry.k8s.io/metrics-server/metrics-server           v0.8.1              e76b3f3568b7f       22.6MB
    ~~~

    Realize that this output does not tell you which images are currently in use. To do that you would have to check out the containers themselves with the `kubectl` command.

3. If you are decided to execute a cleanup of images, you have to do it also with the `k3s crictl` command:

    ~~~sh
    $ sudo k3s crictl rmi --prune
    Deleted: registry.k8s.io/metrics-server/metrics-server:v0.8.0
    Deleted: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0
    Deleted: docker.io/rancher/local-path-provisioner:v0.0.31
    Deleted: quay.io/metallb/speaker:v0.15.2
    Deleted: docker.io/rancher/mirrored-pause:3.6
    Deleted: docker.io/rancher/mirrored-coredns-coredns:1.12.3
    Deleted: docker.io/rancher/mirrored-library-traefik:3.3.6
    ~~~

    The output of `k3s crictl` informs you of the images deleted and, when they happen, of errors that may happen in this action.

4. With the pruning done, let's see what images remain in the node, again with `k3s crictl`:

    ~~~sh
    $ sudo k3s crictl images
    IMAGE                                           TAG                 IMAGE ID            SIZE
    docker.io/prom/node-exporter                    v1.10.2             696e69e899e06       13.1MB
    docker.io/rancher/local-path-provisioner        v0.0.34             acccaf97bcb57       21.6MB
    docker.io/rancher/mirrored-library-traefik      3.6.7               171247bbf2d70       52.2MB
    quay.io/metallb/speaker                         v0.15.3             7976d450b330f       51.4MB
    registry.k8s.io/metrics-server/metrics-server   v0.8.1              e76b3f3568b7f       22.6MB
    ~~~

    The list has gotten noticeably shorter, and no app or service has older or redundant images.

5. Finally, to see how much space has been recovered in your node's root ( `/` ) filesystem, use `df`:

    ~~~sh
    $ df -h /
    Filesystem                    Size  Used Avail Use% Mounted on
    /dev/mapper/k3snode--vg-root  9.1G  2.5G  6.2G  29% /
    ~~~

    The usage has fallen from 3.3 GB to 2.5 GB, which is a significant reduction. This highlights the importance of removing unused images from your nodes.

As a final consideration on this regard, you could think about setting this prune command as a `cron` task in all your K3s nodes, to be run once a month for instance.

#### Adjusting the automated garbage collection of unused container images

As indicated earlier, the Kubernetes engine handles automatically the pruning of container images. This process is regulated with two kubelet parameters that come with default values that you might want to change. These parameters are:

- `imageGCHighThresholdPercent`: Integer value, set as **85** by default.\
  It must be always **greater** than `imageGCLowThresholdPercent`. Percentage value of the disk/filesystem usage. When disk usage goes over this threshold, the image garbage collector is always executed.

- `imageGCLowThresholdPercent`: integer value, set as **80** by default.\
  It must be always **lower** than `imageGCHighThresholdPercent`. Percentage value of the disk/filesystem usage. When disk usage is below this level, the image garbage collector is never executed.

In other words, the Kubernetes engine can only launch (when it deems necessary) the image garbage collector if disk usage has reached or gone over the `imageGCLowThresholdPercent` limit, and when the usage hits or surpasses the `imageGCHighThresholdPercent` threshold the Kubernetes engine always execute this cleaning process. The garbage collector always starts deleting from the oldest images and keeps going on until it hits the `imageGCLowThresholdPercent` limit.

> [!NOTE]
> **The official Kubernetes documentation is not clear about the _disk usage_ notion regarding garbage collection**\
> When the official Kubernetes documentation talks about _disk usage_, it is not specified if they mean "total disk usage as reported by the filesystem" or something more nuanced as "disk usage of container images from the filesystem's storage total capacity". This guide assumes the former.

To estimate a new value for the parameters, also take into account the other reasons that increase disk usage, such as logs or temporal files being written in the system. From this point of view, the defaults look very reasonable. Yet, if you are sure you want to change the values, do the following.

1. The parameters you want to change are for the Kubelet process running on each K3s node, so you can take advantage of the `kubelet.config` file you already have in your nodes and edit the parameters there. But first you must make a backup of your current `/etc/rancher/config.yaml.d/kubelet.conf` file:

    ~~~sh
    $ sudo cp /etc/rancher/config.yaml.d/kubelet.conf /etc/rancher/config.yaml.d/kubelet.conf.bkp
    ~~~

2. Open with an editor the `kubelet.config` file (remember that you also had it symlinked as `/etc/rancher/k3s/kubelet.conf`). It should look like this at this point:

    ~~~sh
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

3. Add the two image garbage collector parameters to the `kubelet.config` file as shown here:

    ~~~sh
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    imageGCHighThresholdPercent: 65
    imageGCLowThresholdPercent: 60
    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

    Here the `imageGC` parameters are set in alphabetical order over the ones already present in the file. The values are just for reference, you should estimate which ones are good for your setup.

4. Save the changes and restart the K3s service:

    - In **server** nodes:

    ~~~sh
    $ sudo systemctl restart k3s.service
    ~~~

    - In **agent** nodes:

    ~~~sh
    $ sudo systemctl restart k3s-agent.service
    ~~~

    > [!IMPORTANT]
    > **Restarting the K3s service does not affect your containers**\
    > The apps and services deployed in your cluster keep on running while the K3s service restarts.

## Reminder about the `apt` updates

After updating a Debian system, some old `apt` packages can be left back and you have to remove them manually. This usually happens with old kernel packages, but it can also happen with other packages that apt detects as not in use by any other package. So remember to execute the following `apt` command after applying any `apt upgrade`:

~~~sh
$ sudo apt autoremove
~~~

## Relevant system paths

### Folders in the Proxmox VE host

- `/boot`
- `/etc/logrotate.d`
- `/run/log/journal`
- `/tmp`
- `/var/cache`
- `/var/log`
- `/var/log/journal`
- `/var/tmp`
- `/var/spool`

### Files in the Proxmox VE host

- `/etc/systemd/journald.conf`

### Folders in the K3s node VMs

- `/boot`
- `/etc/logrotate.d`
- `/run/log/journal`
- `/tmp`
- `/var/cache`
- `/var/lib/rancher/k3s/agent/containerd`
- `/var/log`
- `/var/log/containers`
- `/var/log/journal`
- `/var/log/pods`
- `/var/tmp`
- `/var/spool`

### Files in the K3s node VMs

- `/etc/rancher/config.yaml.d/kubelet.conf`
- `/etc/rancher/config.yaml.d/kubelet.conf.bkp`
- `/etc/rancher/k3s/kubelet.conf`
- `/etc/systemd/journald.conf`
- `/var/lib/rancher/k3s/agent/containerd/containerd.log`

## References

### Linux

- [Linux Handbook. How to Clear Systemd Journal Logs](https://linuxhandbook.com/clear-systemd-journal-logs/)

### [K3s](https://k3s.io/)

- [GitHub. K3s](https://github.com/k3s-io/k3s/)
  - [Issues. how to clean unused images, just like `docker system prune`](https://github.com/k3s-io/k3s/issues/1900)

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Concepts](https://kubernetes.io/docs/concepts/)
  - [Cluster Architecture. Garbage Collection](https://kubernetes.io/docs/concepts/architecture/garbage-collection/)
    - [Garbage collection of unused containers and images](https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images)

- [Kubernetes Documentation. Reference](https://kubernetes.io/docs/reference/)
  - [Configuration APIs. Kubelet Configuration (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)
    - [KubeletConfiguration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration)
  - [Component tools. kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

## Navigation

[<< Previous (**G045. System update 04**)](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G047. Understanding your homelab setup through diagrams**) >>](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md)
