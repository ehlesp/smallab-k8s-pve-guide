# G034 - Deploying services 03 ~ Gitea - Part 1 - Outlining setup and arranging storage

- [Deploy Gitea like you deployed Ghost](#deploy-gitea-like-you-deployed-ghost)
- [Outlining Gitea's setup](#outlining-giteas-setup)
  - [Choosing the K3s agent](#choosing-the-k3s-agent)
- [Setting up new storage drives in the K3s agent](#setting-up-new-storage-drives-in-the-k3s-agent)
  - [Adding the new storage drives to the K3s agent node's VM](#adding-the-new-storage-drives-to-the-k3s-agent-nodes-vm)
  - [LVM storage set up](#lvm-storage-set-up)
  - [Formatting and mounting the new LVs](#formatting-and-mounting-the-new-lvs)
  - [Storage mount points for Gitea containers](#storage-mount-points-for-gitea-containers)
  - [About increasing the size of volumes](#about-increasing-the-size-of-volumes)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in K3s agent node's VM](#folders-in-k3s-agent-nodes-vm)
  - [Files in K3s agent node's VM](#files-in-k3s-agent-nodes-vm)
- [Navigation](#navigation)

## Deploy Gitea like you deployed Ghost

The next platform to deploy from the ones listed in the [**G018** guide](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#gitea) is Gitea. Gitea is a Git-based control version system platform which, from a Kubernetes point of view, is like the Ghost platform you have deployed in the previous [**G033** guide](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md). And what exactly makes Gitea so similar to Ghost?

Both platforms share the need for a database, a storage space for their data and the capacity of using a cache system such as Valkey. Therefore, you can expect that the Gitea deployment in your Kubernetes cluster should mirrors Ghost's. In fact, the procedure is so similar that I will not repeat in this Gitea procedure the same explanations I already gave in the Ghost guide, except for specific configuration particularities.

## Outlining Gitea's setup

As you did with Ghost, let's figure out first how to set up all Gitea's main components.

- **Database**\
  PostgreSQL with its data saved in a local SSD storage drive.

- **Cache server**\
  Valkey instance configured to persist its database for faster startup in a local SSD storage drive.

- **Gitea's application data folder**\
  Persistent volume prepared on a local SSD storage drive.

- **Gitea users' repositories**\
  Persistent volume prepared on a local HDD storage drive.

The whole Gitea setup will run in the same K3s agent node, which will be also the one providing the persistent storage required by all Gitea's components.

### Choosing the K3s agent

In the previous [Ghost **G033** guide](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#choosing-the-k3s-agent-node-for-running-ghost) I used the `k3sagent02` node, so here I will use the `k3sagent01` VM for Gitea instead.

## Setting up new storage drives in the K3s agent

The first thing to setup is the storage, which has to be arranged in the the `k3sagent01` agent node in a very similar way as you did for the Ghost deployment:

- One virtual SSD drive containing three LVM volumes.
- One virtual HDD drive holding just one LVM volume.

### Adding the new storage drives to the K3s agent node's VM

At this point you already know how to add a new virtual storage drive to a VM. So, go to the `Hardware` tab of your `k3sagent01` VM and add two _hard disks_ with the following characteristics:

- **SSD drive**: storage `ssd_disks`, Discard `ENABLED`, disk size `10 GiB`, SSD emulation `ENABLED`, IO thread `ENABLED`.

- **HDD drive**: storage `hdd_data`, Discard `ENABLED`, disk size `10 GiB`, SSD emulation `DISABLED`, IO thread `ENABLED`.

These new storage drives should appear as _Hard Disks_ in the `Hardware` list of the `k3sagent01` VM.

![New Hard Disks at k3sagent01 agent node VM](images/g034/pve_k3snode_hardware_hard_disks.webp "New Hard Disks at k3sagent01 agent node VM")

### LVM storage set up

Since the two new storage drives are already active in your `k3sagent01` VM, you can create the necessary LVM volumes in them:

1. Open a shell into your VM and check with `fdisk` the new drives:

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


    Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
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

    The two new drives are the _disks_ named `/dev/sdb` and `/dev/sdc`.

2. Create a new GPT partition on each of the new storage drives with `sgdisk`:

    ~~~sh
    $ sudo sgdisk -N 1 /dev/sdb
    $ sudo sgdisk -N 1 /dev/sdc
    ~~~

3. Check with `fdisk` that now you have a new partition on each storage drive:

    ~~~sh
    $ sudo fdisk -l /dev/sdb /dev/sdc
    Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: 5BF4E78A-E279-46E6-9C9F-52C03B9D99E5

    Device     Start      End  Sectors Size Type
    /dev/sdb1   2048 20971486 20969439  10G Linux filesystem


    Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
    Disk model: QEMU HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: 76799FE7-2C89-4B6B-A2B1-AFE9E857F60F

    Device     Start      End  Sectors Size Type
    /dev/sdc1   2048 20971486 20969439  10G Linux filesystem
    ~~~

    Now you have the partitions `/dev/sdb1` and `/dev/sdc1` on their respective drives.

4. With `pvcreate`, make a new LVM physical volume with each partition:

    ~~~sh
    $ sudo pvcreate --metadatasize 10m -y -ff /dev/sdb1
    $ sudo pvcreate --metadatasize 10m -y -ff /dev/sdc1
    ~~~

    For the metadata size, remember that I use the rule of thumb of allocating 1 MiB per 1 GiB present in the PV.

    Check with `pvs` that the PVs have been created:

    ~~~sh
    $ sudo pvs
      PV         VG         Fmt  Attr PSize   PFree
      /dev/sda5  k3snode-vg lvm2 a--    9.25g      0
      /dev/sdb1             lvm2 ---  <10.00g <10.00g
      /dev/sdc1             lvm2 ---  <10.00g <10.00g
    ~~~

5. Next, assign a volume group to each PV, being aware of the following:

    - The two drives are running on different storage hardware, so you must clearly differentiate their storage space.
    - Gitea's cache and database data will be stored in `/dev/sdb1`, on the SSD drive.
    - Gitea's application data files will be also stored in `/dev/sdb1`, on the SSD drive.
    - Gitea's users git repositories will be kept in `/dev/sdc1`, on the HDD drive.

    Knowing that, create two volume groups with `vgcreate`:

    ~~~sh
    $ sudo vgcreate gitea-ssd /dev/sdb1
    $ sudo vgcreate gitea-hdd /dev/sdc1
    ~~~

    With `pvs` check that each PV is assigned to their corresponding VG:

    ~~~sh
    $ sudo pvs
      PV         VG         Fmt  Attr PSize PFree
      /dev/sda5  k3snode-vg lvm2 a--  9.25g    0
      /dev/sdb1  gitea-ssd  lvm2 a--  9.98g 9.98g
      /dev/sdc1  gitea-hdd  lvm2 a--  9.98g 9.98g
    ~~~

    Also check with `vgs` the current status of the VGs:

    ~~~sh
    $ sudo vgs
      VG         #PV #LV #SN Attr   VSize VFree
      gitea-hdd    1   0   0 wz--n- 9.98g 9.98g
      gitea-ssd    1   0   0 wz--n- 9.98g 9.98g
      k3snode-vg   1   1   0 wz--n- 9.25g    0
    ~~~

6. Create the required light volumes on each VG with `lvcreate`. Remember the purpose of each LV and give them meaningful names:

    ~~~sh
    $ sudo lvcreate -l 30%FREE -n cache gitea-ssd
    $ sudo lvcreate -l 70%FREE -n db gitea-ssd
    $ sudo lvcreate -l 100%FREE -n srv gitea-ssd
    $ sudo lvcreate -l 100%FREE -n repos gitea-hdd
    ~~~

    > [!IMPORTANT]
    > **Remember what the `%FREE` percentage in the `lvcreate` command means**\
    > The `%FREE` number indicates the percentage the `lvcreate` command will take when creating the light volume from what is currently free (unassigned) in the volume group.
    >
    > In the shell snippet above:
    >
    > - The first `lvcreate` command takes 30% of the 10GiB available in the `gitea-ssd` VG at that moment.
    > - The second `lvcreate` command takes the 70% (about 5GiB) of the approximately 7GiB remaining in the `gitea-ssd` VG.
    > - The third `lvcreate` command uses all the remaining (100%) free space left (about 2GiB) in the `gitea-ssd` VG.
    > -The last `lvcreate` command takes up all the free space available in the `gitea-hdd` VG.

    Check with `lvs` the new LVs in your VM:

    ~~~sh
    $ sudo lvs
      LV    VG         Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      repos gitea-hdd  -wi-a-----  9.98g
      cache gitea-ssd  -wi-a-----  2.99g
      db    gitea-ssd  -wi-a-----  4.89g
      srv   gitea-ssd  -wi-a----- <2.10g
      root  k3snode-vg -wi-ao----  9.25g
    ~~~

    Also verify with `vgs` that there's no free space left in any of the VGs:

    ~~~sh
    $ sudo vgs
      VG         #PV #LV #SN Attr   VSize VFree
      gitea-hdd    1   1   0 wz--n- 9.98g    0
      gitea-ssd    1   3   0 wz--n- 9.98g    0
      k3snode-vg   1   1   0 wz--n- 9.25g    0
    ~~~

### Formatting and mounting the new LVs

The new light volumes have to be formatted as ext4 filesystems and mounted:

1. Get the LVs `/dev/mapper` paths with `fdisk` and `grep`:

    ~~~sh
    $ sudo fdisk -l | grep gitea
    Disk /dev/mapper/gitea--ssd-cache: 2.99 GiB, 3212836864 bytes, 6275072 sectors
    Disk /dev/mapper/gitea--ssd-db: 4.89 GiB, 5255462912 bytes, 10264576 sectors
    Disk /dev/mapper/gitea--ssd-srv: 2.1 GiB, 2252341248 bytes, 4399104 sectors
    Disk /dev/mapper/gitea--hdd-repos: 9.98 GiB, 10720641024 bytes, 20938752 sectors
    ~~~

2. Execute the `mkfs.ext4` command on each of the `/dev/mapper/gitea` paths:

    ~~~sh
    $ sudo mkfs.ext4 /dev/mapper/gitea--ssd-cache
    $ sudo mkfs.ext4 /dev/mapper/gitea--ssd-db
    $ sudo mkfs.ext4 /dev/mapper/gitea--ssd-srv
    $ sudo mkfs.ext4 /dev/mapper/gitea--hdd-repos
    ~~~

3. Create a folder tree to mount the LVs in under the `/mnt` path:

    ~~~sh
    $ sudo mkdir -p /mnt/gitea-ssd/{cache,db,srv} /mnt/gitea-hdd/repos
    ~~~

    Check the directory structure with `tree`:

    ~~~sh
    $ tree -F /mnt
    /mnt/
    ├── gitea-hdd/
    │   └── repos/
    └── gitea-ssd/
        ├── cache/
        ├── db/
        └── srv/

    7 directories, 0 files
    ~~~

4. Mount the LVs in their corresponding mount points:

    ~~~sh
    $ sudo mount /dev/mapper/gitea--ssd-cache /mnt/gitea-ssd/cache
    $ sudo mount /dev/mapper/gitea--ssd-db /mnt/gitea-ssd/db
    $ sudo mount /dev/mapper/gitea--ssd-srv /mnt/gitea-ssd/srv
    $ sudo mount /dev/mapper/gitea--hdd-repos /mnt/gitea-hdd/repos
    ~~~

    Check with `df` that they've been mounted correctly, appearing at the command output's bottom:

    ~~~sh
    $ df -h
    Filesystem                    Size  Used Avail Use% Mounted on
    udev                          965M     0  965M   0% /dev
    tmpfs                         198M  1.7M  196M   1% /run
    /dev/mapper/k3snode--vg-root  9.1G  5.9G  2.7G  70% /
    tmpfs                         987M     0  987M   0% /dev/shm
    tmpfs                         5.0M     0  5.0M   0% /run/lock
    tmpfs                         987M     0  987M   0% /tmp
    tmpfs                         1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
    /dev/sda1                     730M  111M  567M  17% /boot
    tmpfs                         1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/9015de8e0ceb3f2424371d10c7baafb3eb061143e6612580e7bd53ea4d9ead9f/shm
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/ba0018bcdc75df3c859c80530f473bb8494f7a8de766037ec19b6797e58e48cc/shm
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/ebfe5b253ebe2dd2ed865da6fbfe19002525e5c9b9dec6e555d2fa77e8b0a2ad/shm
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/b8b4da1e0c809a005d38ed81d82edfbac8c298940bffc39e28be870d33837b62/shm
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/3a178e736492a65ea950a905564627cc1d967132fed572c3512bf7b5bc5ae44e/shm
    shm                            64M     0   64M   0% /run/k3s/containerd/io.containerd.grpc.v1.cri/sandboxes/308ad5897ddf18fc03e307d76449c2988c798d223d45de996510ab40caaf61fc/shm
    tmpfs                         184M  8.0K  184M   1% /run/user/1000
    /dev/mapper/gitea--ssd-cache  2.9G  788K  2.8G   1% /mnt/gitea-ssd/cache
    /dev/mapper/gitea--ssd-db     4.8G  1.3M  4.5G   1% /mnt/gitea-ssd/db
    /dev/mapper/gitea--ssd-srv    2.0G  560K  1.9G   1% /mnt/gitea-ssd/srv
    /dev/mapper/gitea--hdd-repos  9.8G  2.1M  9.3G   1% /mnt/gitea-hdd/repos
    ~~~

5. Make those mountings permanent, by adding them to the VM's  `/etc/fstab` file. First, backup the file:

    ~~~sh
    $ sudo cp /etc/fstab /etc/fstab.bkp
    ~~~

    Then **append** the following lines to the `fstab` file:

    ~~~sh
    # Gitea volumes
    /dev/mapper/gitea--ssd-cache /mnt/gitea-ssd/cache ext4 defaults,nofail 0 0
    /dev/mapper/gitea--ssd-db /mnt/gitea-ssd/db ext4 defaults,nofail 0 0
    /dev/mapper/gitea--ssd-srv /mnt/gitea-ssd/srv ext4 defaults,nofail 0 0
    /dev/mapper/gitea--hdd-repos /mnt/gitea-hdd/repos ext4 defaults,nofail 0 0
    ~~~

### Storage mount points for Gitea containers

With the LVs mounted, you can create within them the `k3smnt` folders that will act as mounting points for the Gitea containers' persistent volumes.

1. Use the following `mkdir` command to create a `k3smnt` folder within each Gitea storage volume.

    ~~~sh
    $ sudo mkdir /mnt/{gitea-ssd/cache,gitea-ssd/db,gitea-ssd/srv,gitea-hdd/repos}/k3smnt
    ~~~

2. Check with `tree` that the folders have been created where they should:

    ~~~sh
    $ tree -F /mnt
    /mnt/
    ├── gitea-hdd/
    │   └── repos/
    │       ├── k3smnt/
    │       └── lost+found/  [error opening dir]
    └── gitea-ssd/
        ├── cache/
        │   ├── k3smnt/
        │   └── lost+found/  [error opening dir]
        ├── db/
        │   ├── k3smnt/
        │   └── lost+found/  [error opening dir]
        └── srv/
            ├── k3smnt/
            └── lost+found/  [error opening dir]

    15 directories, 0 files
    ~~~

    Ignore the `lost+found` folders, they are created by the system automatically.

> [!WARNING]
> **The `k3smnt` folders exist within the already mounted LVM storage volumes!**\
> You cannot create those folders without mounting the light volumes first.

### About increasing the size of volumes

If, after a time using and filling up these volumes, you need to increase their size, take a look to the [appendix chapter **G907**](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md). It shows you how to extend a partition and the LVM filesystem within it, although in that case it is done on a LV volume that happens to be also the root filesystem of a VM.

## Relevant system paths

### Folders in K3s agent node's VM

- `/etc`
- `/mnt`
- `/mnt/gitea-hdd`
- `/mnt/gitea-hdd/repos/`
- `/mnt/gitea-hdd/repos/k3smnt`
- `/mnt/gitea-ssd`
- `/mnt/gitea-ssd/cache/`
- `/mnt/gitea-ssd/cache/k3smnt`
- `/mnt/gitea-ssd/db`
- `/mnt/gitea-ssd/db/k3smnt`
- `/mnt/gitea-ssd/srv/`
- `/mnt/gitea-ssd/srv/k3smnt`

### Files in K3s agent node's VM

- `/dev/mapper/gitea--hdd-repos`
- `/dev/mapper/gitea--ssd-cache`
- `/dev/mapper/gitea--ssd-db`
- `/dev/mapper/gitea--ssd-srv`
- `/dev/sdb`
- `/dev/sdb1`
- `/dev/sdc`
- `/dev/sdc1`
- `/etc/fstab`
- `/etc/fstab.bkp`

## Navigation

[<< Previous (**G033. Deploying services 02. Ghost Part 5**)](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Gitea Part 2**) >>](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Valkey%20cache%20server.md)
