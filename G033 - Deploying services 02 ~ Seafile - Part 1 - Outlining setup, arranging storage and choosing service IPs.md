# G033 - Deploying services 02 ~ Seafile - Part 1 - Outlining setup, arranging storage and choosing service IPs

- [Beginning with Seafile](#beginning-with-seafile)
- [Outlining Seafile's setup](#outlining-seafiles-setup)
  - [Choosing the K3s agent](#choosing-the-k3s-agent)
- [Setting up new storage drives in the K3s agent node](#setting-up-new-storage-drives-in-the-k3s-agent-node)
  - [Adding the new storage drives to the K3s agent node's VM](#adding-the-new-storage-drives-to-the-k3s-agent-nodes-vm)
  - [LVM storage set up](#lvm-storage-set-up)
  - [Formatting and mounting the new LVs](#formatting-and-mounting-the-new-lvs)
  - [Storage mount points for Seafile components' containers](#storage-mount-points-for-seafile-components-containers)
  - [About increasing the size of volumes](#about-increasing-the-size-of-volumes)
- [Choosing static cluster IPs for Seafile-related services](#choosing-static-cluster-ips-for-seafile-related-services)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in K3s agent node's VM](#folders-in-k3s-agent-nodes-vm)
  - [Files in K3s agent node's VM](#files-in-k3s-agent-nodes-vm)
- [References](#references)
  - [Seafile Admin Manual](#seafile-admin-manual)
  - [Cache servers](#cache-servers)
  - [Database engines](#database-engines)
- [Navigation](#navigation)

## Beginning with Seafile

From the services listed in the [chapter **G018**](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#seafile), let's begin with the **Seafile** file-sharing platform. Since deploying it requires the configuration and deployment of several different components, I have split the Seafile guide in five parts, being this the first one of them. In this part, you will see how to outline the setup of your Nextcloud platform, then work in the arrangement of the storage drives needed to store Nextcloud's data, and finally choose some required IPs.

## Outlining Seafile's setup

First, you must define how you want to setup Seafile in your cluster. This means that you'll have to decide beforehand how to solve the following points:

- For storing operation-related data, Seafile requires a database. Which one are you going to use and how you'll setup it?

- Seafile also needs a cache server. Which one will you use and will it be exclusive to the Seafile instance?

- Where in your K3s cluster should you place the Seafile's users data folder?

This guide solves the previous points as follows:

- **Database**\
  [Seafile's documentation indicates](https://manual.seafile.com/latest/setup/overview/) using [MySQL](https://www.mysql.com/) as database, but this guide will use the compatible alternative [MariaDB](https://mariadb.org/) instead with its data saved in a local SSD storage drive.

- **Cache server**\
  [Seafile's documentation mentions](https://manual.seafile.com/latest/setup/overview/) [Redis](https://redis.io/) as its cache server of choice, but this guide will rather use the compatible alternative [Valkey](https://valkey.io/). This server will not require any storage space since it will run entirely in memory.

- **Seafile's users data**\
  Persistent volume prepared on a local HDD storage drive.

Using Kubernetes affinity rules, **all the Nextcloud-related services will be deployed in pods running in the same K3s agent node**. This implies that the persistent volumes must be also available in that same K3s node.

### Choosing the K3s agent

Your cluster has only two K3s agent nodes, and the two of them are already running services. Pick the one that currently has the lowest CPU and RAM usage of the two. In my case it happened to be the `k3sagent01` node.

## Setting up new storage drives in the K3s agent node

Given how the K3s cluster has been configured, the only persistent volumes you can use are local ones. This means that they rely on paths found in the K3s node VM's host system, but you do not want to use the root filesystem in which the underlying Debian OS is installed. It is better to have separate drives for each persistent volume, which you can create directly from your Proxmox VE web console.

### Adding the new storage drives to the K3s agent node's VM

The very first thing to do is adding the required storage drives to your chosen K3s agent node's VM:

1. Log in your Proxmox VE web console and go to the `Hardware` page of your chosen K3s agent's VM. There, click on the `Add` button and then on the `Hard Disk` option:

    ![Add Hard Disk option in K3s agent node](images/g033/pve_k3sagent_hardware_add_hard_disk_option.webp "Add Hard Disk option in K3s agent node")

2. You'll meet the form (already seen back in the [chapter **G020**](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#setting-up-a-new-virtual-machine)) where you can define a new storage drive for your VM:

    ![Add Hard Disk window for K3s agent node with advanced options enabled](images/g033/pve_k3sagent_hardware_add_hard_disk_window.webp "Add Hard Disk window for K3s agent node with advanced options enabled")

    Add two new "hard disks" to your VM, one SSD drive and a HDD drive. Notice the highlighted elements in the capture above, be sure of having the `Advanced` checkbox enabled and edit only the featured fields as follows:

    - **SSD drive**\
      Storage `ssd_disks`, Discard `ENABLED`, disk size `5 GiB`, SSD emulation `ENABLED`.

    - **HDD drive**\
      Storage `hdd_data`, Discard `ENABLED`, disk size `10 GiB`, SSD emulation `DISABLED`.

    After adding the new drives, they should appear in your K3s agent node VM's hardware list.

    ![New Hard Disks added to K3s agent node VM](images/g033/pve_k3sagent_hardware_hard_disks_added.webp "New Hard Disks added to K3s agent node VM")

3. Now, open a shell in the K3s agent node VM and check with `fdisk` that the new drives are already active and running.

    ~~~sh
    $ sudo fdisk -l
    Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x5dc9a39f

    Device     Boot   Start      End  Sectors  Size Id Type
    /dev/sda1  *       2048  1556479  1554432  759M 83 Linux
    /dev/sda2       1558526 20969471 19410946  9.3G  f W95 Ext'd (LBA)
    /dev/sda5       1558528 20969471 19410944  9.3G 8e Linux LVM


    Disk /dev/mapper/k3snode--vg-root: 9.25 GiB, 9936306176 bytes, 19406848 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/sdb: 5 GiB, 5368709120 bytes, 10485760 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    ~~~

    The new drives are `/dev/sdb` and `/dev/sdc`. Unsurprisingly, they are of the same `Disk model` as `/dev/sda`: `QEMU HARDDISK`.

### LVM storage set up

You have the new storage drives available in your chosen K3s agent node VM, but you still have to configure the required LVM volumes within them:

1. Create a new GPT partition on each of the new storage drives with `sgdisk`. Remember that these new drives are the `/dev/sdb` and `/dev/sdc` devices you saw before with `fdisk`:

    ~~~sh
    $ sudo sgdisk -N 1 /dev/sdb
    $ sudo sgdisk -N 1 /dev/sdc
    ~~~

2. Check with `fdisk` that now you have a new partition on each storage drive:

    ~~~sh
    $ sudo fdisk -l /dev/sdb /dev/sdc
    Disk /dev/sdb: 5 GiB, 5368709120 bytes, 10485760 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: E29D8808-E97B-44CC-93FE-75DC0F2E302C

    Device     Start      End  Sectors Size Type
    /dev/sdb1   2048 10485726 10483679   5G Linux filesystem


    Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: FC861999-48F2-4C84-B522-4018A89BCC42

    Device     Start      End  Sectors Size Type
    /dev/sdc1   2048 20971486 20969439  10G Linux filesystem
    ~~~

    As shown in this shell snippet, find the `/dev/sdb1` and `/dev/sdc1` partitions under their respective "disks".

3. Use `pvcreate` to create a new LVM physical volume, or PV, out of each partition:

    ~~~sh
    $ sudo pvcreate --metadatasize 5m -y -ff /dev/sdb1
    $ sudo pvcreate --metadatasize 10m -y -ff /dev/sdc1
    ~~~

    > [!NOTE]
    > **Simple rule for sizing the metadata space in the LVM physical volume**\
    > To determine the metadata space's size, I have used the rule of thumb of allocating 1 MiB per 1 GiB present in the PV.

    Check with `pvs` that the PVs have been created:

    ~~~sh
    $ sudo pvs
      PV         VG         Fmt  Attr PSize   PFree
      /dev/sda5  k3snode-vg lvm2 a--    9.25g      0
      /dev/sdb1             lvm2 ---   <5.00g  <5.00g
      /dev/sdc1             lvm2 ---  <10.00g <10.00g
    ~~~

4. You also need to assign a volume group, or VG, to each PV, bearing in mind the following:

    - The two drives are running on different storage hardware, so you must clearly differentiate them.
    - Seafile MariaDB database's data will be stored in `/dev/sdb1`, on the SSD drive.
    - Seafile's users data will be kept in `/dev/sdc1`, on the HDD drive.

    Knowing that, create two VGs with `vgcreate`.

    ~~~sh
    $ sudo vgcreate seafile-ssd /dev/sdb1
    $ sudo vgcreate seafile-hdd /dev/sdc1
    ~~~

    See how I named each VG related to Seafile and the kind of underlying drive used. Then, with `pvs` you can see how each PV is now assigned to their respective VG:

    ~~~sh
    $ sudo pvs
      PV         VG          Fmt  Attr PSize PFree
      /dev/sda5  k3snode-vg  lvm2 a--  9.25g    0
      /dev/sdb1  seafile-ssd lvm2 a--  4.99g 4.99g
      /dev/sdc1  seafile-hdd lvm2 a--  9.98g 9.98g
    ~~~

    Also check with `vgs` the current status of the VGs in your VM:

    ~~~sh
    $ sudo vgs
      VG          #PV #LV #SN Attr   VSize VFree
      k3snode-vg    1   1   0 wz--n- 9.25g    0
      seafile-hdd   1   0   0 wz--n- 9.98g 9.98g
      seafile-ssd   1   0   0 wz--n- 4.99g 4.99g
    ~~~

5. At this point, you can create the required light volumes on each VG with `lvcreate`. Remember the purpose of each LV and give them meaningful names:

    ~~~sh
    $ sudo lvcreate -l 100%FREE -n dbdata seafile-ssd
    $ sudo lvcreate -l 100%FREE -n userdata seafile-hdd
    ~~~

    Notice how both new light volumes take up the whole free space available of their respective VGs. Also see how all the LV's names are reminders of the kind of data they'll store later.

    Check with `lvs` the new LVs in your VM:

    ~~~sh
    $ sudo lvs
      LV       VG          Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      root     k3snode-vg  -wi-ao---- 9.25g
      userdata seafile-hdd -wi-a----- 9.98g
      dbdata   seafile-ssd -wi-a----- 4.99g
    ~~~

    With `vgs` you can verify that there is no free storage space left (`VFree` column) in the VGs:

    ~~~sh
    $ sudo vgs
      VG          #PV #LV #SN Attr   VSize VFree
      k3snode-vg    1   1   0 wz--n- 9.25g    0
      seafile-hdd   1   1   0 wz--n- 9.98g    0
      seafile-ssd   1   1   0 wz--n- 4.99g    0
    ~~~

### Formatting and mounting the new LVs

Your new LVs need to be formatted as ext4 filesystems and then mounted in the K3s agent node's system:

1. Before you format the new LVs, you need to see their `/dev/mapper/` paths with `fdisk`. To get only the Seafile related paths, you can filter out their lines with `grep` because the `seafile` string will be part of their paths:

    ~~~sh
    $ sudo fdisk -l | grep seafile
    Disk /dev/mapper/seafile--ssd-dbdata: 4.99 GiB, 5360320512 bytes, 10469376 sectors
    Disk /dev/mapper/seafile--hdd-userdata: 9.98 GiB, 10720641024 bytes, 20938752 sectors
    ~~~

2. Call the `mkfs.ext4` command on their `/dev/mapper/seafile` paths.

    ~~~sh
    $ sudo mkfs.ext4 /dev/mapper/seafile--ssd-dbdata
    $ sudo mkfs.ext4 /dev/mapper/seafile--hdd-userdata
    ~~~

3. Create a directory structure that provides mount points for the new LVs. To make them easier to identify later, make the directories mirror the LVs' naming:

    ~~~sh
    $ sudo mkdir -p /mnt/seafile-ssd/dbdata /mnt/seafile-hdd/userdata
    ~~~

    Notice that you have to use `sudo` for creating those folders, because the system will use its `root` user to mount them later on each boot up. Check, with the `tree` command, that they've been created correctly.

    ~~~sh
    $ tree -F /mnt
    /mnt/
    ├── seafile-hdd/
    │   └── userdata/
    └── seafile-ssd/
        └── dbdata/

    5 directories, 0 files
    ~~~

4. Using the `mount` command, mount the LVs in their respective mount points:

    ~~~sh
    $ sudo mount /dev/mapper/seafile--ssd-dbdata /mnt/seafile-ssd/dbdata
    $ sudo mount /dev/mapper/seafile--hdd-userdata /mnt/seafile-hdd/userdata
    ~~~

    Verify with `df` that they have been mounted in the system. Since you're working in a K3s agent node, you will also see a bunch of containerd-related filesystems mounted. Your newly mounted LVs will appear at the bottom of the list:

    ~~~sh
    $ df -h
    Filesystem                         Size  Used Avail Use% Mounted on
    udev                               965M     0  965M   0% /dev
    tmpfs                              198M  1.1M  197M   1% /run
    /dev/mapper/k3snode--vg-root       9.1G  4.1G  4.5G  48% /
    tmpfs                              987M     0  987M   0% /dev/shm
    tmpfs                              5.0M     0  5.0M   0% /run/lock
    tmpfs                              987M     0  987M   0% /tmp
    tmpfs                              1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
    /dev/sda1                          730M  111M  567M  17% /boot
    tmpfs                              1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
    shm                                 64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/2a568c578a2d3d948387c247fe3de2637d4ef1cf4a62dd917aed22f4801b48c5/shm
    shm                                 64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/85de0719c8beca17a391859ffa522f779c205570616685949404a8cfb5d0a8cd/shm
    shm                                 64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/cf7bf3076a2b7f3de69f90f31ce864d9d5b3e639a6b5293f6584f3602828ae8a/shm
    tmpfs                              180M  8.0K  180M   1% /run/user/1000
    /dev/mapper/seafile--ssd-dbdata    4.9G  1.3M  4.6G   1% /mnt/seafile-ssd/dbdata
    /dev/mapper/seafile--hdd-userdata  9.8G  2.1M  9.3G   1% /mnt/seafile-hdd/userdata
    ~~~

5. To make the mountings permanent, append them to the `/etc/fstab` file of the VM. First, make a backup of the `fstab` file.

    ~~~sh
    $ sudo cp /etc/fstab /etc/fstab.bkp
    ~~~

    Then **append** the following lines to the `fstab` file.

    ~~~sh
    # Seafile volumes
    /dev/mapper/seafile--ssd-dbdata /mnt/seafile-ssd/dbdata ext4 defaults,nofail 0 0
    /dev/mapper/seafile--hdd-userdata /mnt/seafile-hdd/userdata ext4 defaults,nofail 0 0
    ~~~

### Storage mount points for Seafile components' containers

Do not use the directories where you have mounted the new storage volumes as mount points for the persistent volumes you'll enable later for the Seafile deployment. This is because Kubernetes pods can change the owner user and group, and also the permission mode, applied to those folders. This could cause a failure when, after a reboot, your K3s agent node tries to mount again its storage volumes. The issue will happen because it won't have the right user or permissions anymore to access the mount point folders. The best thing to do then is to create another folder within each storage volume that can be used safely as mount point by the Seafile pods:

1. For the LVM storage volumes created before, you have to execute a `mkdir` command like this:

    ~~~sh
    $ sudo mkdir /mnt/{seafile-ssd/dbdata,seafile-hdd/userdata}/k3smnt
    ~~~

    As you did with the mount point folders, these new directories also have to be owned initially by `root`. This is because the K3s service is running under that user.

2. Check the new folder structure with `tree`:

    ~~~sh
    $ tree -F /mnt
    /mnt/
    ├── seafile-hdd/
    │   └── userdata/
    │       ├── k3smnt/
    │       └── lost+found/  [error opening dir]
    └── seafile-ssd/
        └── dbdata/
            ├── k3smnt/
            └── lost+found/  [error opening dir]

    9 directories, 0 files
    ~~~

    Do not mind the `lost+found` folders, they are created by the Linux system automatically.

> [!WARNING]
> **The `k3smnt` folders exist within the already mounted LVM storage volumes!**\
> You must not create those folders without mounting the light volumes first.

### About increasing the size of volumes

If, after a time using and filling up these volumes, you need to increase their size, take a look to the [appendix chapter **G907**](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md). It shows you how to extend a partition and the LVM filesystem within it, although in that case it works on a LV volume that happens to be also the root filesystem of a VM.

## Choosing static cluster IPs for Seafile-related services

For all the main components of your Seafile setup, you are going to create `Service` resources. To make them reachable internally for any pod within your Kubernetes cluster, one way is by assigning them a static cluster IP. With it, you get to know beforehand which internal IP the services have, allowing you pointing the Seafile server instance to the right ones. To determine which cluster IP to g to those future services, you need to take a look with `kubectl` at which cluster IPs are currently in use in your Kubernetes cluster:

~~~sh
$ kubectl get svc -A
NAMESPACE        NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
cert-manager     cert-manager              ClusterIP      10.43.153.243   <none>        9402/TCP                     21d
cert-manager     cert-manager-cainjector   ClusterIP      10.43.131.203   <none>        9402/TCP                     21d
cert-manager     cert-manager-webhook      ClusterIP      10.43.118.87    <none>        443/TCP,9402/TCP             21d
default          kubernetes                ClusterIP      10.43.0.1       <none>        443/TCP                      51d
kube-system      headlamp                  LoadBalancer   10.43.119.9     10.7.0.2      80:31146/TCP                 17d
kube-system      kube-dns                  ClusterIP      10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       51d
kube-system      metrics-server            ClusterIP      10.43.50.63     <none>        443/TCP                      38d
kube-system      traefik                   LoadBalancer   10.43.174.63    10.7.0.0      80:30512/TCP,443:32647/TCP   51d
kube-system      traefik-dashboard         LoadBalancer   10.43.216.2     10.7.0.1      443:31622/TCP                23d
metallb-system   metallb-webhook-service   ClusterIP      10.43.126.18    <none>        443/TCP                      47d
~~~

Check the values under the `CLUSTER-IP` column, and notice how all of them fall under the `10.43` subnet. What you have to do now is just choose IPs that fall into that subnet but do not collide with the ones currently in use by other services. Let's say you choose the following ones:

- `10.43.100.1` for the Seafile server service.
- `10.43.100.2` for the Valkey cache server service.
- `10.43.100.3` for the MariaDB database server service.

See that I've also chosen a cluster IP for the Seafile server. With the internal cluster IPs known, in a later chapter you'll see how Seafile will be able to point at the components it needs to run.

> [!IMPORTANT]
> **Remember that the internal cluster communications run in a separated network**\
> In this guide's setup, the cluster IPs will not collide in any way with the external IPs because they exist in completely separated virtual networks run through independent virtual bridges.

## Relevant system paths

### Folders in K3s agent node's VM

- `/etc`
- `/mnt`
- `/mnt/seafile-hdd`
- `/mnt/seafile-hdd/userdata`
- `/mnt/seafile-hdd/userdata/k3smnt`
- `/mnt/seafile-ssd`
- `/mnt/seafile-ssd/dbdata`
- `/mnt/seafile-ssd/dbdata/k3smnt`

### Files in K3s agent node's VM

- `/dev/mapper/seafile--hdd-userdata`
- `/dev/mapper/seafile--ssd-dbdata`
- `/dev/sdb`
- `/dev/sdb1`
- `/dev/sdc`
- `/dev/sdc1`
- `/etc/fstab`
- `/etc/fstab.bkp`

## References

### [Seafile Admin Manual](https://manual.seafile.com/latest/)

- [Setup. Seafile Docker overview](https://manual.seafile.com/latest/setup/overview/)

### Cache servers

- [Redis](https://redis.io/)
- [Valkey](https://valkey.io/)

### Database engines

- [MariaDB](https://mariadb.org/)
- [MySQL](https://www.mysql.com/)

## Navigation

[<< Previous (**G032. Deploying services 01**)](G032%20-%20Deploying%20services%2001%20~%20Considerations.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Seafile Part 2**) >>](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md)
