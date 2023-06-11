# G905 - Appendix 05 ~ Cloning storage drives with Clonezilla

In this guide I'll show you how to clone and restore an entire storage drive from a computer, like your Proxmox VE host, with one of the most popular tool out there capable of doing so: [Clonezilla](https://clonezilla.org/).

I'll demonstrate the procedures with a VirtualBox VM I've setup with two "internal" storage drives (with fixed sizes), to remind you of the internal storage setup in the Proxmox VE host used in this guide series.

## Preparing the Clonezilla Live USB

To clone a storage drive in a computer, you need to boot up the system with Clonezilla Live. So first you need to download and install it in an USB drive, like you did with the Proxmox VE installer back in the [**G002** guide](G002%20-%20Proxmox%20VE%20installation.md#writing-the-proxmox-ve-iso-from-a-windows-10-system-with-rufus).

1. Download the latest **stable** version of Clonezilla Live [from this page](https://clonezilla.org/downloads.php). Choose the **alternative stable** edition, since that one is based on Ubuntu and will have better hardware support. In this guide I'll use the `20210609-hirsute` stable version of Clonezilla.
    - Clonezilla's download page will ask you three things.
        - **CPU architecture**: choose `amd64` if your computer has a 64 bits CPU. This architecture is also necessary for systems with **uEFI secure boot** enabled.
        - **File type**: choose `iso` to download Clonezilla Live as an iso file.
        - **Repository**: leave `auto`, so the page can determine on its own from where it should download the requested iso file.

2. Prepare an empty USB drive, a 4 GiB one should be enough. Be sure that it's empty, since this is the device where you'll flash the Clonezilla Live iso.

3. Flash the Clonezilla Live iso into your USB drive. If you're on Windows, you can use [Rufus](https://rufus.ie/en/) (as I showed you in the [**G002** guide](G002%20-%20Proxmox%20VE%20installation.md#writing-the-proxmox-ve-iso-from-a-windows-10-system-with-rufus)), [balenaEtcher](https://www.balena.io/etcher/) or any other program you might prefer. If you need more references, check out [this Clonezilla Live page](https://clonezilla.org/liveusb.php) where they give more details about different methods for flashing the iso on different OSes.

## Cloning a storage drive with Clonezilla

With Clonezilla flashed in an USB drive, you can start creating images of the storage drives in your computer.

1. Ready a large external (USB) storage drive, one where your Clonezilla images can fit. Clonezilla supports many filesystem formats so, for instance, you could use a ntfs-formatted storage to save the Clonezilla images.
    - Furthermore, you could prepare beforehand some directory structure to organize the images within that storage drive. Be mindful that you won't be able to create folders from within Clonezilla, only choose where you want to store the images.

2. Boot your system with your Clonezilla Live USB. You'll reach its GRUB boot menu.

    ![Clonezilla Live boot menu](images/g905/clonezilla_boot_menu.png "Clonezilla Live boot menu")

    From the several `Clonezilla live` options shown, choose the one that fits better your screen. In my case, I'll stick with the default `(VGA 800x600)` one.

3. After a few seconds, you'll see a language menu.

    ![Language menu](images/g905/clonezilla_language_menu.png "Language menu")

    Just choose your preferred language and press enter.

4. Next you'll reach the keyboard layout menu.

    ![Keyboard layout menu](images/g905/clonezilla_keyboard_layout_menu.png "Keyboard layout menu")

    If the automatically chosen layout doesn't fit your needs, choose `Change keyboard layout` to change it.

5. The following screen makes you choose between starting Clonezilla or getting into a shell.

    ![Start Clonezilla or shell](images/g905/clonezilla_start_or_shell.png "Start Clonezilla or shell")

    Leave selected the `Start Clonezilla` option and press enter (or click `Ok` with your mouse).

6. You'll get to the Clonezilla main actions menu screen.

    ![Clonezilla main actions menu](images/g905/clonezilla_main_actions_menu.png "Clonezilla main actions menu")

    To clone images out of your storage drives, keep the action already highlighted first, `device-image`, and press enter.

7. Next, Clonezilla will ask you on what kind of storage device you want to store the image in.

    ![Image directory location device](images/g905/clonezilla_image_directory_location_device.png "Image directory location device")

    In this case, you'll be using a local device as storage drive, so leave the already chosen `local_dev` option.

8. Clonezilla will print some lines warning you to plug in the USB drive in which you want to store the image.

    ![Warning for USB drive](images/g905/clonezilla_image_directory_location_insert_device.png "Warning for USB drive")

    If you didn't already, plug your USB storage now and wait a few seconds to allow Clonezilla detect it. Then press enter.

9. Next you'll see the autoscan output (which refreshes every few seconds) of what Clonezilla is detecting as local storage devices.

    ![Local devices autoscan](images/g905/clonezilla_local_devices_autoscan.png "Local devices autoscan")

    Above you can see how it sees three storage devices:
    - `/dev/sda` is the first storage device in this computer.
    - `/dev/sdb` is the second storage device.
    - `/dev/sdc` is the external USB drive you want to use for saving Clonezilla images.

    With your USB drive detected, you can get out of this screen by pressing `Ctrl+C`.

10. You'll get into a screen where you'll have to choose a partition from the ones found within all the previously detected local storage devices.

    ![Partitions available on local devices](images/g905/clonezilla_local_devices_chose_partition.png "Partitions available on local devices")

    > **BEWARE!**  
    > Be careful of not choosing any partition within the drive you want to backup. Only choose a partition present in your USB storage drive (the `sdc` drive in this case).

    Choose the partition that corresponds to your USB drive, which would be `sdc1` in this case.

    ![Partition chosen on USB device](images/g905/clonezilla_local_devices_sdc1_partition_chosen.png "Partition chosen on USB device")

    If there's more than one partition available in your external USB storage, be mindful of which one you're using as repository for your Clonezilla images.

11. After choosing the partition, you'll be asked if you want to check the filesystem within the chosen partition.

    ![Partition check question](images/g905/clonezilla_check_chosen_partition.png "Partition check question")

    Let's trust your USB drive and just skip the check, so keep the `no-fsck` option highlighted and press enter.

12. You'll reach the directory browser screen, where you have to choose the directory (within the partition you selected previously) in which you want to save the image.

    ![Directory browser](images/g905/clonezilla_directory_browser.png "Directory browser")

    The USB drive I'm using here is an empty ntfs formatted one, which explains the Windows recycle bin folder. Notice that Clonezilla here doesn't give you any option for handling directories, you can only choose the one you want.

    > **BEWARE!**  
    > Don't be confused, the `$RECYCLE.BIN` item in the snapshot above is **not** the selected directory. The currently selected one is the '`/`' one, the root of the partition you chose previously as your images' repository.

    Pay attention to the `Current selected dir name` line, it indicates you in which path you are. `Browse` inside the directory you want to use as Clonezilla's image repository and then press `Done` (with the mouse, if you like).

13. Clonezilla will print some lines confirming your selection.

    ![Information about chosen filesystem](images/g905/clonezilla_chosen_filesystem.png "Information about chosen filesystem")

    > **BEWARE!**  
    > Don't be confused, the `$RECYCLE.BIN` item in the snapshot above is **not** the selected directory. The selected one is the '`/`' one, inside of which the `$RECYCLE.BIN` lays.

    The path under the `TARGET` column, the `/home/partimag` is the path in memory where Clonezilla has mounted the partition you chose previously. Press enter to allow Clonezilla to continue with the cloning.

14. Now that you know _where_ you want to save your image, the next step is to choose _how_ you want it to be cloned. The operation mode is something you select at the screen below.

    ![Mode options menu](images/g905/clonezilla_mode_options_menu.png "Mode options menu")

    Stick to the `Beginnger mode` option, since it should be enough for your needs.

15. Clonezilla will ask you if you want to make an image of the entire disk, or save each of its partitions as independent images.

    ![Save options](images/g905/clonezilla_save_options.png "Save options")

    In this case you want the image of the entire disk, so leave the `savedisk` option selected and press enter.

16. You'll be asked a name for the image you're going to create.

    ![Image filename](images/g905/clonezilla_image_filename.png "Image filename")

    > **BEWARE!**  
    > Don't use spaces in the filename.

    Give all your images meaningful filenames, to make their management easier.

    > **BEWARE!**  
    > The only thing that tells apart one image from another is their name, so always try to apply a proper naming scheme to your images. For instance, it could be `<hostname>_<device name>_<current date>_img`.  
    > Also, be careful of not making the name too long or it won't fit when listed by Clonezilla.

    ![Image filename set](images/g905/clonezilla_image_filename_set.png "Image filename set")

    Since I want to clone the `sda` drive in the image, I've named the image related to the targeted storage drive.

17. In the following screen, Clonezilla asks you which disks you want to clone.

    ![Choosing source to clone](images/g905/clonezilla_source_disk_clone.png "Choosing source to clone")

    Notice that you could choose all the disks in the list and clone them all in the same image. This possibility can be useful in some cases but, for our scenario, a one-by-one method is more convenient. So, choose only the one disk you want to clone and press enter. Given the name I set for the image in the previous step, you know is the `sda` one this time.

    ![Drive sda chosen as source](images/g905/clonezilla_source_disk_clone_sda_chosen.png "Drive sda chosen as source")

    Notice the '`*`' marking the selected drive.

18. Clonezilla also needs to know which compression method you prefer.

    ![Compression method](images/g905/clonezilla_compression_method.png "Compression method")

    Unless you think your system cannot handle it, keep the `parallel gzip compression` option highlighted and press enter.

19. You'll be asked about checking the `source filesystem`, meaning if you want Clonezilla to look for errors in the filesystem of the drive you're about to clone.

    ![Source filesystem check](images/g905/clonezilla_source_filesystem_check.png "Source filesystem check")

    Unless you have some suspicion that the filesystem within the disk you're about to clone is faulty, skip the check by keeping the default `-sfsck` option selected and press enter.

20. Clonezilla also has the capacity of checking the resulting image to verify if it's truly restorable. This screen asks you about if you want the check be executed when the cloning is done.

    ![Saved image check](images/g905/clonezilla_saved_image_check.png "Saved image check")

    Leave the default `Yes` option and press enter.

21. The next screen you'll see asks you if you want to encrypt the image.

    ![Image encryption](images/g905/clonezilla_image_encryption.png "Image encryption")

    If you want to encrypt the image, you'll need to provide a strong passphrase or private key (that you should safely keep in a password manager or similar solution). If not, just keep the default `-senc` option selected to skip the encryption.

22. You also have to tell Clonezilla what to do after the whole cloning process is done.

    ![Action after cloning done](images/g905/clonezilla_action_after_cloning.png "Action after cloning done")

    With the highlighted `-p choose` option by default, after the image is cloned, Clonezilla will ask you what to do next. Useful to start the cloning of another storage drive.

23. Next, Clonezilla will print a reminder about how to execute the whole process with a long command line.

    ![Clone command reminder](images/g905/clonezilla_command_reminder.png "Clone command reminder")

    > **BEWARE!**  
    > The command can only be executed within the Clonezilla's own shell.

    Just press enter to continue with the cloning process.

24. Right before it starts saving the image, Clonezilla will ask you for a final confirmation.

    ![Cloning process final confirmation](images/g905/clonezilla_cloning_final_confirmation.png "Cloning process final confirmation")

    Answer `y` to the question to finally start the cloning process.

25. Clonezilla will then launch the program **Partclone**, which will be the one doing the cloning job.

    ![Partclone running](images/g905/clonezilla_partclone_running.png "Partclone running")

26. When Partclone finishes, Clonezilla will print a few informative lines about the last procedure done by Partclone (in this case, the checking of your new image's restorability), and ask you to press enter.

    ![Cloning process done](images/g905/clonezilla_image_done.png "Cloning process done")

27. You'll reach a new menu that offers several actions to execute at this point.

    ![Mode menu after cloning](images/g905/clonezilla_mode_options_menu_after_cloning.png "Mode menu after cloning")

    From this menu you can shutdown (`poweroff`) or `reboot` your system, or even get into the Clonezilla shell (`cmd`). You can also `rerun` Clonezilla to create another image or maybe restore one.
    - If you want to use the same repository you used to create the previous image, use the `rerun2` option.

28. Check on your system or some other computer the image saved. On my Lubuntu computer it looks like below.

    ![Image folder on storage drive](images/g905/clonezilla_image_folder.png "Image folder on storage drive")

    Notice how the image is in fact a folder with the name I gave it in Clonezilla. Within this folder you'll see several files.

    ![Image files](images/g905/clonezilla_image_files.png "Image files")

    This is the real structure of a Clonezilla image, so **don't touch anything** there unless you're using a specialized tool able to handle Clonezilla images.

## Restoring a Clonezilla image

The restoration process of a basic Clonezilla image, like the one created in the previous section, is as follows.

1. Boot your system with Clonezilla Live and reach the main actions menu screen, where you should choose the `device-image` option.

    ![Clonezilla main actions menu](images/g905/clonezilla_main_actions_menu.png "Clonezilla main actions menu")

2. As you had to do for the cloning process, you need to configure where the image repository is. Here I'm assuming a external USB drive, so choose `local_dev` and press enter.

    ![Image directory location device](images/g905/clonezilla_image_directory_location_device.png "Image directory location device")

3. Clonezilla will warn you to plug in now the USB drive in which you have your cloned images stored.

    ![Warning for USB drive](images/g905/clonezilla_image_directory_location_insert_device.png "Warning for USB drive")

    If you didn't already, plug your USB storage now and wait a few seconds to allow Clonezilla detect it. Then press enter.

4. Next you'll see what Clonezilla is detecting as local storage devices.

    ![Local devices autoscan](images/g905/clonezilla_local_devices_autoscan.png "Local devices autoscan")

    Above you can see how it sees three storage devices:
    - `/dev/sda` is the first storage device in this computer.
    - `/dev/sdb` is the second storage device.
    - `/dev/sdc` is the external USB drive you want to use for loading Clonezilla images.

    With your USB drive detected, you can get out of this screen by pressing `Ctrl+C`.

5. You'll get into a screen in which you'll have to choose a partition from the ones found within all the previously detected local storage devices.

    ![Partitions available on local devices](images/g905/clonezilla_local_devices_chose_partition.png "Partitions available on local devices")

    > **BEWARE!**  
    > Only choose a partition present in your USB storage drive (the `sdc` drive in this case) that you know it holds clone images that can be restored in the system.

    Choose the partition that corresponds to your USB drive, which would be `sdc1` in this case.

    ![Partition chosen on USB device](images/g905/clonezilla_local_devices_sdc1_partition_chosen.png "Partition chosen on USB device")

    If there's more than one partition available in your external USB storage, be mindful of which one you're using as repository for your Clonezilla images.

6. After choosing the partition, you'll be asked if you want to check the filesystem within the chosen partition.

    ![Partition check question](images/g905/clonezilla_check_chosen_partition.png "Partition check question")

    Let's trust your USB drive and just skip the check, so keep the `no-fsck` option highlighted and press enter.

7. You'll reach the directory browser to choose the exact location of your images repository. If you're using a repository where you've already saved other images, you'll see their directories listed here.

    ![Images Repository location not empty](images/g905/clonezilla_repository_location_not_empty.png "Images repository location not empty")

    See how, below the `$RECYCLE.BIN` directory, there are two directories that correspond to images done previously. Notice how their names just fit in the listing, so remember to give your Clonezilla images tight names.

    > **BEWARE!**  
    > Be careful of not choosing the folder of another image to create a new one, although it shouldn't be much a problem since each image is self-contained in its own folder.

    If the current directory you're seeing now is the one you want to use as repository, press `Done`.

8. Clonezilla will print a warning informing you about the repository location you've chosen. Just press `enter` to keep with the procedure.

    ![Repository location warning](images/g905/clonezilla_repository_location_warning.png "Repository location warning")

9. Clonezilla will ask you about what mode to use. Use the `Beginner` one, it will be enough.

    ![Mode options menu](images/g905/clonezilla_mode_options_menu.png "Mode options menu")

10. Now you get to choose what action to perform. For restoring the image of an entire disk, choose `retoredisk` and press enter.

    ![Chosen restoredisk option](images/g905/clonezilla_main_actions_menu_restoredisk.png "Chosen restoredisk option")

11. Clonezilla will ask you what image to restore from the previously chosen repository.

    ![Choose image to restore](images/g905/clonezilla_choose_image_to_restore.png "Choose image to restore")

    In this case, there's an image for the `sda` drive and another for the `sdb` one. Notice how, next to their names (both ending with the `_img` suffix), Clonezilla also shows you:

    - The date and time in which each image was created (`2021-0805-1350`, `2021-0805-1749`).
    - The device name (`sda`, `sdb`).
    - The size of the cloned storage (`56.0GB`, `2147MB`)

    Choose the image you want to restore (the `demo_sda_drive_2021-08-04_img` one in this demo) and press enter.

12. Now you need to tell Clonezilla which storage device you want to restore.

    ![Choosing the storage drive to restore](images/g905/clonezilla_storage_drive_to_restore.png "Choosing the storage drive to restore")

    Notice how this screen informs you of the size of each drive present in the system. This is important because you cannot restore, for instance, the `sda`'s image inside the `sdb` drive. In this case, the drive to restore is the `sda` one.

    > **BEWARE!**  
    > When restoring an image, always restore it in a storage drive equal or larger in size than the original drive you cloned it from. Even if the image's data didn't fill the whole original drive, it's filesystem will expect to have available the same storage size it had in the original drive.

13. Clonezilla will ask you about checking the image's restorability before restoring it.

    ![Image restorability check](images/g905/clonezilla_image_restorability_check.png "Image restorability check")

    Leave the default `Yes` option if you like.

14. Now you have to tell Clonezilla what you want it to do after the image has been restored.

    ![Action after restoration done](images/g905/clonezilla_action_after_restoration_done.png "Action after restoration done")

    If in doubt, just leave the `-p choose` option selected and press enter, so you can decide after the restoration is done.

15. Clonezilla will print some lines showing you the command that executes the restoration. Press enter for continuing the process.

    ![Restoration command reminder](images/g905/clonezilla_restoration_command_reminder.png "Restoration command reminder")

16. Next, Clonezilla will launch Partclone to check the image's restorability (if you chose to do so).

    ![Partclone checks image](images/g905/clonezilla_partclone_checks_image.png "Partclone checks image")

17. After checking the image, Clonezilla will ask for your confirmation **twice** to proceed with the restoration.

    ![Image restoration confirmation](images/g905/clonezilla_image_restoration_confirmation.png "Image restoration confirmation")

    Answer `y` and press enter to get to the **second** confirmation.

    ![Image restoration second confirmation](images/g905/clonezilla_image_restoration_second_confirmation.png "Image restoration second confirmation")

    Again, if you're sure of this operation, answer `y` again to finally execute the restoration.

18. After outputting some command lines, Clonezilla will launch Partclone to perform your image's restoration.

    ![Partclone restoring image](images/g905/clonezilla_partclone_restoring_image.png "Partclone restoring image")

19. After Partclone is done, Clonezilla it will output a whole bunch more of command lines before asking you to press enter.

    ![Pressing enter after restoring image](images/g905/clonezilla_enter_after_restoration.png "Pressing enter after restoring image")

20. Finally, you'll get back to the Clonezilla menu in which you can decide what to do next.

    ![Mode menu after restoring](images/g905/clonezilla_mode_options_menu_after_cloning.png "Mode menu after restoring")

21. The restoration is done. Now you can shutdown Clonezilla, start your system normally and check if the restored drive has been recovered as expected.

## Considerations about Clonezilla

Clonezilla is able to see inside filesystem structures in order to make more optimized backups. For instance, is able to detect the swap volume in a Linux setup and just save a reference to it, instead of also backing up its content. Also, it will ignore any empty space and only save content, effectively compacting the data within the backup.

On the other hand, if Clonezilla cannot read the content of a storage drive or volume, it'll be forced to read it completely regardless of it being empty. For example, Clonezilla cannot get inside the virtual drives of your VMs, so it will make backups of the entire drives, free space included.

Also be aware that, by default, Clonezilla splits large backups in 4 GiB chunks. These chunks are gzipped files with an extra alphabetic extension like `.aa`, `.ab` and so on.

> **BEWARE!**  
> If there's something particularly odd within the filesystem you're trying to image, Clonezilla may not be able to execute at all. For instance, the hard disks of the VMs running in Proxmox VE are detected by Clonezilla also as partitions and, if Clonezilla cannot access them for some reason, the process will fail.

## Alternative to Clonezilla: _Rescuezilla_

There are several other tools available, free and paid, that can do the same job as Clonezilla. One that is compatible with Clonezilla images is [Rescuezilla](https://rescuezilla.com/). It's much more user friendly and requires fewer steps to perform the backup or restoration of a storage drive, but at the expense of offering less options: for instance, it doesn't offer encryption of images.

## References

### _Flashing utilities for Windows_

- [balenaEtcher](https://www.balena.io/etcher/)
- [Rufus](https://rufus.ie/)

### _Imaging/cloning tools_

- [Clonezilla](https://clonezilla.org/)
- [Clonezilla Live on USB](https://clonezilla.org/liveusb.php)
- [Rescuezilla](https://rescuezilla.com/)

## Navigation

[<< Previous (**G904. Appendix 04**)](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G906. Appendix 06**) >>](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md)
