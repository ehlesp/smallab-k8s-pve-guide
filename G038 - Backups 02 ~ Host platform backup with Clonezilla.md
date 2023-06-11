# G038 - Backups 02 ~ Host platform backup with Clonezilla

To make a backup of a host platform usually means doing an image of its entire filesystem. This is a procedure that comes with several crucial concerns that you must ponder before executing it.

## What gets inside this backup

In short, a backup of this kind is a complete copy of a host system. This means that you not only backup the operative system with all its critical files, like configuration ones, but also any other data you might have in it.

So, in the case of the Proxmox VE system deployed in this guide series, if you make a full host clone image of it, you'll get in your backup:

- The whole Proxmox VE system itself, including the underlying Debian operative system and all the Proxmox related files.
- The virtual machines and templates (maybe even containers) you have created within Proxmox VE.
- Within each virtual machine, there's operative system, application and user data.

Is important to be aware of this because, obviously, copying all of this data may result in one or more significantly big backup files.

## Why doing this backup

The main utility for a host platform backup is to give you the possibility of a fast recovery to a previous stable version of your system. The scenarios in which you would need such capability are essentially two.

- When applying major changes or updates on your host platform; those can lead to unexpected bad effects or behaviors.

- After being affected by some harmful event such as ransomware, storage drive failure, etc.

The convenience of being able to do a fast restoration of your system from those situations cannot be understated. This not only saves you time and spares your patience, but maybe even save you money!

## How it affects the host platform

The problem with this kind of backup is that you cannot do it while the system is running. You must shut the whole system down, then reboot it with the backup tool of your choosing, which is Clonezilla in this case. Keep in mind that here we're talking about backing up your system's lowest layer, the one that supports all the rest. The cloning/backup tool needs exclusive low level access to the storage drives to read and backing them up properly, so there's no other way to do this.

## When to do the backup

In this guide series' scenario, the system deployed is just a personal one, but still you'll have to plan when you want to do this so it doesn't disrupt too much your system's availability. So, what could be a somewhat decent planning for this kind of backup? I can give you a couple of basic possibilities.

- Backup **always** before **any** update or configuration change, regardless of its scope.
- Regular monthly backups, to keep the clones fresh.
- A combination of the previous two.

So, at the very least, you should make the backups before applying any update on your host platform, meaning updates of the Proxmox VE system itself.

## How to backup with Clonezilla

What you do with Clonezilla is generate clone images of the storage drives in your system. If you remember, the Proxmox VE host platform in this guide series uses two internal storage drives.

- The 1 TiB SSD drive that holds the Proxmox VE system itself and the virtual machines.
- The 2 TiB HDD drive that only has the data volumes connected to the virtual machines.

These two are the ones you must clone with their respective images with Clonezilla, a procedure that I've already explained in the [**G905** appendix guide](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md). Next I give you the general indications of the whole procedure.

1. Prepare an USB drive where you can install the Clonezilla Live system, [as explained here](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#preparing-the-clonezilla-live-usb).

2. Prepare an external USB storage drive where you can keep the Clonezilla images. If you want the storage be compatible with Windows, you can format it to NTFS which is a filesystem Clonezilla is also able to use.

    > **BEWARE!**  
    > If you have to use the same storage drive for different backups, be sure of separate them in different partitions.

3. Shutdown your Proxmox VE system.

4. If you have it, disconnect the USB storage drive that is used in this guide series for storing the Proxmox virtual machines and templates backups.

5. Plug in the external USB storage drive where you'll keep the Clonezilla images.

6. Plug in your Clonezilla Live USB and make your Proxmox VE system boot up with it.

7. Following the [instructions explained here about **making** a Clonezilla image](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#cloning-a-storage-drive-with-clonezilla), create a clone image of **each** of the internal storage drives in your system.

8. When you have done all the clone images, shutdown the system and unplug both the Clonezilla Live USB and the external storage drive with the Clonezilla backups.

9. If you like, check on a different computer that the images are present in the external storage drive you've used. You should have one folder per each clone image done.

## How to restore with Clonezilla

Let's imagine you need to restore your Proxmox VE system because of a botched update, or a serious misconfiguration, that requires a complete reinstallation of the whole system. Since you already prepared for such situation, you have recent clone images of your system's internal storage drives. Then, let's see how the procedure would go.

1. Shutdown your Proxmox VE system.

2. If you have it, disconnect the USB storage drive that is used in this guide series for storing the Proxmox virtual machines and templates backups.

3. Plug in the external USB storage drive where you have the Clonezilla images.

4. Plug in your Clonezilla Live USB and make your Proxmox VE system boot up with it.

5. Follow the [instructions here for **restoring** a Clonezilla image](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#restoring-a-clonezilla-image).

    > **BEWARE!**  
    > I already warned you about this in the [**G905** guide](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#restoring-a-clonezilla-image), but be very careful when you choose the storage drive (or partition) where you restore a clone image. Be always sure that you're choosing the one where you want to restore an image, and that it has enough room for the data within the image.

6. After finishing the restoration, shutdown your system, shutdown the system and unplug both the Clonezilla Live USB and the external storage drive with the Clonezilla backups.

7. Finally, plug back in the other external USB storage drive with the Proxmox VM backups and then boot up normally your system to see if it has been restored.

## Final considerations

Be aware that Clonezilla can also make images of partitions, so you could consider a backup strategy different from the one shown here. Also, notice that, in a restoration of the Proxmox VE system used here, you don't really need to restore the contents of both of the internal storage drives, just the one that truly contains the Proxmox root filesystem. But this also has its danger if the restored system expects a different configuration on the secondary drive than the one currently present. This means that you must keep the clone images of both internal drives current and _in sync_, so to speak, to avoid discrepancies between what the system expects to have and what's really deployed in it.

## References

- [Clonezilla](https://clonezilla.org/)

## Navigation

[<< Previous (**G037. Backups 01**)](G037%20-%20Backups%2001%20~%20Considerations.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G039. Backups 03**) >>](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md)
