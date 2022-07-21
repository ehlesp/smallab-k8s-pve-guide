# G909 - Appendix 09 ~ Kubernetes object stuck in Terminating state

It may happen to you that you need to undeploy a service or app from your cluster for some reason, but an object from that service or app gets stuck in a `Terminating` state. This happened to me in my tests with cert-manager (which you saw how to deploy in the [**G029** guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager.md)), so I'll use it to exemplify this issue and give you a possible solution for it.

## Scenario

1. Let's suppose you deployed cert-manager `v1.5.3` in your cluster applying, with `kubectl`, the default official `cert-manager.yaml` file. To undeploy it then, you would just `delete` the same yaml.

    ~~~bash
    $ kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml
    ~~~

    This command will output a bunch of lines but won't return control to the shell. That's because there's one object that cannot delete and cannot finish till that object is properly terminated.

2. Open another shell and use `kubectl` to locate the problematic object. In the case of cert-manager it usually is the namespace it created for itself.

    ~~~bash
    $ kubectl get namespaces 
    NAME              STATUS        AGE
    default           Active        43h
    kube-system       Active        43h
    kube-public       Active        43h
    kube-node-lease   Active        43h
    metallb-system    Active        22h
    cert-manager      Terminating   144m
    ~~~

    No matter what you do, even rebooting the entire cluster, will get rid of that `cert-manager` namespace.

## Solution

The procedure you'll see explained next has been taken [from this page](https://craignewtondev.medium.com/how-to-fix-kubernetes-namespace-deleting-stuck-in-terminating-state-5ed75792647e). I'll sum it up here for the cert-manager example.

1. Dump the `cert-manager` namespace's descriptor as a json file.

    ~~~bash
    $ kubectl get namespaces cert-manager -o json > cert-manager_namespace.json
    ~~~

2. Edit the `cert-manager_namespace.json` file, it should look like below.

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

3. Remove **only** the `"kubernetes"` string within `spec.finalizers`, effectively leaving **empty** the array defined by the `finalizers` parameter.

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

4. Finally, you'll have to execute a `replace` command with `kubectl`.

    ~~~bash
    $ kubectl replace --raw "/api/v1/namespaces/cert-manager/finalize" -f cert-manager_namespace.json
    ~~~

    Notice that Kubernetes `/api/v1` URL specified, in this case, for the `cert-manager` namespace. If the resource or object to modify were anything else, you would have to specify the correct api URL for it.

This procedure will effectively unstick the namespace and allow to the `kubectl delete` process to end, returning after a few seconds the control to the prompt.

> **BEWARE!**  
> This procedure is valid for **all kind** of Kubernetes objects or resources, not just namespaces. Just be aware that you'll need to find the correct api URL for the Kubernetes object or resource you're trying to fix with the procedure.

## References

- [How to fix — Kubernetes namespace deleting stuck in Terminating state](https://craignewtondev.medium.com/how-to-fix-kubernetes-namespace-deleting-stuck-in-terminating-state-5ed75792647e)
