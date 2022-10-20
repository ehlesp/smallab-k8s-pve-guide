# G046 - Cleaning the system

Over time, any system accumulates digital "dirt" that you must get rid of, and certainly the setup you've set up with all the previous guides is no exception for this. Cleaning that dirt will free up some of your precious storage space and, in the case of the K3s cluster nodes, slightly reduces the size of your VMs backups.

## Checking your storage status

From the point of view of storage, the system described in this guide series has two levels.

- **Proxmox VE host**: main concerns here are logs and temporal files.
- **K3s cluster nodes**: beyond logs and temporal files, Kubernetes nodes also accumulate over time old unused images that must be pruned periodically.

### _Storage space status on the Proxmox VE host_

#### **Filesystem status on Proxmox VE host**

In any Debian-based system such as your Proxmox VE server, remember that you can check the storage available in your filesystems with the `df` command. Open a remote shell to your Proxmox VE server and execute the command as follows.

~~~bash
$ sudo df -h
[sudo] password for mgrsys:
Filesystem                            Size  Used Avail Use% Mounted on
udev                                  3.8G     0  3.8G   0% /dev
tmpfs                                 785M  1.1M  784M   1% /run
/dev/mapper/pve-root                   13G  4.6G  7.2G  39% /
tmpfs                                 3.9G   34M  3.8G   1% /dev/shm
tmpfs                                 5.0M     0  5.0M   0% /run/lock
/dev/sda2                             511M  328K  511M   1% /boot/efi
/dev/mapper/hddusb-hddusb_bkpvzdumps  1.8T  1.3T  438G  75% /mnt/hddusb_bkpvzdumps
/dev/mapper/hddint-hdd_templates       59G  380M   56G   1% /mnt/hdd_templates
/dev/fuse                             128M   24K  128M   1% /etc/pve
tmpfs                                 785M     0  785M   0% /run/user/1000
~~~

All the filesystems listed by `df` are a concern, but pay special attention to the root ( `/` ) one since it's where your Proxmox VE is installed. You don't want to ever run out of space there.

#### **Key directories on `/` filesystem of Proxmox VE host**

It's in the `/` filesystem where all the Proxmox VE logs, temporal and other critical files are stored, so you must know which directories are those you should pay particular attention to.

- `/boot`: where kernel and boot-related files are stored. Notice that the `/boot/efi` directory is just a mount point for a different filesystem meant specifically for the EFI firmware.
- `/tmp`: the main directory for temporal files.
- `/var/cache`: directory where services running in the system can leave files for caching purposes.
- `/var/log`: where all system and service logs are stored.
- `/var/tmp`: another directory for temporal files.
- `/var/spool`: directory to leave files pending to be processed, such as outgoing mail or for printing.

To know how much space a directory is taking in your filesystem, use the `du` command. For instance, let's measure the `/var/log` folder.

~~~bash
$ sudo du -sh /var/log/
410M    /var/log/
~~~

In this case, the `/var/log` folder of my Proxmox VE system fills about 410 MB of the `/` filesystem, which is just fine. Also, you've seen that I've used `du` with two particular options.

- `-s`: gives a summarized total.
- `-h`: to print the measurement in a format easier to read.

#### **Systemd journal logs**

Within the `/var/logs` path there's a `journal` folder which contains the journal logs of `systemd`. In my Proxmox VE system it looks like this.

~~~bash
$ ls -al /var/log/journal
total 12
drwxr-sr-x+  3 root systemd-journal 4096 Jul 25 17:35 .
drwxr-xr-x  15 root root            4096 Oct 19 10:20 ..
drwxr-sr-x+  2 root systemd-journal 4096 Oct 19 10:26 6c79e2f06e92432c80a17a76cafb922e
~~~

Notice how the group owner of this `journal` folder is `systemd-journal`, and that it contains a subdirectory named with an hexadecimal number which is an identifier for the system itself. The systemd journal's logs are inside this last directory.

