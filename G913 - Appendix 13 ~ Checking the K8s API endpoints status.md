# G913 - Appendix 13 ~ Checking the K8s API endpoints' status

If you want or need to know the status of your Kubernetes cluster's API endpoints, you can do it with the `kubectl` command. The trick is about invoking directly certain URLs active in your cluster with the `get` action and the `--raw` flag.

- To check out if your K8s cluster's API endpoints are **ready**.

    ~~~bash
    $ kubectl get --raw='/readyz?verbose'
    [+]ping ok
    [+]log ok
    [+]etcd ok
    [+]etcd-readiness ok
    [+]informer-sync ok
    [+]poststarthook/start-kube-apiserver-admission-initializer ok
    [+]poststarthook/generic-apiserver-start-informers ok
    [+]poststarthook/priority-and-fairness-config-consumer ok
    [+]poststarthook/priority-and-fairness-filter ok
    [+]poststarthook/storage-object-count-tracker-hook ok
    [+]poststarthook/start-apiextensions-informers ok
    [+]poststarthook/start-apiextensions-controllers ok
    [+]poststarthook/crd-informer-synced ok
    [+]poststarthook/bootstrap-controller ok
    [+]poststarthook/rbac/bootstrap-roles ok
    [+]poststarthook/scheduling/bootstrap-system-priority-classes ok
    [+]poststarthook/priority-and-fairness-config-producer ok
    [+]poststarthook/start-cluster-authentication-info-controller ok
    [+]poststarthook/aggregator-reload-proxy-client-cert ok
    [+]poststarthook/start-kube-aggregator-informers ok
    [+]poststarthook/apiservice-registration-controller ok
    [+]poststarthook/apiservice-status-available-controller ok
    [+]poststarthook/kube-apiserver-autoregistration ok
    [+]autoregister-completion ok
    [+]poststarthook/apiservice-openapi-controller ok
    [+]poststarthook/apiservice-openapiv3-controller ok
    [+]shutdown ok
    readyz check passed
    ~~~

- To see if your K8s cluster's API endpoints are **healthy**.

    ~~~bash
    $ kubectl get --raw='/healthz?verbose'
    [+]ping ok
    [+]log ok
    [+]etcd ok
    [+]poststarthook/start-kube-apiserver-admission-initializer ok
    [+]poststarthook/generic-apiserver-start-informers ok
    [+]poststarthook/priority-and-fairness-config-consumer ok
    [+]poststarthook/priority-and-fairness-filter ok
    [+]poststarthook/storage-object-count-tracker-hook ok
    [+]poststarthook/start-apiextensions-informers ok
    [+]poststarthook/start-apiextensions-controllers ok
    [+]poststarthook/crd-informer-synced ok
    [+]poststarthook/bootstrap-controller ok
    [+]poststarthook/rbac/bootstrap-roles ok
    [+]poststarthook/scheduling/bootstrap-system-priority-classes ok
    [+]poststarthook/priority-and-fairness-config-producer ok
    [+]poststarthook/start-cluster-authentication-info-controller ok
    [+]poststarthook/aggregator-reload-proxy-client-cert ok
    [+]poststarthook/start-kube-aggregator-informers ok
    [+]poststarthook/apiservice-registration-controller ok
    [+]poststarthook/apiservice-status-available-controller ok
    [+]poststarthook/kube-apiserver-autoregistration ok
    [+]autoregister-completion ok
    [+]poststarthook/apiservice-openapi-controller ok
    [+]poststarthook/apiservice-openapiv3-controller ok
    healthz check passed
    ~~~

- To verify if the K8s cluster's API endpoints are **live**.

    ~~~bash
    $ kubectl get --raw='/livez?verbose'
    [+]ping ok
    [+]log ok
    [+]etcd ok
    [+]poststarthook/start-kube-apiserver-admission-initializer ok
    [+]poststarthook/generic-apiserver-start-informers ok
    [+]poststarthook/priority-and-fairness-config-consumer ok
    [+]poststarthook/priority-and-fairness-filter ok
    [+]poststarthook/storage-object-count-tracker-hook ok
    [+]poststarthook/start-apiextensions-informers ok
    [+]poststarthook/start-apiextensions-controllers ok
    [+]poststarthook/crd-informer-synced ok
    [+]poststarthook/bootstrap-controller ok
    [+]poststarthook/rbac/bootstrap-roles ok
    [+]poststarthook/scheduling/bootstrap-system-priority-classes ok
    [+]poststarthook/priority-and-fairness-config-producer ok
    [+]poststarthook/start-cluster-authentication-info-controller ok
    [+]poststarthook/aggregator-reload-proxy-client-cert ok
    [+]poststarthook/start-kube-aggregator-informers ok
    [+]poststarthook/apiservice-registration-controller ok
    [+]poststarthook/apiservice-status-available-controller ok
    [+]poststarthook/kube-apiserver-autoregistration ok
    [+]autoregister-completion ok
    [+]poststarthook/apiservice-openapi-controller ok
    [+]poststarthook/apiservice-openapiv3-controller ok
    livez check passed
    ~~~

Notice the following in the examples above.

- All the URLs passed to the `--raw` flag are relative to the connection that you've configured to your `kubectl` installation.
- The output from the `readyz` URL is slightly different from the `healthz` and `livez` ones. It prints a few more lines not shown in the other two outputs.
- Without the `verbose` option in the URL, you'll only get a simple undetailed result such as `ok` from the API.

You can also execute the same checks from within the cluster, if you set up a busybox or similar container with a `curl` command included in it. Then, you could invoke the API from within like below.

~~~bash
$ curl -k https://localhost:6443/livez?verbose
~~~

And finally, there's a deprecated but still working (up to the 1.25 version of Kubernetes at least) component status command.

~~~bash
$ kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE   ERROR
scheduler            Healthy   ok        
controller-manager   Healthy   ok
~~~

Notice the deprecation notice in the commands output, and also that is not really that informative.

## References

- [Post by Bibin Wilson on LinkedIn](https://www.linkedin.com/feed/update/urn:li:activity:6980870783585722368/)
- [Kubernetes docs, `kubectl` commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

## Navigation

[<< Previous (**G912. Appendix 12**)](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G914. Appendix 14**) >>](G914%20-%20Appendix%2014%20~%20Post-update%20manual%20maintenance%20tasks%20for%20Nextcloud.md)
