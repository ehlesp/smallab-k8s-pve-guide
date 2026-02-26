# G016 - Host optimization 02 ~ Disabling the transparent hugepages

- [Understanding the transparent hugepages](#understanding-the-transparent-hugepages)
- [Status of the transparent hugepages in your host](#status-of-the-transparent-hugepages-in-your-host)
- [Disabling the transparent hugepages](#disabling-the-transparent-hugepages)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [About transparent hugepages](#about-transparent-hugepages)
  - [About exclusive hugepages](#about-exclusive-hugepages)
- [Navigation](#navigation)

## Understanding the transparent hugepages

**Transparent hugepages** is a Linux kernel feature intended to improve performance by making more efficient use of your processor’s memory-mapping hardware. This feature gives some applications a small performance boost, but can cause significant latency issues (to database engines for instance) or even apparent memory leaks at worst.

> [!NOTE]
> **Do not confuse transparent hugepages with explicit hugepages**\
> While transparent hugepages are dynamically reassigned by the kernel to be reused by any compatible application, explicit hugepages are reserved for specific services and render inaccessible to other workloads in the system.

This chapter shows you how to disable the transparent hugepages because:

- There is no recommended setup for Proxmox VE about this feature.
- It may not be worth having it enabled in a small server setup (specially on the RAM side) like the one used in this guide.
- Can provoke serious latency issues in a system when it kicks in to compact fragmented RAM.

> [!IMPORTANT]
> **Do not completely dismiss using transparent hugepages!**\
> Remember that some applications may benefit from this feature, although they have to be built for it specifically.
>
> Therefore, research the [references found at the end of this chapter](#references) and carefully evaluate if your system's workload can benefit from having transparent hugepages enabled.

## Status of the transparent hugepages in your host

To check out the current status of the transparent hugepages in your standalone PVE node, log as your `mgrsys` user in a shell and execute:

~~~sh
$ cat /sys/kernel/mm/transparent_hugepage/enabled
always [madvise] never
~~~

The highlighted value is `madvise`, which means that transparent hugepages are enabled but only for applications that request it specifically.

There is other parameter that hints about the usage of transparent hugepages, `AnonHugePages`. To see its current value, execute the following command:

~~~sh
$ grep AnonHuge /proc/meminfo
AnonHugePages:         0 kB
~~~

At this point, no application has made use of transparent hugepages, so the value of `AnonHugePages` is 0 KiB.

## Disabling the transparent hugepages

To switch the status of the transparent hugepages from `madvise` to `never`, you must modify the configuration of your Debian's Grub boot system:

1. Open a shell as `mgrsys`, `cd` to `/etc/default/` and make a backup of the original `grub` file:

    ~~~sh
    $ cd /etc/default/
    $ sudo cp grub grub.orig
    ~~~

2. Edit the `grub` file, modifying the `GRUB_CMDLINE_LINUX=""` line as follows:

    ~~~properties
    GRUB_CMDLINE_LINUX="transparent_hugepage=never"
    ~~~

3. Update the grub and reboot the system:

    ~~~sh
    $ sudo update-grub
    $ sudo reboot
    ~~~

4. Log again as `mgrsys` and check the current status of the transparent hugepages:

    ~~~sh
    $ cat /sys/kernel/mm/transparent_hugepage/enabled
    always madvise [never]
    ~~~

    The highlighted status should be `never` now, as shown in the snippet above.

## Relevant system paths

### Directories

- `/etc/default`

### Files

- `/etc/default/grub`
- `/etc/default/grub.orig`
- `/proc/meminfo`
- `/sys/kernel/mm/transparent_hugepage/enabled`

## References

### About transparent hugepages

- [Proxmox. Forums. Proxmox Virtual Environment](https://forum.proxmox.com/#proxmox-virtual-environment.11)
  - [Proxmox VE: Installation and configuration](https://forum.proxmox.com/forums/proxmox-ve-installation-and-configuration.16/)
    - [How should Transparent Hugepages be configured?](https://forum.proxmox.com/threads/how-should-transparent-hugepages-be-configured.132611/)

- [The Linux Kernel Archives. Transparent Hugepage Support](https://www.kernel.org/doc/html/latest/admin-guide/mm/transhuge.html)
- [Google Groups. mechanical-sympathy. failing to understand the issues with transparent huge paging](https://groups.google.com/g/mechanical-sympathy/c/sljzehnCNZU)
- [The mole is digging. Transparent Hugepages: measuring the performance impact](https://alexandrnikitin.github.io/blog/transparent-hugepages-measuring-the-performance-impact/)
- [GoLinuxHub. How to enable or disable transparent (THP) and explicit (nr_hugepages) hugepage and check the status in Linux with examples (explained in detail)](https://www.golinuxhub.com/2018/08/enable-or-disable-transparent-anon-hugepage-thp-check-status-examples-linux/)
- [Blog for Database and System Administrators. Debian 10: How to disable transparent hugepages](https://dbsysupgrade.com/debian-10-how-to-disable-transparent-hugepages/)
- [StackExchange. Unix & Linux. Which distributions enable transparent huge pages “for all applications”?](https://unix.stackexchange.com/questions/495816/which-distributions-enable-transparent-huge-pages-for-all-applications)

### About exclusive hugepages

- [Proxmox HugePages for VMs](https://dev.to/sergelogvinov/proxmox-hugepages-for-vms-1fh3)
- [Enabling Hugepages in Proxmox](https://docs.renderex.ae/posts/Enabling-hugepages/)

## Navigation

[<< Previous (**G015. Host optimization 01**)](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G017. Virtual Networking**) >>](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md)
