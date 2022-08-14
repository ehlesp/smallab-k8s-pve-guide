# G904 - Appendix 04 ~ Object by object Kubernetes deployments

It may happen that your Kubernetes cluster nodes are tight on hardware resources and cannot deploy big manifests, failing to deploy some of their objects. If you cannot give more CPU or RAM to your nodes, you can also try a workaround to be able perform heavy deployments in your cluster.

This happened to me while trying to deploy cert-manager in my K3s cluster. I solved this issue just by assigning more CPU cores to each node but, if that hadn't been possible, I could have tried a manual object-by-object deployment approach.

## Example scenario: cert-manager deployment

Let's imagine you're trying to deploy a big manifest, such as the one required for cert-manager.

~~~bash
$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
~~~

If the deployment starts returning many errors like the ones next.

~~~bash
...
error when creating "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": Post "https://192.168.1.21:6443/apis/rbac.authorization.k8s.io/v1/clusterroles?fieldManager=kubectl-client-side-apply": EOF
error when retrieving current configuration of:
Resource: "rbac.authorization.k8s.io/v1, Resource=clusterroles", GroupVersionKind: "rbac.authorization.k8s.io/v1, Kind=ClusterRole"
Name: "cert-manager-controller-issuers", Namespace: ""
from server for: "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": Get "https://192.168.1.21:6443/apis/rbac.authorization.k8s.io/v1/clusterroles/cert-manager-controller-issuers": dial tcp 192.168.1.21:6443: connect: connection refused
error when retrieving current configuration of:
Resource: "rbac.authorization.k8s.io/v1, Resource=clusterroles", GroupVersionKind: "rbac.authorization.k8s.io/v1, Kind=ClusterRole"
Name: "cert-manager-controller-clusterissuers", Namespace: ""
from server for: "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": Get "https://192.168.1.21:6443/apis/rbac.authorization.k8s.io/v1/clusterroles/cert-manager-controller-clusterissuers": dial tcp 192.168.1.21:6443: connect: connection refused
...
~~~

This means that your cluster has been overloaded by the deployment, although just momentarily. After the deployment stops running, you'll need then to delete all the objects created up to this moment by the deployment.

~~~bash
$ kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
~~~

This will also temporarily overload your cluster, so you'll need to repeat this command a few times until it **only** returns `NotFound` errors like the following ones.

~~~bash
Error from server (NotFound): error when deleting "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": customresourcedefinitions.apiextensions.k8s.io "certificaterequests.cert-manager.io" not found
Error from server (NotFound): error when deleting "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": customresourcedefinitions.apiextensions.k8s.io "certificates.cert-manager.io" not found
Error from server (NotFound): error when deleting "https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml": customresourcedefinitions.apiextensions.k8s.io "challenges.acme.cert-manager.io" not found
...
~~~

What has happened here? The yaml manifest for cert-manager is heavy: for the `1.4.0` version it weights almost 2 MiB. This implies that either it defines many Kubernetes objects or that they are complex, or both. Also, it might be that some of those objects are Kubernetes secrets that require strong encryption. Regardless, what is obvious is that, if you have seen those errors above, your K3s cluster nodes are lacking in capacity. To fix this, you can go to Proxmox VE and increase the CPU and RAM capabilities of your VMs, then try to execute again the deployment and hope for the best. As a reference, my humble four-single-threaded-cores CPU, running the same five K3s nodes used in the guide series, was able to deploy cert-manager just by increasing the number of cores available to **each VM** to the maximum possible, four.

### _Object-by-object deployment_

If by "improving" the hardware configured in your VMs is not enough to execute a heavy deployment in your cluster properly, you can try a last ditch effort. This is by deploying all the objects inside the problematic manifest **manually**. I'll illustrate this procedure again with cert-manager next.

1. In your kubectl client system, create a folder where to store the cert-manager yaml manifest.

    ~~~bash
    $ mkdir -p $HOME/k3sconfig/cert-manager/objects
    ~~~

    See that I've also created an `objects` folder, which you'll need later to hold all the objects extracted from the cert-manager yaml manifest, each object on their own yaml manifest file.

2. Download the cert-manager manifest, saving it in the corresponding folder you've created in the previous step.

    ~~~bash
    $ wget https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml -O $HOME/k3sconfig/cert-manager/cert-manager_1.4.0.yaml
    ~~~

    Notice how I've appended the cert-manager version to the downloaded file.