~~~bash
$ ls -alh /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/
total 401M
drwxr-sr-x+ 2 root systemd-journal 4.0K Oct 19 10:26 .
drwxr-sr-x+ 3 root systemd-journal 4.0K Jul 25 17:35 ..
-rw-r-----+ 1 root systemd-journal  16M Jul 27 13:37 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000000001-0005e4a2f08e8bd2.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug  2 15:41 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000002632-0005e4c7d87ddb4c.journal
-rw-r-----+ 1 root systemd-journal  16M Aug  4 11:23 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000003512-0005e54246105f24.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug  5 10:06 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000007867-0005e566e5d47106.journal
-rw-r-----+ 1 root systemd-journal  32M Aug 14 10:49 system@432ab158dbed43ed9ef6fc0d13b79461-00000000000086c7-0005e579f30067a1.journal
-rw-r-----+ 1 root systemd-journal  16M Aug 16 10:09 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000010f5d-0005e62f98c4727b.journal
-rw-r-----+ 1 root systemd-journal  40M Aug 30 14:25 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000012a18-0005e657435e043b.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep  1 13:51 system@432ab158dbed43ed9ef6fc0d13b79461-000000000001dd22-0005e7747862b502.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep  2 15:03 system@432ab158dbed43ed9ef6fc0d13b79461-000000000001f15c-0005e79c3ad4b368.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep  4 14:14 system@432ab158dbed43ed9ef6fc0d13b79461-000000000001f844-0005e7b15a6da8e2.journal
-rw-r-----+ 1 root systemd-journal  16M Sep  7 14:23 system@432ab158dbed43ed9ef6fc0d13b79461-000000000001ff1b-0005e7d8e873cd88.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep  8 12:57 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000022f3c-0005e81562656b41.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 10 22:07 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000023c7f-0005e8284aa255b0.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 13 22:02 system@432ab158dbed43ed9ef6fc0d13b79461-00000000000250a9-0005e858355322ac.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 14 21:53 system@432ab158dbed43ed9ef6fc0d13b79461-00000000000265b5-0005e8947d81baf6.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 16 14:22 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000026c9a-0005e8a87cedaaf2.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 18 17:53 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000027372-0005e8ca6b33e968.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 21 13:53 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000028166-0005e8f59889de3a.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 23 14:04 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002887a-0005e92e96f969ba.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 25 19:52 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000029603-0005e956fa2b4831.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 28 21:27 system@432ab158dbed43ed9ef6fc0d13b79461-0000000000029dbc-0005e984139ff8a9.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct  3 11:28 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002a4b4-0005e9c1c1e320f0.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct  5 10:48 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002ab9e-0005ea1df90fc454.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct  6 15:58 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002c15d-0005ea45a52eeabb.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct  8 12:52 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002c895-0005ea5e17f24fd8.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 10 22:41 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002cf48-0005ea83b7df19c8.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 12 19:59 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002d658-0005eab42e93989d.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 14 13:07 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002dd77-0005eada26c9d02e.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 16 13:39 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002e46f-0005eafca2d12d68.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 19 10:20 system@432ab158dbed43ed9ef6fc0d13b79461-000000000002f94d-0005eb25519285fb.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 19 16:17 system.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug 30 14:25 user-1000@45a5cb82df7943a2b9423b9ede38b58e-000000000001381c-0005e662fb012a8d.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug  4 11:23 user-1000@46772ca5c30d4d59ab9c62355d80510d-000000000000354a-0005e542a15ff6de.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep  7 14:23 user-1000@4949bfacbd6b4b688c7c4368a2c360e0-00000000000213fb-0005e7f37f041db2.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug  2 15:41 user-1000@4da66c2be2ac4cd0a11254cf3d86d8ba-00000000000026b7-0005e4c868fb4678.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct  5 10:48 user-1000@58948a811883414693d849710e19d766-000000000002ac08-0005ea1e44932251.journal
-rw-r-----+ 1 root systemd-journal 8.0M Sep 25 19:52 user-1000@ac786a238e764036b62e791de871fc6d-00000000000296ba-0005e9584aed0234.journal
-rw-r-----+ 1 root systemd-journal 8.0M Aug 14 10:49 user-1000@e255377e52ab49518e477063ca5ad315-000000000000951e-0005e591b7a84753.journal
-rw-r-----+ 1 root systemd-journal 8.0M Oct 19 16:27 user-1000.journal
~~~

The `ls` command reports the total size of this folder as 401 MB, and notice how the journal files start by weighting 8 MB and grow in multiples of 8.

> **BEWARE!**  
> Those `.journal` files are binaries, not your regular text-based log file, so don't try to open them with `less`, `vim` or any other text editor.

A more proper way to manage your journal logs is with the `journalctl` command. In this case, to see how much your journal logs weight you can do the following.

~~~bash
$ sudo journalctl --disk-usage
Archived and active journals take up 400.1M in the file system.
~~~

See how `journalctl` returns a more precise measurement as the one I got previously with `ls`. Of course, you can also compare this measuring with what `du` can tell you.

~~~bash
$ sudo du -sh /var/log/journal/
401M    /var/log/journal/
~~~

As you can see, `du` measures the size like `ls`, rounding the decimal up to the next integer value.

To see the systemd journal logs themselves, you have to use the `journalctl` command. For instance, to read **all** the latest logs

~~~bash
$ sudo journalctl -r
~~~

This command will show you the logs in reverse order, starting from the latest one registered, in a `less`-like viewer.

