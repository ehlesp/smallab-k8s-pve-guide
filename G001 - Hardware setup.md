# G001 - Hardware setup

The first thing you need to have is a capable computer. In the [README](README.md) I've talked about a small or low-end consumer computer, meaning that you don't need the latest and fastest machine available in the market. Any relatively modern small tower PC, or even a normal laptop, could be adequate. Still, your computer must meet certain minimum requirements, or it won't be able to run the Kubernetes cluster the way it's explained in this guide series.

## The reference hardware setup

The hardware setup that serves as platform and reference for this guide series is a slightly upgraded [Lenovo H30-00 desktop computer](https://pcsupport.lenovo.com/us/en/products/desktops-and-all-in-ones/lenovo-h-series-desktops/lenovo-h30-00-desktop) from 2014. After the upgrade, it has the following specs.

- **CPU** [Intel Pentium J2900](https://ark.intel.com/content/www/us/en/ark/products/78868/intel-pentium-processor-j2900-2m-cache-up-to-2-67-ghz.html): This is a **four one-thread cores** cpu built on a **64 bits architecture** that also comes with **VT-x virtualization technology**.

- **GPU** [Intel® HD Graphics for Intel Atom® Processor Z3700 Series](https://ark.intel.com/content/www/us/en/ark/products/78868/intel-pentium-processor-j2900-2m-cache-up-to-2-67-ghz.html#tab-blade-1-0-4), integrated in the CPU.

- **RAM** is one DDR3 8 GiB module, the maximum allowed by the motherboard and the J2900 CPU.

- The storage has the following setup:
    - One internal, 1 TiB, SSD drive, linked to a SATA 2 port.
    - One internal, 1 TiB, HDD drive, linked to a SATA 2 port .
    - One external, 2 TiB, HDD drive, plugged to a USB 3 port.

- The computer also has a bunch of USB 2 connectors plus one USB 3 plug.

- One Realtek fast/gigabit ethernet controller, integrated in the motherboard.

- One Realtek wireless network adapter, also integrated in the motherboard.

- Power supply happens to be an external small brick like the ones used in laptops. Good for keeping the power supply's heat out of the computer.

- UPS [APC Back-UPS ES 700](https://www.apc.com/shop/es/es/products/Back-UPS-700-de-bajo-consumo-de-APC-230-V-CEE-7-7/P-BE700G-SP).

This rather cheap rig is close to what a basic modern NUC or mini PC can come with (at the time of writing this). Now, let me explain why you should consider a hardware configuration like this as your bare minimum.

- The CPU must be 64 bits since Proxmox VE only runs on 64 bits CPUs.

- The CPU should have virtualization technology embedded or the virtual machines' performance could be awful. Proxmox VE also expects the CPU to have this capability available.

- Having less than 8 GiB of RAM won't cut it, the virtual machines you'll use as Kubernetes nodes will require at least 1 GiB each. So, starting from 8 GiB, the more RAM you can put in your computer the better.

- Regarding storage, at least you'll need one big enough internal storage drive and another big external one.
    - The internal one should be SSD so you can get the best performance possible out of your system, meaning that in this drive is where you should install the Proxmox VE platform and where you must put the root filesystems of your VMs.
    - The external one could be a 7200 RPM HDD, pluggable through USB 3 (if possible). This drive would serve you as the backup storage.
    - If you happen to have another big storage drive that you can put inside your computer, as I set up in mine, you could use it as data storage.

- If you don't have it already, get an UPS. Running a server without one is risking damage or, at least, data losses in case of outages or electric spikes.

So, although a hardware setup like this won't allow you to use things usually found in professional environments (RAID storage configurations, high availability, etc), you'll get a decent small homelab for your personal usage.

## References

### _Hardware_

- [Lenovo H30-00 desktop computer](https://pcsupport.lenovo.com/us/en/products/desktops-and-all-in-ones/lenovo-h-series-desktops/lenovo-h30-00-desktop)
- [Intel Pentium J2900](https://ark.intel.com/content/www/us/en/ark/products/78868/intel-pentium-processor-j2900-2m-cache-up-to-2-67-ghz.html)
- [Intel® HD Graphics for Intel Atom® Processor Z3700 Series](https://ark.intel.com/content/www/us/en/ark/products/78868/intel-pentium-processor-j2900-2m-cache-up-to-2-67-ghz.html#tab-blade-1-0-4)
- [APC Back-UPS ES 700](https://www.apc.com/shop/es/es/products/Back-UPS-700-de-bajo-consumo-de-APC-230-V-CEE-7-7/P-BE700G-SP)

## Navigation

[<< Previous (**README**)](README.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G002. Proxmox VE installation**) >>](G002%20-%20Proxmox%20VE%20installation.md)
