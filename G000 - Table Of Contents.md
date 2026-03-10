# G000 - Table Of Contents

## [README](README.md)

- [A complete guide for building a virtualized Kubernetes homelab](README.md#a-complete-guide-for-building-a-virtualized-kubernetes-homelab)
- [Main concepts](README.md#main-concepts)
- [Intended audience](README.md#intended-audience)
- [Goal of this guide](README.md#goal-of-this-guide)
- [Software used](README.md#software-used)

## [LICENSE](LICENSE.md)

- [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License](LICENSE.md#creative-commons-attribution-noncommercial-sharealike-40-international-public-license)

## Main chapters

### [G001 - Hardware setup](G001%20-%20Hardware%20setup.md)

- [You just need a capable enough computer](G001%20-%20Hardware%20setup.md#you-just-need-a-capable-enough-computer)
- [The reference hardware setup](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup)
- [Why this hardware setup?](G001%20-%20Hardware%20setup.md#why-this-hardware-setup)
- [References](G001%20-%20Hardware%20setup.md#references)

### [G002 - Proxmox VE installation](G002%20-%20Proxmox%20VE%20installation.md)

- [A procedure to install Proxmox VE in limited consumer hardware](G002%20-%20Proxmox%20VE%20installation.md#a-procedure-to-install-proxmox-ve-in-limited-consumer-hardware)
- [System Requirements](G002%20-%20Proxmox%20VE%20installation.md#system-requirements)
- [Installation procedure](G002%20-%20Proxmox%20VE%20installation.md#installation-procedure)
- [After the installation](G002%20-%20Proxmox%20VE%20installation.md#after-the-installation)
- [Connecting remotely](G002%20-%20Proxmox%20VE%20installation.md#connecting-remotely)
- [References](G002%20-%20Proxmox%20VE%20installation.md#references)

### [G003 - Host configuration 01 ~ Apt sources, updates and extra tools](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md)

- [Proxmox VE 9.0 runs on Debian 13 "trixie"](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#proxmox-ve-90-runs-on-debian-13-trixie)
- [Editing the apt repository sources](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#editing-the-apt-repository-sources)
- [Update your system](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#update-your-system)
- [Installing useful extra tools](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#installing-useful-extra-tools)
- [Relevant system paths](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#relevant-system-paths)
- [References](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#references)

### [G004 - Host configuration 02 ~ UPS management with NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md)

- [Any server must be always connected to an UPS unit](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#any-server-must-be-always-connected-to-an-ups-unit)
- [Connecting your UPS with your PVE node using NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#connecting-your-ups-with-your-pve-node-using-nut)
- [Checking the NUT logs](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#checking-the-nut-logs)
- [Executing instant commands on your UPS unit](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#executing-instant-commands-on-your-ups-unit)
- [Other possibilities with NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#other-possibilities-with-nut)
- [Relevant system paths](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#relevant-system-paths)
- [References](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#references)

### [G005 - Host configuration 03 ~ LVM storage](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md)

- [Your Proxmox VE server's storage needs to be reorganized](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#your-proxmox-ve-servers-storage-needs-to-be-reorganized)
- [Initial filesystem configuration (PVE web console)](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-pve-web-console)
- [Initial filesystem configuration (shell as root)](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-shell-as-root)
- [Configuring the unused storage drives](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#configuring-the-unused-storage-drives)
- [LVM rearrangement in the main storage drive](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#lvm-rearrangement-in-the-main-storage-drive)
- [References](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#references)

### [G006 - Host configuration 04 ~ Removing Proxmox's subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md)

- [About the Proxmox subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#about-the-proxmox-subscription-warning)
- [Removing the subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#removing-the-subscription-warning)
- [Reverting the changes](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#reverting-the-changes)
- [Change executed in just one command line](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#change-executed-in-just-one-command-line)
- [Final note](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#final-note)
- [Relevant system paths](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#relevant-system-paths)
- [References](G006%20-%20Host%20configuration%2004%20~%20Removing%20Proxmox's%20subscription%20warning.md#references)

### [G007 - Host hardening 01 ~ TFA authentication](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md)

- [Enable Two Factor Authentication in your PVE system](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enable-two-factor-authentication-in-your-pve-system)
- [Enabling TFA for SSH access](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enabling-tfa-for-ssh-access)
- [Enforcing TFA TOTP for accessing the Proxmox VE web console](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-for-accessing-the-proxmox-ve-web-console)
- [Enforcing TFA TOTP as a default requirement for the `pam` realm](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-as-a-default-requirement-for-the-pam-realm)
- [Incompatibility of PVE web console login with TFA enforced local shell access](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#incompatibility-of-pve-web-console-login-with-tfa-enforced-local-shell-access)
- [Relevant system paths](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#relevant-system-paths)
- [References](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#references)

### [G008 - Host hardening 02 ~ Alternative administrator user](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md)

- [Avoid using the root user](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#avoid-using-the-root-user)
- [Understanding the Proxmox VE user management and the realms](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#understanding-the-proxmox-ve-user-management-and-the-realms)
- [Creating a new system administrator user for a Proxmox VE node](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#creating-a-new-system-administrator-user-for-a-proxmox-ve-node)
- [Relevant system paths](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#relevant-system-paths)
- [References](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#references)

### [G009 - Host hardening 03 ~ SSH key pairs and sshd service configuration](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md)

- [Harden your SSH connections with key pairs](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#harden-your-ssh-connections-with-key-pairs)
- [Generating SSH key pairs](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#generating-ssh-key-pairs)
- [Hardening the `sshd` service](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#hardening-the-sshd-service)
- [Relevant system paths](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#relevant-system-paths)
- [References](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#references)

### [G010 - Host hardening 04 ~ Enabling Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md)

- [Harden your setup against intrusions with Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#harden-your-setup-against-intrusions-with-fail2ban)
- [Installing Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#installing-fail2ban)
- [Configuring Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#configuring-fail2ban)
- [Considerations regarding Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#considerations-regarding-fail2ban)
- [Relevant system paths](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#relevant-system-paths)
- [References](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#references)

### [G011 - Host hardening 05 ~ Proxmox VE services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md)

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

### [G012 - Host hardening 06 ~ Network hardening with sysctl](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md)

- [Harden your PVE's networking with a `sysctl` configuration](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#harden-your-pves-networking-with-a-sysctl-configuration)
- [About `sysctl`](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#about-sysctl)
- [TCP/IP stack hardening with `sysctl`](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#tcpip-stack-hardening-with-sysctl)
- [Relevant system paths](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#relevant-system-paths)
- [References](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#references)

### [G013 - Host hardening 07 ~ Mitigating CPU vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md)

- [CPUs also have security vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#cpus-also-have-security-vulnerabilities)
- [Discovering your CPU's vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#discovering-your-cpus-vulnerabilities)
- [Your Proxmox VE system already has the correct microcode package applied](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#your-proxmox-ve-system-already-has-the-correct-microcode-package-applied)
- [Relevant system paths](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#relevant-system-paths)
- [References](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#references)

### [G014 - Host hardening 08 ~ Firewalling](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md)

- [[Enabling your PVE's firewall is a must](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#enabling-your-pves-firewall-is-a-must)]
- [Proxmox VE firewall uses iptables](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#proxmox-ve-firewall-uses-iptables)
- [Zones in the Proxmox VE firewall](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#zones-in-the-proxmox-ve-firewall)
- [Situation at this point](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#situation-at-this-point)
- [Enabling the firewall at the Datacenter tier](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#enabling-the-firewall-at-the-datacenter-tier)
- [Firewalling with ebtables](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewalling-with-ebtables)
- [Firewall fine tuning](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-fine-tuning)
- [Firewall logging](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-logging)
- [Connection tracking tool](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#connection-tracking-tool)
- [Relevant system paths](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#relevant-system-paths)
- [References](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#references)

### [G015 - Host optimization 01 ~ Adjustments through sysctl](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md)

- [Tune your Proxmox VE system's `sysctl` files to improve performance](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#tune-your-proxmox-ve-systems-sysctl-files-to-improve-performance)
- [First go the `sysctl` directory](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#first-go-the-sysctl-directory)
- [Network optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#network-optimizations)
- [Memory optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#memory-optimizations)
- [Kernel optimizations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#kernel-optimizations)
- [Reboot the system](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#reboot-the-system)
- [Final considerations](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#final-considerations)
- [Relevant system paths](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#relevant-system-paths)
- [References](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#references)

### [G016 - Host optimization 02 ~ Disabling the transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md)

- [Understanding the transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md#understanding-the-transparent-hugepages)
- [Status of the transparent hugepages in your host](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md#status-of-the-transparent-hugepages-in-your-host)
- [Disabling the transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md#disabling-the-transparent-hugepages)
- [Relevant system paths](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md#relevant-system-paths)
- [References](G016%20-%20Host%20optimization%2002%20~%20Disabling%20the%20transparent%20hugepages.md#references)

### [G017 - Virtual Networking ~ Network configuration](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md)

- [Preparing your virtual network for Kubernetes](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#preparing-your-virtual-network-for-kubernetes)
- [Current virtual network setup](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#current-virtual-network-setup)
- [Target network scenario](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#target-network-scenario)
- [Creating an isolated Linux bridge](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#creating-an-isolated-linux-bridge)
- [Bridges management](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#bridges-management)
- [Relevant system paths](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#relevant-system-paths)
- [References](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#references)

### [G018 - K3s cluster setup 01 ~ Requirements and arrangement](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md)

- [Gearing up for your K3s cluster](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#gearing-up-for-your-k3s-cluster)
- [Requirements for the K3s cluster and the services to deploy in it](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it)
- [Arrangement of VMs and services](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#arrangement-of-vms-and-services)
- [References](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#references)

### [G019 - K3s cluster setup 02 ~ Storage setup](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md)

- [Identifying your storage needs and current setup](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#identifying-your-storage-needs-and-current-setup)
- [Storage organization model](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#storage-organization-model)
- [Creating the logical volumes (LVs)](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#creating-the-logical-volumes-lvs)
- [Enabling the LVs for Proxmox VE](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#enabling-the-lvs-for-proxmox-ve)
- [Configuration file](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#configuration-file)
- [Relevant system paths](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#relevant-system-paths)
- [References](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#references)

### [G020 - K3s cluster setup 03 ~ Debian VM creation](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md)

- [You can start creating VMs in your Proxmox VE server](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#you-can-start-creating-vms-in-your-proxmox-ve-server)
- [Preparing the Debian ISO image](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#preparing-the-debian-iso-image)
- [Building a Debian virtual machine](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#building-a-debian-virtual-machine)
- [Note about the VM's `Boot Order` option](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#note-about-the-vms-boot-order-option)
- [Relevant system paths](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#relevant-system-paths)
- [References](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#references)

### [G021 - K3s cluster setup 04 ~ Debian VM configuration](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md)

- [You have to configure your new Debian VM](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#you-have-to-configure-your-new-debian-vm)
- [Suggestion about the IP organization within your LAN](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#suggestion-about-the-ip-organization-within-your-lan)
- [Adding the `apt` sources for _non-free_ packages](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#adding-the-apt-sources-for-non-free-packages)
- [Installing extra packages](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#installing-extra-packages)
- [The QEMU guest agent comes enabled in Debian](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#the-qemu-guest-agent-comes-enabled-in-debian)
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

### [G022 - K3s cluster setup 05 ~ Connecting the VM to the NUT server](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md)

- [Make your VMs aware of your UPS unit with NUT](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#make-your-vms-aware-of-your-ups-unit-with-nut)
- [Reconfiguring the NUT server on your Proxmox VE host](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#reconfiguring-the-nut-server-on-your-proxmox-ve-host)
- [Configuring the NUT client on your Debian VM](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#configuring-the-nut-client-on-your-debian-vm)
- [Checking the connection between the VM NUT client and the PVE node NUT server](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#checking-the-connection-between-the-vm-nut-client-and-the-pve-node-nut-server)
- [Testing a Forced ShutDown sequence (`FSD`) with NUT](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#testing-a-forced-shutdown-sequence-fsd-with-nut)
- [Relevant system paths](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#relevant-system-paths)
- [References](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#references)

### [G023 - K3s cluster setup 06 ~ Debian VM template and backup](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md)

- [Turn your Debian VM into a VM template](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#turn-your-debian-vm-into-a-vm-template)
- [Steps for transforming your Debian VM into a VM template](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#steps-for-transforming-your-debian-vm-into-a-vm-template)
- [VM template's backup](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#vm-templates-backup)
- [Other considerations regarding VM templates](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#other-considerations-regarding-vm-templates)
- [References](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#references)

### [G024 - K3s cluster setup 07 ~ K3s node VM template setup](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md)

- [You need a more specialized VM template for building K3s nodes](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#you-need-a-more-specialized-vm-template-for-building-k3s-nodes)
- [Reasons for a new VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#reasons-for-a-new-vm-template)
- [Creating a new VM based on the Debian VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#creating-a-new-vm-based-on-the-debian-vm-template)
- [Setting an static IP for the main network device (`net0`)](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-an-static-ip-for-the-main-network-device-net0)
- [Setting a proper hostname string](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-a-proper-hostname-string)
- [Disabling the swap volume](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#disabling-the-swap-volume)
- [Changing the VG's name](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#changing-the-vgs-name)
- [Setting up the second network card](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-the-second-network-card)
- [Setting up sysctl kernel parameters for K3s nodes](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-sysctl-kernel-parameters-for-k3s-nodes)
- [Turning the VM into a VM template](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#turning-the-vm-into-a-vm-template)
- [Relevant system paths](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#relevant-system-paths)
- [References](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#references)

### [G025 - K3s cluster setup 08 ~ K3s Kubernetes cluster setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md)

- [Build your virtualized K3s cluster](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#build-your-virtualized-k3s-cluster)
- [Criteria for the VMs' IPs and hostnames](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-the-vms-ips-and-hostnames)
- [Creation of VMs based on the K3s node VM template](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#creation-of-vms-based-on-the-k3s-node-vm-template)
- [Preparing the VMs for K3s](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#preparing-the-vms-for-k3s)
- [Firewall setup for the K3s cluster](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#firewall-setup-for-the-k3s-cluster)
- [Considerations before installing the K3s software](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#considerations-before-installing-the-k3s-software)
- [K3s Server node setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-server-node-setup)
- [K3s Agent nodes setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-agent-nodes-setup)
- [Enabling bash autocompletion for `kubectl`](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-bash-autocompletion-for-kubectl)
- [Regular K3s logs are journaled](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#regular-k3s-logs-are-journaled)
- [Rotating the `containerd.log` file](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#rotating-the-containerdlog-file)
- [K3s relevant paths](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-relevant-paths)
- [Starting up and shutting down the K3s cluster nodes](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#starting-up-and-shutting-down-the-k3s-cluster-nodes)
- [Relevant system paths](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#relevant-system-paths)
- [References](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#references)

### [G026 - K3s cluster setup 09 ~ Setting up a kubectl client for remote access](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md)

- [Never handle your Kubernetes cluster directly from the server nodes](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#never-handle-your-kubernetes-cluster-directly-from-server-nodes)
- [Description of the `kubectl` client system](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#description-of-the-kubectl-client-system)
- [Getting the right version of `kubectl`](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-right-version-of-kubectl)
- [Installing `kubectl` on your client system](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#installing-kubectl-on-your-client-system)
- [Getting the configuration for accessing the K3s cluster](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-configuration-for-accessing-the-k3s-cluster)
- [Opening the `6443` port in the K3s server node](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#opening-the-6443-port-in-the-k3s-server-node)
- [Enabling bash autocompletion for `kubectl`](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#enabling-bash-autocompletion-for-kubectl)
- [Validate Kubernetes configuration files with `kubeconform`](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#validate-kubernetes-configuration-files-with-kubeconform)
- [Relevant system paths](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#relevant-system-paths)
- [References](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#references)

### [G027 - K3s cluster setup 10 ~ Deploying the MetalLB load balancer](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md)

- [Considerations before deploying MetalLB](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#considerations-before-deploying-metallb)
- [Choosing the IP ranges for MetalLB](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#choosing-the-ip-ranges-for-metallb)
- [Deploying MetalLB on your K3s cluster](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#deploying-metallb-on-your-k3s-cluster)
- [MetalLB's Kustomize project attached to this guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#metallbs-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#relevant-system-paths)
- [References](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#references)

### [G028 - K3s cluster setup 11 ~ Deploying the metrics-server service](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md)

- [Deploy a metric-server service that you can fully configure](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deploy-a-metric-server-service-that-you-can-fully-configure)
- [Checking the metrics-server's manifest](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-servers-manifest)
- [Deployment of metrics-server](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deployment-of-metrics-server)
- [Checking the metrics-server service](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-server-service)
- [Metrics-server's Kustomize project attached to this guide](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#metrics-servers-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#relevant-system-paths)
- [References](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#references)

### [G029 - K3s cluster setup 12 ~ Setting up cert-manager and self-signed CA](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md)

- [Use cert-manager to handle certificates in your cluster](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#use-cert-manager-to-handle-certificates-in-your-cluster)
- [Deploying cert-manager](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#deploying-cert-manager)
- [Setting up self-signed CAs for your cluster](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#setting-up-self-signed-cas-for-your-cluster)
- [Deploying the self-signed CAs](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#deploying-the-self-signed-cas)
- [Checking your certificates with the cert-manager command line tool](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#checking-your-certificates-with-the-cert-manager-command-line-tool)
- [Cert-manager's Kustomize project attached to this guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#cert-managers-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#relevant-system-paths)
- [References](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md#references)

### [G030 - K3s cluster setup 14 ~ Enabling the Traefik dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md)

- [Traefik is the embedded ingress controller of K3s](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-is-the-embedded-ingress-controller-of-k3s)
- [Steps to enable access to the Traefik dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#steps-to-enable-access-to-the-traefik-dashboard)
- [Kustomize project's folder structure](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#kustomize-projects-folder-structure)
- [Traefik dashboard user](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-user)
- [Traefik dashboard Middleware](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-middleware)
- [Traefik dashboard IngressRoute](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-ingressroute)
- [Traefik dashboard Kustomize project](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-kustomize-project)
- [Deploying the Traefik dashboard Kustomize project](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#deploying-the-traefik-dashboard-kustomize-project)
- [Getting into the Traefik dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#getting-into-the-traefik-dashboard)
- [What to do if Traefik's dashboard has bad performance](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#what-to-do-if-traefiks-dashboard-has-bad-performance)
- [Traefik dashboard's Kustomize project attached to this guide](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboards-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#relevant-system-paths)
- [References](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md#references)

### [G031 - K3s cluster setup 13 ~ Deploying the Headlamp dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md)

- [Headlamp is an alternative to the Kubernetes Dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamp-is-an-alternative-to-the-kubernetes-dashboard)
- [Components required for deploying Headlamp](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#components-required-for-deploying-headlamp)
- [Kustomize project's folder structure](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#kustomize-projects-folder-structure)
- [Headlamp ServiceAccount](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamp-serviceaccount)
- [Headlamp ClusterRoleBinding](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamp-clusterrolebinding)
- [Headlamp TLS certificate](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamp-tls-certificate)
- [Headlamp IngressRoute](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamp-ingressroute)
- [Kustomize manifest for the Headlamp project](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#kustomize-manifest-for-the-headlamp-project)
- [Deploying Headlamp](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#deploying-headlamp)
- [Getting the administrator user's service account token](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#getting-the-administrator-users-service-account-token)
- [Testing Headlamp](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#testing-headlamp)
- [Headlamp's Kustomize project attached to this guide](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#headlamps-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#relevant-system-paths)
- [References](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#references)

### [G032 - Deploying services 01 ~ Considerations](G032%20-%20Deploying%20services%2001%20~%20Considerations.md)

- [Upcoming chapters are about deploying services in your K3s cluster](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#upcoming-chapters-are-about-deploying-services-in-your-k3s-cluster)
- [Be watchful of your system's resources usage](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#be-watchful-of-your-systems-resources-usage)
- [Do not fill your cluster up to the brim](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#do-not-fill-your-cluster-up-to-the-brim)

### [G033 - Deploying services 02 ~ Ghost - Part 1 - Outlining setup and arranging storage](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md)

- [Beginning with Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#beginning-with-ghost)
- [Outlining Ghost's setup](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-ghosts-setup)
- [Choosing the K3s agent node for running Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#choosing-the-k3s-agent-node-for-running-ghost)
- [Setting up new storage drives in the K3s agent node](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agent-node)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [G033 - Deploying services 02 ~ Ghost - Part 2 - Valkey cache server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md)

- [You can use Valkey instead of Redis as caching server for Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#you-can-use-valkey-instead-of-redis-as-caching-server-for-ghost)
- [Kustomize project folders for Ghost and Valkey](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#kustomize-project-folders-for-ghost-and-valkey)
- [Valkey configuration file](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-configuration-file)
- [Valkey secrets](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-secrets)
- [Valkey persistent storage claim](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-persistent-storage-claim)
- [Valkey StatefulSet](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-statefulset)
- [Valkey Service](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service)
- [Valkey Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-kustomize-project)
- [Do not deploy this Valkey project on its own](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#do-not-deploy-this-valkey-project-on-its-own)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#references)

### [G033 - Deploying services 02 ~ Ghost - Part 3 - MariaDB database server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md)

- [You can use MariaDB instead of MySQL as database server for Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#you-can-use-mariadb-instead-of-mysql-as-database-server-for-ghost)
- [MariaDB Kustomize subproject's folders](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-subprojects-folders)
- [MariaDB configuration files](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-configuration-files)
- [MariaDB passwords](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-passwords)
- [MariaDB persistent storage claim](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-persistent-storage-claim)
- [MariaDB StatefulSet](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset)
- [MariaDB Service](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-service)
- [MariaDB Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-project)
- [Do not deploy this MariaDB project on its own](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#do-not-deploy-this-mariadb-project-on-its-own)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md#references)

### [G033 - Deploying services 02 ~ Ghost - Part 4 - Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md)

- [Deploy the Ghost server just like another component](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#deploy-the-ghost-server-just-like-another-component)
- [Considerations about the Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#considerations-about-the-ghost-server)
- [Ghost server Kustomize subproject's folders](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-kustomize-subprojects-folders)
- [Ghost server configuration file](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-configuration-file)
- [Ghost server environment variables](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-environment-variables)
- [Ghost server persistent storage claim](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-persistent-storage-claim)
- [Ghost server StatefulSet](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-statefulset)
- [Ghost server Service](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-service)
- [Ghost server Kustomize project](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-kustomize-project)
- [Do not deploy this Ghost server project on its own](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#do-not-deploy-this-ghost-server-project-on-its-own)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#references)

### [G033 - Deploying services 02 ~ Ghost - Part 5 - Complete Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md)

- [Putting together the whole Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#putting-together-the-whole-ghost-platform)
- [Create a folder for the pending Ghost platform resources](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#create-a-folder-for-the-pending-ghost-platform-resources)
- [Ghost platform's persistent volumes](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#ghost-platforms-persistent-volumes)
- [Ghost platform's TLS certificate](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#ghost-platforms-tls-certificate)
- [Traefik IngressRoute for enabling HTTPS access to the Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#traefik-ingressroute-for-enabling-https-access-to-the-ghost-platform)
- [Ghost Namespace](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#ghost-namespace)
- [Main Kustomize project for the Ghost platform](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#main-kustomize-project-for-the-ghost-platform)
- [Deploying the main Kustomize project in the cluster](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#deploying-the-main-kustomize-project-in-the-cluster)
- [Start using Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#start-using-ghost)
- [Security considerations in Ghost](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#security-considerations-in-ghost)
- [Ghost platform's Kustomize project attached to this guide](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#ghost-platforms-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#relevant-system-paths)
- [References](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md#references)

### [G034 - Deploying services 03 ~ Forgejo - Part 1 - Outlining setup and arranging storage](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md)

- [Deploy Forgejo like you deployed Ghost](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#deploy-forgejo-like-you-deployed-ghost)
- [Outlining Forgejo's setup](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-forgejos-setup)
- [Setting up new storage drives in the K3s agent](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agent)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [G034 - Deploying services 03 ~ Forgejo - Part 2 - Valkey cache server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md)

- [Valkey can be the cache server of Forgejo](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-can-be-the-cache-server-of-forgejo)
- [Kustomize project folders for Forgejo and Valkey](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#kustomize-project-folders-for-forgejo-and-valkey)
- [Valkey configuration file](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-configuration-file)
- [Valkey secrets](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-secrets)
- [Valkey persistent storage claim](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-persistent-storage-claim)
- [Valkey StatefulSet](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-statefulset)
- [Valkey Service](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service)
- [Valkey Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-kustomize-project)
- [Do not deploy this Valkey project on its own](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#do-not-deploy-this-valkey-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#references)

### [G034 - Deploying services 03 ~ Forgejo - Part 3 - PostgreSQL database server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md)

- [Forgejo can use PostgreSQL as database](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#forgejo-can-use-postgresql-as-database)
- [PostgreSQL Kustomize project's folders](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-projects-folders)
- [PostgreSQL configuration files](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-configuration-files)
- [PostgreSQL passwords](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-passwords)
- [PostgreSQL persistent storage claim](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-persistent-storage-claim)
- [PostgreSQL StatefulSet](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-statefulset)
- [PostgreSQL Service](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-service)
- [PostgreSQL Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-project)
- [Do not deploy this PostgreSQL project on its own](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#do-not-deploy-this-postgresql-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#references)

### [G034 - Deploying services 03 ~ Forgejo - Part 4 - Forgejo server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md)

- [Considerations about the Forgejo server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#considerations-about-the-forgejo-server)
- [Forgejo server Kustomize project's folders](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-kustomize-projects-folders)
- [Forgejo server configuration with environment variables](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-configuration-with-environment-variables)
- [Forgejo server persistent storage claims](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-persistent-storage-claims)
- [Forgejo server StatefulSet](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-statefulset)
- [Forgejo server Service](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-service)
- [Forgejo Kustomize project](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-kustomize-project)
- [Do not deploy this Forgejo server project on its own](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#do-not-deploy-this-forgejo-server-project-on-its-own)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#references)

### [G034 - Deploying services 03 ~ Forgejo - Part 5 - Complete Forgejo platform](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md)

- [Finishing up the complete Forgejo platform](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#finishing-up-the-complete-forgejo-platform)
- [Create a folder for the missing Forgejo platform resources](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#create-a-folder-for-the-missing-forgejo-platform-resources)
- [Forgejo platform's persistent volumes](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#forgejo-platforms-persistent-volumes)
- [Forgejo platform's TLS certificate](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#forgejo-platforms-tls-certificate)
- [Traefik IngressRoute for enabling HTTPS access to the Forgejo platform](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#traefik-ingressroute-for-enabling-https-access-to-the-forgejo-platform)
- [Forgejo Namespace resource](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#forgejo-namespace-resource)
- [Main Kustomize project for the Forgejo platform](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#main-kustomize-project-for-the-forgejo-platform)
- [Deploying the main Kustomize project in the cluster](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform#deploying-the-main-kustomize-project-in-the-cluster)
- [Finishing Forgejo installation](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#finishing-forgejo-installation)
- [Security considerations in Forgejo](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#security-considerations-in-forgejo)
- [Forgejo platform's Kustomize project attached to this guide](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#forgejo-platforms-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#relevant-system-paths)
- [References](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 1 - Outlining setup and arranging storage](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md)

- [Improve your K3s cluster's observability with a Prometheus-based monitoring stack](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#improve-your-k3s-clusters-observability-with-a-prometheus-based-monitoring-stack)
- [Outlining your monitoring stack setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-your-monitoring-stack-setup)
- [Setting up new storage drives in the K3s agents](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agents)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 2 - Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md)

- [Start by deploying the Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#start-by-deploying-the-kube-state-metrics-service)
- [Kustomize project folders for your monitoring stack and Kube State Metrics](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kustomize-project-folders-for-your-monitoring-stack-and-kube-state-metrics)
- [Kube State Metrics ServiceAccount](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-serviceaccount)
- [Kube State Metrics ClusterRole](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrole)
- [Kube State Metrics ClusterRoleBinding](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrolebinding)
- [Kube State Metrics Deployment](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-deployment)
- [Kube State Metrics Service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-service)
- [Kube State Metrics Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-kustomize-project)
- [Do not deploy this Kube State Metrics project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#do-not-deploy-this-kube-state-metrics-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 3 - Prometheus Node Exporter service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md)

- [The Prometheus Node Exporter is simpler to deploy](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#the-prometheus-node-exporter-is-simpler-to-deploy)
- [Kustomize project folders for Prometheus Node Exporter](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#kustomize-project-folders-for-prometheus-node-exporter)
- [Prometheus Node Exporter DaemonSet](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-daemonset)
- [Prometheus Node Exporter Service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-service)
- [Prometheus Node Exporter Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-kustomize-project)
- [Do not deploy this Prometheus Node Exporter project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#do-not-deploy-this-prometheus-node-exporter-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 4 - Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md)

- [Prometheus is the core of your monitoring stack](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-is-the-core-of-your-monitoring-stack)
- [Kustomize project folders for Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#kustomize-project-folders-for-prometheus-server)
- [Prometheus configuration files](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-configuration-files)
- [Prometheus server persistent storage claim](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-persistent-storage-claim)
- [Prometheus server ServiceAccount](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-serviceaccount)
- [Prometheus server ClusterRole](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-clusterrole)
- [Prometheus server ClusterRoleBinding](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-clusterrolebinding)
- [Prometheus server StatefulSet](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-statefulset)
- [Prometheus server Service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-service)
- [Prometheus server's Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-servers-kustomize-project)
- [Do not deploy this Prometheus server project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#do-not-deploy-this-prometheus-server-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 5 - Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md)

- [Grafana is your monitoring dashboard](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#grafana-is-your-monitoring-dashboard)
- [Kustomize project folders for Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#kustomize-project-folders-for-grafana)
- [Grafana server persistent storage claim](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#grafana-server-persistent-storage-claim)
- [Grafana server StatefulSet](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#grafana-server-statefulset)
- [Grafana server Service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#grafana-server-service)
- [Grafana server Kustomize project](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#grafana-server-kustomize-project)
- [Do not deploy this Grafana server project on its own](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#do-not-deploy-this-grafana-server-project-on-its-own)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana%20server.md#references)

### [G035 - Deploying services 04 ~ Monitoring stack - Part 6 - Complete monitoring stack setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md)

- [Completing your monitoring stack](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#completing-your-monitoring-stack)
- [Create a folder to hold the missing monitoring stack components](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#create-a-folder-to-hold-the-missing-monitoring-stack-components)
- [Monitoring stack persistent volumes](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stack-persistent-volumes)
- [Monitoring stack TLS certificate](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stack-tls-certificate)
- [Traefik IngressRoute for enabling HTTPS access to the monitoring stack's Prometheus and Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#traefik-ingressroute-for-enabling-https-access-to-the-monitoring-stacks-prometheus-and-grafana)
- [Monitoring stack Namespace](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stack-namespace)
- [Main Kustomize project for the monitoring stack](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#main-kustomize-project-for-the-monitoring-stack)
- [Deploying the main Kustomize project in the cluster](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#deploying-the-main-kustomize-project-in-the-cluster)
- [Checking on Prometheus](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#checking-on-prometheus)
- [Finishing Grafana's setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#finishing-grafanas-setup)
- [Monitoring stack Kustomize project attached to this guide](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stack-kustomize-project-attached-to-this-guide)
- [Relevant system paths](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#relevant-system-paths)
- [References](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#references)

### [G036 - Host and K3s cluster ~ Monitoring and diagnosis](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md)

- [Monitor your homelab setup with its own tools](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#monitor-your-homelab-setup-with-its-own-tools)
- [Monitoring resources usage](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#monitoring-resources-usage)
- [Checking the logs](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#checking-the-logs)
- [Shell access into your containers](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers)
- [Metrics from the monitoring stack](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#metrics-from-the-monitoring-stack)
- [References](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#references)

### [G037 - Backups 01 ~ Considerations](G037%20-%20Backups%2001%20~%20Considerations.md)

- [What to backup. Identifying your data concerns](G037%20-%20Backups%2001%20~%20Considerations.md#what-to-backup-identifying-your-data-concerns)
- [How to backup. Backup tools](G037%20-%20Backups%2001%20~%20Considerations.md#how-to-backup-backup-tools)
- [Where to store the backups. Backup storage](G037%20-%20Backups%2001%20~%20Considerations.md#where-to-store-the-backups-backup-storage)
- [When to do the backups. Backup scheduling](G037%20-%20Backups%2001%20~%20Considerations.md#when-to-do-the-backups-backup-scheduling)
- [References](G037%20-%20Backups%2001%20~%20Considerations.md#references)

### [G038 - Backups 02 ~ Host platform backup with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md)

- [Host backups are filesystem images](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#host-backups-are-filesystem-images)
- [What gets inside a host backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#what-gets-inside-a-host-backup)
- [Why doing this backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#why-doing-this-backup)
- [How it affects the host platform](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-it-affects-the-host-platform)
- [When to do the backup](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#when-to-do-the-backup)
- [How to backup with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-backup-with-clonezilla)
- [How to restore with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-restore-with-clonezilla)
- [Final considerations](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#final-considerations)
- [References](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#references)

### [G039 - Backups 03 ~ Proxmox VE backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md)

- [Backup your VMs in Proxmox VE](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#backup-your-vms-in-proxmox-ve)
- [What gets covered with the backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#what-gets-covered-with-the-backup-job)
- [Why scheduling a backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#why-scheduling-a-backup-job)
- [How it affects the K3s Kubernetes cluster](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#how-it-affects-the-k3s-kubernetes-cluster)
- [When to do the backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#when-to-do-the-backup-job)
- [Scheduling the backup job in Proxmox VE](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#scheduling-the-backup-job-in-proxmox-ve)
- [Restoring a backup in Proxmox VE](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#restoring-a-backup-in-proxmox-ve)
- [Location of the backup files in the Proxmox VE system](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#location-of-the-backup-files-in-the-proxmox-ve-system)
- [Relevant system paths](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#relevant-system-paths)
- [References](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#references)

### [G040 - Backups 04 ~ UrBackup 01 - Server setup](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md)

- [Use UrBackup to preserve specific directories](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#use-urbackup-to-preserve-specific-directories)
- [Setting up a new VM for the UrBackup server](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#setting-up-a-new-vm-for-the-urbackup-server)
- [Deploying UrBackup](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#deploying-urbackup)
- [Firewall configuration on Proxmox VE](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#firewall-configuration-on-proxmox-ve)
- [Adjusting the UrBackup server configuration](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#adjusting-the-urbackup-server-configuration)
- [UrBackup server log file](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#urbackup-server-log-file)
- [About backing up the UrBackup server VM](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#about-backing-up-the-urbackup-server-vm)
- [Relevant system paths](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#relevant-system-paths)
- [References](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#references)

### [G041 - Backups 05 ~ UrBackup 02 - Clients setup and configuring file backups](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md)

- [Install UrBackup clients in your K3s node VMs](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#install-urbackup-clients-in-your-k3s-node-vms)
- [Deploying the UrBackup client program](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#deploying-the-urbackup-client-program)
- [UrBackup client log file](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-log-file)
- [UrBackup client uninstaller](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-uninstaller)
- [Configuring file backup paths on a client](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#configuring-file-backup-paths-on-a-client)
- [Backups on the UrBackup server](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#backups-on-the-urbackup-server)
- [Restoration from file backups](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#restoration-from-file-backups)
- [Relevant system paths](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#relevant-system-paths)
- [References](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#references)

### [G042 - System update 01 ~ Considerations](G042%20-%20System%20update%2001%20~%20Considerations.md)

- [Updating this guide's homelab setup is not a straightforward task](G042%20-%20System%20update%2001%20~%20Considerations.md#updating-this-guides-homelab-setup-is-not-a-straightforward-task)
- [What to update. Identifying your system's software layers](G042%20-%20System%20update%2001%20~%20Considerations.md#what-to-update-identifying-your-systems-software-layers)
- [How to update. Update procedures](G042%20-%20System%20update%2001%20~%20Considerations.md#how-to-update-update-procedures)
- [When to apply the updates](G042%20-%20System%20update%2001%20~%20Considerations.md#when-to-apply-the-updates)
- [Update order](G042%20-%20System%20update%2001%20~%20Considerations.md#update-order)

### [G043 - System update 02 ~ Updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md)

- [Start by updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#start-by-updating-proxmox-ve)
- [Examining your Proxmox VE system](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#examining-your-proxmox-ve-system)
- [Updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#updating-proxmox-ve)
- [References](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#references)

### [G044 - System update 03 ~ Updating VMs and UrBackup](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md)

- [Updating the VMs means updating their OS](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-the-vms-means-updating-their-os)
- [Examining your VMs](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#examining-your-vms)
- [Updating Debian on your VMs](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-debian-on-your-vms)
- [Updating the UrBackup software](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-the-urbackup-software)
- [References](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#references)

### [G045 - System update 04 ~ Updating K3s and deployed apps](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md)

- [Use `kubectl` to help you when updating your K3s cluster](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#use-kubectl-to-help-you-when-updating-your-k3s-cluster)
- [Examining your K3s Kubernetes cluster](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#examining-your-k3s-kubernetes-cluster)
- [Updating apps and K3s](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#updating-apps-and-k3s)
- [References](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#references)

### [G046 - Cleaning up your homelab system](G046%20-%20Cleaning%20up%20your%20homelab%20system.md)

- [Save storage space by cleaning your system up](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#save-storage-space-by-cleaning-your-system-up)
- [Checking your storage status](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#checking-your-storage-status)
- [Cleaning procedures](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#cleaning-procedures)
- [Reminder about the `apt` updates](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#reminder-about-the-apt-updates)
- [Relevant system paths](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#relevant-system-paths)
- [References](G046%20-%20Cleaning%20up%20your%20homelab%20system.md#references)

### [G047 - Understanding your homelab setup through diagrams](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md)

- [This guide's homelab setup is complex](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md#this-guides-homelab-setup-is-complex)
- [Hardware](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md#hardware)
- [Virtual environment](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md#virtual-environment)
- [Kubernetes cluster](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md#kubernetes-cluster)
- [References](G047%20-%20Understanding%20your%20homelab%20setup%20through%20diagrams.md#references)

## Appendix chapters

### [G901 - Appendix 01 ~ Connecting through SSH with PuTTY](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md)

- [These instructions could be valid for other remote terminal clients](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#these-instructions-could-be-valid-for-other-remote-terminal-clients)
- [Generating a `.ppk` file from a private key](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#generating-a-ppk-file-from-a-private-key)
- [Configuring the connection to the PVE node](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#configuring-the-connection-to-the-pve-node)
- [References](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#references)

### [G902 - Appendix 02 ~ Vim vimrc configuration](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md)

- [The default Vim configuration can feel insufficient](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#the-default-vim-configuration-can-feel-insufficient)
- [Practical Vim configuration](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#practical-vim-configuration)
- [References](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#references)

### [G903 - Appendix 03 ~ Customization of the motd file](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md)

- [What is the motd](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md#what-is-the-motd)
- [How to modify the motd](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md#how-to-modify-the-motd)
- [References](G903%20-%20Appendix%2003%20~%20Customization%20of%20the%20motd%20file.md#references)

### [G904 - Appendix 04 ~ Handling VM or VM template volumes](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md)

- [VM hard disks are disk images](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#vm-hard-disks-are-disk-images)
- [Installing the `libguestfs-tools` package](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#installing-the-libguestfs-tools-package)
- [Locating and checking a VM or VM template's hard disk volume](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#locating-and-checking-a-vm-or-vm-templates-hard-disk-volume)
- [Relevant system paths](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#relevant-system-paths)
- [References](G904%20-%20Appendix%2004%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#references)

### [G905 - Appendix 05 ~ Resizing a root LVM volume](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md)

- [Resize a VM's root LVM volume if you find it too small](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md#resize-a-vms-root-lvm-volume-if-you-find-it-too-small)
- [Resizing the storage drive on Proxmox VE](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md#resizing-the-storage-drive-on-proxmox-ve)
- [Extending the root LVM filesystem on a live VM](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md#extending-the-root-lvm-filesystem-on-a-live-vm)
- [Final note](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md#final-note)
- [References](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md#references)

### [G906 - Appendix 06 ~ K3s cluster with two or more server nodes](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md)

- [Real Kubernetes clusters have more than one server node](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#real-kubernetes-clusters-have-more-than-one-server-node)
- [Add a new VM to act as the second server node](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#add-a-new-vm-to-act-as-the-second-server-node)
- [Adapt the Proxmox VE firewall setup](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#adapt-the-proxmox-ve-firewall-setup)
- [Setup of the FIRST K3s server node](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-first-k3s-server-node)
- [Setup of the SECOND K3s server node](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-second-k3s-server-node)
- [Regarding the K3s agent nodes](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#regarding-the-k3s-agent-nodes)
- [References](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#references)

### [G907 - Appendix 07 ~ Kubernetes object stuck in Terminating state](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md)

- [Kubernetes objects can get stuck as `Terminating` when undeployed](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#kubernetes-objects-can-get-stuck-as-terminating-when-undeployed)
- [Scenario](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#scenario)
- [Solution](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#solution)
- [References](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#references)

### [G908 - Appendix 08 ~ Checking the K8s API endpoints' status](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md)

- [Review the status of your K3s cluster's Kubernetes API endpoints with `kubectl`](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#review-the-status-of-your-k3s-clusters-kubernetes-api-endpoints-with-kubectl)
- [Check out your K8s cluster API endpoints readiness](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#check-out-your-k8s-cluster-api-endpoints-readiness)
- [See if your K8s cluster's API endpoints are healthy](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#see-if-your-k8s-clusters-api-endpoints-are-healthy)
- [Verify if the K8s cluster's API endpoints are live](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#verify-if-the-k8s-clusters-api-endpoints-are-live)
- [Details to notice from the `kubectl` commands](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#details-to-notice-from-the-kubectl-commands)
- [Deprecated component status command](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#deprecated-component-status-command)
- [References](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#references)

### [G909 - Appendix 09 ~ Updating MariaDB to a newer major version](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md)

- [Upgrading a containerized MariaDB to a new major version is easy](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#upgrading-a-containerized-mariadb-to-a-new-major-version-is-easy)
- [Concerns](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#concerns)
- [Enabling the update procedure](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#enabling-the-update-procedure)
- [References](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#references)

### [G910 - Appendix 10 ~ Updating PostgreSQL to a newer major version](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md)

- [Upgrading a containerized PostgreSQL server is not straightforward](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#upgrading-a-containerized-postgresql-server-is-not-straightforward)
- [Concerns](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#concerns)
- [Upgrade procedure (for Forgejo's PostgreSQL instance)](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#upgrade-procedure-for-forgejos-postgresql-instance)
- [Kustomize project only for updating PostgreSQL included in this guide](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#kustomize-project-only-for-updating-postgresql-included-in-this-guide)
- [Relevant system paths](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#relevant-system-paths)
- [References](G910%20-%20Appendix%2010%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#references)

## Navigation

[<< Previous (**README**)](README.md) | [Next (**G001 - Hardware setup**) >>](G001%20-%20Hardware%20setup.md)
