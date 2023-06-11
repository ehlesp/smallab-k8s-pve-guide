# G025 - K3s cluster setup 08 ~ K3s Kubernetes cluster setup

Now that you have a more specialized VM template suited for creating K3s nodes, it's time to build your K3s cluster. First you'll create and set up the VMs you need, then you'll install the K3s software although with a concrete configuration on each of them.

## Criteria for the VMs' IPs and hostnames

In the [**G021** guide](G021%20-%20K3s%20cluster%20setup%2004%20~%20Debian%20VM%20configuration.md#suggestion-about-ip-configuration-in-your-network), I made you a suggestion about how to organize the IPs within your network. Here, I'll deepen in the matter by showing you a simple IP arrangement for the K3s cluster nodes you'll create in this guide. Also, I'll show you a naming convention for the VMs' hostnames, since it's required that each node in a Kubernetes cluster has an unique hostname for identification purposes.

Another thing you must know is the two node types that exist in a K3s cluster:

- The **server** node, which corresponds with the **master** in a standard Kubernetes cluster.
- The **agent** node, which is called **worker** in Kubernetes.

A master can also act as an agent at the same time, but I won't show you that case in this guide series.

> **BEWARE!**  
> In this guide you'll see how to create a single-server/master K3s cluster that uses an embedded sqlite database as data storage. If you want a multiserver/multimaster cluster setup, you'll need to combine the instructions given here with the indications summarized in the [**G908** appendix guide](G908%20-%20Appendix%2008%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md).  
> Also be aware that a sqlite-based cluster can only have one server node and **cannot** be converted to a multiserver one.

### _Criteria for IPs_

I'll assume the most simple scenario, which is a single local network behind one router. This means that everything falls within a network range such as `192.168.1.0/24`, and no other subnets are present. Don't forget that the VMs will have two network cards: the primary NIC which will be the one exposed to the internet, and the secondary NIC which will be configured to communicate only through the isolated `vmbr1` bridge. Finally, also know that the cluster won't have a high number of nodes; in this guide I'm aiming to have only three nodes. With all this in mind, the IPs arrangement could be something like the following.

#### **IP range for VM templates**

- Main network card: between `192.168.1.11` and `192.168.1.20`.
- Secondary network card: any address beyond `10.0.0.20`.

#### **IP range for K3s SERVER nodes**

- Main network card: between `192.168.1.21` and `192.168.1.30`.
- Secondary network card: between `10.0.0.1` and `10.0.0.10`.

#### **IP range for K3s AGENT nodes**

- Main network card: between `192.168.1.31` and `192.168.1.40`.
- Secondary network card: between `10.0.0.11` and `10.0.0.20`.

This is just a suggestion, although I'll use it to illustrate the setup of the K3s cluster.

> **BEWARE!**  
> You must not forget to set up **static** IPs to **all** your other devices in your network, like your Proxmox VE host. Otherwise you'll risk having conflicts due to the dynamic IP assignment applied by your router.

### _Naming convention for hostnames_

The naming schema I'll use to assign hostnames to the new VMs is the following.

- `k3snodetpl`: name for the VM that is the template of all the K3s cluster VM nodes.
- `k3sserverXX`: name for VMs that will act as server nodes in the K3s cluster.
- `k3sagentXX`: name for VMs that will act as agent nodes in the K3s cluster.

My intention is to have a K3s cluster with one server and two agents, therefore the hostnames for each VM will be:

- The VM acting as server will be called `k3sserver01`.
- The other two VMs that will run as agents will be named `k3sagent01` and `k3sagent02`.

As you can see above, the naming convention doesn't need to be complicated, but make sure that it makes sense and reflects the role given to each VM in the K3s cluster.

## Creation of VMs based on the K3s node VM template

For starters, you'll create two VMs: one will be a K3s server and the other an agent. After creating them, you'll have to configure a number of things in both.

To create these two, go to your latest VM template (the `k3snodetpl` one), unfold the `More` options and click on `Clone`. In the `Clone` window that appears:

- Make the `VM ID` somehow correspond to the IPs the VM will eventually have.
- Specify a significant `Name`, like `k3sserver01`.
- Leave the mode as `Linked Clone`, so the new VMs take up less space by reusing the data already present in the VM template.

![Link-cloning the K3s node template](images/g025/pve_node_template_link_cloning_k3snodetpl.png "Link-cloning the K3s node template")

In the snapshot you see that I've given the ID `2101` to the VM, since this VM is going to have a primary IP ended in `21`, and a secondary IP ended in `01`. Also see that, since this VM is going to be the K3s server in the cluster, I've named this VM `k3sserver01`.

The second VM is going to be an agent, so its name should be `k3sagent01`. The IPs I plan to give to this VM end in `31` and `11` respectively, so a good `ID` would be `3111`.

> **BEWARE!**  
> The VM IDs are important for configuring their automatic starting and shutting down by Proxmox VE. Later in this guide I'll tell you about it, but you can check how the VM IDs are important in such process [in the Proxmox VE official documentation](https://pve.proxmox.com/pve-docs/chapter-qm.html#qm_startup_and_shutdown).

Again, my hostname schema and ID assignments are just suggestions. Put the names and IDs you find suitable for your particular preferences or requirements.

> **BEWARE!**  
> Linked clones are attached to their VM template, so Proxmox VE won't allow you to remove the template unless you delete its linked clones first.

### _VM as K3s server node_

K3s server nodes can run workloads (apps and services), but it's more appropriate to use them just for managing the cluster. Acting just as a server is a heavy duty job, even in a small setup such as the one you're building with this guide series. So, you can start assigning your `k3sserver01` node low hardware specs and increase them later depending on how well the node runs. Still, be aware that if the server node has a bad performance, the whole cluster won't run properly either. In my case I left this VM with rather low capabilities to begin with.

- **Memory**: 1.00/1.50 GiB of RAM.
- **Processors**: 2 vCPUs.

Those are really low hardware capabilities, so don't go lower than those or it will be too tight for the server node to run properly. Don't forget that, to change the hardware attached to a VM, just go to the `Hardware` tab of the VM. There, choose the item you want to modify and press on `Edit`.

![Hardware tab of a VM](images/g025/pve_vm_hardware_tab.png "Hardware tab of a VM")

> **NOTE**  
> Remember that in this guide series I'm working on a low end computer, but if yours happens to be more powerful, don't hesitate to assign more resources to the VMs if you want or need to, although be careful of not overloading your hardware.

### _VM as K3s agent node_

K3s agents are the ones meant to run workloads in the cluster, so how much CPU and RAM you must assign to them depends heavily on what will be load they'll run. To play it safe you can do as I did and start by assigning them something like this.

- **Memory**: 1.00/2.00 GiB of RAM.
- **Processors**: 3 vCPUs.

As it happens with the server node VM, depending on how well your agent nodes run, later you'll have to adjust their capabilities to fit both their needs and the limits of your real hardware.

### _Assign a static IP to each VM_

After creating the VMs, go to your router or gateway and assign each a static IP. In this guide, I'll follow the criteria I explained at the beginning of this guide, so the nodes here will have the following IPs for their **primary network cards**.

- K3s **server** node 1: `192.168.1.21`
- K3s **agent** node 1: `192.168.1.31`

## Preparing the VMs for K3s

Now that you have the new VMs created, you might think that you can start creating the K3s cluster, right? Wrong. In the following subsections, you'll see the pending procedures that you must apply in your VMs to make them fully adequate to become K3s cluster nodes.

### _Customizing the hostname_

As it happened when you set up the k3s node VM template, these two new VMs you've created both have the same hostname inherited from the VM template. You need to change it, as you did before, but customizing it to the role each node will play in the K3s cluster. So, if you apply the naming scheme I showed you back at the beginning of this guide, the hostname value for each VM will be as follows.

- The K3s server VM will be called `k3sserver01`.
- The other VM will run as an agent, so it'll be named `k3sagent01`.

With the naming scheme decided, you can change the hostname **to each VM** in the same way you did when you configured the K3s node VM template.

> **BEWARE!**  
> At this point, your two new VMs will have the same credentials (meaning the same certificates, password and TFA TOTP code for the `mgrsys` user) as the ones used in the VM template they are clones of. Remember this when you try to connect remotely to those VMs through SSH.

1. Using the `hostnamectl` command, change the VM's hostname value (`k3snodetpl` now). For instance, for the K3s server VM it would be like below.

    ~~~bash
    $ sudo hostnamectl set-hostname k3sserver01
    ~~~

2. Edit the `/etc/hosts` file, where you must replace the old hostname (`k3snodetpl`) with the new one. The hostname should only appear in the `127.0.1.1` line.

    ~~~properties
    127.0.1.1   k3sserver01.deimos.cloud    k3sserver01
    ~~~

3. Don't forget to do the same steps on the `k3sagent01` VM. First the `hostnamectl` command.

    ~~~bash
    $ sudo hostnamectl set-hostname k3sagent01
    ~~~

    Then, changing the proper line in the `/etc/hosts` file.

    ~~~properties
    127.0.1.1   k3sagent01.deimos.cloud    k3sagent01
    ~~~

Remember that to see the change applied, you have to exit your current shell session and log back into the VM. You'll see the new hostname in the shell prompt.

### _Changing the second network card's IP address_

The second network card of the new VMs has the same IP address that was configured in the template, something you must correct or the networking with this card won't work. Following the pattern I established before, the IPs I'm going to set for this VMs are the next.

- K3s **server** node 1: `10.0.0.1`
- K3s **agent** node 1: `10.0.0.11`

1. To change this value on each VM, you just have to edit the `/etc/network/interfaces` file and replace there the template IP with the correct one. Of course, for extra safety, first do a backup.

    ~~~bash
    $ sudo cp /etc/network/interfaces /etc/network/interfaces.bkp
    ~~~

2. Edit the `interfaces` file and just change the address assigned to the interface. In my case, it's the `ens19` interface, and this is how it would look in the K3s server node.

    ~~~bash
    # The secondary network interface
    allow-hotplug ens19
    iface ens19 inet static
      address 10.0.0.1
      netmask 255.255.255.0
    ~~~

3. To apply the change you'll have to restart the interface with the `ifdown` and `ifup` commands.

    ~~~bash
    $ sudo ifdown ens19
    RTNETLINK answers: Cannot assign requested address
    $ sudo ifup ens19
    ~~~

    Don't mind the warning `ifdown` returns, `ifup` will be able to activate the interface just fine.

4. Finally, check with the `ip` command that the interface has the new IP address.

    ~~~bash
    $ ip a
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
    2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP group default qlen 1000
        link/ether f6:26:b3:ce:76:a6 brd ff:ff:ff:ff:ff:ff
        altname enp0s18
        inet 192.168.1.21/24 brd 192.168.1.255 scope global dynamic ens18
           valid_lft 84332sec preferred_lft 84332sec
    3: ens19: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP group default qlen 1000
        link/ether 5a:b0:5f:41:3c:48 brd ff:ff:ff:ff:ff:ff
        altname enp0s19
        inet 10.0.0.1/24 brd 10.0.0.255 scope global ens19
           valid_lft forever preferred_lft forever
    ~~~

Remember to change the secondary network card's IP, following the same steps, on your other VM!

### _Changing the TOTP code_

The VMs share the same TOTP code that you generated for the Debian VM template. Obviously, this is not secure, so you must change it **on each VM**. On the other hand, you'll probably don't want to complicate your system management too much for what is just a homelab setup. So, for the scenario contemplated in this guide, a middle-ground solution would be having one TOTP for the K3s server node, and another TOTP code for all the K3s agent nodes. Regardless of the strategy you adopt, the procedure to change the TOTP on each VM is the same.

You just have to execute the `google-authenticator` command, and it will overwrite the current content of the `.google_authenticator` file in the `$HOME` directory of your current user. For instance, in the K3s server node you would execute something like the following.

~~~bash
$ google-authenticator -t -d -f -r 3 -R 30 -w 3 -Q UTF8 -i k3sserverxx.deimos.cloud -l mgrsys@k3sserverxx
~~~

And the command for the agent node should be as shown next.

~~~bash
$ google-authenticator -t -d -f -r 3 -R 30 -w 3 -Q UTF8 -i k3sagentxx.deimos.cloud -l mgrsys@k3sagentxx
~~~

> **BEWARE!**  
> Export and save all the codes and even the `.google_authenticator` file in a password manager or by any other secure method.

### _Changing the ssh key-pair_

As with the TOTP code, the ssh key-pair files are the same ones you created for your first VM template, and all the VMs you've created till now have the very same pair. Following the same strategy as with the TOTP code, create a different key-pair for the server node and for the agent node. The procedure in both cases is as follows.

1. Being sure that you're on your `$HOME` directory, remove the current key-pair completely.

    ~~~bash
    $ cd
    $ rm -rf .ssh/
    ~~~

2. Now you can create a new ssh key-pair with the `ssh-keygen` command.

    ~~~bash
    $ ssh-keygen -t rsa -b 4096 -C "k3sserverxx.deimos.cloud@mgrsys"
    ~~~

    > **BEWARE!**  
    > The comment (`-C`) in the command above is just an example, replace it with whatever string suits the node or your requirements.

3. Now enable the public part of the key-pair.

    ~~~bash
    $ cat .ssh/id_rsa.pub >> .ssh/authorized_keys ; chmod 600 .ssh/authorized_keys
    ~~~

Careful now, you have to export the new private key (the `id_rsa` file) so you can remotely connect through your ssh client. Don't close your current connection so you can use it to export the private key.

> **BEWARE!**  
> Don't forget to export and save the new ssh key-pairs in a password manager or by any other secure method.

### _Changing the administrative user's password_

The `mgrsys` user also has the same password you gave it in the creation of the first Debian 10 template. To change it, I'll follow the same strategy as with the TOTP code and the ssh key-pair, one password for the K3s server and another for all the K3s agents. To change the password, just execute the `passwd` command.

~~~bash
$ passwd
Changing password for mgrsys.
Current password:
New password:
Retype new password:
passwd: password updated successfully
~~~

> **BEWARE!**  
> Save the password somewhere safe, like in a password manager.

### _Creating the pending K3s agent node VM_

You've created and configured one VM that will act as a K3s server node, and another that will be a K3s agent node. Still, you're missing another agent node, so link-clone it to the K3s node template with a `3112` VM ID and for name the string `k3sagent02`. Then, you'll have to configure it as you did with the first K3s nodes you've created, but with some differences.

#### **Changing hostname and assigning IPs**

As you did with both the k3s server and the first agent nodes, you'll need to assign concrete static IPs to the network devices. Also, you'll need to change the hostname.

1. Assign in your router or gateway the static main IPs for the new VM. In my criteria, its address would be as follows.

    - K3s **agent** node 2: `192.168.1.32`

2. Change its hostname, as you've already seen before in this guide.

    - K3s **agent** node 2: `k3sagent02`

3. Finally, you'll also have to change the IP address of its second network interface.

    - K3s **agent** node 2: `10.0.0.12`

#### **Exporting the TOTP codes, the ssh key-pairs and reusing passwords**

To ease a bit the burden of system maintenance, and reduce the madness of many passwords and codes, let's reuse the ones you generated for the `mgrsys` user in the first agent node. It's not the safest configuration possible, true, but should be safe enough for the homelab you're building in this guide series.

The idea is that you export the TOTP code and the ssh key-pair from your `k3sagent01` VM to the `k3sagent02` one. Also, you would reuse the new password you've applied in the first agent. This way, at least you'll have different authorization codes for the different types of nodes in your K3s cluster.

The files you have to export are:

- `/home/mgrsys/.google_authenticator`: this is the file where the TOTP code is stored.
- `/home/mgrsys/.ssh/`: in this folder are the ssh key-files. Export the whole folder.

The most convenient way to export files is packaging and compressing them with the `tar` command.

~~~bash
$ cd
$ tar czvf .ssh.tgz .ssh/
$ tar czvf .google_authenticator.tgz .google_authenticator
~~~

When you have exported these `.tgz` files (with a tool like WinSCP, for instance) to the second agent node, remove the ones already present and then decompress the `.tgz` files.

~~~bash
$ cd
$ rm -rf .ssh
$ rm -f .google_authenticator
$ tar xvf .ssh.tgz
$ tar xvf .google_authenticator.tgz
$ rm .ssh.tgz .google_authenticator.tgz
~~~

The `.tgz` files' content will be extracted with the same permissions and owners they had originally, which in this case makes them good to go as they are: the users and groups, and their internal ids, are the same in all your VMs.

Finally, don't forget to use the `passwd` command to change the password and put the same one as in the first agent node.

## Firewall setup for the K3s cluster

A K3s cluster uses certain ports to work, although they're different on each K3s node type.

### _Port mapping_

In a **default** installation of a K3s cluster, the ports you need to have open are the following.

- On SERVER nodes:
    - TCP `2379-2380`: necessary when using HA with embedded etcd database engines. These are not used in a one-server-node setup.
    - TCP `6443`: this is for connecting to the Kubernetes API server, necessary for cluster management tasks.
    - TCP `10250`: required to access to Kubelet metrics.

- On AGENT nodes:
    - TCP `80`: used by the Traefik service.
    - TCP `443`: also used by the Traefik service.
    - TCP `10250`: required to access Kubelet metrics.

On the other hand, there's also the TCP port `22`, which you must keep open in the firewall to allow yourself SSH access into all your VMs. Also, you need to give all your VMs access to the TCP port `3493` in the Proxmox VE host, so they can connect to the NUT server monitoring the UPS in your system.

Now that you know the ports required by K3s, you may wonder how these ports will be arranged in the network interface cards enabled in your VMs. Check it out below.

- On SERVER nodes:
    - NIC `net0`/`ens18`, IP `192.168.1.x`:
        - TCP: `22`, `6443`.
    - NIC `net1`/`ens19`, IP `10.0.0.x`:
        - TCP: `2379-2380`, `6443`, `10250`.

- On AGENT nodes:
    - NIC `net0`/`ens18`, IP `192.168.1.x`:
        - TCP: `22`, `80`, `443`.
    - NIC `net1`/`ens19`, IP `10.0.0.x`:
        - TCP: `10250`.

Remember that each NIC is meant for a particular use:

- The `net0`/`ens18` interfaces are the firewalled ones facing the external network. You'll configure your K3s cluster to use these ones only for external traffic.

- The `net1`/`ens19` interfaces are not firewalled but isolated through the vmbr1 bridge. Your K3s cluster will used these NICs for its internal networking needs.

The upshot is that you'll need to open in your Proxmox VE firewall only the ports required on the `net0`/`ens18` interfaces. Also, you'll need to give your VMs explicit access to the `3493` TCP port.

### _Firewall configuration for the K3s node VMs_

Now that you have the ports setup visualized, let's get down to it. The process is like what you did in the [**G022** guide](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md#opening-the-upsd-port-on-the-proxmox-ve-node), where you gave your first Debian VM access to the NUT TCP port `3493` at the Proxmox VE host. This time you'll handle more ports and IPs.

#### **Allowing access to the host's NUT port for all K3s nodes VMs**

To give your VMs access to the NUT server running in your Proxmox VE host, you just have to include their main IPs to the IP set you already allowed to reach the NUT port.

1. Open your Proxmox VE web console and go to the `Datacenter`, then to `Firewall > Alias`. There you must add the IPs of your VMs' `net0` NICs, the `192.168.1.x` ones. The view should end looking like below.

    ![Alias created for VMs net0 IPs at Datacenter Firewall](images/g025/pve_datacenter_firewall_alias_updated.png "Alias created for VMs net0 IPs at Datacenter Firewall")

    Remember that you created, back in the [**G022** guide](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md), the alias `debiantpl_net0` you see already listed here.

2. Browse now to the `Datacenter > Firewall > IPSet` tab, where you'll find the already existing `k3s_nodes_net0_ips` IP set.

    ![Datacenter IPSet view before adding new IPs](images/g025/pve_datacenter_firewall_ipset_initial.png "IPSet view before adding new IPs")

3. Select the `k3s_nodes_net0_ips` set, where you'll see the `debiantpl_net0` alias already added there. Since it's the IP of the first Debian VM template you've created, and VM templates can't be run, you can remove the `debiantpl_net0` alias from this IP set by pressing the `Remove` button.

    ![Removing the debiantpl_net0 alias](images/g025/pve_datacenter_firewall_ipset_debiantpl_net0_removal.png "Removing the debiantpl_net0 alias")

    You'll have to confirm the action.

    ![Confirmation of debiantpl_net0 removal](images/g025/pve_datacenter_firewall_ipset_debiantpl_net0_removal_confirm.png "Confirmation of debiantpl_net0 removal")

4. Now, using the `Add` button, aggregate to the `k3s_nodes_net0_ips` IP set the other aliases you've created before. The IP set should end looking like below.

    ![IPSet edited with the newly aliased IPs](images/g025/pve_datacenter_firewall_ipset_edited.png "IPSet edited with the newly aliased IPs")

The connection of your VMs with the NUT server should be enabled now. Check it out with a NUT client command like `upsc apc@192.168.1.107`. Or go back to the [G004](G004%20-%20Host%20configuration%2002%20~%20UPS%20management%20with%20NUT.md) or [G022](G022%20-%20K3s%20cluster%20setup%2005%20~%20Connecting%20the%20VM%20to%20the%20NUT%20server.md) guides to remember how to use the NUT-related commands.

#### **K3s node VMs' firewall setup**

1. Browse back to the `Datacenter > Firewall > Alias` tab. In this page, add the whole IP range of your local network (`192.168.1.0/24`). The `Alias` view should end looking like in the next snapshot.

    ![Alias created for local network IPs at Datacenter Firewall](images/g025/pve_datacenter_firewall_alias_updated_local_network.png "Alias created for VMs net1 IPs at Datacenter Firewall")

2. Go to the `Datacenter > Firewall > IPSet` page and create an IP set for the local network IPs, called `local_network_ips`. In it, add the `local_network` alias.

    ![New IP set added for local network IPs](images/g025/pve_datacenter_firewall_ipset_local_network.png "New IP set added for local network IPs")

    I could have used just the `local_network` alias directly for creating rules, but it's better to use sets, even for just one alias or IP, since they give you more flexibility to manipulate IPs within the sets.

3. Now jump to the `Datacenter > Firewall > Security Group` page. Here you'll define all the rules to give access to the ports you need open in your K3s cluster, in this case only the ones on your VM's `net0` interfaces. Next, I'll detail the rules, but organized in two distinct security groups.

    - `k3s_srvrs_net0_in`:
        - Rule 1: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `local_network_ips`, Dest. port `22`, Comment `SSH standard port open for entire local network`.

    - `k3s_agnts_net0_in`:
        - Rule 1: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `local_network_ips`, Dest. port `22`, Comment `SSH standard port open for entire local network`.
        - Rule 2: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `local_network_ips`, Dest. port `80`, Comment `HTTP standard port open for entire local network`.
        - Rule 3: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `local_network_ips`, Dest. port `443`, Comment `HTTPS standard port open for entire local network`.

    Don't mind the rules numbers, it just for your reference when you read them. Their numbering will be different when you add them in the security groups, and they should end looking like in the following snapshots.

    ![Security group rules for K3s server nodes net0 NIC](images/g025/pve_datacenter_firewall_security_group_k3s_servers_accept_in_net0.png "Security group rules for K3s server nodes net0 NIC")

    ![Security group rules for K3s agent nodes net0 NIC](images/g025/pve_datacenter_firewall_security_group_k3s_agents_accept_in_net0.png "Security group rules for K3s agent nodes net0 NIC")

    > **BEWARE!**  
    > Don't forget to **enable** the rules when you create them, so revise the `On` column and check the ones you may have left disabled.

    The security groups don't work just as they are, you have to apply them **on each** of your K3s node VMs. In particular, you have to insert the `k3s_srvrs_net0_in` security group in the K3s **server** VM firewall, and put the `k3s_agnts_net0_in` one in your other two K3s **agent** VMs firewalls.

4. Next, I'll show you how the firewall should look in the `k3sserver01` firewall with it's corresponding security group inserted as a rule, after using the `Insert: Security Group` button.

    ![Inserted security group to k3sserver01 node and applied to net0 NIC](images/g025/pve_k3server01_firewall_inserted_security_group_net0.png "Inserted security group to k3sserver01 node and applied to net0 NIC")

    Notice that not only I've inserted and enabled the corresponding `k3s_srvrs_net0_in` group, I've applied it to the `net0` interface of this VM.

5. Browse to the VM's `Firewall > IPSet` page and create an IP set for the `net0` network interface. In the case of the `k3sserver01` VM, it should be like in the following snapshot.

    ![IP set for ip filtering on net0 interface](images/g025/pve_k3server01_firewall_ipset_ipfilter_net0.png "IP set for ip filtering on net0 interface")

    Notice how the IP set's name follows the pattern `ipfilter-netX`, where "X" is the network interface's number in the VM. Keep the name as it is, since it's the one the Proxmox VE firewall expects for IP filtering. Also see how I've added only the aliased IP for the `net0` interface on the IP set, restricting to one the valid IPs that can initiate outgoing connections from that interface.

6. Now you can enable the firewall itself on `k3sserver01`. Go to the VM's `Firewall > Options` tab and `Edit` the `Firewall` field to enable it.

    ![Enabled firewall and IP filter on VM firewall](images/g025/pve_k3server01_firewall_options_enabled_ipfilter.png "Enabled firewall and IP filter on VM firewall")

    Notice that I've also adjusted some other options:

    - The `NDP` option is disabled because is only useful for IPv6 networking, which is not active in your VMs.

    - The `IP filter` is enabled, which helps to avoid IP spoofing.
        - Remember that enabling the option is not enough. You need to specify the concrete IPs allowed on the network interface in which you want to apply this security measure, something you've just done in the previous step.

    - The `log_level_in` and `log_level_out` options are set to `info`, enabling the logging of the firewall on the VM. This allows you to see, in the `Firewall > Log` view of the VM, any incoming or outgoing traffic that gets dropped or rejected by the firewall.

    On the other hand, you must know that the firewall configuration you apply to the VM is saved as a `.fw` file in your Proxmox VE host, under the `/etc/pve/firewall` path. So, open a shell as `mgrsys` on your Proxmox VE host and `cd` to that directory.

    ~~~bash
    $ cd /etc/pve/firewall
    ~~~

    There, execute an `ls` and see what files are there.

    ~~~bash
    $ ls
    2101.fw  cluster.fw
    ~~~

    The `2101.fw` is the firewall configuration for the `k3sserver01` VM, identified in Proxmox VE with the VM ID `2101`. The `cluster.fw` is the file containing the whole Proxmox VE datacenter firewall configuration. If you open the `2101.fw` file, you'll see the following content.

    ~~~properties
    [OPTIONS]

    log_level_in: info
    log_level_out: info
    ndp: 0
    enable: 1
    ipfilter: 1

    [IPSET ipfilter-net0]

    k3sserver01_net0

    [RULES]

    GROUP k3s_srvrs_net0_in -i net0
    ~~~

7. As you've done with your K3s server node, now you have to apply the corresponding security group (`k3s_agnts_net0_in`) and other firewall configuration to the K3s agent node VMs, starting with the `k3sagent01` VM (with ID `3111`). Applying this configuration will generate a `/etc/pve/firewall/3111.fw` file that should look like below.

    ~~~properties
    [OPTIONS]

    enable: 1
    log_level_out: info
    ndp: 0
    ipfilter: 1
    log_level_in: info

    [IPSET ipfilter-net0]

    k3sagent01_net0

    [RULES]

    GROUP k3s_agnts_net0_in -i net0
    ~~~

    This firewall setup for `k3sagent01` is almost identical to the one for `k3sserver01`:

    - The lines under `OPTIONS` might show up ordered differently, as happens above, but they are the same as in the `k3sserver01` VM.

    - There's only one `IPSET` that applies an IP filter on the VM's `net0` network card.

    - The security group in the `GROUP` rules and alias in the `IPSET` directive correspond to the ones corresponding to the agent nodes.

8. Since the firewall configuration for the second K3s agent node is essentially the same as with the first one, instead of using the web console to set up the firewall for the other VM, open a shell as `mgrsys` on your Proxmox VE host and do the following.

    ~~~bash
    $ cd /etc/pve/firewall
    $ sudo cp 3111.fw 3112.fw
    ~~~

    Edit the new `3112.fw` file to replace just the IP alias in the `IPSET` block with the correct one (`k3sagent02_net0`) for the `3112` VM.

    ~~~properties
    [OPTIONS]

    enable: 1
    log_level_out: info
    ndp: 0
    ipfilter: 1
    log_level_in: info

    [IPSET ipfilter-net0]

    k3sagent02_net0

    [RULES]

    GROUP k3s_agnts_net0_in -i net0
    ~~~

With the necessary ports open for the right IPs, you can now install the K3s software in your VMs. Also remember that it's not necessary to have the VMs running to configure their firewalls, and that the changes in the firewall configuration are put in effect immediately after the rules are enabled.

#### **Port `6443` left closed on the server nodes' `net0` NIC**

I listed the `6443` port as one to be opened in the `net0` network card of your server node. So, why I haven't told you to open it in the firewall already? This port, on the `net0` NIC of your server nodes, is meant to be open only for external clients from which you'll manage remotely your K3s cluster. I'll explain how to set up such a client in the upcoming [**G026** guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md), where you'll open the `6443` port on your server node accordingly.

## Considerations before installing the K3s cluster nodes

To install the K3s software on any node, the procedure is essentially the same: you have to download and run a small executable and it will do everything to install and start the `k3s` service. The question is that, before you install the K3s software, you must plan in advance how you want to configure your cluster. This is because you'll not only configure the K3s service itself, but also which embedded services it'll (or won't) deploy from the start and how those will run in your K3s cluster. In other words, the initial configuration determines how the K3s cluster and its services are configured, and reconfiguring all of it later can be a more complicated matter.

On the other hand, the K3s service installer supports two ways of being configured: by using arguments like any other command, or reading its settings from a configuration file. In this guide, I'll show you how to do it with the configuration file.

### _The K3s installer's configuration file_

By default, the K3s installer looks for the `/etc/rancher/k3s/config.yaml` file in the system, although you can specify another path with the `--config` or `-c` argument.

Another aspect you must be aware of is that the K3s installer arguments **take precedence** over the parameters set in the file. So, careful of using the same argument both in the command and in the `config.yaml` file, **only the command's value will stand**.

## K3s Server node setup

The very first nodes you must install in a Kubernetes cluster are the **master** ones. These are called **servers** in K3s jargon, and you'll setup one for your cluster.

### _Folder structure for K3s configuration files_

In your K3s cluster server node (`k3sserver01`), execute the following.

~~~bash
$ sudo mkdir -p /etc/rancher/k3s/ /etc/rancher/k3s.config.d/
~~~

Notice that I've created two folders, the `/etc/rancher/k3s/` expected by K3s by default and the `/etc/rancher/k3s.config.d/`. The idea is to put your own configuration files in the `k3s.config.d` directory and symlink them in the `k3s` one. This is convenient because, if you happen to uninstall the K3s software for some reason, the uninstaller also removes the `/etc/rancher/k3s/` folder completely.

### _Enabling graceful shutdown on the server node_

Since the release `1.21`, the graceful node shutdown capacity is available (as beta for now) in Kubernetes, and you can use it in your K3s cluster. This way, you can protect better your cluster nodes against unexpected failures or just ensuring that, when your Proxmox VE host shuts down, your nodes also shutdown but in a graceful manner.

To configure this functionality in your cluster, you need to setup a configuration file with two specific parameters and, optionally, a system service for cleaning up any Kubernetes pods that could get stuck in shutdown phase.

#### **The `kubelet.config` file**

The configuration file you need to enable the graceful node shutdown can be called anything and be on any path accessible by the K3s service. So, let's use the folder structure created before and create in it the required file with a significant name.

1. Create a `kubelet.config` file at `/etc/rancher/k3s.config.d`, and then symlink it in the `/etc/rancher/k3s` folder.

    ~~~bash
    $ sudo touch /etc/rancher/k3s.config.d/kubelet.config
    $ sudo ln -s /etc/rancher/k3s.config.d/kubelet.config /etc/rancher/k3s/kubelet.config
    ~~~

    The file is named `kubelet.config` because it affects the configuration of the kubelet process thar runs on each node of any Kubernetes cluster. Symlinking this file is not really necessary, its just a manner of keeping all the configuration files accesible through the same default K3s folder for coherence.

2. In the `kubelet.config` file, put the following lines.

    ~~~yaml
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

    A few highlight from the yaml above.

    - `apiVersion`: the Kubernetes API used here is the beta one (`v1beta1`).

    - `kind`: indicates the type of Kubernetes object specified in the file. In this case is a `KubeletConfiguration`, meant to be used for configuring the kubelet process that any Kubernetes node has running.

    - `shutdownGracePeriod`: default value is `0`. Total delay period of the node's shutdown, which gives the regular pods this time MINUS the period specified in the `shutdownGracePeriodCriticalPods` parameter.

    - `shutdownGracePeriodCriticalPods`: default value is `0`. This is the grace period conceded only to pods marked as critical. This value has to be lower than `shutdownGracePeriod`.

    - Both the `shutdownGracePeriod` and the `shutdownGracePeriodCriticalPods` must be set to **non-zero** values to enable the graceful shutdown functionality.

    - With the values set in the yaml above, the node will have `20` seconds to terminate all regular pods running in it, and `10` to end the critical ones.

#### **Cleanup pods script**

It might be that some pods don't shutdown in time and get stuck with the `Shutdown` status, and could reappear as dead unevicted pods in your cluster after a reboot. To clean them up, you can prepare a system service in your server node that can get rid of them.

1. Create the `k3s-cleanup.service` file at `/lib/systemd/system/`.

    ~~~bash
    $ sudo touch /lib/systemd/system/k3s-cleanup.service
    ~~~

2. Put the next content in the `k3s-cleanup.service` file.

    ~~~properties
    [Unit]
    Description=k3s-cleanup
    StartLimitInterval=200
    StartLimitBurst=5
    Wants=k3s.service

    [Service]
    Type=oneshot
    ExecStart=kubectl delete pods --field-selector status.phase=Failed -A --ignore-not-found=true
    RemainAfterExit=true
    User=root
    StandardOutput=journal
    Restart=on-failure
    RestartSec=30

    [Install]
    WantedBy=multi-user.target
    ~~~

    Notice how, in the `ExecStart` parameter, the service invokes a `kubectl` command. You don't have it installed in the server node, so you can't enable this service yet until you install the K3s software in the node.

### _The `k3sserver01` node's `config.yaml` file_

As I've already told you before, the `/etc/rancher/k3s/config.yaml` file is the one the K3s installer will try to read by default.

1. Create the `config.yaml` file as follows.

    ~~~bash
    $ sudo touch /etc/rancher/k3s.config.d/config.yaml
    $ sudo ln -s /etc/rancher/k3s.config.d/config.yaml /etc/rancher/k3s/config.yaml
    ~~~

    Notice how the `config.yaml` file is symlinked into the `/etc/rancher/k3s` folder, so the K3s installer can find it.

2. You'll also need some basic networking information from the VM itself, which you can get with the `ip` command.

    ~~~bash
    $ ip a
        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
            inet 127.0.0.1/8 scope host lo
               valid_lft forever preferred_lft forever
        2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP group default qlen 1000
            link/ether f6:26:b3:ce:76:a6 brd ff:ff:ff:ff:ff:ff
            altname enp0s18
            inet 192.168.1.21/24 brd 192.168.1.255 scope global dynamic ens18
               valid_lft 73731sec preferred_lft 73731sec
        3: ens19: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq state UP group default qlen 1000
            link/ether 5a:b0:5f:41:3c:48 brd ff:ff:ff:ff:ff:ff
            altname enp0s19
            inet 10.0.0.1/24 brd 10.0.0.255 scope global ens19
               valid_lft forever preferred_lft forever
    ~~~

    The values you must have at hand are the IP for the first interface (`ens18` in the output above), and the IP and name of the second interface (`ens19`).

3. Next, edit the `/etc/rancher/k3s/config.yaml` file by adding the following content.

    ~~~yaml
    # k3sserver01

    cluster-domain: "deimos.cluster.io"
    tls-san:
        - "k3sserver01.deimos.cloud"
    flannel-backend: host-gw
    flannel-iface: "ens19"
    bind-address: "0.0.0.0"
    https-listen-port: 6443
    advertise-address: "10.0.0.1"
    advertise-port: 6443
    node-ip: "10.0.0.1"
    node-external-ip: "192.168.1.21"
    node-taint:
        - "k3s-controlplane=true:NoExecute"
    log: "/var/log/k3s.log"
    kubelet-arg: "config=/etc/rancher/k3s/kubelet.config"
    disable:
        - metrics-server
        - servicelb
    protect-kernel-defaults: true
    secrets-encryption: true
    agent-token: "SomeReallyLongPassword"
    ~~~

    The parameters from the `config.yaml` file above are explained next.

    - `cluster-domain`: specify the base domain name used **internally** in your cluster for assigning DNS records to pods and services. By default is `cluster.local`. If you change it, make it different to the main domain name you may want to use for accessing **externally** the services you'll deploy in your cluster later.

    - `tls-san`: additional hostnames or IPs that will be applied in the self-generated TLS certs of the K3s service, meaning not the ones specified in the `bind-address`, `advertise-address`, `node-ip` or `node-external-ip` parameters. For instance, you could put here the VM's hostname.

    - `flannel-backend`: [Flannel](https://github.com/coreos/flannel) is a plugin for handling the cluster's internal networking. Flannel supports four different network backend methods, being `vxlan` the default one. The `host-gw` backend set in the `config.yaml` above has better performance than `vxlan`, something you really want to have in your rather hardware-constrained K3s cluster. Know more about the Flannel backend options [in this related documentation](https://www.containerlabs.kubedaily.com/rancher/Networking/Networking-with-Flannel.html) and [also here](https://stackoverflow.com/questions/45293321/why-host-gw-of-flannel-requires-direct-layer2-connectivity-between-hosts).
        > **BEWARE!**  
        > The backend you choose for your cluster will affect its performance, sometimes in a big way. For instance, the default `vxlan` proved to be an awful backend for my setup, making services respond not just slowly but erratically even. The solution was to use `host-gw`, which offered a very noticeable good performance. Therefore, be aware that you might need to run some tests to choose the right backend which suits your requirements and your cluster setup.

    - `flannel-iface`: with this parameter you can specify through which interface you want Flannel to run. In this case, I'm making it use the bridged network.

    - `bind-address`: the address on which the K3s api service will listen. By default is already `0.0.0.0` (listening on all interfaces), but I think it's convenient to make it explicit for clarity.

    - `https-listen-port`: the port through which the K3s api service will listen. By default is `6443`, change it if needed (but don't forget to update your firewall rules accordingly!).

    - `advertise-address`: the K3s api server will advertise through this IP to the other nodes in the cluster. See how I've used the IP meant for the bridged network.

    - `advertise-port`: this is the port used only to advertise the api to the other nodes in the cluster. By default takes the value set in the `https-listen-port` parameter.

    - `node-ip`: the internal IP the node uses to advertise itself in the cluster. Again, here I'm using the IP for the bridged network.

    - `node-external-ip`: the public or external IP where the node also advertises itself and through which it offers its services.

    - `node-taint`: a taint is a way used in Kubernetes to mark nodes and other objects with certain characteristics. In this case, with the `k3s-controlplane=true:NoExecute` taint applied, this node will only do control-plane work. Therefore, it won't run any normal workloads, not even deployments for embedded services like Traefik.

    - `log`: the K3s service logs by default in the `/var/log/daemon.log` and the `/var/log/syslog` files. Putting here another file path makes the K3s service to write its log lines there, which helps uncluttering your VM's other log files.

    - `kubelet-arg`: allows you to specify parameters to the kubelet process that runs in this node.
        - `config`: path to a configuration file with parameters overwriting the kubelet defaults. In this case, the file is the one you've configured before to enable the node's graceful shutdown.

    - `disable`: for specifying which embedded components are not to be deployed in the cluster. In this case, you can see that I've disabled two embedded services.
        - `metrics-server`: service for monitoring resources usage. It will be deployed as a regular service rather than an embedded one for adjusting its configuration to the particularities of the network setup used in this guide for the K3s cluster.
        - `servicelb`: this is the default load balancer. In the [**G027** guide](G027%20-%20K3s%20cluster%20setup%2010%20~%20Deploying%20the%20MetalLB%20load%20balancer.md) I'll show you how to deploy a better alternative.

    - `protect-kernel-defaults`: When set, the K3s service will return an error if certain kernel sysctl parameters are different than the defaults required by the kubelet service. You already set those parameters properly in the previous [**G024** guide](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md#setting-up-sysctl-kernel-parameters-for-k3s-nodes).

    - `secrets-encryption`: _experimental argument_. When the node is at rest, it will encrypt any secrets resources created in the cluster using a self-generated AES-CBC encrypted key. This option has to be set when the K3s cluster is created initially, not in a later reconfiguration, or you'll have authentication problems later with your cluster nodes. To know more about this feature, [read here about it](https://rancher.com/docs/k3s/latest/en/advanced/#secrets-encryption-config-experimental).

    - `agent-token`: _experimental argument_. Alternative shared password to be used only by agents to join the cluster.

        > **BEWARE!**  
        This password can be any string, but **all** the server nodes in a multiserver cluster **must** have configured the **same** value.

        Mind that this value is just the password part of what shall become the full agent token. The complete pattern of an agent token is as follows.

        ~~~bash
        K10<sha256 sum of cluster CA certificate>::node:<password>
        ~~~

        The cluster CA certificate is the `/var/lib/rancher/k3s/server/tls/server-ca.crt` file of the server node (or the **first server** in a multiserver cluster). The sha256 sum is already calculated in the first portion of the server token saved in the `/var/lib/rancher/k3s/server/token` file. Alternatively, you can calculate the sha256 sum yourself with the command `sudo sha256sum /var/lib/rancher/k3s/server/tls/server-ca.crt`.

        The `node` is the username used by default for agents, whereas for server nodes the username is `server` (you can see this in the server token string saved in the file `/var/lib/rancher/k3s/server/token`).

### _Installation of your K3s server node_

With the `config.yaml` and other files ready, you can launch the installation of K3s in your VM.

#### **K3s installation command**

The command to execute in the server node is the following.

~~~bash
$ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.22.3+k3s1" sh -s - server
~~~

The command will find the `config.yaml` file in the default path on the VM, and apply it in the installation. Also noticed the following details in the command above.

- `wget`: this is the command that downloads the K3s installer. Instead of saving the executable into a file, `wget` dumps it into the shell output (option `-O` followed by `-`) to be consumed by the following pipe (`|`) command.

- `INSTALL_K3S_VERSION`: with this environment variable you can control what version of K3s you're installing on your system. It's optional and, when omitted altogether, the K3s installer will download and install the lastest release of K3s. To know which releases are available, check the [Releases page of K3s on GitHub](https://github.com/k3s-io/k3s/releases).

- `server`: makes the node run as a server in the cluster.

#### **K3s installation of the server node `k3sserver01`**

1. Execute the installation command on the `k3sserver01` VM.

    ~~~bash
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.22.3+k3s1" sh -s - server
    [INFO]  Using v1.22.3+k3s1 as release
    [INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.22.3+k3s1/sha256sum-amd64.txt
    [INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.22.3+k3s1/k3s
    [INFO]  Verifying binary download
    [INFO]  Installing k3s to /usr/local/bin/k3s
    [INFO]  Skipping installation of SELinux RPM
    [INFO]  Creating /usr/local/bin/kubectl symlink to k3s
    [INFO]  Creating /usr/local/bin/crictl symlink to k3s
    [INFO]  Creating /usr/local/bin/ctr symlink to k3s
    [INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
    [INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
    [INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
    [INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
    [INFO]  systemd: Enabling k3s unit
    Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
    [INFO]  systemd: Starting k3s
    ~~~

2. The installer won't take too long to do its job. Still, give some time to the `k3s.service`, which will start at the end of the installation, to setup itself. Open another shell session to this VM and check with the `kubectl` command the current status of this new K3s server node.

    ~~~bash
    $ sudo kubectl get nodes
    NAME          STATUS     ROLES                  AGE   VERSION
    k3sserver01   NotReady   control-plane,master   14s   v1.22.3+k3s1
    ~~~

    > **BEWARE!**  
    > The AGE column means how **old** is the node since it was created, **not** how long it has been running in the current session.

    At first, it will probably show the `NotReady` status for a moment. This depends on the capabilities given to your VM, so wait a bit and then execute again the `kubectl` command. But this time, lets use `kubectl` with a couple of extra options to get more information about the cluster.

    ~~~bash
    $ sudo kubectl get nodes -o wide
    NAME          STATUS   ROLES                  AGE     VERSION        INTERNAL-IP   EXTERNAL-IP    OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
    k3sserver01   Ready    control-plane,master   2m20s   v1.22.3+k3s1   10.0.0.1      192.168.1.21   Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   containerd://1.5.7-k3s2
    ~~~

    See how now the `k3sserver01` node is `Ready` now. Also notice the roles it has: is not only a `master` of the cluster, but also has a `control-plane` role. This means that it will only worry about managing the cluster, not running workloads, unless the workloads are compatible with the `k3s-controlplane=true:NoExecute` taint given before to this server in the installation. On the other hand, you can verify that the IPs are assigned as expected, the one of the first network interface is the `EXTERNAL-IP` and the one of the second NIC is the `INTERNAL-IP`. Moreover, now you can see other information about the container runtime that is running in the cluster.

3. If at this point the installer hasn't returned the control to the prompt yet, just get ouf of it by pressing `Ctrl+C`.

#### **Enabling the `k3s-cleanup` service**

With the K3s software installed in your server node, you can enable the `k3s-cleanup` service you prepared before for cleaning up automatically any pods that get stuck with a shutdown status after some reboot.

~~~bash
$ sudo systemctl enable k3s-cleanup.service
$ sudo systemctl start k3s-cleanup.service
~~~

Also, check it's status.

~~~bash
$ sudo systemctl status k3s-cleanup.service
● k3s-cleanup.service - k3s-cleanup
     Loaded: loaded (/lib/systemd/system/k3s-cleanup.service; enabled; vendor preset: enabled)
     Active: active (exited) since Sat 2021-11-27 21:11:03 CET; 2s ago
    Process: 4803 ExecStart=kubectl delete pods --field-selector status.phase=Failed -A --ignore-not-found=true (code=exited, status=0/SUCCESS)
   Main PID: 4803 (code=exited, status=0/SUCCESS)
        CPU: 1.135s

Nov 27 21:11:03 k3sserver01 systemd[1]: Starting k3s-cleanup...
Nov 27 21:11:03 k3sserver01 kubectl[4803]: No resources found
Nov 27 21:11:03 k3sserver01 systemd[1]: Finished k3s-cleanup.
~~~

In the command's output, you'll notice that in the last lines you can see the output of the `kubectl` command this service invokes for cleaning up pods. This time there was nothing to clean up, which is expected since you don't have anything running yet in your still incomplete cluster.

This service **can only run on server nodes**, because those are the ones which can fully run the `kubectl` command. I'll explain a bit more about this detail later in this guide.

## K3s Agent nodes setup

The procedure to setup your two remaining VMs as K3s agent nodes is mostly the same as with the server nodes. The few things that change are the parameters specified in the `config.yaml` files and an argument in the installer command.

1. Create the `config.yaml` file for the installer.

    ~~~bash
    $ sudo mkdir -p /etc/rancher/k3s.config.d /etc/rancher/k3s
    $ sudo touch /etc/rancher/k3s.config.d/config.yaml /etc/rancher/k3s.config.d/kubelet.config
    $ sudo ln -s /etc/rancher/k3s.config.d/config.yaml /etc/rancher/k3s/config.yaml
    $ sudo ln -s /etc/rancher/k3s.config.d/kubelet.config /etc/rancher/k3s/kubelet.config
    ~~~

2. Put in the `kubelet.config` the same content as in the server node.

    ~~~yaml
    # Kubelet configuration
    apiVersion: kubelet.config.k8s.io/v1beta1
    kind: KubeletConfiguration

    shutdownGracePeriod: 30s
    shutdownGracePeriodCriticalPods: 10s
    ~~~

3. Edit the `config.yaml` files, being aware of the particular values required on each agent node.

    Content for the `k3sagent01` node.

    ~~~properties
    # k3sagent01

    flannel-iface: "ens19"
    node-ip: "10.0.0.11"
    node-external-ip: "192.168.1.31"
    server: "https://10.0.0.1:6443"
    token: "K10<sha256 sum of server node CA certificate>::node:<PasswordSetInServerNode>"
    log: "/var/log/k3s.log"
    kubelet-arg: "config=/etc/rancher/k3s/kubelet.config"
    protect-kernel-defaults: true
    ~~~

    Content for the `k3sagent02` node.

    ~~~properties
    # k3sagent02

    flannel-iface: "ens19"
    node-ip: "10.0.0.12"
    node-external-ip: "192.168.1.32"
    server: "https://10.0.0.1:6443"
    token: "K10<sha256 sum of server node CA certificate>::node:<PasswordSetInServerNode>"
    log: "/var/log/k3s.log"
    kubelet-arg: "config=/etc/rancher/k3s/kubelet.config"
    protect-kernel-defaults: true
    ~~~

    The `token` value in these two `config.yaml` files is the same for all the agent nodes. Remember how to build it:

    - The `K10` part can be taken directly from the server token saved in the `/var/lib/rancher/k3s/server/token` file at the server node.

    - The `node` string is the username for all the agent nodes.

    - The password is the one defined as `agent-token` in the server node.

4. With the `config.yaml` and `kubelet.config` files ready, you can launch the K3s installer on **both** your `k3sagentXX` VMs.

    ~~~bash
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.22.3+k3s1" sh -s - agent
    ~~~

    Notice that at the end of the command there's an `agent` parameter, indicating that the installer will setup and launch a `k3s-agent.service` which only runs agent worloads.

5. On the server node, run a `watch sudo kubectl get nodes` and monitor how the agents join your cluster.

    ~~~bash
    Every 2.0s: sudo kubectl get nodes -o wide                                                                                             k3sserver01: Sun Nov 28 14:12:33 2021

    NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP    OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
    k3sserver01   Ready    control-plane,master   110m   v1.22.3+k3s1   10.0.0.1      192.168.1.21   Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   containerd://1.5.7-k3s2
    k3sagent01    Ready    <none>                 24s    v1.22.3+k3s1   10.0.0.11     192.168.1.31   Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   containerd://1.5.7-k3s2
    k3sagent02    Ready    <none>                 21s    v1.22.3+k3s1   10.0.0.12     192.168.1.32   Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   containerd://1.5.7-k3s2
    ~~~

    > **BEWARE!**  
    > The new nodes will need some time to appear in the list and reach the `Ready` status.

    The `watch` command executes a command every two seconds by default, and constantly displays its newest output. To get out of this command, use `Ctrl+C`.

6. If the K3s installer on any of your agent nodes doesn't return control to the prompt after that node has reached the `Ready` state, just `Ctrl+C` out of it.

With the agent nodes running, your K3s Kubernetes cluster is completed and will deploy immediately on the agents all the embedded services that is allowed to run initially.

## Understanding your cluster through `kubectl`

Congratulations, your K3s cluster is up and running! Now you'd like to know how to get all the information possible from your cluster, right? In your current setup, the command for managing the cluster and getting all the information is `kubectl`.

- `kubectl help`: lists the commands supported by `kubectl`.
- `kubectl <command> --help`: shows the help relative to a concrete command, for instance `kubectl get --help` will return extensive information about the `get` command.
- `kubectl options`: lists all the options that can be passed to ANY `kubectl` command.
- `kubectl api-resources`: lists the resources supported in the K3s cluster, like nodes or pods.

> **NOTE**  
> Since the help texts can be lenghty, use a `| less` after the commands listed above to have a paginated output, rather than having the text directly dumped in the shell.

In particular, the main command for retrieving information about what's going on in your cluster is `kubectl get`. You've already used it to see the nodes, but you can also see other resources like pods, services and many other. Next I list a few examples to give you an idea of this command's usage.

- `kubectl get pods -Ao wide`: information about the pods running in your cluster. Notice here that only agent nodes are running the pods, since the servers are tainted not to do so.

    ~~~bash
    $ sudo kubectl get pods -Ao wide
    NAMESPACE     NAME                                     READY   STATUS      RESTARTS   AGE    IP          NODE         NOMINATED NODE   READINESS GATES
    kube-system   coredns-85cb69466-9l6ws                  1/1     Running     0          111m   10.42.1.5   k3sagent01   <none>           <none>
    kube-system   local-path-provisioner-64ffb68fd-zxm2v   1/1     Running     0          111m   10.42.1.2   k3sagent01   <none>           <none>
    kube-system   helm-install-traefik-crd--1-bjv95        0/1     Completed   0          111m   10.42.1.3   k3sagent01   <none>           <none>
    kube-system   helm-install-traefik--1-zb5gb            0/1     Completed   1          111m   10.42.1.4   k3sagent01   <none>           <none>
    kube-system   traefik-74dd4975f9-tdv42                 0/1     Running     0          34s    10.42.2.2   k3sagent02   <none>           <none>
    ~~~

    See that each pod has its own IP, and that it has nothing to do with the one defined as internal IP for the cluster.

- `kubectl get services -Ao wide`: information about the services running in your cluster. Be aware that a service could be running in several pods at the same time.

    ~~~bash
    $ sudo kubectl get services -Ao wide
    NAMESPACE     NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
    default       kubernetes   ClusterIP      10.43.0.1      <none>        443/TCP                      112m   <none>
    kube-system   kube-dns     ClusterIP      10.43.0.10     <none>        53/UDP,53/TCP,9153/TCP       112m   k8s-app=kube-dns
    kube-system   traefik      LoadBalancer   10.43.110.37   <pending>     80:30963/TCP,443:32446/TCP   59s    app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik
    ~~~

    See here that each service has its own cluster IP, different from the internal IP (configured in the installation process) and the pods IPs.

- `kubectl get pv -Ao wide`: lists the persistent volumes active in the cluster. See that instead of using the full `persistentvolumes` resource name, I've typed the shortname `pv`. Not all resources have a shortname, something you should check in the list returned by `kubectl api-resources`.

    ~~~bash
    $ sudo kubectl get pv -Ao wide
    No resources found
    ~~~

    At this point, you won't have any persistent volume active in your cluster.

- `kubectl get pvc -Ao wide`: returns the persitent volume clamins (`pvc` is shorthand for `persistentvolumeclaims`) active in the cluster.

    ~~~bash
    $ sudo kubectl get pvc -Ao wide
    No resources found
    ~~~

    Like it happens with the persistent volumes, there won't be any persistent volume claims active in your cluster at this point.

- `kubectl get all -Ao wide`: gives you information of all resources active in your cluster. Since this list can be long, append `| less` to this command to see the output paginated.

    ~~~bash
    $ sudo kubectl get all -Ao wide
    NAMESPACE     NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
    default       kubernetes   ClusterIP      10.43.0.1      <none>        443/TCP                      112m   <none>
    kube-system   kube-dns     ClusterIP      10.43.0.10     <none>        53/UDP,53/TCP,9153/TCP       112m   k8s-app=kube-dns
    kube-system   traefik      LoadBalancer   10.43.110.37   <pending>     80:30963/TCP,443:32446/TCP   59s    app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik
    mgrsys@k3sserver01:~$ sudo kubectl get all -Ao wide
    NAMESPACE     NAME                                         READY   STATUS      RESTARTS   AGE    IP          NODE         NOMINATED NODE   READINESS GATES
    kube-system   pod/coredns-85cb69466-9l6ws                  1/1     Running     0          112m   10.42.1.5   k3sagent01   <none>           <none>
    kube-system   pod/local-path-provisioner-64ffb68fd-zxm2v   1/1     Running     0          112m   10.42.1.2   k3sagent01   <none>           <none>
    kube-system   pod/helm-install-traefik-crd--1-bjv95        0/1     Completed   0          112m   10.42.1.3   k3sagent01   <none>           <none>
    kube-system   pod/helm-install-traefik--1-zb5gb            0/1     Completed   1          112m   10.42.1.4   k3sagent01   <none>           <none>
    kube-system   pod/traefik-74dd4975f9-tdv42                 1/1     Running     0          86s    10.42.2.2   k3sagent02   <none>           <none>

    NAMESPACE     NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
    default       service/kubernetes   ClusterIP      10.43.0.1      <none>        443/TCP                      112m   <none>
    kube-system   service/kube-dns     ClusterIP      10.43.0.10     <none>        53/UDP,53/TCP,9153/TCP       112m   k8s-app=kube-dns
    kube-system   service/traefik      LoadBalancer   10.43.110.37   <pending>     80:30963/TCP,443:32446/TCP   86s    app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik

    NAMESPACE     NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS               IMAGES                                   SELECTOR
    kube-system   deployment.apps/local-path-provisioner   1/1     1            1           112m   local-path-provisioner   rancher/local-path-provisioner:v0.0.20   app=local-path-provisioner
    kube-system   deployment.apps/coredns                  1/1     1            1           112m   coredns                  rancher/mirrored-coredns-coredns:1.8.4   k8s-app=kube-dns
    kube-system   deployment.apps/traefik                  1/1     1            1           86s    traefik                  rancher/mirrored-library-traefik:2.5.0   app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik

    NAMESPACE     NAME                                               DESIRED   CURRENT   READY   AGE    CONTAINERS               IMAGES                                   SELECTOR
    kube-system   replicaset.apps/local-path-provisioner-64ffb68fd   1         1         1       112m   local-path-provisioner   rancher/local-path-provisioner:v0.0.20   app=local-path-provisioner,pod-template-hash=64ffb68fd
    kube-system   replicaset.apps/coredns-85cb69466                  1         1         1       112m   coredns                  rancher/mirrored-coredns-coredns:1.8.4   k8s-app=kube-dns,pod-template-hash=85cb69466
    kube-system   replicaset.apps/traefik-74dd4975f9                 1         1         1       86s    traefik                  rancher/mirrored-library-traefik:2.5.0   app.kubernetes.io/instance=traefik,app.kubernetes.io/name=traefik,pod-template-hash=74dd4975f9

    NAMESPACE     NAME                                 COMPLETIONS   DURATION   AGE    CONTAINERS   IMAGES                                      SELECTOR
    kube-system   job.batch/helm-install-traefik-crd   1/1           110m       112m   helm         rancher/klipper-helm:v0.6.6-build20211022   controller-uid=95e189fc-71b1-4299-928d-17668ca12a33
    kube-system   job.batch/helm-install-traefik       1/1           110m       112m   helm         rancher/klipper-helm:v0.6.6-build20211022   controller-uid=ba1a2858-2044-40a1-8bf0-30d35bd76540
    ~~~

In all those examples you see that I've used the `-Ao wide` options, which are related to the `get` command.

- The `A` is for getting the resources from all the namespaces present in the cluster.
- The `o` is for indicating the format of the output returned by `kubectl get`. The `wide` string just indicates one of the formats available in the command.

Also, don't forget that you can combine those `kubectl` commands with `watch` whenever you need to have a real time monitoring in your shell of the entities running in your cluster.

### _The `kubectl` command has to be executed with `sudo`_

Given how you've set up your cluster, `kubectl` must be executed with `sudo` in the cluster's nodes, otherwise you'll only see the following warning output.

~~~bash
$ kubectl version
WARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml, please start server with --write-kubeconfig-mode to modify kube config permissions
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
~~~

This is because the `kubectl` command embedded in the K3s installation tries to read the kubeconfig file `/etc/rancher/k3s/k3s.yaml`, and this file is protected with `root` rights. This is the safe configuration, but you could change the permissions of the `k3s.yaml` file using the `write-kubeconfig-mode` parameter in the `config.yaml` file as follows.

~~~yaml
...
write-kubeconfig-mode: "0644"
...
~~~

Above you see how you can change the mode of the `k3s.yaml` file, with values used with the `chmod` command. But, again, the **safe** configuration is the default one. The proper thing to do is to access from a remote client that has the `kubectl` command installed and configured in it, something I'll explain you in the upcoming [**G026** guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md).

### _The `kubectl` command doesn't work on pure agent nodes_

For the most part, `kubectl` won't work on pure agent nodes like the ones in your cluster. This is because pure agents are not meant to manage cluster, hence don't have the required server components running within them for such tasks. Without those components, `kubectl` will fail to run. This can be seen already just by executing the `kubectl version` command on any agent node.

~~~bash
$ sudo kubectl version
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.3+k3s1", GitCommit:"61a2aab25eeb97c26fa3f2b177e4355a7654c991", GitTreeState:"clean", BuildDate:"2021-11-04T00:24:35Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
~~~

See that the final output line warns about the server in `localhost:8080` refusing connection, just the component the `kubectl` program needs to work.

You'll be asking yourself, why the `kubectl` command is also installed in the agent nodes? This is because it's embedded in the K3s software, and the installation makes it also available in whichever system K3s gets installed.

## Enabling bash autocompletion for `kubectl`

To make the use of the `kubectl` command a bit easier, you can enable the bash autocompletion in your **server** node, a hack which will help you type `kubectl` commands more agilely.

1. Execute the following only in your **server** node (remember, `kubectl` is useless in the agent nodes).

    ~~~bash
    $ sudo touch /usr/share/bash-completion/completions/kubectl
    $ sudo kubectl completion bash | sudo tee /usr/share/bash-completion/completions/kubectl
    ~~~

2. Then, execute the following `source` command to enable the new bash autocompletion rules.

    ~~~bash
    source ~/.bashrc
    ~~~

## Enabling the `k3s.log` file's rotation

Your `k3s.service` is configured to log in the `/var/log/k3s.log` file in **all** your nodes. The problem you have now is that this file, like any other log file, will grow over time and you'll have to empty it regularly. Instead of doing this manually, you can make the system take care of it automatically by using the `logrotate` service. Apply the following procedure in **all** your cluster nodes.

1. Create the file `/etc/logrotate.d/k3s`.

    ~~~bash
    $ sudo touch /etc/logrotate.d/k3s
    ~~~

2. Edit the `k3s` file by adding the following configuration block to it.

    ~~~bash
    /var/log/k3s.log {
        daily
        rotate 5
        missingok
        notifempty
        dateext
        compress
        delaycompress
    }
    ~~~

    The logrotate directives in the file mean the following.

    - `daily`: the log rotation will be done daily.
    - `rotate`: how many times a log file is rotated before is finally deleted.
    - `missingok`: if there's no log file to rotate, it's just ignored rather than provoking an error.
    - `notifempty`: if the current log file is empty, it's not rotated.
    - `dateext`: adds a date extension to the rotated log files, by default it's a string following the `YYYYMMDD` schema.
    - `compress`: logrotate compresses with gzip the rotated log files.
    - `delaycompress`: the previous log to the current one will be rotated but not compressed.

    To know more about the logrotate directives, just check `man logrotate` in any of your cluster nodes.

3. To test that the configuration works, execute the logrotate task manually.

    ~~~bash
    $ sudo logrotate -d /etc/logrotate.d/k3s
    ~~~

    With the `-d` option, the `logrotate` command will do a dry run and also print some debug information, enough to see if there's something wrong with the configuration. The output should look like the following.

    ~~~bash
    WARNING: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.

    reading config file /etc/logrotate.d/k3s
    Reading state from file: /var/lib/logrotate/status
    Allocating hash table for state file, size 64 entries
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state
    Creating new state

    Handling 1 logs

    rotating pattern: /var/log/k3s.log  after 1 days (5 rotations)
    empty log files are not rotated, old logs are removed
    considering log /var/log/k3s.log
    Creating new state
      Now: 2021-11-22 14:53
      Last rotated at 2021-11-22 14:00
      log does not need rotating (log has already been rotated)
    ~~~

    Notice the final line which says that the `log does not need rotating`. This means that, if you execute the same `logrotate` command but without the `-d` parameter, it won't rotate the log at this moment.

## Enabling the `containerd.log` file's rotation

There's another log in the K3s setup that for which you need also to configure its rotation, the file `/var/lib/rancher/k3s/agent/containerd/containerd.log`. Notice that it's an agent node log file, so you'll find it in all your nodes. It's logrotate configuration is essentially the same one applied for the `k3s.log`, and you should also apply this in **all** your cluster nodes.

1. Create the file `/etc/logrotate.d/k3s-containerd`.

    ~~~bash
    $ sudo touch /etc/logrotate.d/k3s-containerd
    ~~~

2. Edit the `k3s-containerd` file by adding the following configuration block to it.

    ~~~bash
    /var/lib/rancher/k3s/agent/containerd/containerd.log {
        daily
        rotate 5
        missingok
        notifempty
        dateext
        compress
        delaycompress
    }
    ~~~

3. Test this new configuration.

    ~~~bash
    $ sudo logrotate -d /etc/logrotate.d/k3s-containerd
    ~~~

## K3s relevant paths

Something you should also know is where the K3s relevant paths are. On all the nodes of your K3s cluster you'll have the two following paths.

- `/etc/rancher`
- `/var/lib/rancher/k3s`

From here on, the differences start between the server and the agent nodes. In the following subsections I list some paths you should be aware of on each node type.

### _K3s paths at SERVER nodes_

#### **Under the `/etc/rancher` folder**

- `/etc/rancher/k3s/k3s.yaml`:  
    Kubeconfig file in which your K3s setup has its cluster, context and credentials defined; in other words, this file is used to configure access to the Kubernetes cluster. By default, this file can only be accessed by the `root` user, forcing you to use `sudo` to execute `kubectl` commands.

- `/etc/rancher/node/password`:
    Randomly generated password for the node, used by agents to register in the cluster (servers also have the agent processes active, since they're also K3s nodes).

#### **Under the `/etc/systemd/system` folder**

- `/etc/systemd/system/k3s.service`:  
    Service script that runs the K3s server node. Like with any other systemd services, you can manage it with `systemctl` commands, for instance `sudo systemctl status k3s.service`.

- `/etc/systemd/system/k3s.service.env`:  
    An associated file for setting environment variables for the `k3s.service`. It's already called by the `k3s.service` script, but the installer creates it empty.

#### **Under the `/var/lib/rancher/k3s` folder**

- `/var/lib/rancher/k3s/agent`:  
    This root-restricted folder is related to agent functionality. Contains configuration files, certificates and manifests.

- `/var/lib/rancher/k3s/data`:  
    Holds the busybox related binaries of command tools that come included with the K3s installation. Also has the configuration for the embedded [strongSwan](https://strongswan.org/) IPsec solution which provides encryption and authentication to the K3s cluster nodes.

- `/var/lib/rancher/k3s/server`:  
    This root-restricted folder is related to server functionality, so you'll only find it in server nodes. Contains configuration files and certificates related to the server functionality like, for instance, the internal database.

- `/var/lib/rancher/k3s/server/token`:  
    File containing a self-generated token used for authenticating when joining the cluster. Is symlinked by a `node-token` file also present in the same folder.

- `/var/lib/rancher/k3s/server/manifests`:  
    Contains the yaml manifests that configure the services and resources which run in a default K3s installation. For instance, here you'll find the manifests that configure the embedded Traefik service running in your K3s cluster.

### _K3s paths at AGENT nodes_

#### **Under the `/etc/rancher` folder**

- `/etc/rancher/node/password`:  
    Randomly generated password for the node, used by agents to register in the cluster.

#### **Under the `/etc/systemd/system` folder**

- `/etc/systemd/system/k3s-agent.service`:  
    Service script that runs the K3s agent node. Like with any other systemd services, you can manage it with `systemctl` commands, for instance `sudo systemctl status k3s-agent.service`.

- `/etc/systemd/system/k3s-agent.service.env`:  
    An associated file for setting environment variables for the `k3s-agent.service`. It's already called by the `k3s-agent.service` script, but the installer creates it empty.

#### **Under the `/var/lib/rancher/k3s` folder**

- `/var/lib/rancher/k3s/agent`:  
    This root-restricted folder is related to agent functionality. Contains configuration files, certificates and manifests.

- `/var/lib/rancher/k3s/data`:  
    Holds the busybox related binaries of command tools that come included with the K3s installation. Also has the configuration for the embedded [strongSwan](https://strongswan.org/) IPsec solution which provides encryption and authentication to the K3s cluster nodes.

## Starting up and shutting down the K3s cluster nodes

In a K3s/Kubernetes cluster you need to apply a certain order to start the whole cluster properly.

- First the server nodes or, at least, one of them.
- Then the agent nodes, but only when you have started at least one server.

And what about the shutting down order? As you may suppose, it's the same but just in reverse: agents first, then the servers. Be sure of always **shut down** (not halting, mind you) the agents first and doing it, of course, gracefully (using the feature you've specifically configured during the K3s installation). If you happen to shut down the servers first, the agents could get hang up waiting for the servers to be available again. This could force you to halt the agent VMs ungracefully, or to kill all the K3s process inside them before proceeding to shut those VMs down. Of course, this is a messy way of stopping the cluster so, again, remember: first the agents, then the servers.

The question now is, do you have to start and shutdown the VMs of your K3s cluster manually every time? Not at all, Proxmox VE has the ability to start your VMs when your host boots up, and even allows you to specify in which order. The VM IDs are also relevant in the order in which the VMs are start or shut down, something I've mentioned you previously in this guide (in the section about link-cloning the VMs to the K3s node VM template). Read the next section to learn about this ordering.

### _Automatic ordered start or shutdown of the K3s nodes VMs_

1. In your Proxmox VE web console, go to your K3s server VM (the `k3sserver01` one) and open its `Options` page.

    ![Start and shutdown options at VM Options page](images/g025/pve_vm_options_start_shutdown_hihglighted.png "Start and shutdown options at VM Options page")

    The two options highlighted above are the ones related to the automatic start and shutdown process managed by Proxmox VE.

2. Select `Start at boot` and then press on the `Edit` button above; you'll see that this option is just a simple checklist field.

    ![Start at boot option edit window](images/g025/pve_vm_options_start_at_boot_edit_window.png "Start at boot option edit window")

    Enable it and press `OK`. Be aware that this action won't start the VM in that moment, it's only marking it to autostart at your host's boot time.

3. Now select the option right below, `Start/Shutdown order`, and `Edit` it too.

    ![Start/Shutdown order option edit window](images/g025/pve_vm_options_start_shutdown_order_edit_window.png "Start/Shutdown order option edit window")

    I'll explain next the three fields of this option.

    - `Start/Shutdown order`: this is an integer number that indicates in which order you want to start AND shutdown this VM. The ordering works as follows:
        - At boot time, **lower** numbers start before _higher_ numbers. So, a VM with order `1` will be booted up by Proxmox VE before another having a `2` or a higher value.
        - At shutdown, **higher** numbers are shutdown by Proxmox VE before _lower_ numbers. So, a VM with order `2` or higher will shutdown _before_ another with any lower value.
        - If two or more VMs have the same value on this field, they'll be ordered among each other by VM ID using the same criteria as with the order value. So, if your K3s nodes have the same order, lets say `1`, the VM with the lower ID will start before another with a higher one.
        - VMs with the default value `any` in this field will always start **after** the ones that have a concrete number set here.
        - The ordering behaviour for VMs that have this value set as `any` is not explicitly explained in the Proxmox VE official documentation, but I think it can be safely assumed that it would be like as if they have the same order value, hence the VM ID can be expected to be the one used as ordering value.

    - `Startup delay`: number of seconds that Proxmox VE must wait before it can boot up the next VM _after_ this one. So, setting this field with a value of 30, it would make Proxmox VE wait 30 seconds till it can start the next VM in order. The default value here is 0 seconds (this is not explicitly detailed in the Proxmox VE documentation).

    - `Shutdown timeout`: number of seconds that Proxmox VE concedes to the VM to shutdown gracefully. If the VM hasn't shutdown by the time this countdown reaches 0, Proxmox VE will halt the VM forcefully. The default value is 180 seconds.

    > **BEWARE!**  
    > The `Start/Shutdown order` option only works among VMs that reside within the same Proxmox VE host. So, if you happened to have a Proxmox VE cluster of two or more nodes (instead of the standalone node setup used in this guide series), this option wouldn't be shared cluster wide, it just works in a node-per-node basis. To have cluster-wide ordering, you have to use the HA (High Availability) manager, which offers its own ways to do such things. Further, VMs managed by HA skip this `Start/Shutdown order` option altogether.

4. So, set the server node with a `Start/Shutdown order` of 1, a `Startup delay` of 10 seconds, and leave the `Shutdown timeout` with the `default` value. Press `OK` and return to the VM's `Options` page.

    ![Start and shutdown options changed for k3sserver01 VM](images/g025/pve_vm_options_start_shutdown_edited.png "Start and shutdown options changed for k3sserver01 VM")

    With the startup delay, which is shown as `up=10` in the `Start/Shutdown order` option, will make Proxmox VE wait 10 seconds before starting up any other VM that may come after this one. This is convenient to give some time to your server to fully start up before it can serve your agents in your K3s cluster.

5. In the other VMs, the two that act as agents of your cluster, you'll have to edit the same options but, this time, just give a higher order number (like 2) to all of them.

    ![Start and shutdown options changed for k3sagent01 VM](images/g025/pve_vm_options_start_shutdown_edited_k3sagent01.png "Start and shutdown options changed for k3sagent01 VM")

    This way, the agent nodes will start in order of VM ID: first the VM 3111, then the VM 3112. And both of them will start **after** the delay of 10 seconds set in the `k3sserver01` node, the VM 2101.

6. Reboot your Proxmox VE host, your only `pve` node in your `Datacenter`, with the `Reboot` button.

    ![Reboot button of the PVE node](images/g025/pve_node_summary_reboot_button.png "Reboot button of the PVE node")

7. After rebooting your Proxmox VE host, get back inside the web console and open the `Tasks` log console at the bottom. There you'll see listed when the VMs start and shutdown tasks started. Pay particular attention to the time difference between the `VM 2101-Start` and the `VM 3111-Start` tasks, you'll see that it's exactly of 10 seconds.

    ![VM start and shutdown tasks at log console](images/g025/pve_tasks_log_start_shutdown_vms.png "VM start and shutdown tasks at log console")

    You'll also see the lines `Start all VMs and Containers` and `Stop all VMs and Containers`, those are the tasks that do begin those two processes.

### _Understanding the shutdown/reboot process of your Proxmox VE host with the K3s cluster running_

When you press the `Shutdown` or the `Reboot` button on the Proxmox VE web console, what you're really doing is sending the corresponding signal to your host to execute those actions. This is the same as executing the `reboot` or `shutdown` commands on a shell in your host, or just pressing the power or reset button on the machine itself. Your VMs also shutdown because they have the Qemu guest agent running, through which they automatically receive the same shutdown signal.

On the other hand, you might be thinking now that the NUT configuration you've done in the VMs is now kind of redundant, since when the UPS kicks in it already provokes a shutdown action of your whole Proxmox VE system, including the VMs. About this, you have to consider that a shutdown provoked by the UPS is something unexpected, so having the NUT clients in your VMs allows you to apply more fine grained behaviours with shell scripts that can be launched whenever some UPS-related event happens.

### _Warning about the Kubernetes graceful shutdown feature_

Bear in mind that this is currently a beta feature, so it could give you surprises. For instance, in my experience with the release `v1.22.3+k3s1` of K3s (the one you've installed in this guide), after a graceful reboot the pods will appear as `Terminated` although they are actually running. This is something you can see with `kubectl` when checking the pods like in the output below.

~~~bash
$ kubectl get pods -n kube-system
NAME                                     READY   STATUS       RESTARTS      AGE
helm-install-traefik-crd--1-bjv95        0/1     Completed    0             30h
helm-install-traefik--1-zb5gb            0/1     Completed    1             30h
local-path-provisioner-64ffb68fd-zxm2v   1/1     Terminated   3 (17m ago)   30h
coredns-85cb69466-9l6ws                  1/1     Terminated   3 (21m ago)   30h
traefik-74dd4975f9-tdv42                 1/1     Terminated   3 (21m ago)   29h
metrics-server-5b45cf8dbb-nv477          1/1     Terminated   1 (21m ago)   28m
~~~

Notice the `STATUS` column. All the pods that appear `Terminated` there are in fact `Running`. How can you tell? The `READY` column informs you that there's 1 out of 1 pods ready (`1/1`) which should be 0 out of 1 if in fact no pod is running. Just be aware of this quirk, kind of unsurprising when using a beta feature.

## Relevant system paths

### _Folders on the Proxmox VE host_

- `/etc/pve/firewall`

### _Files on the Proxmox VE host_

- `/etc/pve/firewall/2101.fw`
- `/etc/pve/firewall/3111.fw`
- `/etc/pve/firewall/3112.fw`
- `/etc/pve/firewall/cluster.fw`

### _Folders on the VMs/K3s nodes_

- `/etc`
- `/etc/bash_completion.d`
- `/etc/logrotate.d`
- `/etc/network`
- `/etc/rancher`
- `/etc/rancher/k3s`
- `/etc/rancher/k3s.config.d`
- `/etc/rancher/node`
- `/etc/sysctl.d`
- `/etc/systemd/system`
- `/home/mgrsys`
- `/home/mgrsys/.ssh`
- `/var/lib/rancher/k3s`
- `/var/lib/rancher/k3s/agent`
- `/var/lib/rancher/k3s/agent/containerd`
- `/var/lib/rancher/k3s/data`
- `/var/lib/rancher/k3s/server`
- `/var/lib/rancher/k3s/server/manifests`
- `/var/lib/rancher/k3s/server/tls`
- `/var/log`

### _Files on the VMs/K3s nodes_

- `/etc/bash_completion.d/kubectl`
- `/etc/logrotate.d/k3s`
- `/etc/network/interfaces`
- `/etc/rancher/k3s/config.yaml`
- `/etc/rancher/k3s/k3s.yaml`
- `/etc/rancher/k3s.config.d/config.yaml`
- `/etc/rancher/node/password`
- `/etc/systemd/system/k3s.service`
- `/etc/systemd/system/k3s.service.env`
- `/home/mgrsys/.google_authenticator`
- `/home/mgrsys/.ssh/authorized_keys`
- `/home/mgrsys/.ssh/id_rsa`
- `/home/mgrsys/.ssh/id_rsa.pub`
- `/var/lib/rancher/k3s/agent/containerd/containerd.log`
- `/var/lib/rancher/k3s/server/token`
- `/var/lib/rancher/k3s/server/tls/server-ca.crt`
- `/var/log/k3s.log`

## References

### _Proxmox VE_

- [Firewall IP sets](https://pve.proxmox.com/wiki/Firewall#pve_firewall_ip_sets)
- [IPFilter vs IPSet](https://forum.proxmox.com/threads/ipfilter-vs-ipset.36127/#post-384591)
- [How to apply proxmox firewall rules to VMs?](https://serverfault.com/questions/801617/how-to-apply-proxmox-firewall-rules-to-vms)
- [How to prevent stealing of (others) IP addresses on KVM/Proxmox based virtualisation hosts?](https://serverfault.com/questions/1030177/how-to-prevent-stealing-of-others-ip-addresses-on-kvm-proxmox-based-virtualisa)
- [Startup Order](https://forum.proxmox.com/threads/startup-order.13629/)
- [Automatic Start and Shutdown of Virtual Machines](https://pve.proxmox.com/pve-docs/chapter-qm.html#qm_startup_and_shutdown)
- [Clean scheduled reboot](https://forum.proxmox.com/threads/clean-scheduled-reboot.38386/)
- [How to shutdown PROXMOX from the command line?](https://www.reddit.com/r/selfhosted/comments/jkmpgt/how_to_shutdown_proxmox_from_the_command_line/)
- [Shutdown VM's and CT's from Proxmox Shutdown Command?](https://www.reddit.com/r/Proxmox/comments/agdfgj/shutdown_vms_and_cts_from_proxmox_shutdown_command/)
- [Proxmox can’t stop VM – How we fix it!](https://bobcares.com/blog/proxmox-cant-stop-vm/)
- [UPS APC to shutdown VMs?](https://forum.proxmox.com/threads/ups-apc-to-shutdown-vms.54695/)

### _Debian and Linux SysOps_

#### **Changing the `Hostname`**

- [How to Change Hostname in Debian](https://linuxhandbook.com/debian-change-hostname/)

#### **Network interfaces configuration**

- [Proxmox VE con Open vSwitch](https://www.doblefactor.com/en/seguridad/proxmox-ve-con-open-vswitch/)
- [IEEE 802.1Q VLAN Tutorial](http://www.microhowto.info/tutorials/802.1q.html)
- [Configure an Ethernet interface as a VLAN trunk (Debian)](http://www.microhowto.info/howto/configure_an_ethernet_interface_as_a_vlan_trunk_on_debian.html)
- [How to configure 802.1Q VLAN Tagging on Debian 9](https://www.snel.com/support/how-to-configure-802-1q-vlan-tagging-on-debian-9/)
- [How To Configure VLAN Interface on Debian 10 (Buster)](https://techviewleo.com/how-to-configure-vlan-interface-on-debian/)
- [Debian: add and configure VLAN](https://docs.gz.ro/debian-linux-vlan.html)
- [How to setup a Static IP address on Debian Linux](https://linuxconfig.org/how-to-setup-a-static-ip-address-on-debian-linux)
- [Howto: Ubuntu Linux convert DHCP network configuration to static IP configuration](https://www.cyberciti.biz/tips/howto-ubuntu-linux-convert-dhcp-network-configuration-to-static-ip-configuration.html)
- [Debian Linux Configure Network Interface Cards – IP address and Netmasks](https://www.cyberciti.biz/faq/howto-configuring-network-interface-cards-on-debian/)
- [For those wanting to play with VLANs](https://forums.virtualbox.org/viewtopic.php?f=1&t=38037)
- [Open vSwitch Documentation about VLANs](https://docs.openvswitch.org/en/latest/faq/vlan/)
- [Configure openvswitch in virtualization environment](https://www.humblec.com/configure-openvswitch-in-virt-environment/)
- [How to setup and save vlans on ethernet](https://askubuntu.com/questions/660506/how-to-setup-and-save-vlans-on-ethernet)
- [Proxmox OVS VLANs any idea how to do ?](https://www.reddit.com/r/Proxmox/comments/7prxig/proxmox_ovs_vlans_any_idea_how_to_do/)

#### **Logrotate configuration**

- [logrotate(8) — Linux manual page](https://www.man7.org/linux/man-pages/man8/logrotate.8.html)
- [How to Setup and Manage Log Rotation Using Logrotate in Linux](https://www.tecmint.com/install-logrotate-to-manage-log-rotation-in-linux/)
- [How to Install and Configure logrotate on Linux](https://www.osradar.com/how-to-install-and-configure-logrotate-on-linux/)

#### **Downloading files with `wget`**

- [Execute Bash Script Directly From a URL](https://www.baeldung.com/linux/execute-bash-script-from-url#installation-and-usage---wget)
- [How to disable HTTP redirect in wget](https://www.xmodulo.com/disable-http-redirect-wget.html)

### _K3s cluster setup_

#### **K3s configuration**

- [Releases](https://github.com/k3s-io/k3s/releases)
- [Installation](https://rancher.com/docs/k3s/latest/en/installation/)
- [Server Configuration Reference](https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/)
- [Agent Configuration Reference](https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config/)
- [Installation Options. Configuration File](https://rancher.com/docs/k3s/latest/en/installation/install-options/#configuration-file)
- [Secrets Encryption Config (Experimental)](https://rancher.com/docs/k3s/latest/en/advanced/#secrets-encryption-config-experimental)
- [Architecture](https://rancher.com/docs/k3s/latest/en/architecture/)
- [Is there any way to bind K3s / flannel to another interface?](https://stackoverflow.com/questions/66449289/is-there-any-way-to-bind-k3s-flannel-to-another-interface)
- [5 Ways to Install K3s](https://www.youtube.com/watch?v=O3s3YoPesKs)
- [Intro to K3s Online Training: Lightweight Kubernetes](https://www.youtube.com/watch?v=vRjk3r9fwFo)
- [K3s – lightweight kubernetes made ready for production – Part 1](https://digitalis.io/blog/kubernetes/k3s-lightweight-kubernetes-made-ready-for-production-part-1/)
- [bash auto-completion on Linux](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)
- [How to Enable kubectl Autocompletion in Bash?](https://www.digitalocean.com/community/questions/how-to-enable-kubectl-autocompletion-in-bash)
- [How to enable kubernetes commands autocomplete](https://stackoverflow.com/questions/53444924/how-to-enable-kubernetes-commands-autocomplete)
- [401 Unauthorized message when joining a single-node cluster](https://github.com/k3s-io/k3s/issues/2463)
- [k3s + Gitlab. Remote Access with kubectl](https://github.com/apk8s/k3s-gitlab#remote-access-with-kubectl)
- [How to Install and Configure K3s on Ubuntu 18.04](https://www.liquidweb.com/kb/how-to-install-and-configure-k3s-on-ubuntu-18-04/)
- [Home Server with k3s](https://www.publish0x.com/awesome-self-hosted/home-server-with-k3s-xdnwrmx)
- [Questions regarding the server node's agent-token parameter](https://github.com/k3s-io/k3s/discussions/3443)
- [Question: Problem setting up k3s in my VPS](https://www.reddit.com/r/k3s/comments/nl85h2/question_problem_setting_up_k3s_in_my_vps/)
- [K3s Network Options](https://rancher.com/docs/k3s/latest/en/installation/network-options/)

#### **Flannel**

- [Flannel Backends](https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md)
- [Networking with Flannel](https://www.containerlabs.kubedaily.com/rancher/Networking/Networking-with-Flannel.html)
- [K3S Supports Container Network Interface (CNI) and Flannel](https://www.henrydu.com/2020/11/16/k3s-cni-flannel/)
- [why host-gw of flannel requires direct layer2 connectivity between hosts?](https://stackoverflow.com/questions/45293321/why-host-gw-of-flannel-requires-direct-layer2-connectivity-between-hosts)
- [Flannel Networking Demystify](https://msazure.club/flannel-networking-demystify/)
- [Configure Kubernetes Network With Flannel](https://dzone.com/articles/configure-kubernetes-network-with-flannel)
- [Configure Kubernetes Network with Flannel](https://appfleet.com/blog/configure-kubernetes-network-with-flannel/)
- [Networking with Flannel](https://www.containerlabs.kubedaily.com/rancher/Networking/Networking-with-Flannel.html)
- [flannel host-gw network](https://hustcat.github.io/flannel-host-gw-network/)
- [Kubernetes the not so hard way with Ansible - Harden the instances - (K8s v1.21)](https://www.tauceti.blog/posts/kubernetes-the-not-so-hard-way-with-ansible-harden-the-instances/)

#### **Graceful Shutdown**

- [Graceful Node Shutdown Goes Beta](https://kubernetes.io/blog/2021/04/21/graceful-node-shutdown-beta/)
- [Graceful node shutdown](https://kubernetes.io/docs/concepts/architecture/nodes/#graceful-node-shutdown)
- [Set Kubelet parameters via a config file](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-config-file/)
- [Graceful Node shutdown Single Node Cluster](https://github.com/k3s-io/k3s/discussions/4319)

#### **Embedded software in K3s**

- [Kubernetes](https://kubernetes.io/)
- [strongSwan](https://strongswan.org/)
- [CoreDNS](https://coredns.io/)
- [Traefik](https://traefik.io/)
- [Traefik on GitHub](https://github.com/traefik/traefik)
- [Kine](https://github.com/k3s-io/kine)
- [SQLite](https://sqlite.org/index.html)
- [Etcd](https://etcd.io/)
- [Etcd K3s version on GitHub](https://github.com/k3s-io/etcd)
- [Containerd](https://containerd.io/)
- [Containerd K3s version on GitHub](https://github.com/k3s-io/containerd)
- [Runc](https://github.com/opencontainers/runc)
- [Flannel](https://github.com/flannel-io/flannel)
- [Flannel on GitHub](https://github.com/flannel-io/flannel)
- [Metrics-server](https://github.com/kubernetes-sigs/metrics-server)
- [Helm-controller](https://github.com/k3s-io/helm-controller)
- [Local-path-provisioner](https://github.com/rancher/local-path-provisioner)

### _YAML_

- [YAML Ain't Markup Language](http://yaml.org/)
- [YAML Tutorial](https://www.tutorialspoint.com/yaml/index.htm)

## Navigation

[<< Previous (**G024. K3s cluster setup 07**)](G024%20-%20K3s%20cluster%20setup%2007%20~%20K3s%20node%20VM%20template%20setup.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G026. K3s cluster setup 09**) >>](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md)
