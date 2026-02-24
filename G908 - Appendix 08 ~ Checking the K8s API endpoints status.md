# G908 - Appendix 08 ~ Checking the K8s API endpoints' status

- [Review the status of your K3s cluster's Kubernetes API endpoints with `kubectl`](#review-the-status-of-your-k3s-clusters-kubernetes-api-endpoints-with-kubectl)
- [Check out your K8s cluster API endpoints readiness](#check-out-your-k8s-cluster-api-endpoints-readiness)
- [See if your K8s cluster's API endpoints are healthy](#see-if-your-k8s-clusters-api-endpoints-are-healthy)
- [Verify if the K8s cluster's API endpoints are live](#verify-if-the-k8s-clusters-api-endpoints-are-live)
- [Details to notice from the `kubectl` commands](#details-to-notice-from-the-kubectl-commands)
- [Deprecated component status command](#deprecated-component-status-command)
- [References](#references)
  - [Kubernetes](#kubernetes)
  - [Other Kubernetes-related content](#other-kubernetes-related-content)
- [Navigation](#navigation)

## Review the status of your K3s cluster's Kubernetes API endpoints with `kubectl`

If you want or need to know the status of your Kubernetes cluster's API endpoints, you can do it with the `kubectl` command. The trick is about invoking directly certain URLs active in your cluster with the `get` action and the `--raw` flag. See how to do it in different use cases in the following sections.

## Check out your K8s cluster API endpoints readiness

~~~sh
$ kubectl get --raw='/readyz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]kms-providers ok
[+]informer-sync ok
[+]poststarthook/start-encryption-provider-config-automatic-reload ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed
~~~

## See if your K8s cluster's API endpoints are healthy

~~~sh
$ kubectl get --raw='/healthz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]kms-providers ok
[+]poststarthook/start-encryption-provider-config-automatic-reload ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
healthz check passed
~~~

## Verify if the K8s cluster's API endpoints are live

~~~sh
$ kubectl get --raw='/livez?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]poststarthook/start-encryption-provider-config-automatic-reload ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
livez check passed
~~~

## Details to notice from the `kubectl` commands

Be aware of certain details from the `kubectl` commands shown in the previous sections:

- All the URLs passed to the `--raw` flag are relative to the connection you have configured to your `kubectl` installation.

- The output from the `readyz` URL is slightly different from the `healthz` and `livez` ones. It prints a few more lines not shown in the other two outputs.

- Without the `verbose` option in the URL, you will only get a simple undetailed result such as `ok` from the API.

You can also execute the same checks from within the cluster, if you set up a busybox or similar container with a `curl` command included in it. Then, you could invoke the API from within like below:

~~~sh
$ curl -k https://localhost:6443/livez?verbose
~~~

## Deprecated component status command

There is a deprecated but still working (up to the 1.35 version of Kubernetes at least) component status command:

~~~sh
$ kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE   ERROR
etcd-0               Healthy   ok        
scheduler            Healthy   ok        
controller-manager   Healthy   ok
~~~

Notice the deprecation notice in the commands output, and also that is does not really give much information.

## References

### [Kubernetes](https://kubernetes.io/)

- [Kubernetes Documentation. Reference. Command line tool (kubectl)](https://kubernetes.io/docs/reference/kubectl/)
  - [kubectl Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

- [Kubernetes docs, `kubectl` commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

### Other Kubernetes-related content

- [LinkedIn. Bibin Wilson. Basic Kubernetes Tip](https://www.linkedin.com/feed/update/urn:li:activity:6980870783585722368/)

## Navigation

[<< Previous (**G907. Appendix 07**)](G907%20-%20Appendix%2007%20~%20Kubernetes%20object%20stuck%20in%20Terminating%20state.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G909. Appendix 09**) >>](G909%20-%20Appendix%2009%20~%20Updating%20MariaDB%20to%20a%20newer%20major%20version.md)
