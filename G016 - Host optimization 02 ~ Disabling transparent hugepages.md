# G016 - Host optimization 02 ~ Disabling transparent hugepages

**Transparent Hugepages** is a Linux kernel feature intended to improve performance by making more efficient use of your processor’s memory-mapping hardware. It is enabled (“enabled=always”) by default in most Linux distributions.

Transparent Hugepages gives some applications a small performance improvement (~ 10% at best, 0-3% more typically), but can cause significant performance problems (to database engines for instance) or even apparent memory leaks at worst.

## Status of transparent hugepages in your host

To check out the current status of the transparent hugepages in your standalone PVE node, log as your `mgrsys` user in a shell and execute.

~~~bash
$ cat /sys/kernel/mm/transparent_hugepage/enabled
always [madvise] never
~~~

The highlighted value is `madvise`, which means that transparent hugepages are enabled but not system wide. It's a feature available only for applications that request it specifically.

There's other parameter that hints about the usage of transparent hugepages, `AnonHugePages`. To see its current value, execute the following command.

~~~bash
$ grep AnonHuge /proc/meminfo
AnonHugePages:         0 kB
~~~

At this point, no application has made use of transparent hugepages, so the value of `AnonHugePages` is 0 KiB.

## Disabling the transparent hugepages

To switch the status of the transparent hugepages from `madvise` to `never`, you'll have to modify the configuration of your Debian's Grub boot system.

1. Open a shell as `mgrsys`, `cd` to `/etc/default/` and make a backup of the original `grub` file.

    ~~~bash
    $ cd /etc/default/
    $ sudo cp grub grub.orig
    ~~~

2. Edit the `grub` file, modifying the `GRUB_CMDLINE_LINUX=""` line as follows.

    ~~~properties
    GRUB_CMDLINE_LINUX="transparent_hugepage=never"
    ~~~

3. Update the grub and reboot the system.

    ~~~bash
    $ sudo update-grub
    $ sudo reboot
    ~~~

4. Log again as `mgrsys` and check the current status of the transparent hugepages.

    ~~~bash
    $ cat /sys/kernel/mm/transparent_hugepage/enabled
    always madvise [never]
    ~~~

## Relevant system paths

### _Directories_

- `/etc/default`

### _Files_

- `/etc/default/grub`
- `/etc/default/grub.orig`
- `/proc/meminfo`
- `/sys/kernel/mm/transparent_hugepage/enabled`

## References

- [Transparent Hugepage Support](https://www.kernel.org/doc/Documentation/vm/transhuge.txt)
- [Debian 10: How to disable transparent hugepages](https://dbsysupgrade.com/debian-10-how-to-disable-transparent-hugepages/)
- [Disabling transparent hugepages on Ubuntu/Debian](https://lxadm.com/Disabling_transparent_hugepages_on_Ubuntu/Debian)
- [Which distributions enable transparent huge pages “for all applications”?](https://unix.stackexchange.com/questions/495816/which-distributions-enable-transparent-huge-pages-for-all-applications)
