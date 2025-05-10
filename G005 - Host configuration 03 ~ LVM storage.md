# G005 - Host configuration 03 ~ LVM storage

- [Your Proxmox VE server's storage needs to be reorganized](#your-proxmox-ve-servers-storage-needs-to-be-reorganized)
- [Initial filesystem configuration (**web console**)](#initial-filesystem-configuration-web-console)
- [Initial filesystem configuration (**shell as root**)](#initial-filesystem-configuration-shell-as-root)
- [Configuring the unused storage drives](#configuring-the-unused-storage-drives)
  - [Seeing the new storage volumes in Proxmox VE's web console](#seeing-the-new-storage-volumes-in-proxmox-ves-web-console)
- [LVM rearrangement in the main storage drive](#lvm-rearrangement-in-the-main-storage-drive)
  - [Removing the `data` LVM thin pool](#removing-the-data-lvm-thin-pool)
  - [Extending the `root` logical volume](#extending-the-root-logical-volume)
  - [Creating a new partition and a new VG in the unallocated space on the `sda` drive](#creating-a-new-partition-and-a-new-vg-in-the-unallocated-space-on-the-sda-drive)
- [References](#references)
  - [Logical Volume Management (LVM)](#logical-volume-management-lvm)
- [Navigation](#navigation)

## Your Proxmox VE server's storage needs to be reorganized

After installing Proxmox VE with (almost) default settings, the storage is still not ready since it needs some reorganization.

As a reference, I'll use in this guide my own server's storage setup.

> [!NOTE]
> **Remember that I'm using a VM-based system**\
> This VM is configured to be as close as possible to the reference hardware, something I already pointed out [in the **G001 chapter**](G001%20-%20Hardware%20setup.md).

- One internal, 1 TiB, SSD drive, linked to a SATA 2 port.
- One internal, 1 TiB, HDD drive, linked to a SATA 2 port .
- One external, 2 TiB, HDD drive, linked to a USB 3 port.

Also, keep in mind that:

- The Proxmox VE system is installed in the SSD drive, but only using 50 GiB of its storage space.
- The filesystem is `ext4`.

## Initial filesystem configuration (**web console**)

Log in the **web console** as `root`. In a recently installed Proxmox VE node, you'll see that, at the `Datacenter` level, the `Storage` already has an initial configuration.

![Datacenter storage's initial configuration](images/g005/datacenter_storage_initial_configuration.webp "Datacenter storage's initial configuration")

Meanwhile, at the `pve` **node** level you can see which storage drives you have available in your physical system. Remember, **one node represents one physical server**.

![pve node disks screen](images/g005/pve_node_disks_screen.webp "pve node disks screen")

Proxmox shows some technical details from each disk, and also about the partitions present on each of them. At this point, only the `/dev/sda` ssd drive has partitions, the ones corresponding to the Proxmox VE installation. Additionally, notice that Proxmox VE is unable to tell what type of storage device is the `/dev/sdb` one. This unit should appear typified as a hard disk or equivalent term, similarly as the `/dev/sda` drive is correctly detected as an SSD unit. Still, this is just a minor issue that shouldn't be any trouble at all.

On the other hand, be aware that Proxmox VE has installed itself in a LVM structure, but the web console won't show you much information about it.

Go to the `Disks > LVM` option at your **node** level.

![pve node LVM screen](images/g005/pve_node_disks_lvm_screen.webp "pve node LVM screen")

There's a volume group in your `sda` device which fills most of the space in the SSD drive. But this screen **does not show you the complete underlying LVM structure**.

In the `Disks > LVM-Thin` screen you can see a bit more information regarding the **LVM-Thin pools** enabled in the system.

![pve node LVM-Thin screen](images/g005/pve_node_disks_lvm-thin_screen.webp "pve node LVM-Thin screen")

The LVM thinpool created by the Proxmox VE installation it's called `data` and appears unused. In Proxmox VE, a LVM thinpool is were the disk images for the virtual machines and containers can be stored and grow dynamically.

Under the unfolded node in the `Datacenter` tree on the left, you can see three leafs. Two of those leafs are the storages shown at the `Datacenter` level.

Clicking on the `local` one will show you a screen like the following.

![pve node local storage screen](images/g005/pve_node_storage_local_initial_screen.webp "pve node local storage screen")

This page offers several tabs like `Summary`, which is the one shown above. The tabs shown will change depending on the type of storage, and they also depend on what Proxmox VE content types have been enabled on the storage. Notice how the `Usage` of `Storage 'local' on node 'pve'` has a capacity of 19.37 GiB. This is the main system partition, but it's just a portion of the `pve` LVM volume group's total capacity.

The rest of the space is assigned to the LVM-Thin pool, which can be seen by browsing into the `local-lvm` leaf.

![pve node local-lvm storage screen](images/g005/pve_node_storage_local-lvm_initial_screen.webp "pve node local-lvm storage screen")

The `Storage 'local-lvm' on node 'pve'` shows in `Usage` that this thinpool has a capacity of 11.27 GiB, which is the rest of storage space available in the `pve` volume group (50 GiB), and is still empty.

Finally, notice that the web console doesn't show the 12 GiB swap volume also existing within the LVM structure.

## Initial filesystem configuration (**shell as root**)

To have a more complete idea of how the storage is organized in your recently installed Proxmox VE server, get into the shell as `root` (either remotely through a client like **PuTTY** or by using one of the shells provided by the Proxmox web console).

The first thing to do is to check the filesystem structure in your connected storage drives with `fdisk`.

~~~sh
$ fdisk -l
Disk /dev/sda: 1 TiB, 1099511627776 bytes, 2147483648 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: B22CE842-A5E2-4051-B22A-D0F1A1028F36

Device       Start       End   Sectors  Size Type
/dev/sda1       34      2047      2014 1007K BIOS boot
/dev/sda2     2048   2099199   2097152    1G EFI System
/dev/sda3  2099200 104857600 102758401   49G Linux LVM


Disk /dev/sdb: 1 TiB, 1099511627776 bytes, 2147483648 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/pve-swap: 12 GiB, 12884901888 bytes, 25165824 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/pve-root: 18.5 GiB, 19860029440 bytes, 38789120 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 2 TiB, 2199022206976 bytes, 4294965248 sectors
Disk model: HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
~~~

The `sda` device is the 1TiB SSD drive in which Proxmox VE is installed. In it's block, below its list of technical capabilities, you can also see the list of the **real partitions** (the `/dev/sda#` lines under **Device**) created in it by the Proxmox VE installation. The `sda1` and `sda2` are partitions used essentially for booting the system up, and the `sda3` is the one that contains the whole `pve` LVM volume group for Proxmox VE.

Below the `sda` information block, you can see the details of the `sdb` and `sdc` storage devices. In this case, both of them are not partitioned at all and, therefore, completely empty. That's why they don't have a listing of devices like the `sda` unit.

And let's not forget the two remaining devices seen by `fdisk`, one per each LVM **logical volumes** (kind of virtual partitions) present in the system. From the point of view of the `fdisk` command, they are just like any other storage devices, although the command gives a bit less information about them. Still, you can notice how these volumes are mounted on a `/dev/mapper` route instead of hanging directly from `/dev`, this is something related to their _logical_ nature. Also, notice the following regarding the LVM volumes shown in the previous listing:

- The one called `pve-swap` is the swapping partition, as it names implies.
- The one called `pve-root` is the one in which the whole Debian system is installed, the so called `/` filesystem.
- There's no mention at all of the **LVM-Thin pool** called `data` you saw in your PVE web console.

Thanks to the `fdisk` command, now you really have a good picture of what's going on inside your storage drives, but it's still a bit lacking. There are a couple commands more that will help you visualize better the innards of your server's filesystem.

The first one is `lsblk`:

~~~sh
$ lsblk
NAME               MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0    1T  0 disk
├─sda1               8:1    0 1007K  0 part
├─sda2               8:2    0    1G  0 part
└─sda3               8:3    0   49G  0 part
  ├─pve-swap       252:0    0   12G  0 lvm  [SWAP]
  ├─pve-root       252:1    0 18.5G  0 lvm  /
  ├─pve-data_tmeta 252:2    0    1G  0 lvm
  │ └─pve-data     252:4    0 10.5G  0 lvm
  └─pve-data_tdata 252:3    0 10.5G  0 lvm
    └─pve-data     252:4    0 10.5G  0 lvm
sdb                  8:16   0    1T  0 disk
sdc                  8:32   0    2T  0 disk
sr0                 11:0    1 1024M  0 rom
~~~

This command not only sees all the physical storage drives available (`TYPE disk`) in the system and their partitions (`TYPE part` that, at this point, are only inside the `sda` device), it also gives information about the LVM filesystem itself (`TYPE lvm`).

It correctly shows the `pve-swap`, the `pve-root` and their mount points, but also lists the two elements that compose an LVM-Thin pool: its metadata (`pve-data_tmeta`) and the reserved space itself (`pve-data`). Also, the default branch format is really helpful to see where is what, although the `lsblk` command supports a few other output formats as well.

> [!NOTE]
> The `sr0` represents the virtual CD-ROM unit my VM has, connected as a SCSI drive.

With the two previous commands you get the Linux's point of view, but you also need to know how the LVM system sees itself. For this, LVM has its own set of commands, and one of them is `vgs`.

~~~sh
$ vgs
  VG  #PV #LV #SN Attr   VSize   VFree
  pve   1   3   0 wz--n- <49.00g 6.00g
~~~

This commands informs about the LVM _volume groups_ present on the system. In the snippet there's only one called `pve` (also prefix for the light volumes names as in `pve-root`).

Another interesting command is `lvs`:

~~~sh
$ lvs
  LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  data pve twi-a-tz-- <10.50g             0.00   1.58
  root pve -wi-ao---- <18.50g
  swap pve -wi-ao----  12.00g
~~~

In the output above, the command lists the logical volumes and also the thin pool. Notice how the names (`LV` column) have changed: instead of being listed as `pve-something`, the list shows them indicating their volume group (`pve`) in a different column (`VG`). Also, notice how the real available space in the thin `data` pool is shown properly (10.50 GiB, under the `LSize` column).

The last command I'll show you here is `vgdisplay`.

~~~sh
$ vgdisplay
  --- Volume group ---
  VG Name               pve
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  7
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                3
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <49.00 GiB
  PE Size               4.00 MiB
  Total PE              12543
  Alloc PE / Size       11006 / 42.99 GiB
  Free  PE / Size       1537 / 6.00 GiB
  VG UUID               esWe2j-K4dG-s8Wr-le5V-eQYH-B7cM-oh7rHx
~~~

This command outputs details from the volume groups present in the system. In this case, it only shows information from the sole volume group present now, the `pve` group.

See the different parameters shown in the output, and notice how the commands gives you the count of logical (`LV`) and **physical** (`PV`) volumes present in the group. Bear in mind that a LVM physical volume can be either a **whole** storage drive or just a **real** partition.

Now that you have the whole picture of how the storage setup is organized in a newly installed Proxmox VE server, let's rearrange it to a more convenient one.

## Configuring the unused storage drives

Let's begin by making the two empty HDDs' storage available for the LVM system.

1. First, make a partition on each empty storage device that takes the **whole space** available. You'll do this with `sgdisk`.

    ~~~sh
    $ sgdisk -N 1 /dev/sdb
    Creating new GPT entries in memory.
    The operation has completed successfully.
    $ sgdisk -N 1 /dev/sdc
    Creating new GPT entries in memory.
    The operation has completed successfully.
    ~~~

    The `sgdisk` command may return lines like the following.

    ~~~sh
    Warning: Partition table header claims that the size of partition table
    entries is 0 bytes, but this program  supports only 128-byte entries.
    Adjusting accordingly, but partition table may be garbage.
    Creating new GPT entries in memory.
    The operation has completed successfully.
    ~~~

    Usually, you should expect seeing only the last line but, depending on what you has been done to the storage drives previously, you might also see the partition table warning or anything else detected by `sgdisk`.

2. Then, you can check the new partitions with `fdisk -l`.

    ~~~sh
    $ fdisk -l /dev/sdb /dev/sdc
    Disk /dev/sdb: 1 TiB, 1099511627776 bytes, 2147483648 sectors
    Disk model: VBOX HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: 0413FEF2-23DD-4E8B-BE2A-DD49DFBDD6FF

    Device     Start        End    Sectors  Size Type
    /dev/sdb1   2048 2147483614 2147481567 1024G Linux filesystem


    Disk /dev/sdc: 2 TiB, 2199022206976 bytes, 4294965248 sectors
    Disk model: HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: 5D371D37-8A06-46A2-8555-768E42C6D63C

    Device     Start        End    Sectors Size Type
    /dev/sdc1   2048 4294965214 4294963167   2T Linux filesystem
    ~~~

    Remember how the `sdb` and `sdc` devices didn't had a listing under their technical details? Now you see that they have one partition each.

3. Next, lets create a _physical volume_ (or PV) with each of those new partitions. For this operation, you'll need to use the `pvcreate` command.

    > [!WARNING]
    > **The `pvcreate` command will fail if it finds references to a previous LVM structure in the storage drive its trying to turn into a physical volume**\
    > If `pvcreate` returns a message like `Can't open /dev/sdb1 exclusively.  Mounted filesystem?`, you'll need to remove all the LVM structure that might be lingering in your storage device.
    >
    > [Follow this guide](https://www.thegeekdiary.com/lvm-error-cant-open-devsdx-exclusively-mounted-filesystem/) to know more about this issue.

    ~~~sh
    $ pvcreate --metadatasize 1g -y -ff /dev/sdb1
      Physical volume "/dev/sdb1" successfully created.
    $ pvcreate --metadatasize 2g -y -ff /dev/sdc1
      Physical volume "/dev/sdc1" successfully created.
    ~~~

    > [!NOTE]
    > **Don't worry about any `Wiping` lines returned by `pvcreate`**\
    > The `Wiping` lines mean that the command is removing any references, or signatures, of previous filesystems that were used in the storage devices. These lines may look like this:
    >
    > ~~~sh
    > Wiping ntfs signature on /dev/sdb1.
    > Wiping zfs_member signature on /dev/sdc1.
    > ~~~

    See that, in the commands above, and following the rule of thumb of 1 MiB per 1 GiB, I've assigned 1 GiB on the `sdb1` PV and 2 GiB on the `sdc1` PV as the size for their LVM metadata space. If more is required in the future, this can be reconfigured later.

4. Check your new physical volumes executing `pvs`.

    ~~~sh
    $ pvs
      PV         VG  Fmt  Attr PSize     PFree
      /dev/sda3  pve lvm2 a--    <49.00g     6.00g
      /dev/sdb1      lvm2 ---  <1024.00g <1024.00g
      /dev/sdc1      lvm2 ---     <2.00t    <2.00t
    ~~~

    See how the new physical volumes, `sdb1` and `sdc1`, appear under the already present one, `sda3`.

5. The next step is to create a _volume group_ (or VG) for each one of the new PVs. Do this with `vgcreate`.

    ~~~sh
    $ vgcreate hddint /dev/sdb1
      Volume group "hddint" successfully created
    $ vgcreate hddusb /dev/sdc1
      Volume group "hddusb" successfully created
    ~~~

6. To check the new VGs you can use `vgdisplay`.

    ~~~sh
    $ vgdisplay
      --- Volume group ---
      VG Name               hddusb
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  1
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                0
      Open LV               0
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               <2.00 TiB
      PE Size               4.00 MiB
      Total PE              523775
      Alloc PE / Size       0 / 0
      Free  PE / Size       523775 / <2.00 TiB
      VG UUID               XxnDrK-wD8w-80vX-40fq-GcHh-BHq0-nFwI01

      --- Volume group ---
      VG Name               hddint
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  1
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                0
      Open LV               0
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               <1023.00 GiB
      PE Size               4.00 MiB
      Total PE              261887
      Alloc PE / Size       0 / 0
      Free  PE / Size       261887 / <1023.00 GiB
      VG UUID               W2kwlV-iV1c-RgXk-abzp-xpy3-BPKk-35vs7U

      --- Volume group ---
      VG Name               pve
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  7
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                3
      Open LV               2
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               <49.00 GiB
      PE Size               4.00 MiB
      Total PE              12543
      Alloc PE / Size       11006 / 42.99 GiB
      Free  PE / Size       1537 / 6.00 GiB
      VG UUID               esWe2j-K4dG-s8Wr-le5V-eQYH-B7cM-oh7rHx
    ~~~

    A shorter way of checking the volume groups is with the command `vgs`.

    ~~~sh
    $ vgs
      VG     #PV #LV #SN Attr   VSize     VFree
      hddint   1   0   0 wz--n- <1023.00g <1023.00g
      hddusb   1   0   0 wz--n-    <2.00t    <2.00t
      pve      1   3   0 wz--n-   <49.00g     6.00g
    ~~~

### Seeing the new storage volumes in Proxmox VE's web console

If you're wondering if any of this changes appear in the Proxmox web console, just open it and browse to the `pve` node level. There, open the `Disks` screen:

![pve node devices usage updated to LVM](images/g005/pve_node_disks_devices_lvm_updated_screen.webp "pve node devices usage updated to LVM")

You can see how the `sdb` and `sdc` devices now show their new LVM partitions. Meanwhile, in the `Disks > LVM` section:

![pve node LVM screen updated with new volume groups](images/g005/pve_node_disks_lvm_screen_new_vgs.webp "pve node LVM screen updated with new volume groups")

The new volume groups `hddint` and `hddusb` appear above the system's `pve` one (by default, they appear alphabetically ordered by the Volume Group _Name_ column).

At this point, you have an initial arrangement for your unused storage devices. It's just a basic configuration over which _logical volumes_ and _thin pools_ can be created as needed.

## LVM rearrangement in the main storage drive

The main storage drive, the SSD unit, has an LVM arrangement that is not optimal for the small server you want to build. Let's create a new differentiated storage unit in the SSD drive, one that is not the `pve` volume group used by the Proxmox VE system itself. This way, you'll keep thing separated and reduce the chance of messing anything directly related to your Proxmox VE installation.

### Removing the `data` LVM thin pool

The installation process of Proxmox VE created a LVM-thin pool called `data`, which is part of the `pve` volume group. You need to reclaim this space, so let's remove this `data`:

1. On the Proxmox VE web console, go to the `Datacenter > Storage` option and take our the `local-lvm` volume from the list by selecting it and pressing on the `Remove` button.

    ![Selected local-lvm thin pool for removal](images/g005/datacenter_storage_local_lvm_thin_remove_button.webp "Selected local-lvm thin pool for removal")

    A dialog will ask for your confirmation.

    ![Removal confirmation of the local-lvm thin pool](images/g005/datacenter_storage_local_lvm_thin_remove_confirmation.webp "Removal confirmation of the local-lvm thin pool")

    The volume will be immediately taken out from the storage list.

    ![local-lvm thin pool removed](images/g005/datacenter_storage_local_lvm_thin_removed.webp "local-lvm thin pool removed")

    This hasn't erased the LVM thinpool volume itself, only made it unavailable for Proxmox VE.

2. To remove the `data` thinpool volume, get into the shell as `root` and execute the following.

    ~~~sh
    $ lvs
      LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      data pve twi-a-tz-- <10.50g             0.00   1.58
      root pve -wi-ao---- <18.50g
      swap pve -wi-ao----  12.00g
    ~~~

    The `data` volume is under the `pve` volume group (`VG`). Knowing this, execute `lvremove` to delete this logical volume (`LV`).

    ~~~sh
    $ lvremove pve/data
    ~~~

    Notice how you have to specify the VG before the name of the LV you want to remove. The command will ask you to confirm the removal. Answer with `y`:

    ~~~sh
    Do you really want to remove active logical volume pve/data? [y/n]: y
      Logical volume "data" successfully removed.
    ~~~

3. To verify that the `data` volume doesn't exist anymore, you can check it with the `lvs` command.

    ~~~sh
    $ lvs
      LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      root pve -wi-ao---- <18.50g
      swap pve -wi-ao----  12.00g
    ~~~

    Only two logical volumes are listed now, and with the `pvs` command you can see how much space you have available now in the physical volume where the `data` thin pool was present. In this case it was in the `sda3` unit.

    ~~~sh
    $ pvs
      PV         VG     Fmt  Attr PSize     PFree
      /dev/sda3  pve    lvm2 a--    <49.00g    18.50g
      /dev/sdb1  hddint lvm2 a--  <1023.00g <1023.00g
      /dev/sdc1  hddusb lvm2 a--     <2.00t    <2.00t
    ~~~

    Also, if you go back to the Proxmox VE web console, you'll see there how the thin pool is not present anymore as a leaf under your `pve` node nor in the `Disks > LVM-Thin` screen.

    ![PVE node thinpool list empty](images/g005/pve_node_disks_lvm-thin_screen_empty.webp "PVE node thinpool list empty")

### Extending the `root` logical volume

Now that you have a lot of free space in the /dev/sda3, let's give more room to your system's `root` volume.

1. First locate, with `lvs`, where in your system's LVM structure the `root` LV is.

    ~~~sh
    $ lvs
      LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      root pve -wi-ao---- <18.50g
      swap pve -wi-ao----  12.00g
    ~~~

    It's in the `pve` VG.

2. Now you need to know exactly how much space you have available in the `pve` VG. Use `vgdisplay` to see all the details of this group.

    ~~~sh
    $ vgdisplay pve
      --- Volume group ---
      VG Name               pve
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  8
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                2
      Open LV               2
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               <49.00 GiB
      PE Size               4.00 MiB
      Total PE              12543
      Alloc PE / Size       7807 / <30.50 GiB
      Free  PE / Size       4736 / 18.50 GiB
      VG UUID               esWe2j-K4dG-s8Wr-le5V-eQYH-B7cM-oh7rHx
    ~~~

    The line you must pay attention to is the `Free PE / Size`. **PE** stands for _Physical Extend_ size, and is the number of extends you have available in the volume group. The previous `Alloc PE` line gives you the _allocated_ extends or storage already in use.

3. You need to use the `lvextend` command to expand the `root` LV in the free space you have in the `pve` group.

    ~~~sh
    $ lvextend -l +4736 -r pve/root
      Size of logical volume pve/root changed from <18.50 GiB (4735 extents) to <37.00 GiB (9471 extents).
      Logical volume pve/root successfully resized.
    resize2fs 1.47.0 (5-Feb-2023)
    Filesystem at /dev/mapper/pve-root is mounted on /; on-line resizing required
    old_desc_blocks = 3, new_desc_blocks = 5
    The filesystem on /dev/mapper/pve-root is now 9698304 (4k) blocks long.
    ~~~

    Two options are specified to the `lvextend` command.

    - `-l +4736` : specifies the number of extents (`+4736`) you want to give to the logical volume.

    - `-r` : tells the `lvextend` command to call the `resizefs` procedure, after extending the volume, to expand the filesystem within the volume over the newly assigned storage space.

4. As a final verification, check with the commands `lvs`, `vgs`, `pvs` and `df` that the root partition has taken up the entire free space available in the `pve` volume group.

    ~~~sh
    $ lvs
      LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      root pve -wi-ao---- <37.00g
      swap pve -wi-ao----  12.00g
    $ vgs
      VG     #PV #LV #SN Attr   VSize    VFree
      hddint   1   0   0 wz--n- <1023.00g <1023.00g
      hddusb   1   0   0 wz--n-    <2.00t    <2.00t
      pve      1   2   0 wz--n-   <49.00g        0
    $ pvs
      PV         VG     Fmt  Attr PSize    PFree
      /dev/sda3  pve    lvm2 a--    <49.00g        0
      /dev/sdb1  hddint lvm2 a--  <1023.00g <1023.00g
      /dev/sdc1  hddusb lvm2 a--     <2.00t    <2.00t
    $ df -h
    Filesystem            Size  Used Avail Use% Mounted on
    udev                  3.9G     0  3.9G   0% /dev
    tmpfs                 795M  1.1M  794M   1% /run
    /dev/mapper/pve-root   37G  3.8G   31G  11% /
    tmpfs                 3.9G   46M  3.9G   2% /dev/shm
    tmpfs                 5.0M     0  5.0M   0% /run/lock
    /dev/fuse             128M   16K  128M   1% /etc/pve
    tmpfs                 795M     0  795M   0% /run/user/0
    ~~~

    You'll see that the `root` volume has grown from 18.50 GiB to 37.00 GiB, the `pve` VG doesn't have any empty space (`VFree`) available, the `/dev/sda3` physical volume also doesn't have any space (`PFree`) free either, and that the `/dev/mapper/pve-root` `Size` corresponds to what the `root` LV has free.

### Creating a new partition and a new VG in the unallocated space on the `sda` drive

What remains to do is to make usable all the still unallocated space within the `sda` drive. So, let's make a new partition in it.

1. In a `root` shell, use the following `fdisk` command.

    ~~~sh
    $ fdisk /dev/sda

    Welcome to fdisk (util-linux 2.38.1).
    Changes will remain in memory only, until you decide to write them.
    Be careful before using the write command.

    This disk is currently in use - repartitioning is probably a bad idea.
    It's recommended to umount all file systems, and swapoff all swap
    partitions on this disk.


    Command (m for help):
    ~~~

    > [!IMPORTANT]
    > **The `fdisk` command warns you about messing with the `/dev/sda` unit while in use**\
    > In this particular scenario, this will not be an issue since you are going to create a new partition in the free space available.
    >
    > Still, modifying the partition table of an active storage unit is not recommended. **Never do this in a real production environment!**

2. You're in the `fdisk` partition editor now. Be careful what you do here or you might mess your drive up! Input the command `F` to check the empty space available in the `sda` drive. You should see an output like the following.

    ~~~sh
    Command (m for help): F
    Unpartitioned space /dev/sda: 974 GiB, 1045823471104 bytes, 2042623967 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes

        Start        End    Sectors  Size
    104859648 2147483614 2042623967  974G
    ~~~

3. With the previous information you're sure now of where the free space begins and ends, and also its size (974 GiB in my case). Now you can create a new partition, type `n` as the command.

    ~~~sh
    Command (m for help): n
    Partition number (4-128, default 4):
    ~~~

    The first thing `fdisk` asks you is the number you want for the new partition. Since there are already three other partitions in `sda`, it has to be any number between 4 and 128 (both included). The default value (4) is fine, so **just press enter** on this question.

4. The next question `fdisk` asks you is about which `sector` the new `sda4` partition should **start** in your `sda` drive.

    ~~~sh
    First sector (104857601-2147483614, default 104859648):
    ~~~

    Notice how the first sector chosen by default is the same one you saw before with the `F` command as the `Start` of the free space. Again, the default value (104859648) is good, since you want the `sda4` partition to start at the very beginning of the available unallocated space. Therefore, **press enter** to accept the default value.

5. The last question is about on which sector the new `sda4` partition has to **end**.

    ~~~sh
    Last sector, +/-sectors or +/-size{K,M,G,T,P} (104859648-2147483614, default 2147481599):
    ~~~

    Curiously enough, it offers you as a possibility the sector in which your partition is starting. Notice how the default value proposed is the free space's `End`. This value is right what you want so the new `sda4` partition takes all the available free space. **Just press enter** to accept the default value.

6. The `fdisk` program will warn you about the partition's creation and return you to its command line.

    ~~~sh
    Created a new partition 4 of type 'Linux filesystem' and of size 974 GiB.

    Command (m for help):
    ~~~

    > [!WARNING]
    > **Although `fdisk` says it has done it, be aware that, in fact, the new partition table is only in memory**\
    > The change still has to be saved in the real `sda`'s partition table.

7. To verify that the partition has been registered, use the command `p` to see the current partition table in `fdisk`'s memory.

    ~~~sh
    Command (m for help): p
    Disk /dev/sda: 1 TiB, 1099511627776 bytes, 2147483648 sectors
    Disk model: VBOX HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: B22CE842-A5E2-4051-B22A-D0F1A1028F36

    Device         Start        End    Sectors  Size Type
    /dev/sda1         34       2047       2014 1007K BIOS boot
    /dev/sda2       2048    2099199    2097152    1G EFI System
    /dev/sda3    2099200  104857600  102758401   49G Linux LVM
    /dev/sda4  104859648 2147481599 2042621952  974G Linux filesystem
    ~~~

    See how the new `sda4` partition is named correlatively to the other three already existing ones, and takes up the previously unassigned free space (974 GiB). Also notice how `fdisk` indicates that the partition is of the `Type Linux filesystem`, not `Linux LVM`.

8. To turn the partition into a Linux LVM type, use the `t` command.

    ~~~sh
    Command (m for help): t
    Partition number (1-4, default 4):
    ~~~

    Notice how the command asks you first which partition you want to change, and it also offers by default the newest one (number `4`). In this case, the default value 4 is the correct one, so press enter here.

9. The next question is about what type you want to change the partition into. If you don't know the numeric code of the type you want, type `L` on this question and you'll get a long list with all the types available. To exit the types listing press `q` and you'll return to the question.

    ~~~sh
    Partition type (type L to list all types): L
      1 EFI System                     C12A7328-F81F-11D2-BA4B-00A0C93EC93B
      2 MBR partition scheme           024DEE41-33E7-11D3-9D69-0008C781F39F
      3 Intel Fast Flash               D3BFE2DE-3DAF-11DF-BA40-E3A556D89593
      4 BIOS boot                      21686148-6449-6E6F-744E-656564454649
      5 Sony boot partition            F4019732-066E-4E12-8273-346C5641494F
      6 Lenovo boot partition          BFBFAFE7-A34F-448A-9A5B-6213EB736C22
      7 PowerPC PReP boot              9E1A2D38-C612-4316-AA26-8B49521E5A8B
      8 ONIE boot                      7412F7D5-A156-4B13-81DC-867174929325
      9 ONIE config                    D4E6E2CD-4469-46F3-B5CB-1BFF57AFC149
    10 Microsoft reserved             E3C9E316-0B5C-4DB8-817D-F92DF00215AE
    11 Microsoft basic data           EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
    12 Microsoft LDM metadata         5808C8AA-7E8F-42E0-85D2-E1E90434CFB3
    13 Microsoft LDM data             AF9B60A0-1431-4F62-BC68-3311714A69AD
    14 Windows recovery environment   DE94BBA4-06D1-4D40-A16A-BFD50179D6AC
    15 IBM General Parallel Fs        37AFFC90-EF7D-4E96-91C3-2D7AE055B174
    16 Microsoft Storage Spaces       E75CAF8F-F680-4CEE-AFA3-B001E56EFC2D
    17 HP-UX data                     75894C1E-3AEB-11D3-B7C1-7B03A0000000
    18 HP-UX service                  E2A1E728-32E3-11D6-A682-7B03A0000000
    19 Linux swap                     0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
    20 Linux filesystem               0FC63DAF-8483-4772-8E79-3D69D8477DE4
    21 Linux server data              3B8F8425-20E0-4F3B-907F-1A25A76F98E8
    22 Linux root (x86)               44479540-F297-41B2-9AF7-D131D5F0458A
    23 Linux root (x86-64)            4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709
    24 Linux root (Alpha)             6523F8AE-3EB1-4E2A-A05A-18B695AE656F
    25 Linux root (ARC)               D27F46ED-2919-4CB8-BD25-9531F3C16534
    26 Linux root (ARM)               69DAD710-2CE4-4E3C-B16C-21A1D49ABED3
    27 Linux root (ARM-64)            B921B045-1DF0-41C3-AF44-4C6F280D3FAE
    28 Linux root (IA-64)             993D8D3D-F80E-4225-855A-9DAF8ED7EA97
    29 Linux root (LoongArch-64)      77055800-792C-4F94-B39A-98C91B762BB6
    30 Linux root (MIPS-32 LE)        37C58C8A-D913-4156-A25F-48B1B64E07F0
    31 Linux root (MIPS-64 LE)        700BDA43-7A34-4507-B179-EEB93D7A7CA3
    32 Linux root (PPC)               1DE3F1EF-FA98-47B5-8DCD-4A860A654D78
    33 Linux root (PPC64)             912ADE1D-A839-4913-8964-A10EEE08FBD2
    34 Linux root (PPC64LE)           C31C45E6-3F39-412E-80FB-4809C4980599
    35 Linux root (RISC-V-32)         60D5A7FE-8E7D-435C-B714-3DD8162144E1
    36 Linux root (RISC-V-64)         72EC70A6-CF74-40E6-BD49-4BDA08E8F224
    37 Linux root (S390)              08A7ACEA-624C-4A20-91E8-6E0FA67D23F9
    38 Linux root (S390X)             5EEAD9A9-FE09-4A1E-A1D7-520D00531306
    39 Linux root (TILE-Gx)           C50CDD70-3862-4CC3-90E1-809A8C93EE2C
    40 Linux reserved                 8DA63339-0007-60C0-C436-083AC8230908
    41 Linux home                     933AC7E1-2EB4-4F13-B844-0E14E2AEF915
    42 Linux RAID                     A19D880F-05FC-4D3B-A006-743F0F84911E
    43 Linux LVM                      E6D6D379-F507-44C2-A23C-238F2A3DF928
    ...
    ~~~

    When you've have located the type you want, in this case `Linux LVM`, return to the question by pressing `q` and type the type's index number. For the `Linux LVM` is `43`.

    ~~~sh
    Partition type or alias (type L to list all): 43
    ~~~

    > [!WARNING]
    > **The number identifying the type can change between `fdisk` versions!**\
    > Always check which number corresponds to the type you want to use.

10. After indicating the type and pressing enter, `fdisk` will indicate you if the change has been done properly and will exit the command.

    ~~~sh
    Changed type of partition 'Linux filesystem' to 'Linux LVM'.

    Command (m for help):
    ~~~

11. To verify that `fdisk` has applied the type change, check the partition table again with the `p` command.

    ~~~sh
    Command (m for help): p
    Disk /dev/sda: 1 TiB, 1099511627776 bytes, 2147483648 sectors
    Disk model: VBOX HARDDISK
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: B22CE842-A5E2-4051-B22A-D0F1A1028F36

    Device         Start        End    Sectors  Size Type
    /dev/sda1         34       2047       2014 1007K BIOS boot
    /dev/sda2       2048    2099199    2097152    1G EFI System
    /dev/sda3    2099200  104857600  102758401   49G Linux LVM
    /dev/sda4  104859648 2147481599 2042621952  974G Linux LVM
    ~~~

12. Now that you have the new `sda4` partition ready, exit the `fdisk` program with the `w` command. **This will write the changes to the `sda` drive's partition table**.

    ~~~sh
    Command (m for help): w
    The partition table has been altered.
    Syncing disks.
    ~~~

    See how `fdisk` gives you some final output about the update before returning you to the shell.

13. With the `lsblk` command you can see that the `sda4` now appears as another branch of the `sda` tree, right below the `sda3`'s structure.

    ~~~sh
    $ lsblk
    sda            8:0    0    1T  0 disk
    ├─sda1         8:1    0 1007K  0 part
    ├─sda2         8:2    0    1G  0 part
    ├─sda3         8:3    0   49G  0 part
    │ ├─pve-swap 252:0    0   12G  0 lvm  [SWAP]
    │ └─pve-root 252:1    0   37G  0 lvm  /
    └─sda4         8:4    0  974G  0 part
    sdb            8:16   0    1T  0 disk
    └─sdb1         8:17   0 1024G  0 part
    sdc            8:32   0    2T  0 disk
    └─sdc1         8:33   0    2T  0 part
    sr0           11:0    1 1024M  0 rom
    ~~~

    Notice how the `sda4` TYPE is simply indicated as `part`.

14. Now that the `sda4` partition is ready, let's create a new **LVM physical volume** with it. Use the `pvcreate` command.

    ~~~sh
    $ pvcreate /dev/sda4
      Physical volume "/dev/sda4" successfully created.
    ~~~

15. To verify that `sda4` is now also a PV, you can use the `lvmdiskscan` command.

    ~~~sh
    $ lvmdiskscan
      /dev/sda2 [       1.00 GiB]
      /dev/sda3 [     <49.00 GiB] LVM physical volume
      /dev/sda4 [    <974.00 GiB] LVM physical volume
      /dev/sdb1 [   <1024.00 GiB] LVM physical volume
      /dev/sdc1 [      <2.00 TiB] LVM physical volume
      0 disks
      1 partition
      0 LVM physical volume whole disks
      4 LVM physical volumes
    ~~~

    Also, you can execute the `pvs` command to see if the `sda4` PV is there (which should).

    ~~~sh
    $ pvs
      PV         VG     Fmt  Attr PSize    PFree
      /dev/sda3  pve    lvm2 a--    <49.00g        0
      /dev/sda4         lvm2 ---   <974.00g  <974.00g
      /dev/sdb1  hddint lvm2 a--  <1023.00g <1023.00g
      /dev/sdc1  hddusb lvm2 a--     <2.00t    <2.00t
    ~~~

16. What's left to do is to create a **volume group** over the `sda4` PV. For this, execute a `vgcreate` command.

    ~~~sh
    $ vgcreate ssdint /dev/sda4
      Volume group "ssdint" successfully created
    ~~~

17. Finally, check with the `vgs` command if this new `ssdint` VG has been really created.

    ~~~sh
    $ vgs
      VG     #PV #LV #SN Attr   VSize    VFree
      hddint   1   0   0 wz--n- <1023.00g <1023.00g
      hddusb   1   0   0 wz--n-    <2.00t    <2.00t
      pve      1   2   0 wz--n-   <49.00g        0
      ssdint   1   0   0 wz--n-  <974.00g  <974.00g
    ~~~

With all these steps you've got an independent space in your SSD storage unit, meant to separate the storage used for virtual machines and containers, services and other non-Proxmox VE system related files (like ISO images or container templates) from what is the Proxmox VE system itself.

## References

### Logical Volume Management (LVM)

- [Logical Volume Management Explained on Linux](https://devconnected.com/logical-volume-management-explained-on-linux/)
- [Understanding LVM In Linux (Create Logical Volume) RHEL/CentOS 7&8](https://tekneed.com/understanding-lvm-with-examples-advantages-of-lvm/)
- [RED HAT ENTERPRISE LINUX **8** - CONFIGURING AND MANAGING LOGICAL VOLUMES](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/index)
- [How to Create Disk Storage with Logical Volume Management (LVM) in Linux – PART 1](https://www.tecmint.com/create-lvm-storage-in-linux/)
- [How to Extend/Reduce LVM’s (Logical Volume Management) in Linux – Part II](https://www.tecmint.com/extend-and-reduce-lvms-in-linux/)
- [How to Take ‘Snapshot of Logical Volume and Restore’ in LVM – Part III](https://www.tecmint.com/take-snapshot-of-logical-volume-and-restore-in-lvm/)
- [Setup Thin Provisioning Volumes in Logical Volume Management (LVM) – Part IV](https://www.tecmint.com/setup-thin-provisioning-volumes-in-lvm/)
- [Logical Volume Management in Linux](https://www.techtutsonline.com/logical-volume-management-in-linux/)

## Navigation

[<< Previous (**G004. Host configuration 02**)](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G006. Host configuration 04**) >>](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md)
