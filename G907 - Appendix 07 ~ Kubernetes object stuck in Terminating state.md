# G907 - Appendix 07 ~ Kubernetes object stuck in Terminating state

- [Kubernetes objects can get stuck as `Terminating` when undeployed](#kubernetes-objects-can-get-stuck-as-terminating-when-undeployed)
- [Scenario](#scenario)
- [Solution](#solution)
- [References](#references)
- [Navigation](#navigation)

## Kubernetes objects can get stuck as `Terminating` when undeployed

While undeploying a service or app from your Kubernetes cluster, it may happen that an object from that service or app gets stuck in a `Terminating` state. It is possible to unstuck such a `Terminating` object by tinkering a bit with its effective configuration deployed in the cluster.This chapter uses an older cert-manager installation to exemplify this issue and it possible solution.

> [!NOTE]
> **This solution has not been tested for the current version of this guide**\
> Since this issue was detected when working with an older version of K3s (`v1.22.3+k3s1`), it might be possible that this is issue no longer happens in modern K3s or Kubernetes clusters.

## Scenario

Suppose you have deployed cert-manager `v1.5.3` in your cluster applying, with `kubectl`, the default official `cert-manager.yaml` file:

1. To undeploy cert-manager you would just `delete` the same YAML manifest used in the deployment:

    ~~~sh
    $ kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
    ~~~

    This command will output a bunch of lines but will not return control to the shell. That is because there is one object that cannot delete and cannot finish untill that object is properly terminated.

2. Open another shell and use `kubectl` to locate the problematic object. In this example with cert-manager, it happened to be the namespace cert-manager created for itself:

    ~~~sh
    $ kubectl get namespaces 
    NAME              STATUS        AGE
    default           Active        43h
    kube-system       Active        43h
    kube-public       Active        43h
    kube-node-lease   Active        43h
    metallb-system    Active        22h
    cert-manager      Terminating   144m
    ~~~

    No matter what you do, not even rebooting the entire cluster, will get rid of that `cert-manager` namespace.

## Solution

The procedure explained next has been taken [from this article by Craig Newton](https://craignewtondev.medium.com/how-to-fix-kubernetes-namespace-deleting-stuck-in-terminating-state-5ed75792647e) and adapted for this example with cert-manager:

1. Dump the `cert-manager` namespace's declaration as a JSON file:

    ~~~sh
    $ kubectl get namespaces cert-manager -o json > cert-manager_namespace.json
    ~~~

2. Open with a text editor the `cert-manager_namespace.json` file. It should look like below:

    ~~~json
    {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"cert-manager\"}}\n"
            },
            "creationTimestamp": "2021-09-01T12:08:32Z",
            "labels": {
                "kubernetes.io/metadata.name": "cert-manager"
            },
            "name": "cert-manager",
            "resourceVersion": "33330",
            "uid": "d77020c8-433e-4abd-a95d-9568dcada8eb"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Terminating"
        }
    }
    ~~~

3. Only remove the `"kubernetes"` string within `spec.finalizers`, ensuring to leave empty the array declared in the `finalizers` parameter:

    ~~~json
    {
        ...
        "spec": {
            "finalizers": [
            ]
        },
        ...
    }
    ~~~

4. Finally, you have to execute a `replace` command with `kubectl`:

    ~~~sh
    $ kubectl replace --raw "/api/v1/namespaces/cert-manager/finalize" -f cert-manager_namespace.json
    ~~~

    Notice that Kubernetes `/api/v1` path specified, in this case, for the `cert-manager` namespace. If the resource or object to modify were anything else, you would have to specify the correct API path for it.

This procedure will effectively unstick the namespace and allow the `kubectl delete` process to end, returning the control to the prompt after a few seconds.

> [!NOTE]
> **This procedure is valid for **all kind** of Kubernetes objects or resources, not just namespaces**\
> Just be aware that you will need to find the correct API path for the Kubernetes (or non-Kubernetes) object or resource you are trying to fix with this solution.

## References

- [Medium. Craig Newton. How to fix — Kubernetes namespace deleting stuck in Terminating state](https://craignewtondev.medium.com/how-to-fix-kubernetes-namespace-deleting-stuck-in-terminating-state-5ed75792647e)

## Navigation

[<< Previous (**G906. Appendix 06**)](G906%20-%20Appendix%2006%20~%20K3s%20cluster%20with%20two%20or%20more%20server%20nodes.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G908. Appendix 08**) >>](G908%20-%20Appendix%2008%20~%20Checking%20the%20K8s%20API%20endpoints%20status.md)
