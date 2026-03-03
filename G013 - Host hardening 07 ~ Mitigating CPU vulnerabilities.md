# G013 - Host hardening 07 ~ Mitigating CPU vulnerabilities

- [CPUs also have security vulnerabilities](#cpus-also-have-security-vulnerabilities)
- [Discovering your CPU's vulnerabilities](#discovering-your-cpus-vulnerabilities)
- [Your Proxmox VE system already has the correct microcode package applied](#your-proxmox-ve-system-already-has-the-correct-microcode-package-applied)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [About CPU vulnerabilities](#about-cpu-vulnerabilities)
- [Navigation](#navigation)

## CPUs also have security vulnerabilities

CPUs also come with bugs and, in some cases, they can become security vulnerabilities. For instance, a couple of famous cases of such bugs were the meltdown and spectre vulnerabilities.

## Discovering your CPU's vulnerabilities

To check out what known vulnerabilities your CPU has, perform these steps:

1. Open a remote terminal as your administrator user into your Proxmox VE, and execute the following:

    ~~~sh
    $ cat /proc/cpuinfo | grep bugs
    ~~~

2. The output will be one line per core on your CPU. So, in the four-cores processor of this guide's reference hardware it looks like below:

    ~~~sh
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only mmio_unknown
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only mmio_unknown
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only mmio_unknown
    bugs            : cpu_meltdown spectre_v1 spectre_v2 mds msbds_only mmio_unknown
    ~~~

As you can imagine, the list of vulnerabilities will change depending on the CPU inspected.

## Your Proxmox VE system already has the correct microcode package applied

To mitigate these bugs, it is required to install the proper microcode `apt` package for your CPU: the `intel-microcode` or the `amd-microcode` one. In this guide's case, the Proxmox VE installation process already installed the correct package (the `intel-microcode` one) in the system. This can be discovered by first checking what `apt` sources are configured in the `/etc/apt/sources.list.d/debian.sources` file:

~~~properties
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
~~~

Notice that both sources have the `non-free-firmware` components, which is where the microcode packages are part of. Then, you try to install the `intel-microcode` package in the PVE system with `apt`:

~~~sh
$ sudo apt install -y intel-microcode
intel-microcode is already the newest version (3.20250512.1).
Summary:
  Upgrading: 0, Installing: 0, Removing: 0, Not Upgrading: 3
~~~

The `apt` command warns that the package is already installed in the system and in its newest version. Therefore, you can expect your Proxmox VE setup to have the correct microcode package already applied. If not, first ensure that your `/etc/apt/sources.list.d/debian.sources` file looks like the one shown before, then do the following:

1. Make apt update its references, then install the correct microcode package for your system:

    ~~~sh
    $ sudo apt update
    $ sudo apt install -y intel-microcode
    ~~~

2. After the package's installation is done, reboot your system:

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

- `/etc/apt/sources.list.d/debian.sources`
- `/proc/cpuinfo`

## References

### About CPU vulnerabilities

- [Meltdown and Spectre](https://meltdownattack.com/)
- [Debian Wiki. Microcode](https://wiki.debian.org/Microcode)

## Navigation

[<< Previous (**G012. Host hardening 06**)](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G014. Host hardening 08**) >>](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md)
