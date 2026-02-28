# G037 - Backups 01 ~ Considerations

- [Protect your homelab from data losses with backups](#protect-your-homelab-from-data-losses-with-backups)
- [What to backup. Identifying your data concerns](#what-to-backup-identifying-your-data-concerns)
- [How to backup. Backup tools](#how-to-backup-backup-tools)
- [Where to store the backups. Backup storage](#where-to-store-the-backups-backup-storage)
- [When to do the backups. Backup scheduling](#when-to-do-the-backups-backup-scheduling)
- [References](#references)
- [Navigation](#navigation)

## Protect your homelab from data losses with backups

With your Kubernetes cluster setup up and running, you must start thinking about how to protect the data it produces or stores. The main method for achieving this protection is always with backups. Read this and upcoming chapters to learn about backups suitable for the low-cost small homelab setup used in this guide.

## What to backup. Identifying your data concerns

To setup your backups properly, first you must be aware of the different data concerns you have in your system. In the homelab system configured in this guide series, you can single out the following areas of concern:

- **Host platform**\
  This encompasses your entire host system, which runs the Proxmox VE server. The relevant data here is the whole Proxmox VE setup itself, including the underlying Debian operative system, all related configuration and other files like logs.

- **Virtual machines**\
  The virtual machines you have running within Proxmox VE, and also the templates that were used to create them.

- **Kubernetes cluster**\
  This concern is about the Kubernetes cluster setup and all the applications deployed in it.

- **Application data**\
  Refers to configuration applied and data generated within each application.

- **User data**\
  This is all the data generated or just stored by users on each application running in your system.

- **Backups**\
  The backups themselves are also sensitive data that has to be protected.

As you can see, each layer is essentially a different perspective with its own concerns about your system.

## How to backup. Backup tools

Knowing the data layers your system has is one step, the following one is to identify which tools can fit your backup needs. Here you have a correlation of each data concern with the concrete tool that can be used to do the corresponding backup.

- **Host platform**\
  [Clonezilla](https://clonezilla.org/), for making images of the entire storage drives used to run the whole the Proxmox VE system.

- **Virtual machines**\
  Proxmox VE comes with its own integrated backup system for the virtual machines and containers you run in it.

- **Kubernetes cluster**\
  [Velero](https://velero.io/) is a popular tool for backing up and restore Kubernetes cluster resources and persistent volumes. The problem with it is that it is not really designed to work with the Local Path Provisioner for storage, at least not directly. Making Velero work with file-system-based backups involves other tools in a complex setup that could be a bit too much for the small homelab built with this guide. In conclusion, just know it is possible and there are tools to do so, although essentially centered on cloud storage technology.

- **Application and user data**\
  The same technical particularity that makes hard to make backups within your K3s cluster with Velero, allows for doing them more easily in a external manner. With [UrBackup](https://www.urbackup.org/) you can have an agent on each of your K3s cluster nodes, and make them access the folders in which you mounted the persistent volumes of your applications. Those agents are clients for a UrBackup server, run on a different VM, where you can store the backups of those volumes.

- **Backups**\
  The backups themselves are usually just files, so they can be treated as such. The backups you make with Clonezilla or UrBackup can be copied in other storages to improve their chances against issues like faulty drives, data corruption or ransomware. The ones made within Proxmox VE are also just files, but they are not as easily accesible since they are kept within your Proxmox VE system. Still, you could get them with a remote access tool like WinSCP and copy them like with any other file.

## Where to store the backups. Backup storage

After determining what data to backup and how to do it, you have to decide **where** to store all your backups. Of course, in a low cost and completely local system scenario like this guide's cheap homelab, we are not talking about advanced RAID 5 systems or cloud storage. For us in this case, a couple of external USB storage drives will do:

- If you remember, the system described [in the first chapter of this guide](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup) included "_One external, 2 TiB, HDD drive, plugged to a USB 3 port_". This drive is already configured and in use by Proxmox VE, and is where you were told to put the backups of the two VM templates you did way back in the [**G023**](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#vm-templates-backup) and [**G024**](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#turning-the-vm-into-a-vm-template) chapters.

  - This USB storage drive will also be the place where to put the backups done with UrBackup, but in a different LVM volume.

- To store the Clonezilla backups, better use a different USB drive than the one configured with Proxmox VE to avoid awful surprises (like accidentally overwriting or wiping out the Proxmox VE backups).

Needles to say that you should use only storage drives that are already empty and in good condition (check their SMART attributes). Also, bear in mind that you should take special care of those drives as much as you possibly can.

## When to do the backups. Backup scheduling

It is not a trivial matter at all to decide when to do backups. This depends a lot on the nature of the data you have to backup, but also about how the procedure itself can affect the system you are backing up. This guide goes a bit deeper on this in the upcoming chapters but, broadly speaking, the main concerns to bear in mind when scheduling backups are these:

- **How much "time" can you afford to lose in your data in case of a failure**\
  A backup is made in a concrete point in time, and a failure or issue will almost always happen between backups. This results in a data gap that cannot be covered by any backup you may have. Therefore, you have to ponder what gap size (or age) you tolerate in your data, and if you can recover somehow that information loss.

- **How your backup processes hit your system**\
  The execution or restoration of backups affects your system. Ideally, you want your data to remain static while you copy it, but this usually implies stopping the affected system or application altogether. Also, depending on what tool you use, you have to apply a different approach to make or restore your backups on your system.

- **Your backups get old**\
  A backup done a year ago does not have the same value as one made this week. This depends a lot on what kind of data a backup stores. For instance, configuration files do not tend to change a lot over time, but their old versions could help you solving current problems in your system. On the other hand, user data usually changes frequently, so you want their backups to be as recent as possible. Still, old versions of that information can be required to be kept to attend technical or legal issues.

- **Your backups grow in number**\
  You will accumulate an ever growing number of backups, so you can run out of storage space for them. You need to figure out the purging policy that fits your needs. For instance, you could replace all the daily backups done within the week with the last one from Sunday, all the weeklies with the one made the last day of the month, etc.

- **Your backups grow in size**\
  You need to be aware that certain backups grow bigger in size over time, usually the ones holding user data. This is something you need to factor in your backup purging policies, forcing you to plan when to get more storage depending on your backup size growth factor.

## References

- [Clonezilla](https://clonezilla.org/)
- [UrBackup](https://www.urbackup.org/)
- [Velero](https://velero.io/)

## Navigation

[<< Previous (**G036. Host and K3s cluster**)](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G038. Backups 02**) >>](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md)
