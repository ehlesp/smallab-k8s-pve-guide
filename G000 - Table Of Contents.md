# **G000** - Table Of Contents

## [**README**](README.md#small-homelab-k8s-cluster-on-proxmox-ve)

- [Introduction](README.md#introduction)
- [Description of contents](README.md#description-of-contents)
- [Intended audience](README.md#intended-audience)
- [Goals](README.md#goals)

## [**LICENSE**](LICENSE.md)

- [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License](LICENSE.md#creative-commons-attribution-noncommercial-sharealike-40-international-public-license)

## Guides

### [**G001** - Hardware setup](G001%20-%20Hardware%20setup.md#g001-hardware-setup)

- [You just need a capable enough computer](G001%20-%20Hardware%20setup.md#you-just-need-a-capable-enough-computer)
- [The reference hardware setup](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup)
- [References](G001%20-%20Hardware%20setup.md#references)

### [**G002** - Proxmox VE installation](G002%20-%20Proxmox%20VE%20installation.md#g002-proxmox-ve-installation)

- [System Requirements](G002%20-%20Proxmox%20VE%20installation.md#system-requirements)
- [Installation procedure](G002%20-%20Proxmox%20VE%20installation.md#installation-procedure)
- [After the installation](G002%20-%20Proxmox%20VE%20installation.md#after-the-installation)
- [Connecting remotely](G002%20-%20Proxmox%20VE%20installation.md#connecting-remotely)
- [References](G002%20-%20Proxmox%20VE%20installation.md#references)

### [**G003** - Host configuration 01 ~ Apt sources, updates and extra tools](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#g003-host-configuration-01-apt-sources-updates-and-extra-tools)

- [Remember, Proxmox VE 7.0 runs on Debian 11_ bullseye](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#remember-proxmox-ve-70-runs-on-debian-11-bullseye)
- [Editing the apt repository sources](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#editing-the-apt-repository-sources)
- [Update your system](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#update-your-system)
- [Installing useful extra tools](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#installing-useful-extra-tools)
- [Relevant system paths](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#relevant-system-paths)
- [References](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#references)

### [**G004** - Host configuration 02 ~ UPS management with NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#g004-host-configuration-02-ups-management-with-nut)

- [Connecting your UPS with your pve node using NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#connecting-your-ups-with-your-pve-node-using-nut)
- [Executing instant commands on the UPS unit](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#executing-instant-commands-on-the-ups-unit)
- [Other possibilities with NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#other-possibilities-with-nut)
- [Relevant system paths](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#relevant-system-paths)
- [References](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#references)

### [**G005** - Host configuration 03 ~ LVM storage](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#g005-host-configuration-03-lvm-storage)

- [Initial filesystem configuration (**web console**)](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-web-console)
- [Initial filesystem configuration (**shell as root**)](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-shell-as-root)
- [Configuring the unused storage drives](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#configuring-the-unused-storage-drives)
- [LVM rearrangement in the main storage drive](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#lvm-rearrangement-in-the-main-storage-drive)
- [References](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#references)

### [**G006** - Host configuration 04 ~ Removing Proxmox's subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md)

- [About the Proxmox subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#about-the-proxmox-subscription-warning)
- [Removing the subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#removing-the-subscription-warning)
- [Reverting the changes](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#reverting-the-changes)
- [Change executed in just one command line](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#change-executed-in-just-one-command-line)
- [Final note](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#final-note)
- [Relevant system paths](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#relevant-system-paths)
- [References](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#references)

### [**G007** - Host hardening 01 ~ TFA authentication](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#g007-host-hardening-01-tfa-authentication)

- [Enable Two Factor Authentication in your PVE system](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enable-two-factor-authentication-in-your-pve-system)
- [Enabling TFA for SSH access](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enabling-tfa-for-ssh-access)
- [Enforcing TFA TOTP for accessing the Proxmox VE web console](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-for-accessing-the-proxmox-ve-web-console)
- [Enforcing TFA TOTP as a default requirement for `pam` realm](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-as-a-default-requirement-for-pam-realm)
- [Incompatibility of PVE web console login with TFA enforced local shell access](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#incompatibility-of-pve-web-console-login-with-tfa-enforced-local-shell-access)
- [Relevant system paths](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#relevant-system-paths)
- [References](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#references)

### [**G008** - Host hardening 02 ~ Alternative administrator user](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#g008-host-hardening-02-alternative-administrator-user)

- [Avoid using the root user](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#avoid-using-the-root-user)
- [Understanding the Proxmox VE user management and the realms](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#understanding-the-proxmox-ve-user-management-and-the-realms)
- [Creating a new system administrator user for a Proxmox VE node](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#creating-a-new-system-administrator-user-for-a-proxmox-ve-node)
- [Relevant system paths](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#relevant-system-paths)
- [References](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#references)

### [**G009** - Host hardening 03 ~ SSH key pairs and sshd service configuration](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#g009-host-hardening-03-ssh-key-pairs-and-sshd-service-configuration)

- [Harden your SSH connections with key pairs](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#harden-your-ssh-connections-with-key-pairs)
- [SSH key pairs](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#ssh-key-pairs)
- [Hardening the `sshd` service](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#hardening-the-sshd-service)
- [Relevant system paths](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#relevant-system-paths)
- [References](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#references)

### [**G010** - Host hardening 04 ~ Enabling Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#g010-host-hardening-04-enabling-fail2ban)

- [Harden your setup against intrusions with Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#harden-your-setup-against-intrusions-with-fail2ban)
- [Installing Fail2ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#installing-fail2ban)
- [Configuring Fail2ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#configuring-fail2ban)
- [Considerations regarding Fail2ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#considerations-regarding-fail2ban)
- [Relevant system paths](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#relevant-system-paths)
- [References](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#references)

### [**G011** - Host hardening 05 ~ Proxmox VE services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#g011-host-hardening-05-proxmox-ve-services)

- [Reduce your Proxmox VE server's exposed surface](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#reduce-your-proxmox-ve-servers-exposed-surface)
- [Checking currently running services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#checking-currently-running-services)
- [Configuring the `pveproxy` service](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#configuring-the-pveproxy-service)
- [Disabling RPC services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-rpc-services)
- [Disabling `zfs` and `ceph`](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-zfs-and-ceph)
- [Disabling the SPICE proxy](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-the-spice-proxy)
- [Disabling cluster and high availability related services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-cluster-and-high-availability-related-services)
- [Considerations](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#considerations)
- [Relevant system paths](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#relevant-system-paths)
- [References](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#references)

### [**G012** - Host hardening 06 ~ Network hardening with sysctl](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#g012-host-hardening-06-network-hardening-with-sysctl)

- [Harden your PVE's networking with a `sysctl` configuration](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#harden-your-pves-networking-with-a-sysctl-configuration)
- [About `sysctl`](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#about-sysctl)
- [TCP/IP stack hardening with `sysctl`](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#tcpip-stack-hardening-with-sysctl)
- [Relevant system paths](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#relevant-system-paths)
- [References](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#references)

### [**G013** - Host hardening 07 ~ Mitigating CPU vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#g013-host-hardening-07-mitigating-cpu-vulnerabilities)

- [CPUs also have security vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#cpus-also-have-security-vulnerabilities)
- [Discovering your CPU's vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#discovering-your-cpus-vulnerabilities)
- [Applying the correct microcode package](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#applying-the-correct-microcode-package)
- [Relevant system paths](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#relevant-system-paths)
- [References](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#references)

### [**G014** - Host hardening 08 ~ Firewalling](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#g014-host-hardening-08-firewalling)

- [Proxmox VE firewall uses `iptables`](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#proxmox-ve-firewall-uses-iptables)
- [Zones in the Proxmox VE firewall](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#zones-in-the-proxmox-ve-firewall)
- [Situation at this point](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#situation-at-this-point)
- [Enabling the firewall at the `Datacenter` tier](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#enabling-the-firewall-at-the-datacenter-tier)
- [Firewalling with `ebtables`](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewalling-with-ebtables)
- [Firewall fine tuning](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-fine-tuning)
- [Firewall logging](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-logging)
- [Connection tracking tool](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#connection-tracking-tool)
- [Relevant system paths](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#relevant-system-paths)
- [References](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#references)

### [**G015** - Host optimization 01 ~ Adjustments through sysctl](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#g015-host-optimization-01-adjustments-through-sysctl)

- [Network optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#network-optimizations)
- [Memory optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#memory-optimizations)
- [Kernel optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#kernel-optimizations)
- [Reboot the system](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#reboot-the-system)
- [Final considerations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#final-considerations)
- [Relevant system paths](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#relevant-system-paths)
- [References](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#references)

### [**G016** - Host optimization 02 ~ Disabling transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#g016-host-optimization-02-disabling-transparent-hugepages)

- [Status of transparent hugepages in your host](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#status-of-transparent-hugepages-in-your-host)
- [Disabling the transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#disabling-the-transparent-hugepages)
- [Relevant system paths](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#relevant-system-paths)
- [References](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#references)

### [**G017** - Virtual Networking ~ Network configuration](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#g017-virtual-networking-network-configuration)

- [Current virtual network setup](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#current-virtual-network-setup)
- [Target network scenario](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#target-network-scenario)
- [Creating an isolated Linux bridge](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#creating-an-isolated-linux-bridge)
- [Bridges management](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#bridges-management)
- [Relevant system paths](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#relevant-system-paths)
- [References](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#references)

### [**G018** - K3s cluster setup 01 ~ Requirements and arrangement](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#g018-k3s-cluster-setup-01-requirements-and-arrangement)

- [Requirements for the K3s cluster and the services to deploy in it](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it)
- [Arrangement of VMs and services](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#arrangement-of-vms-and-services)
- [References](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#references)

### [**G019** - K3s cluster setup 02 ~ Storage setup](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#g019-k3s-cluster-setup-02-storage-setup)

- [Storage organization model](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#storage-organization-model)
- [Creating the logical volumes (LVs)](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#creating-the-logical-volumes-lvs)
- [Enabling the LVs for Proxmox VE](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#enabling-the-lvs-for-proxmox-ve)
- [Configuration file](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#configuration-file)
- [Relevant system paths](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#relevant-system-paths)
- [References](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#references)

### [**G020** - K3s cluster setup 03 ~ Debian VM creation](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#g020-k3s-cluster-setup-03-debian-vm-creation)

- [Preparing the Debian ISO image](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#preparing-the-debian-iso-image)
- [Building a Debian virtual machine](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#building-a-debian-virtual-machine)
- [Note about the VM's `Boot Order` option](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#note-about-the-vms-boot-order-option)
- [Relevant system paths](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#relevant-system-paths)
- [References](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#references)

### [**G021** - K3s cluster setup 04 ~ Debian VM configuration](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#g021-k3s-cluster-setup-04-debian-vm-configuration)

- [Suggestion about IP configuration in your network](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#suggestion-about-ip-configuration-in-your-network)
- [Adding the `apt` sources for _non-free_ packages](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#adding-the-apt-sources-for-non-free-packages)
- [Installing extra packages](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#installing-extra-packages)
- [The QEMU guest agent comes enabled in Debian 11](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#the-qemu-guest-agent-comes-enabled-in-debian-11)
- [Hardening the VM's access](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#hardening-the-vms-access)
- [Hardening the `sshd` service](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#hardening-the-sshd-service)
- [Configuring Fail2Ban for SSH connections](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#configuring-fail2ban-for-ssh-connections)
- [Disabling the `root` user login](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#disabling-the-root-user-login)
- [Configuring the VM with `sysctl`](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#configuring-the-vm-with-sysctl)
- [Reboot the VM](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#reboot-the-vm)
- [Disabling transparent hugepages on the VM](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#disabling-transparent-hugepages-on-the-vm)
- [Regarding the microcode `apt` packages for CPU vulnerabilities](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#regarding-the-microcode-apt-packages-for-cpu-vulnerabilities)
- [Relevant system paths](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#relevant-system-paths)
- [References](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#references)

### [**G022** - K3s cluster setup 05 ~ Connecting the VM to the NUT server](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#g022-k3s-cluster-setup-05-connecting-the-vm-to-the-nut-server)

- [Reconfiguring the NUT `master` server on your **Proxmox VE host**](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#reconfiguring-the-nut-master-server-on-your-proxmox-ve-host)
- [Configuring the NUT `slave` client on your Debian VM](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#configuring-the-nut-slave-client-on-your-debian-vm)
- [Checking the connection between the VM NUT `slave` client and the PVE node NUT `master` server](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#checking-the-connection-between-the-vm-nut-slave-client-and-the-pve-node-nut-master-server)
- [Testing a Forced ShutDown sequence (`FSD`) with NUT](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#testing-a-forced-shutdown-sequence-fsd-with-nut)
- [Relevant system paths](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#relevant-system-paths)
- [References](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#references)

### [**G023** - K3s cluster setup 06 ~ Debian VM template and backup](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#g023-k3s-cluster-setup-06-debian-vm-template-and-backup)

- [Turning the Debian VM into a VM template](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#turning-the-debian-vm-into-a-vm-template)
- [VM template's backup](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#vm-templates-backup)
- [Other considerations regarding VM templates](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#other-considerations-regarding-vm-templates)
- [References](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#references)

### [**G024** - K3s cluster setup 07 ~ K3s node VM template setup](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#g024-k3s-cluster-setup-07-k3s-node-vm-template-setup)

- [Reasons for a new VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#reasons-for-a-new-vm-template)
- [Creating a new VM based on the Debian VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#creating-a-new-vm-based-on-the-debian-vm-template)
- [Set an static IP for the main network device (`net0`)](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#set-an-static-ip-for-the-main-network-device-net0)
- [Setting a proper hostname string](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-a-proper-hostname-string)
- [Disabling the swap volume](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#disabling-the-swap-volume)
- [Changing the VG's name](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#changing-the-vgs-name)
- [Setting up the second network card](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-the-second-network-card)
- [Setting up sysctl kernel parameters for K3s nodes](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-sysctl-kernel-parameters-for-k3s-nodes)
- [Turning the VM into a VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#turning-the-vm-into-a-vm-template)
- [Protecting VMs and VM templates in Proxmox VE](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#protecting-vms-and-vm-templates-in-proxmox-ve)
- [Relevant system paths](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#relevant-system-paths)
- [References](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#references)

### [**G025** - K3s cluster setup 08 ~ K3s Kubernetes cluster setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#g025-k3s-cluster-setup-08-k3s-kubernetes-cluster-setup)

- [Criteria for the VMs' IPs and hostnames](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-the-vms-ips-and-hostnames)
- [Creation of VMs based on the K3s node VM template](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#creation-of-vms-based-on-the-k3s-node-vm-template)
- [Preparing the VMs for K3s](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#preparing-the-vms-for-k3s)
- [Firewall setup for the K3s cluster](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#firewall-setup-for-the-k3s-cluster)
- [Considerations before installing the K3s cluster nodes](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#considerations-before-installing-the-k3s-cluster-nodes)
- [K3s Server node setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-server-node-setup)
- [K3s Agent nodes setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-agent-nodes-setup)
- [Enabling bash autocompletion for `kubectl`](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-bash-autocompletion-for-kubectl)
- [Enabling the `k3s.log` file's rotation](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-k3slog-files-rotation)
- [Enabling the `containerd.log` file's rotation](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-containerdlog-files-rotation)
- [K3s relevant paths](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-relevant-paths)
- [Starting up and shutting down the K3s cluster nodes](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#starting-up-and-shutting-down-the-k3s-cluster-nodes)
- [Relevant system paths](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#relevant-system-paths)
- [References](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#references)

### [**G026** - K3s cluster setup 09 ~ Setting up a kubectl client for remote access](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#g026-k3s-cluster-setup-09-setting-up-a-kubectl-client-for-remote-access)

- [Scenario](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#scenario)
- [Getting the right version of `kubectl`](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-right-version-of-kubectl)
- [Installing `kubectl` on your client system](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#installing-kubectl-on-your-client-system)
- [Getting the configuration for accessing the K3s cluster](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-configuration-for-accessing-the-k3s-cluster)
- [Opening the `6443` port in the K3s server node](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#opening-the-6443-port-in-the-k3s-server-node)
- [Enabling bash autocompletion for `kubectl`](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#enabling-bash-autocompletion-for-kubectl)
- [**Kubeval**, tool for validating Kubernetes configuration files](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#kubeval-tool-for-validating-kubernetes-configuration-files)
- [Relevant system paths](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#relevant-system-paths)
- [References](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#references)

### [**G027** - K3s cluster setup 10 ~ Deploying the MetalLB load balancer](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#g027-k3s-cluster-setup-10-deploying-the-metallb-load-balancer)

- [Considerations before deploying MetalLB](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#considerations-before-deploying-metallb)
- [Choosing the IP ranges for MetalLB](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#choosing-the-ip-ranges-for-metallb)
- [Deploying MetalLB on your K3s cluster](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#deploying-metallb-on-your-k3s-cluster)
- [MetalLB's Kustomize project attached to this guide series](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#metallbs-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#relevant-system-paths)
- [References](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#references)

### [**G028** - K3s cluster setup 11 ~ Deploying the metrics-server service](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#g028-k3s-cluster-setup-11-deploying-the-metrics-server-service)

- [Checking the metrics-server's manifest](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-servers-manifest)
- [Deployment of metrics-server](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deployment-of-metrics-server)
- [Checking the metrics-server service](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-server-service)
- [Metrics-server's Kustomize project attached to this guide series](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#metrics-servers-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#relevant-system-paths)
- [References](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#references)

### [**G029** - K3s cluster setup 12 ~ Setting up cert-manager and wildcard certificate](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#g029-k3s-cluster-setup-12-setting-up-cert-manager-and-wildcard-certificate)

- [Warning about cert-manager performance](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#warning-about-cert-manager-performance)
- [Deploying cert-manager](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#deploying-cert-manager)
- [Reflector, a solution for syncing secrets and configmaps](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#reflector-a-solution-for-syncing-secrets-and-configmaps)
- [Setting up a wildcard certificate for a domain](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#setting-up-a-wildcard-certificate-for-a-domain)
- [Checking your certificate with the `kubectl` cert-manager plugin](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#checking-your-certificate-with-the-kubectl-cert-manager-plugin)
- [Cert-manager and Reflector's Kustomize projects attached to this guide series](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#cert-manager-and-reflectors-kustomize-projects-attached-to-this-guide-series)
- [Relevant system paths](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#relevant-system-paths)
- [References](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#references)

### [**G030** - K3s cluster setup 13 ~ Deploying the Kubernetes Dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#g030-k3s-cluster-setup-13-deploying-the-kubernetes-dashboard)

- [Deploying Kubernetes Dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#deploying-kubernetes-dashboard)
- [Testing Kubernetes Dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#testing-kubernetes-dashboard)
- [Kubernetes Dashboard's Kustomize project attached to this guide series](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#kubernetes-dashboards-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#relevant-system-paths)
- [References](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#references)

### [**G031** - K3s cluster setup 14 ~ Enabling the Traefik dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#g031-k3s-cluster-setup-14-enabling-the-traefik-dashboard)

- [Creating an IngressRoute for Traefik dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#creating-an-ingressroute-for-traefik-dashboard)
- [Getting into the dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#getting-into-the-dashboard)
- [Traefik dashboard has bad performance](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-has-bad-performance)
- [Traefik dashboard's Kustomize project attached to this guide series](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboards-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#relevant-system-paths)
- [References](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#references)

### [**G032** - Deploying services 01 ~ Considerations](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#g032-deploying-services-01-considerations)

- [Be watchful of your system's resources usage](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#be-watchful-of-your-systems-resources-usage)
- [Don't fill your setup up to the brim](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#dont-fill-your-setup-up-to-the-brim)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 1** - Outlining setup, arranging storage and choosing service IPs](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#g033-deploying-services-02-nextcloud-part-1-outlining-setup-arranging-storage-and-choosing-service-ips)

- [Outlining Nextcloud's setup](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#outlining-nextclouds-setup)
- [Setting up new storage drives in the K3s agent](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#setting-up-new-storage-drives-in-the-k3s-agent)
- [Choosing static cluster IPs for Nextcloud related services](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#choosing-static-cluster-ips-for-nextcloud-related-services)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#relevant-system-paths)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 2** - Redis cache server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#g033-deploying-services-02-nextcloud-part-2-redis-cache-server)

- [Kustomize project folders for Nextcloud and Redis](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#kustomize-project-folders-for-nextcloud-and-redis)
- [Redis configuration file](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-configuration-file)
- [Redis password](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-password)
- [Redis Deployment resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-deployment-resource)
- [Redis Service resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource)
- [Redis Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-kustomize-project)
- [Don't deploy this Redis project on its own](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#dont-deploy-this-redis-project-on-its-own)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 3** - MariaDB database server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#g033-deploying-services-02-nextcloud-part-3-mariadb-database-server)

- [MariaDB Kustomize project's folders](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-projects-folders)
- [MariaDB configuration files](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-configuration-files)
- [MariaDB passwords](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-passwords)
- [MariaDB storage](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-storage)
- [MariaDB StatefulSet resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource)
- [MariaDB Service resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-service-resource)
- [MariaDB Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-project)
- [Don't deploy this MariaDB project on its own](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#dont-deploy-this-mariadb-project-on-its-own)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 4** - Nextcloud server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#g033-deploying-services-02-nextcloud-part-4-nextcloud-server)

- [Considerations about the Nextcloud server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#considerations-about-the-nextcloud-server)
- [Nextcloud server Kustomize project's folders](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-kustomize-projects-folders)
- [Nextcloud server configuration files](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-configuration-files)
- [Nextcloud server password](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-password)
- [Nextcloud server storage](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-storage)
- [Nextcloud server Stateful resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-stateful-resource)
- [Nextcloud server Service resource](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-service-resource)
- [Nextcloud server Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-kustomize-project)
- [Don't deploy this Nextcloud server project on its own](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#dont-deploy-this-nextcloud-server-project-on-its-own)
- [Background jobs on Nextcloud](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#background-jobs-on-nextcloud)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 5** - Complete Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#g033-deploying-services-02-nextcloud-part-5-complete-nextcloud-platform)

- [Preparing pending Nextcloud platform elements](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#preparing-pending-nextcloud-platform-elements)
- [Kustomize project for Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#kustomize-project-for-nextcloud-platform)
- [Logging and checking the background jobs configuration on your Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#logging-and-checking-the-background-jobs-configuration-on-your-nextcloud-platform)
- [Security considerations in Nextcloud](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#security-considerations-in-nextcloud)
- [Nextcloud platform's Kustomize project attached to this guide series](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#nextcloud-platforms-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 1** - Outlining setup and arranging storage](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#g034-deploying-services-03-gitea-part-1-outlining-setup-and-arranging-storage)

- [Outlining Gitea's setup](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-giteas-setup)
- [Setting up new storage drives in the K3s agent](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agent)
- [FQDNs for Gitea related services](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#fqdns-for-gitea-related-services)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 2** - Redis cache server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#g034-deploying-services-03-gitea-part-2-redis-cache-server)

- [Kustomize project folders for Gitea and Redis](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#kustomize-project-folders-for-gitea-and-redis)
- [Redis configuration file](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-configuration-file)
- [Redis password](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-password)
- [Redis Deployment resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-deployment-resource)
- [Redis Service resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource)
- [Redis Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-kustomize-project)
- [Don't deploy this Redis project on its own](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#dont-deploy-this-redis-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 3** - PostgreSQL database server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#g034-deploying-services-03-gitea-part-3-postgresql-database-server)

- [PostgreSQL Kustomize project's folders](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-projects-folders)
- [PostgreSQL configuration files](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-configuration-files)
- [PostgreSQL passwords](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-passwords)
- [PostgreSQL storage](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-storage)
- [PostgreSQL StatefulSet resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-statefulset-resource)
- [PostgreSQL Service resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-service-resource)
- [PostgreSQL Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-project)
- [Don't deploy this PostgreSQL project on its own](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#dont-deploy-this-postgresql-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 4** - Gitea server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#g034-deploying-services-03-gitea-part-4-gitea-server)

- [Considerations about the Gitea server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#considerations-about-the-gitea-server)
- [Gitea server Kustomize project's folders](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-kustomize-projects-folders)
- [Gitea server configuration file](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-configuration-file)
- [Gitea server storage](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-storage)
- [Gitea server Stateful resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-stateful-resource)
- [Gitea server Service resource](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-service-resource)
- [Gitea server's Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-servers-kustomize-project)
- [Don't deploy this Gitea server project on its own](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#dont-deploy-this-gitea-server-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 5** - Complete Gitea platform](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#g034-deploying-services-03-gitea-part-5-complete-gitea-platform)

- [Declaring the pending Gitea platform elements](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#declaring-the-pending-gitea-platform-elements)
- [Kustomize project for Gitea platform](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#kustomize-project-for-gitea-platform)
- [Finishing Gitea platform's setup](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#finishing-gitea-platforms-setup)
- [Security considerations in Gitea](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#security-considerations-in-gitea)
- [Gitea platform's Kustomize project attached to this guide series](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#gitea-platforms-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 1** - Outlining setup and arranging storage](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#g035-deploying-services-04-monitoring-stack-part-1-outlining-setup-and-arranging-storage)

- [Outlining your monitoring stack setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-your-monitoring-stack-setup)
- [Setting up new storage drives in the K3s agents](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agents)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 2** - Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#g035-deploying-services-04-monitoring-stack-part-2-kube-state-metrics-service)

- [Kustomize project folders for your monitoring stack and Kube State Metrics](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kustomize-project-folders-for-your-monitoring-stack-and-kube-state-metrics)
- [Kube State Metrics ServiceAccount resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-serviceaccount-resource)
- [Kube State Metrics ClusterRole resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrole-resource)
- [Kube State Metrics ClusterRoleBinding resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrolebinding-resource)
- [Kube State Metrics Deployment resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-deployment-resource)
- [Kube State Metrics Service resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-service-resource)
- [Kube State Metrics Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-kustomize-project)
- [Don't deploy this Kube State Metrics project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#dont-deploy-this-kube-state-metrics-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 3** - Prometheus Node Exporter service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#g035-deploying-services-04-monitoring-stack-part-3-prometheus-node-exporter-service)

- [Kustomize project folders for Prometheus Node Exporter](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#kustomize-project-folders-for-prometheus-node-exporter)
- [Prometheus Node Exporter DaemonSet resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-daemonset-resource)
- [Prometheus Node Exporter Service resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-service-resource)
- [Prometheus Node Exporter Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-kustomize-project)
- [Don't deploy this Prometheus Node Exporter project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#dont-deploy-this-prometheus-node-exporter-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 4** - Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#g035-deploying-services-04-monitoring-stack-part-4-prometheus-server)

- [Kustomize project folders for Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#kustomize-project-folders-for-prometheus-server)
- [Prometheus configuration files](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-configuration-files)
- [Prometheus server storage](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-storage)
- [Prometheus server StatefulSet resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-statefulset-resource)
- [Prometheus server Service resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-service-resource)
- [Prometheus server Traefik IngressRoute resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-traefik-ingressroute-resource)
- [Prometheus server's Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-servers-kustomize-project)
- [Don't deploy this Prometheus server project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#dont-deploy-this-prometheus-server-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 5** - Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#g035-deploying-services-04-monitoring-stack-part-5-grafana)

- [Kustomize project folders for Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#kustomize-project-folders-for-grafana)
- [Grafana data storage](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-data-storage)
- [Grafana Stateful resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-stateful-resource)
- [Grafana Service resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-service-resource)
- [Grafana Traefik IngressRoute resource](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-traefik-ingressroute-resource)
- [Grafana Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-kustomize-project)
- [Don't deploy this Grafana project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#dont-deploy-this-grafana-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 6** - Complete monitoring stack setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#g035-deploying-services-04-monitoring-stack-part-6-complete-monitoring-stack-setup)

- [Declaring the remaining monitoring stack components](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#declaring-the-remaining-monitoring-stack-components)
- [Kustomize project for the monitoring setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#kustomize-project-for-the-monitoring-setup)
- [Checking Prometheus](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#checking-prometheus)
- [Finishing Grafana's setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#finishing-grafanas-setup)
- [Security concerns on Prometheus and Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#security-concerns-on-prometheus-and-grafana)
- [Monitoring stack's Kustomize project attached to this guide series](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stacks-kustomize-project-attached-to-this-guide-series)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#references)

### [**G036** - Host and K3s cluster ~ Monitoring and diagnosis](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#g036-host-and-k3s-cluster-monitoring-and-diagnosis)

- [Monitoring resources usage](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#monitoring-resources-usage)
- [Checking the logs](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#checking-the-logs)
- [Shell access into your containers](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers)
- [References](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#references)

### [**G037** - Backups 01 ~ Considerations](G037%20-%20Backups%2001%20~%20Considerations.md#g037-backups-01-considerations)

- [What to backup. Identifying your data concerns](G037%20-%20Backups%2001%20~%20Considerations.md#what-to-backup-identifying-your-data-concerns)
- [How to backup. Backup tools](G037%20-%20Backups%2001%20~%20Considerations.md#how-to-backup-backup-tools)
- [Where to store the backups. Backup storage](G037%20-%20Backups%2001%20~%20Considerations.md#where-to-store-the-backups-backup-storage)
- [When to do the backups. Backup scheduling](G037%20-%20Backups%2001%20~%20Considerations.md#when-to-do-the-backups-backup-scheduling)
- [References](G037%20-%20Backups%2001%20~%20Considerations.md#references)

### [**G038** - Backups 02 ~ Host platform backup with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#g038-backups-02-host-platform-backup-with-clonezilla)

- [What gets inside this backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#what-gets-inside-this-backup)
- [Why doing this backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#why-doing-this-backup)
- [How it affects the host platform](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-it-affects-the-host-platform)
- [When to do the backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#when-to-do-the-backup)
- [How to backup with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-backup-with-clonezilla)
- [How to restore with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-restore-with-clonezilla)
- [Final considerations](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#final-considerations)
- [References](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#references)

### [**G039** - Backups 03 ~ Proxmox VE backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#g039-backups-03-proxmox-ve-backup-job)

- [What gets covered with the backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#what-gets-covered-with-the-backup-job)
- [Why scheduling a backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#why-scheduling-a-backup-job)
- [How it affects the K3s Kubernetes cluster](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#how-it-affects-the-k3s-kubernetes-cluster)
- [When to do the backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#when-to-do-the-backup-job)
- [Scheduling the backup job in Proxmox VE](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#scheduling-the-backup-job-in-proxmox-ve)
- [Restoring a backup in Proxmox VE](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#restoring-a-backup-in-proxmox-ve)
- [Location of the backup files in the Proxmox VE system](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#location-of-the-backup-files-in-the-proxmox-ve-system)
- [Relevant system paths](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#relevant-system-paths)
- [References](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#references)

### [**G040** - Backups 04 ~ UrBackup 01 - Server setup](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#g040-backups-04-urbackup-01-server-setup)

- [Setting up a new VM for the UrBackup server](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#setting-up-a-new-vm-for-the-urbackup-server)
- [Deploying UrBackup](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#deploying-urbackup)
- [Firewall configuration on Proxmox VE](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#firewall-configuration-on-proxmox-ve)
- [Adjusting the UrBackup server configuration](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#adjusting-the-urbackup-server-configuration)
- [UrBackup server log file](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#urbackup-server-log-file)
- [About backing up the UrBackup server VM](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#about-backing-up-the-urbackup-server-vm)
- [Relevant system paths](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#relevant-system-paths)
- [References](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#references)

### [**G041** - Backups 05 ~ UrBackup 02 - Clients setup and configuring file backups](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#g041-backups-05-urbackup-02-clients-setup-and-configuring-file-backups)

- [Deploying the UrBackup client program](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#deploying-the-urbackup-client-program)
- [UrBackup client log file](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-log-file)
- [UrBackup client uninstaller](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-uninstaller)
- [Configuring file backup paths on a client](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#configuring-file-backup-paths-on-a-client)
- [Backups on the UrBackup server](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#backups-on-the-urbackup-server)
- [Restoration from file backups](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#restoration-from-file-backups)
- [Relevant system paths](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#relevant-system-paths)
- [References](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#references)

### [**G042** - System update 01 ~ Considerations](G042%20-%20System%20update%2001%20~%20Considerations.md#g042-system-update-01-considerations)

- [What to update. Identifying your system's software layers](G042%20-%20System%20update%2001%20~%20Considerations.md#what-to-update-identifying-your-systems-software-layers)
- [How to update. Update procedures](G042%20-%20System%20update%2001%20~%20Considerations.md#how-to-update-update-procedures)
- [When to apply the updates](G042%20-%20System%20update%2001%20~%20Considerations.md#when-to-apply-the-updates)

### [**G043** - System update 02 ~ Updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#g043-system-update-02-updating-proxmox-ve)

- [Examining your Proxmox VE system](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#examining-your-proxmox-ve-system)
- [Updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#updating-proxmox-ve)
- [References](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#references)

### [**G044** - System update 03 ~ Updating VMs and UrBackup](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#g044-system-update-03-updating-vms-and-urbackup)

- [Examining your VMs](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#examining-your-vms)
- [Updating Debian on your VMs](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-debian-on-your-vms)
- [Updating the UrBackup software](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-the-urbackup-software)
- [References](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#references)

### [**G045** - System update 04 ~ Updating K3s and deployed apps](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#g045-system-update-04-updating-k3s-and-deployed-apps)

- [Examining your K3s Kubernetes cluster](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#examining-your-k3s-kubernetes-cluster)
- [Updating apps and K3s](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#updating-apps-and-k3s)
- [References](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#references)

### [**G046** - Cleaning the system](G046%20-%20Cleaning%20the%20system.md#g046-cleaning-the-system)

- [Checking your storage status](G046%20-%20Cleaning%20the%20system.md#checking-your-storage-status)
- [Cleaning procedures](G046%20-%20Cleaning%20the%20system.md#cleaning-procedures)
- [Reminder about the `apt` updates](G046%20-%20Cleaning%20the%20system.md#reminder-about-the-apt-updates)
- [Relevant system paths](G046%20-%20Cleaning%20the%20system.md#relevant-system-paths)
- [References](G046%20-%20Cleaning%20the%20system.md#references)

## Appendixes

### [**G901** - Appendix 01 ~ Connecting through SSH with PuTTY](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#g901-appendix-01-connecting-through-ssh-with-putty)

- [Generating `.ppk` file from private key](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#generating-ppk-file-from-private-key)
- [Configuring the connection to the PVE node](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#configuring-the-connection-to-the-pve-node)
- [References](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#references)

### [**G902** - Appendix 02 ~ Vim vimrc configuration](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#g902-appendix-02-vim-vimrc-configuration)

- [References](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#references)

### [**G903** - Appendix 03 ~ Customization of the motd file](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md#g903-appendix-03-customization-of-the-motd-file)

- [References](G903%20-%20Appendiz%2003%20~%20Customization%20of%20the%20motd%20file.md#references)

### [**G904** - Appendix 04 ~ Object by object Kubernetes deployments](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#g904-appendix-04-object-by-object-kubernetes-deployments)

- [Example scenario: cert-manager deployment](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#example-scenario-cert-manager-deployment)
- [Relevant system paths](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#relevant-system-paths)
- [References](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#references)

### [**G905** - Appendix 05 ~ Cloning storage drives with Clonezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#g905-appendix-05-cloning-storage-drives-with-clonezilla)

- [Preparing the Clonezilla Live USB](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#preparing-the-clonezilla-live-usb)
- [Cloning a storage drive with Clonezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#cloning-a-storage-drive-with-clonezilla)
- [Restoring a Clonezilla image](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#restoring-a-clonezilla-image)
- [Considerations about Clonezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#considerations-about-clonezilla)
- [Alternative to Clonezilla:_ Rescuezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#alternative-to-clonezilla-rescuezilla)
- [References](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#references)

### [**G906** - Appendix 06 ~ Handling VM or VM template volumes](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#g906-appendix-06-handling-vm-or-vm-template-volumes)

- [Installing the `libguestfs-tools` package](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#installing-the-libguestfs-tools-package)
- [Locating and checking a VM or VM template's hard disk volume](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#locating-and-checking-a-vm-or-vm-templates-hard-disk-volume)
- [Relevant system paths](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#relevant-system-paths)
- [References](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#references)

### [**G907** - Appendix 07 ~ Resizing a root LVM volume](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#g907-appendix-07-resizing-a-root-lvm-volume)

- [Resizing the storage drive on Proxmox VE](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#resizing-the-storage-drive-on-proxmox-ve)
- [Extending the root LVM filesystem on a live VM](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#extending-the-root-lvm-filesystem-on-a-live-vm)
- [Final note](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#final-note)
- [References](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#references)

### [**G908** - Appendix 08 ~ K3s cluster with two or more server nodes](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#g908-appendix-08-k3s-cluster-with-two-or-more-server-nodes)

- [Add a new VM to act as the second server node](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#add-a-new-vm-to-act-as-the-second-server-node)
- [Adapt the Proxmox VE firewall setup](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#adapt-the-proxmox-ve-firewall-setup)
- [Setup of the FIRST K3s server node](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-first-k3s-server-node)
- [Setup of the SECOND K3s server node](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-second-k3s-server-node)
- [Regarding the K3s agent nodes](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#regarding-the-k3s-agent-nodes)

### [**G909** - Appendix 09 ~ Kubernetes object stuck in Terminating state](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#g909-appendix-09-kubernetes-object-stuck-in-terminating-state)

- [Scenario](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#scenario)
- [Solution](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#solution)
- [References](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#references)

### [**G910** - Appendix 10 ~ Setting up virtual network with Open vSwitch](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#g910-appendix-10-setting-up-virtual-network-with-open-vswitch)

- [Installation](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#installation)
- [Replacing the Linux bridge with the OVS one](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#replacing-the-linux-bridge-with-the-ovs-one)
- [Relevant system paths](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#relevant-system-paths)
- [References](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#references)

### [**G911** - Appendix 11 ~ Alternative Nextcloud web server setups](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#g911-appendix-11-alternative-nextcloud-web-server-setups)

- [Ideas for the Apache setup](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#ideas-for-the-apache-setup)
- [Nginx setup](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#nginx-setup)
- [Relevant system paths](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#relevant-system-paths)
- [References](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#references)

### [**G912** - Appendix 12 ~ Adapting MetalLB config to CR](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md#g912-appendix-12-adapting-metallb-config-to-cr)

- [References](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md#references)

### [**G913** - Appendix 13 ~ Checking the K8s API endpoints' status](G913%20-%20Appendix%2013%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md)

- [References](G913%20-%20Appendix%2013%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#references)

### [**G914** - Appendix 14 ~ Post-update manual maintenance tasks for Nextcloud](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md)

- [Concerns](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#concerns)
- [Procedure](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#procedure)
- [References](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#references)

### [**G915** - Appendix 15 ~ Updating MariaDB to a newer major version](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md)

- [Concerns](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#concerns)
- [Enabling the update procedure](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#enabling-the-update-procedure)
- [References](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#references)

### [**G916** - Appendix 16 ~ Updating PostgreSQL to a newer major version](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md)

- [Concerns](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#concerns)
- [Upgrade procedure (for Gitea's PostgreSQL instance)](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#upgrade-procedure-for-gitea-s-postgresql-instance)
- [Kustomize project only for updating PostgreSQL included in this guide series](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#kustomize-project-only-for-updating-postgresql-included-in-this-guide-series)
- [Relevant system paths](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#relevant-system-paths)
- [References](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#references)

## Navigation

[<< Previous (**README**)](README.md) | [Next (**G001** - Hardware setup) >>](G001%20-%20Hardware%20setup.md)
