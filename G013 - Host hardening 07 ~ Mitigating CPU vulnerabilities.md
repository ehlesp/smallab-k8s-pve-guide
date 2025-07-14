# G013 - Host hardening 07 ~ Mitigating CPU vulnerabilities

- [CPUs also have security vulnerabilities](#cpus-also-have-security-vulnerabilities)
- [Discovering your CPU's vulnerabilities](#discovering-your-cpus-vulnerabilities)
- [Applying the correct microcode package](#applying-the-correct-microcode-package)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [About CPU vulnerabilities](#about-cpu-vulnerabilities)
  - [Debian](#debian)
- [Navigation](#navigation)

## CPUs also have security vulnerabilities

CPUs also come with bugs and, in some cases, can become security vulnerabilities. At the time of writing this, the most famous cases of such bugs (still) are the **meltdown** and **spectre** vulnerabilities.

## Discovering your CPU's vulnerabilities

To check out what known vulnerabilities your CPU has, perform these steps.

1. Open a shell as your administrator user, and execute the following.

    ~~~sh
    $ cat /proc/cpuinfo | grep bugs
    ~~~

2. The output will be one line per core on your CPU. So, in the four-cores processor of my virtual machine it looks like below.

    ~~~sh
    bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit srbds mmio_stale_data retbleed gds bhi
    bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit srbds mmio_stale_data retbleed gds bhi
    bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit srbds mmio_stale_data retbleed gds bhi
    bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit srbds mmio_stale_data retbleed gds bhi
    ~~~

    > [!NOTE]
    > **VMs inherit the bugs of the real processor they run on**\
    > The bugs listed above come from the Intel Core i7 processor running the VM where I've installed the Proxmox VE setup explained in this guide.

As you may expect, the list of vulnerabilities will change depending on the CPU inspected.

## Applying the correct microcode package

To mitigate these bugs, you can install the proper microcode `apt` package for your CPU: the `intel-microcode` or the `amd-microcode` one. But to do so, first you need to enable the proper `apt` sources so those packages can be downloaded in your system.

1. Log in as `mgrsys`, then `cd` to `/etc/apt/sources.list.d`:

    ~~~sh
    $ cd /etc/apt/sources.list.d
    ~~~

2. Create a new file called `debian-nonfree.list`:

    ~~~sh
    $ sudo touch debian-nonfree.list
    ~~~

3. Edit the `debian-nonfree.list` file, filling it with the lines below:

    ~~~sh
    deb https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
    deb-src https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

    deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
    deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

    deb https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
    deb-src https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
    ~~~

    > [!WARNING]
    > This sources list is only for **Debian 12 (Bookworm)**!

4. Save the file, update `apt` and then install the package that suits your CPU. In my case, I'll apply the `intel-microcode` package:

    ~~~sh
    $ sudo apt update
    $ sudo apt install -y intel-microcode
    ~~~

5. After the package's installation is done, reboot your system.

    ~~~sh
    $ sudo reboot
    ~~~

> [!WARNING]
> **The microcode package can affect your CPU's performance**\
> Furthermore, the microcode applied may just mitigate rather than completely fix the vulnerabilities on your CPU.

## Relevant system paths

### Directories

- `/etc/apt/sources.list.d`
- `/proc`

### Files

- `/etc/apt/sources.list.d/debian-nonfree.list`
- `/proc/cpuinfo`

## References

### About CPU vulnerabilities

- [Meltdown and Spectre](https://meltdownattack.com/)
- [Microcode on Debian Wiki](https://wiki.debian.org/Microcode)

### [Debian](https://www.debian.org/)

- [Debian Wiki. SourcesList](https://wiki.debian.org/SourcesList)
- [How do I install non-free firmware in Debian 12 (Bookworm)?](https://unix.stackexchange.com/questions/736065/how-do-i-install-non-free-firmware-in-debian-12-bookworm)

## Navigation

[<< Previous (**G012. Host hardening 06**)](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G014. Host hardening 08**) >>](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md)
