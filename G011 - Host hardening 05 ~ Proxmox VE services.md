# G011 - Host hardening 05 ~ Proxmox VE services

- [Reduce your Proxmox VE server's exposed surface](#reduce-your-proxmox-ve-servers-exposed-surface)
- [Checking currently running services](#checking-currently-running-services)
  - [Listing the contents of the `/etc/init.d/` folder](#listing-the-contents-of-the-etcinitd-folder)
  - [Listing the unit files with `systemctl`](#listing-the-unit-files-with-systemctl)
  - [Getting the status of running services with `systemctl`](#getting-the-status-of-running-services-with-systemctl)
  - [Checking the systemd units loaded in memory](#checking-the-systemd-units-loaded-in-memory)
  - [Inspecting the running services with `htop`](#inspecting-the-running-services-with-htop)
- [Configuring the `pveproxy` service](#configuring-the-pveproxy-service)
  - [Default 8006 port and listening interfaces](#default-8006-port-and-listening-interfaces)
  - [Enforcing strong SSL/TLS ciphers](#enforcing-strong-ssltls-ciphers)
  - [Host based access control rules](#host-based-access-control-rules)
- [Disabling RPC services](#disabling-rpc-services)
- [Disabling `zfs` and `ceph`](#disabling-zfs-and-ceph)
- [Disabling the SPICE proxy](#disabling-the-spice-proxy)
- [Disabling cluster and high availability related services](#disabling-cluster-and-high-availability-related-services)
- [Considerations](#considerations)
  - [Errors in the `apt upgrade` process](#errors-in-the-apt-upgrade-process)
  - [View of services running in the Proxmox VE node](#view-of-services-running-in-the-proxmox-ve-node)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Services management in Debian](#services-management-in-debian)
  - [Proxmox hardening and standalone node optimization](#proxmox-hardening-and-standalone-node-optimization)
  - [Proxmox VE service daemons](#proxmox-ve-service-daemons)
  - [NFS and RPC](#nfs-and-rpc)
  - [Default listening behaviour of `pveproxy`](#default-listening-behaviour-of-pveproxy)
  - [Configuration of SSL/TSL ciphers in `pveproxy`](#configuration-of-ssltsl-ciphers-in-pveproxy)
  - [ZFS and Ceph](#zfs-and-ceph)
  - [SPICE proxy](#spice-proxy)
- [Navigation](#navigation)

## Reduce your Proxmox VE server's exposed surface

Your standalone Proxmox VE node comes with a number of services running by default. Having in mind the target system's particularities assumed in this guide, there is some reconfiguring or disabling of services you can do to harden your Proxmox VE platform even more.

The basic idea is to reduce your platform's surface exposed to possible attacks, while also saving some RAM and CPU in the process, by disabling unneeded processes related to Proxmox VE.

## Checking currently running services

To see what services are running in your system, you can do any of the following.

### Listing the contents of the `/etc/init.d/` folder

Check out the `/etc/init.d/` folder with `ls -al` to get an output like the following:

~~~sh
$ ls -al /etc/init.d/
total 128
drwxr-xr-x  2 root root 4096 Jul 12 19:49 .
drwxr-xr-x 97 root root 4096 Jul 12 19:49 ..
-rwxr-xr-x  1 root root 3740 Feb 14  2023 apparmor
-rwxr-xr-x  1 root root 1897 May  8  2023 chrony
-rwxr-xr-x  1 root root 1235 May 21  2023 console-setup.sh
-rwxr-xr-x  1 root root 3059 Jul 17  2022 cron
-rwxr-xr-x  1 root root 3152 Sep 16  2023 dbus
-rwxr-xr-x  1 root root 7013 Apr 21  2023 fail2ban
-rwxr-xr-x  1 root root 1748 Nov 21  2024 hwclock.sh
-rwxr-xr-x  1 root root 1503 May  3  2024 iscsid
-rwxr-xr-x  1 root root 1482 Jul 18  2022 keyboard-setup.sh
-rwxr-xr-x  1 root root 2063 Dec  9  2022 kmod
-rwxr-xr-x  1 root root 5658 Dec 11  2024 nfs-common
-rwxr-xr-x  1 root root 5329 Jan 25  2023 nut-client
-rwxr-xr-x  1 root root 5316 Jan 25  2023 nut-server
-rwxr-xr-x  1 root root 2433 May  3  2024 open-iscsi
-rwxr-xr-x  1 root root 3089 Mar  6  2024 postfix
-rwxr-xr-x  1 root root  959 Dec 19  2022 procps
-rwxr-xr-x  1 root root 2505 Jul 27  2022 rpcbind
-rwxr-xr-x  1 root root 5246 Sep  1  2019 rrdcached
-rwxr-xr-x  1 root root 4417 Jan 15 19:47 rsync
-rwxr-xr-x  1 root root 3088 Jun 15  2023 smartmontools
-rwxr-xr-x  1 root root 4060 Feb 14 12:51 ssh
-rwxr-xr-x  1 root root 1161 Jun 27  2023 sudo
-rwxr-xr-x  1 root root 6871 Mar  6 15:56 udev
lrwxrwxrwx  1 root root   10 Jan 25  2023 ups-monitor -> nut-client
~~~

The problem is that not all running processes or services have an executable file in this folder, so this listing gives you a very incomplete reference.

### Listing the unit files with `systemctl`

A much more detailed listing is the one offered by the following `systemctl` command.

~~~sh
$ sudo systemctl list-unit-files
~~~

This will give you an interactive read-only long and exhaustive list of processes and services.

~~~sh
UNIT FILE                              STATE           PRESET
proc-sys-fs-binfmt_misc.automount      static          -
-.mount                                generated       -
dev-hugepages.mount                    static          -
dev-mqueue.mount                       static          -
proc-fs-nfsd.mount                     static          -
proc-sys-fs-binfmt_misc.mount          disabled        disabled
run-rpc_pipefs.mount                   generated       -
sys-fs-fuse-connections.mount          static          -
sys-kernel-config.mount                static          -
sys-kernel-debug.mount                 static          -
sys-kernel-tracing.mount               static          -
var-lib-nfs-rpc_pipefs.mount           static          -
nut-driver-enumerator.path             enabled         enabled
postfix-resolvconf.path                disabled        enabled
systemd-ask-password-console.path      static          -
systemd-ask-password-wall.path         static          -
session-1.scope                        transient       -
apparmor.service                       enabled         enabled
apt-daily-upgrade.service              static          -
apt-daily.service                      static          -
...
~~~

### Getting the status of running services with `systemctl`

Another way of listing all the running services with `systemctl` is the following:

~~~sh
$ sudo systemctl status
~~~

The command will output an interactive read-only list like the following excerpt.

~~~sh
● pve
    State: running
    Units: 394 loaded (incl. loaded aliases)
     Jobs: 1 queued
   Failed: 0 units
    Since: Sun 2025-07-13 16:47:00 CEST; 8min ago
  systemd: 252.38-1~deb12u1
   CGroup: /
           ├─init.scope
           │ └─1 /sbin/init
           ├─system.slice
           │ ├─chrony.service
           │ │ ├─796 /usr/sbin/chronyd -F 1
           │ │ └─799 /usr/sbin/chronyd -F 1
           │ ├─cron.service
           │ │ └─988 /usr/sbin/cron -f
           │ ├─dbus.service
           │ │ └─563 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile -->
           │ ├─fail2ban.service
           │ │ └─754 /usr/bin/python3 /usr/bin/fail2ban-server -xf start
           │ ├─ksmtuned.service
           │ │ ├─ 588 /bin/bash /usr/sbin/ksmtuned
           │ │ └─2900 sleep 60
           │ ├─lxc-monitord.service
           │ │ └─756 /usr/libexec/lxc/lxc-monitord --daemon
           │ ├─lxcfs.service
           │ │ └─609 /usr/bin/lxcfs /var/lib/lxcfs
           │ ├─nut-monitor.service
           │ │ ├─1058 /lib/nut/upsmon -F
           │ │ └─1060 /lib/nut/upsmon -F
           │ ├─nut-server.service
           │ │ └─1057 /lib/nut/upsd -F
           │ ├─proxmox-firewall.service
           │ │ └─989 /usr/libexec/proxmox/proxmox-firewall
           │ ├─pve-cluster.service
           │ │ └─875 /usr/bin/pmxcfs
           │ ├─pve-firewall.service
           │ │ └─1001 pve-firewall
...
~~~

### Checking the systemd units loaded in memory

Also with `systemctl`, you can see the "units" systemd has currently in memory and their state.

~~~sh
$ sudo systemctl list-units
    UNIT                                                                                                       LOAD   ACTIVE     SUB       DESCRIPTION
    proc-sys-fs-binfmt_misc.automount                                                                          loaded active     waiting   Arbitrary Executable File Formats File System Automount Point
    dev-fuse.device                                                                                            loaded activating tentative /dev/fuse
    sys-devices-pci0000:00-0000:00:13.0-ata1-host0-target0:0:0-0:0:0:0-block-sda-sda1.device                   loaded active     plugged   Samsung_SSD_860_QVO_1TB 1
    sys-devices-pci0000:00-0000:00:13.0-ata1-host0-target0:0:0-0:0:0:0-block-sda-sda2.device                   loaded active     plugged   Samsung_SSD_860_QVO_1TB 2
    sys-devices-pci0000:00-0000:00:13.0-ata1-host0-target0:0:0-0:0:0:0-block-sda-sda3.device                   loaded active     plugged   Samsung_SSD_860_QVO_1TB 3
    sys-devices-pci0000:00-0000:00:13.0-ata1-host0-target0:0:0-0:0:0:0-block-sda-sda4.device                   loaded active     plugged   Samsung_SSD_860_QVO_1TB 4
    sys-devices-pci0000:00-0000:00:13.0-ata1-host0-target0:0:0-0:0:0:0-block-sda.device                        loaded active     plugged   Samsung_SSD_860_QVO_1TB
    sys-devices-pci0000:00-0000:00:13.0-ata2-host1-target1:0:0-1:0:0:0-block-sdb-sdb1.device                   loaded active     plugged   ST1000DM003-9YN162 1
    sys-devices-pci0000:00-0000:00:13.0-ata2-host1-target1:0:0-1:0:0:0-block-sdb.device                        loaded active     plugged   ST1000DM003-9YN162
    sys-devices-pci0000:00-0000:00:14.0-usb2-2\x2d1-2\x2d1:1.0-host2-target2:0:0-2:0:0:0-block-sdc-sdc1.device loaded active     plugged   WDC_WD20EARX-00PASB0 1
    sys-devices-pci0000:00-0000:00:14.0-usb2-2\x2d1-2\x2d1:1.0-host2-target2:0:0-2:0:0:0-block-sdc.device      loaded active     plugged   WDC_WD20EARX-00PASB0
    sys-devices-pci0000:00-0000:00:1b.0-sound-card0-controlC0.device                                           loaded active     plugged   /sys/devices/pci0000:00/0000:00:1b.0/sound/card0/controlC0
    sys-devices-pci0000:00-0000:00:1c.2-0000:02:00.0-net-enp2s0.device                                         loaded active     plugged   RTL810xE PCI Express Fast Ethernet controller
    sys-devices-pci0000:00-0000:00:1c.3-0000:03:00.0-net-wlp3s0.device                                         loaded active     plugged   RTL8723BE PCIe Wireless Network Adapter
    sys-devices-platform-serial8250-tty-ttyS1.device                                                           loaded active     plugged   /sys/devices/platform/serial8250/tty/ttyS1
    sys-devices-platform-serial8250-tty-ttyS10.device                                                          loaded active     plugged   /sys/devices/platform/serial8250/tty/ttyS10
    sys-devices-platform-serial8250-tty-ttyS11.device                                                          loaded active     plugged   /sys/devices/platform/serial8250/tty/ttyS11
    sys-devices-platform-serial8250-tty-ttyS12.device                                                          loaded active     plugged   /sys/devices/platform/serial8250/tty/ttyS12
...
~~~

### Inspecting the running services with `htop`

If you installed it, you can use `htop` to monitor in real time all the services running and the resources usage.

~~~sh
$ htop
~~~

This program offers an interactive text-based interface that, after some tinkering, can be configured to look like in this snapshot:

![Htop interface already customized](images/g011/htop_command.webp "Htop interface already customized")

## Configuring the `pveproxy` service

The PVEProxy is the component responsible for exposing the Proxmox VE API through HTTPS. It's just a specific reverse proxy that gives access to the PVE API and the web console at the 8006 port.

### Default 8006 port and listening interfaces

By default, `pveproxy` listens on all your system's network interfaces through the `8006` port. This behavior **cannot be changed in any way**, or is not documented how to do so. Hence you'll need to rely on other techniques, like firewalling or use an extra reverse proxy, to protect the PVE's proxy.

### Enforcing strong SSL/TLS ciphers

To make the `pveproxy` use strong SSL/TLS ciphers (for TLS 1.2 and below) and cipher suites (for TLS 1.3 and above) only when its negotiating TLS connections (to avoid _Man In The Middle_, or _MITM_, attacks), do the following.

1. Open a shell with `mgrsys`, `cd` to `/etc/default/` and create an empty `pveproxy` file.

    ~~~sh
    $ cd /etc/default/
    $ sudo touch pveproxy
    ~~~

2. Add to the `pveproxy` file the following lines.

    ~~~sh
    CIPHERS="ECDHE-ARIA128-GCM-SHA256:ECDHE-ARIA256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-ARIA128-GCM-SHA256:ECDHE-ECDSA-ARIA256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-PSK-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305"
    CIPHERSUITES="TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256"
    HONOR_CIPHER_ORDER="1"
    ~~~

3. Save the changes and restart the `pveproxy` service.

    ~~~sh
    $ sudo systemctl restart pveproxy.service
    ~~~

The set in the CIPHERS parameter is derived from the list of supported ciphers you can find [in Cryptcheck](https://cryptcheck.fr/ciphers). The chosen ones are the ones at the top of the list, branded with a green mark but not of the _CCM_ type. The set in `CIPHERSUITES` is the default one, which is a selection of the just five cipher suites currently available for TLS 1.3.

> [!WARNING]\
> **Ciphers evolve over time**\
> Over time, the ciphers will become outdated or deemed weak. You should check this list or a similar one from time to time to update the set of ciphers admitted in your system.

### Host based access control rules

You can apply some degree of access control by specifying a list of allowed IP addresses or ranges in the `pveproxy` configuration.

> [!IMPORTANT]
> **This approach forces you to remember to what program did you apply certain rules**\
> The `sshd` and other services also offer this kind of access control in their configuration, but managing all those rules in this disperse way is just unnecessarily hard.
>
> **Better centralize all the access control rules in the Proxmox VE firewall or putting a similar solution "in front" of all your services.**

If you really need or find useful to enforce some hard access control directly in the PVE proxy's configuration:

1. Edit the `pveproxy` file and append to it the following parameters.

    ~~~sh
    DENY_FROM="all"
    ALLOW_FROM="YOUR.PRIVATE.IP.RANGE/24,YOUR.HOME.IP.ADDRESS"
    POLICY="allow"
    ~~~

    For example, you could put in the `ALLOW_FROM` parameter something like the following.

    ~~~sh
    ALLOW_FROM="10.0.0.1-10.0.0.5,192.168.0.0/22"
    ~~~

2. Save the changes and restart the `pveproxy` service.

    ~~~sh
    $ sudo systemctl restart pveproxy.service
    ~~~

## Disabling RPC services

Since we're not using NFS in our standalone node, here you'll see how to disable all of its related services or daemons.

1. Open a shell with your `mgrsys` user, and prevent with `systemctl` the `rpcbind` services from starting up when the system boots up.

    ~~~sh
    $ sudo systemctl disable --now rpcbind.target rpcbind.socket rpcbind.service
    ~~~

    The command will output this:

    ~~~sh
    Synchronizing state of rpcbind.service with SysV service script with /lib/systemd/systemd-sysv-install.
    Executing: /lib/systemd/systemd-sysv-install disable rpcbind
    Removed "/etc/systemd/system/sockets.target.wants/rpcbind.socket".
    Removed "/etc/systemd/system/multi-user.target.wants/rpcbind.service".
    ~~~

2. `cd` to `/etc/defaults/` and make a backup of the `nfs-common` file.

    ~~~sh
    $ cd /etc/defaults
    $ sudo cp nfs-common nfs-common.orig
    ~~~

    Then, edit `nfs-common` and set its parameters as follows.

    ~~~sh
    # If you do not set values for the NEED_ options, they will be attempted
    # autodetected; this should be sufficient for most people. Valid alternatives
    # for the NEED_ options are "yes" and "no".

    # Do you want to start the statd daemon? It is not needed for NFSv4.
    NEED_STATD=no

    # Options for rpc.statd.
    #   Should rpc.statd listen on a specific port? This is especially useful
    #   when you have a port-based firewall. To use a fixed port, set this
    #   this variable to a statd argument like: "--port 4000 --outgoing-port 4001".
    #   For more information, see rpc.statd(8) or http://wiki.debian.org/SecuringNFS
    STATDOPTS=

    # Do you want to start the idmapd daemon? It is only needed for NFSv4.
    NEED_IDMAPD=no

    # Do you want to start the gssd daemon? It is required for Kerberos mounts.
    NEED_GSSD=no
    ~~~

    Notice that I've set only the `NEED_` parameters as `no`, disabling certain daemons that won't be used in this guide's PVE setup.

3. There's also a unit loaded in systemd which offers nfs client services. Let's disable it.

    ~~~sh
    $ sudo systemctl disable --now nfs-client.target
    ~~~

4. Reboot your system.

    ~~~sh
    $ sudo reboot
    ~~~

5. Finally, check what sockets are currently listening in your system.

    ~~~sh
    $ sudo ss -atlnup
    ~~~

    This will return you an output like this:

    ~~~sh
    Netid    State      Recv-Q     Send-Q         Local Address:Port         Peer Address:Port    Process
    udp      UNCONN     0          0                  127.0.0.1:323               0.0.0.0:*        users:(("chronyd",pid=784,fd=5))
    udp      UNCONN     0          0                      [::1]:323                  [::]:*        users:(("chronyd",pid=784,fd=6))
    tcp      LISTEN     0          4096               127.0.0.1:85                0.0.0.0:*        users:(("pvedaemon worke",pid=997,fd=6),("pvedaemon worke",pid=996,fd=6),("pvedaemon worke",pid=995,fd=6),("pvedaemon",pid=994,fd=6))
    tcp      LISTEN     0          100                127.0.0.1:25                0.0.0.0:*        users:(("master",pid=949,fd=13))
    tcp      LISTEN     0          128                 10.3.0.2:22                0.0.0.0:*        users:(("sshd",pid=767,fd=3))
    tcp      LISTEN     0          16                 127.0.0.1:3493              0.0.0.0:*        users:(("upsd",pid=1026,fd=4))
    tcp      LISTEN     0          4096                       *:8006                    *:*        users:(("pveproxy worker",pid=1010,fd=6),("pveproxy worker",pid=1009,fd=6),("pveproxy worker",pid=1008,fd=6),("pveproxy",pid=1007,fd=6))
    tcp      LISTEN     0          4096                       *:3128                    *:*        users:(("spiceproxy work",pid=1016,fd=6),("spiceproxy",pid=1015,fd=6))
    tcp      LISTEN     0          100                    [::1]:25                   [::]:*        users:(("master",pid=949,fd=14))
    ~~~

    The nfs service use several ports in both TCP and UDP protocols: 111, 1110, 2049, 4045. But, as you can see in the output above, none of them appear as being in use by any active socket.

## Disabling `zfs` and `ceph`

ZFS requires a lot of RAM we cannot afford in such a small server as the one used in this guide. Ceph, on the other hand, is impossible to use with just one standalone node. So let's disable all their related services.

1. Open a shell with you administrator user, and disable the `zfs` and `ceph` related services so they don't start when the node boots up:

    ~~~sh
    $ sudo systemctl disable --now zfs-mount.service zfs-share.service zfs-volume-wait.service zfs-zed.service zfs-import.target zfs-volumes.target zfs.target ceph-fuse.target
    ~~~

2. The `ceph.target` cannot be just disabled, **it has to be masked** or it will run again after a reboot:

    ~~~sh
    $ sudo systemctl mask --now ceph.target
    ~~~

3. Reboot the system.

    ~~~sh
    $ sudo reboot
    ~~~

4. Check with `htop` or `systemctl` that the `zfs` services are not running.

> [!NOTE]
> **The ZFS tab will remain visible in PVE's web console**\
> Disabling the `zfs` services **won't remove** the ZFS tab found in the PVE web console at the `pve` node level, under the `Disks` section.
>
> Also, Ceph was not really installed on your system, something notified by the PVE web console at the `Datacenter > Ceph` section, although Proxmox VE is installed with a couple of Ceph-related services.

## Disabling the SPICE proxy

The `spiceproxy` service allows SPICE clients to connect to virtual machines and containers with graphical environments. Since this guide does not contemplate having a graphical environment running in any VM or container, let's disable this proxy.

1. Open a shell with you administrator user, and mask the `spiceproxy` service.

    ~~~sh
    $ sudo systemctl mask --now spiceproxy
    ~~~

    > [!IMPORTANT]
    > **The `pve-manager` service launches `spiceproxy`**\
    > The Proxmox VE startup script called `pve-manager` starts this `spiceproxy` service, and that forces us to `mask` rather than `disable` it with `systemctl`. If you just `disable` the `spiceproxy`, it will be started again by the `pve-manager` after a reboot.

2. Reboot the system.

    ~~~sh
    $ sudo reboot
    ~~~

3. Check with `htop` or `systemctl` that the `spiceproxy` service is not running.

4. Check with `ss` that there's no `spiceproxy` process with a socket open at the `3128` port.

    ~~~sh
    $ sudo ss -atlnup | grep spiceproxy
    ~~~

    The command above should return no result whatsoever.

> [!NOTE]
> **The `SPICE` option will remain available**\
> The `SPICE` option offered by the PVE web console will still be present in the `Shell` list, although of course you won't be able to connect to the server through that method now.
> 
> ![The SPICE option remains available among the web console's shell options](images/g011/pve_web_console_shell_options.webp "The SPICE option remains available among the web console's shell options")

## Disabling cluster and high availability related services

Since we're working just with a standalone node, it doesn't make much sense to have cluster or high availability related services running for nothing.

1. Open a shell with you administrator user, and with the `systemctl` command disable and stop the services as follows.

    ~~~sh
    $ sudo systemctl disable --now pve-ha-crm pve-ha-lrm corosync
    ~~~

2. Reboot the system.

    ~~~sh
    $ sudo reboot
    ~~~

3. Check either with `htop` or `systemctl` that the `pve-ha-crm` and `pve-ha-lrm` services are not running. Corosync wasn't running since your node is a standalone one.

> [!WARNING]
> **Do not attempt to disable the `pve-cluster` daemon**\
> [The Proxmox VE documentation explicitly says](https://pve.proxmox.com/wiki/Service_daemons#pve-cluster) that this service is **needed** even when not running a cluster.

## Considerations

### Errors in the `apt upgrade` process

Disabling or masking PVE related services may provoke errors during the `apt upgrade` process of Proxmox VE packages, as it can happen with the `pve-manager` when `apt` does not find the `spiceproxy` daemon available. The update process of some of those PVE packages may expect a certain service to be present or running in the system, and they may try to restart them as part of the update process.

You should expect these error happening anytime you run an update of your system, although your Proxmox VE standalone node should keep on running just fine. Any time you end an upgrade process with errors, try the command `sudo apt autoremove` to make `apt` or `dpkg` treat them somehow.

### View of services running in the Proxmox VE node

The Proxmox VE web console has a view, at the node level, where you can see the current status of the Proxmox VE-related service units running in your host.

![PVE web console's System view](images/g011/pve_web_console_system_services_view.webp "PVE web console's System view")

For example, notice how the `corosync`, `pve-ha-crm` and `pve-ha-lrm` services are reported _dead_ with their systemd units _disabled_. Meanwhile, the `spiceproxy` service is listed as _disabled_ with its systemd unit _masked_ (which explains why its line has been rendered in a light gray color) .

> [!IMPORTANT]
> **The System view only shows PVE-related services**\
> The services shown in this System view are only the ones Proxmox VE is directly concerned with. Other services running in your PVE host will not appear here.

## Relevant system paths

### Directories

- `/etc/default`

### Files

- `/etc/default/nfs-common`
- `/etc/default/nfs-common.orig`
- `/etc/default/pveproxy`

## References

### Services management in Debian

- [How to Start, Stop and Restart Services in Debian 10](https://vitux.com/how-to-start-stop-and-restart-services-in-debian-10/)
- [The directory `/etc/default/`](https://www.linuxquestions.org/questions/slackware-14/the-directory-etc-default-723942/)
- [What is the purpose of /etc/default?](https://superuser.com/questions/354944/what-is-the-purpose-of-etc-default)

### Proxmox hardening and standalone node optimization

- [Hardening Proxmox, some in one place](https://blog.samuel.domains/blog/security/hardening-proxmox-some-in-one-place)
- [Proxmox Lite](https://www.lowendtalk.com/discussion/165481/proxmox-lite)
- [PROXMOX Standalone or Cluster](https://www.reddit.com/r/Proxmox/comments/i3mupd/proxmox_standalone_or_cluster/)

### Proxmox VE service daemons

- [Proxmox VE wiki. Service daemons](https://pve.proxmox.com/wiki/Service_daemons)

### NFS and RPC

- [Is it possible to disable rpcbind (port 111) and how to do it?](https://forum.proxmox.com/threads/is-it-possible-to-disable-rpcbind-port-111-and-how-to-do-it.33590/)
- [Is rpcbind needed for an NFS client?](https://serverfault.com/questions/1015970/is-rpcbind-needed-for-an-nfs-client)
- [What is the purpose of rpcbind service on Linux Systems?](https://www.quora.com/What-is-the-purpose-of-rpcbind-service-on-Linux-Systems)
- [Which ports do I need to open in the firewall to use NFS?](https://serverfault.com/questions/377170/which-ports-do-i-need-to-open-in-the-firewall-to-use-nfs)

### Default listening behaviour of `pveproxy`

- [pveproxy LISTEN address](https://forum.proxmox.com/threads/pveproxy-listen-address.75376/).

### Configuration of SSL/TSL ciphers in `pveproxy`

- [pveproxy - Disable weak SSL ciphers?](https://forum.proxmox.com/threads/pveproxy-disable-weak-ssl-ciphers.14794/page-3)
- [Supported cipher suites - List of SSL ciphers and it's quality](https://cryptcheck.fr/ciphers)
- [Cipher Suites Explained in Simple Terms: Unlocking the Code](https://www.ssldragon.com/blog/cipher-suites/)
- [Cipher Suites: Ciphers, Algorithms and Negotiating Security Settings](https://www.thesslstore.com/blog/cipher-suites-algorithms-security-settings/)

### ZFS and Ceph

- [ZFS on Linux](https://pve.proxmox.com/wiki/ZFS_on_Linux).
- [Deploy Hyper-Converged Ceph Cluster](https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster).

### SPICE proxy

- [PVE admin manual. spiceproxy - SPICE Proxy Service](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_spiceproxy_spice_proxy_service)
- [disable spiceproxy](https://forum.proxmox.com/threads/disable-spiceproxy.36638/)
- [pve-manager and other updates with optional services masked](https://forum.proxmox.com/threads/pve-manager-and-other-updates-with-optional-services-masked.63652/)

## Navigation

[<< Previous (**G010. Host hardening 04**)](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G012. Host hardening 06**) >>](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md)
