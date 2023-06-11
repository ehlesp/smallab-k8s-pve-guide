# G908 - Appendix 08 ~ K3s cluster with two or more server nodes

In the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md) you've seen how to create a K3s Kubernetes cluster with just one server node. This works fine and suits the constrained scenario set in this guide series. But if you want a more complete Kubernetes experience, you'll need to know how to set up two or more server nodes in your cluster.

In this supplementary guide I'll summarize you what to add or just do differently on the procedures explained in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md), with the goal of creating a K3s cluster with two server nodes.

> **BEWARE!**  
> You cannot convert a single-node cluster setup that uses the embedded SQLite database into a multiserver one. You'll have to do to a clean new install of the K3s software, although of course you can reuse the same VMs you already have.

## Add a new VM to act as the second server node

The first step is rather obvious: create a new VM and configure it to be the second K3s server node. And by `configure` I mean the following.

1. Create the VM as you created the other ones (by link-cloning the `k3snodetpl` VM template), but:
    - Give it the next `VM ID` number after the one assigned to the first K3s server node. So, if the first server has the ID `201`, assign the ID `202` to this new VM.
    - Follow the same convention for naming this VM, but changing the number in the string. The first server is called `k3sserver01`, so this VM should be called `k3sserver02`.

2. Configure this new `k3sserver02` VM as you did with the first server node VM, although:
    - Assign to its network cards the next IPs in the range reserved for server nodes in your network configuration. If you were using the same IP ranges used in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md):
        - The net0 card should have `192.168.1.22`.
        - The net1 card should have `10.0.0.2`.
    - Change its hostname so its unique and concurs with the name of the VM. So, if the VM is called `k3ssserver02`, its hostname should also be `k3sserver02`.
    - Either import the configuration files for TFA and SSH key-pair from `k3sserver01` or generate new ones for the `mgrsys` user.
        - TFA: `/home/mgrsys/.google_authenticator` file.
        - SSH key-pair: entire `/home/mgrsys/.ssh` folder.
    - Either give the `mgrsys` user the same password as in the first server node or assign it a new one.

## Adapt the Proxmox VE firewall setup

You'll need to add a bunch of extra firewall rules to allow this second server node work properly in your K3s cluster. So open your Proxmox VE web console and do the following.

1. Go the `Datacenter > Firewall > Alias` page, and add a new alias for each of the IPs of your new VM.
    - Name `k3sserver02_net0`, IP `192.168.1.22`.
    - Name `k3sserver02_net1`, IP `10.0.0.2`.

2. Browse to `Datacenter > Firewall > IPSet`, and there:
    - Add the `k3sserver02_net0` alias to the `k3s_nodes_net0_ips` set.
    - Add the `k3sserver02_net1` alias to the `k3s_server_nodes_net1_ips` set.

3. Browse to `Datacenter > Firewall > Security Group`. In this page, add to the `k3s_srvrs_net1_in` group the following rules:
    - Rule 1: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `k3s_srvrs_net1_in`, Dest. port `2379,2380`, Comment `HA etcd server ports for K3s SERVER nodes`.
    - Rule 2: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `k3s_srvrs_net1_in`, Dest. port `6443`, Comment `K3s Kubernetes api server port open internally for K3s SERVER nodes`.
    - Rule 3: Type `in`, Action `ACCEPT`, Protocol `tcp`, Source `k3s_srvrs_net1_in`, Dest. port `10250`, Comment `Kubelet metrics port open internally for K3s SERVER nodes`.
    - Rule 4: Type `in`, Action `ACCEPT`, Protocol `udp`, Source `k3s_srvrs_net1_in`, Dest. port `8472`, Comment `Flannel VXLAN port open internally for K3s SERVER nodes`.

4. Open a shell terminal as `mgrsys` on your Proxmox VE host, then copy the firewall file of the first K3s server VM but giving it the `VM ID` of your second server VM.

    ~~~bash
    $ cd /etc/pve/firewall/
    $ sudo cp 201.fw 202.fw
    ~~~

5. Modify the copy so the IPSET blocks point to the correct IP aliases for the `k3sserver02` node.

    ~~~properties
    [OPTIONS]

    ipfilter: 1
    enable: 1

    [IPSET ipfilter-net0] # Only allow specific IPs on net0

    k3sserver02_net0

    [IPSET ipfilter-net1] # Only allow specific IPs on net1

    k3sserver02_net1

    [RULES]

    GROUP k3s_srvrs_net1_in -i net1
    GROUP k3s_srvrs_net0_in -i net0
    ~~~

## Setup of the FIRST K3s server node

The `/etc/rancher/k3s.config.d/config.yaml` file for the first server node (`k3sserver01`) is just slightly different from the one used in the single-server cluster scenario.

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
disable:
    - metrics-server
    - servicelb
protect-kernel-defaults: true
secrets-encryption: true
agent-token: "SomePassword"
cluster-init: true
~~~

This `config.yaml` file is essentially the same as it was in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md), but just with one extra parameter at the end.

