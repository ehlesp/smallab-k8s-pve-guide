# G036 - Host and K3s cluster ~ Monitoring and diagnosis

In this guide I'll give you some ideas and show you a couple of commands to help you monitoring and make diagnosis of your K3s Kubernetes cluster and the containers it runs.

## Monitoring resources usage

I'll remind you here all the tools you have to monitor the usage of resources in your system.

- Proxmox VE has a `Summary` view on all its levels (datacenter, node and virtual machine) in which it shows how the usage of resources is going. On the other hand, the web console offers a page for each storage unit configured in the system.

- Don't forget shell commands like `htop`, `df` or `free` that will give you a different point of view of the resources usages from a "closer" distance of your host or VMs. For instance, in the nodes of your K3s cluster, you'll see with `htop` many lines related to the K3s service running in them and also about the containerd service that executes your Kubernetes containers.

- To see how your Kubernetes nodes and pods fare about CPU and RAM usage, either you can:
    - Use the `kubectl top` command from your `kubectl` client system. For instance, you could see the usages of your Nexcloud platform's pods.

        ~~~bash
        $ kubectl top pod -n nextcloud 
        NAME                                CPU(cores)   MEMORY(bytes)   
        nxcd-cache-redis-68984788b7-xtzvl   3m           4Mi             
        nxcd-db-mariadb-0                   1m           93Mi            
        nxcd-server-apache-nextcloud-0      1m           51Mi
        ~~~

        Notice that `top pod` requires specyfing the namespace, while `top node` doesn't (cluster nodes are not namespaced).

    - Use the Kubernetes Dashboard, which you deployed and browsed into in the [**G030** guide](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md).

## Checking the logs

Logs are specially useful when you need to diagnose issues in a system. I'll highlight the most relevant logs you'll have in your setup at this point.

- The Proxmox VE host is a Debian system, so its logs are all found in the `/var/log` directory. From all the files you can find there, pay particular attention to the following ones.
    - `daemon.log`: usually you'll only see daemons or system services related lines in this file, but don't forget it when you have to deal with hard-to-determine issues.
    - `kern.log`: here you'll see device-related logs, so if you happen to detect issues with the virtual devices of your VMs, you can start checking them out here.
    - `pve-firewall.log`: here is where the Proxmox VE's firewall writes all of its logs, including the ones related to your virtual machines. Very important to revise it when you detect networking issues with your containers, like blocked traffic to certain ports. You can see this log also in the web console:
        - At the `pve` node level, in the `Firewall > Log` view, you'll see all the lines written in the log.
        - At each VM you also have a `Firewall > Log` view, but it will only show the lines related to the current VM.
    - `syslog`: is a combination of the `daemon.log` and the `kern.log` files, and you can also see this file at the `pve` node level of your web console, at the `System > Syslog` page.

