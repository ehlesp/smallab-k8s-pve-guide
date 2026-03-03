# G042 - System update 01 ~ Considerations

- [Updating this guide's homelab setup is not a straightforward task](#updating-this-guides-homelab-setup-is-not-a-straightforward-task)
- [What to update. Identifying your system's software layers](#what-to-update-identifying-your-systems-software-layers)
- [How to update. Update procedures](#how-to-update-update-procedures)
- [When to apply the updates](#when-to-apply-the-updates)
- [Update order](#update-order)
- [Navigation](#navigation)

## Updating this guide's homelab setup is not a straightforward task

The homelab setup resulting from this guide is a system built on many software components that depend on each other at different levels. These dependencies are the main thing to be aware of when attempting to update any part of the system, while the update procedures to apply are usually not that technically difficult. In other words, updating any software element of your homelab may not be particularly hard, but before you do you must think first about the consequences of performing that update in your system.

## What to update. Identifying your system's software layers

The setup built in this guide has five software layers, so to speak, each with their own particularities:

1. **Proxmox VE**\
   The lowest level, which executes your VMs and is run by a custom Debian system on your physical host.

2. **Qemu VMs**\
   Virtual machines run by the Proxmox VE Qemu engine that, inside them, have a Debian system environment.

3. **K3s Kubernetes cluster**\
   Three nodes that are Debian VMs running the K3s software that makes the Kubernetes cluster possible. The K3s software does not have dependencies with the underlying Debian system of the VMs.

4. **Apps deployed in the K3s Kubernetes cluster**\
   In the K3s Kubernetes cluster you have several apps and software tools deployed. Some of them have direct dependencies with the Kubernetes API, a sensible detail that can make updating K3s and those apps a bit more complicated.

5. **UrBackup**\
   One Debian VM dedicated as the UrBackup server, and the UrBackup client software which is installed on the K3s node VMs. The server does have some dependencies with libraries installed in the Debian system, while the client can also have them depending on how it is configured in the installation.

The first three layers are, from the software point of view, independent from each other. The apps deployed in the K3s Kubernetes cluster are only dependant on the cluster itself, but some of them are only compatible with concrete versions of the Kubernetes engine. Those particular cases makes the update of the K3s software more tricky than with the rest of layers identified in the system.

Something else is the UrBackup software, since both the server and the client software have (or can have) dependencies installed in the VMs where they run. Therefore, it is better to handle the update of the UrBackup software together with the update of the Debian system in the VMs.

## How to update. Update procedures

For updating the Proxmox VE main system and all the Debian environments running in all your VMs, there is only the `apt` command which you already know. On the other hand, the K3s software has two ways to update itself: one is essentially the same procedure used for installing it, the other is by creating a specific Kubernetes task that would take care of it.

The update of the apps running in the K3s cluster can be easily handled by reusing the same Kustomize projects used for their deployment. Essentially, it is just changing the image used in the deployment, although not before checking that the new version is still compatible with the current configuration of the app being updated.

Finally, updating the UrBackup software is kind of a hybrid approach: the server can be upgraded the same way it was installed if `apt` does not find its newest version, and the client has its own `sh` update program similar to the installer one.

## When to apply the updates

Ideally, you want to update as soon as possible, specially when dealing with security patches or version upgrades. You may think that this procedure could be automated (scheduled with a `cron` script, for instance), but that is a dangerous proposition.

Before applying any update, you need to evaluate what it does. Is it just a library update? Does it change the software's behavior? Or it could be a major version change. Also, you need to consider other implications of updating a system. For instance, you will need to stop all your VMs before you can apply the updates to the Proxmox VE system running them.

Therefore, you need to plan the updates of the different software layers running in your system. You have to think about the services you are running, when and for how long you can afford your system to be down, and also how recent your backups are in case you need them.

Broadly speaking, for a small personal homelab system as the one built in this guide, doing a regular update in a biweekly or just monthly basis should be enough. Do not wait more than that, or you may end up having a lot of updates to apply, and, potentially, who knows how many adjustments to do in your system at once.

## Update order

Related to the "when" question is the matter of in what order you should deal with the updates of all the layers identified in your homelab. Thanks to the relative independence between the Proxmox VE, the Debian systems within the VMs and the K3s software, in theory you can update these layers on whichever order you need or prefer to follow. Still, it is always better to keep the same order. That way you will find easier to repeat the procedure every time and detect issues when going through it.

In general, you prefer to start from the bottom:

1. Proxmox VE, since it supports the whole setup.

2. The Debian system in the VMs:
   1. The UrBackup software, which can be affected by the Debian updates.

3. The K3s software:
   1. The apps deployed in the K3s cluster.

What if one layer does not have any updates pending? Easy. After making sure that it does not have any updates to apply in that cycle, you just skip it in that particular update cycle.

## Navigation

[<< Previous (**G041. Backups 05. UrBackup 02**)](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G043. System update 02**) >>](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md)