- `cluster-init`: _experimental argument_. Using this option will initialize a new cluster using an embedded **etcd** data source.
    > **BEWARE!**  
    > A K3s cluster with several server nodes won't work just with a sqlite data source. It needs a full database engine to run, such as **etcd**.

With the `config.yaml` file ready, execute the K3s installer.

~~~bash
$ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.21.4+k3s1" sh -s - server
~~~

## Setup of the SECOND K3s server node

### _The `k3sserver02` node's `config.yaml` file_

The `/etc/rancher/k3s.config.d/config.yaml` file for the second server has few, but important, differences.

~~~yaml
# k3sserver02

cluster-domain: "deimos.cluster.io"
tls-san:
    - "k3sserver02.deimos.cloud"
flannel-backend: host-gw
flannel-iface: "ens19"
bind-address: "0.0.0.0"
https-listen-port: 6443
advertise-address: "10.0.0.2"
advertise-port: 6443
node-ip: "10.0.0.2"
node-external-ip: "192.168.1.22"
node-taint:
    - "k3s-controlplane=true:NoExecute"
log: "/var/log/k3s.log"
disable:
    - metrics-server
    - servicelb
protect-kernel-defaults: true
secrets-encryption: true
agent-token: "SamePasswordAsInTheFirstServer"
server: "https://10.0.0.1:6443"
token: "K10<sha256 sum of cluster CA certificate>::server:<password>"
~~~

There's no `cluster-init` option, the `agent-token` is also present here, and two new parameters have been added:

- `agent-token`: this has to be **exactly the same password** as in the first server node.

- `server`: the address or url of a server node in the cluster, in this case the **secondary IP** of the first server. Notice that you also need to specify the port, which in this case is the default `6443`.

- `token`: code for authenticating this server node in an already running cluster. The token is generated and saved within the **first** server node that starts said cluster, in the `/var/lib/rancher/k3s/server/token` file.

#### **Getting the server token from the FIRST server node `k3sserver01`**

With the first server node up and running, let's get the server token you'll need to authorize the joining of any other **server** nodes into the cluster. Use the `cat` command for getting it from `/var/lib/rancher/k3s/server/token` file.

~~~bash
$ sudo cat /var/lib/rancher/k3s/server/token
K10288e77934e06dda1e7523114282478fdc1798545f04235a86b97c71a0bca41f4::server:baecfccac88699f5a12e228e72a69cf2
~~~

As it happens with agent tokens, you can distinguish three parts in a server token string:

- After the `K10` characters, you have the sha256 sum of the `server-ca.cert` file generated in this server node.
- The `server` string is the username.
- The remaining string after the `:` is the password for other server nodes.

### _K3s installation of the SECOND server node `k3sserver02`_

The procedure for your second K3s server node will be as follows.

1. Edit the `/etc/rancher/k3s/config.yaml` file and verify that all its values are correct, in particular the interface and IPs and both the `agent-token` and the `token`. Remember:
    - The `agent-token` must be the same password already set in the first server node.
    - The `token` value is stored within the **first server node**, in the `/var/lib/rancher/k3s/server/token` file.

2. With the `config.yaml` file properly set, launch the installation on of your second server node.

    ~~~bash
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.21.4+k3s1" sh -s - server
    ~~~

3. In your **first server node**, execute the next `watch kubectl` command.

    ~~~bash
    $ watch sudo kubectl get nodes -Ao wide
    ~~~

    Observe the output until you see the new server join the cluster and reach the `Ready` `STATUS`.

    ~~~bash
    Every 2.0s: sudo kubectl get nodes -Ao wide                                                                                              k3sserver01: Thu Jun 10 13:00:01 2021

    NAME          STATUS   ROLES                       AGE     VERSION        INTERNAL-IP   EXTERNAL-IP    OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
    k3sserver01   Ready    control-plane,etcd,master   14h     v1.21.4+k3s1   10.0.0.1      192.168.1.21   Debian GNU/Linux 11 (bullseye)   5.10.0-8-amd64    containerd://1.4.9-k3s1
    k3sserver02   Ready    control-plane,etcd,master   4m46s   v1.21.4+k3s1   10.0.0.2      192.168.1.22   Debian GNU/Linux 11 (bullseye)   5.10.0-8-amd64    containerd://1.4.9-k3s1
    ~~~

    Notice, in the `ROLES` column, the role `etcd` that indicates that the server nodes are running the embedded etcd engine that comes with the K3s installation.

4. When the second server has joined the cluster, get back in your second server node. It's possible that the installer has get stuck and not returned the prompt. Like you have to do when in the installation of the first server node, just press `Ctrl+C` to return to the shell prompt.

## Regarding the K3s agent nodes

The agent nodes are installed with exactly the same `config.yaml` file and command you already saw in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md). The only thing you might consider to change is to make each of your agent nodes point to different server nodes (the `server` parameter in their `config.yaml` file). Since the server nodes are always synchronized, it shouldn't matter to which one each agent is connected to.

## Navigation

[<< Previous (**G907. Appendix 07**)](G907%20-%20Appendix%2007%20~%20Resizing%20a%20root%20LVM%20volume.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G909. Appendix 09**) >>](G909%20-%20Appendix%2009%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md)