3. Now you can extract all the objects configured inside the downloaded yaml file. First get into the `objects` folder you created before.

    ~~~bash
    $ cd $HOME/k3sconfig/cert-manager/objects
    ~~~

    Then, execute the following `csplit` command.

    ~~~bash
    $ csplit --suppress-matched --digits=2 --quiet --prefix=cert-manager_object_ --suffix-format=%02d.yaml ../cert-manager_1.4.0.yaml "/---/" "{*}"
    ~~~

    On yaml files, `---` is a separator of directives. In the case of Kubernetes manifests, it separates objects, so what `csplit` does here is extract those objects into text files by distinguishing them just by the separator. Also realize that the objects are extracted in the order they're found within the original yaml file. The execution of this command should be fast; check with `ls` the files it has generated.

    ~~~bash
    $ ls
    cert-manager_object_00.yaml  cert-manager_object_09.yaml  cert-manager_object_18.yaml  cert-manager_object_27.yaml  cert-manager_object_36.yaml
    cert-manager_object_01.yaml  cert-manager_object_10.yaml  cert-manager_object_19.yaml  cert-manager_object_28.yaml  cert-manager_object_37.yaml
    cert-manager_object_02.yaml  cert-manager_object_11.yaml  cert-manager_object_20.yaml  cert-manager_object_29.yaml  cert-manager_object_38.yaml
    cert-manager_object_03.yaml  cert-manager_object_12.yaml  cert-manager_object_21.yaml  cert-manager_object_30.yaml  cert-manager_object_39.yaml
    cert-manager_object_04.yaml  cert-manager_object_13.yaml  cert-manager_object_22.yaml  cert-manager_object_31.yaml  cert-manager_object_40.yaml
    cert-manager_object_05.yaml  cert-manager_object_14.yaml  cert-manager_object_23.yaml  cert-manager_object_32.yaml  cert-manager_object_41.yaml
    cert-manager_object_06.yaml  cert-manager_object_15.yaml  cert-manager_object_24.yaml  cert-manager_object_33.yaml  cert-manager_object_42.yaml
    cert-manager_object_07.yaml  cert-manager_object_16.yaml  cert-manager_object_25.yaml  cert-manager_object_34.yaml  cert-manager_object_43.yaml
    cert-manager_object_08.yaml  cert-manager_object_17.yaml  cert-manager_object_26.yaml  cert-manager_object_35.yaml  cert-manager_object_44.yaml
    ~~~

4. With the objects extracted to individual ordered yaml manifest files, you can try applying them **in ascendant order** (the order in which they were in the original manifest) on your cluster.

    ~~~bash
    $ kubectl apply -f cert-manager_object_00.yaml -f cert-manager_object_01.yaml
    ~~~

    The command above is just an example of how you could do it. Instead of just going one by one, you could deploy the yaml in bunches of two or more yamls to go faster with this manual process. And, if you get an error in a bunch, you could delete the deployment of just those yamls and then deploy them one by one.

Bear in mind that I haven't tried this rather cumbersome method. You should always first try to readjust the resources assigned to your VMs, and even consider also the reduction of the number of nodes you have running in your cluster.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k3sconfig/cert-manager`
- `$HOME/k3sconfig/cert-manager/objects/`

### _Files in `kubectl` client system_

- `$HOME/k3sconfig/cert-manager/cert-manager_1.4.0.yaml`
- `$HOME/k3sconfig/cert-manager/objects/cert-manager_object_00.yaml` ~ `$HOME/k3sconfig/cert-manager/objects/cert-manager_object_44.yaml`

## References

### _cert-manager_

- [cert-manager's v1.4.0 manifest](https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml)

### _Splitting text file with `csplit` using delimiter_

- [Split one file into multiple files based on delimiter](https://stackoverflow.com/questions/11313852/split-one-file-into-multiple-files-based-on-delimiter)

## Navigation

[<< Previous (**G903. Appendix 03**)](G903%20-%20Appendiz%2003%20~%20Customization%20of%20the%20motd%20file.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G905. Appendix 05**) >>](G905%20-%20Appendix%2005%20~%20Cloning%20storage%20drives%20with%20Clonezilla.md)
