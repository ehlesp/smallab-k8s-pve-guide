# G021 - K3s cluster setup 04 ~ Debian VM configuration

- [You have to configure your new Debian VM](#you-have-to-configure-your-new-debian-vm)
- [Suggestion about the IP organization within your LAN](#suggestion-about-the-ip-organization-within-your-lan)
- [Adding the `apt` sources for _non-free_ packages](#adding-the-apt-sources-for-non-free-packages)
- [Installing extra packages](#installing-extra-packages)
- [The QEMU guest agent comes enabled in Debian](#the-qemu-guest-agent-comes-enabled-in-debian)
  - [Discovering the QEMU guest agent configuration](#discovering-the-qemu-guest-agent-configuration)
- [Hardening the VM's access](#hardening-the-vms-access)
  - [Enabling `sudo` to the administrative user](#enabling-sudo-to-the-administrative-user)
  - [Assigning a TOTP code to the administrative user](#assigning-a-totp-code-to-the-administrative-user)
  - [SSH key pair for the administrative user](#ssh-key-pair-for-the-administrative-user)
- [Hardening the `sshd` service](#hardening-the-sshd-service)
  - [Create group for SSH users](#create-group-for-ssh-users)
  - [Backup of `sshd` configuration files](#backup-of-sshd-configuration-files)
  - [Changes to the `/etc/pam.d/sshd` file](#changes-to-the-etcpamdsshd-file)
  - [Changes to the `/etc/ssh/sshd_config` file](#changes-to-the-etcsshsshd_config-file)
- [Configuring Fail2Ban for SSH connections](#configuring-fail2ban-for-ssh-connections)
- [Disabling the `root` user login](#disabling-the-root-user-login)
- [Configuring the VM with `sysctl`](#configuring-the-vm-with-sysctl)
  - [TCP/IP stack hardening](#tcpip-stack-hardening)
  - [Network optimizations](#network-optimizations)
  - [Memory optimizations](#memory-optimizations)
  - [Kernel optimizations](#kernel-optimizations)
- [Reboot the VM](#reboot-the-vm)
- [Disabling transparent hugepages on the VM](#disabling-transparent-hugepages-on-the-vm)
- [Regarding the microcode `apt` packages for CPU vulnerabilities](#regarding-the-microcode-apt-packages-for-cpu-vulnerabilities)
  - [The Debian installer has installed the microcode package](#the-debian-installer-has-installed-the-microcode-package)
- [Relevant system paths](#relevant-system-paths)
  - [Directories on Debian VM](#directories-on-debian-vm)
  - [Files on Debian VM](#files-on-debian-vm)
- [References](#references)
  - [Proxmox](#proxmox)
  - [QEMU](#qemu)
  - [About `sudo`](#about-sudo)
  - [Disabling `root` login](#disabling-root-login)
  - [Microcode packages on VMs](#microcode-packages-on-vms)
- [Navigation](#navigation)

## You have to configure your new Debian VM

Now you have a functional Debian VM but, as you did with your Proxmox VE host, you have to configure it. This chapter indicates most of the same setup procedures detailed in the chapters between [**G003**](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources%2C%20updates%20and%20extra%20tools.md) and [**G016**](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md), but in an condensed manner. This chapter also adds some extra steps needed for setting up particular aspects on this VM.

## Suggestion about the IP organization within your LAN

Before you start configuring your new VM or create some more, you should consider organizing the IPs in your network. This means that you should assign static IPs (if you have not done it already) to your Proxmox VE server and your new and future VMs. This allows you to know to what IPs to connect to through SSH easily, rather than being forced to check every time what IP is assigned to your VMs and Proxmox VE host. Also it helps you avoid potential IP conflicts among your devices and VMs. Start by figuring out first, in a document or spreadsheet, the IP distribution you want within your network. This way you can see how to divide the IPs among all your present devices and future VMs.

Here is a description of how it has been done in the LAN used for this guide. The router's LAN is set as a `10.0.0.0/8` network, which gives a very big range of IP numbers. Then, there are static IPs set in specific subranges (just defined in a spreadsheet) only for the Proxmox VE server and the VMs run in it. The Proxmox VE standalone node's IP is in a particular subrange (`10.1.0.0`), while all the Proxmox-based VMs are in a different one (`10.4.0.0`). Since the range of IPs available in a `10.0.0.0` network is enormous for a home LAN, it is possible to leave the users' devices getting random IPs (with randomized MACs for better security) without worrying much about possible IP conflicts.

## Adding the `apt` sources for _non-free_ packages

It might happen that you need to install `apt` packages in your VM that are _non-free_ for Debian standards. To allow that, you need to enable the right `apt` sources in your Debian VM:

1. Start the VM, then open a `noVNC` shell and log in the VM as `root`, or open a SSH session and log in as your other user (the `sshd` server will not allow you to log in as `root` using a password). If you choose the SSH method, you have to become `root` with the `su` command:

    ~~~sh
    $ su root
    ~~~

2. Then, `cd` to `/etc/apt/sources.list.d`:

    ~~~sh
    $ cd /etc/apt/sources.list.d
    ~~~

3. Create a new file called `debian-nonfree.list`:

    ~~~sh
    $ touch debian-nonfree.list
    ~~~

4. Edit the `debian-nonfree.list` file, filling it with these lines:

    ~~~sh
    deb http://deb.debian.org/debian trixie non-free
    deb-src http://deb.debian.org/debian trixie non-free

    deb http://deb.debian.org/debian-security/ trixie-security non-free
    deb-src http://deb.debian.org/debian-security/ trixie-security non-free

    deb http://deb.debian.org/debian trixie-updates non-free
    deb-src http://deb.debian.org/debian trixie-updates non-free
    ~~~

    > [!WARNING]
    > This sources list is only for Debian 13 "trixie"!

5. Save the file and update `apt`:

    ~~~sh
    $ apt update
    ~~~

## Installing extra packages

The Debian OS you have running in your VM is rather barebones. You have to install in it some packages useful to have in a server. Some of them are also necessary to perform the next steps described in this chapter. As `root`, execute the following `apt` command:

~~~sh
$ apt install -y ethtool fail2ban gdisk htop libpam-google-authenticator net-tools nut-client sudo tree vim
~~~

## The QEMU guest agent comes enabled in Debian

To grant the Proxmox VE platform a better control of its VMs, you need to have deployed in them the QEMU guest agent service. Since Debian already comes with it installed and running, you can go to the web console and check the `Status` block in your VM's `Summary` tab:

![PVE web console connects with QEMU guest agent on VM](images/g021/pve_qemu_guest_agent_web_console_connects.webp "PVE web console connects with QEMU guest agent on VM")

The web console now shows the v4 and v6 IPs of the VM's current main network card. If you click on `More`, you can see all the MACs and IPs assigned to all the network devices currently present in your VM:

![Guest Agent Network Information window of VM](images/g021/pve_qemu_guest_agent_web_console_connects_show_more.webp "Guest Agent Network Information window of VM")

In the list above, you should recognize the network devices currently attached to your VM:

- The `localhost`, called `lo`.
- The `ens18`, named `net0` for Proxmox VE in the VM's `Hardware` tab.
- The `ens19`, named `net1` for Proxmox VE in the VM's `Hardware` tab.

Any change to the network devices active in the VM will also be shown in this list.

Thanks to this QEMU agent, you can execute PVE web console actions like `Shutdown` or execute VM snapshots properly.

### Discovering the QEMU guest agent configuration

Another important detail to take into account is the configuration of this QEMU agent. Although, in the case of your first Debian VM, it works well just with the default values, you should know where to find its configuration files:

- `/etc/qemu`
  Directory for the agent configuration files.

- `/etc/qemu/qemu-ga.conf`
  This is the configuration file for the agent. Oddly enough, you will not find one created in your Debian VM, meaning the agent is working with default values set either in some other file or just hardcoded in the program.

- `/usr/sbin/qemu-ga`
  The path to the agent program itself. Probably for security reason, it is setup in such a way that you will not be able to execute it like a regular command.

If you want to know what is the concrete configuration of the QEMU agent running in your VM:

1. As `root`, cd to `/usr/sbin`:

    ~~~sh
    $ cd /usr/sbin
    ~~~

2. Execute the `qemu-ga` command as follows:

    ~~~sh
    $ ./qemu-ga -D
    ~~~

3. The `qemu-ga` command returns an output like this:

    ~~~properties
    [general]
    daemon=false
    method=virtio-serial
    path=/dev/virtio-ports/org.qemu.guest_agent.0
    pidfile=/var/run/qemu-ga.pid
    statedir=/var/run
    verbose=false
    retry-path=false
    block-rpcs=
    allow-rpcs=
    ~~~

    The lines returned have the same format used in the agent's `/etc/qemu/qemu-ga.conf` configuration file.

## Hardening the VM's access

The user you created in the Debian installation process, which in this guide is called `mgrsys`, needs its login to be hardened with TFA and a SSH key pair, while also enabling it to use the `sudo` command. This way, that user will become a proper administrative user for your system. On the other hand, after properly setting up that user, you won't really need to use `root` any more in this VM. This section explains how to completely disable the `root` login access to the VM.

### Enabling `sudo` to the administrative user

1. Log in as `root` in a `noVNC` shell on your VM, then add the `mgrsys` user to the `sudo` group:

    ~~~sh
    $ adduser mgrsys sudo
    ~~~

    > [!WARNING]
    > **You cannot execute the `adduser` command from a SSH shell with `mgrsys`**\
    > I does not matter if you become `root` with `su` as you have just done in the previous section. You must be root within a **noVNC or local shell** or the `adduser` command will not work.

2. Now login as the `mgrsys` user with a regular SSH shell, then test that `sudo` works with a harmless command like `ls`:

    ~~~sh
    $ sudo ls -al
    ~~~

    The `sudo` command immediately requires your `mgrsys`'s password:

    ~~~sh
    [sudo] password for mgrsys:
    ~~~

    Type the password to finally execute `ls`.

### Assigning a TOTP code to the administrative user

Having a TOTP code hardens the login of your administrative user:

1. As your administrative `mgrsys` user, create a TOTP token with the `google-authenticator` program as follows:

    ~~~sh
    $ google-authenticator -t -d -f -r 3 -R 30 -w 3 -Q UTF8 -i debiantpl.homelab.cloud -l mgrsys@debiantpl
    ~~~

    > [!IMPORTANT]
    > Remember to replace the values at the `-i` (issuer) and `-l` (label) options with your own!

2. Copy all the codes given by the `google-authenticator` command in a safe location, like a password manager:

> [!NOTE]
> The configuration for the TOTP code is saved in the administrative user's `HOME` directory, in a plain text `.google_authenticator` file.

### SSH key pair for the administrative user

It is much better if you login as your administrative user with a SSH key pair:

1. Logged in as your administrative user, execute the `ssh-keygen` command:

    ~~~sh
    $ ssh-keygen -t ed25519 -a 250 -C "mgrsys@debiantpl"
    ~~~

    > [!NOTE]
    > **The `ssh-keygen` command asks you for a passphrase, but you can leave it empty**\
    > Ideally, you want to set up a passphrase for your key pair. Still, take into account that you will also use TOTP codes when connecting through SSH after finishing this chapter. This means that, when you login, you will have to enter both the TOTP code and the passphrase, if you also specified it. Depending on the SSH client you use, this may be cumbersome depending on the time limit you set to enter the login credentials.

2. Authorize the public key of your newly generated pair:

    ~~~sh
    $ cd .ssh/
    $ touch authorized_keys ; chmod 600 authorized_keys
    $ cat id_ed25519.pub >> authorized_keys
    ~~~

3. Export this key pair and keep it in a safe location. Remember that you need to generate the `.ppk` file from the private key for connecting from Windows clients. Check out the [appendix chapter **G901**](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#generating-a-ppk-file-from-a-private-key) to learn how.

> [!WARNING]
> **You cannot login as the administrative user with its new SSH key pair yet!**\
> Since the `publickey` method is still not enabled in the `sshd` service's configuration, the SSH server in your Proxmox VE node will reject your key pair if you attempt to login with it.
>
> Just use the password and the TOTP code for now at this point. In the next [Hardening the `sshd` service](#hardening-the-sshd-service) section you will finally enable the `publickey` method, allowing you login remotely with your key pair.

## Hardening the `sshd` service

As you did in the chapters [**G007**](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md) and [**G009**](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md), you need to change two configuration files:

- `/etc/pam.d/sshd`
- `/etc/ssh/sshd_config`

You also need to create a new `pam` group for grouping the users that will connect through SSH to the VM, like the administrative user `mgrsys`.

### Create group for SSH users

In a shell opened as your `mgrsys` user:

1. Create a new group called `sshauth`:

    ~~~sh
    $ sudo addgroup sshauth
    ~~~

2. Add the administrative user to this group:

    ~~~sh
    $ sudo adduser mgrsys sshauth
    ~~~

### Backup of `sshd` configuration files

Open a terminal as your `mgrsys` user and make a backup of the current `sshd` related configuration:

~~~sh
$ cd /etc/pam.d ; sudo cp sshd sshd.orig
$ cd /etc/ssh ; sudo cp sshd_config sshd_config.orig
~~~

### Changes to the `/etc/pam.d/sshd` file

1. Comment out the first `@include common-auth` line found at at its top:

    ~~~sh
    # Standard Un*x authentication.
    #@include common-auth
    ~~~

2. Append the following lines:

    ~~~sh
    # Enforcing TFA with Google Authenticator tokens
    auth required pam_google_authenticator.so
    ~~~

### Changes to the `/etc/ssh/sshd_config` file

1. Edit the `/etc/ssh/sshd_config` file and **replace all its content** with this:

    ~~~sh
    # This is the sshd server system-wide configuration file.  See
    # sshd_config(5) for more information.

    # This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/bin:/usr/games

    # The strategy used for options in the default sshd_config shipped with
    # OpenSSH is to specify options with their default value where
    # possible, but leave them commented.  Uncommented options override the
    # default value.

    Include /etc/ssh/sshd_config.d/*.conf

    #Port 22
    AddressFamily inet
    #ListenAddress 0.0.0.0
    #ListenAddress ::

    #HostKey /etc/ssh/ssh_host_rsa_key
    #HostKey /etc/ssh/ssh_host_ecdsa_key
    #HostKey /etc/ssh/ssh_host_ed25519_key

    # Ciphers and keying
    #RekeyLimit default none

    # Logging
    #SyslogFacility AUTH
    #LogLevel INFO

    # Authentication:

    LoginGraceTime 45
    PermitRootLogin no
    #StrictModes yes
    MaxAuthTries 3
    #MaxSessions 10

    #PubkeyAuthentication yes

    # Expect .ssh/authorized_keys2 to be disregarded by default in future.
    #AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

    #AuthorizedPrincipalsFile none

    #AuthorizedKeysCommand none
    #AuthorizedKeysCommandUser nobody

    # For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
    #HostbasedAuthentication no
    # Change to yes if you don't trust ~/.ssh/known_hosts for
    # HostbasedAuthentication
    #IgnoreUserKnownHosts no
    # Don't read the user's ~/.rhosts and ~/.shosts files
    #IgnoreRhosts yes

    # To disable tunneled clear text passwords, change to "no" here!
    PasswordAuthentication no
    #PermitEmptyPasswords no

    # Change to "yes" to enable keyboard-interactive authentication.  Depending on
    # the system's configuration, this may involve passwords, challenge-response,
    # one-time passwords or some combination of these and other methods.
    # Beware issues with some PAM modules and threads.
    KbdInteractiveAuthentication yes

    # Kerberos options
    #KerberosAuthentication no
    #KerberosOrLocalPasswd yes
    #KerberosTicketCleanup yes
    #KerberosGetAFSToken no

    # GSSAPI options
    #GSSAPIAuthentication no
    #GSSAPICleanupCredentials yes
    #GSSAPIStrictAcceptorCheck yes
    #GSSAPIKeyExchange no

    # Set this to 'yes' to enable PAM authentication, account processing,
    # and session processing. If this is enabled, PAM authentication will
    # be allowed through the KbdInteractiveAuthentication and
    # PasswordAuthentication.  Depending on your PAM configuration,
    # PAM authentication via KbdInteractiveAuthentication may bypass
    # the setting of "PermitRootLogin prohibit-password".
    # If you just want the PAM account and session checks to run without
    # PAM authentication, then enable this but set PasswordAuthentication
    # and KbdInteractiveAuthentication to 'no'.
    UsePAM yes

    #AllowAgentForwarding yes
    #AllowTcpForwarding yes
    #GatewayPorts no
    X11Forwarding no
    #X11DisplayOffset 10
    #X11UseLocalhost yes
    #PermitTTY yes
    PrintMotd no
    #PrintLastLog yes
    #TCPKeepAlive yes
    #PermitUserEnvironment no
    #Compression delayed
    #ClientAliveInterval 0
    #ClientAliveCountMax 3
    #UseDNS no
    #PidFile /run/sshd.pid
    #MaxStartups 10:30:100
    #PermitTunnel no
    #ChrootDirectory none
    #VersionAddendum none

    # no default banner path
    #Banner none

    # Allow client to pass locale and color environment variables
    AcceptEnv LANG LC_* COLORTERM NO_COLOR

    # override default of no subsystems
    Subsystem       sftp    /usr/lib/openssh/sftp-server

    # Example of overriding settings on a per-user basis
    #Match User anoncvs
    #       X11Forwarding no
    #       AllowTcpForwarding no
    #       PermitTTY no
    #       ForceCommand cvs server

    # Only users from the 'ssauth' group can connect remotely through ssh.
    # They are required to provide both a valid ssh key and a TFA code.
    Match Group sshauth
            AuthenticationMethods publickey,keyboard-interactive

    # Users not in the sshauth group are not allowed to connect through ssh.
    # They won't have any authentication method available.
    Match Group *,!sshauth
            AuthenticationMethods none
    ~~~

2. Save the file and restart the `sshd` service:

    ~~~sh
    $ sudo systemctl restart sshd.service
    ~~~

3. Try to login opening a new non-shared SSH session with your `mgrsys` user. Also, you can try to log in as `root` and verify that it is not possible to connect with that user at all through SSH.

## Configuring Fail2Ban for SSH connections

Fail2Ban is already enabled for SSH connections in the VM, but it needs a more refined configuration, as you did back in the [chapter **G010**](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md).

1. As `mgrsys`, `cd` to `/etc/fail2ban/jail.d` and create an empty file called `01_sshd.conf`:

    ~~~sh
    $ cd /etc/fail2ban/jail.d ; sudo touch 01_sshd.conf
    ~~~

2. Edit the `01_sshd.conf` file by inserting the configuration lines below:

    ~~~sh
    [sshd]
    enabled = true
    port = 22
    maxretry = 3
    ~~~

    > [!IMPORTANT]
    > Remember to set the `maxretry` parameter with the same value as the `MaxAuthTries` in the `sshd` configuration!

3. Save the changes and restart the fail2ban service:

    ~~~sh
    $ sudo systemctl restart fail2ban.service
    ~~~

4. Check the current status of the fail2ban service with the `fail2ban-client` command:

    ~~~sh
    $ sudo fail2ban-client status
    Status
    |- Number of jail:      1
    `- Jail list:   sshd
    ~~~

## Disabling the `root` user login

Now that your Debian VM has an administrative `sudo` user like `mgrsys` and a hardened SSH service, you can disable the `root` user login altogether:

1. As your administrative `mgrsys` user, `cd` to `/etc` and check the `passwd` files present there:

    ~~~sh
    $ cd /etc/
    $ ls -al pass*
    -rw-r--r-- 1 root root 1285 Sep  4 11:52 passwd
    -rw-r--r-- 1 root root 1239 Sep  3 14:00 passwd-
    ~~~

    The `passwd-` is a backup made by some commands (like `adduser`) that modify the `passwd` file. Other files like `group`, `gshadow`, `shadow` and `subgid` also have backups of this kind.

2. Edit the `passwd` file, by only changing the `root` line to make it look as shown below:

    ~~~sh
    root:x:0:0:root:/root:/usr/sbin/nologin
    ~~~

    With this setup, any program that requires a shell for login will not be able to do so with the `root` user.

3. Then, lock the `root` password:

    ~~~sh
    $ sudo passwd -l root
    ~~~

    A user with the password locked cannot login at all. The `passwd -l` command corrupts, by putting a `!` character, the `root` password hash stored in the `/etc/shadow` file.

    ~~~sh
    root:!$7$HVw1KYN.qAC.lOMC$zb3vRm1oqqdR.gITdV.Lce9XuTjkv7CZ2z4R7diVsduplK.cAGeByZc1Gk3wfhQA6pzuzls3VT9/GhcjehiX70:20336:0:99999:7:::
    ~~~

To check that you cannot login with the `root` user, open a noVNC terminal on the VM from the web console and try to login as `root`. You will get a `Login incorrect` message back every time you try.

## Configuring the VM with `sysctl`

Next thing to do is to harden and improve the configuration of the VM with `sysctl` settings, as you did in the chapters [**G012**](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md) and [**G015**](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md) for your Proxmox VE host. Since your VM is also running a Debian system, the `sysctl` values applied here are mostly the same as the ones applied to your PVE node.

> [!NOTE]
> **This `sysctl` configuration is kind of generic but oriented to support virtualization and containers, as the Proxmox VE platform does**\
> In later chapters of this guide, you will have to change some of these settings in the VMs you will use as nodes of your Kubernetes cluster.

As `mgrsys`, `cd` to `/etc/sysctl.d/` and apply the configuration files detailed in the following subsections.

~~~sh
$ cd /etc/sysctl.d
~~~

### TCP/IP stack hardening

1. Create a new empty file called `80_tcp_hardening.conf`:

    ~~~sh
    $ sudo touch 80_tcp_hardening.conf
    ~~~

2. Edit `80_tcp_hardening.conf`, adding the following content to it:

    ~~~properties
    ## TCP/IP stack hardening

    # Disable IPv6 protocol
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1

    # Timeout broken connections faster (amount of time to wait for FIN).
    # Sets how many seconds to wait for a final FIN packet before the socket
    # is forcibly closed. This is strictly a violation of the TCP specification,
    # but required to prevent denial-of-service attacks.
    # https://sysctl-explorer.net/net/ipv4/tcp_fin_timeout/
    # Value in SECONDS.
    net.ipv4.tcp_fin_timeout = 10

    # IP loose spoofing protection or source route verification.
    # Complements the rule set in /usr/lib/sysctl.d/pve-firewall.conf for all interfaces.
    # Set to "loose" (2) to avoid unexpected networking problems in usual scenarios.
    net.ipv4.conf.default.rp_filter = 2

    # Ignore ICMP echo requests, or pings.
    # Commented by default since Proxmox VE or any other monitoring tool might
    # need to do pings to this host.
    # Uncomment only if you're sure that your system won't need to respond to pings.
    # net.ipv4.icmp_echo_ignore_all = 1
    # net.ipv6.icmp.echo_ignore_all = 1

    # Disable source packet routing; this system is not a router.
    net.ipv4.conf.default.accept_source_route = 0

    # Ignore send redirects; this system is not a router.
    net.ipv4.conf.all.send_redirects = 0
    net.ipv4.conf.default.send_redirects = 0

    # Do not accept ICMP redirects; prevents MITM attacks.
    net.ipv4.conf.all.accept_redirects = 0
    net.ipv4.conf.default.accept_redirects = 0
    net.ipv4.conf.all.secure_redirects = 0
    net.ipv4.conf.default.secure_redirects = 0

    # Protect against tcp time-wait assassination hazards,
    # drop RST packets for sockets in the time-wait state.
    net.ipv4.tcp_rfc1337 = 1

    # Only retry creating TCP connections twice.
    # Minimize the time it takes for a connection attempt to fail.
    net.ipv4.tcp_syn_retries = 2
    net.ipv4.tcp_synack_retries = 2
    net.ipv4.tcp_orphan_retries = 2

    # For intranets or low latency users, SACK is not worth it.
    # Also can become a performance and security issue.
    net.ipv4.tcp_sack = 0

    # A martian packet is an IP packet which specifies a source or destination
    # address that is reserved for special-use by Internet Assigned Numbers Authority
    # (IANA).
    # To monitor 'martian' packets in your logs, enable the lines below.
    # Be aware that this can fill up your logs with a lot of information,
    # so use these options only if you really need to do some checking or diagnostics.
    # net.ipv4.conf.all.log_martians = 1
    # net.ipv4.conf.default.log_martians = 1
    ~~~

3. Save the `80_tcp_hardening.conf` file and apply it in your system:

    ~~~sh
    $ sudo sysctl -p 80_tcp_hardening.conf
    ~~~

### Network optimizations

1. Create a new empty file called  `85_network_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_network_optimizations.conf
    ~~~

2. Edit the `85_network_optimizations.conf` file, adding the following content to it:

    ~~~properties
    ## NETWORK optimizations

    # TCP Fast Open is an extension to the transmission control protocol (TCP)
    # that helps reduce network latency by enabling data to be exchanged during
    # the sender’s initial TCP SYN [3]. Using the value 3 instead of the default 1
    # allows TCP Fast Open for both incoming and outgoing connections.
    net.ipv4.tcp_fastopen = 3

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
    # Disconnect dead TCP connections after 1 minute.
    # https://sysctl-explorer.net/net/ipv4/tcp_keepalive_time/
    # Value in SECONDS.
    net.ipv4.tcp_keepalive_time = 60
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
    # having many virtual machines or containers running in the system.
    # https://www.serveradminblog.com/2011/02/neighbour-table-overflow-sysctl-conf-tunning/
    net.ipv4.neigh.default.gc_thresh1 = 1024
    net.ipv4.neigh.default.gc_thresh2 = 4096
    net.ipv4.neigh.default.gc_thresh3 = 8192

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

### Memory optimizations

1. Create a new empty file called `85_memory_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_memory_optimizations.conf
    ~~~

2. Edit the `85_memory_optimizations.conf` file, adding the following content to it:

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

    # This file contains the maximum number of memory map areas a process may have.
    # Memory map areas are used as a side-effect of calling malloc, directly by
    # mmap and mprotect, and also when loading shared libraries.
    vm.max_map_count = 262144
    ~~~

3. Save the `85_memory_optimizations.conf` file and apply the changes:

    ~~~sh
    $ sudo sysctl -p 85_memory_optimizations.conf
    ~~~

### Kernel optimizations

1. Create a new empty file called `85_kernel_optimizations.conf`:

    ~~~sh
    $ sudo touch 85_kernel_optimizations.conf
    ~~~

2. Edit the `85_kernel_optimizations.conf` file, adding the following content to it:

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

    # This is the maximum number of keys a non-root user can use, should be higher
    # than the number of containers
    kernel.keys.maxkeys = 2000

    # Increase kernel hardcoded defaults by a factor of 512 to allow running more
    # than a very limited count of inotfiy hungry CTs (i.e., those with newer
    # systemd >= 240). This can be done as the memory used by the queued events and
    # watches is accounted to the respective memory CGroup.
    #
    # 2^23
    fs.inotify.max_queued_events = 8388608
    # 2^16
    fs.inotify.max_user_instances = 65536
    # 2^22
    fs.inotify.max_user_watches = 4194304
    ~~~

3. Save the `85_kernel_optimizations.conf` file and apply the changes:

    ~~~sh
    $ sudo sysctl -p 85_kernel_optimizations.conf
    ~~~

## Reboot the VM

Although you have applied the changes with the `sysctl -p` command, restart the VM.

~~~sh
$ sudo reboot
~~~

Then, login as `mgrsys` and check the system's journal (`journalctl` command) to look for possible errors or warnings related to your changes.

## Disabling transparent hugepages on the VM

Back in the [chapter **G016**](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md), you disabled the transparent hugepages in your Proxmox VE host. Do the same in this VM:

1. Check the current status of the transparent hugepages:

    ~~~sh
    $ cat /sys/kernel/mm/transparent_hugepage/enabled
    [always] madvise never
    ~~~

    Is set as `always` active, which means that probably is already in use. Check its current usage then:

    ~~~sh
    $ grep AnonHuge /proc/meminfo
    AnonHugePages:      6144 kB
    ~~~

    In this case, 6 MiB are currently in use for transparent hugepages.

2. To switch the `/sys/kernel/mm/transparent_hugepage/enabled` value to `never`, first `cd` to `/etc/default/` and make a backup of the original `grub` file:

    ~~~sh
    $ cd /etc/default/ ; sudo cp grub grub.orig
    ~~~

3. Edit the `grub` file, modifying the `GRUB_CMDLINE_LINUX=""` line as follows:

    ~~~properties
    GRUB_CMDLINE_LINUX="transparent_hugepage=never"
    ~~~

4. Update the grub and reboot the system:

    ~~~sh
    $ sudo update-grub
    $ sudo reboot
    ~~~

5. After the reboot, check the current status of the transparent hugepages:

    ~~~sh
    $ cat /sys/kernel/mm/transparent_hugepage/enabled
    always madvise [never]
    $ grep AnonHuge /proc/meminfo
    AnonHugePages:         0 kB
    ~~~

## Regarding the microcode `apt` packages for CPU vulnerabilities

In the [chapter **G013**](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md), you applied a microcode package to mitigate vulnerabilities found within your host's CPU. You could think that you also need to apply such package in the VM, but installing it in a VM is useless, since the KVM hypervisor does not allow the VM to apply such microcode to the real CPU installed in your Proxmox VE host. In short, never install CPU microcode packages in VMs.

### The Debian installer has installed the microcode package

While monitoring the installation of the Debian VM, I noticed that the installer installs the microcode package. This is certainly incorrect, so you should uninstall it as follows:

1. Purge the microcode package with `apt`:

    ~~~sh
    $ sudo apt -y purge intel-microcode
    ~~~

    Replace `intel-microcode` for `amd-microcode` if your microcode package is the one for AMD CPUs.

2. To autoremove any related packages to the purged microcode one that are no longer required in your Debian VM, use `apt` again:

    ~~~sh
    $ sudo apt -y autoremove
    ~~~

3. Reboot the VM:

    ~~~sh
    $ sudo reboot
    ~~~

## Relevant system paths

### Directories on Debian VM

- `/dev`
- `/etc`
- `/etc/apt/sources.list.d`
- `/etc/default`
- `/etc/fail2ban/jail.d`
- `/etc/pam.d`
- `/etc/qemu`
- `/etc/ssh`
- `/etc/sysctl.d`
- `/proc`
- `$HOME`
- `$HOME/.ssh`

### Files on Debian VM

- `/etc/apt/sources.list.d/debian-nonfree.list`
- `/etc/default/grub`
- `/etc/default/grub.orig`
- `/etc/fail2ban/jail.d/01_sshd.conf`
- `/etc/pam.d/sshd`
- `/etc/pam.d/sshd.orig`
- `/etc/passwd`
- `/etc/passwd-`
- `/etc/qemu/qemu-ga.conf`
- `/etc/shadow`
- `/etc/ssh/sshd_config`
- `/etc/ssh/sshd_config.orig`
- `/etc/sysctl.d/80_tcp_hardening.conf`
- `/etc/sysctl.d/85_kernel_optimizations.conf`
- `/etc/sysctl.d/85_memory_optimizations.conf`
- `/etc/sysctl.d/85_network_optimizations.conf`
- `/proc/meminfo`
- `/usr/sbin/qemu-ga`
- `$HOME/.google_authenticator`
- `$HOME/.ssh/authorized_keys`
- `$HOME/.ssh/id_ed25519`
- `$HOME/.ssh/id_ed25519.pub`

## References

### [Proxmox](https://www.proxmox.com/en/)

- [Proxmox VE Wiki](https://pve.proxmox.com/wiki/Main_Page)
  - [Qemu-guest-agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)

### [QEMU](https://www.qemu.org/)

- [QEMU Wiki](https://wiki.qemu.org/Main_Page)
- [Features/GuestAgent](https://wiki.qemu.org/Features/GuestAgent)

### About `sudo`

- [Server Space. Tutorials. Instructions. Debian superuser rights (sudo, visudo)](https://serverspace.us/support/help/debian-superuser-rights-sudo-visudo/)

### Disabling `root` login

- [Tecmint. 4 Ways to Disable Root Account in Linux](https://www.tecmint.com/disable-root-login-in-linux/)
- [StackExchange. Unix & Linux. Should I disable the root account on my Debian PC for security?](https://unix.stackexchange.com/a/383309)
- [StackExchange. Unix & Linux. Who creates /etc/{group,gshadow,passwd,shadow}-?](https://unix.stackexchange.com/questions/27717/who-creates-etc-group-gshadow-passwd-shadow)

### Microcode packages on VMs

- [Reddit. debian. What if you have a microcode package installed on the VM?](https://www.reddit.com/r/debian/comments/bqk2z0/is_it_necessary_to_install_intelmicrocode_to/eo5zt6i?utm_source=share&utm_medium=web2x&context=3)

## Navigation

[<< Previous (**G020. K3s cluster setup 03**)](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G022. K3s cluster setup 05**) >>](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md)
