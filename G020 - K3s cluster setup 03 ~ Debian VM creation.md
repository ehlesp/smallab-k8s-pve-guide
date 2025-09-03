# G020 - K3s cluster setup 03 ~ Debian VM creation

- [You can start creating VMs in your Proxmox VE server](#you-can-start-creating-vms-in-your-proxmox-ve-server)
- [Preparing the Debian ISO image](#preparing-the-debian-iso-image)
  - [Obtaining the latest stable Debian ISO image](#obtaining-the-latest-stable-debian-iso-image)
  - [Storing the ISO image in the Proxmox VE platform](#storing-the-iso-image-in-the-proxmox-ve-platform)
- [Building a Debian virtual machine](#building-a-debian-virtual-machine)
  - [Setting up a new virtual machine](#setting-up-a-new-virtual-machine)
  - [Adding an extra network device to the new VM](#adding-an-extra-network-device-to-the-new-vm)
  - [Installing Debian on the new VM](#installing-debian-on-the-new-vm)
- [Note about the VM's `Boot Order` option](#note-about-the-vms-boot-order-option)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Debian](#debian)
  - [Virtual Machines on Proxmox VE](#virtual-machines-on-proxmox-ve)
  - [Units of measurement for storage](#units-of-measurement-for-storage)
- [Navigation](#navigation)

## You can start creating VMs in your Proxmox VE server

Your Proxmox VE system is now configured well enough for you to start creating the virtual machines you require in it. This chapter will show you how to create a rather generic VM with Debian. This Debian VM will be the base over which you'll build, in the following chapters, a more specialized VM template for your K3s cluster's nodes.

## Preparing the Debian ISO image

Since the operative system chosen to build the VMs is Debian Linux, first you need to get its ISO and store it in your Proxmox VE server.

### Obtaining the latest stable Debian ISO image

At the time of writing this, the latest stable version of Debian is [**13.0.0 "trixie"**](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso).

You can find the _net install_ version of the ISO for the latest Debian version right at the [Debian project's webpage](https://www.debian.org/):

![Debian project main's webpage](images/g020/debian_netinstall_iso_download.webp "Debian project's main webpage")

After clicking on that big `Download` button, your browser should start downloading the `debian-13.0.0-amd64-netinst.iso` file.

### Storing the ISO image in the Proxmox VE platform

Proxmox VE needs that ISO image saved in the proper storage space it has available to be able to use it. Therefore, you need to upload the `debian-13.0.0-amd64-netinst.iso` file to the storage space you configured to hold such files, the one called `hdd_templates`:

1. Open the web console and unfold the tree of available storages under your `pve` node. Click on `hdd_templates` to reach its `Summary` page:

    ![Summary of templates storage](images/g020/pve_templates_storage_summary.webp "Summary of templates storage")

2. Click on the `ISO Images` tab, and you'll see the page of available ISO images:

    ![ISO images list empty](images/g020/pve_templates_storage_images_list_empty.webp "ISO images list empty")

    You'll find it empty at this point.

3. Click on the `Upload` button to raise the dialog below:

    ![ISO image upload dialog](images/g020/pve_templates_storage_iso_upload_dialog.webp "ISO image upload dialog")

    > [!NOTE]
    > **Ensure having enough free storage available in your Proxmox VE's root filesystem before uploading files**\
    > Notice the warning about where Proxmox VE temporarily stores the file you upload before moving it to its definitive place. The `/var/tmp/` path lays in the root filesystem of your PVE server, so be sure of having enough room in it or the upload will fail.

4. Click on `Select File`, find and select your `debian-13.0.0-amd64-netinst.iso` file in your computer, then click on `Upload`. The same dialog will show the upload progress:

    ![ISO image upload dialog in progress](images/g020/pve_templates_storage_iso_upload_dialog_in_progress.webp "ISO image upload dialog in progress")

    When the upload is finished, Proxmox VE will show you another dialog with the result of the task that moves the ISO file from the `/var/tmp/` PVE system path to the `hdd_templates` storage:

    ![ISO image copy data task dialog result OK](images/g020/pve_templates_storage_iso_upload_copy_task_ok.webp "ISO image copy data task dialog result OK")

5. Close the Task viewer dialog to return to the `ISO Images` page. You will see that the list now shows your newly uploaded Debian ISO image:

    ![ISO images list updated](images/g020/pve_templates_storage_images_list_updated.webp "ISO images list updated")

    Notice how the ISO is only identified by its file name. Sometimes ISOs don't have detailed names like the one for the Debian distribution, so be sure of giving the ISOs you upload meaningful and unique names to tell them apart.

6. Finally, you can check out in the `hdd_templates` storage's `Summary` how much space you have left (`Usage` field):

    ![Summary of templates storage updated](images/g020/pve_templates_storage_summary_updated.webp "Summary of templates storage updated")

Now you only have one ISO image but, over time, you may accumulate a number of them. Be mindful of the free space you have left, and prune old images or container templates you are not using anymore.

## Building a Debian virtual machine

In this section you'll see how to create a basic and lean Debian VM, then how to turn it into a VM template.

### Setting up a new virtual machine

First, you need to create and configure a new VM:

1. Click on the `Create VM` button found at the web console's top right:

    ![Create VM button](images/g020/debian_vm_create_vm_button.webp "Create VM button")

2. You'll see the `Create: Virtual Machine` window, opened at the `General` tab:

    ![General tab unfilled at Create VM window](images/g020/debian_vm_create_vm_general_unfilled.webp "General tab unfilled at Create VM window")

    From it, only worry about the following parameters:

    - `Node`\
      In a cluster with several nodes you would need to choose where to put this VM. Since you only have one standalone node, just leave the default `pve` value.

    - `VM ID`\
      A numerical identifier for the VM.

      > [!NOTE]
      > Proxmox VE does not allow IDs lower than `100`.

    - `Name`\
      This field must be a valid DNS name, like `debiantpl` or something longer such as `debiantpl.homelab.cloud`.

      > [!NOTE]
      > The official Proxmox VE says that this name is `a free form text string you can use to describe the VM`, which contradicts what the web console actually validates as correct.

    - `Resource Pool`\
      Here you can indicate to which pool of resources (you have none defined at this point) you want to make this VM a member of.

    The only value you really need to set here is the name, which in this case it could be `debiantpl` (for Debian Template).

    ![General tab filled at Create VM window](images/g020/debian_vm_create_vm_general_filled.webp "General tab filled at Create VM window")

3. Click on the `Next` button and you'll reach the `OS` tab:

    ![OS tab unfilled at Create VM window](images/g020/debian_vm_create_vm_os_unfilled.webp "OS tab unfilled at Create VM window")

    In this form, you only have to choose the Debian ISO image you uploaded before. The `Guest OS` options are already properly set up for the kind of OS (a Linux distribution) you're going to install in this VM.

    Therefore, be sure of having the `Use CD/DVD disc image file` option enabled, then select the proper `Storage` (you should only see here the `hdd_templates` one) and `ISO image` (you just have one ISO right now).

    ![OS tab filled at Create VM window](images/g020/debian_vm_create_vm_os_filled.webp "OS tab filled at Create VM window")

4. The next tab you should go to is `System`:

    ![System tab unfilled at Create VM window](images/g020/debian_vm_create_vm_system_unfilled.webp "System tab unfilled at Create VM window")

    Here, only tick the `Qemu Agent` checkbox and leave the rest with their default values.

    ![System tab filled at Create VM window](images/g020/debian_vm_create_vm_system_filled.webp "System tab filled at Create VM window")

    The QEMU agent _"lets Proxmox VE know that it can use its features to show some more information, and complete some actions (for example, shutdown or snapshots) more intelligently"_.

5. Hit on `Next` to reach the `Disks` tab:

    ![Disks tab unfilled at Create VM window](images/g020/debian_vm_create_vm_disk_unfilled.webp "Disks tab unfilled at Create VM window")

    In this step you have a form in which you can add several storage drives to your VM, but there are certain parameters that you need to see to create a virtual SSD drive. So, enable the `Advanced` checkbox at the bottom of this window and you'll get some extra parameters which I've highlighted in the next snapshot:

    > [!NOTE]
    > Although the `Advanced` checkbox appears in all the steps of this wizard, not all of those steps have advanced parameters to offer.

    ![Disks tab unfilled advanced options](images/g020/debian_vm_create_vm_disk_unfilled_advanced.webp "Disks tab unfilled advanced options")

    From the many parameters showing now in this form, just pay attention to the following ones:

    - `Storage`\
      Here you must choose on which storage you will place the disk image of this VM. At this point, in the list you'll only see the thinpools you created in the [**G019** chapter](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md).

    - `Disk size (GiB)`\
      How big you want the main disk for this VM, [in gibibytes](https://en.wikipedia.org/wiki/Gigabyte#Base_2_(binary)).

    - `Discard`\
      Since this drive will be put on a thin provisioned storage, you can enable this option to make this drive's image get shrunk when space is marked as freed after removing files within the VM.

    - `SSD emulation`\
      If your storage is on an SSD drive, (like the `ssd_disks` thinpool), you can turn this on.

    - `IO thread`\
      With this option enabled, IO activity will have its own CPU thread in the VM, which could improve the VM's performance and also sets the `SCSI Controller` of the drive to _VirtIO SCSI single_.

    - `Async IO`\
      The official documentation does not explain this value, but it can be summarized as the way to choose which method to use for asynchronous IO.

      > [!NOTE]
      > [Know more about the async IO property in this Proxmox Forum thread](https://forum.proxmox.com/threads/async-io-settings-for-virtual-disks-documentation-how-to-set.114932/).

    > [!IMPORTANT]
    > **The `Bandwidth` tab allows you to adjust the read/write capabilities of the storage drive**\
    > Only adjust the bandwidth options if you are really sure about how to set them up.

    Knowing all this, choose the `ssd_disks` thinpool as `Storage`, put a small number as `Disk Size` (such as 10 GiB), and ensure to enable the `Discard` and `SSD emulation` options. Leave the `IO thread` option enabled (as it is by default), and do not change the default value already set in the `Async IO` parameter. Do not change any of the remaining parameters in this dialog.

    ![Disks tab filled at Create VM window](images/g020/debian_vm_create_vm_disk_filled.webp "Disks tab filled at Create VM window")

    This way, you've configured the `scsi0` drive you see listed in the column at the window's left. If you want to add more drives, click on the `Add` button and a new drive will be added with default values.

6. The next tab to fill is `CPU`. Since you have enabled the `Advanced` checkbox in the previous `Disks` tab, you'll see the advanced parameters of this and following steps right away:

    ![CPU tab unfilled at Create VM window](images/g020/debian_vm_create_vm_cpu_unfilled.webp "CPU tab unfilled at Create VM window")

    The parameters on this tab are very dependant on the real capabilities of your host's CPU. The main parameters you have to care about at this point are:

    - `Sockets`\
      A way of saying how many CPUs you want to assign to this VM. Just leave it with the default value (`1`).

    - `Cores`\
      How many cores you want to give to this VM. When unsure on how many to assign, just put `2` here.

      > [!IMPORTANT]
      > Never put here a number greater than the real cores count in your CPU, or Proxmox VE won't start your VM!

    - `Type`\
      This indicates the type of CPU you want to emulate, and the closer it is to the real CPU running your system the better. There's a type `host` which'll make the VM's CPU have exactly the same flags as the real CPU running your Proxmox VE platform, but VMs with that `host` CPU type will only run on CPUs that include the same flags. So, if you migrated such VM to a new Proxmox VE platform that runs on a CPU lacking certain flags expected by the VM, the VM won't run there.

    - `Enable NUMA`\
      If your host supports [**NUMA**](https://en.wikipedia.org/wiki/Non-uniform_memory_access), enable this option.

    - `Extra CPU Flags`\
      Flags to enable special CPU options on your VM. Only enable the ones actually available in the CPU `Type` you chose, otherwise the VM **won't run**. If you choose the type `Host`, you can see the flags available in your real CPU in the `/proc/cpuinfo` file within your Proxmox VE host.

        ~~~sh
        $ less /proc/cpuinfo
        ~~~

        This file lists the specifications of each core on your CPU. For instance, the first core (called `processor` in the file) on the host where I'm running this guide's whole Proxmox VE setup is detailed as follows:

        ~~~properties
        processor       : 0
        vendor_id       : GenuineIntel
        cpu family      : 6
        model           : 55
        model name      : Intel(R) Celeron(R) CPU  J1900  @ 1.99GHz
        stepping        : 8
        microcode       : 0x838
        cpu MHz         : 2211.488
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
        flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology tsc_reliable nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 movbe popcnt tsc_deadline_timer rdrand lahf_lm 3dnowprefetch epb pti ibrs ibpb stibp tpr_shadow flexpriority ept vpid tsc_adjust smep erms dtherm ida arat vnmi md_clear
        vmx flags       : vnmi preemption_timer invvpid ept_x_only flexpriority tsc_offset vtpr mtf vapic ept vpid unrestricted_guest
        bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only mmio_unknown
        bogomips        : 4000.00
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 36 bits physical, 48 bits virtual
        power management:
        ~~~

        The flags available in the CPU are listed on the `flags`, `vmx flags` and `bugs` lists.

    Being aware of the capabilities of the real CPU used to run the Proxmox VE VM used in this guide, this form is filled like this:

    ![CPU tab filled at Create VM window](images/g020/debian_vm_create_vm_cpu_filled.webp "CPU tab filled at Create VM window")

7. The next tab is `Memory`, also with advanced parameters shown:

    ![Memory tab unfilled at Create VM window](images/g020/debian_vm_create_vm_memory_unfilled.webp "Memory tab unfilled at Create VM window")

    The parameters to set in this dialog are:

    - `Memory (MiB)`\
      The maximum amount of RAM this VM will be allowed to use.

    - `Minimum memory (MiB)`\
      The minimum amount of RAM Proxmox VE must guarantee for this VM.

    If the `Minimum memory` is a different (thus lower) value than the `Memory` one, Proxmox VE will use `Automatic Memory Allocation` to dynamically balance the use of the host RAM among the VMs you may have in your system, which you can also configure with the `Shares` attribute in this form. Better check the documentation to understand [how Proxmox VE handles the VMs' memory](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_memory).

    ![Memory tab filled at Create VM window](images/g020/debian_vm_create_vm_memory_filled.webp "Memory tab filled at Create VM window")

    With the arrangement above, the VM will start with 1 GiB and will only be able to take as much as 2 GiB from the host's available RAM.

8. The next tab to go to is `Network`, which also has advanced parameters:

    ![Network tab default at Create VM window](images/g020/debian_vm_create_vm_network_unfilled.webp "Network tab default at Create VM window")

    Notice how the `Bridge` parameter is set by default with the `vmbr0` Linux bridge. You will come back to this parameter later but, for now, you don't need to configure anything in this step, the default values are correct for this Debian template VM.

9. The last tab you'll reach is `Confirm`:

    ![Confirm tab at Create VM window](images/g020/debian_vm_create_vm_confirm.webp "Confirm tab at Create VM window")

    Here you'll be able to give a final look to the configuration you've assigned to your new VM before you create it. If you want to readjust something, just click on the proper tab or press `Back` to reach the step you want to change.

    Also notice the `Start after created` check. Do NOT enable it, since it'll make Proxmox VE boot up your new VM right after its creation, something you don't want at this point.

10. Click on `Finish` and the creation should proceed. Check the `Tasks` log at the bottom of your web console to see its progress:

    ![VM creation on Tasks log](images/g020/debian_vm_create_vm_task_done.webp "VM creation on Tasks log")

    Notice how the new VM appears in the `Server View` tree of your PVE node. Click on it to see its `Summary` view as shown in the capture above.

The configuration file for the new VM is stored at `/etc/pve/nodes/pve/qemu-server` (notice that **it is related to the `pve` node**) as `[VM ID].conf`. So, for this new VM that has the VM ID `100`, the file is `/etc/pve/nodes/pve/qemu-server/100.conf`:

~~~properties
agent: 1
balloon: 1024
boot: order=scsi0;ide2;net0
cores: 2
cpu: host
ide2: hdd_templates:iso/debian-13.0.0-amd64-netinst.iso,media=cdrom,size=754M
memory: 2048
meta: creation-qemu=10.0.2,ctime=1756890694
name: debiantpl
net0: virtio=BC:24:11:3E:B9:39,bridge=vmbr0,firewall=1
numa: 0
ostype: l26
scsi0: ssd_disks:vm-100-disk-0,discard=on,iothread=1,size=10G,ssd=1
scsihw: virtio-scsi-single
smbios1: uuid=8fce9b8d-d716-4e7b-9817-3d727b40eb9f
sockets: 1
vmgenid: 08b95c71-2feb-4338-8970-c3cfba8a6e94
~~~

### Adding an extra network device to the new VM

In the VM creation wizard, Proxmox VE does not allow you to configure more than one network device. To add an extra network device in your VM, **you have to do it after you've created the VM in Proxmox VE**. And why the extra network device? To allow your future K3s cluster's nodes to communicate directly with each other through the other Linux bridge you already created in the [**G017** chapter](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md). Let's add that extra network device to your new Debian 12 template VM.

1. Go to the `Hardware` tab of your new VM:

    ![Hardware tab at the new VM](images/g020/debian_vm_adding_network_device_hardware_tab.webp "Hardware tab at the new VM")

2. Click on `Add` to see the list of devices you can aggregate to the VM, then choose `Network Device`:

    ![Choosing Network Device from Add list](images/g020/debian_vm_adding_network_device_choose_network_device.webp "Choosing Network Device from Add list")

3. You'll see that the raised window is exactly the same as the `Network` tab you saw while creating the VM:

    ![Adding a new network device to the VM](images/g020/debian_vm_adding_network_device.webp "Adding a new network device to the VM")

    Notice that the `Advanced` options are also enabled, probably because the Proxmox VE web administration remembers that check as enabled from the creation wizard. Here you have to adjust only two parameters:

    - `Bridge`\
      You must set the `vmbr1` bridge.

    - `Firewall`\
      Since this network device is strictly meant for internal networking, you won't need the firewall active here. Disable this checkbox.

    ![Changing bridge of new network device](images/g020/debian_vm_adding_network_device_changing_bridge.webp "Changing bridge of new network device")

4. Click on `Add` and you'll see that the new network device appears immediately as `net1` at the end of your VM's hardware list:

    ![Hardware list updated with new network device](images/g020/debian_vm_adding_network_device_hardware_updated.webp "Hardware list updated with new network device")

### Installing Debian on the new VM

At this point, your Debian template VM has the minimal virtual hardware setup you need for installing Debian in it.

1. Go back to the `Summary` tab of your new VM and press the `Start` button to start the VM up:

    ![VM Start button](images/g020/debian_vm_install_os_start_button.webp "VM Start button")

    Right after starting the VM, click on the `>_ Console` button to raise a `noVNC` shell window.

2. In the `noVCN` shell window, you should end up seeing the Debian installer boot menu:

    ![Debian installer menu](images/g020/debian_vm_install_os_installer_menu.webp "Debian installer menu")

3. In this menu, **you must choose the `Install` option** to run the installation of Debian in text mode:

    ![Install option chosen](images/g020/debian_vm_install_os_installer_install_option.webp "Install option chosen")

    It will take a few seconds to load the next step's screen.

4. The next screen asks you about what language you want to use in the installation process and apply to the installed system:

    ![Choosing system language](images/g020/debian_vm_install_os_installer_choosing_language.webp "Choosing system language")

    Just choose whatever suits you and press `Enter`.

5. The following step is about your geographical location. This will determine your VM's timezone and locale:

    ![Choosing system geographical location](images/g020/debian_vm_install_os_installer_choosing_location.webp "Choosing system geographical location")

    Again, highlight whatever suits you and press `Enter`.

6. If you choose an unexpected combination of language and location, the installer will ask you about what locale to apply on your system:

    ![Configuring system locales](images/g020/debian_vm_install_os_installer_choosing_locales.webp "Configuring system locales")

    Oddly enough, it only offers the options shown in the screenshot above. In case of doubt, just stick with the default `United States - en_US.UTF-8` option.

7. Next, you'll have to choose the keyboard configuration that suits you better:

    ![Configuring the keyboard](images/g020/debian_vm_install_os_installer_configuring_keyboard.webp "Configuring the keyboard")

8. At this point it will show some progress bars while the installer retrieves additional components and scans the VM's hardware:

    ![Installer loading componentes](images/g020/debian_vm_install_os_installer_loading_components.webp "Installer loading componentes")

9. After a few seconds you'll reach the screen about configuring the network:

    ![Choosing network card](images/g020/debian_vm_install_os_installer_configuring_network_choosing_network_device.webp "Choosing network card")

    Since this VM has two virtual Ethernet network cards, the installer must know which one to use as the primary network device. Leave the default option (the card with the lowest `ens##` number, like the `ens18` in the snapshot) and press `Enter`.

10. Next, you'll see how the installer tries to setup the network in a few progress bars:

    ![Configuring the network with DHCP](images/g020/debian_vm_install_os_installer_configuring_network_with_dhcp.webp "Configuring the network with DHCP")

11. If the previous network autosetup process is successful, you'll end up in the following screen:

    ![Hostname input screen](images/g020/debian_vm_install_os_installer_hostname_input.webp "Hostname input screen")

    In the text box, type in the `hostname` for this system, bearing in mind that this VM will become just a template to build others. Preferably, input the same name you used previously in the creation of the VM, which in this guide is `debiantpl`.

12. In the next step you'll have to specify a domain name:

    ![Domain name input screen](images/g020/debian_vm_install_os_installer_domain_name_input.webp "Domain name input screen")

    Here use the same one you set for your Proxmox VE system, which in this guide is `homelab.cloud`.

13. The following screen is about setting up the password for the `root` user:

    ![Setting up root password](images/g020/debian_vm_install_os_installer_setting_root_password.webp "Setting up root password")

    Since this VM is going to be just a template, there's no need here for you to type a difficult or long password.

14. The installer will ask you to confirm the `root` password:

    ![Confirming root password](images/g020/debian_vm_install_os_installer_setting_root_password_confirmation.webp "Confirming root password")

15. The next step is about creating a new user that you should use instead of the `root` one:

    ![Creating new admin user](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_full_name.webp "Creating new admin user")

    In this screen you are expected to type the new user's full name, but since this is going to be your administrative one, input something more generic like `System Manager` for instance.

16. The following screen is about typing a username for the new user:

    ![Setting the new user's username](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_username.webp "Setting the new user's username")

    By default, the installer will take the first word you set as the user's full name and use it (in lowercase) as username. In this guide, this user will be called `mgrsys`, following the same criteria used for creating the alternative manager user for the Proxmox VE host.

17. On this step you input the password for this new administrative user. Again, since this VM is going to be just a template, do not enter a complex password here:

    ![Setting password for new user](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_password.webp "Setting password for new user")

18. You'll have to confirm the new user's password:

    ![Confirmation of new user's password](images/g020/debian_vm_install_os_installer_creating_admin_user_setting_password_confirmation.webp "Confirmation of new user's password")

19. This step it's just about setting up the clock of this VM. First, the Debian installer will try to find a proper time server:

    ![Installer looks for a time server](images/g020/debian_vm_install_os_installer_time_server.webp "Installer looks for a time server")

    Then, the installer may or may not ask your specific timezone within the country you picked earlier:

    ![Choosing timezone](images/g020/debian_vm_install_os_installer_choosing_timezone.webp "Choosing timezone")

20. After a few more loading bars, you'll reach the step for disk partitioning:

    ![Disk partitioning options screen](images/g020/debian_vm_install_os_installer_disk_partitioning.webp "Disk partitioning options screen")

    **Be sure of choosing the SECOND guided option** to give the VM's disk a more flexible partition structure with the LVM system, like the one you have in your Proxmox VE host.

    ![Second option chosen at disk partitioning](images/g020/debian_vm_install_os_installer_disk_partitioning_second_option_chosen.webp "Second option chosen at disk partitioning")

21. The following screen is about choosing the storage drive to partition:

    ![Choosing disk for partitioning](images/g020/debian_vm_install_os_installer_disk_partitioning_choose_drive.webp "Choosing disk for partitioning")

    There is only one disk attached to this VM, so there's no other option but the one shown.

22. Next, the installer asks you which partition schema you want to apply:

    ![Choosing the partition schema to apply on the VM storage](images/g020/debian_vm_install_os_installer_disk_partitioning_schema_setup.webp "Choosing the partition schema to apply on the VM storage")

    This VM is going to be a template for servers, so you shouldn't ever need to mount a separate partition for the `home` directory. Something else could be said about the `var`. `srv` directories and swap, which they can grow notably. Therefore, better chose the option meant for servers, the third option specifying `Separate /var and /srv, swap < 1GB (for servers)`:

    ![Picking the option for servers as partition schema](images/g020/debian_vm_install_os_installer_disk_partitioning_schema_for_servers.webp "Picking the option for servers as partition schema")

23. The next screen is the confirmation of the disk partitioning you've setup in the previous steps:

    ![Disk partitioning confirmation screen](images/g020/debian_vm_install_os_installer_disk_partitioning_confirmation.webp "Disk partitioning confirmation screen")

    If you are sure that the partition setup is what you wanted, highlight `Yes` and press `Enter`.

24. The following step asks you about the size assigned to the LVM group in which the system partitions are going to be created:

    ![LVM group size](images/g020/debian_vm_install_os_installer_disk_partitioning_lvm_group_size.webp "LVM group size")

    Unless you know better, just stick with the default value and move on.

25. The installer will apply the partition scheme selected and, after seeing some more fast progress windows, you'll reach the disk partitioning final confirmation screen:

    ![Disk partitioning final confirmation screen](images/g020/debian_vm_install_os_installer_disk_partitioning_final_confirmation.webp "Disk partitioning final confirmation screen")

    Choose `Yes` to allow the installer to finally write the changes to disk.

26. After the partitioning is finished, you'll reach the progress bar of the base system installation:

    ![Installing the base system screen](images/g020/debian_vm_install_os_installer_base_system_installation.webp "Installing the base system screen")

    The Debian installer will need a bit of time to finish this task.

27. When the base system is installed, you'll see the following dialog:

    ![Additional media scan dialog](images/g020/debian_vm_install_os_installer_additional_media.webp "Additional media scan dialog")

    You do not have any additional media to use, so just answer `No` to this dialog.

28. The following step is about setting the right mirror servers location for your `apt` configuration:

    ![Mirror servers location screen](images/g020/debian_vm_install_os_installer_package_manager_mirrors_location.webp "Mirror servers location screen")

    By default, the option highlighted will be the same country you chose at the beginning of this installation. Pick the country that suits you best.

29. The next screen is about choosing a concrete mirror server for your `apt` settings:

    ![Choosing apt mirror server screen](images/g020/debian_vm_install_os_installer_package_manager_choosing_mirror_server.webp "Choosing apt mirror server screen")

    Stick with the default option, or change it if you identify a better alternative for you in the list.

30. A window will arise asking you to input your `HTTP proxy information`, if your PVE node happens to be connecting through one:

    ![HTTP proxy information screen](images/g020/debian_vm_install_os_installer_package_manager_proxy.webp "HTTP proxy information screen")

    In this guide it's assumed that you're not using a proxy, so that field should be left blank.

31. The installer will take a moment to configure the VM's `apt` system:

    ![Autoconfiguration of apt system](images/g020/debian_vm_install_os_installer_package_manager_autoconfiguring_apt.webp "Autoconfiguration of apt system")

32. When the `apt` configuration has finished, you'll see the following question about allowing a script to get some usage statistics of packages on your system:

    ![Popularity contest question screen](images/g020/debian_vm_install_os_installer_package_manager_popularity_contest.webp "Popularity contest question screen")

    Choose whatever you like here, although bear in mind that the security restrictions that you'll have to apply later to this Debian VM system may end blocking that script's functionality.

33. After another loading bar, you'll reach the `Software selection` screen:

    ![Software selection screen](images/g020/debian_vm_install_os_installer_software_selection.webp "Software selection screen")

    Notice that the installer has "deduced" (probably because of the "for servers" partition schema chosen in the previous step 22) that the VM is going to be a server. The installer has  already chosen the only two options that must be enabled here: `SSH server` and `standard system utilities`. This allows you to press `Continue` directly without changing anything.

34. Another progress windows will show up and the installer will proceed with the remainder of the installation process:

    ![Installation progress bar](images/g020/debian_vm_install_os_installer_executing_installation.webp "Installation progress bar")

35. Within the installation process, the installer will ask you if you want to install the GRUB boot loader in the VM's primary storage drive:

    ![GRUB boot loader installation screen](images/g020/debian_vm_install_os_installer_grub_boot_loader.webp "GRUB boot loader installation screen")

    The default `Yes` option is the correct one, so just press `Enter` on this screen.

36. Next, the installer will ask you on which drive you want to install GRUB:

    ![GRUB boot loader installation location screen](images/g020/debian_vm_install_os_installer_grub_boot_loader_disk.webp "GRUB boot loader installation location screen")

    Highlight the `/dev/sda` option and press `Enter` to continue the process:

    ![GRUB boot loader disk sda chosen](images/g020/debian_vm_install_os_installer_grub_boot_loader_disk_sda_chosen.webp "GRUB boot loader disk sda chosen")

37. After installing the GRUB boot loader, the installer will perform some remaining tasks like installing GRUB:

    ![Finishing the installation screen](images/g020/debian_vm_install_os_installer_finishing_installation.webp "Finishing the installation screen")

38. After the installation has finished, the installer will warn you about removing the media you used to launch the whole procedure:

    ![Remove installer media screen](images/g020/debian_vm_install_os_installer_remove_media.webp "Remove installer media screen")

    > [!WARNING]
    > **Keep calm, _DO NOT_ press `Enter` yet and read the following steps**\
    > If you `Continue`, the VM will reboot and, if the installer media is still in place, the installer will boot up again.

39. Go back to your Proxmox VE web console, and open the `Hardware` tab of your VM. Then, choose the `CD/DVD Drive` item and press the `Edit` button:

    ![Edit button on VM's hardware tab](images/g020/debian_vm_install_os_vm_hardware_tab_edit_button.webp "Edit button on VM's hardware tab")

40. You'll see the Edit window for the `CD/DVD Drive` you chose:

    ![Edit window for CD/DVD Drive](images/g020/debian_vm_install_os_vm_hardware_tab_edit_window.webp "Edit window for CD/DVD Drive")

    Here, choose the `Do not use any media` option and click on `OK`.

    ![Option changed at Edit window for CD/DVD Drive](images/g020/debian_vm_install_os_vm_hardware_tab_edit_window_changed.webp "Option changed at Edit window for CD/DVD Drive")

41. Back in the Hardware screen, you'll see how the CD/DVD Drive is now set to `none`:

    ![CD/DVD Drive empty on VM's Hardware tab](images/g020/debian_vm_install_os_vm_hardware_tab_cdrom_updated.webp "CD/DVD Drive empty on VM's Hardware tab")

    > [!IMPORTANT]
    > **This does not mean that the change has been applied to the still running VM**\
    > Usually, changes like these will require a reboot of the VM.

42. Now that the VM's CD/DVD drive is configured to be empty, you can go back to the noVNC shell and press on `Enter` to finish the Debian installation. If everything goes as it should, the VM will reboot into the GRUB screen of your newly installed Debian system:

    ![GRUB boot loader screen](images/g020/debian_vm_install_os_vm_rebooted_grub.webp "GRUB boot loader screen")

43. Press Enter with the default highlighted option or allow the timer to reach `0`. Then, after the usual system booting shell output, you should reach the login:

    ![Debian login](images/g020/debian_vm_install_os_debian_login.webp "Debian login")

44. As a final verification, login either with `root` or with `mgrsys` to check that they work as expected.

## Note about the VM's `Boot Order` option

Go to the `Options` tab of your new Debian VM:

![VM Options tab](images/g020/debian_vm_note_option_boot_order_options_tab.webp "VM Options tab")

In the capture above, you can see highlighted the `Boot Order` list currently enabled in this VM. If you press on the `Edit` button, you'll be able to edit this `Boot Order` list:

![Edit Boot Order option window](images/g020/debian_vm_note_option_boot_order_edit_window.webp "Edit Boot Order option window")

Notice how PVE has already enabled the bootable hardware devices (hard disk, CD/DVD drive and network device) that were configured in the VM creation process. Also see how the network device added later, `net1`, **is NOT enabled by default**.

> [!IMPORTANT]
> **New bootable devices in VMs are not enabled by default**\
> When you modify the bootable hardware devices of a VM, Proxmox VE **WON'T** enable automatically any new bootable device in the `Boot Order` list. You must revise or modify it whenever you make changes to the hardware devices available in a VM.

## Relevant system paths

### Directories

- `/etc/pve`
- `/etc/pve/nodes/pve/qemu-server`

### Files

- `/etc/pve/user.cfg`
- `/etc/pve/nodes/pve/qemu-server/100.cfg`

## References

### Debian

- [Debian](https://www.debian.org/)
- [How to Install a Debian 12 (Bookworm) Minimal Server](https://www.howtoforge.com/tutorial/debian-minimal-server/)

### Virtual Machines on Proxmox VE

- [PVE admin guide. QEMU/KVM Virtual Machines](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_virtual_machines)
  - [CPU](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_cpu)
  - [Memory](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_memory)
  - [Network Device](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_network_device)

- [PVE admin guide. Permission Management. Pools](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pveum_pools)

- [Proxmox Forum. Async IO Settings for Virtual Disks: Documentation? How to Set?](https://forum.proxmox.com/threads/async-io-settings-for-virtual-disks-documentation-how-to-set.114932/)

- [Reddit. Proxmox. Best practices on setting up Proxmox on a new server](https://www.reddit.com/r/Proxmox/comments/oz81qq/best_practices_on_setting_up_proxmox_on_a_new/)

- [Non-uniform memory access](https://en.wikipedia.org/wiki/Non-uniform_memory_access)

### Units of measurement for storage

- [Wikipedia. Gigabyte](https://en.wikipedia.org/wiki/Gigabyte#Definition)
  - [Definition. Base 2 (binary)](https://en.wikipedia.org/wiki/Gigabyte#Base_2_(binary))

## Navigation

[<< Previous (**G019. K3s cluster setup 02**)](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G021. K3s cluster setup 04**) >>](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md)
