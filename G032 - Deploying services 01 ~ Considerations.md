# G032 - Deploying services 01 ~ Considerations

- [Upcoming chapters are about deploying services in your K3s cluster](#upcoming-chapters-are-about-deploying-services-in-your-k3s-cluster)
- [Be watchful of your system's resources usage](#be-watchful-of-your-systems-resources-usage)
- [Do not fill your cluster up to the brim](#do-not-fill-your-cluster-up-to-the-brim)
- [Navigation](#navigation)

## Upcoming chapters are about deploying services in your K3s cluster

The next chapters of this guide will show you how to deploy in your K3s cluster the services listed in the [chapter **G018**](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it). Of course, you may want to deploy other apps. Consider the ones deployed in the following chapters as examples of how you could do it for other deployments.

## Be watchful of your system's resources usage

Your K3s Kubernetes cluster is not running "empty" at this point. It is already executing a number of services that eat up a good chunk of your hardware's resources. Be always aware of the current resources usage in your setup before you deploy any new app or service in your cluster.

At this point of the guide, you can monitor the resource usages in your setup in these ways:

- **The Proxmox VE's web console has a `Summary` view on every level**\
  Datacenter, node and VMs have all a `Summary` page in which you can see the current resource usages.

- **From the OS point of view, using shell commands like `htop`, `free` or `df`**\
  It is important that you also see the usage values from within your Proxmox VE host and VMs, because they are more fine grained and can indicate you better how resources are being used.

- **The `kubectl top` command**\
  Gives you the view on resources usage from within your K3s cluster.

- **Headlamp**\
  The Headlamp dashboard you deployed in the [previous chapter **G031**](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md) offers a resources usage overview in its main `Clusters` page.

## Do not fill your cluster up to the brim

Just because you still have free RAM or a not so high CPU usage, it does not mean that you can keep on deploying more services in your setup. You must leave some room for possible usage spikes, and for the underlying platforms running everything (Proxmox VE and K3s) which also need resources to run. This way you can run sporadic tasks like backup jobs or updates when required.

## Navigation

[<< Previous (**G031. K3s cluster setup 14**)](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Ghost Part 1**) >>](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md)