~~~bash
-- Journal begins at Mon 2022-07-25 17:35:55 CEST, ends at Wed 2022-10-19 17:12:10 CEST. --
Oct 19 17:12:10 pve sudo[101481]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Oct 19 17:12:10 pve sudo[101481]:   mgrsys : TTY=pts/3 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl -r
Oct 19 17:10:42 pve sudo[101062]: pam_unix(sudo:session): session closed for user root
Oct 19 17:10:30 pve sudo[101062]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Oct 19 17:10:30 pve sudo[101062]:   mgrsys : TTY=pts/3 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl -r
Oct 19 17:10:23 pve sudo[100977]: pam_unix(sudo:session): session closed for user root
Oct 19 17:10:07 pve sudo[100977]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Oct 19 17:10:07 pve sudo[100977]:   mgrsys : TTY=pts/3 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl -r
Oct 19 17:10:04 pve sudo[100933]: pam_unix(sudo:session): session closed for user root
Oct 19 17:09:59 pve sudo[100933]: pam_unix(sudo:session): session opened for user root(uid=0) by mgrsys(uid=1000)
Oct 19 17:09:59 pve sudo[100933]:   mgrsys : TTY=pts/3 ; PWD=/home/mgrsys ; USER=root ; COMMAND=/usr/bin/journalctl -r
Oct 19 17:07:34 pve sudo[100334]: pam_unix(sudo:session): session closed for user root
...
~~~

> **BEWARE!**  
> You'll see all the journal logs only when you execute the `journalctl` command with `sudo` (or `root` privileges). When not, you'll only see the journal logs relative to your _current_ user.

### _Storage space status on the K3s Kubernetes nodes_

All your K3s nodes are Debian systems, just like your Proxmox VE host, so all the things I've explained in the previous sections about how to check the storage space and which directories you should pay attention first also apply in your K3s VMs. Therefore, here I'll tell you just about the particular Kubernetes-related things that will eat your storage space in your system.

#### **K3s and Kubernetes container logs**

