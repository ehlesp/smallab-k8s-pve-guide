# G015 - Host optimization 01 ~ Adjustments through `sysctl`

- [Tune your Proxmox VE system's `sysctl` files to improve performance](#tune-your-proxmox-ve-systems-sysctl-files-to-improve-performance)
- [First go the `sysctl` directory](#first-go-the-sysctl-directory)
- [Network optimizations](#network-optimizations)
- [Memory optimizations](#memory-optimizations)
- [Kernel optimizations](#kernel-optimizations)
- [Reboot the system](#reboot-the-system)
- [Final considerations](#final-considerations)
- [Relevant system paths](#relevant-system-paths)
  - [Directories](#directories)
  - [Files](#files)
- [References](#references)
  - [`sysctl` variables](#sysctl-variables)
  - [About `sysctl` in general](#about-sysctl-in-general)
  - [About network optimizations](#about-network-optimizations)
  - [About memory optimizations](#about-memory-optimizations)
  - [Inotify system](#inotify-system)
  - [About optimizing the kernel](#about-optimizing-the-kernel)
- [Navigation](#navigation)

## Tune your Proxmox VE system's `sysctl` files to improve performance

You can get performance improvements in your Proxmox VE system just by setting some parameters in `sysctl` configuration files. Remember that you did something like this for hardening the TCP/IP stack back in the [chapter **G012**](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md).

The changes explained in the following sections are focused on improving the performance of your system on different concerns. For the sake of clarity, each concern will have its own `sysctl` file with their own particular parameter set. This is to avoid two problems: having the same parameter defined twice on different configuration files, and worrying about the order in which the parameters are being read (`sysctl` only keeps the last value read for each parameter).

> [!IMPORTANT]
> **Do not apply this configuration blindly in your PVE system**\
> Revise and adjust the values set in the following sections to suit your own system setup and presumed load.

## First go the `sysctl` directory

In this chapter you are going to create a bunch of `sysctl` configuration files that all have to be placed in the `/etc/sysctl.d` directory. Then, first `cd` to that path:

~~~sh
$ cd /etc/sysctl.d/
~~~

Staying in this directory, apply the configurations specified in the following sections.

> [!NOTE]
> **These configurations are self-explanatory**\
> All the configurations included in this chapter have comments explaining each of their parameters.

## Network optimizations

1. Create a new empty file called `85_network_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_network_optimizations.conf
    ~~~

2. Edit the `85_network_optimizations.conf` file and set the following content:

    ~~~properties
    ## NETWORK optimizations

    # TCP Fast Open is an extension to the transmission control protocol (TCP)
    # that helps reduce network latency by enabling data to be exchanged during
    # the sender’s initial TCP SYN [3]. Using the value 3 instead of the default 1
    # allows TCP Fast Open for both incoming and outgoing connections.
    net.ipv4.tcp_fastopen = 3

    # Wait a maximum of 5 * 2 = 10 seconds in the TIME_WAIT state after a FIN,
    # to handle any remaining packets in the network.
    # Load module nf_conntrack if needed.
    # BEWARE: this parameter won't be available if the firewall hasn't been enabled first!
    # Value is an INTEGER.
    net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 5

    # Keepalive optimizations
    #
    # TCP keepalive is a mechanism for TCP connections that help to determine whether
    # the other end has stopped responding or not. TCP will send the keepalive probe
    # that contains null data to the network peer several times after a period of idle
    # time. If the peer does not respond, the socket will be closed automatically.
    #
    # By default, the keepalive routines wait for two hours (7200 secs)
    # before sending the first keepalive probe, and then resend it every 75 seconds.
    # If no ACK response is received for 9 consecutive times, the connection
    # is marked as broken. As long as there is TCP/IP socket communications going on
    # and active, no keepalive packets are needed.
    #
    # The default values are:
    # tcp_keepalive_time = 7200, tcp_keepalive_intvl = 75, tcp_keepalive_probes = 9
    #
    # We would decrease the default values for tcp_keepalive_* params as follow:
    #
    # Disconnect dead TCP connections after 10 minutes
    # https://sysctl-explorer.net/net/ipv4/tcp_keepalive_time/
    # Value in SECONDS.
    net.ipv4.tcp_keepalive_time = 600
    #
    # Determines the wait time between isAlive interval probes.
    # https://sysctl-explorer.net/net/ipv4/tcp_keepalive_intvl/
    # Value in SECONDS.
    net.ipv4.tcp_keepalive_intvl = 10
    #
    # Determines the number of probes before timing out.
    # https://sysctl-explorer.net/net/ipv4/tcp_keepalive_probes/
    net.ipv4.tcp_keepalive_probes = 6

    # The longer the maximum transmission unit (MTU) the better for performance,
    # but the worse for reliability. This is because a lost packet means more data
    # to be retransmitted and because many routers on the Internet cannot deliver
    # very long packets.
    net.ipv4.tcp_mtu_probing = 1

    # Maximum number of connections that can be queued for acceptance.
    net.core.somaxconn = 256000

    # How many half-open connections for which the client has not yet
    # sent an ACK response can be kept in the queue or, in other words,
    # the maximum queue length of pending connections 'Waiting Acknowledgment'.
    # SYN cookies only kick in when this number of remembered connections is surpassed.
    # Handle SYN floods and large numbers of valid HTTPS connections.
    net.ipv4.tcp_max_syn_backlog = 40000

    # Maximal number of packets in the receive queue that passed through the network
    # interface and are waiting to be processed by the kernel.
    # Increase the length of the network device input queue.
    net.core.netdev_max_backlog = 50000

    # Huge improve Linux network performance by change TCP congestion control to BBR
    # (Bottleneck Bandwidth and RTT).
    # BBR congestion control computes the sending rate based on the delivery
    # rate (throughput) estimated from ACKs.
    # https://djangocas.dev/blog/huge-improve-network-performance-by-change-tcp-congestion-control-to-bbr/
    net.core.default_qdisc = fq
    net.ipv4.tcp_congestion_control = bbr

    # Increase ephemeral IP ports available for outgoing connections.
    # The ephemeral port is typically used by the Transmission Control Protocol (TCP),
    # User Datagram Protocol (UDP), or the Stream Control Transmission Protocol (SCTP)
    # as the port assignment for the client end of a client–server communication.
    # https://www.cyberciti.biz/tips/linux-increase-outgoing-network-sockets-range.html
    net.ipv4.ip_local_port_range = 30000 65535

    # This is a setting for large networks (more than 128 hosts), and this includes
    # having many virtual machines or containers running in the Proxmox VE platform.
    # https://www.serveradminblog.com/2011/02/neighbour-table-overflow-sysctl-conf-tunning/
    net.ipv4.neigh.default.gc_thresh1 = 1024
    net.ipv4.neigh.default.gc_thresh2 = 4096
    # The gc_thresh3 is already set at /usr/lib/sysctl.d/10-pve-ct-inotify-limits.conf

    # Limits number of Challenge ACK sent per second, as recommended in RFC 5961.
    # Improves TCP’s Robustness to Blind In-Window Attacks.
    # https://sysctl-explorer.net/net/ipv4/tcp_challenge_ack_limit/
    net.ipv4.tcp_challenge_ack_limit = 9999

    # Sets whether TCP should start at the default window size only for new connections
    # or also for existing connections that have been idle for too long.
    # This setting kills persistent single connection performance and could be turned off.
    # https://sysctl-explorer.net/net/ipv4/tcp_slow_start_after_idle/
    # https://github.com/ton31337/tools/wiki/tcp_slow_start_after_idle---tcp_no_metrics_save-performance
    net.ipv4.tcp_slow_start_after_idle = 0

    # Maximal number of sockets in TIME_WAIT state held by the system simultaneously.
    # After reaching this number, the system will start destroying the sockets
    # that are in this state. Increase this number to prevent simple DOS attacks.
    # https://sysctl-explorer.net/net/ipv4/tcp_max_tw_buckets/
    net.ipv4.tcp_max_tw_buckets = 500000

    # Sets whether TCP should reuse an existing connection in the TIME-WAIT state
    # for a new outgoing connection, if the new timestamp is strictly bigger than
    # the most recent timestamp recorded for the previous connection.
    # This helps avoid from running out of available network sockets
    # https://sysctl-explorer.net/net/ipv4/tcp_tw_reuse/
    net.ipv4.tcp_tw_reuse = 1

    # Increase Linux autotuning TCP buffer limits.
    # The default the Linux network stack is not configured for high speed large
    # file transfer across WAN links (i.e. handle more network packets) and setting
    # the correct values may save memory resources.
    # Values in BYTES.
    net.core.rmem_default = 1048576
    net.core.rmem_max = 16777216
    net.core.wmem_default = 1048576
    net.core.wmem_max = 16777216
    net.core.optmem_max = 65536
    net.ipv4.tcp_rmem = 4096 1048576 2097152
    net.ipv4.tcp_wmem = 4096 65536 16777216

    # In case UDP connections are used, these limits should also be raised.
    # Values in BYTES.
    # https://sysctl-explorer.net/net/ipv4/udp_rmem_min/
    net.ipv4.udp_rmem_min = 8192
    # https://sysctl-explorer.net/net/ipv4/udp_wmem_min/
    net.ipv4.udp_wmem_min = 8192

    # The maximum length of dgram socket receive queue.
    net.unix.max_dgram_qlen = 1024
    ~~~

3. Save the `85_network_optimizations.conf` file and apply the changes:

    ~~~sh
    $ sudo sysctl -p 85_network_optimizations.conf
    ~~~

## Memory optimizations

1. Create a new empty file called `85_memory_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_memory_optimizations.conf
    ~~~

2. Edit the `85_memory_optimizations.conf` file and enter the following content:

    ~~~properties
    ## Memory optimizations

    # Define how aggressive the kernel will swap memory pages.
    # The value represents the percentage of the free memory remaining
    # in the system's RAM before activating swap.
    # https://sysctl-explorer.net/vm/swappiness/
    # Value is a PERCENTAGE.
    vm.swappiness = 2

    # Allow application request allocation of virtual memory
    # more than real RAM size (or OpenVZ/LXC limits).
    # https://sysctl-explorer.net/vm/overcommit_memory/
    vm.overcommit_memory = 1

    # Controls the tendency of the kernel to reclaim the memory
    # which is used for caching of directory and inode objects.
    # Adjusting this value higher than the default one (100) should
    # help in keeping the caches down to a reasonable level.
    # Value is a PERCENTAGE.
    # https://sysctl-explorer.net/vm/vfs_cache_pressure/
    vm.vfs_cache_pressure = 500

    # How the kernel will deal with old data on memory.
    #
    # The kernel flusher threads will periodically wake up and write
    # `old’ data out to disk.
    # Value in CENTISECS (100 points = 1 second)
    # https://sysctl-explorer.net/vm/dirty_writeback_centisecs/
    vm.dirty_writeback_centisecs = 3000
    #
    # Define when dirty data is old enough to be eligible for
    # writeout by the kernel flusher threads.
    # https://sysctl-explorer.net/vm/dirty_expire_centisecs/
    # Value in CENTISECS (100 points = 1 second)
    vm.dirty_expire_centisecs = 18000

    # Adjustment of vfs cache to decrease dirty cache, aiming for a faster flush on disk.
    # 
    # Percentage of system memory that can be filled with “dirty” pages
    # — memory pages that still need to be written to disk — before the
    # pdflush/flush/kdmflush background processes kick in to write it to disk.
    # https://sysctl-explorer.net/vm/dirty_background_ratio/
    # Value is a PERCENTAGE.
    vm.dirty_background_ratio = 5
    #
    # Absolute maximum percentage amount of system memory that can be filled with
    # dirty pages before everything must get committed to disk.
    # https://sysctl-explorer.net/vm/dirty_ratio/
    # Value is a PERCENTAGE.
    vm.dirty_ratio = 10

    # Indicates the current number of "persistent" huge pages in the
    # kernel's huge page pool.
    # https://sysctl-explorer.net/vm/nr_hugepages/
    # https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt
    vm.nr_hugepages = 1
    ~~~

3. Save the `85_memory_optimizations.conf` file and apply the changes:

    ~~~sh
    $ sudo sysctl -p 85_memory_optimizations.conf
    ~~~

## Kernel optimizations

1. Create a new empty file called `85_kernel_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_kernel_optimizations.conf
    ~~~

2. Edit the `85_kernel_optimizations.conf` file and input the following content:

    ~~~properties
    ## Kernel optimizations

    # Controls whether unprivileged users can load eBPF programs.
    # For most scenarios this is recommended to be set as 1 (enabled).
    # This is a kernel hardening concern rather than a optimization one, but
    # is left here since its just this value.
    kernel.unprivileged_bpf_disabled=1

    # Process Scheduler related settings
    #
    # This setting groups tasks by TTY, to improve perceived responsiveness on an
    # interactive system. On a server with a long running forking daemon, this will
    # tend to keep child processes from migrating away as soon as they should.
    # So in a server it's better to leave it disabled.
    kernel.sched_autogroup_enabled = 0
    ~~~

3. Save the `85_kernel_optimizations.conf` file and apply the changes:

    ~~~sh
    $ sudo sysctl -p 85_kernel_optimizations.conf
    ~~~

## Reboot the system

Although you have applied the changes with the `sysctl -p` command, it is better to restart your server too:

~~~sh
$ sudo reboot
~~~

Then, open a new shell as your `mgrsys` user and check your system's journal (with the `journalctl` command), and also check the log files under the `/var/log` directory, to look for possible errors or warnings related to your changes.

## Final considerations

All the values modified in the previous sections have to be measured and tested against the possibilities of your system and the real workloads running on it. Expect to revise these configurations later to make them fit to your needs, and maybe even adjust any other `sysctl` parameters not specified in this guide.

On the other hand, notice how the configurations proposed here avoid touching any `sysctl` configuration files already present in the system (like the ones related to the PVE platform). This guarantees that future updates can change them without complaining about being different as they expected them to be.

## Relevant system paths

### Directories

- `/etc/sysctl.d`

### Files

- `/etc/sysctl.d/85_kernel_optimizations.conf`
- `/etc/sysctl.d/85_memory_optimizations.conf`
- `/etc/sysctl.d/85_network_optimizations.conf`

## References

### `sysctl` variables

- [The Linux Kernel Archives](https://www.kernel.org/)
  - [Networking ip variables](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
  - [Virtual memory variables](https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
  - [Summary of hugetlbpage (huge pages) support in the Linux kernel](https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt)
  - [Netfilter Conntrack Sysfs variables](https://www.kernel.org/doc/html/latest/networking/nf_conntrack-sysctl.html)

### About `sysctl` in general

- [GitHub Gist. sergey-dryabzhinsky/sysctl-proxmox-tune.conf. Most popular speedup sysctl options for Proxmox, corrected for the 5.3.18-3-pve kernel](https://gist.github.com/sergey-dryabzhinsky/bcc1a15cb7d06f3d4606823fcc834824#gistcomment-3297285)
- [Archlinux. ArchWiki. sysctl](https://wiki.archlinux.org/index.php/Sysctl)
- [Pluralsight. Tech Insights & How-To Guides. Tech Operations | Tech Insights & How-To Guides. Linux Hardening](https://www.pluralsight.com/resources/blog/tech-operations/linux-hardening-secure-server-checklist)

### About network optimizations

- [StackExchange. Unix & Linux. How long does conntrack remember a connection?](https://unix.stackexchange.com/questions/524295/how-long-does-conntrack-remember-a-connection)
- [StackExchange. Information Security. nf_conntrack: table full, dropping packet](https://security.stackexchange.com/questions/43205/nf-conntrack-table-full-dropping-packet)
- [PC-freak. Resolving “nf_conntrack: table full, dropping packet.” flood message in dmesg Linux kernel log](https://pc-freak.net/blog/resolving-nf_conntrack-table-full-dropping-packet-flood-message-in-dmesg-linux-kernel-log/)
- [The conntrack-tools user manual](https://conntrack-tools.netfilter.org/manual.html)
- [Dmitri Lerko. Kubernetes Networking Problems Due to the Conntrack](https://deploy.live/blog/kubernetes-networking-problems-due-to-the-conntrack/)
- [StackOverflow. What is the difference between tcp_max_syn_backlog and somaxconn?](https://stackoverflow.com/questions/62641621/what-is-the-difference-between-tcp-max-syn-backlog-and-somaxconn)
- [django-cas-ng. Linux. Huge improve network performance by change TCP congestion control to BBR](https://djangocas.dev/blog/huge-improve-network-performance-by-change-tcp-congestion-control-to-bbr/)
- [nixCraft. Tutorials. High performance computing. Linux Increase TCP Port Range with net.ipv4.ip_local_port_range Kernel Parameter](https://www.cyberciti.biz/tips/linux-increase-outgoing-network-sockets-range.html)
- [ Mattias Geniar. Linux increase ip_local_port_range TCP port range](https://ma.ttias.be/linux-increase-ip_local_port_range-tcp-port-range/)
- [ServerAdminBlog. Neighbour Table Overflow – sysctl.Conf Tuning](https://www.serveradminblog.com/2011/02/neighbour-table-overflow-sysctl-conf-tunning/)
- [Tips, Tricks and Tools. Overflow in datagram type sockets](https://www.toptip.ca/2013/02/overflow-in-datagram-type-sockets.html)

### About memory optimizations

- [LinuxHint. Understanding vm.swappiness](https://linuxhint.com/understanding_vm_swappiness/)
- [ServerFault. How does vm.overcommit_memory work?](https://serverfault.com/questions/606185/how-does-vm-overcommit-memory-work)
- [Iain V Linux. Memory Overcommit Settings](https://iainvlinux.wordpress.com/2014/02/16/memory-overcommit-settings/)
- [Major Hayden. Reducing inode and dentry caches to keep OOM killer at bay](https://major.io/2008/12/03/reducing-inode-and-dentry-caches-to-keep-oom-killer-at-bay/)
- [The Lone Sysadmin. Better Linux Disk Caching & Performance with vm.dirty_ratio & vm.dirty_background_ratio](https://lonesysadmin.net/2013/12/22/better-linux-disk-caching-performance-vm-dirty_ratio/)
- [Debian. Wiki. Hugepages](https://wiki.debian.org/Hugepages)
- [Educba. Software Development. Software Development Tutorials. Linux Tutorial. Linux HugePages](https://www.educba.com/linux-hugepages/)

- [Proxmox. Forums. Proxmox Virtual Environment](https://forum.proxmox.com/#proxmox-virtual-environment.11)
  - [Proxmox VE: Installation and configuration](https://forum.proxmox.com/forums/proxmox-ve-installation-and-configuration.16/)
    - [Hugepages and Multiple VMs](https://forum.proxmox.com/threads/hugepages-and-multiple-vms.34075/)

### Inotify system

- [StackOverflow. What is a reasonable amount of inotify watches with Linux?](https://stackoverflow.com/questions/535768/what-is-a-reasonable-amount-of-inotify-watches-with-linux)
- [GitHub Gist. ntamvl/Increasing-the-amount-of-inotify-watchers.md. Increasing the amount of inotify watchers](https://gist.github.com/ntamvl/7c41acee650d376863fd940b99da836f)
- [DEV. Ubuntu Increase Inotify Watcher (File Watch Limit)](https://dev.to/rubiin/ubuntu-increase-inotify-watcher-file-watch-limit-kf4)

### About optimizing the kernel

- [StackOverflow. Unable to run bpf program as non root](https://stackoverflow.com/questions/65949586/unable-to-run-bpf-program-as-non-root)
- [GitLab. Tails. Issues. Disable unprivileged BPF](https://gitlab.tails.boum.org/tails/tails/-/issues/11827)
- [Tweaked.io. The GNU/Linux Kernel](http://www.tweaked.io/guide/kernel/)

## Navigation

[<< Previous (**G014. Host hardening 08**)](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G016. Host optimization 02**) >>](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md)
