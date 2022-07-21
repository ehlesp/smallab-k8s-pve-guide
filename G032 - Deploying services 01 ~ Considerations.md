# G032 - Deploying services 01 ~ Considerations

In the upcoming guides I'll show you how to deploy a number of services in your K3s cluster. These services are the ones listed in the [**G018** guide](G018%20-%20K3s%20cluster%20setup%2001%20~%20Requirements%20and%20arrangement.md#requirements-for-the-k3s-cluster-and-the-services-to-deploy-in-it), together with their requirements. Of course, you might want to deploy other apps, so consider the ones deployed in the following guides as examples of how you could do it in other deployments. But before you jump into the next guides, ponder the following points.

## Be watchful of your system's resources usage

Your K3s Kubernetes cluster is not running "empty", it already has a fair number of services running which already eat up a good chunk of your hardware's resources. Be always aware of the current resources usage in your setup before you deploy any new app or service in your cluster. Remember that you can see the usages in three ways at least.

- The Proxmox VE's web console has a `Summary` view on every level. Datacenter, node and VMs have all a `Summary` page in which you can see the current resource usages.

- From the OS point of view, using shell commands like `htop`, `free` or `df`. It's important that you also see the usage values from within your Proxmox VE host and VMs, because they are more fine grained and can indicate you better how resources are being used.

- From within the K3s cluster, with the `kubectl top` command.

## Don't fill your setup up to the brim

Just because you still have free RAM or a not so high CPU usage, it doesn't mean that you can keep on deploying more services in your setup. You must leave some room for possible usage spikes, and for the underlying platforms running everything (Proxmox VE and K3s) which also need resources to run. This way you can also run sporadic tasks like backup jobs or updates when required.