You already know where the K3s logs are in your cluster nodes, I told you about them in the [**G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-k3slog-files-rotation) and [**G036**](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#checking-the-logs) guides. I'll just remind you here about their paths.

- `/var/log/k3s.log`
- `/var/lib/rancher/k3s/agent/containerd/containerd.log`
- `/var/log/containers/`
- `/var/log/pods/`

#### **Images of Kubernetes containers**

> **_NOTICE_**  
> By the time (some months later) I wrote this particular guide, I no longer had the K3s Kubernetes cluster detailed previously in this series, but a more lean and simpler single node one. This is why the commands' outputs won't completely match what it should had been in the cluster. Still, all the commands executed here on my single node K3s setup work as well in the original multinode scenario too.

The containers you deploy in your Kubernetes cluster run docker images, and these images get stored in the root ( `/` ) filesystem of any node running containers. I won't tell you the exact path where the images are stored, since **you must not touch them directly**. Instead, in a K3s-based Kubernetes cluster such as yours, you can use the `k3s` command to get a list of all the images downloaded in a particular node.

~~~bash
$ sudo k3s crictl images
IMAGE                                        TAG                    IMAGE ID            SIZE
docker.io/emberstack/kubernetes-reflector    6.1.47                 33d623321fbae       89.7MB
docker.io/gitea/gitea                        1.16                   e7e1f53658ad9       110MB
docker.io/gitea/gitea                        1.17                   60f51dd498f3e       108MB
docker.io/gitea/gitea                        1.17.2                 622bf599c783b       108MB
docker.io/kubernetesui/dashboard             v2.6.0                 1042d9e0d8fcc       74.6MB
docker.io/kubernetesui/dashboard             v2.7.0                 07655ddf2eebe       75.8MB
docker.io/kubernetesui/metrics-scraper       v1.0.8                 115053965e86b       19.7MB
docker.io/library/mariadb                    10.8-jammy             40b966d7252f5       124MB
docker.io/library/mariadb                    10.9-jammy             5c284e5e82961       124MB
docker.io/library/mariadb                    10.9.3-jammy           11aee66fdc314       124MB
docker.io/library/nextcloud                  24.0-apache            490a945356e4c       318MB
docker.io/library/nextcloud                  24.0.4-apache          69e5eee6991f9       318MB
docker.io/library/nextcloud                  24.0.5-apache          30d005b4cbc13       318MB
docker.io/library/postgres                   14.4-bullseye          e09e90144645e       138MB
docker.io/library/postgres                   14.5-bullseye          b37c2a6c1506f       138MB
docker.io/library/redis                      7.0-alpine             d30e0f8484bbe       11.9MB
docker.io/library/redis                      7.0.5-alpine           0139e70204365       11.9MB
docker.io/rancher/klipper-helm               v0.7.3-build20220613   38b3b9ad736af       83MB
docker.io/rancher/local-path-provisioner     v0.0.21                fb9b574e03c34       11.4MB
docker.io/rancher/mirrored-coredns-coredns   1.9.1                  99376d8f35e0a       14.1MB
docker.io/rancher/mirrored-library-traefik   2.6.2                  72463d8000a35       30.3MB
docker.io/rancher/mirrored-pause             3.6                    6270bb605e12e       301kB
k8s.gcr.io/metrics-server/metrics-server     v0.6.1                 e57a417f15d36       28.1MB
quay.io/jetstack/cert-manager-cainjector     v1.9.1                 11778d29f8cc2       12.1MB
quay.io/jetstack/cert-manager-controller     v1.9.1                 8eaca4249b016       16.8MB
quay.io/jetstack/cert-manager-webhook        v1.9.1                 d3348bcdc1e7e       13.5MB
quay.io/metallb/controller                   v0.13.4                d875204170d63       25.6MB
quay.io/metallb/controller                   v0.13.5                c2a2710353669       25.6MB
quay.io/metallb/speaker                      v0.13.4                5e3a0e9ab91a1       46.8MB
quay.io/metallb/speaker                      v0.13.5                85ac2fb6e3d10       46.8MB
~~~

The list above tells you about all the images currently stored in the node and, more importantly, how much does each of them weight. Notice that older or redundant images are present and, in cases such as the Nextcloud images, eat up a significant chunk of your storage space. Also see how the IMAGE path indicates the source repository of each image: there are those who come from `docker`, others from `quay` and one from `k8s`.

## Cleaning procedures

In general, all the elements I've mentioned before (logs, temporal files and container images) are all already automatically managed by your system in some way. Still, you might find that the default configuration for rotation or pruning of any of those elements is too lenient and you want to either adjust it or known how to execute a proper cleaning manually. Here I'll show ways to do that.

> **BEWARE!**  
> Always be sure that you don't need the element you're removing from your system, most in particular logs. Remember that logs are usually the only piece of information you have to identify the root of any problem you might have in your system.

### _Procedures for cleaning logs_

Here you have to distinguish between the regular `.log` files and the systemd journal logs, but both cases apply in **all** your Debian systems (Proxmox VE host and VMs).

#### **Regular `.log` files**

Usually, your log files will be controlled either by `logrotate` or rotated by the same application or service that writes them. For those that are under the management of `logrotate`, you can force a rotation manually if you feel it necessary.

~~~bash
$ sudo logrotate --force /path/to/service.logrotate.conf
~~~

That command will force the rotation of the particular logs configured in the specified `/path/to/service.logrotate.conf` file, and this may or may not free up some space in your filesystem.

With log files not managed by `logrotate` you can try handling them manually, but be always careful of **not** removing log files currently in use by any service. Instead, you can just empty them with a simple command.

~~~bash
$ > /var/log/theoretical.log
~~~

Since it's left side is an empty input, the `>` operator in this case rewrites the entire target file on the right side with literally nothing, effectively emptying it. Reserve this trick for particularly tight situations.

#### **Systemd journal logs**

Don't ever try to manage the systemd journal log files directly, **always** use the `journalctl` command instead to do so, specially when pruning them.

1. First, check the space used by your systemd journal logs.

    ~~~bash
    $ sudo journalctl --disk-usage
    Archived and active journals take up 400.1M in the file system.
    ~~~

2. If you think that the logs are taking too much space, you can "vacuum" some of them.

    ~~~bash
    $ sudo journalctl --vacuum-time=7d
    Vacuuming done, freed 0B of archived journals from /run/log/journal.
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000000001-0005e4a2f08e8bd2.journal (16.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000002632-0005e4c7d87ddb4c.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@4da66c2be2ac4cd0a11254cf3d86d8ba-00000000000026b7-0005e4c868fb4678.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000003512-0005e54246105f24.journal (16.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@46772ca5c30d4d59ab9c62355d80510d-000000000000354a-0005e542a15ff6de.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000007867-0005e566e5d47106.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-00000000000086c7-0005e579f30067a1.journal (32.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@e255377e52ab49518e477063ca5ad315-000000000000951e-0005e591b7a84753.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000010f5d-0005e62f98c4727b.journal (16.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000012a18-0005e657435e043b.journal (40.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@45a5cb82df7943a2b9423b9ede38b58e-000000000001381c-0005e662fb012a8d.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000001dd22-0005e7747862b502.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000001f15c-0005e79c3ad4b368.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000001f844-0005e7b15a6da8e2.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000001ff1b-0005e7d8e873cd88.journal (16.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@4949bfacbd6b4b688c7c4368a2c360e0-00000000000213fb-0005e7f37f041db2.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000022f3c-0005e81562656b41.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000023c7f-0005e8284aa255b0.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-00000000000250a9-0005e858355322ac.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-00000000000265b5-0005e8947d81baf6.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000026c9a-0005e8a87cedaaf2.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000027372-0005e8ca6b33e968.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000028166-0005e8f59889de3a.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002887a-0005e92e96f969ba.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000029603-0005e956fa2b4831.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@ac786a238e764036b62e791de871fc6d-00000000000296ba-0005e9584aed0234.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-0000000000029dbc-0005e984139ff8a9.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002a4b4-0005e9c1c1e320f0.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002ab9e-0005ea1df90fc454.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/user-1000@58948a811883414693d849710e19d766-000000000002ac08-0005ea1e44932251.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002c15d-0005ea45a52eeabb.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002c895-0005ea5e17f24fd8.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002cf48-0005ea83b7df19c8.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002d658-0005eab42e93989d.journal (8.0M).
    Deleted archived journal /var/log/journal/6c79e2f06e92432c80a17a76cafb922e/system@432ab158dbed43ed9ef6fc0d13b79461-000000000002dd77-0005eada26c9d02e.journal (8.0M).
    Vacuuming done, freed 368.1M of archived journals from /var/log/journal/6c79e2f06e92432c80a17a76cafb922e.
    Vacuuming done, freed 0B of archived journals from /var/log/journal.
    ~~~

    There are several things to notice from the `journalctl` command above.

    - The option `--vacuum-time` is for removing files that contain data older than the period specified, in this case seven days (`7d`). The command has other similar options, check them out with `man journalctl`.
    - The command does the vacuuming in three different locations:
        - `/run/log/journal`: used as a fallback for in-memory logging when no persistent storage is available, as in booting time.
        - `/var/log/journal/6c79e2f06e92432c80a17a76cafb922e`: the persistent location of all the journal logs in the system.
        - `/var/log/journal`: the default path for journal logs, although usually it shouldn't have any.
    - The command informs you of the files it has removed and how much space it has freed on each location.

3. Check out how much space use your journal logs after the vacuuming action.

    ~~~bash
    $ sudo journalctl --disk-usage
    Archived and active journals take up 32.0M in the file system.
    ~~~

    In this case, the usage has dropped from 400.1 MB to just 32.0 MB.

Alternatively, you can just readjust your systemd journal's configuration, making it remove those logs earlier.

1. The configuration file for systemd journals is `/etc/systemd/journald.conf` and, as usual, first you should make a backup of it.

    ~~~bash
    $ sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.orig
    ~~~

2. Open `/etc/systemd/journald.conf` with an editor to see the following content.

    ~~~bash
    #  This file is part of systemd.
    #
    #  systemd is free software; you can redistribute it and/or modify it
    #  under the terms of the GNU Lesser General Public License as published by
    #  the Free Software Foundation; either version 2.1 of the License, or
    #  (at your option) any later version.
    #
    # Entries in this file show the compile time defaults.
    # You can change settings by editing this file.
    # Defaults can be restored by simply deleting this file.
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
    #MaxRetentionSec=
    #MaxFileSec=1month
    #ForwardToSyslog=yes
    #ForwardToKMsg=no
    #ForwardToConsole=no
    #ForwardToWall=yes
    #TTYPath=/dev/console
    #MaxLevelStore=debug
    #MaxLevelSyslog=debug
    #MaxLevelKMsg=notice
    #MaxLevelConsole=info
    #MaxLevelWall=emerg
    #LineMax=48K
    #ReadKMsg=yes
    #Audit=no
    ~~~

    Check the meaning of all the parameters in this file in the corresponding man page, `man journald.conf`.

3. In this case, I'll show you a simple change to just limit the logs retained to only those within one week. To specify this, uncomment the `MaxRetentionSec` parameter and edit it as follows.

    ~~~bash
    MaxRetentionSec=7day
    ~~~

    Or

    ~~~bash
    MaxRetentionSec=1week
    ~~~

4. Save the changes and exit the file.

5. Restart the systemd journal service.

    ~~~bash
    $ sudo systemctl restart systemd-journald.service
    ~~~

This way, systemd will clean up its journals automatically more frequently.

To know some more about clearing the journals of systemd, [check out this article](https://linuxhandbook.com/clear-systemd-journal-logs/).

### _Procedures for pruning container images_

> **_NOTICE_**  
> By the time (some months later) I wrote this particular guide, I no longer had the K3s Kubernetes cluster detailed previously in this series, but a more lean and simpler single node one. This is why the commands' outputs won't completely match what it should had been in the cluster. Still, all the commands executed here on my single node K3s setup work as well in the original multinode scenario too.

The only place in your cluster setup where you'll have container images is in your K3s nodes, so the cleaning procedure I'll show you next only applies to them. It doesn't matter if a node is a server/master or an agent/worker, both types run containers and both need to cache their images in their root ( `/` ) filesystem to run them when required. The Kubernetes engine does [automatic garbage collection on unused containers and images](https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images), but you might find its default settings too "generous" with your storage space. So here I'll show you two ways to deal with the issue of your container images eating up too much of your K3s nodes storage space, one manual and another through the configuration of the K3s Kubernetes engine.

#### _Deleting container images manually_

This is a straightforward procedure that you can execute in all your K3s nodes, but you must be aware that it will remove **any image** not currently used in a running container within your Kubernetes cluster, regardless of its age.

1. First, use `df` to get an idea of the usage status of the filesystem where the images are stored, root ( `/` ).

    ~~~bash
    $ df -h /
    Filesystem                    Size  Used Avail Use% Mounted on
    /dev/mapper/k3snode--vg-root   25G   12G   13G  48% /
    ~~~

    In this case, 12 GB are in use in root ( `/` ), and some of that usage is due to the container images stored in the K3s node.

2. Now, let's see which are the images stored in the node with the `k3s crictl` command.

    ~~~bash
    $ sudo k3s crictl images
    IMAGE                                        TAG                    IMAGE ID            SIZE
    docker.io/emberstack/kubernetes-reflector    6.1.47                 33d623321fbae       89.7MB
    docker.io/gitea/gitea                        1.16                   e7e1f53658ad9       110MB
    docker.io/gitea/gitea                        1.17                   60f51dd498f3e       108MB
    docker.io/gitea/gitea                        1.17.2                 622bf599c783b       108MB
    docker.io/kubernetesui/dashboard             v2.6.0                 1042d9e0d8fcc       74.6MB
    docker.io/kubernetesui/dashboard             v2.7.0                 07655ddf2eebe       75.8MB
    docker.io/kubernetesui/metrics-scraper       v1.0.8                 115053965e86b       19.7MB
    docker.io/library/mariadb                    10.8-jammy             40b966d7252f5       124MB
    docker.io/library/mariadb                    10.9-jammy             5c284e5e82961       124MB
    docker.io/library/mariadb                    10.9.3-jammy           11aee66fdc314       124MB
    docker.io/library/nextcloud                  24.0-apache            490a945356e4c       318MB
    docker.io/library/nextcloud                  24.0.4-apache          69e5eee6991f9       318MB
    docker.io/library/nextcloud                  24.0.5-apache          30d005b4cbc13       318MB
    docker.io/library/postgres                   14.4-bullseye          e09e90144645e       138MB
    docker.io/library/postgres                   14.5-bullseye          b37c2a6c1506f       138MB
    docker.io/library/redis                      7.0-alpine             d30e0f8484bbe       11.9MB
    docker.io/library/redis                      7.0.5-alpine           0139e70204365       11.9MB
    docker.io/rancher/klipper-helm               v0.7.3-build20220613   38b3b9ad736af       83MB
    docker.io/rancher/local-path-provisioner     v0.0.21                fb9b574e03c34       11.4MB
    docker.io/rancher/mirrored-coredns-coredns   1.9.1                  99376d8f35e0a       14.1MB
    docker.io/rancher/mirrored-library-traefik   2.6.2                  72463d8000a35       30.3MB
    docker.io/rancher/mirrored-pause             3.6                    6270bb605e12e       301kB
    k8s.gcr.io/metrics-server/metrics-server     v0.6.1                 e57a417f15d36       28.1MB
    quay.io/jetstack/cert-manager-cainjector     v1.9.1                 11778d29f8cc2       12.1MB
    quay.io/jetstack/cert-manager-controller     v1.9.1                 8eaca4249b016       16.8MB
    quay.io/jetstack/cert-manager-webhook        v1.9.1                 d3348bcdc1e7e       13.5MB
    quay.io/metallb/controller                   v0.13.4                d875204170d63       25.6MB
    quay.io/metallb/controller                   v0.13.5                c2a2710353669       25.6MB
    quay.io/metallb/speaker                      v0.13.4                5e3a0e9ab91a1       46.8MB
    quay.io/metallb/speaker                      v0.13.5                85ac2fb6e3d10       46.8MB
    ~~~

    This is the same list I showed you [earlier in this guide](#images-of-kubernetes-containers), but now also realize that this output doesn't tell you which images are currently in use. To do that you would have to check out the containers themselves with the `kubectl` command.

3. If you're decided to execute a cleanup of images, you have to do it also with the `k3s crictl` command.

    ~~~bash
    $ sudo k3s crictl rmi --prune
    Deleted: quay.io/metallb/controller:v0.13.4
    E1019 11:02:56.361908    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:490a945356e4c6af60162c202cd335b38153cb5d15d33d3b6966442b0ab354ac"
    E1019 11:02:58.364345    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:d30e0f8484bbe1929025f5ec91049d42e0f3399aac22f3f794e63ecf077dd24f"
    E1019 11:03:00.365967    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:6270bb605e12e581514ada5fd5b3216f727db55dc87d5889c790e4c760683fee"
    Deleted: docker.io/gitea/gitea:1.17
    E1019 11:03:02.905448    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = Unknown desc = failed to delete image reference \"sha256:40b966d7252f541b41677fc35f8660fa90d14df0f33edc8085e6ca2dc0c5b247\" for \"sha256:40b966d7252f541b41677fc35f8660fa90d14df0f33edc8085e6ca2dc0c5b247\": context deadline exceeded: unknown" image="sha256:40b966d7252f541b41677fc35f8660fa90d14df0f33edc8085e6ca2dc0c5b247"
    Deleted: docker.io/rancher/klipper-helm:v0.7.3-build20220613
    Deleted: docker.io/library/mariadb:10.9-jammy
    Deleted: docker.io/library/postgres:14.4-bullseye
    E1019 11:03:08.040270    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:69e5eee6991f95548088a76658596296d650107f942aa4c75cee027ed03cea34"
    E1019 11:03:10.042530    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:e7e1f53658ad95a44d37aed9f454124317e71a59a1d3e0afc065d19256707e14"
    E1019 11:03:12.046438    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:5e3a0e9ab91a112fa5a4635242b3c3342f6d53d1713946a0dd1ce93077e22441"
    E1019 11:03:14.050055    5932 remote_image.go:270] "RemoveImage from image service failed" err="rpc error: code = DeadlineExceeded desc = context deadline exceeded" image="sha256:1042d9e0d8fcc64f2c6b9ade3af9e8ed255fa04d18d838d0b3650ad7636534a9"
    ~~~

    The output of `k3s crictl` informs you of the images deleted and, in this case, of errors when executing the `rmi --prune` action. I haven't found the reason for those `E1019` errors, but they're probably due to the command trying to remove images currently in use by running containers. Regardless, the command will do its job.

4. With the pruning done, let's see what images remain in the node, again with `k3s crictl`.

    ~~~bash
    $ sudo k3s crictl images
    IMAGE                                        TAG                 IMAGE ID            SIZE
    docker.io/emberstack/kubernetes-reflector    6.1.47              33d623321fbae       89.7MB
    docker.io/gitea/gitea                        1.17.2              622bf599c783b       108MB
    docker.io/kubernetesui/dashboard             v2.7.0              07655ddf2eebe       75.8MB
    docker.io/kubernetesui/metrics-scraper       v1.0.8              115053965e86b       19.7MB
    docker.io/library/mariadb                    10.9.3-jammy        11aee66fdc314       124MB
    docker.io/library/nextcloud                  24.0.5-apache       30d005b4cbc13       318MB
    docker.io/library/postgres                   14.5-bullseye       b37c2a6c1506f       138MB
    docker.io/library/redis                      7.0.5-alpine        0139e70204365       11.9MB
    docker.io/rancher/local-path-provisioner     v0.0.21             fb9b574e03c34       11.4MB
    docker.io/rancher/mirrored-coredns-coredns   1.9.1               99376d8f35e0a       14.1MB
    docker.io/rancher/mirrored-library-traefik   2.6.2               72463d8000a35       30.3MB
    k8s.gcr.io/metrics-server/metrics-server     v0.6.1              e57a417f15d36       28.1MB
    quay.io/jetstack/cert-manager-cainjector     v1.9.1              11778d29f8cc2       12.1MB
    quay.io/jetstack/cert-manager-controller     v1.9.1              8eaca4249b016       16.8MB
    quay.io/jetstack/cert-manager-webhook        v1.9.1              d3348bcdc1e7e       13.5MB
    quay.io/metallb/controller                   v0.13.5             c2a2710353669       25.6MB
    quay.io/metallb/speaker                      v0.13.5             85ac2fb6e3d10       46.8MB
    ~~~

    The list has gotten noticeably shorter, and no app or service has older or redundant images.

5. Finally, to see how much space you've recovered in your node's root ( `/` ) filesystem, use `df`.

    ~~~bash
    $ df -h /
    Filesystem                    Size  Used Avail Use% Mounted on
    /dev/mapper/k3snode--vg-root   25G  6.2G   17G  27% /
    ~~~

    The usage has fallen from 12 GB to 6.2 GB, almost 6 GB! This highlights the importance of removing unused images from your nodes.

As a final consideration on this regard, you could think about setting this prune command as a `cron` task in all your K3s nodes, to be run once a month for instance.

#### _Adjusting the automated garbage collection of unused images_

As I already indicated before, the Kubernetes engine handles automatically the pruning of container images. This process is regulated with two kubelet parameters that come with default values that you might want to change. These parameters are:

- `imageGCHighThresholdPercent`: integer value, set as **85** by default. It must be always **greater** than `imageGCLowThresholdPercent`. Percentage value of the disk/filesystem usage. When disk usage goes over this threshold, the image garbage collector is always run.
- `imageGCLowThresholdPercent`: integer value, set as **80** by default. It must be always **lower** than `imageGCHighThresholdPercent`. Percentage value of the disk/filesystem usage. When disk usage is below this level, the image garbage collector is never run.

In other words, the Kubernetes engine can only launch (when it deems necessary) the image garbage collector if disk usage has reached or gone over the `imageGCLowThresholdPercent` limit, and when the usage hits or surpasses the `imageGCHighThresholdPercent` threshold the Kubernetes engine will always execute this cleaning process. The garbage collector always starts deleting from the oldest images and keeps going on until it hits the `imageGCLowThresholdPercent` limit.

> **BEWARE!**  
> When the official documentation talks about _disk usage_, it's not especified if they mean "total disk usage as reported by the filesystem" or something more nuanced as "disk usage of container images from the filesystem's storage total capacity". In this guide I'll assume the former.

To estimate a new value for the parameters, also take into account the other reasons that increase disk usage, such as logs or temporal files being written in the system. From this point of view, the defaults look very reasonable. Yet, if you are sure you want to change the values, do the following.

1. The parameters you want to change are for the Kubelet process running on each K3s node, so you can take advantage of the `kubelet.config` file you already have in your nodes and edit the parameters there. But first you must make a backup of your current `/etc/rancher/k3s.config.d/kubelet.config` file.

    ~~~bash
    $ sudo cp /etc/rancher/k3s.config.d/kubelet.config /etc/rancher/k3s.config.d/kubelet.config.bkp
    ~~~

2. Now you can open with an editor the `kubelet.config` file (remember that you also had it symlinked as `/etc/rancher/k3s/kubelet.config`). It should look like this at this point.

    ~~~bash
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

3. You just need to add the two image garbage collector parameters to `kubelet.config`, so it ends up being like this.

    ~~~bash
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    imageGCHighThresholdPercent: 65
    imageGCLowThresholdPercent: 60
    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

    See that I've put the `imageGC` parameters in alphabetical order over the ones already present in the file. The values are just for reference, you should estimate which ones are good for your setup.

4. Save the changes and restart the K3s service.

    - In **server** nodes.

    ~~~bash
    $ sudo systemctl restart k3s.service
    ~~~

    - In **agent** nodes.

    ~~~bash
    $ sudo systemctl restart k3s-agent.service
    ~~~

    > **BEWARE!**  
    > Remember that restarting the K3s service won't affect your running containers.

## Reminder about the `apt` updates

When you update a Debian system, some old `apt` packages can be left back and you'll have to remove them manually. This usually happens with old kernel packages, but it can also happen with other packages that apt detects as not in use by any other package. So remember to execute the following `apt` command after applying an `update`.

~~~bash
$ sudo apt autoremove
~~~

## Relevant system paths

### _Folders on the Proxmox VE host_

- `/boot`
- `/tmp`
- `/var/cache`
- `/var/log`
- `/var/log/journal`
- `/var/tmp`
- `/var/spool`

### _Files on the Proxmox VE host_

- `/etc/systemd/journald.conf`

### _Folders on the VMs/K3s nodes_

- `/boot`
- `/tmp`
- `/var/cache`
- `/var/lib/rancher/k3s/agent/containerd`
- `/var/log`
- `/var/log/containers/`
- `/var/log/journal`
- `/var/log/pods/`
- `/var/tmp`
- `/var/spool`

### _Files on the VMs/K3s nodes_

- `/etc/rancher/k3s.config.d/kubelet.config`
- `/etc/systemd/journald.conf`
- `/var/lib/rancher/k3s/agent/containerd/containerd.log`
- `/var/log/k3s.log`

## References

### _Linux_

- [How to Clear Systemd Journal Logs](https://linuxhandbook.com/clear-systemd-journal-logs/)

### _K3s_

- [how to clean unused images, just like `docker system prune`](https://github.com/k3s-io/k3s/issues/1900)

### _Kubernetes_

- [Garbage collection of unused containers and images](https://kubernetes.io/docs/concepts/architecture/garbage-collection/#containers-images)
- [Kubelet Configuration (v1beta1). KubeletConfiguration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration)
- [Command line tools reference. Kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

[<< Previous (**G045. System update 04**)](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G901. Appendix 01**) >>](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md)