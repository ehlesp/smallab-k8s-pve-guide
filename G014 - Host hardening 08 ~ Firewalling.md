# G014 - Host hardening 08 ~ Firewalling

- [Enabling your PVE's firewall is a must](#enabling-your-pves-firewall-is-a-must)
- [Proxmox VE firewall uses iptables](#proxmox-ve-firewall-uses-iptables)
  - [iptables is a legacy package](#iptables-is-a-legacy-package)
- [Zones in the Proxmox VE firewall](#zones-in-the-proxmox-ve-firewall)
- [Situation at this point](#situation-at-this-point)
- [Enabling the firewall at the Datacenter tier](#enabling-the-firewall-at-the-datacenter-tier)
  - [Netfilter conntrack sysctl parameters](#netfilter-conntrack-sysctl-parameters)
- [Firewalling with ebtables](#firewalling-with-ebtables)
  - [Setting up ebtables](#setting-up-ebtables)
  - [Example of ebtables usage](#example-of-ebtables-usage)
- [Firewall fine tuning](#firewall-fine-tuning)
  - [Enabling TCP SYN flood protection](#enabling-tcp-syn-flood-protection)
- [Firewall logging](#firewall-logging)
  - [Understanding the firewall log](#understanding-the-firewall-log)
- [Connection tracking tool](#connection-tracking-tool)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Proxmox VE firewall](#proxmox-ve-firewall)
  - [Ethernet Bridge firewall ebtables](#ethernet-bridge-firewall-ebtables)
  - [Network auditing on Linux](#network-auditing-on-linux)
  - [Network security concepts](#network-security-concepts)
  - [Networking concepts](#networking-concepts)
  - [conntrack command](#conntrack-command)
- [Navigation](#navigation)

## Enabling your PVE's firewall is a must

One of the strongest hardening measures you can apply is a proper firewall, and Proxmox VE comes with one integrated. Needless to say, you must enable and configure this firewall to secure your system.

## Proxmox VE firewall uses iptables

The Proxmox VE firewall is based on iptables, meaning that any rules defined within the PVE firewall will be enforced by the underlying iptables firewall present in your standalone node. In a cluster, those rules are spread by the PVE firewall daemon through all the nodes.

### iptables is a legacy package

The iptables is a legacy package that has been replaced by [nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) (where `nf` stands for _Netfilter_), but Proxmox VE 8.4 is still using iptables. You can verify this by printing the iptables version.

~~~sh
$ sudo iptables -V
iptables v1.8.9 (legacy)
~~~

> [!NOTE]
> **You can enable in your Proxmox VE system a nftables-based version of its firewall**\
> At the time of writing this, [the new nftables-based `proxmox-firewall` service it is still in the _tech-preview_ stage](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#pve_firewall_nft). Therefore, this guide sticks to the legacy iptables-based firewall, which is the one that comes enabled by default in a Proxmox VE 8.4 server.
>
> If you want to try using the nftables firewall, know that the configuration explained here is compatible with the new firewall since it uses the same files and configuration format.

> [!NOTE]
> **Careful of not confusing nftables commands with iptables ones**\
> There are several iptables commands available in the system, but some of them are meant to be used with the nftables firewall. So, when you execute iptables commands, avoid using the ones that have the `-nft` string in their names (unless you have switched to the new nftables firewall).

## Zones in the Proxmox VE firewall

The [Proxmox VE documentation](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#_zones) indicates that the firewall groups the network in three logical zones:

- **Host**\
  Traffic from/to a cluster node (a host).

- **VM**\
  Traffic from/to a specific VM or container.

- **VNet**\
  Traffic passing through a SDN VNet, either from guest to guest or from host to guest and vice-versa.

But the same documentation also mentions three distinct tiers, or levels, that are contemplated by the PVE firewall: datacenter (the cluster), hosts (the cluster nodes) and guests (the virtual machines or containers).

Be always aware that these tiers or zones are kind of independent from each other. Essentially, the firewall has to be enabled on each level individually, and the rules applied at the datacenter level won't be applied automatically in cascade to the lower tiers. You will have to enable each firewall option specifically for each level, and for each virtual NIC on each guest in the case of VMs and containers.

Also, know that the PVE firewall offers different options for each tier.

## Situation at this point

By enabling Fail2Ban in the previous [**G010** chapter](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md), you have also enabled the iptables firewall at the **node level**. You can verify this in the web console at the `pve` node level, by going to the `Firewall > Options` of your standalone node.

![Firewall enabled at the node level](images/g014/pve_firewall_enabled_node_level.webp "Firewall enabled at the node level")

But, on the other hand, the PVE firewall **is NOT running at the `Datacenter` tier**.

![Firewall disabled at the datacenter tier](images/g014/pve_firewall_disabled_datacenter_tier.webp "Firewall disabled at the datacenter tier")

The Proxmox VE documentation indicates that the firewall comes completely disabled, at all levels we should understand, after the installation. That's why you find the `Firewall` disabled at the `Datacenter` level.

Also, from the PVE web console's point of view, the firewall doesn't seem to have rules whatsoever, something you can check when you go directly into the `Firewall` screen of either the `Datacenter` or the node tier.

![No rules present in firewall at the node level](images/g014/pve_firewall_no_rules_node_level.webp "No rules present in firewall at the node level")

The _No firewall rule configured here._ line highlighted in the snapshot above is mostly correct. If you open a shell terminal in your node as your `mgrsys` user, you can check the rules actually enabled in the iptables firewall of your Proxmox VE server.

~~~sh
$ sudo iptables -L -n
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
~~~

There are no rules per se, just empty _chains of rules_. Still, you can see how each `Chain` has a policy already established: all chains are **accepting everything** with the default `ACCEPT` policy. Your firewall is completely open, something you do not want at all.

Next, let's revise which are the ports currently open in your PVE system.

~~~sh
$ sudo ss -atlnup
Netid            State             Recv-Q            Send-Q                       Local Address:Port                       Peer Address:Port           Process
udp              UNCONN            0                 0                                127.0.0.1:323                             0.0.0.0:*               users:(("chronyd",pid=752,fd=5))
tcp              LISTEN            0                 100                              127.0.0.1:25                              0.0.0.0:*               users:(("master",pid=926,fd=13))
tcp              LISTEN            0                 4096                             127.0.0.1:85                              0.0.0.0:*               users:(("pvedaemon worke",pid=979,fd=6),("pvedaemon worke",pid=978,fd=6),("pvedaemon worke",pid=977,fd=6),("pvedaemon",pid=976,fd=6))
tcp              LISTEN            0                 16                               127.0.0.1:3493                            0.0.0.0:*               users:(("upsd",pid=1004,fd=4))
tcp              LISTEN            0                 128                               10.3.0.2:22                              0.0.0.0:*               users:(("sshd",pid=733,fd=3))
tcp              LISTEN            0                 4096                                     *:8006                                  *:*               users:(("pveproxy worker",pid=991,fd=6),("pveproxy worker",pid=990,fd=6),("pveproxy worker",pid=989,fd=6),("pveproxy",pid=988,fd=6))
~~~

If you've followed this guide closely, you should get a list of listening sockets like the output above:

- Service `chronyd` listening on localhost (`127.0.0.1`) interface at port `323`:\
  Daemon for synchronizing the system's clock with an external time server (already seen back in the [**G012** guide](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md)).

- Service `master` listening on localhost (`127.0.0.1`) interface at port `25`:\
  Postmaster mail service providing mailing within the system itself.

- Service `pvedaemon` listening on localhost (`127.0.0.1`) interface at port `85`:
  Exposes the whole Proxmox VE API.

- Service `upsd` listening on localhost (`127.0.0.1`) interface at port `3493`:
  NUT service for monitoring your UPS.

- Service `sshd` listening on the host's network Ethernet interface (`10.3.0.2`) at port `22`:
  SSH daemon service.

- Service `pveproxy` listening on all interfaces (`0.0.0.0`) at port `8006`:
  Proxmox VE proxy that gives access to the web console and also exposes the Proxmox VE API.

## Enabling the firewall at the Datacenter tier

Just by enabling the PVE firewall at the `Datacenter` tier you'll get a much stronger set of rules enforced in your firewall. But, before you do this...

> [!WARNING]
> **Read this before enabling the firewall at the `Datacenter` tier**\
> After enabling the firewall at the `Datacenter` tier, your Proxmox VE platform will block incoming traffic from all hosts towards your datacenter, except the traffic coming from your LAN towards the 8006 (web console) and 22 (ssh) ports.
>
> If you plan to access your PVE platform **from IPs outside your LAN**, you'll need to **add first** the rules in the PVE firewall to allow such access. But I won't cover this here, since I'm just assuming a "pure" LAN scenario (meaning a Proxmox VE server **not accessible** from internet), in this guide series.

Assuming you are accessing your PVE system from another computer in the same LAN, go to the `Datacenter > Firewall > Options` screen in the web console and select the `Firewall` parameter.

![Selecting Firewall parameter at Datacenter level](images/g014/pve_firewall_enabling_datacenter_tier.webp "Selecting Firewall parameter at Datacenter level")

Click on `Edit` and mark the `Firewall` checkbox presented to enable the firewall at the `Datacenter` tier.

![Enabling firewall option at datacenter tier](images/g014/pve_firewall_enabling_datacenter_tier_checking_option.webp "Enabling firewall option at Datacenter tier")

Hit `OK` and you'll see the `Firewall` parameter has a `Yes` value now.

![Firewall enabled at Datacenter tier](images/g014/pve_firewall_enabled_datacenter_tier.webp "Firewall enabled at Datacenter tier")

The change will be applied immediately, but you won't see any rules at all in the `Firewall` screens, neither at the `Datacenter` nor at the `pve` node level. But the iptables ruleset will change a lot, something you can verify with the iptables command.

~~~sh
$ sudo iptables -L -n
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
PVEFW-INPUT  0    --  0.0.0.0/0            0.0.0.0/0

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination
PVEFW-FORWARD  0    --  0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
PVEFW-OUTPUT  0    --  0.0.0.0/0            0.0.0.0/0

Chain PVEFW-Drop (1 references)
target     prot opt source               destination
PVEFW-DropBroadcast  0    --  0.0.0.0/0            0.0.0.0/0
ACCEPT     1    --  0.0.0.0/0            0.0.0.0/0            icmptype 3 code 4
ACCEPT     1    --  0.0.0.0/0            0.0.0.0/0            icmptype 11
DROP       0    --  0.0.0.0/0            0.0.0.0/0            ctstate INVALID
DROP       17   --  0.0.0.0/0            0.0.0.0/0            multiport dports 135,445
DROP       17   --  0.0.0.0/0            0.0.0.0/0            udp dpts:137:139
DROP       17   --  0.0.0.0/0            0.0.0.0/0            udp spt:137 dpts:1024:65535
DROP       6    --  0.0.0.0/0            0.0.0.0/0            multiport dports 135,139,445
DROP       17   --  0.0.0.0/0            0.0.0.0/0            udp dpt:1900
DROP       6    --  0.0.0.0/0            0.0.0.0/0            tcp flags:!0x17/0x02
DROP       17   --  0.0.0.0/0            0.0.0.0/0            udp spt:53
           0    --  0.0.0.0/0            0.0.0.0/0            /* PVESIG:83WlR/a4wLbmURFqMQT3uJSgIG8 */

Chain PVEFW-DropBroadcast (2 references)
target     prot opt source               destination
DROP       0    --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type BROADCAST
DROP       0    --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type MULTICAST
DROP       0    --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type ANYCAST
DROP       0    --  0.0.0.0/0            224.0.0.0/4
           0    --  0.0.0.0/0            0.0.0.0/0            /* PVESIG:NyjHNAtFbkH7WGLamPpdVnxHy4w */

Chain PVEFW-FORWARD (1 references)
target     prot opt source               destination
DROP       0    --  0.0.0.0/0            0.0.0.0/0            ctstate INVALID
ACCEPT     0    --  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
PVEFW-FWBR-IN  0    --  0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-in fwln+ --physdev-is-bridged
PVEFW-FWBR-OUT  0    --  0.0.0.0/0            0.0.0.0/0            PHYSDEV match --physdev-out fwln+ --physdev-is-bridged
           0    --  0.0.0.0/0            0.0.0.0/0            /* PVESIG:qnNexOcGa+y+jebd4dAUqFSp5nw */
...
~~~

I've omitted most of the output since it is quite long, but you can see that quite a lot of rules have been added just by enabling the firewall at the `Datacenter` tier.

The Proxmox VE firewall's configuration files can be found at the following locations.

- `/etc/pve/firewall/cluster.fw`\
  For the datacenter or cluster wide tier.

- `/etc/pve/firewall/<VMID>.fw`\
  For each virtual machine or container, identified by their `<VMID>`, present in the system.

- `/etc/pve/nodes/<nodename>/host.fw`\
  For each node, identified by their `<nodename>`, present in the datacenter.

- `/etc/pve/sdn/firewall/<vnet_name>.fw`\
  For each VNet configured in the system, identified by their `<vnet_name>`.

### Netfilter conntrack sysctl parameters

I hinted you in the [G012 chapter](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md) how, by enabling the firewall, new `sysctl` parameters would become available in your Proxmox VE host. Those new parameters are all the files put in the `/proc/sys/net/netfilter` folder, except the `nf_log` ones which were already present initially. All of them are related to the netfilter conntrack system used to track network connections on the system. A new `/proc/sys/net/nf_conntrack_max` file is also created as a duplicate of the `/proc/sys/net/netfilter/nf_conntrack_max` file, maybe as a management convenience for Proxmox VE.

But not only new parameters are enabled, some already existing ones get changed. In particular the `net.bridge.bridge-nf-call-ip6tables` and `net.bridge.bridge-nf-call-iptables` are set to `1`, enabling filtering on the bridges existing on the host. In fact, at this point your system already has one Linux bridge enabled, which you can find in the `pve` node level at the `System > Network` view.

![Linux bridge at pve node network](images/g014/pve_node_system_network_bridge.webp "Linux bridge at pve node network")

In the capture above, you can see how this Linux bridge uses the host's Ethernet network card `enp0s3` as port to have access to the network. This bridge is necessary for later being able to provide network connectivity to the VMs you'll create in later chapters. But keep on reading this guide to see how to apply firewalling at the bridge level with **ebtables**.

## Firewalling with ebtables

When you enabled the firewall at the datacenter level, you might have noticed the ebtables option which was already enabled.

![ebtables option at Datacenter firewall](images/g014/pve_firewall_ebtables_option.webp "ebtables option at Datacenter firewall")

This option refers to the ebtables program that works as a firewall for bridges, like the one you have in your PVE virtual network. This firewall is mainly for filtering packets at the network's link layer, in which MACs (not IPs) and VLAN tags are what matter to route packets. On the other hand, ebtables is also capable of some packet filtering on upper network layers. The problem is that Proxmox VE does not have a page where you can manage ebtables rules, forcing you to handle them with the corresponding `ebtables` shell command.

> [!WARNING]
> **The ebtables firewall is a legacy program**\
> As it happens with iptables, ebtables is also a legacy package that has an alternative version meant for nftables. Therefore, in a Proxmox VE setup based on this guide, only use the ebtables commands that do not include the `-nft` string in their names.

### Setting up ebtables

The `ebtables` command handles rules but is unable to make them persist, meaning that any rules you may add to the ebtables won't survive a reboot. But there is a way to persist these rules in your system:

> [!WARNING]
> **This configuration may not work with the nftables version of ebtables**\
> Keep this in mind if you want to try the nftables-based firewall of Proxmox VE.

1. Open a shell as `mgrsys` on your Proxmox VE host, then install the package `netfilter-persistent`:

    ~~~sh
    $ sudo apt install netfilter-persistent
    ~~~

    This package provides a "_loader for netfilter configuration_" and, with the proper extension (a shell script), it can handle ebtables configuration too.

2. Create a new empty file at `/usr/share/netfilter-persistent/plugins.d/35-ebtables`:

    ~~~sh
    $ sudo touch /usr/share/netfilter-persistent/plugins.d/35-ebtables
    ~~~

    Then make it executable.

    ~~~sh
    $ sudo chmod 544 /usr/share/netfilter-persistent/plugins.d/35-ebtables
    ~~~

3. Copy in the `/usr/share/netfilter-persistent/plugins.d/35-ebtables` file the whole shell script below:

    ~~~sh
    #!/bin/sh

    # This file is part of netfilter-persistent
    # (was iptables-persistent)
    # Copyright (C) 2009, Simon Richter <sjr@debian.org>
    # Copyright (C) 2010, 2014 Jonathan Wiltshire <jmw@debian.org>
    #
    # This program is free software; you can redistribute it and/or
    # modify it under the terms of the GNU General Public License
    # as published by the Free Software Foundation, either version 3
    # of the License, or (at your option) any later version.

    set -e

    rc=0
    done=0

    TABLES="filter nat broute"

    for i in $TABLES; do
        modprobe -q ebtable_$i
    done

    RULES=/etc/ebtables/rules

    if [ -x ebtables ]; then
        echo "Warning: ebtables binary not available"
        exit
    fi

    load_rules()
    {
        #load ebtables rules
        for i in $TABLES; do
            done=1
            if [ -f $RULES.$i ]; then
                ebtables -t $i --atomic-file $RULES.$i --atomic-commit
                if [ $? -ne 0 ]; then
                    rc=1
                fi
            fi
        done
        if [ "x$done" = "x0" ]; then
            echo "Warning: skipping ebtables (no rules to load)"
        fi
    }

    save_rules()
    {
        #save ebtables rules
        for i in $TABLES; do
            ebtables -t $i --atomic-file $RULES.$i --atomic-save
            # zero the counters
            ebtables -t $i --atomic-file $RULES.$i -Z
        done
    }

    flush_rules()
    {
        for i in $TABLES; do
            ebtables -t $i --init-table
        done
    }

    case "$1" in
    start|restart|reload|force-reload)
        load_rules
        ;;
    save)
        save_rules
        ;;
    stop)
        # Why? because if stop is used, the firewall gets flushed for a variable
        # amount of time during package upgrades, leaving the machine vulnerable
        # It's also not always desirable to flush during purge
        echo "Automatic flushing disabled, use \"flush\" instead of \"stop\""
        ;;
    flush)
        flush_rules
        ;;
    *)
        echo "Usage: $0 {start|restart|reload|force-reload|save|flush}" >&2
        exit 1
        ;;
    esac

    exit $rc
    ~~~

    This script (found attached to [this old Debian Bug thread](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=697088)) is the extension that allows `netfilter-persistent` to truly persist the ebtables rules in your system.

4. Create the empty folder `/etc/ebtables`:

    ~~~sh
    $ sudo mkdir /etc/ebtables
    ~~~

    This is the folder where the previous `35-ebtables` shell script will persist the ebtables rules, in several `rules` files.

5. Make the script save the current ebtables rules to check if it works:

    ~~~sh
    $ sudo /usr/share/netfilter-persistent/plugins.d/35-ebtables save
    ~~~

    Then list the contents of `/etc/ebtables` and see if the `rules` files are there.

    ~~~sh
    $ ls /etc/ebtables/
    rules.broute  rules.filter  rules.nat
    ~~~

    You should see three different rule files, as in the output above. The files are in binary format, so **do not open them with a text editor**. Each file corresponds to one of the tables ebtables uses to separate its functionality into different sets of rules. The `filter` table is the default one on which the ebtables command works.

### Example of ebtables usage

Next, I'll give you an example about when and how to use ebtables based on my own experience.

> [!NOTE]
> **The example shown here is based on the original hardware setup I used for the first version of this guide**\
> Therefore you will notice small differences with the virtualized hardware I'm using in this newer version of the guide. Still, the commands used in this example are still valid.

While I was working in the first version of this guide, I detected that incoming (`RX`) packets were being dropped only by the `vmbr0` bridge for some unknown reason. I noticed this in the output of the following `ip` command.

~~~sh
$ ip -s link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    RX: bytes  packets  errors  dropped missed  mcast
    62755      932      0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    62755      932      0       0       0       0
2: enp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0 state UP mode DEFAULT group default qlen 1000
    link/ether a8:ae:ed:27:c1:7d brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped missed  mcast
    327191     3186     0       0       0       2279
    TX: bytes  packets  errors  dropped carrier collsns
    65623      639      0       0       0       0
3: wlp3s0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 64:39:ac:32:cb:23 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped missed  mcast
    0          0        0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    0          0        0       0       0       0
4: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether a8:ae:ed:27:c1:7d brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped missed  mcast
    280443     3186     0       1494    0       2279
    TX: bytes  packets  errors  dropped carrier collsns
    65677      640      0       0       0       0
~~~

In the output above, you can see that only the `vmbr0` interface is reporting many `dropped` `RX` packets. As you can imagine, this was kind of bothersome, so I tracked them down. To do that there is a command called `tcpdump` that comes handy to see the packets themselves. The command captures the traffic going on in your system's network and prints a description of each packet it sees. I executed `tcpdump` as follows.

~~~sh
$ sudo tcpdump -vvv -leni vmbr0 > captured-packets.txt
~~~

Notice the following in the `tcpdump` command:

- `-vvv`: enables the command's maximum verbosity.
- `leni`: enables printing more details from each intercepted packet
- `vmbr0`: the interface where I want to get the traffic from.
- `> captured-packets.txt`: instead of dumping the output on screen, I redirected it to a file.

This command will run in the foreground for as long as you allow it till you stop it (with `Ctrl+C`). I gave `tcpdump` about a minute to be sure that it would have enough time to catch those misteriously dropped packets, then stopped it. Next, I opened the `captured-packets.txt` file and saw something like the following.

~~~log
21:53:15.420381 a8:ae:ed:27:c1:7d > 63:6d:87:4a:1b:cd, ethertype IPv4 (0x0800), length 166: (tos 0x10, ttl 64, id 27256, offset 0, flags [DF], proto TCP (6), length 152)
    192.168.1.107.22 > 192.168.1.2.10977: Flags [P.], cksum 0x84ac (incorrect -> 0x4055), seq 1921226259:1921226371, ack 2434765221, win 501, length 112
21:53:15.428254 63:6d:87:4a:1b:cd > a8:ae:ed:27:c1:7d, ethertype IPv4 (0x0800), length 54: (tos 0x0, ttl 128, id 51333, offset 0, flags [DF], proto TCP (6), length 40)
    192.168.1.2.10977 > 192.168.1.107.22: Flags [.], cksum 0xd35f (correct), seq 1, ack 0, win 512, length 0
21:53:15.471631 63:6d:87:4a:1b:cd > a8:ae:ed:27:c1:7d, ethertype IPv4 (0x0800), length 54: (tos 0x0, ttl 128, id 51334, offset 0, flags [DF], proto TCP (6), length 40)
    192.168.1.2.10977 > 192.168.1.107.22: Flags [.], cksum 0xd2f0 (correct), seq 1, ack 112, win 511, length 0
21:53:15.519341 16:71:9c:d3:30:8b > 01:80:c2:00:00:00, 802.3, length 38: LLC, dsap STP (0x42) Individual, ssap STP (0x42) Command, ctrl 0x03: STP 802.1d, Config, Flags [none], bridge-id 8000.16:71:9c:d3:30:8b.8002, length 35
        message-age 0.00s, max-age 20.00s, hello-time 2.00s, forwarding-delay 0.00s
        root-id 8000.16:71:9c:d3:30:8b, root-pathcost 0
21:53:17.438893 16:71:9c:d3:30:8b > 01:80:c2:ef:03:fe, ethertype Unknown (0xfe68), length 111:
        0x0000:  0303 0485 f90f 0080 0180 c2ef 03fe 1882  ................
        0x0010:  8cb3 202b 004f 5350 0303 0085 f90f 0080  ...+.OSP........
        0x0020:  b5cb a588 a39d 51e9 45b5 cba5 88a3 9d51  ......Q.E......Q
        0x0030:  e942 45b7 eb4d 1e68 cac6 8ce6 6cb6 2354  .BE..M.h....l.#T
        0x0040:  103e 1b7a f801 86ec c328 901f aeca 241d  .>.z.....(....$.
        0x0050:  73d0 1c8d 82a0 32be 1c8d 82a0 32be 1c8d  s.....2.....2...
        0x0060:  82                                       .
21:53:17.438900 16:71:9c:d3:30:8b > 01:80:c2:ef:03:fe, ethertype Unknown (0xfe68), length 102:
        0x0000:  0303 0485 f90f 00c0 0180 c2ef 03fe 1882  ................
        0x0010:  8cb3 202b 0d4f 5350 0303 0d85 f90f 00c0  ...+.OSP........
        0x0020:  b5cb a588 a39d 51e9 45bc 5f5e 8382 a008  ......Q.E._^....
        0x0030:  aba9 be1c 8dc0 77a0 7fa6 40bd 85df ac59  ......w...@....Y
        0x0040:  9b18 3332 9364 05e9 6e06 45b7 c2ba 6e06  ..32.d..n.E...n.
        0x0050:  45b7 c2ba 6e06 45b7                      E...n.E.
21:53:17.438903 16:71:9c:d3:30:8b > 01:80:c2:ef:03:fe, ethertype Unknown (0xfe68), length 180:
        0x0000:  0303 0485 f90f 00c0 0180 c2ef 03fe 1882  ................
        0x0010:  8cb3 202b 0d4f 5350 0303 0e85 f90f 00c0  ...+.OSP........
        0x0020:  bf2b 564a 85ad 0c4b 60de d1da b1f8 63c3  .+VJ...K`.....c.
        0x0030:  1a7a 9114 228d 82a0 32be 1c8d 82a0 32be  .z.."...2.....2.
        0x0040:  1c8d 82a0 32be 1c8d 82a0 32be 1c8d 82a0  ....2.....2.....
        0x0050:  32be 1c8d 82a0 32be 1c8d 82a0 32be 1c8d  2.....2.....2...
        0x0060:  82a0 32be 1c8d 82a0 32be 1c8d 82a0 32be  ..2.....2.....2.
        0x0070:  1c8d 82a0 32be 1c8d 82a0 32be 1cad 3ad6  ....2.....2...:.
        0x0080:  2ca5 a63f ddcb 9371 86ad 3cf8 5318 31f4  ,..?...q..<.S.1.
        0x0090:  c29a f111 328e 7aa2 d46d 3fdd d932 8fa3  ....2.z..m?..2..
        0x00a0:  22be 2e20 b959                           "....Y
21:53:17.518887 16:71:9c:d3:30:8b > 01:80:c2:00:00:00, 802.3, length 38: LLC, dsap STP (0x42) Individual, ssap STP (0x42) Command, ctrl 0x03: STP 802.1d, Config, Flags [none], bridge-id 8000.16:71:9c:d3:30:8b.8002, length 35
        message-age 0.00s, max-age 20.00s, hello-time 2.00s, forwarding-delay 0.00s
        root-id 8000.16:71:9c:d3:30:8b, root-pathcost 0
...
~~~

From all the traffic I saw there, the thing that stood out were the packets with the `ethertype Unknown (0xfe68)` string on them. I investigated further, but the best guess I could find was that the routers or modems installed by internet service providers (ISPs) send packets like those for some reason every second or so. Knowing that much, those packets were just noise to me in my system's network, and I wanted to drop them silently before they ever reached my `vmbr0` bridge. To do this I just needed to add the proper rule in ebtables.

~~~sh
$ sudo ebtables -A INPUT -p fe68 -j DROP
~~~

The command above means the following:

- The rule table is omitted, meaning this rule will be added to the default `filter` table.

- `-A INPUT`: append rule to rule chain `INPUT`.

- `-p fe68`: packet protocol or ethertype `fe68`, which is the hexadecimal number returned by `tcpdump`.

- `-j DROP`: target of this rule, `DROP` in this case.

With the rule added, I checked how it looked in the `filter` table of ebtables:

~~~sh
$ sudo ebtables -L
Bridge table: filter

Bridge chain: INPUT, entries: 1, policy: ACCEPT
-p 0xfe68 -j DROP

Bridge chain: FORWARD, entries: 1, policy: ACCEPT
-j PVEFW-FORWARD

Bridge chain: OUTPUT, entries: 0, policy: ACCEPT

Bridge chain: PVEFW-FORWARD, entries: 3, policy: ACCEPT
-p IPv4 -j ACCEPT
-p IPv6 -j ACCEPT
-o fwln+ -j PVEFW-FWBR-OUT

Bridge chain: PVEFW-FWBR-OUT, entries: 0, policy: ACCEPT
~~~

See in this output that:

- The `ebtables -L` command only shows the `filter` table. To specify which table to see, you have to use the `-t` option as in `ebtables -t filter -L`.

- My new rule appears in the bridge chain `INPUT`.

- Proxmox VE also has its own rules in ebtables, see the `PVEFW-FORWARD` and `PVEFW-FWBR-OUT` rule chains.

The final step was persisting the rules with the `netfilter-persistent` command.

~~~sh
$ sudo netfilter-persistent save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/35-ebtables save
~~~

Notice how, in the command's output, how it calls the `35-ebtables` shell script. Now, if you rebooted your Proxmox VE host, the `netfilter-persistent` command would restore the ebtables rules you've just persisted, also invoking the `35-ebtables` script for that. Look for this loading in the `/var/log/syslog` file, by searching the `netfilter-persistent` string.

Thanks to this configuration, I don't have any more `dropped` packets of that unknown ethertype showing up on my `vmbr0` bridge.

~~~sh
$ ip -s link show vmbr0
4: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether a8:ae:ed:27:c1:7d brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped missed  mcast
    123734     1392     0       0       0       1117
    TX: bytes  packets  errors  dropped carrier collsns
    32132      302      0       0       0       0
~~~

## Firewall fine tuning

You now have your Proxmox VE's firewall up and running with default settings, but you can adjust it further. In particular, there are a number of options at the node level you should have a look to. Browse to the `Firewall > Options` view at your `pve` node level.

![Firewall options at pve node level](images/g014/pve_firewall_node_level_options.webp "Firewall options at pve node level")

Since the official documentation is not very detailed about them, let me tell you a bit about these options:

- `Firewall`\
  Disabled by default. Enables the firewall at the `pve` node/host level.

- `SMURFS filter`\
  Enabled by default. Gives protection against SMURFS attacks, which are a form of distributed denial of service (DDoS) attacks "[that overloads network resources by broadcasting ICMP echo requests to devices across the network](https://www.fortinet.com/resources/cyberglossary/smurf-attack)".

- `TCP flags filter`\
  Disabled by default. Blocks illegal TCP flag combinations that could be found in packets.

- `NDP`\
  Enabled by default. NDP stands for _Neighbor Discovery Protocol_, and it's the IPv6 version of IPv4's ARP (_Address Resolution Protocol_). Since IPv6 is disabled in this guide series' setup, you could disable this option.

- `nf_conntrack_max`\
  `262144` by default. This value corresponds to both the `sysctl` parameters `net.netfilter.nf_conntrack_max` and `net.nf_conntrack_max`, meaning that by changing this value you'll change the two of them at the same time.

  These two values limit how many simultaneous connections can be established with your host and be tracked in the corresponding connections table maintained by netfilter. When the maximum value is reached, your host will stop accepting new TCP connections silently. If you detect connectivity issues in your setup, one of the things you can try is making this value bigger.

  This is one of the sysctl parameters enabled by the firewall when it got fully active, as I mentioned back in the [G012 guide](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md).

- `nf_conntrack_tcp_timeout_established`\
  `432000` by default (in seconds). This value says for how long established connections can be considered to be in such state, before being discarded as too old. The default value is equivalent to 5 days, which may or may not be excessive for your needs or requirements. If you want to reduce this value, know that the Proxmox VE web console won't allow you to put a value lower than `7875` seconds, which is equivalent to roughly 2 hours and 11 minutes.

- `log_level_in`\
  `nolog` value by default. To enable the logging of the firewall activity with traffic INCOMING into your host, edit this value and choose `info`. This way, you'll manage to see things like dropped packets. There are other logging levels you can choose from, as shown in the capture below.

  ![Firewall log levels](images/g014/pve_firewall_log_level_values.webp "Firewall log levels")

- `log_level_out`\
  `nolog` value by default. Change it to `info` to see the firewall activity with traffic OUTGOING from your host.

- `log_level_forward`\
  `nolog` value by default. Change it to `info` to see the firewall activity regarding the traffic FORWARDED towards your VMs.

- `tcp_flags_log_level`\
  `nolog` value by default. To see logs of firewall actions related to TCP flags filtering.

- `smurf_log_level_in`\
  `nolog` value by default. To get logs of firewall action regarding SMURFS attacks protection.

- `nftables (tech preview)`\
  Disabled by default. Enable this if you want to try the newer (but still in tech preview state) nftables-based firewall of Proxmox VE.

### Enabling TCP SYN flood protection

There are three extra options related to SYN flood protection that are mentioned only in the Proxmox VE firewall documentation, [in the Host Specific Configuration subsection](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pve_firewall_host_specific_configuration).

- `protection_synflood`\
  Disabled (value `0`) by default. Enables the protection against TCP syn flood attacks, which is another kind of DDoS that essentially can saturate your host's with new connection requests. This protection essentially controls how many connections can be requested by other IPs at once and per second.

- `protection_synflood_burst`\
  `1000` by default. Puts a limit on how many new connections can be requested from other IPs to this host.

- `protection_synflood_rate`\
  `200` by default. Its the maximum number of new connections that can be requested **per second** to this host from other IPs.

These three parameters haven't been made directly available from the PVE web console. If you want to enable and configure this synflood protection, you need to enter the parameters directly in the corresponding `host.fw` file of your PVE node.

1. Since in this guide the Proxmox VE node is called `pve`, the full path of that file is `/etc/pve/nodes/pve/host.fw`. Open a shell with your `mgrsys` user, then edit the file:

    ~~~properties
    [OPTIONS]

    smurf_log_level: info
    ndp: 0
    log_level_in: info
    tcp_flags_log_level: info
    log_level_forward: info
    log_level_out: info
    tcpflags: 1
    nf_conntrack_tcp_timeout_established: 7875
    ~~~

    Above you can see the configuration I set up in my host, which may differ from what you have chosen to configure in your setup.

2. Below the last parameter you see in the `[OPTIONS]` section, append the synflood parameters:

    ~~~properties
    [OPTIONS]
    ...
    protection_synflood: 1
    protection_synflood_burst: 1000
    protection_synflood_rate: 200
    ~~~

    Notice that, in my case, I chose to stick with the default values for `protection_synflood_burst` and `protection_synflood_rate`.

3. The Proxmox VE documentation does not say if the changes in the `host.fw` file are automatically applied after saving them. Just reboot your PVE node to be sure.

## Firewall logging

If you've configured your firewall as I've showed you before, now you have its log enabled at the node level. You can see it in the PVE web console, at the `Firewall > Log` view of your `pve` node.

![PVE node firewall log view](images/g014/pve_node_firewall_log_view.webp "PVE node firewall log view")

This log is a text file that you can find in your PVE host at the path `/var/log/pve-firewall.log`, and is rotated daily.

### Understanding the firewall log

Let's imagine you just booted up your Proxmox VE system and then you connect through a SSH client, like PuTTY, to open a shell in your PVE host. With the configuration explained in this guide, you may see lines in your firewall log like the following ones.

~~~log
0 5 - 24/Jul/2025:15:53:00 +0200 starting pvefw logger
0 5 - 24/Jul/2025:16:45:37 +0200 received terminate request (signal)
0 5 - 24/Jul/2025:16:45:37 +0200 stopping pvefw logger
0 5 - 24/Jul/2025:16:45:38 +0200 starting pvefw logger
0 6 PVEFW-HOST-IN 24/Jul/2025:17:27:00 +0200 policy DROP: IN=vmbr0 PHYSIN=enp0s3 MAC=ae:b7:cd:26:7f:d2:54:5e:96:4b:2c:cf:08:00 SRC=10.137.113.200 DST=10.3.0.2 LEN=60 TOS=0x00 PREC=0x00 TTL=128 ID=64406 PROTO=ICMP TYPE=8 CODE=0 ID=1 SEQ=1
0 6 PVEFW-HOST-IN 24/Jul/2025:17:27:17 +0200 policy DROP: IN=vmbr0 PHYSIN=enp0s3 MAC=ae:b7:cd:26:7f:d2:54:5e:96:4b:2c:cf:08:00 SRC=10.137.113.200 DST=10.3.0.2 LEN=60 TOS=0x00 PREC=0x00 TTL=128 ID=64488 PROTO=ICMP TYPE=8 CODE=0 ID=1 SEQ=2
~~~

The typical log line is formatted with the following schema:

~~~sh
VMID LOGID CHAIN TIMESTAMP POLICY: PACKET_DETAILS
~~~

This schema is translated as follows:

- `VMID`: identifies the virtual machine on which the firewall rule or policy is acting. For the Proxmox VE host itself this value is always `0`.

- `LOGID`: tells the logging level this log line has. Proxmox VE firewall has eight levels, check them out [in its official wiki](https://pve.proxmox.com/wiki/Firewall#_logging_of_firewall_rules).

- `CHAIN`: the firewall rule chain's name in which the policy or rule that provoked the log line is set. For cases in which there's no related chain, a `-` is printed here.

- `TIMESTAMP`: a full timestamp that includes the UTC.

- `POLICY`: indicates what policy was applied in the rule that printed the log line.

- `PACKET_DETAILS`: details from the affected packet, like source and destination IPs, protocol used, etc.

Knowing all that above, let's translate the previous logging example.

- All the lines are relative to the Proxmox VE host, since all of them start with the `VMID` set as `0`.

- The first four lines are **notices** warning about the firewall logger activity:

  - Their `LOGID` is `5`, which corresponds to the **notice** logging level.
  - These log lines don't correspond to any rule chain of the firewall, so their `CHAIN` is just a `-`.
  - The `TIMESTAMP` is a full date plus the UTC reference as expected.
  - The rest of their content is just a string in which the POLICY part is just empty and the PACKET_DETAILS is used to print the notice's message.

- The following two lines **inform** of two packets that have been dropped by the firewall.

  - Their `LOGID` is `6`, which corresponds to the **info** logging level.
  - The rule that has printed this log is set in the `PVEFW-HOST-IN` chain.
  - The `TIMESTAMP` is like in the previous notice log lines.
  - The `POLICY` string indicates the `DROP` action taken with the packets.
  - The `PACKET_DETAILS` is a list of details from the dropped packets.

    - `IN`: refers to the input network device through which the packet came, in this case the bridge `vmbr0`.
    - `PHYSIN`: is the _physical_ input network device through which the packet came. Here is the ethernet network card `enp0s3` of this host, which is the one used by the bridge `vmbr0` as networking port.
    - `MAC`: this is a rather odd value because is not just the mac of a particular network device, but the concatenation of the packet's source mac (`ae:b7:cd:26:7f:d2`) with the destination mac (`54:5e:96:4b:2c:cf`) and an extra suffix `08:00`.
    - `SRC`: IP of this packet's source.
    - `DST`: IP of this packet's destination.
    - `LEN`: packet's total length in bytes.
    - `TOS`: [Type Of Service](https://linuxreviews.org/Type_of_Service_(ToS)_and_DSCP_Values), meant for prioritization of packets within a network.
    - `PREC`: the precedence bits of the previous `TOS` field.
    - `TTL`: Time To Live, which is the number of hops this packet can make before being discarded.
    - `ID`: packet's datagram identifier.
    - `PROTO`: message protocol used in the packet, [ICMP](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol) in these two cases.
    - `TYPE`: is the ICMP type of [control message](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol#Control_messages). Here is `8` which is the echo request, used to ping.
    - `CODE`: parameter used in ICMP messages, some types have several codes but the 8 only has the `0` one.
    - `ID`: this second identifier is also an ICMP field.
    - `SEQ`: a sequence identifier set up too by the ICMP protocol.

The conclusion you can get from those log lines is that this Proxmox VE setup is dropping incoming ping packets, something common as a network hardening method. Be aware that, in the `PACKET_DETAILS` section, you should expect seeing very different parameters depending on the protocol used on each logged packet. In the example above you've seen ICMP ping packets, but other times you might see other types of ICMP messages or, more commonly, TCP or UDP packets.

## Connection tracking tool

In this chapter and in the [previous G012 one](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md) I've mentioned a few times the connection tracking system enabled by the firewall. This is popularly known as _conntrack_ and, adding to its own particular `sysctl` parameters (identified by the `nf_conntrack_` prefix), there is also a command enabling system administrators to manage the in-kernel connection tracking state tables.

1. Install the `conntrack` command with `apt`.

    ~~~sh
    $ sudo apt install conntrack
    ~~~

2. Test the command by showing the currently tracked connections.

    ~~~sh
    $ sudo conntrack -L
    ~~~

    The `-L` option makes `conntrack` list the currently "established" or "expected" connections in your system.

    ~~~sh
    tcp      6 103 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59955 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59955 [ASSURED] mark=0 use=1
    unknown  2 579 src=0.0.0.0 dst=224.0.0.1 [UNREPLIED] src=224.0.0.1 dst=0.0.0.0 mark=0 use=1
    tcp      6 82 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59937 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59937 [ASSURED] mark=0 use=1
    tcp      6 108 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48786 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48786 [ASSURED] mark=0 use=1
    tcp      6 22 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43730 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43730 [ASSURED] mark=0 use=1
    tcp      6 17 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59881 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59881 [ASSURED] mark=0 use=1
    tcp      6 61 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42514 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42514 [ASSURED] mark=0 use=1
    tcp      6 11 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58690 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58690 [ASSURED] mark=0 use=1
    tcp      6 97 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37430 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37430 [ASSURED] mark=0 use=1
    tcp      6 46 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40820 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40820 [ASSURED] mark=0 use=1
    tcp      6 108 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59956 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59956 [ASSURED] mark=0 use=1
    tcp      6 13 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58698 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58698 [ASSURED] mark=0 use=1
    tcp      6 82 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59294 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59294 [ASSURED] mark=0 use=1
    tcp      6 38 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40764 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40764 [ASSURED] mark=0 use=1
    tcp      6 35 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52504 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52504 [ASSURED] mark=0 use=1
    tcp      6 43 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59901 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59901 [ASSURED] mark=0 use=1
    tcp      6 115 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48850 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48850 [ASSURED] mark=0 use=1
    tcp      6 61 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59920 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59920 [ASSURED] mark=0 use=1
    tcp      6 88 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55626 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55626 [ASSURED] mark=0 use=2
    tcp      6 100 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37440 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37440 [ASSURED] mark=0 use=1
    tcp      6 66 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59925 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59925 [ASSURED] mark=0 use=1
    tcp      6 71 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59928 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59928 [ASSURED] mark=0 use=1
    udp      17 20 src=10.3.0.2 dst=10.0.0.1 sport=41858 dport=53 src=10.0.0.1 dst=10.3.0.2 sport=53 dport=41858 mark=0 use=1
    tcp      6 85 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59310 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59310 [ASSURED] mark=0 use=1
    tcp      6 83 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59939 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59939 [ASSURED] mark=0 use=1
    tcp      6 118 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59914 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59914 [ASSURED] mark=0 use=1
    tcp      6 54 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59912 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59912 [ASSURED] mark=0 use=1
    tcp      6 102 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59954 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59954 [ASSURED] mark=0 use=1
    tcp      6 65 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59923 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59923 [ASSURED] mark=0 use=1
    tcp      6 69 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59927 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59927 [ASSURED] mark=0 use=1
    tcp      6 87 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59318 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59318 [ASSURED] mark=0 use=1
    tcp      6 33 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59895 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59895 [ASSURED] mark=0 use=1
    tcp      6 15 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58726 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58726 [ASSURED] mark=0 use=1
    tcp      6 65 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42538 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42538 [ASSURED] mark=0 use=1
    tcp      6 81 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59278 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59278 [ASSURED] mark=0 use=1
    tcp      6 80 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59936 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59936 [ASSURED] mark=0 use=1
    tcp      6 51 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47074 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47074 [ASSURED] mark=0 use=1
    tcp      6 90 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55640 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55640 [ASSURED] mark=0 use=2
    tcp      6 68 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60512 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60512 [ASSURED] mark=0 use=1
    tcp      6 8 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59875 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59875 [ASSURED] mark=0 use=1
    tcp      6 50 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47062 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47062 [ASSURED] mark=0 use=1
    tcp      6 42 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59903 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59903 [ASSURED] mark=0 use=1
    tcp      6 100 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59952 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59952 [ASSURED] mark=0 use=1
    tcp      6 60 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59919 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59919 [ASSURED] mark=0 use=1
    tcp      6 44 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59904 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59904 [ASSURED] mark=0 use=1
    tcp      6 31 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59892 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59892 [ASSURED] mark=0 use=1
    tcp      6 24 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59887 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59887 [ASSURED] mark=0 use=1
    tcp      6 23 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59886 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59886 [ASSURED] mark=0 use=1
    tcp      6 36 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59897 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59897 [ASSURED] mark=0 use=1
    tcp      6 85 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59938 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59938 [ASSURED] mark=0 use=1
    tcp      6 91 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55646 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55646 [ASSURED] mark=0 use=1
    tcp      6 42 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40786 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40786 [ASSURED] mark=0 use=1
    tcp      6 31 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52464 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52464 [ASSURED] mark=0 use=1
    tcp      6 110 TIME_WAIT src=10.3.0.2 dst=199.232.34.132 sport=55598 dport=80 src=199.232.34.132 dst=10.3.0.2 sport=80 dport=55598 [ASSURED] mark=0 use=1
    tcp      6 13 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59878 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59878 [ASSURED] mark=0 use=1
    tcp      6 106 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37506 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37506 [ASSURED] mark=0 use=1
    tcp      6 49 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59907 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59907 [ASSURED] mark=0 use=2
    tcp      6 91 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59943 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59943 [ASSURED] mark=0 use=1
    tcp      6 115 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59964 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59964 [ASSURED] mark=0 use=1
    tcp      6 64 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59922 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59922 [ASSURED] mark=0 use=1
    tcp      6 34 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52488 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52488 [ASSURED] mark=0 use=1
    tcp      6 47 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40826 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40826 [ASSURED] mark=0 use=1
    tcp      6 3 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=51444 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=51444 [ASSURED] mark=0 use=1
    tcp      6 119 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59968 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59968 [ASSURED] mark=0 use=1
    tcp      6 19 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43722 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43722 [ASSURED] mark=0 use=1
    tcp      6 83 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59302 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59302 [ASSURED] mark=0 use=1
    tcp      6 89 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55634 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55634 [ASSURED] mark=0 use=1
    tcp      6 95 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55674 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55674 [ASSURED] mark=0 use=1
    tcp      6 2 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59870 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59870 [ASSURED] mark=0 use=1
    tcp      6 118 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59966 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59966 [ASSURED] mark=0 use=1
    tcp      6 109 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59959 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59959 [ASSURED] mark=0 use=1
    tcp      6 79 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59934 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59934 [ASSURED] mark=0 use=1
    tcp      6 53 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47086 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47086 [ASSURED] mark=0 use=1
    tcp      6 27 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43766 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43766 [ASSURED] mark=0 use=1
    tcp      6 10 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58680 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58680 [ASSURED] mark=0 use=1
    tcp      6 53 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59910 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59910 [ASSURED] mark=0 use=2
    tcp      6 15 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59879 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59879 [ASSURED] mark=0 use=1
    tcp      6 113 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48826 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48826 [ASSURED] mark=0 use=1
    tcp      6 30 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59890 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59890 [ASSURED] mark=0 use=1
    tcp      6 93 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55666 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55666 [ASSURED] mark=0 use=1
    tcp      6 80 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59262 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59262 [ASSURED] mark=0 use=1
    tcp      6 4 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59872 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59872 [ASSURED] mark=0 use=1
    tcp      6 37 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52524 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52524 [ASSURED] mark=0 use=1
    tcp      6 98 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59950 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59950 [ASSURED] mark=0 use=1
    tcp      6 93 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59947 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59947 [ASSURED] mark=0 use=1
    tcp      6 36 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52510 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52510 [ASSURED] mark=0 use=1
    tcp      6 75 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59931 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59931 [ASSURED] mark=0 use=1
    tcp      6 26 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59889 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59889 [ASSURED] mark=0 use=1
    tcp      6 74 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60562 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60562 [ASSURED] mark=0 use=1
    tcp      6 110 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48798 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48798 [ASSURED] mark=0 use=1
    tcp      6 90 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59944 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59944 [ASSURED] mark=0 use=1
    tcp      6 30 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52456 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52456 [ASSURED] mark=0 use=1
    tcp      6 114 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48840 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48840 [ASSURED] mark=0 use=1
    tcp      6 33 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52484 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52484 [ASSURED] mark=0 use=1
    tcp      6 56 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59913 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59913 [ASSURED] mark=0 use=2
    tcp      6 79 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59256 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59256 [ASSURED] mark=0 use=1
    tcp      6 92 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55652 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55652 [ASSURED] mark=0 use=1
    tcp      6 7873 ESTABLISHED src=10.137.113.200 dst=10.3.0.2 sport=59967 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59967 [ASSURED] mark=0 use=1
    tcp      6 3 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59871 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59871 [ASSURED] mark=0 use=1
    tcp      6 0 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59867 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59867 [ASSURED] mark=0 use=1
    tcp      6 64 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42530 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42530 [ASSURED] mark=0 use=1
    tcp      6 70 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60528 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60528 [ASSURED] mark=0 use=1
    tcp      6 116 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59965 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59965 [ASSURED] mark=0 use=1
    tcp      6 14 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58714 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58714 [ASSURED] mark=0 use=1
    tcp      6 0 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=51424 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=51424 [ASSURED] mark=0 use=1
    tcp      6 41 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59902 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59902 [ASSURED] mark=0 use=1
    tcp      6 14 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59880 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59880 [ASSURED] mark=0 use=1
    tcp      6 68 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59926 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59926 [ASSURED] mark=0 use=1
    tcp      6 111 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48814 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48814 [ASSURED] mark=0 use=1
    tcp      6 60 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42508 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42508 [ASSURED] mark=0 use=1
    tcp      6 38 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59899 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59899 [ASSURED] mark=0 use=1
    tcp      6 58 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59918 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59918 [ASSURED] mark=0 use=1
    tcp      6 113 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59961 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59961 [ASSURED] mark=0 use=1
    tcp      6 111 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59962 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59962 [ASSURED] mark=0 use=2
    tcp      6 40 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59900 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59900 [ASSURED] mark=0 use=1
    tcp      6 32 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59894 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59894 [ASSURED] mark=0 use=1
    tcp      6 76 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60582 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60582 [ASSURED] mark=0 use=1
    tcp      6 72 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60558 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60558 [ASSURED] mark=0 use=1
    tcp      6 71 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60544 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60544 [ASSURED] mark=0 use=1
    tcp      6 75 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60576 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60576 [ASSURED] mark=0 use=1
    tcp      6 102 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37458 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37458 [ASSURED] mark=0 use=1
    tcp      6 47 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59905 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59905 [ASSURED] mark=0 use=1
    tcp      6 27 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59888 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59888 [ASSURED] mark=0 use=1
    tcp      6 6 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=51464 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=51464 [ASSURED] mark=0 use=1
    tcp      6 24 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43752 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43752 [ASSURED] mark=0 use=1
    tcp      6 94 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59946 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59946 [ASSURED] mark=0 use=1
    tcp      6 37 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59898 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59898 [ASSURED] mark=0 use=1
    tcp      6 101 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59953 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59953 [ASSURED] mark=0 use=1
    udp      17 20 src=10.3.0.2 dst=10.0.0.1 sport=44052 dport=53 src=10.0.0.1 dst=10.3.0.2 sport=53 dport=44052 mark=0 use=1
    tcp      6 34 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59896 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59896 [ASSURED] mark=0 use=1
    tcp      6 2 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=51438 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=51438 [ASSURED] mark=0 use=1
    tcp      6 6 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59873 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59873 [ASSURED] mark=0 use=1
    tcp      6 57 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47110 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47110 [ASSURED] mark=0 use=2
    tcp      6 54 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47092 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47092 [ASSURED] mark=0 use=1
    tcp      6 10 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59876 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59876 [ASSURED] mark=0 use=1
    tcp      6 9 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58678 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58678 [ASSURED] mark=0 use=1
    tcp      6 49 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47050 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47050 [ASSURED] mark=0 use=1
    tcp      6 56 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47094 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47094 [ASSURED] mark=0 use=1
    tcp      6 44 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40808 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40808 [ASSURED] mark=0 use=1
    tcp      6 97 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59951 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59951 [ASSURED] mark=0 use=1
    tcp      6 8 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58666 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58666 [ASSURED] mark=0 use=1
    tcp      6 74 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59930 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59930 [ASSURED] mark=0 use=1
    tcp      6 50 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59909 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59909 [ASSURED] mark=0 use=1
    tcp      6 106 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59958 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59958 [ASSURED] mark=0 use=1
    tcp      6 32 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52474 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52474 [ASSURED] mark=0 use=1
    tcp      6 88 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59940 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59940 [ASSURED] mark=0 use=1
    tcp      6 92 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59945 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59945 [ASSURED] mark=0 use=1
    tcp      6 18 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43706 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43706 [ASSURED] mark=0 use=1
    tcp      6 95 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59949 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59949 [ASSURED] mark=0 use=1
    tcp      6 41 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40784 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40784 [ASSURED] mark=0 use=1
    tcp      6 26 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43756 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43756 [ASSURED] mark=0 use=1
    tcp      6 103 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37474 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37474 [ASSURED] mark=0 use=2
    tcp      6 87 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59941 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59941 [ASSURED] mark=0 use=1
    tcp      6 300 ESTABLISHED src=10.137.113.200 dst=10.3.0.2 sport=59044 dport=22 src=10.3.0.2 dst=10.137.113.200 sport=22 dport=59044 [ASSURED] mark=0 use=3
    tcp      6 22 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59883 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59883 [ASSURED] mark=0 use=1
    tcp      6 46 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59906 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59906 [ASSURED] mark=0 use=1
    tcp      6 7872 ESTABLISHED src=127.0.0.1 dst=127.0.0.1 sport=47606 dport=3493 src=127.0.0.1 dst=127.0.0.1 sport=3493 dport=47606 [ASSURED] mark=0 use=1
    tcp      6 94 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55670 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55670 [ASSURED] mark=0 use=1
    tcp      6 109 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48790 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48790 [ASSURED] mark=0 use=1
    tcp      6 52 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=47078 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=47078 [ASSURED] mark=0 use=1
    tcp      6 70 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59924 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59924 [ASSURED] mark=0 use=1
    tcp      6 9 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59874 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59874 [ASSURED] mark=0 use=1
    tcp      6 57 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59915 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59915 [ASSURED] mark=0 use=1
    tcp      6 96 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=55690 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=55690 [ASSURED] mark=0 use=1
    tcp      6 51 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59908 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59908 [ASSURED] mark=0 use=1
    tcp      6 17 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=58740 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=58740 [ASSURED] mark=0 use=1
    tcp      6 81 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59935 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59935 [ASSURED] mark=0 use=1
    tcp      6 43 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40798 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40798 [ASSURED] mark=0 use=1
    tcp      6 28 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59891 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59891 [ASSURED] mark=0 use=1
    tcp      6 40 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=40776 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=40776 [ASSURED] mark=0 use=1
    tcp      6 98 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37432 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37432 [ASSURED] mark=0 use=2
    tcp      6 21 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59885 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59885 [ASSURED] mark=0 use=1
    tcp      6 104 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37490 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37490 [ASSURED] mark=0 use=1
    tcp      6 78 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59932 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59932 [ASSURED] mark=0 use=1
    tcp      6 52 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59911 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59911 [ASSURED] mark=0 use=1
    tcp      6 11 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59877 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59877 [ASSURED] mark=0 use=1
    tcp      6 76 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59933 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59933 [ASSURED] mark=0 use=1
    tcp      6 114 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59963 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59963 [ASSURED] mark=0 use=1
    tcp      6 63 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59921 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59921 [ASSURED] mark=0 use=1
    tcp      6 28 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=52448 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=52448 [ASSURED] mark=0 use=1
    tcp      6 110 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59960 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59960 [ASSURED] mark=0 use=1
    tcp      6 101 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=37448 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=37448 [ASSURED] mark=0 use=1
    tcp      6 96 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59948 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59948 [ASSURED] mark=0 use=1
    tcp      6 18 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59882 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59882 [ASSURED] mark=0 use=1
    tcp      6 23 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43746 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43746 [ASSURED] mark=0 use=1
    tcp      6 72 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59929 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59929 [ASSURED] mark=0 use=1
    tcp      6 58 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42502 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42502 [ASSURED] mark=0 use=1
    tcp      6 35 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59893 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59893 [ASSURED] mark=0 use=1
    tcp      6 19 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59884 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59884 [ASSURED] mark=0 use=1
    tcp      6 78 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59252 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59252 [ASSURED] mark=0 use=2
    tcp      6 4 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=51456 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=51456 [ASSURED] mark=0 use=1
    tcp      6 63 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42522 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42522 [ASSURED] mark=0 use=1
    tcp      6 104 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59957 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59957 [ASSURED] mark=0 use=1
    tcp      6 69 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=60526 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=60526 [ASSURED] mark=0 use=1
    tcp      6 66 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=42546 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=42546 [ASSURED] mark=0 use=1
    tcp      6 116 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=48862 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=48862 [ASSURED] mark=0 use=1
    tcp      6 21 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=43726 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=43726 [ASSURED] mark=0 use=1
    tcp      6 119 TIME_WAIT src=127.0.0.1 dst=127.0.0.1 sport=59926 dport=85 src=127.0.0.1 dst=127.0.0.1 sport=85 dport=59926 [ASSURED] mark=0 use=1
    tcp      6 89 TIME_WAIT src=10.137.113.200 dst=10.3.0.2 sport=59942 dport=8006 src=10.3.0.2 dst=10.137.113.200 sport=8006 dport=59942 [ASSURED] mark=0 use=1
    conntrack v1.4.7 (conntrack-tools): 199 flow entries have been shown.
    ~~~

Know that the connection tracking subsystem uses four different internal tables: _conntrack_ (the default one for active connections), _expect_, _dying_ and _unconfirmed_. Check [the `conntrack` command's `man` page](https://manpages.debian.org/bullseye/conntrack/conntrack.8.en.html) to know more.

## Relevant system paths

### Directories

- `/etc/pve/firewall`
- `/etc/pve/nodes/<nodename>/`
- `/etc/pve/sdn/firewall/`

### Files

- `/etc/pve/firewall/<VMID>.fw`
- `/etc/pve/firewall/cluster.fw`
- `/etc/pve/nodes/<nodename>/host.fw`
- `/etc/pve/sdn/firewall/<vnet_name>.fw`

## References

### Proxmox VE firewall

- [Proxmox VE admin guide. Firewall](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html)
  - [Directions & Zones. Zones](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#_zones)
  - [nftables](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#pve_firewall_nft)
- [Proxmox VE wiki. Firewall](https://pve.proxmox.com/wiki/Firewall)
- [nftables HOWTO documentation](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page)
- [Postinstall Configuration of Proxmox VE 6.2](https://lowendspirit.com/postinstall-configuration-of-proxmox-ve-6-2)
- [Secure Proxmox Install – Sudo, Firewall with IPv6, and more – How to Configure from Start to Finish](https://www.kiloroot.com/secure-proxmox-install-sudo-firewall-with-ipv6-and-more-how-to-configure-from-start-to-finish/)
- [Hardening Proxmox VE management interface with 2FA, reverse proxy and Let's Encrypt](https://loicpefferkorn.net/2020/11/hardening-proxmox-ve-management-interface-with-2fa-reverse-proxy-and-lets-encrypt/)
- [Proxmox Port Forwarding To VM | An Easy Way](https://bobcares.com/blog/proxmox-port-forwarding-to-vm/)

### Ethernet Bridge firewall ebtables

- [ebtables netfilter](https://ebtables.netfilter.org/)
- [Proxmox dropping packets](https://www.reddit.com/r/homelab/comments/inqncm/proxmox_dropping_packets/)
- [Tracking down dropped packets](https://blog.hambier.lu/post/tracking-dropped-packets)
- [iptables-persistent: also persist ebtables and arptables?](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=697088)

### Network auditing on Linux

- [How to show dropped packets per interface on Linux](https://www.cyberciti.biz/faq/linux-show-dropped-packets-per-interface-command/)
- [How to capture "dropped packets" in tcpdump](https://superuser.com/questions/1208783/how-to-capture-dropped-packets-in-tcpdump)
- [Dropped packets in all Linux and Unix](https://serverfault.com/questions/780195/dropped-packets-in-all-linux-and-unix)
- [Lots of dropped packages when tcpdumping on busy interface](https://serverfault.com/questions/421789/lots-of-dropped-packages-when-tcpdumping-on-busy-interface)

### Network security concepts

- [Linux TCP/IP Tuning for Scalability](https://developer.akamai.com/blog/2012/09/27/linux-tcpip-tuning-scalability)
- [What Is a Smurf Attack?](https://www.fortinet.com/resources/cyberglossary/smurf-attack)
- [Smurf attack](https://en.wikipedia.org/wiki/Smurf_attack)
- [Tcpdump: Filter Packets with Tcp Flags](https://www.howtouselinux.com/post/tcpdump-capture-packets-with-tcp-flags)
- [Filtering on TCP Flags](https://flylib.com/books/en/2.77.1.30/1/)
- [Neighbor Discovery Protocol (NDP)](https://www.oreilly.com/library/view/mastering-proxmox/9781788397605/78dcf187-f5b7-4239-89af-b4880f929b76.xhtml)
- [Address Resolution Protocol (ARP)](https://en.wikipedia.org/wiki/Address_Resolution_Protocol)
- [Netfilter Conntrack Sysfs variables](https://www.kernel.org/doc/html/latest/networking/nf_conntrack-sysctl.html)
- [TCP SYN Flood](https://www.imperva.com/learn/ddos/syn-flood/)
- [Firewall Log Messages What Do They Mean](https://www.halolinux.us/firewalls/firewall-log-messages-what-do-they-mean.html)

### Networking concepts

- [Internet Control Message Protocol](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol)
- [What is the Internet Control Message Protocol (ICMP)?](https://www.cloudflare.com/learning/ddos/glossary/internet-control-message-protocol-icmp/)
- [TCP/IP packets](https://inc0x0.com/tcp-ip-packets-introduction/)
- [Type of Service (ToS) and DSCP Values](https://linuxreviews.org/Type_of_Service_(ToS)_and_DSCP_Values)

### conntrack command

- [CONNTRACK(8)](https://manpages.debian.org/bullseye/conntrack/conntrack.8.en.html)
- [Package: conntrack (1:1.4.6-2)](https://packages.debian.org/bullseye/conntrack)
- [Matching connection tracking stateful metainformation](https://wiki.nftables.org/wiki-nftables/index.php/Matching_connection_tracking_stateful_metainformation)

## Navigation

[<< Previous (**G013. Host hardening 07**)](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G015. Host optimization 01**) >>](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md)
