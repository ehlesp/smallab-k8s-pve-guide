# G037 - Backups 01 ~ Considerations

Now that you have your Kubernetes cluster setup up and running, you must start thinking about how to protect the data you'll store in it. The main method for achieving this protection is always with a good backup, or a well managed set of them. So here, and in the following guides, I'll give you a more or less basic explanation about managing backups suitable for this guides series' low-cost small setup.

## What to backup. Identifying your data concerns

To setup your backups properly, first you must be aware of the different data concerns (so to speak) you have in your system. In the system configured in this guide series, you can single out the following areas of concern.

- **Host platform**: this encompasses your entire host system, which runs the Proxmox VE server. The relevant data here is the whole Proxmox VE setup itself, including the underlying Debian operative system, all related configuration and other files like logs.
- **Virtual machines**: the virtual machines you have running within Proxmox VE, and also the templates that were used to create them.
- **Kubernetes cluster**: about the Kubernetes cluster setup and all the applications deployed in it.
- **Application data**: related to configuration applied and data generated within each application.
- **User data**: all the data generated or just stored by users on each application running in your system.
- **Backups**: the backups themselves are also sensitive data that has to be protected.

As you can see, each layer is essentially a different perspective with its own concerns about your system.

## How to backup. Backup tools

Knowing the data layers your system has is one step, the following one is to identify which tools can fit your backup needs. Here I give you a correlation of each data concern with the concrete tool that can be used to do the corresponding backup.

- **Host platform**: [Clonezilla](https://clonezilla.org/), for making images of the entire storage drives used to run the whole the Proxmox VE system.

- **Virtual machines**: Proxmox VE comes with its own integrated backup system for the virtual machines and containers you run in it.

- **Kubernetes cluster**: my initial idea was to use [velero](https://velero.io/) for creating backups of the persistent volumes and resources running in the K3s cluster but, since this tool is not compatible with the local path storage provider used in this guide series (because it employs the `hostpath` method) to connect with the persistent volumes, I've been forced to dismiss this possibility. On the other hand, I haven't found any other similar backup tool that could fit our setup, so I won't be able to show you how to do backups from within your Kubernetes cluster. Just know it's possible and there are several tools to do so, although mostly centered on storage cloud technology.

- **Application and user data**: the same technical particularity that makes impossible to make backups within your K3s cluster with velero, allows for doing them in a external manner. With [UrBackup](https://www.urbackup.org/) you can have an agent on each of your K3s cluster nodes, and make them access the folders in which you mounted the persistent volumes of your applications. Those agents are clients for a UrBackup server, run on a different VM, where you can store the backups of those volumes.

- **Backups**: the backups themselves usually are just files, so they can be treated as such. The backups you make with Clonezilla or UrBackup could be copied in other storages to improve their chances against faulty drives, data corruption, ramsonware, etc. The ones made within Proxmox VE are also just files, but they're not as easily accesible since they're kept within your Proxmox VE system. Still, you could get them with a remote access tool like WinSCP and copy them like with any other file.

## Where to store the backups. Backup storage

You've seen what data to backup and how to do it. Now you have to decide **where** you'll store all your backups. Of course, in a low cost and completely local system scenario like the one depicted in this guide series, we're not talking about advanced RAID 5 systems or cloud storage. For us in this case, a couple of external USB drives will do.

- If you remember, the system I depicted at the beginning of this guide series ([guide **G001**](G001%20-%20Hardware%20setup.md)) included "_one external, 2 TiB, HDD drive, plugged to a USB 3 port_". This drive is already configured and in use by Proxmox VE, and is where I told you to put the backups of the two VM templates you did way back in the [**G023**](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#vm-templates-backup) and [**G024**](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#turning-the-vm-into-a-vm-template) guides.
    - This will also be the drive where to put the backups done with UrBackup, but in a different LVM volume.

- To store the Clonezilla backups, use a different USB drive than the one configured with Proxmox VE to avoid awful surprises (like accidentally overwriting or wiping out the Proxmox VE backups!).

Needles to say that you should use only storage drives that are already empty and in good condition (check their SMART attributes!). Also, bear in mind that you should take special care of those drives as much as you possibly can.

## When to do the backups. Backup scheduling

It's not a trivial matter at all to decide when to do backups. This depends a lot on the nature of the data you have to backup, but also about how the procedure itself can affect the system you're backing up. I'll go a bit deeper on this in the upcoming guides but, broadly speaking, the main notions to bear in mind when programming backups are the following.

- _How much "time" can you afford to lose in your data in case of a failure_: a backup is made in a concrete point in time, and a failure or issue will almost always happen between backups. So you'll have a data gap that won't be covered by any backup you may have. Therefore, you'll have to ponder what gap size (or age) you tolerate in your data, and if you can recover somehow that information loss.

- _How your backup processes hit your system_: depending on what kind of backup you do, its execution will affect your system, in its performance usually. Ideally, you want your data to remain static while you copy it, but this usually implies stopping the affected system or application altogether. Also, depending on what tool you use, you'll apply a different approach to do your backups on your system.

- _Your backups get old_: a backup done a year ago doesn't have the same value as one made this week. This depends a lot on what kind of data a backup stores. For instance, configuration files don't tend to change a lot over time, but old versions could help you solving current problems in your system. On the other hand, user data usually changes frequently, so you'll want your backups as recent as possible. Still, old versions of that information can be required to be kept to attend technical or, more commonly, legal issues.

- _Your backups grow in number_: you'll accumulate an ever growing number of backups, so you'll eventually run out of storage space for them. You need to figure out the purging policy that fits your needs. For instance, you could replace all the daily backups done within the week with the last one from sunday, all the weeklies with the one made the last day of the month, etc.

- _Your backups grow in size_: you need to be aware that certain backups will get bigger in size over time, usually the ones holding user data. This is something you'll also need to factor in your backup purging policies, while also forcing you to plan when to get more storage depending on your backup size growth factor.

## References

- [Clonezilla](https://clonezilla.org/)
- [UrBackup](https://www.urbackup.org/)
- [Velero](https://velero.io/)
