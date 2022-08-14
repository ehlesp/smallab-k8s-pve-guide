# G042 - System update 01 ~ Considerations

The last concept I'll tackle in this guide series is the update of the system's software components. As usual, the system I'm referring to is the whole setup you've been building up through all the previous guides. Updating this system is not technically difficult, in particular when using the most straighforward (and many times the only proper) method. Yet you need to be careful when doing it, something which demands knowing your system well.

## What to update. Identifying your system's software layers

The setup you've built in this guide series has five software layers, so to speak, each with their own particularities.

- **Proxmox VE**: the lowest level, which executes your VMs and is run by a custom Debian 11 system on your physical host.

- **Qemu VMs**: virtual machines run by the Proxmox VE Qemu engine that, inside them, have a Debian 11 system environment.

- **K3s Kubernetes cluster**: three nodes that are Debian 11 VMs running the K3s software making the Kubernetes cluster possible. The K3s software has no direct dependencies with the underlying Debian 11 system of the VMs.

- **Apps deployed in the K3s Kubernetes cluster**: in the K3s Kubernetes cluster you have several apps and software tools deployed. Some of them have direct dependencies with the Kubernetes API, which makes updating K3s and those apps something not trivial at all.

- **UrBackup**: one Debian 11 VM dedicated as the UrBackup server, and the UrBackup client software which is installed on the K3s node VMs. The server does have some dependencies with libraries installed in the Debian 11 system, while the client can also have them depending on how it's configured in the installation.

The first three layers are, from the software point of view, independent from each other. The apps deployed in the K3s Kubernetes cluster are only dependant on the cluster itself, but some of them are only compatible with concrete versions of the Kubernetes engine. Those particular cases makes the update of the K3s software more tricky than with the rest of layers identified in the system.

Something else is the UrBackup software, since both the server and the client software have (or can have) dependencies installed in the VMs where they run. Therefore, it'll be better to handle the update of the UrBackup software together with the update of the Debian system in the VMs.

## How to update. Update procedures

For updating the Proxmox VE main system and all the Debian 11 environments running in all your VMs, there's only the `apt` command which you already know. On the other hand, the K3s software has two ways to update itself: one is essentially the same procedure used for installing it, the other is by creating a specific Kubernetes task that would take care of it.

The update of the apps running in the K3s cluster can be easily handled by reusing the same kustomize projects used for their deployment. Essentially, its just changing the image used in the deployment, although not before checking that the new version is still compatible with the current configuration of the app being updated.

Finally, updating the UrBackup software is kind of a hybrid approach: the server can be upgraded the same way it was installed if `apt` doesn't find its newest version, and the client has its own `sh` update program similar to the installer one.

## When to apply the updates

Ideally, you want to update as soon as possible, specially when dealing with security patches or version upgrades. You may think that this procedure could be automated (scheduled with a `cron` script, for instance), but that's a dangerous proposition.

Before applying any update, you need to evaluate what it does. It's just a library update?, or maybe it changes the software's behaviour, or it could be a major version change. Also, you need to be aware of the indirect implications of updating a system. For instance, you'll need to stop all your VMs before you can apply the updates to the Proxmox VE system that runs them.

Therefore, you'll need to plan the updates of the different software layers running in your system. You'll have to take into account what services you're running, when and for how long you can afford your system to be down, and also how recent your backups are in case you need them.

Broadly speaking, for a small personal homelab system as the one used in this guide series, I'd say that doing a regular update in a biweekly or just monthly basis should be enough. Don't wait more than that, or you'll end up having a lot of updates to apply, and, potentially, who knows how many adjustments to do in your system.

### _Update order_

Related to the "when" question is the matter of in what order you should deal with the updates of all the layers of your system. Thanks to the relative independence existing among the Proxmox VE, the Debian 11 systems within the VMs and the K3s software, in theory you can update these layers on whichever order you prefer. Still, is always better to keep the same order, that way you'll find easier to repeat the procedure every time and detect issues when going through it.

For me, a good order is going always from the bottom up:

1. Proxmox VE, since it supports all the system.
2. The Debian system in the VMs.
   1. The UrBackup software, which can be affected by the Debian updates.
3. The K3s software.
   1. The apps deployed in the K3s cluster.

And what if one layer doesn't have any updates pending? Easy, you just skip it in that particular update cycle.

## Navigation

[<< Previous (**G041. Backups 05. UrBackup 02**)](G041%20-%20Backups%2005%20~%20UrBackup%2002%20-%20Clients%20setup%20and%20configuring%20file%20backups.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G043. System update 02**) >>](G043%20-%20System%20update%2002%20~%20Updating%20Proxmox%20VE.md)
