# G001 - Hardware setup

- [You just need a capable enough computer](#you-just-need-a-capable-enough-computer)
- [The reference hardware setup](#the-reference-hardware-setup)
  - [Why this hardware setup?](#why-this-hardware-setup)
- [References](#references)
  - [Hardware](#hardware)
- [Navigation](#navigation)

## You just need a capable enough computer

In the [README](README.md) I talk about a small or low-end consumer-grade computer, meaning that you don't need the latest and fastest machine available in the market. Any relatively modern small tower or mini PC, or even a normal laptop, could be adequate. Still, your computer must meet certain minimum requirements, or it won't be able to run the Kubernetes cluster the way it's explained in this guide.

> [!NOTE]
> **Virtualizing the Proxmox VE setup is problematic**\
> It is possible to run the Proxmox VE platform in a VM but, in my experience with VirtualBox at least, configuring the networking to enable access to the VMs run from within Proxmox VE is not straightforward. Depending on the virtualization platform you use, you may be forced to try different configurations and, even then, you might not be able to reach the VMs running in your Proxmox VE server.
>
> In short, it is better if you use real hardware to avoid extra pains with the networking aspects of this guide's setup.

## The reference hardware setup

The hardware used in this guide is an upgraded [Packard Bell iMedia S2883 desktop computer](https://archive.org/details/manualzilla-id-7098831) from around 2014. This quite old and rather limited computer has the following specifications (after the upgrade):

- The BIOS firmware is UEFI (Secure Boot) but also provides a CSM mode.

- The **CPU** is an [Intel Pentium J1900](https://www.intel.com/content/www/us/en/products/sku/78867/intel-celeron-processor-j1900-2m-cache-up-to-2-42-ghz/specifications.html). This is a **four one-thread cores** CPU built on a **64 bits architecture** that also comes with **VT-x virtualization technology**.

- The **GPU** is from the Intel® HD Graphics for Intel Atom® Processor Z3700 Series, and comes integrated in the J1900 CPU.

- The **RAM** is made up of two DDR3 4 GiB SDRAM modules, the maximum allowed by the motherboard and the J1900 CPU.

- The **storage** is composed of the following drives:

  - One internal, 1 TiB, SSD drive, linked to a SATA port.
  - One internal, 1 TiB, HDD drive, linked to a SATA port.
  - One external, 2 TiB, HDD drive, plugged to a USB 3 port.

- For **networking**, it has one Realtek gigabit Ethernet controller.

- The computer also has some USB 2 connectors plus one USB 3 plug.

- The UPS is an [Eaton 3S700D](https://www.eaton.com/at/en-gb/skuPage.3S700D.html) unit.

This rather cheap rig is somewhat close to what, at the time of writing this, a basic modern NUC or mini PC can come with.

### Why this hardware setup?

Let me explain why you should consider a hardware configuration like this as your bare minimum:

- It has an UEFI (Secure Boot) BIOS, necessary to boot up the EFI-based bootloader of Proxmox VE.

- The CPU must be 64 bits since Proxmox VE only runs on 64 bits CPUs.

- The CPU must have virtualization technology embedded or the virtual machines' performance could be awful. Proxmox VE also expects the CPU to have this capability available.

  > [!IMPORTANT]
  > **Ensure your CPU's virtualization technology is active**\
  > Check in your computer's UEFI or BIOS to ensure that the virtualization instructions are enabled.
  >
  > On the other hand, if you are considering installing Proxmox VE in a virtual machine, do not forget to give that virtual machine access to the virtualization technology of your host's CPU. For instance, in VirtualBox there's an option named `Enable Nested VT-x/AMD-V` that allows you just that (although its activation is not straightforward).

- Having less than 8 GiB of RAM won't cut it, the virtual machines you will use as Kubernetes nodes will use 2 GiB each. So, starting from 8 GiB, the more RAM you can put in your computer the better.

- Regarding storage, you will need at least one big enough internal storage drive and another big external one.

  - The internal one should be SSD, enabling you to get the best performance possible out of your system. Is in this drive where you should install the Proxmox VE platform and where you must put the root filesystems of your VMs.

  - The external one could be a 7200 RPM HDD, pluggable through the fastest USB port available. This drive would serve you as the backup storage.

  - If you happen to have another big storage drive that you can put inside your computer, as I set up in mine, you could use it as data storage.

- If you don't have it already, get an UPS. Running a server without one is risking damage or, at least, data losses in case of outages or electric spikes.

A hardware setup like this won't allow you to use features usually found in professional environments such as RAID storage or high availability. Still, it will be enough for you to build a decent personal homelab.

## References

### Hardware

- [Packard Bell iMedia S2883 desktop computer](https://archive.org/details/manualzilla-id-7098831)

- [Intel Pentium J1900](https://www.intel.com/content/www/us/en/products/sku/78867/intel-celeron-processor-j1900-2m-cache-up-to-2-42-ghz/specifications.html)

- [Eaton 3S700D](https://www.eaton.com/at/en-gb/skuPage.3S700D.html)

## Navigation

[<< Previous (**README**)](README.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G002. Proxmox VE installation**) >>](G002%20-%20Proxmox%20VE%20installation.md)