- The VMs you've setup as K3s nodes they're all Debian systems, so their logs are under the `/var/log` path.
    - `daemon.log`: as in the Proxmox VE host, here you'll see daemon or system services log lines and, among them, lines related to the K3s service such as logs informing about containers.
    - `k3s.log`: where the K3s service dumps its logs. You already configured its automated rotation with logrotate back in the [**G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#enabling-the-k3slog-files-rotation).
    - `kern.log`: again, like in your Proxmox VE host, in this file you can find logs related to devices running in a VM. Be aware that the containers you run in your K3s nodes will have their own virtual network devices, and those will appear in this log.
    - `containers`: in a node that runs workloads, like your K3s agent ones, this folder holds the logs of the containers currently running in the virtual machine. More precisely, they are symbolic links to the actual log files found under the path `/var/log/pods`, where they're grouped in folders.
    - `pods`: folder where the logs of the Kubernetes containers are kept. The logs are in folders organized in the following manner.
        - Each pod running in the node has its own folder named following the pattern `<namespace>_<pod's current name>_<cluster-generated UUID>`.
        - Within each pod's folder you'll have one directory per container running in that pod. The containers' logs are inside their corresponding folders.
        - For instance, the Nextcloud platform has three pods with two containers each. The `tree` command would present them like the output below.

            ~~~bash
            .
            ├── nextcloud_nxcd-cache-redis-68984788b7-xtzvl_2de71564-058c-440b-a6ed-554c43d735b8/
            │   ├── metrics/
            │   │   ├── 3.log
            │   │   └── 4.log
            │   └── server/
            │       ├── 3.log
            │       └── 4.log
            ├── nextcloud_nxcd-db-mariadb-0_3fb12838-3555-4247-9d67-7a857c871d31/
            │   ├── metrics/
            │   │   ├── 3.log
            │   │   └── 4.log
            │   └── server/
            │       ├── 3.log
            │       └── 4.log
            └── nextcloud_nxcd-server-apache-nextcloud-0_4e3a16c7-f5e1-42bf-b852-ccaaccd5557d/
                ├── metrics/
                │   ├── 0.log
                │   └── 1.log
                └── server/
                    ├── 0.log
                    └── 1.log
            ~~~

            Notice how there are more than one log files in each container's folder, and that their filenames are just numbers. The higher the number, the more recent the log file is.

    - `syslog`: the same thing as in the Proxmox VE host, although the ones in the VMs are not accessible through the PVE web console.

- You can access a container's log with `kubectl`. For instance, to access the log of your Nextcloud Apache server container you would execute the command next.

    ~~~bash
    $ kubectl logs -n nextcloud nxcd-server-apache-nextcloud-0 server | less
    ~~~

    See how after indicating the `nexcloud` namespace, I've specified the pod's name (`nxcd-server-apache-nextcloud-0`) and then the concrete container (`server`). I've also piped the output to `less` for getting the log paginated. This log is the same one stored in the corresponding `/var/log/pod` path which, at the moment of writing this, was `/var/log/pod/nextcloud_nxcd-server-apache-nextcloud-0_4e3a16c7-f5e1-42bf-b852-ccaaccd5557d/server/0.log`.

## Shell access into your containers

You might face issues you won't be able to understand unless you get inside the containers. To do so, you can open a shell into them with `kubectl`. I'll illustrate you this by getting into the `server` container of the Nextcloud platform's MariaDB instance.

~~~bash
$ kubectl exec -it -n nextcloud nxcd-db-mariadb-0 -c server -- bash
root@nxcd-db-mariadb-0:/#
~~~

> **BEWARE!**  
> You'll log in as `root`, so be careful about what you do inside the container.

I'll explain the command below.

- The `exec` option is for executing commands in containers.

- The `-it` options are for configuring the stdin in the container.

- With `-c` you specify to what container you want to connect to within the specified pod.

- If you don't specify the container, `kubectl` will connect you to the first one listed in the `Deployment`, `ReplicaSet` or `StatefulSet` that deployed the pod.

- Also, be aware that any command you invoke in a container has to be already present in the image the container is running. In the example above, the MariaDB image happens to have the `bash` shell available but other images may only have `sh`.

While inside your MariaDB server container, you can take a look at the files defined and mounted by the `StatefulSet` resource you configured [in the Part 3 of the Nextcloud platform's deployment guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md). You'll find them exactly where their `mountPath`s said they should be. For instance, check the `my.cnf` file.

~~~bash
root@nxcd-db-mariadb-0:/# ls -al /etc/mysql/my.cnf 
lrwxrwxrwx 1 root root 24 Nov 10 01:30 /etc/mysql/my.cnf -> /etc/alternatives/my.cnf
~~~

It's just a symlink to a `/etc/alternatives/my.cnf` file, but it's content should be the one in the file you set in the `ConfigMap` (the one set to be autogenerated by Kustomize).

On the other hand, you can also see how the Nextcloud's MariaDB server has put a bunch of files in the volume set up for it in the K3s agent node in which its container is running. So, open a shell on the node itself (in the guide was the `k3sagent02` one) and just `ls` the folder where the database's volume is mounted (`/mnt/nextcloud-ssd/db/k3smnt/`).

~~~bash
$ ls -al /mnt/nextcloud-ssd/db/k3smnt/
total 198612
drwxr-xr-x 6 systemd-coredump root                  4096 Dec 13 15:59 .
drwxr-xr-x 4 root             root                  4096 Dec  3 14:18 ..
-rw-rw---- 1 systemd-coredump systemd-coredump    417792 Dec 13 14:21 aria_log.00000001
-rw-rw---- 1 systemd-coredump systemd-coredump        52 Dec 13 14:21 aria_log_control
-rw-rw---- 1 systemd-coredump systemd-coredump         9 Dec 13 15:59 ddl_recovery.log
-rw-rw---- 1 systemd-coredump systemd-coredump      4333 Dec 13 14:20 ib_buffer_pool
-rw-rw---- 1 systemd-coredump systemd-coredump  79691776 Dec 13 14:21 ibdata1
-rw-rw---- 1 systemd-coredump systemd-coredump 100663296 Dec 13 15:59 ib_logfile0
-rw-rw---- 1 systemd-coredump systemd-coredump  12582912 Dec 13 15:59 ibtmp1
-rw-rw---- 1 systemd-coredump systemd-coredump         0 Dec 10 18:54 multi-master.info
drwx------ 2 systemd-coredump systemd-coredump      4096 Dec 10 18:54 mysql
-rw-rw---- 1 systemd-coredump systemd-coredump     27640 Dec 10 18:54 mysql-bin.000001
-rw-rw---- 1 systemd-coredump systemd-coredump   8987681 Dec 10 18:54 mysql-bin.000002
-rw-rw---- 1 systemd-coredump systemd-coredump    815877 Dec 10 20:31 mysql-bin.000003
-rw-rw---- 1 systemd-coredump systemd-coredump     64089 Dec 11 14:18 mysql-bin.000004
-rw-rw---- 1 systemd-coredump systemd-coredump       365 Dec 11 20:24 mysql-bin.000005
-rw-rw---- 1 systemd-coredump systemd-coredump     33648 Dec 13 14:20 mysql-bin.000006
-rw-rw---- 1 systemd-coredump systemd-coredump       342 Dec 13 15:59 mysql-bin.000007
-rw-rw---- 1 systemd-coredump systemd-coredump       224 Dec 13 15:59 mysql-bin.index
drwx------ 2 systemd-coredump systemd-coredump     12288 Dec 10 18:55 nextcloud@002ddb
drwx------ 2 systemd-coredump systemd-coredump      4096 Dec 10 18:54 performance_schema
-rw-rw---- 1 systemd-coredump systemd-coredump      1696 Dec 13 15:59 slow.log
drwx------ 2 systemd-coredump systemd-coredump     12288 Dec 10 18:54 sys
~~~

See how all the files are owned by a `systemd-coredump` user and group. But, if you checked them from within the MariaDB container itself, in the default data `/var/lib/mysql/` folder, you would see that they are owned by `mysql`.

~~~bash
root@nxcd-db-mariadb-0:/# ls -al /var/lib/mysql/
total 198612
drwxr-xr-x 6 mysql root       4096 Dec 13 14:59 .
drwxr-xr-x 1 root  root       4096 Nov 10 01:30 ..
-rw-rw---- 1 mysql mysql    417792 Dec 13 13:21 aria_log.00000001
-rw-rw---- 1 mysql mysql        52 Dec 13 13:21 aria_log_control
-rw-rw---- 1 mysql mysql         9 Dec 13 14:59 ddl_recovery.log
-rw-rw---- 1 mysql mysql      4333 Dec 13 13:20 ib_buffer_pool
-rw-rw---- 1 mysql mysql 100663296 Dec 13 14:59 ib_logfile0
-rw-rw---- 1 mysql mysql  79691776 Dec 13 13:21 ibdata1
-rw-rw---- 1 mysql mysql  12582912 Dec 13 14:59 ibtmp1
-rw-rw---- 1 mysql mysql         0 Dec 10 17:54 multi-master.info
drwx------ 2 mysql mysql      4096 Dec 10 17:54 mysql
-rw-rw---- 1 mysql mysql     27640 Dec 10 17:54 mysql-bin.000001
-rw-rw---- 1 mysql mysql   8987681 Dec 10 17:54 mysql-bin.000002
-rw-rw---- 1 mysql mysql    815877 Dec 10 19:31 mysql-bin.000003
-rw-rw---- 1 mysql mysql     64089 Dec 11 13:18 mysql-bin.000004
-rw-rw---- 1 mysql mysql       365 Dec 11 19:24 mysql-bin.000005
-rw-rw---- 1 mysql mysql     33648 Dec 13 13:20 mysql-bin.000006
-rw-rw---- 1 mysql mysql       342 Dec 13 14:59 mysql-bin.000007
-rw-rw---- 1 mysql mysql       224 Dec 13 14:59 mysql-bin.index
drwx------ 2 mysql mysql     12288 Dec 10 17:55 nextcloud@002ddb
drwx------ 2 mysql mysql      4096 Dec 10 17:54 performance_schema
-rw-rw---- 1 mysql mysql      1696 Dec 13 14:59 slow.log
drwx------ 2 mysql mysql     12288 Dec 10 17:54 sys
~~~

This apparent mismatch is because the `mysql` user only exists within the container, but its "user id" number happens to correspond with the `systemd-coredump` that do exists within the K3s agent node system hosting the container.

On the other hand, the permission mode of the files are the same as how you saw them directly in the agent node. Needless to say that you should be careful of not tinkering with these files unless strictly necessary.

Back in the K3s agent node shell, if you now checked the folder where the MariaDB volume is mounted (`/mnt/nextcloud-ssd/db/k3smnt`), you'll see that its owner has changed.

~~~bash
$ ls -al /mnt/nextcloud-ssd/db/
total 12
drwxr-xr-x 3 root             root 4096 Oct  4 18:11 .
drwxr-xr-x 4 root             root 4096 Sep 28 21:24 ..
drwxr-xr-x 6 systemd-coredump root 4096 Oct  5 14:10 k3smnt
~~~

Remember that the `k3smnt` folder was originally completely owned by the `root` user, but the MariaDB container has switched it to `mysql`/`systemd-coredump`. This situation illustrates you the need to have a different folder for mounting the volumes used by the containers, at least when using local storage as its done in this guide series.

## References

### _Kubernetes_

- [Official Doc - Get a Shell to a Running Container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 6**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%206%20-%20Complete%20monitoring%20stack%20setup.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G037. Backups 01**) >>](G037%20-%20Backups%2001%20~%20Considerations.md)
