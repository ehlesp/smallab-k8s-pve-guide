# G020 - K3s cluster setup 03 ~ Debian VM creation

Your Proxmox VE system is now configured well enough for you to start creating in it the virtual machines you require. In this guide, I'll show you how to create a rather generic VM with Debian. This Debian VM will be the base over which you'll build, in the following guides, a more specialized VM template for your K3s cluster's nodes.

## Preparing the Debian ISO image

### _Obtaining the latest Debian ISO image_

First, you'll need to download the Debian ISO image. At the time of writing this, the latest version is [**11.1.0 Bullseye**](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.1.0-amd64-netinst.iso).

You'll find the _net install_ version of the ISO for the latest Debian version right at the [Debian project's webpage](https://www.debian.org/).

![Debian project main's webpage](images/g020/debian_netinstall_iso_download.png "Debian project's main webpage")

After clicking on that big `Download` button your browser should start downloading the `debian-11.1.0-amd64-netinst.iso` file automatically.

### _Storing the ISO image in the Proxmox VE platform_

Proxmox VE needs that ISO image saved in the proper storage space it has to be able to use it. This means that you need to upload the `debian-11.1.0-amd64-netinst.iso` file to the storage you configured to hold such files, the one called `hdd_templates`.

1. Open the web console and unfold the tree of available storages under your `pve` node. Click on `hdd_templates` and you'll reach its `Summary` page.

    ![Summary of templates storage](images/g020/pve_templates_storage_summary.png "Summary of templates storage")

2. Click on the `ISO Images` tab, and you'll see the page of available ISO images.

    ![ISO images list empty](images/g020/pve_templates_storage_images_list_empty.png "ISO images list empty")

    You'll find it empty at this point.

3. Click on the `Upload` button to raise the dialog below.

    ![ISO image upload dialog](images/g020/pve_templates_storage_iso_upload_dialog.png "ISO image upload dialog")

4. Click on `Select File`, find and select your `debian-11.1.0-amd64-netinst.iso` file in your computer, then click on `Upload`. The same dialog will show the upload progress.

    ![ISO image upload dialog in progress](images/g020/pve_templates_storage_iso_upload_dialog_in_progress.png "ISO image upload dialog in progress")

5. After the upload is completed, the upload dialog will close on its own and you'll be back to the `ISO Images` page. Refresh the page, then you'll see the list now updated with your newly uploaded ISO image.

    ![ISO images list updated](images/g020/pve_templates_storage_images_list_updated.png "ISO images list updated")

    Notice how the ISO is only identified by its file name. Sometimes ISOs don't have detailed names like the one for the Debian distribution, so be sure of giving the ISOs you upload meaningful and unique names so you can tell them apart.

6. Finally, you can check out in the `hdd_templates` storage's `Summary` how much space you have left (`Usage` field).

    ![Summary of templates storage updated](images/g020/pve_templates_storage_summary_updated.png "Summary of templates storage updated")

Now you only have one ISO image but, over time, you may accumulate a number of them. So be always mindful of the free space you have left, and remove old images or container templates you're not using anymore.

## Building a Debian virtual machine

In this section you'll see how to create a basic and lean Debian VM, then how to turn it into a VM template.

### _Setting up a new virtual machine_

First, you need to configure the VM itself.

1. Click on the `Create VM` button found at the web console's top right.

    ![Create VM button](images/g020/debian_vm_create_vm_button.png "Create VM button")

2. You'll see the `Create: Virtual Machine` window, opened at the `General` tab.

    ![General tab unfilled at Create VM window](images/g020/debian_vm_create_vm_general_unfilled.png "General tab unfilled at Create VM window")

    From it, only worry about the following parameters:

    - `Node`: in a cluster with several nodes you would need to choose where to put this VM. Since you only have one standalone node, just leave the default value.

    - `VM ID`: a numerical identifier for the VM.
        > **BEWARE!**  
        > Proxmox VE doesn't allow IDs lower than 100.

    - `Name`: this must be a valid DNS name, like `debiantpl` or something longer such as `debiantpl.your.pve.domain`.
        > **BEWARE!**  
        > The official Proxmox VE says that this name is `a free form text string you can use to describe the VM`, which contradicts what the web console actually validates as correct.

    - `Resource Pool`: here you can indicate to which pool of resources (you have none defined at this point) you want to make this VM a member of.

    The only value you need to set here is the name, which in this case could be `debiantpl` (for Debian Template).

    ![General tab filled at Create VM window](images/g020/debian_vm_create_vm_general_filled.png "General tab filled at Create VM window")

3. Click on the `Next` button and you'll reach the `OS` tab.

    ![OS tab unfilled at Create VM window](images/g020/debian_vm_create_vm_os_unfilled.png "OS tab unfilled at Create VM window")

    In this form, you only have to choose the Debian ISO image you uploaded before. The `Guest OS` options are already properly set up for the kind of OS (a Linux distribution) you're going to install in this VM.

    So, be sure of having the `Use CD/DVD disc image file` option enabled, so you can select the proper `Storage` (you should only see here the `hdd_templates` one) and `ISO image` (you just have one ISO right now).

    ![OS tab filled at Create VM window](images/g020/debian_vm_create_vm_os_filled.png "OS tab filled at Create VM window")

4. The next tab you should go to is `System`.

    ![System tab unfilled at Create VM window](images/g020/debian_vm_create_vm_system_unfilled.png "System tab unfilled at Create VM window")

    Here, only tick the `Qemu Agent` box and leave the rest with their default values.

    ![System tab filled at Create VM window](images/g020/debian_vm_create_vm_system_filled.png "System tab filled at Create VM window")

    The `Qemu Agent` option _"lets Proxmox VE know that it can use its features to show some more information, and complete some actions (for example, shutdown or snapshots) more intelligently"_.

5. Hit on `Next` to reach the `Disk` tab.

    ![Disk tab unfilled at Create VM window](images/g020/debian_vm_create_vm_disk_unfilled.png "Disk tab unfilled at Create VM window")

    In this step you have a form in which you can add several storage drives to your VM, but there are certain parameters that you need to see to create a virtual SSD drive. So, enable the `Advanced` checkbox at the bottom of this window and you'll see some extra parameters which I've hightlighted in the next snapshot.

    > **BEWARE!**  
    > The `Advanced` checkbox affects all the steps of this wizard, but not all of those steps have advanced parameters to show.

    ![Disk tab unfilled advanced options](images/g020/debian_vm_create_vm_disk_unfilled_advanced.png "Disk tab unfilled advanced options")

    From the many parameters showing now in this form, just pay attention to the following ones:

    - `Storage`: here you must choose on which storage you will place the disk image of this VM. At this point, in the list you'll only see the thinpools you created in the [**G019** guide](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md).

    - `Disk size (GiB)`: how big you want the main disk for this VM, in gigabytes.

    - `Discard`: since this drive will be put on a thin provisioned storage, you can enable this option so this drive's image get's shrunk when space is marked as freed after removing files within the VM.

    - `SSD emulation`: if your storage is on an SSD drive, (like the `ssd_disks` thinpool), you can turn this on.

    - `IO thread`: with this option enabled, IO activity will have its own CPU thread in the VM, which could improve the VM's performance and also will change the `SCSI Controller` of the drive to _VirtIO SCSI single_.

    > **BEWARE!**  
    > The `Bandwidth` tab allows you to adjust the read/write capabilities of this drive, so only adjust them if you're really sure about how to set them up.

    Knowing all that, choose the `ssd_disks` thinpool as `Storage`, put a small number as `Disk Size` (such as 10 GiB), and enable the `Discard`, `SSD emulation` and `IO thread` options.

    ![Disk tab filled at Create VM window](images/g020/debian_vm_create_vm_disk_filled.png "Disk tab filled at Create VM window")

    This way, you've configured the `scsi0` drive you see listed in the column at the window's left. If you wante to add more drives, click on the `Add` button and a new drive will be added with default values.

6. The next tab to fill is `CPU`. Since you have enabled the `Advanced` checkbox, you'll see the advanced parameters of this and following steps right away.

    ![CPU tab unfilled at Create VM window](images/g020/debian_vm_create_vm_cpu_unfilled.png "CPU tab unfilled at Create VM window")

    The parameters on this tab are very dependant on the real capabilities of your host's CPU. The main parameters you have to care about at this point are:

    - `Sockets`: a way of saying how many CPUs you want to assign to this VM. Just leave it with the default value (`1`).

    - `Cores`: how many cores you want to give to this VM. When unsure on how many to assign, just put `2` here.
        > **BEWARE!**  
        > Never put here a number greater than the real cores count in your CPU, or Proxmox VE won't start your VM!

    - `Type`: this indicates the type of CPU you want to emulate, and the closer it is to the real CPU running your system the better. There's a type `host` which'll make the VM's CPU have exactly the same flags as the real CPU running your Proxmox VE platform, but VMs with such CPU type will only run on CPUs that include the same flags. So, if you migrated such VM to a new Proxmox VE platform that runs on a CPU lacking certain flags expected by the VM, the VM won't run there.

    - `Enable NUMA`: if your host supports [**NUMA**](https://en.wikipedia.org/wiki/Non-uniform_memory_access), enable this option.

    - `Extra CPU Flags`: flags to enable special CPU options on your VM. Only enable the ones actually available in the CPU `Type` you chose, otherwise the VM **won't run**. If you choose the type `Host`, you can see the flags available in your real CPU in the `/proc/cpuinfo` file within your Proxmox VE host.

        ~~~bash
        $ less /proc/cpuinfo
        ~~~

        This file lists the specifications of each core on your CPU. For instance, the first core (called `processor` in the file) on my Intel Pentium J2900 is detailed as follows.

        ~~~properties
        processor       : 0
        vendor_id       : GenuineIntel
        cpu family      : 6
        model           : 55
        model name      : Intel(R) Pentium(R) CPU  J2900  @ 2.41GHz
        stepping        : 8
        microcode       : 0x838
        cpu MHz         : 1440.392
        cache size      : 1024 KB
        physical id     : 0
        siblings        : 4
        core id         : 0
        cpu cores       : 4
        apicid          : 0
        initial apicid  : 0
        fpu             : yes
        fpu_exception   : yes
        cpuid level     : 11
        wp              : yes
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology tsc_reliable nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 movbe popcnt tsc_deadline_timer rdrand lahf_lm 3dnowprefetch epb pti ibrs ibpb stibp tpr_shadow vnmi flexpriority ept vpid tsc_adjust smep erms dtherm ida arat md_clear
        vmx flags       : vnmi preemption_timer invvpid ept_x_only flexpriority tsc_offset vtpr mtf vapic ept vpid unrestricted_guest
        bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only
        bogomips        : 4833.33
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 36 bits physical, 48 bits virtual
        power management:
        ~~~

        The flags available in the CPU are listed on the `flags` line, and below you can see also the `bugs` list.

    Being aware of the capabilities of the real CPU used in this guide series, this form could be filled like shown below.

    ![CPU tab filled at Create VM window](images/g020/debian_vm_create_vm_cpu_filled.png "CPU tab filled at Create VM window")

7. The next tab is `Memory`, also with advanced parameters shown.

    ![Memory tab unfilled at Create VM window](images/g020/debian_vm_create_vm_memory_unfilled.png "Memory tab unfilled at Create VM window")

    The parameters to set here are:

    - `Memory (MiB)`: the maximum amount of RAM this VM will be allowed to use.
    - `Minimum memory (MiB)`: the minimum amount of RAM Proxmox VE must guarantee for this VM.

    If the `Minimum memory` is a different (thus lower) value than the `Memory` one, Proxmox VE will use `Automatic Memory Allocation` to dynamically balance the use of the host RAM among the VMs you may have in your system, which you can also configure with the `Shares` attribute in this form. Better check the documentation to understand [how Proxmox VE handles the VMs' memory](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_memory).

    ![Memory tab filled at Create VM window](images/g020/debian_vm_create_vm_memory_filled.png "Memory tab filled at Create VM window")

    With the arrangement above, the VM will start with 1 GiB and should only be able to take as much as 1.5 GiB from the host's available RAM.

8. The next tab to go to is `Network`, which shows too its advanced parameters.

    ![Network tab default at Create VM window](images/g020/debian_vm_create_vm_network_unfilled.png "Network tab default at Create VM window")

    Notice how the `Bridge` parameter is set by default with the `vmbr0` Linux bridge. We'll come back to this parameter later but, for now, you don't need to configure anything in this step, the default values are correct for this VM.

9. The last tab you'll reach is `Confirm`.

    ![Confirm tab at Create VM window](images/g020/debian_vm_create_vm_confirm.png "Confirm tab at Create VM window")

    Here you'll be able to give a final look to the configuration you've assigned to your new VM before you create it. If you want to readjust something, just click on the proper tab or press `Back` to reach the step you want to change.

    Also notice the `Start after created` check. If enabled, it'll make Proxmox VE boot up your new VM right after its creation.

10. Click on `Finish` and the creation should proceed. Check the `Tasks` log at the bottom of your web console to see its progress.

    ![VM creation on Tasks log](images/g020/debian_vm_create_vm_task_done.png "VM creation on Tasks log")

    Notice how the new VM appear in the `Server View` tree of your PVE node. Click on it to see its `Summary` view, as you can also see in the capture above.

The configuration file for the VM is stored at `/etc/pve/nodes/pve/qemu-server` (notice that **it's relative to the `pve` node**) as `[VM ID].cfg`. So, for this new VM that has the VM ID `100`, the file is `/etc/pve/nodes/pve/qemu-server/100.cfg` and looks like below.

~~~properties
agent: 1
balloon: 1024
boot: order=scsi0;ide2;net0
cores: 2
cpu: host,flags=+md-clear;+spec-ctrl
ide2: hdd_templates:iso/debian-11.1.0-amd64-netinst.iso,media=cdrom
memory: 1512
meta: creation-qemu=6.1.0,ctime=1637241576
name: debiantpl
net0: virtio=CE:AE:AB:C6:8B:7F,bridge=vmbr0,firewall=1
numa: 0
ostype: l26
scsi0: ssd_disks:vm-100-disk-0,discard=on,iothread=1,size=10G,ssd=1
scsihw: virtio-scsi-single
smbios1: uuid=88136df8-90b0-4dc5-9ae7-2b302dd559c9
sockets: 1
vmgenid: 4e4b10c7-f323-48d8-87c7-6a2c4fdc787c
~~~

### _Adding an extra network device to the new VM_

Proxmox VE doesn't allow you to assign, in the VM creation wizard, more than one device of any kind. So, if you want to have an extra network device in your VM, you have to do it **after** you've created the VM in Proxmox VE. And why the extra network device? To allow your future K3s cluster's nodes to communicate directly with each other through the other Linux bridge you already created in the [**G017** guide](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md).

So, let's add that extra network device to your new VM.

1. Go to the `Hardware` tab of your new VM.

    ![Hardware tab at the new VM](images/g020/debian_vm_adding_network_device_hardware_tab.png "Hardware tab at the new VM")

2. Click on `Add` to see the list of devices you can aggregate to the VM, then choose `Network Device`.

    ![Choosing Network Device from Add list](images/g020/debian_vm_adding_network_device_choose_network_device.png "Choosing Network Device from Add list")

3. You'll see that the raised window is exactly the same as the `Network` tab you saw while creating the VM.

    ![Adding a new network device to the VM](images/g020/debian_vm_adding_network_device.png "Adding a new network device to the VM")

    You have to adjust two fields:

    - `Bridge` parameter: here you must set the `vmbr1` bridge.

    - `Firewall` checkbox: since this network device is strictly meant for internal networking, you won't need the firewall active here. Disable this checkbox.

    ![Changing bridge of new network device](images/g020/debian_vm_adding_network_device_changing_bridge.png "Changing bridge of new network device")

4. Click on `Add` and you'll see that the new network device appears immediately as `net1` at the end of your VM's hardware list.

    ![Hardware list updated with new network device](images/g020/debian_vm_adding_network_device_hardware_updated.png "Hardware list updated with new network device")

### _Installing Debian on the new VM_

At this point, your new VM has the minimal virtual hardware setup you need for installing Debian in it.

1. Go back to the `Summary` tab of your new VM and press the `Start` button to start the VM up.

    ![VM Start button](images/g020/debian_vm_install_os_start_button.png "VM Start button")

    Right after it, click on the `>_ Console` button to raise a `noVNC` shell window.

2. In the `noVCN` shell window you should see the following screen.

    ![Debian installer menu](images/g020/debian_vm_install_os_installer_menu.png "Debian installer menu")

3. In this menu, you **must** choose the `Install` option to run the installation of Debian in text mode.

    ![Install option chosen](images/g020/debian_vm_install_os_installer_install_option.png "Install option chosen")

4. The next screen will ask you about what language you want to use in the installation process and apply to the installed system.

    ![Choosing system language](images/g020/debian_vm_install_os_installer_choosing_language.png "Choosing system language")

    Just choose whatever suits you and press `Enter`.

5. The following step is about your geographical location. This will determine your VM's timezone and locale.

    ![Choosing system geographical location](images/g020/debian_vm_install_os_installer_choosing_location.png "Choosing system geographical location")

    Again, highlight whatever suits you and press `Enter`.

6. If you choose an unexpected combination of language and location, the installer will ask you about what locale to apply on your system.

    ![Configuring system locales](images/g020/debian_vm_install_os_installer_choosing_locales.png "Configuring system locales")

    Oddly enough, it only shows the options you see in the screenshot above so, in case of doubt, just stick with the default `United States - en_US.UTF-8` option.

7. Next, you'll have to choose the keyboard configuration that suits you better.

    ![Configuring the keyboard](images/g020/debian_vm_install_os_installer_configuring_keyboard.png "Configuring the keyboard")

8. At this point it will show some progress bars while the installer retrieves components and scans the VM hardware.

    ![Intaller loading componentes](images/g020/debian_vm_install_os_installer_loading_components.png "Intaller loading componentes")

9. After some seconds you'll end seeing the following screen about the network configuration.

    ![Choosing network card](images/g020/debian_vm_install_os_installer_configuring_network_choosing_network_device.png "Choosing network card")

    Since this VM has two virtual ethernet network cards, the installer must know which one to use as the primary network device. Leave the default option (the card with the lowest `ens##` number) and press `Enter`.

10. Next, you'll see how the installer tries to setup the network in a few progress bars.

    ![Configuring the network with DHCP](images/g020/debian_vm_install_os_installer_configuring_network_with_dhcp.png "Configuring the network with DHCP")

11. If the previous network autosetup process is successful, you'll end up in the following screen.

    ![Hostname input screen](images/g020/debian_vm_install_os_installer_hostname_input.png "Hostname input screen")

    In the text box, type in the `hostname` for this system, bearing in mind that this VM will become just a template to build others. Preferably, input the same name you used previously in the creation of the VM, which in this guide was `debiantpl`.

12. In the next step you'll have to specify a domain name.

    ![Domain name input screen](images/g020/debian_vm_install_os_installer_domain_name_input.png "Domain name input screen")

    Here use the same one you set for your Proxmox VE system.

13. The following screen is about setting up the password for the `root` user.

    ![Setting up root password](images/g020/debian_vm_install_os_installer_setting_root_password.png "Setting up root password")

    Since this VM is going to be just a template, there's no need for you to type a difficult or long password.

14. The installer will ask you to confirm the `root` password.

    ![Confirming root password](images/g020/debian_vm_install_os_installer_setting_root_password_confirmation.png "Confirming root password")

15. The next step is about creating a new user that you should use instead of the `root` one.

    ![Creating new admin user](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_full_name.png "Creating new admin user")

    In this screen you are expected to type the new user's full name, but since this is going to be your administrative one, input something more generic like `System Manager User` for instance.

16. The following screen is about typing a username for the new user.

    ![Setting the new user's username](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_username.png "Setting the new user's username")

    By default, the installer will take the first word you set in the full name and use it (in lowercase) as username. In this guide, this user will be called `mgrsys`, following the same criteria used for creating the alternative manager user for the Proxmox VE host.

17. On this step you input the password for this new user. Again, since this VM is going to be a template, don't put a complex password here.

    ![Setting password for new user](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_password.png "Setting password for new user")

18. You'll have to confirm the new user's password.

    ![Confirmation of new user's password](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_password_confirmation.png "Confirmation of new user's password")

19. This step might not show up in your case, but it's just about choosing the right timezone within the country you chose before.

    ![Choosing timezone](images/g020/debian_vm_install_os_installer_choosing_timezone.png "Choosing timezone")

20. After seeing a few more loading bars, you'll reach the step regarding the disk partitioning.

    ![Disk partitioning options screen](images/g020/debian_vm_install_os_installer_disk_partitioning.png "Disk partitioning options screen")

    Be sure of choosing the **SECOND** guided option to give the VM's disk a more flexible partition structure with the LVM system, like the one you have in your Proxmox VE host.

    ![Second option chosen at disk partitioning](images/g020/debian_vm_install_os_installer_disk_partitioning_second_option_chosen.png "Second option chosen at disk partitioning")

21. The following screen is about choosing the storage drive to partition.

    ![Choosing disk for partitioning](images/g020/debian_vm_install_os_installer_disk_partitioning_choose_drive.png "Choosing disk for partitioning")

    There's only one disk attached to this VM, so there's no other option but the one shown.

22. Next, the installer will ask you about how to set up the `home` and other directories.

    ![Partition setup for home directory](images/g020/debian_vm_install_os_installer_disk_partitioning_home_setup.png "Partition setup for home directory")

    This VM is going to be a template for servers, so you shouldn't ever need to mount a separate partition for the `home` directory. Something else could be said about the `var` or the `tmp` directories, whose contents can grow notably. But, since you can increase the size of the VM's storage easily from Proxmox VE, just leave the default highlighted option and press `Enter`.

23. The next screen is the confirmation of the disk partitioning you've setup in the previous steps.

    ![Disk partitioning confirmation screen](images/g020/debian_vm_install_os_installer_disk_partitioning_confirmation.png "Disk partitioning confirmation screen")

    If you are sure that the partition setup is what you wanted, highlight `Yes` and press `Enter`.

24. The following step asks you about the size assigned to the LVM group in which the system partitions are going to be created.

    ![LVM group size](images/g020/debian_vm_install_os_installer_disk_partitioning_lvm_group_size.png "LVM group size")

    Unless you know better, just stick with the default value and move on.

25. After a few loading screens, you'll reach the disk partitioning final confirmation screen.

    ![Disk partitioning final confirmation screen](images/g020/debian_vm_install_os_installer_disk_partitioning_final_confirmation.png "Disk partitioning final confirmation screen")

    Choose `Yes` to allow the installer to finally write the changes to disk.

26. After the partitioning is finished, you'll reach the progress bar of the base system installation.

    ![Installing the base system screen](images/g020/debian_vm_install_os_installer_base_system_installation.png "Installing the base system screen")

    The installer will take a bit in finishing this task.

27. When the base system is installed, you'll see the following screen.

    ![Additional media scan screen](images/g020/debian_vm_install_os_installer_additional_media.png "Additional media scan screen")

    You don't have any additional media to use, so just answer `No` to this screen.

28. The following step is about setting the right mirror servers location for your `apt` configuration.

    ![Mirror servers location screen](images/g020/debian_vm_install_os_installer_package_manager_mirrors_location.png "Mirror servers location screen")

    By default, the option highlighted will be the same country you chose at the beginning of this installation. Chose the country that suits you best.

29. The next screen is about choosing a concrete mirror server for your `apt` settings.

    ![Choosing apt mirror server screen](images/g020/debian_vm_install_os_installer_package_manager_choosing_mirror_server.png "Choosing apt mirror server screen")

    Stick with the default option, or change it if you identify a better alternative for you in the list.

30. A window will arise asking you to input your `HTTP proxy information`, if you happen to be connecting through one.

    ![HTTP proxy information screen](images/g020/debian_vm_install_os_installer_package_manager_proxy.png "HTTP proxy information screen")

    In this guide it's assumed that you're not using a proxy, so that field should be left blank.

31. The installer will take a bit while configuring the VM's `apt` system.

    ![Autoconfiguration of apt system](images/g020/debian_vm_install_os_installer_package_manager_autoconfiguring_apt.png "Autoconfiguration of apt system")

32. When the `apt` configuration has finished, you'll see the following question about allowing some script to get some usage statistics of packages on your system.

    ![Popularity contest question screen](images/g020/debian_vm_install_os_installer_package_manager_popularity_contest.png "Popularity contest question screen")

    Choose whatever you like here, although bear in mind that the security restrictions that you'll have to apply later to this Debian VM system may end blocking that script's functionality.

33. After another loading bar, you'll reach the `Software selection` screen.

    ![Software selection screen](images/g020/debian_vm_install_os_installer_software_selection.png "Software selection screen")

    You'll see that, by default, the installer is setting the VM to be a graphical environment. You only need the two last options enabled (`SSH server` and `standard system utilities`), so change them so they look like below and then press `Continue`.

    ![Software selection changed](images/g020/debian_vm_install_os_installer_software_selection_changed.png "Software selection changed")

34. Another progress windows will show up and the installer will proceed with the remainder of the installation process.

    ![Installation progress bar](images/g020/debian_vm_install_os_installer_executing_installation.png "Installation progress bar")

35. In the installation process, the installer will ask you if you want to install the GRUB boot loader in the VM's primary storage drive.

    ![GRUB boot loader installation screen](images/g020/debian_vm_install_os_installer_grub_boot_loader.png "GRUB boot loader installation screen")

    The default `Yes` option is the correct one, so just press `Enter` on this screen.

36. Next, the installer will ask you on which drive you want to install GRUB.

    ![GRUB boot loader installation location screen](images/g020/debian_vm_install_os_installer_grub_boot_loader_disk.png "GRUB boot loader installation location screen")

    Highlight the `/dev/sda` option and press `Enter` to continue the process.

    ![GRUB boot loader disk sda chosen](images/g020/debian_vm_install_os_installer_grub_boot_loader_disk_sda_chosen.png "GRUB boot loader disk sda chosen")

37. After installing the GRUB boot loader, you'll see for a few seconds how the installer finishes the process.

    ![Finishing the installation screen](images/g020/debian_vm_install_os_installer_finishing_installation.png "Finishing the installation screen")

38. After the installation has finished, the installer will warn you about removing the media you used to launch the whole procedure.

    ![Remove installer media screen](images/g020/debian_vm_install_os_installer_remove_media.png "Remove installer media screen")

    > **BEWARE!**  
    > Keep calm, **DON'T** press `Enter` yet and read the following steps.

    If you `Continue`, the VM will reboot and, if the installer media is still in place, the installer will boot up again.

39. Go back to your Proxmox VE web console, and open the `Hardware` tab of your VM. Then, choose the `CD/DVD Drive` item and press the `Edit` button.

    ![Edit button on VM's hardware tab](images/g020/debian_vm_install_os_vm_hardware_tab_edit_button.png "Edit button on VM's hardware tab")

40. You'll see the Edit window for the `CD/DVD Drive` you chose.

    ![Edit window for CD/DVD Drive](images/g020/debian_vm_install_os_vm_hardware_tab_edit_window.png "Edit window for CD/DVD Drive")

    Here, choose the `Do not use any media` option and click on `OK`.

    ![Option changed at Edit window for CD/DVD Drive](images/g020/debian_vm_install_os_vm_hardware_tab_edit_window_changed.png "Option changed at Edit window for CD/DVD Drive")

41. Back in the Hardware screen, you'll see how the CD/DVD Drive is now set to `none`.

    ![CD/DVD Drive empty on VM's Hardware tab](images/g020/debian_vm_install_os_vm_hardware_tab_cdrom_updated.png "CD/DVD Drive empty on VM's Hardware tab")

    > **BEWARE!**  
    > This doesn't mean that the change has been applied to the still running VM. Usually, changes like these will require a reboot of the VM.

42. Now that the VM's CD/DVD Drive is configured to be empty, you can go back to the noVNC shell and press on `Enter` to finish the Debian installation. If everything goes as it should, the VM will reboot into the GRUB screen of your newly installed Debian system.

    ![GRUB boot loader screen](images/g020/debian_vm_install_os_vm_rebooted_grub.png "GRUB boot loader screen")

43. Press Enter with the default highlighted option or allow the timer to reach `0`. Then, after the usual system booting shell output, you should reach the login.

    ![Debian login](images/g020/debian_vm_install_os_debian_login.png "Debian login")

44. As a final verification, login either with `root` or with `mgrsys` to check that they work as expected.

## Note about the VM's `Boot Order` option

Go to the `Options` tab of your new Debian VM.

![VM Options tab](images/g020/debian_vm_note_option_boot_order_options_tab.png "VM Options tab")

In the capture above, you can see highlighted the `Boot Order` list currently enabled in this VM. If you press on the `Edit` button, you'll be able to edit this `Boot Order` list.

![Edit Boot Order option window](images/g020/debian_vm_note_option_boot_order_edit_window.png "Edit Boot Order option window")

Notice how PVE has already enabled the bootable hardware devices (hard disk, CD/DVD drive and network device) that were configured in the VM creation process. Also see how the network device added later, `net1`, is **NOT** enabled by default.

> **BEWARE!**  
> When you modify the bootable hardware devices of a VM, Proxmox VE **WON'T** enable automatically any new bootable device in the `Boot Order` list. You must revise or modify it whenever you make changes to the hardware devices available in a VM.

## Relevant system paths

### _Directories_

- `/etc/pve`
- `/etc/pve/nodes/pve/qemu-server`

### _Files_

- `/etc/pve/user.cfg`
- `/etc/pve/nodes/pve/qemu-server/100.cfg`

## References

### _Debian_

- [Debian](https://www.debian.org/)
- [How to Install a Debian 10 (Buster) Minimal Server](https://www.howtoforge.com/tutorial/debian-minimal-server/)

### _Virtual Machines on Proxmox VE_

- [PVE admin guide. Qemu/KVM Virtual Machines](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_virtual_machines)
- [PVE admin guide. User management. Pools](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pveum_pools)
- [PVE admin guide. Qemu/KVM Virtual Machines ~ CPU options](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_cpu)
- [PVE admin guide. Qemu/KVM Virtual Machines ~ Memory options](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_memory)
- [PVE admin guide. Qemu/KVM Virtual Machines ~ Network Device options](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_network_device)
- [Best practices on setting up Proxmox on a new server](https://www.reddit.com/r/Proxmox/comments/oz81qq/best_practices_on_setting_up_proxmox_on_a_new/)
