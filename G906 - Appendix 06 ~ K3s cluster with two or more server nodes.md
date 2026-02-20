# G906 - Appendix 06 ~ K3s cluster with two or more server nodes

- [Real Kubernetes clusters have more than one server node](#real-kubernetes-clusters-have-more-than-one-server-node)
- [Add a new VM to act as the second server node](#add-a-new-vm-to-act-as-the-second-server-node)
- [Adapt the Proxmox VE firewall setup](#adapt-the-proxmox-ve-firewall-setup)
- [Setup of the FIRST K3s server node](#setup-of-the-first-k3s-server-node)
- [Setup of the SECOND K3s server node](#setup-of-the-second-k3s-server-node)
  - [The `k3sserver02` node's `config.yaml` file](#the-k3sserver02-nodes-configyaml-file)
    - [Getting the server token from the FIRST server node `k3sserver01`](#getting-the-server-token-from-the-first-server-node-k3sserver01)
  - [K3s installation of the SECOND server node `k3sserver02`](#k3s-installation-of-the-second-server-node-k3sserver02)
- [Regarding the K3s agent nodes](#regarding-the-k3s-agent-nodes)
- [References](#references)
  - [K3s](#k3s)
- [Navigation](#navigation)

## Real Kubernetes clusters have more than one server node

In the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md) you have seen how to create a K3s Kubernetes cluster with just one server node. This works fine and suits the constrained scenario of this guide. But if you want a more complete Kubernetes experience, you need to know how to set up two or more server nodes in your cluster.

This appendix chapter summarizes what to add or just do differently on the procedures explained in the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md), with the goal of creating a K3s cluster with two server nodes.

> [!IMPORTANT]
> **You cannot reuse the single-node cluster built with this guide**\
> You cannot convert a single-node cluster setup that uses the embedded SQLite database into a multiserver one. You have to do a clean new install of the K3s software, although you can reuse the VMs you already have.

## Add a new VM to act as the second server node

The first step is rather obvious: create a new VM and configure it to be the second K3s server node. And by `configure` I mean the following.

1. Create a new K3s server node VM by link-cloning the `k3snodetpl` VM template, but:

    - Give it the next `VM ID` number after the one assigned to the first K3s server node:\
      The first server has the ID `411`, so assign the ID `412` to this new VM.

    - Follow the same convention for naming this VM, but changing the number in the string:\
      The first server is called `k3sserver01`, so the new VM should be called `k3sserver02`.

2. Configure this new `k3sserver02` VM as you did with the first server node VM, although:

    - Assign to its network cards the next IPs in the range reserved for server nodes in your network configuration:\
      If you were using the same IP ranges used in the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#criteria-for-ips):

      - The net0 card should have `10.4.1.2`.
      - The net1 card should have `172.16.1.2`.

    - Change its hostname so its unique and concurs with the name of the VM:\
      If the VM is called `k3ssserver02`, its hostname should also be `k3sserver02`.

    - Either import the configuration files for TFA and SSH key-pair from `k3sserver01` or generate new ones for the `mgrsys` user:

      - TFA: `/home/mgrsys/.google_authenticator` file.
      - SSH key-pair: entire `/home/mgrsys/.ssh` folder.

    - Either give the `mgrsys` user the same password as in the first server node (convenient, but not recommended) or assign it a new one.

## Adapt the Proxmox VE firewall setup

You will need to add a bunch of extra firewall rules to allow this second server node work properly in your K3s cluster. So open your Proxmox VE web console and do the following:

1. Go the `Datacenter > Firewall > Alias` page, and add a new alias for the IP of your new VM's primary NIC:

    - Name `k3sserver02_net0`, IP `10.4.1.2`.

2. Browse to `Datacenter > Firewall > IPSet`, and there:

    - Add the `k3sserver02_net0` alias to the `k3s_nodes_net0_ips` set.

3. Open a shell terminal as `mgrsys` on your Proxmox VE host, then copy the firewall file of the first K3s server VM but giving it the `VM ID` of your second server VM:

    ~~~sh
    $ cd /etc/pve/firewall/
    $ sudo cp 411.fw 412.fw
    ~~~

4. Modify the `412.fw` file so the IPSET blocks point to the correct IP aliases for the `k3sserver02` node:

    ~~~properties
    [OPTIONS]

    enable: 1
    ndp: 0
    log_level_out: info
    ipfilter: 1
    log_level_in: info

    [IPSET ipfilter-net0]

    dc/k3sserver02_net0

    [RULES]

    GROUP k3s_srvrs_net0_in -i net0
    ~~~

## Setup of the FIRST K3s server node

The `/etc/rancher/k3s.config.d/config.yaml` file for the first server node (`k3sserver01`) is just slightly different from the one used in the single-server cluster scenario:

~~~yaml
# k3sserver01

cluster-domain: "homelab.cluster"
tls-san:
    - "k3sserver01.homelab.cloud"
    - "10.4.1.1"
flannel-backend: host-gw
flannel-iface: "ens19"
bind-address: "0.0.0.0"
https-listen-port: 6443
advertise-address: "172.16.1.1"
advertise-port: 6443
node-ip: "172.16.1.1"
node-external-ip: "10.4.1.1"
node-taint:
    - "node-role.kubernetes.io/control-plane=true:NoSchedule"
kubelet-arg: "config=/etc/rancher/k3s/kubelet.conf"
disable:
    - metrics-server
    - servicelb
protect-kernel-defaults: true
secrets-encryption: true
agent-token: "SomeReallyLongPassword"
cluster-init: true
~~~

This `config.yaml` file is essentially the same as it is set for the `K3sserver01` node in the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file), but just with one extra parameter at the end:

- `cluster-init`\
  Using this option will initialize a new cluster that will run with an embedded Etcd data source.

    > [!IMPORTANT]
    > **A K3s cluster with several server nodes will not work just with a sqlite data source**\ > "Fully fledged" K3s clusters require more advanced database engines to run, such as Etcd.

With the `config.yaml` file ready, execute the K3s installer.

~~~sh
$ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.33.4+k3s1" sh -s - server
~~~

## Setup of the SECOND K3s server node

### The `k3sserver02` node's `config.yaml` file

The `/etc/rancher/k3s.config.d/config.yaml` file for the second server has few, but important, differences.

~~~yaml
# k3sserver02

cluster-domain: "homelab.cluster"
tls-san:
    - "k3sserver02.homelab.cloud"
    - "10.4.1.2"
flannel-backend: host-gw
flannel-iface: "ens19"
bind-address: "0.0.0.0"
https-listen-port: 6443
advertise-address: "172.16.1.2"
advertise-port: 6443
node-ip: "172.16.1.2"
node-external-ip: "10.4.1.2"
node-taint:
    - "node-role.kubernetes.io/control-plane=true:NoSchedule"
kubelet-arg: "config=/etc/rancher/k3s/kubelet.conf"
disable:
    - metrics-server
    - servicelb
protect-kernel-defaults: true
secrets-encryption: true
agent-token: "SamePasswordAsInTheFirstServer"
server: "https://172.16.1.1:6443"
token: "K10<sha256 sum of cluster CA certificate>::server:<password>"
~~~

There's no `cluster-init` option, the `agent-token` is also present here, and two new parameters have been added:

- `agent-token`\
  This has to be **exactly the same password** as in the first server node.

- `server`\
  The address or url of a server node in the cluster, in this case **the IP of the secondary NIC** of the first server node. Notice that you also need to specify the port, which in this case is the default `6443`.

- `token`\
  Shared secret for authenticating this second server node in an already running cluster. The token is generated and saved **within the first server node** that starts said cluster, in the `/var/lib/rancher/k3s/server/token` file.

#### Getting the server token from the FIRST server node `k3sserver01`

With the first server node up and running, obtain from it the server token you will need to authorize the joining of any other server nodes into your K3s cluster. Use the `cat` command for getting it from the `/var/lib/rancher/k3s/server/token` file that should exist in the `k3sserver01` VM :

~~~sh
$ sudo cat /var/lib/rancher/k3s/server/token
K10288e77934e06dda1e7523114282478fdc1798545f04235a86b97c71a0bca41f4::server:baecfccac88699f5a12e228e72a69cf2
~~~

As it happens with agent tokens, you can distinguish three parts in a server token string:

- After the `K10` characters, you have the sha256 sum of the `server-ca.cert` file generated in this first server node.
- The `server` string is the username that identifies all server nodes in the cluster.
- The remaining string after the `:` is the password shared by all server nodes in the cluster.

### K3s installation of the SECOND server node `k3sserver02`

The procedure for your second K3s server node will be as follows.

1. Edit the `/etc/rancher/k3s/config.yaml` file and verify that all its values are correct, in particular the interface and IPs and both the `agent-token` and the `token`. Remember:

    - The `agent-token` must be the same password already set in the first server node.
    - The `token` value is stored within the **first server node**, in the `/var/lib/rancher/k3s/server/token` file.

2. With the `config.yaml` file properly set, launch the installation of your second server node:

    ~~~sh
    $ wget -qO - https://get.k3s.io | INSTALL_K3S_VERSION="v1.33.4+k3s1" sh -s - server
    ~~~

3. In your **first server node**, execute the next `watch kubectl` command:

    ~~~sh
    $ watch sudo kubectl get nodes -Ao wide
    ~~~

    Observe the output until you see the new server join the cluster and reach the `Ready` `STATUS`.

    ~~~sh
    Every 2.0s: sudo kubectl get nodes -Ao wide                                                                                              k3sserver01: Thu Feb 20 12:00:01 2026

    NAME          STATUS   ROLES                  AGE    VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
    k3sserver01   Ready    control-plane,master   163d   v1.33.4+k3s1   172.16.1.1    10.4.1.1      Debian GNU/Linux 13 (trixie)   6.12.73+deb13-amd64   containerd://2.1.5-k3s1
    k3sserver02   Ready    control-plane,master   5m32s  v1.33.4+k3s1   172.16.1.2    10.4.1.2      Debian GNU/Linux 13 (trixie)   6.12.73+deb13-amd64   containerd://2.1.5-k3s1
    ~~~

    Notice, in the `ROLES` column, the role `etcd` that indicates that the server nodes are running the embedded etcd engine that comes with the K3s installation.

## Regarding the K3s agent nodes

The agent nodes are installed with exactly the same `config.yaml` file and command you already saw in the [chapter **G025**](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#k3s-agent-nodes-setup). The only thing you might consider to change is to make each of your agent nodes point to different server nodes (the `server` parameter in their `config.yaml` file). Since the server nodes are always synchronized, it should not matter to which one each agent is connected to.

## References

### [K3s](https://k3s.io/)

- [Docs](https://docs.k3s.io/)
  - [CLI Tools. server](https://docs.k3s.io/cli/server)

## Navigation

[<< Previous (**G905. Appendix 05**)](G905%20-%20Appendix%2005%20~%20Resizing%20a%20root%20LVM%20volume.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G907. Appendix 07**) >>](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md)
