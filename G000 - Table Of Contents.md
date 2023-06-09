# **G000** - Table Of Contents

## [**README**](README.md#small-homelab-k8s-cluster-on-proxmox-ve)

- [_Description of contents_](README.md#description-of-contents)
- [_Intended audience_](README.md#intended-audience)
- [_Goals_](README.md#goals)

## [**LICENSE**](LICENSE.md)

- [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License](LICENSE.md#creative-commons-attribution-noncommercial-sharealike-40-international-public-license)

## Guides

### [**G001** - Hardware setup](G001%20-%20Hardware%20setup.md#g001-hardware-setup)

- [_The reference hardware setup_](G001%20-%20Hardware%20setup.md#the-reference-hardware-setup)
- [_References_](G001%20-%20Hardware%20setup.md#references)

### [**G002** - Proxmox VE installation](G002%20-%20Proxmox%20VE%20installation.md#g002-proxmox-ve-installation)

- [_System Requirements_](G002%20-%20Proxmox%20VE%20installation.md#system-requirements)
- [_Installation procedure_](G002%20-%20Proxmox%20VE%20installation.md#installation-procedure)
- [_After the installation_](G002%20-%20Proxmox%20VE%20installation.md#after-the-installation)
- [_Connecting remotely_](G002%20-%20Proxmox%20VE%20installation.md#connecting-remotely)
- [_References_](G002%20-%20Proxmox%20VE%20installation.md#references)

### [**G003** - Host configuration 01 ~ Apt sources, updates and extra tools](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#g003-host-configuration-01-apt-sources-updates-and-extra-tools)

- [_Remember, Proxmox VE 7.0 runs on Debian 11_ bullseye](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#remember-proxmox-ve-70-runs-on-debian-11-bullseye)
- [_Editing the apt repository sources_](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#editing-the-apt-repository-sources)
- [_Update your system_](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#update-your-system)
- [_Installing useful extra tools_](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#installing-useful-extra-tools)
- [_Relevant system paths_](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#relevant-system-paths)
- [_References_](G003%20-%20Host%20configuration%2001%20~%20Apt%20sources,%20updates%20and%20extra%20tools.md#references)

### [**G004** - Host configuration 02 ~ UPS management with NUT](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#g004-host-configuration-02-ups-management-with-nut)

- [_Connecting your UPS with your pve node using NUT_](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#connecting-your-ups-with-your-pve-node-using-nut)
- [_Executing instant commands on the UPS unit_](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#executing-instant-commands-on-the-ups-unit)
- [_Other possibilities with NUT_](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#other-possibilities-with-nut)
- [_Relevant system paths_](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#relevant-system-paths)
- [_References_](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md#references)

### [**G005** - Host configuration 03 ~ LVM storage](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#g005-host-configuration-03-lvm-storage)

- [_Initial filesystem configuration (**web console**)_](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-web-console)
- [_Initial filesystem configuration (**shell as root**)_](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#initial-filesystem-configuration-shell-as-root)
- [_Configuring the unused storage drives_](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#configuring-the-unused-storage-drives)
- [_LVM rearrangement in the main storage drive_](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#lvm-rearrangement-in-the-main-storage-drive)
- [_References_](G005%20-%20Host%20configuration%2003%20~%20LVM%20storage.md#references)

### [**G006** - Host configuration 04 ~ Removing subscription warning](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#g006-host-configuration-04-removing-subscription-warning)

- [_Reverting the changes_](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#reverting-the-changes)
- [_Change executed in just one command line_](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#change-executed-in-just-one-command-line)
- [_Final note_](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#final-note)
- [_Relevant system paths_](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#relevant-system-paths)
- [_References_](G006%20-%20Host%20configuration%2004%20~%20Removing%20subscription%20warning.md#references)

### [**G007** - Host hardening 01 ~ TFA authentication](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#g007-host-hardening-01-tfa-authentication)

- [_Enabling TFA for SSH access_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enabling-tfa-for-ssh-access)
- [_Enforcing TFA TOTP for accessing the Proxmox VE web console_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-for-accessing-the-proxmox-ve-web-console)
- [_Enforcing TFA TOTP as a default requirement for `pam` realm_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#enforcing-tfa-totp-as-a-default-requirement-for-pam-realm)
- [_Incompatibility of PVE web console login with TFA enforced local shell access_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#incompatibility-of-pve-web-console-login-with-tfa-enforced-local-shell-access)
- [_Relevant system paths_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#relevant-system-paths)
- [_References_](G007%20-%20Host%20hardening%2001%20~%20TFA%20authentication.md#references)

### [**G008** - Host hardening 02 ~ Alternative administrator user](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#g008-host-hardening-02-alternative-administrator-user)

- [_Understanding the Proxmox VE user management and the realms_](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#understanding-the-proxmox-ve-user-management-and-the-realms)
- [_Creating a new system administrator user for a Proxmox VE node_](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#creating-a-new-system-administrator-user-for-a-proxmox-ve-node)
- [_Relevant system paths_](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#relevant-system-paths)
- [_References_](G008%20-%20Host%20hardening%2002%20~%20Alternative%20administrator%20user.md#references)

### [**G009** - Host hardening 03 ~ SSH key pairs and sshd service configuration](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#g009-host-hardening-03-ssh-key-pairs-and-sshd-service-configuration)

- [_SSH key pairs_](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#ssh-key-pairs)
- [_Hardening the `sshd` service_](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#hardening-the-sshd-service)
- [_Relevant system paths_](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#relevant-system-paths)
- [_References_](G009%20-%20Host%20hardening%2003%20~%20SSH%20key%20pairs%20and%20sshd%20service%20configuration.md#references)

### [**G010** - Host hardening 04 ~ Enabling Fail2Ban](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#g010-host-hardening-04-enabling-fail2ban)

- [_Installing Fail2ban_](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#installing-fail2ban)
- [_Configuring Fail2ban_](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#configuring-fail2ban)
- [_Considerations regarding Fail2ban_](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#considerations-regarding-fail2ban)
- [_Relevant system paths_](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#relevant-system-paths)
- [_References_](G010%20-%20Host%20hardening%2004%20~%20Enabling%20Fail2Ban.md#references)

### [**G011** - Host hardening 05 ~ Proxmox VE services](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#g011-host-hardening-05-proxmox-ve-services)

- [_Checking currently running services_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#checking-currently-running-services)
- [_Configuring the `pveproxy` service_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#configuring-the-pveproxy-service)
- [_Disabling RPC services_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-rpc-services)
- [_Disabling `zfs` and `ceph`_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-zfs-and-ceph)
- [_Disabling the SPICE proxy_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-the-spice-proxy)
- [_Disabling cluster and high availability related services_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#disabling-cluster-and-high-availability-related-services)
- [_Considerations_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#considerations)
- [_Relevant system paths_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#relevant-system-paths)
- [_References_](G011%20-%20Host%20hardening%2005%20~%20Proxmox%20VE%20services.md#references)

### [**G012** - Host hardening 06 ~ Network hardening with sysctl](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#g012-host-hardening-06-network-hardening-with-sysctl)

- [_About `sysctl`_](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#about-sysctl)
- [_TCP/IP stack hardening with `sysctl`_](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#tcpip-stack-hardening-with-sysctl)
- [_Relevant system paths_](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#relevant-system-paths)
- [_References_](G012%20-%20Host%20hardening%2006%20~%20Network%20hardening%20with%20sysctl.md#references)

### [**G013** - Host hardening 07 ~ Mitigating CPU vulnerabilities](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#g013-host-hardening-07-mitigating-cpu-vulnerabilities)

- [_Checking out your CPU's vulnerabilities_](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#checking-out-your-cpus-vulnerabilities)
- [_Applying the correct microcode package_](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#applying-the-correct-microcode-package)
- [_Relevant system paths_](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#relevant-system-paths)
- [_References_](G013%20-%20Host%20hardening%2007%20~%20Mitigating%20CPU%20vulnerabilities.md#references)

### [**G014** - Host hardening 08 ~ Firewalling](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#g014-host-hardening-08-firewalling)

- [_Proxmox VE firewall uses `iptables`_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#proxmox-ve-firewall-uses-iptables)
- [_Zones in the Proxmox VE firewall_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#zones-in-the-proxmox-ve-firewall)
- [_Situation at this point_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#situation-at-this-point)
- [_Enabling the firewall at the `Datacenter` tier_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#enabling-the-firewall-at-the-datacenter-tier)
- [_Firewalling with `ebtables`_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewalling-with-ebtables)
- [_Firewall fine tuning_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-fine-tuning)
- [_Firewall logging_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#firewall-logging)
- [_Connection tracking tool_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#connection-tracking-tool)
- [_Relevant system paths_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#relevant-system-paths)
- [_References_](G014%20-%20Host%20hardening%2008%20~%20Firewalling.md#references)

### [**G015** - Host optimization 01 ~ Adjustments through sysctl](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#g015-host-optimization-01-adjustments-through-sysctl)

- [_Network optimizations_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#network-optimizations)
- [_Memory optimizations_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#memory-optimizations)
- [_Kernel optimizations_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#kernel-optimizations)
- [_Reboot the system_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#reboot-the-system)
- [_Final considerations_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#final-considerations)
- [_Relevant system paths_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#relevant-system-paths)
- [_References_](G015%20-%20Host%20optimization%2001%20~%20Adjustments%20through%20sysctl.md#references)

### [**G016** - Host optimization 02 ~ Disabling transparent hugepages](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#g016-host-optimization-02-disabling-transparent-hugepages)

- [_Status of transparent hugepages in your host_](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#status-of-transparent-hugepages-in-your-host)
- [_Disabling the transparent hugepages_](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#disabling-the-transparent-hugepages)
- [_Relevant system paths_](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#relevant-system-paths)
- [_References_](G016%20-%20Host%20optimization%2002%20~%20Disabling%20transparent%20hugepages.md#references)

### [**G017** - Virtual Networking ~ Network configuration](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#g017-virtual-networking-network-configuration)

- [_Current virtual network setup_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#current-virtual-network-setup)
- [_Target network scenario_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#target-network-scenario)
- [_Creating an isolated Linux bridge_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#creating-an-isolated-linux-bridge)
- [_Bridges management_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#bridges-management)
- [_Relevant system paths_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#relevant-system-paths)
- [_References_](G017%20-%20Virtual%20Networking%20~%20Network%20configuration.md#references)

### [**G018** - K3s cluster setup 01 ~ Requirements and arrangement](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#g018-k3s-cluster-setup-01-requirements-and-arrangement)

- [_Requirements for the K3s cluster and the services to deploy in it_](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it)
- [_Arrangement of VMs and services_](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#arrangement-of-vms-and-services)
- [_References_](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#references)

### [**G019** - K3s cluster setup 02 ~ Storage setup](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#g019-k3s-cluster-setup-02-storage-setup)

- [_Storage organization model_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#storage-organization-model)
- [_Creating the logical volumes (LVs)_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#creating-the-logical-volumes-lvs)
- [_Enabling the LVs for Proxmox VE_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#enabling-the-lvs-for-proxmox-ve)
- [_Configuration file_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#configuration-file)
- [_Relevant system paths_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#relevant-system-paths)
- [_References_](G019%20-%20K3s%20cluster%20setup%2002%20~%20Storage%20setup.md#references)

### [**G020** - K3s cluster setup 03 ~ Debian VM creation](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#g020-k3s-cluster-setup-03-debian-vm-creation)

- [_Preparing the Debian ISO image_](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#preparing-the-debian-iso-image)
- [_Building a Debian virtual machine_](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#building-a-debian-virtual-machine)
- [_Note about the VM's `Boot Order` option_](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#note-about-the-vms-boot-order-option)
- [_Relevant system paths_](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#relevant-system-paths)
- [_References_](G020%20-%20K3s%20cluster%20setup%2003%20~%20Debian%20VM%20creation.md#references)

### [**G021** - K3s cluster setup 04 ~ Debian VM configuration](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#g021-k3s-cluster-setup-04-debian-vm-configuration)

- [_Suggestion about IP configuration in your network_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#suggestion-about-ip-configuration-in-your-network)
- [_Adding the `apt` sources for _non-free_ packages_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#adding-the-apt-sources-for-non-free-packages)
- [_Installing extra packages_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#installing-extra-packages)
- [_The QEMU guest agent comes enabled in Debian 11_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#the-qemu-guest-agent-comes-enabled-in-debian-11)
- [_Hardening the VM's access_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#hardening-the-vms-access)
- [_Hardening the `sshd` service_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#hardening-the-sshd-service)
- [_Configuring Fail2Ban for SSH connections_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#configuring-fail2ban-for-ssh-connections)
- [_Disabling the `root` user login_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#disabling-the-root-user-login)
- [_Configuring the VM with `sysctl`_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#configuring-the-vm-with-sysctl)
- [_Reboot the VM_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#reboot-the-vm)
- [_Disabling transparent hugepages on the VM_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#disabling-transparent-hugepages-on-the-vm)
- [_Regarding the microcode `apt` packages for CPU vulnerabilities_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#regarding-the-microcode-apt-packages-for-cpu-vulnerabilities)
- [_Relevant system paths_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#relevant-system-paths)
- [_References_](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#references)

### [**G022** - K3s cluster setup 05 ~ Connecting the VM to the NUT server](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#g022-k3s-cluster-setup-05-connecting-the-vm-to-the-nut-server)

- [_Reconfiguring the NUT `master` server on your **Proxmox VE host**_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#reconfiguring-the-nut-master-server-on-your-proxmox-ve-host)
- [_Configuring the NUT `slave` client on your Debian VM_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#configuring-the-nut-slave-client-on-your-debian-vm)
- [_Checking the connection between the VM NUT `slave` client and the PVE node NUT `master` server_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#checking-the-connection-between-the-vm-nut-slave-client-and-the-pve-node-nut-master-server)
- [_Testing a Forced ShutDown sequence (`FSD`) with NUT_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#testing-a-forced-shutdown-sequence-fsd-with-nut)
- [_Relevant system paths_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#relevant-system-paths)
- [_References_](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#references)

### [**G023** - K3s cluster setup 06 ~ Debian VM template and backup](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#g023-k3s-cluster-setup-06-debian-vm-template-and-backup)

- [_Turning the Debian VM into a VM template_](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#turning-the-debian-vm-into-a-vm-template)
- [_VM template's backup_](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#vm-templates-backup)
- [_Other considerations regarding VM templates_](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#other-considerations-regarding-vm-templates)
- [_References_](G023%20-%20K3s%20cluster%20setup%2006%20~%20Debian%20VM%20template%20and%20backup.md#references)

### [**G024** - K3s cluster setup 07 ~ K3s node VM template setup](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#g024-k3s-cluster-setup-07-k3s-node-vm-template-setup)

- [_Reasons for a new VM template_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#reasons-for-a-new-vm-template)
- [_Creating a new VM based on the Debian VM template_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#creating-a-new-vm-based-on-the-debian-vm-template)
- [_Set an static IP for the main network device (`net0`)_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#set-an-static-ip-for-the-main-network-device-net0)
- [_Setting a proper hostname string_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-a-proper-hostname-string)
- [_Disabling the swap volume_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#disabling-the-swap-volume)
- [_Changing the VG's name_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#changing-the-vgs-name)
- [_Setting up the second network card_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-the-second-network-card)
- [_Setting up sysctl kernel parameters for K3s nodes_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-sysctl-kernel-parameters-for-k3s-nodes)
- [_Turning the VM into a VM template_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#turning-the-vm-into-a-vm-template)
- [_Protecting VMs and VM templates in Proxmox VE_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#protecting-vms-and-vm-templates-in-proxmox-ve)
- [_Relevant system paths_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#relevant-system-paths)
- [_References_](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#references)

### [**G025** - K3s cluster setup 08 ~ K3s Kubernetes cluster setup](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#g025-k3s-cluster-setup-08-k3s-kubernetes-cluster-setup)

- [_Criteria for the VMs' IPs and hostnames_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-the-vms-ips-and-hostnames)
- [_Creation of VMs based on the K3s node VM template_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#creation-of-vms-based-on-the-k3s-node-vm-template)
- [_Preparing the VMs for K3s_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#preparing-the-vms-for-k3s)
- [_Firewall setup for the K3s cluster_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#firewall-setup-for-the-k3s-cluster)
- [_Considerations before installing the K3s cluster nodes_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#considerations-before-installing-the-k3s-cluster-nodes)
- [_K3s Server node setup_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-server-node-setup)
- [_K3s Agent nodes setup_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-agent-nodes-setup)
- [_Enabling bash autocompletion for `kubectl`_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-bash-autocompletion-for-kubectl)
- [_Enabling the `k3s.log` file's rotation_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-k3slog-files-rotation)
- [_Enabling the `containerd.log` file's rotation_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-containerdlog-files-rotation)
- [_K3s relevant paths_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-relevant-paths)
- [_Starting up and shutting down the K3s cluster nodes_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#starting-up-and-shutting-down-the-k3s-cluster-nodes)
- [_Relevant system paths_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#relevant-system-paths)
- [_References_](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#references)

### [**G026** - K3s cluster setup 09 ~ Setting up a kubectl client for remote access](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#g026-k3s-cluster-setup-09-setting-up-a-kubectl-client-for-remote-access)

- [_Scenario_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#scenario)
- [_Getting the right version of `kubectl`_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-right-version-of-kubectl)
- [_Installing `kubectl` on your client system_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#installing-kubectl-on-your-client-system)
- [_Getting the configuration for accessing the K3s cluster_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#getting-the-configuration-for-accessing-the-k3s-cluster)
- [_Opening the `6443` port in the K3s server node_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#opening-the-6443-port-in-the-k3s-server-node)
- [_Enabling bash autocompletion for `kubectl`_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#enabling-bash-autocompletion-for-kubectl)
- [_**Kubeval**, tool for validating Kubernetes configuration files_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#kubeval-tool-for-validating-kubernetes-configuration-files)
- [_Relevant system paths_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#relevant-system-paths)
- [_References_](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md#references)

### [**G027** - K3s cluster setup 10 ~ Deploying the MetalLB load balancer](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#g027-k3s-cluster-setup-10-deploying-the-metallb-load-balancer)

- [_Considerations before deploying MetalLB_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#considerations-before-deploying-metallb)
- [_Choosing the IP ranges for MetalLB_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#choosing-the-ip-ranges-for-metallb)
- [_Deploying MetalLB on your K3s cluster_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#deploying-metallb-on-your-k3s-cluster)
- [_MetalLB's Kustomize project attached to this guide series_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#metallbs-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#relevant-system-paths)
- [_References_](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md#references)

### [**G028** - K3s cluster setup 11 ~ Deploying the metrics-server service](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#g028-k3s-cluster-setup-11-deploying-the-metrics-server-service)

- [_Checking the metrics-server's manifest_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-servers-manifest)
- [_Deployment of metrics-server_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deployment-of-metrics-server)
- [_Checking the metrics-server service_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#checking-the-metrics-server-service)
- [_Metrics-server's Kustomize project attached to this guide series_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#metrics-servers-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#relevant-system-paths)
- [_References_](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#references)

### [**G029** - K3s cluster setup 12 ~ Setting up cert-manager and wildcard certificate](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#g029-k3s-cluster-setup-12-setting-up-cert-manager-and-wildcard-certificate)

- [_Warning about cert-manager performance_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#warning-about-cert-manager-performance)
- [_Deploying cert-manager_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#deploying-cert-manager)
- [_Reflector, a solution for syncing secrets and configmaps_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#reflector-a-solution-for-syncing-secrets-and-configmaps)
- [_Setting up a wildcard certificate for a domain_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#setting-up-a-wildcard-certificate-for-a-domain)
- [_Checking your certificate with the `kubectl` cert-manager plugin_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#checking-your-certificate-with-the-kubectl-cert-manager-plugin)
- [_Cert-manager and Reflector's Kustomize projects attached to this guide series_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#cert-manager-and-reflectors-kustomize-projects-attached-to-this-guide-series)
- [_Relevant system paths_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#relevant-system-paths)
- [_References_](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#references)

### [**G030** - K3s cluster setup 13 ~ Deploying the Kubernetes Dashboard](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#g030-k3s-cluster-setup-13-deploying-the-kubernetes-dashboard)

- [_Deploying Kubernetes Dashboard_](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#deploying-kubernetes-dashboard)
- [_Testing Kubernetes Dashboard_](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#testing-kubernetes-dashboard)
- [_Kubernetes Dashboard's Kustomize project attached to this guide series_](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#kubernetes-dashboards-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#relevant-system-paths)
- [_References_](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md#references)

### [**G031** - K3s cluster setup 14 ~ Enabling the Traefik dashboard](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#g031-k3s-cluster-setup-14-enabling-the-traefik-dashboard)

- [_Creating an IngressRoute for Traefik dashboard_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#creating-an-ingressroute-for-traefik-dashboard)
- [_Getting into the dashboard_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#getting-into-the-dashboard)
- [_Traefik dashboard has bad performance_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboard-has-bad-performance)
- [_Traefik dashboard's Kustomize project attached to this guide series_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#traefik-dashboards-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#relevant-system-paths)
- [_References_](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#references)

### [**G032** - Deploying services 01 ~ Considerations](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#g032-deploying-services-01-considerations)

- [_Be watchful of your system's resources usage_](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#be-watchful-of-your-systems-resources-usage)
- [_Don't fill your setup up to the brim_](G032%20-%20Deploying%20services%2001%20~%20Considerations.md#dont-fill-your-setup-up-to-the-brim)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 1** - Outlining setup, arranging storage and choosing service IPs](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#g033-deploying-services-02-nextcloud-part-1-outlining-setup-arranging-storage-and-choosing-service-ips)

- [_Outlining Nextcloud's setup_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#outlining-nextclouds-setup)
- [_Setting up new storage drives in the K3s agent_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#setting-up-new-storage-drives-in-the-k3s-agent)
- [_Choosing static cluster IPs for Nextcloud related services_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#choosing-static-cluster-ips-for-nextcloud-related-services)
- [_Relevant system paths_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%201%20-%20Outlining%20setup%2C%20arranging%20storage%20and%20choosing%20service%20IPs.md#relevant-system-paths)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 2** - Redis cache server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#g033-deploying-services-02-nextcloud-part-2-redis-cache-server)

- [_Kustomize project folders for Nextcloud and Redis_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#kustomize-project-folders-for-nextcloud-and-redis)
- [_Redis configuration file_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-configuration-file)
- [_Redis password_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-password)
- [_Redis Deployment resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-deployment-resource)
- [_Redis Service resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource)
- [_Redis Kustomize project_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-kustomize-project)
- [_Don't deploy this Redis project on its own_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#dont-deploy-this-redis-project-on-its-own)
- [_Relevant system paths_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#relevant-system-paths)
- [_References_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%202%20-%20Redis%20cache%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 3** - MariaDB database server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#g033-deploying-services-02-nextcloud-part-3-mariadb-database-server)

- [_MariaDB Kustomize project's folders_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-projects-folders)
- [_MariaDB configuration files_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-configuration-files)
- [_MariaDB passwords_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-passwords)
- [_MariaDB storage_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-storage)
- [_MariaDB StatefulSet resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource)
- [_MariaDB Service resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-service-resource)
- [_MariaDB Kustomize project_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-kustomize-project)
- [_Don't deploy this MariaDB project on its own_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#dont-deploy-this-mariadb-project-on-its-own)
- [_Relevant system paths_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#relevant-system-paths)
- [_References_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 4** - Nextcloud server](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#g033-deploying-services-02-nextcloud-part-4-nextcloud-server)

- [_Considerations about the Nextcloud server_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#considerations-about-the-nextcloud-server)
- [_Nextcloud server Kustomize project's folders_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-kustomize-projects-folders)
- [_Nextcloud server configuration files_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-configuration-files)
- [_Nextcloud server password_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-password)
- [_Nextcloud server storage_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-storage)
- [_Nextcloud server Stateful resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-stateful-resource)
- [_Nextcloud server Service resource_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-service-resource)
- [_Nextcloud server Kustomize project_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#nextcloud-server-kustomize-project)
- [_Don't deploy this Nextcloud server project on its own_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#dont-deploy-this-nextcloud-server-project-on-its-own)
- [_Background jobs on Nextcloud_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#background-jobs-on-nextcloud)
- [_Relevant system paths_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#relevant-system-paths)
- [_References_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md#references)

### [**G033** - Deploying services 02 ~ **Nextcloud - Part 5** - Complete Nextcloud platform](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#g033-deploying-services-02-nextcloud-part-5-complete-nextcloud-platform)

- [_Preparing pending Nextcloud platform elements_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#preparing-pending-nextcloud-platform-elements)
- [_Kustomize project for Nextcloud platform_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#kustomize-project-for-nextcloud-platform)
- [_Logging and checking the background jobs configuration on your Nextcloud platform_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#logging-and-checking-the-background-jobs-configuration-on-your-nextcloud-platform)
- [_Security considerations in Nextcloud_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#security-considerations-in-nextcloud)
- [_Nextcloud platform's Kustomize project attached to this guide series_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#nextcloud-platforms-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#relevant-system-paths)
- [_References_](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 1** - Outlining setup and arranging storage](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#g034-deploying-services-03-gitea-part-1-outlining-setup-and-arranging-storage)

- [_Outlining Gitea's setup_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-giteas-setup)
- [_Setting up new storage drives in the K3s agent_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agent)
- [_FQDNs for Gitea related services_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#fqdns-for-gitea-related-services)
- [_Relevant system paths_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [_References_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 2** - Redis cache server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#g034-deploying-services-03-gitea-part-2-redis-cache-server)

- [_Kustomize project folders for Gitea and Redis_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#kustomize-project-folders-for-gitea-and-redis)
- [_Redis configuration file_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-configuration-file)
- [_Redis password_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-password)
- [_Redis Deployment resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-deployment-resource)
- [_Redis Service resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-service-resource)
- [_Redis Kustomize project_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-kustomize-project)
- [_Don't deploy this Redis project on its own_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#dont-deploy-this-redis-project-on-its-own)
- [_Relevant system paths_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#relevant-system-paths)
- [_References_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 3** - PostgreSQL database server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#g034-deploying-services-03-gitea-part-3-postgresql-database-server)

- [_PostgreSQL Kustomize project's folders_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-projects-folders)
- [_PostgreSQL configuration files_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-configuration-files)
- [_PostgreSQL passwords_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-passwords)
- [_PostgreSQL storage_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-storage)
- [_PostgreSQL StatefulSet resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-statefulset-resource)
- [_PostgreSQL Service resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-service-resource)
- [_PostgreSQL Kustomize project_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-kustomize-project)
- [_Don't deploy this PostgreSQL project on its own_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#dont-deploy-this-postgresql-project-on-its-own)
- [_Relevant system paths_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#relevant-system-paths)
- [_References_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 4** - Gitea server](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#g034-deploying-services-03-gitea-part-4-gitea-server)

- [_Considerations about the Gitea server_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#considerations-about-the-gitea-server)
- [_Gitea server Kustomize project's folders_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-kustomize-projects-folders)
- [_Gitea server configuration file_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-configuration-file)
- [_Gitea server storage_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-storage)
- [_Gitea server Stateful resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-stateful-resource)
- [_Gitea server Service resource_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-server-service-resource)
- [_Gitea server's Kustomize project_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#gitea-servers-kustomize-project)
- [_Don't deploy this Gitea server project on its own_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#dont-deploy-this-gitea-server-project-on-its-own)
- [_Relevant system paths_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#relevant-system-paths)
- [_References_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%204%20-%20Gitea%20server.md#references)

### [**G034** - Deploying services 03 ~ **Gitea - Part 5** - Complete Gitea platform](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#g034-deploying-services-03-gitea-part-5-complete-gitea-platform)

- [_Declaring the pending Gitea platform elements_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#declaring-the-pending-gitea-platform-elements)
- [_Kustomize project for Gitea platform_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#kustomize-project-for-gitea-platform)
- [_Finishing Gitea platform's setup_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#finishing-gitea-platforms-setup)
- [_Security considerations in Gitea_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#security-considerations-in-gitea)
- [_Gitea platform's Kustomize project attached to this guide series_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#gitea-platforms-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#relevant-system-paths)
- [_References_](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 1** - Outlining setup and arranging storage](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#g035-deploying-services-04-monitoring-stack-part-1-outlining-setup-and-arranging-storage)

- [_Outlining your monitoring stack setup_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-your-monitoring-stack-setup)
- [_Setting up new storage drives in the K3s agents_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#setting-up-new-storage-drives-in-the-k3s-agents)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 2** - Kube State Metrics service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#g035-deploying-services-04-monitoring-stack-part-2-kube-state-metrics-service)

- [_Kustomize project folders for your monitoring stack and Kube State Metrics_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kustomize-project-folders-for-your-monitoring-stack-and-kube-state-metrics)
- [_Kube State Metrics ServiceAccount resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-serviceaccount-resource)
- [_Kube State Metrics ClusterRole resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrole-resource)
- [_Kube State Metrics ClusterRoleBinding resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-clusterrolebinding-resource)
- [_Kube State Metrics Deployment resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-deployment-resource)
- [_Kube State Metrics Service resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-service-resource)
- [_Kube State Metrics Kustomize project_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#kube-state-metrics-kustomize-project)
- [_Don't deploy this Kube State Metrics project on its own_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#dont-deploy-this-kube-state-metrics-project-on-its-own)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%202%20-%20Kube%20State%20Metrics%20service.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 3** - Prometheus Node Exporter service](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#g035-deploying-services-04-monitoring-stack-part-3-prometheus-node-exporter-service)

- [_Kustomize project folders for Prometheus Node Exporter_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#kustomize-project-folders-for-prometheus-node-exporter)
- [_Prometheus Node Exporter DaemonSet resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-daemonset-resource)
- [_Prometheus Node Exporter Service resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-service-resource)
- [_Prometheus Node Exporter Kustomize project_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#prometheus-node-exporter-kustomize-project)
- [_Don't deploy this Prometheus Node Exporter project on its own_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#dont-deploy-this-prometheus-node-exporter-project-on-its-own)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 4** - Prometheus server](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#g035-deploying-services-04-monitoring-stack-part-4-prometheus-server)

- [_Kustomize project folders for Prometheus server_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#kustomize-project-folders-for-prometheus-server)
- [_Prometheus configuration files_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-configuration-files)
- [_Prometheus server storage_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-storage)
- [_Prometheus server StatefulSet resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-statefulset-resource)
- [_Prometheus server Service resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-service-resource)
- [_Prometheus server Traefik IngressRoute resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-server-traefik-ingressroute-resource)
- [_Prometheus server's Kustomize project_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#prometheus-servers-kustomize-project)
- [_Don't deploy this Prometheus server project on its own_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#dont-deploy-this-prometheus-server-project-on-its-own)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%204%20-%20Prometheus%20server.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 5** - Grafana](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#g035-deploying-services-04-monitoring-stack-part-5-grafana)

- [_Kustomize project folders for Grafana_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#kustomize-project-folders-for-grafana)
- [_Grafana data storage_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-data-storage)
- [_Grafana Stateful resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-stateful-resource)
- [_Grafana Service resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-service-resource)
- [_Grafana Traefik IngressRoute resource_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-traefik-ingressroute-resource)
- [_Grafana Kustomize project_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#grafana-kustomize-project)
- [_Don't deploy this Grafana project on its own_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#dont-deploy-this-grafana-project-on-its-own)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%205%20-%20Grafana.md#references)

### [**G035** - Deploying services 04 ~ **Monitoring stack - Part 6** - Complete monitoring stack setup](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#g035-deploying-services-04-monitoring-stack-part-6-complete-monitoring-stack-setup)

- [_Declaring the remaining monitoring stack components_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#declaring-the-remaining-monitoring-stack-components)
- [_Kustomize project for the monitoring setup_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#kustomize-project-for-the-monitoring-setup)
- [_Checking Prometheus_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#checking-prometheus)
- [_Finishing Grafana's setup_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#finishing-grafanas-setup)
- [_Security concerns on Prometheus and Grafana_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#security-concerns-on-prometheus-and-grafana)
- [_Monitoring stack's Kustomize project attached to this guide series_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#monitoring-stacks-kustomize-project-attached-to-this-guide-series)
- [_Relevant system paths_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#relevant-system-paths)
- [_References_](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md#references)

### [**G036** - Host and K3s cluster ~ Monitoring and diagnosis](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#g036-host-and-k3s-cluster-monitoring-and-diagnosis)

- [_Monitoring resources usage_](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#monitoring-resources-usage)
- [_Checking the logs_](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#checking-the-logs)
- [_Shell access into your containers_](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#shell-access-into-your-containers)
- [_References_](G036%20-%20Host%20and%20K3s%20cluster%20~%20Monitoring%20and%20diagnosis.md#references)

### [**G037** - Backups 01 ~ Considerations](G037%20-%20Backups%2001%20~%20Considerations.md#g037-backups-01-considerations)

- [_What to backup. Identifying your data concerns_](G037%20-%20Backups%2001%20~%20Considerations.md#what-to-backup-identifying-your-data-concerns)
- [_How to backup. Backup tools_](G037%20-%20Backups%2001%20~%20Considerations.md#how-to-backup-backup-tools)
- [_Where to store the backups. Backup storage_](G037%20-%20Backups%2001%20~%20Considerations.md#where-to-store-the-backups-backup-storage)
- [_When to do the backups. Backup scheduling_](G037%20-%20Backups%2001%20~%20Considerations.md#when-to-do-the-backups-backup-scheduling)
- [_References_](G037%20-%20Backups%2001%20~%20Considerations.md#references)

### [**G038** - Backups 02 ~ Host platform backup with Clonezilla](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#g038-backups-02-host-platform-backup-with-clonezilla)

- [_What gets inside this backup_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#what-gets-inside-this-backup)
- [_Why doing this backup_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#why-doing-this-backup)
- [_How it affects the host platform_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-it-affects-the-host-platform)
- [_When to do the backup_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#when-to-do-the-backup)
- [_How to backup with Clonezilla_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-backup-with-clonezilla)
- [_How to restore with Clonezilla_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#how-to-restore-with-clonezilla)
- [_Final considerations_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#final-considerations)
- [_References_](G038%20-%20Backups%2002%20~%20Host%20platform%20backup%20with%20Clonezilla.md#references)

### [**G039** - Backups 03 ~ Proxmox VE backup job](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#g039-backups-03-proxmox-ve-backup-job)

- [_What gets covered with the backup job_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#what-gets-covered-with-the-backup-job)
- [_Why scheduling a backup job_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#why-scheduling-a-backup-job)
- [_How it affects the K3s Kubernetes cluster_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#how-it-affects-the-k3s-kubernetes-cluster)
- [_When to do the backup job_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#when-to-do-the-backup-job)
- [_Scheduling the backup job in Proxmox VE_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#scheduling-the-backup-job-in-proxmox-ve)
- [_Restoring a backup in Proxmox VE_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#restoring-a-backup-in-proxmox-ve)
- [_Location of the backup files in the Proxmox VE system_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#location-of-the-backup-files-in-the-proxmox-ve-system)
- [_Relevant system paths_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#relevant-system-paths)
- [_References_](G039%20-%20Backups%2003%20~%20Proxmox%20VE%20backup%20job.md#references)

### [**G040** - Backups 04 ~ UrBackup 01 - Server setup](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#g040-backups-04-urbackup-01-server-setup)

- [_Setting up a new VM for the UrBackup server_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#setting-up-a-new-vm-for-the-urbackup-server)
- [_Deploying UrBackup_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#deploying-urbackup)
- [_Firewall configuration on Proxmox VE_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#firewall-configuration-on-proxmox-ve)
- [_Adjusting the UrBackup server configuration_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#adjusting-the-urbackup-server-configuration)
- [_UrBackup server log file_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#urbackup-server-log-file)
- [_About backing up the UrBackup server VM_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#about-backing-up-the-urbackup-server-vm)
- [_Relevant system paths_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#relevant-system-paths)
- [_References_](G040%20-%20Backups%2004%20~%20UrBackup%2001%20-%20Server%20setup.md#references)

### [**G041** - Backups 05 ~ UrBackup 02 - Clients setup and configuring file backups](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#g041-backups-05-urbackup-02-clients-setup-and-configuring-file-backups)

- [_Deploying the UrBackup client program_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#deploying-the-urbackup-client-program)
- [_UrBackup client log file_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-log-file)
- [_UrBackup client uninstaller_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#urbackup-client-uninstaller)
- [_Configuring file backup paths on a client_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#configuring-file-backup-paths-on-a-client)
- [_Backups on the UrBackup server_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#backups-on-the-urbackup-server)
- [_Restoration from file backups_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#restoration-from-file-backups)
- [_Relevant system paths_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#relevant-system-paths)
- [_References_](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md#references)

### [**G042** - System update 01 ~ Considerations](G042%20-%20System%20update%2001%20~%20Considerations.md#g042-system-update-01-considerations)

- [_What to update. Identifying your system's software layers_](G042%20-%20System%20update%2001%20~%20Considerations.md#what-to-update-identifying-your-systems-software-layers)
- [_How to update. Update procedures_](G042%20-%20System%20update%2001%20~%20Considerations.md#how-to-update-update-procedures)
- [_When to apply the updates_](G042%20-%20System%20update%2001%20~%20Considerations.md#when-to-apply-the-updates)

### [**G043** - System update 02 ~ Updating Proxmox VE](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#g043-system-update-02-updating-proxmox-ve)

- [_Examining your Proxmox VE system_](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#examining-your-proxmox-ve-system)
- [_Updating Proxmox VE_](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#updating-proxmox-ve)
- [_References_](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md#references)

### [**G044** - System update 03 ~ Updating VMs and UrBackup](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#g044-system-update-03-updating-vms-and-urbackup)

- [_Examining your VMs_](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#examining-your-vms)
- [_Updating Debian on your VMs_](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-debian-on-your-vms)
- [_Updating the UrBackup software_](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#updating-the-urbackup-software)
- [_References_](G044%20-%20System%20update%2003%20~%20Updating%20VMs%20and%20UrBackup.md#references)

### [**G045** - System update 04 ~ Updating K3s and deployed apps](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#g045-system-update-04-updating-k3s-and-deployed-apps)

- [_Examining your K3s Kubernetes cluster_](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#examining-your-k3s-kubernetes-cluster)
- [_Updating apps and K3s_](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#updating-apps-and-k3s)
- [_References_](G045%20-%20System%20update%2004%20~%20Updating%20K3s%20and%20deployed%20apps.md#references)

### [**G046** - Cleaning the system](G046%20-%20Cleaning%20the%20system.md#g046-cleaning-the-system)

- [_Checking your storage status_](G046%20-%20Cleaning%20the%20system.md#checking-your-storage-status)
- [_Cleaning procedures_](G046%20-%20Cleaning%20the%20system.md#cleaning-procedures)
- [_Reminder about the `apt` updates_](G046%20-%20Cleaning%20the%20system.md#reminder-about-the-apt-updates)
- [_Relevant system paths_](G046%20-%20Cleaning%20the%20system.md#relevant-system-paths)
- [_References_](G046%20-%20Cleaning%20the%20system.md#references)

## Appendixes

### [**G901** - Appendix 01 ~ Connecting through SSH with PuTTY](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#g901-appendix-01-connecting-through-ssh-with-putty)

- [_Generating `.ppk` file from private key_](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#generating-ppk-file-from-private-key)
- [_Configuring the connection to the PVE node_](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#configuring-the-connection-to-the-pve-node)
- [_References_](G901%20-%20Appendix%2001%20~%20Connecting%20through%20SSH%20with%20PuTTY.md#references)

### [**G902** - Appendix 02 ~ Vim vimrc configuration](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#g902-appendix-02-vim-vimrc-configuration)

- [_References_](G902%20-%20Appendix%2002%20~%20Vim%20vimrc%20configuration.md#references)

### [**G903** - Appendiz 03 ~ Customization of the motd file](G903%20-%20Appendiz%2003%20~%20Customization%20of%20the%20motd%20file.md#g903-appendiz-03-customization-of-the-motd-file)

- [_References_](G903%20-%20Appendiz%2003%20~%20Customization%20of%20the%20motd%20file.md#references)

### [**G904** - Appendix 04 ~ Object by object Kubernetes deployments](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#g904-appendix-04-object-by-object-kubernetes-deployments)

- [_Example scenario: cert-manager deployment_](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#example-scenario-cert-manager-deployment)
- [_Relevant system paths_](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#relevant-system-paths)
- [_References_](G904%20-%20Appendix%2004%20~%20Object%20by%20object%20Kubernetes%20deployments.md#references)

### [**G905** - Appendix 05 ~ Cloning storage drives with Clonezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#g905-appendix-05-cloning-storage-drives-with-clonezilla)

- [_Preparing the Clonezilla Live USB_](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#preparing-the-clonezilla-live-usb)
- [_Cloning a storage drive with Clonezilla_](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#cloning-a-storage-drive-with-clonezilla)
- [_Restoring a Clonezilla image_](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#restoring-a-clonezilla-image)
- [_Considerations about Clonezilla_](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#considerations-about-clonezilla)
- [_Alternative to Clonezilla:_ Rescuezilla](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#alternative-to-clonezilla-rescuezilla)
- [_References_](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md#references)

### [**G906** - Appendix 06 ~ Handling VM or VM template volumes](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#g906-appendix-06-handling-vm-or-vm-template-volumes)

- [_Installing the `libguestfs-tools` package_](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#installing-the-libguestfs-tools-package)
- [_Locating and checking a VM or VM template's hard disk volume_](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#locating-and-checking-a-vm-or-vm-templates-hard-disk-volume)
- [_Relevant system paths_](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#relevant-system-paths)
- [_References_](G906%20-%20Appendix%2006%20~%20Handling%20VM%20or%20VM%20template%20volumes.md#references)

### [**G907** - Appendix 07 ~ Resizing a root LVM volume](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#g907-appendix-07-resizing-a-root-lvm-volume)

- [_Resizing the storage drive on Proxmox VE_](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#resizing-the-storage-drive-on-proxmox-ve)
- [_Extending the root LVM filesystem on a live VM_](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#extending-the-root-lvm-filesystem-on-a-live-vm)
- [_Final note_](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#final-note)
- [_References_](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md#references)

### [**G908** - Appendix 08 ~ K3s cluster with two or more server nodes](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#g908-appendix-08-k3s-cluster-with-two-or-more-server-nodes)

- [_Add a new VM to act as the second server node_](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#add-a-new-vm-to-act-as-the-second-server-node)
- [_Adapt the Proxmox VE firewall setup_](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#adapt-the-proxmox-ve-firewall-setup)
- [_Setup of the FIRST K3s server node_](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-first-k3s-server-node)
- [_Setup of the SECOND K3s server node_](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#setup-of-the-second-k3s-server-node)
- [_Regarding the K3s agent nodes_](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md#regarding-the-k3s-agent-nodes)

### [**G909** - Appendix 09 ~ Kubernetes object stuck in Terminating state](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#g909-appendix-09-kubernetes-object-stuck-in-terminating-state)

- [_Scenario_](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#scenario)
- [_Solution_](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#solution)
- [_References_](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md#references)

### [**G910** - Appendix 10 ~ Setting up virtual network with Open vSwitch](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#g910-appendix-10-setting-up-virtual-network-with-open-vswitch)

- [_Installation_](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#installation)
- [_Replacing the Linux bridge with the OVS one_](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#replacing-the-linux-bridge-with-the-ovs-one)
- [_Relevant system paths_](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#relevant-system-paths)
- [_References_](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md#references)

### [**G911** - Appendix 11 ~ Alternative Nextcloud web server setups](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#g911-appendix-11-alternative-nextcloud-web-server-setups)

- [Ideas for the Apache setup](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#ideas-for-the-apache-setup)
- [Nginx setup](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#nginx-setup)
- [Relevant system paths](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#relevant-system-paths)
- [References](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md#references)

### [**G912** - Appendix 12 ~ Adapting MetalLB config to CR](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md#g912-appendix-12-adapting-metallb-config-to-cr)

- [_References_](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md#references)

### [**G913** - Appendix 13 ~ Checking the K8s API endpoints' status](G913%20-%20Appendix%2013%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md)

- [_References_](G913%20-%20Appendix%2013%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md#references)

### [**G914** - Appendix 14 ~ Post-update manual maintenance tasks for Nextcloud](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md)

- [_Concerns_](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#concerns)
- [_Procedure_](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#procedure)
- [_References_](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md#references)

### [**G915** - Appendix 15 ~ Updating MariaDB to a newer major version](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md)

- [_Concerns_](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#concerns)
- [_Enabling the update procedure_](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#enabling-the-update-procedure)
- [_References_](G915%20-%20Appendix%2015%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md#references)

### [**G916** - Appendix 16 ~ Updating PostgreSQL to a newer major version](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md)

- [_Concerns_](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#concerns)
- [_Upgrade procedure (for Gitea's PostgreSQL instance)_](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#upgrade-procedure-for-giteas-postgresql-instance)
- [_Kustomize project only for updating PostgreSQL included in this guide series_](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#kustomize-project-only-for-updating-postgresql-included-in-this-guide-series)
- [_References_](G916%20-%20Appendix%2016%20~%20Updating%20PostgreSQL%20to%20a%20newer%20major%20version.md#references)

## Navigation

[<< Previous (**README**)](README.md) | [Next (**G001** - Hardware setup) >>](G001%20-%20Hardware%20setup.md)
