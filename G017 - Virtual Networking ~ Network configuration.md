# G017 - Virtual Networking ~ Network configuration

- [Preparing your virtual network for Kubernetes](#preparing-your-virtual-network-for-kubernetes)
- [Current virtual network setup](#current-virtual-network-setup)
- [Target network scenario](#target-network-scenario)
- [Creating an isolated Linux bridge](#creating-an-isolated-linux-bridge)
- [Bridges management](#bridges-management)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [Proxmox](#proxmox)
  - [Linux and virtual networking](#linux-and-virtual-networking)
- [Navigation](#navigation)

## Preparing your virtual network for Kubernetes

The upcoming chapters explain how to setup a small Kubernetes cluster run on virtual machines. Those VMs will need to be networked with each other and also with your LAN. Therefore, you need revise the virtual network setup you have and make it fit for the needs you will face later.

## Current virtual network setup

The network setup of your Proxmox VE standalone system is kept at its node level. To see it, you need to get into your PVE web console and browse to the `System > Network` view of your `pve` node:

![Initial network setup](images/g017/pve_node_system_network_initial_setup.webp "Initial network setup")

In the capture above you can see the setup on this guide's Proxmox VE host, which has these network interfaces:

- `enp3s0`\
  Is the host's real Ethernet NIC.

- `vmbr0`\
  Is the Linux bridge generated in the installation of Proxmox VE. It holds the IP of this host, and "owns" the `enp3s0` NIC. If you remember, all this was set up [back in the Proxmox VE installation](G002%20-%20Proxmox%20VE%20installation.md).

Your system should have, at least, one `en*` device and the `vmbr0` Linux bridge.

Any changes you make in this `Network` page are saved in the `/etc/network/interfaces` file of your PVE host. Open a remote shell as `mgrsys`, then make a backup of that file before you start changing your PVE network:

~~~sh
$ sudo cp /etc/network/interfaces /etc/network/interfaces.orig
~~~

## Target network scenario

The idea is to create a small Kubernetes cluster run with a few virtual machines. Each of those VMs will have two network cards. Why two network cards? To separate the internal communications that a Kubernetes cluster has between its nodes from the traffic between the cluster and the external or LAN network.

The VMs will have access to the external or LAN network and be reachable through one NIC, and communicate only with each other for cluster-related tasks through the other NIC. This is achieved simply by setting up the NICs on different IP subnets but, to guarantee true isolation for the internal-cluster-communication NICs you can emulate how it would be done if you were using real hardware: by setting up another Linux bridge not connected to the external network and connecting the internal-cluster-communication NICs to it.

## Creating an isolated Linux bridge

Creating a new and isolated Linux bridge in your Proxmox VE system is rather simple through the web console:

1. Browse to the `System > Network` of your `pve` node. Then click on the `Create` button to unfold a list of options:

    ![PVE node Network Create options list](images/g017/pve_node_system_network_create_options_list.webp "PVE node Network Create options list")

    Notice that there are two options groups in the unfolded list:

    - **`Linux` options**\
      Networking technology included in the Linux kernel, meaning that it is already available in your PVE system.

    - **`OVS` options**\
      Relative to **Open vSwitch** technology. Since it is not installed in your system, these options cannot work in your setup.

2. Click on the `Linux Bridge` option to raise the `Create: Linux Bridge` form window:

    ![Create Linux Bridge form window](images/g017/pve_node_system_network_create_linux_bridge.webp "Create Linux Bridge form window")

    The default values are just fine:

    - `Name`\
      You could put a different name if you wanted to but, since Proxmox VE follows a naming convention for device names like these, it is better to leave the default one to avoid potential issues.

    - `IPv4/CIDR` and `Gateway (IPv4)`\
      Left empty because you do not really need an IP assigned to a bridge for it to do its job at the MAC level.

    - `IPv6/CIDR` and `Gateway (IPv6)`\
      Also left empty for the same reason as with the IPv4 values, plus you are not even using IPv6 in the setup explained in this guide.

    - `Autostart`\
      You want this bridge to be always available when the system boots up.

    - `VLAN aware`\
      For the scenario contemplated in this guide series, there is no need for you to use VLANs at all. In fact, the existing `vmbr0` bridge does not have this option enabled either.

    - `Bridge ports`\
      Here will be listed all the interfaces connected to this bridge. Right now this list has to be left empty in this bridge. Notice that, in the `vmbr0` bridge, the `enp3s0` interface appears listed in this field.

    - `Comment`\
      Here you could enter a string like `K3s cluster inner networking` (Rancher K3s will be the Kubernetes distribution used to set up the cluster later).

3. Click on `Create` to see your new `vmbr1` Linux bridge added to the list of network devices:

    ![Linux Bridge created pending changes](images/g017/pve_node_system_network_linux_bridge_created_pending_changes.webp "Linux Bridge created pending changes")

    Realize that:

    - The `Apply Configuration` button has been enabled.
    - Your new Linux bridge has been added to the network list, **but it is not active**.
    - A log console has appeared right below the network devices list, showing you the "pending changes" you have to apply.

4. Press on the `Apply Configuration` button to make the underlying `ifupdown2` commands apply the changes. This action demands confirmation in the window shown below:

    ![PVE Network Apply Configuration confirmation](images/g017/pve_node_system_network_linux_bridge_apply_config_confirm.webp "PVE Network Apply Configuration confirmation")

    Press on `Yes`, and a small fast progress window appears:

    ![PVE Network Apply Configuration progress window](images/g017/pve_node_system_network_linux_bridge_apply_config_progress.webp "PVE Network Apply Configuration progress window")

5. The `Network` page refreshes automatically, showing your new `vmbr1` Linux bridge active in the devices list:

    ![PVE Network New vmbr1 Linux Bridge active](images/g017/pve_node_system_network_linux_bridge_active.webp "PVE Network New vmbr1 Linux Bridge active")

6. You can also check out the changes applied at the `/etc/network/interfaces` configuration file of your PVE host. Open a shell as `mgrsys` and open the file with `less`:

    ~~~sh
    $ less /etc/network/interfaces
    ~~~

    The file should look now like this:

    ~~~sh
    # network interface settings; autogenerated
    # Please do NOT modify this file directly, unless you know what
    # you're doing.
    #
    # If you want to manage parts of the network configuration manually,
    # please utilize the 'source' or 'source-directory' directives to do
    # so.
    # PVE will preserve these directives, but will NOT read its network
    # configuration from sourced files, so do not attempt to move any of
    # the PVE managed interfaces into external files!

    auto lo
    iface lo inet loopback

    iface enp3s0 inet manual

    auto vmbr0
    iface vmbr0 inet static
            address 10.1.0.1/8
            gateway 10.0.0.1
            bridge-ports enp3s0
            bridge-stp off
            bridge-fd 0

    auto vmbr1
    iface vmbr1 inet manual
            bridge-ports none
            bridge-stp off
            bridge-fd 0
    #K3s cluster inner networking

    source /etc/network/interfaces.d/*
    ~~~

    Find your new `vmbr1` bridge appended to this `interfaces` file with a set of `bridge-` options similar to the original `vmbr0` bridge.

## Bridges management

You can handle your bridges through your Proxmox VE web console, but that is a rather limited tool for solving more complex situations:

- You can use the `ip` command to handle the bridges like any other network device. For instance, you can compare the traffic statistics of your new `vmbr1` bridge with the ones from `vmbr0`.

    ~~~sh
    $ ip -s link show vmbr0
    3: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
        link/ether 98:ee:cb:03:05:a3 brd ff:ff:ff:ff:ff:ff
        RX:  bytes packets errors dropped  missed   mcast
          3682639   12855      0       0       0    5660
        TX:  bytes packets errors dropped carrier collsns
          3750287    4968      0       0       0       0
    $ ip -s link show vmbr1
    4: vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
        link/ether 32:06:ef:79:b5:9d brd ff:ff:ff:ff:ff:ff
        RX:  bytes packets errors dropped  missed   mcast
                0       0      0       0       0       0
        TX:  bytes packets errors dropped carrier collsns
                0       0      0       0       0       0
    ~~~

    See how, at this point, the `vmbr1` bridge has no traffic whatsoever while `vmbr0` has some networking flow going through it.

- There is a command with specific functionality meant for managing bridges, called `bridge`. It is already installed in your Proxmox VE system, so you can use it right away. Also, be aware that **the `bridge` command requires `sudo` to be executed**.

    > [!NOTE]
    > **To understand the bridge command, you also need to study the particularities of bridges in general**\
    > Please take a look to the [references linked at the end of this chapter](#references).

## Relevant system paths

### Directories

- `/etc/network`

### Files

- `/etc/network/interfaces`
- `/etc/network/interfaces.orig`

## References

### [Proxmox](https://www.proxmox.com/en/)

- [Host System Administration](https://pve.proxmox.com/pve-docs/chapter-sysadmin.html)
  - [Network Configuration](https://pve.proxmox.com/pve-docs/chapter-sysadmin.html#sysadmin_network_configuration)

- [Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)
  - [Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)

### Linux and virtual networking

- [Linux Expert. Deep Guide to Bridge Command Line in Linux](https://www.linuxoperatingsystem.net/deep-guide-bridge-command-line-in-linux/)
- [Linux-Blog – Dr. Mönchmeyer / anracon. Fun with veth devices, Linux virtual bridges, KVM, VMware – attach the host and connect bridges via veth](https://linux-blog.anracom.com/tag/linux-bridge-linking/)
- [Kernel Virtual Machine. Networking](https://www.linux-kvm.org/page/Networking)
- [nixCraft. Howto. Debian Linux. How to setup and configure network bridge on Debian Linux](https://www.cyberciti.biz/faq/how-to-configuring-bridging-in-debian-linux/)
- [Hechao's Blog. Linux Bridge - Part 1](https://hechao.li/posts/linux-bridge-part1/)
- [Hechao's Blog. Mini Container Series Part 5](https://hechao.li/posts/Mini-Container-Series-Part-5-Network-Isolation/)
- [ServerFault. Linux: bridges, VLANs and RSTP](https://serverfault.com/questions/824621/linux-bridges-vlans-and-rstp)
- [Ubuntu. Community Help Wiki. NetworkConnectionBridge. Bridging Ethernet Connections (as of Ubuntu 16.04)](https://help.ubuntu.com/community/NetworkConnectionBridge)

## Navigation

[<< Previous (**G016. Host optimization 02**)](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G018. K3s cluster setup 01**) >>](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md)
