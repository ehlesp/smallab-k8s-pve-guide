# G030 - K3s cluster setup 13 ~ Deploying the Headlamp dashboard

- [Headlamp is an alternative to the Kubernetes Dashboard](#headlamp-is-an-alternative-to-the-kubernetes-dashboard)
- [Deploying Headlamp](#deploying-headlamp)
  - [Getting the administrator user's secret token](#getting-the-administrator-users-secret-token)
- [Testing Headlamp](#testing-headlamp)
- [Headlamp's Kustomize project attached to this guide](#headlamps-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Kubernetes Dashboard](#kubernetes-dashboard)
  - [Headlamp](#headlamp)
  - [Traefik Reference](#traefik-reference)
- [Navigation](#navigation)

## Headlamp is an alternative to the Kubernetes Dashboard

To monitor what's going on in your K3s cluster in a more visual manner, [Kubernetes offers its own native web-based dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/). The problem is that, at the time of writing this, [the Kubernetes Dashboard can only be deployed with Helm charts](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui). Since this guide sticks to the Kustomize way of deploying apps in the K3s cluster, I picked [Headlamp](https://headlamp.dev/) as an alternative that allows its deployment with `kubectl`.

> [!WARNING]
> **Ensure having the metrics-server service running in your cluster first!**\
> To be able to show stats from your K3s cluster, Headlamp (like the Kubernetes Dashboard) requires having [the **metrics-server** service already running in your cluster](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md).

## Deploying Headlamp

For deploying [Headlamp v0.35.0](https://github.com/kubernetes-sigs/headlamp/releases/tag/v0.35.0) (the _latest_ version at the time of writing this) in your homelab cluster, you need:

- A user with the cluster administrator role.

- A patch to set the Headlamp service with a static IP picked from the IP range provided by MetalLB.

- A Traefik IngressRoute resource that will handle the ingress to Headlamp through HTTP.

  > [!WARNING]
  > **Headlamp does not support HTTPS requests!**\
  > Headlamp offers a basic secret-token-based login system and also integration with more advanced authorization and authentication mechanisms (which are outside the scope of this guide). Still, it does not support communications encrypted with a certificate through HTTPS, only open communications through the old HTTP's port 80.
  >
  > Be very aware of this since Headlamp provides you with critical information of your cluster and could be eavesdropped.

All the components will be part of the same Kustomize project for deploying Headlamp:

1. In your `kubectl` client system, create the folder structure for the Headlamp Kustomize project:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/headlamp/{patches,resources}
    ~~~

2. Create the necessary files under the `patches` and `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/headlamp/patches/headlamp.service.patch.yaml $HOME/k8sprjs/headlamp/resources/{headlamp-admin.serviceaccount.yaml,cluster-admin-users.clusterrolebinding.yaml,headlamp.homelab.cloud.ingressroute.traefik.yaml}
    ~~~

3. Check out which IPs are available from the MetalLB IP address pool. The only way is by seeing with `kubectl` which external IPs have been assigned to the services currently running in your cluster:

    ~~~sh
    $ kubectl get services -A
    NAMESPACE        NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    cert-manager     cert-manager              ClusterIP      10.43.113.216   <none>        9402/TCP                     4d2h
    cert-manager     cert-manager-cainjector   ClusterIP      10.43.206.23    <none>        9402/TCP                     4d2h
    cert-manager     cert-manager-webhook      ClusterIP      10.43.118.166   <none>        443/TCP,9402/TCP             4d2h
    default          kubernetes                ClusterIP      10.43.0.1       <none>        443/TCP                      18d
    kube-system      kube-dns                  ClusterIP      10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       18d
    kube-system      metrics-server            ClusterIP      10.43.50.63     <none>        443/TCP                      5d23h
    kube-system      traefik                   LoadBalancer   10.43.174.63    10.7.0.0      80:30512/TCP,443:32647/TCP   18d
    metallb-system   metallb-webhook-service   ClusterIP      10.43.126.18    <none>        443/TCP                      15d
    ~~~

    The only service with a EXTERNAL-IP assigned at this point is Traefik. The service has the very first IP available in MetalLB's `default-pool` IP range (`10.7.0.0` to `10.7.0.20`), autoprovided by MetalLB. This means that Headlamp can use the next IP, `10.7.0.1`.

4. Create a patch to specify the static IP and port for the Headlamp service in the `patches/Headlamp.service.patch.yaml` file:

    ~~~yaml
    # Headlamp service patch
    kind: Service
    apiVersion: v1

    metadata:
      name: headlamp
      namespace: kube-system

    spec:
      type: LoadBalancer
      loadBalancerIP: 10.7.0.1
    ~~~

    This patch ensures that the Headlamp service uses the static IP `10.7.0.1` provided by the MetalLB load balancer.

5. In `resources/headlamp-admin.serviceaccount.yaml`, declare the `headlamp-admin` service account:

    ~~~yaml
    # Headlamp administrator user
    apiVersion: v1
    kind: ServiceAccount

    metadata:
      name: headlamp-admin
      namespace: kube-system
    ~~~

    About this service account, know that:

    - The name `headlamp-admin` is the one expected in the official Headlamp installation. Its deployment YAML already declares a secret token for a service account called `headlamp-admin`.

    - The `kube-system` namespace is where the Headlamp service is going to be deployed. The service account must be in the same namespace as Headlamp to authorize this service to access the cluster information it needs to work.

    - This declaration only creates the `headlamp-admin` service account without any special privileges in the cluster. The account needs to be bound to a cluster role to be authorized to access your K3s cluster information, something you will declare in the next step.

6. In `resources/cluster-admin-users.clusterrolebinding.yaml`, bind the `headlamp-admin` with the `cluster-admin` cluster role:

    ~~~yaml
    # Administrator cluster role bindings
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding

    metadata:
      name: cluster-admin-users
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: headlamp-admin
      namespace: kube-system
    ~~~

    This declaration

    With this declaration, you make the `headlamp-admin` account an administrator of your cluster under the `kube-system` namespace:

    - The `roleRef` attribute specifies that the cluster role to be bound is `cluster-admin`.
    - In `subjects` you list all the users you want bounded to the role indicated in roleRef. In this case, there is only the `headlamp-admin` service account.

7. In `resources/headlamp.homelab.cloud.ingressroute.traefik.yaml`, specify the Traefik IngressRoute resource for accessing Headlamp through HTTPS:

    ~~~yaml
    # Traefik IngressRoute for Headlamp
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute

    metadata:
      name: headlamp
      namespace: kube-system
    spec:
      entryPoints:
        - web # Headlamp only supports the HTTP scheme
      routes:
      - match: (Host(`10.7.0.1`) || Host(`headlamp.homelab.cloud`) || Host(`hdl.homelab.cloud`))
        kind: Rule
        services:
        - name: headlamp
          kind: Service
    ~~~

    Details to highlight in this declaration are:

    - The `spec.entryPoints` is set to `web` only, which corresponds to HTTP.

    - The `spec.routes.match` is a list that informs Traefik of the possible routes to call Headlamp, including its static IP.

      > [!NOTE]
      > **The domain names must be enabled in your local network**\
      > Your equivalent of the host names seen in the YAML above will not be reachable unless you enable them from a DNS service (your local network's router could provide it), or specify them in the `hosts` file of the clients you want to access from.

    - The `spec.routes.services` only has an entry for the Headlamp service, linking it to this IngressRoute.

8. Create the `kustomization.yaml` file for the Kustomize project.

    ~~~sh
    $ touch $HOME/k8sprjs/headlamp/kustomization.yaml
    ~~~

9. Put in the `kustomization.yaml` file the following lines:

    ~~~yaml
    # Headlamp setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - resources/headlamp-admin.serviceaccount.yaml
    - resources/cluster-admin-users.clusterrolebinding.yaml
    - resources/headlamp.homelab.cloud.ingressroute.traefik.yaml
    - https://raw.githubusercontent.com/kubernetes-sigs/headlamp/main/kubernetes-headlamp.yaml

    patches:
    - path: patches/headlamp.service.patch.yaml
    ~~~

10. Apply the Kustomize project to your cluster:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/headlamp
    ~~~

11. Give Headlamp about a minute to boot up, then verify that its corresponding pod and service are running in the `kube-system` namespace:

    ~~~sh
    $ kubectl get pods,svc -n kube-system | grep headlamp
    pod/headlamp-747b5f4d5-j9l66                  1/1     Running     0          52s
    service/headlamp         LoadBalancer   10.43.234.223   10.7.0.1      80:30179/TCP                 52s
    ~~~

### Getting the administrator user's secret token

To log in Headlamp with the `headlamp-admin` user you created in its deployment, you need to use its secret token for authenticating in the app. Create this token with the following `kubectl` command:

~~~sh
$ kubectl -n kube-system create token headlamp-admin
eyJhbGciOiJSUzI1NiIsImtpZCI6ImtxNzh0bmk3cDAzVU4zXzFnMVgwZXVSR3c0U1FnNVZ3OUtSdDBSTkw2WmsifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXFiMnQ1Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI4MjU4Mjc4ZC02YjBmLTQwZDItOTI1Yy1kMzEwMmY3MTkxYzQiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.PG-4qfeT3C6vFfwhdGDoXVmjDEU7TJDTftcmIa2kQO0HtWM8ZN45wDGk4ZSWUR5mO5HlXpYORiGkKHq6GNPFRr_qCo4tKIONyZbgXtV98P6OpOIrfDTJCwxjFf0aqOmEs1N3BqViFs3MgBRCLElx98rD6AXehdxPADXlAksnaypKKx6q1WFgNmOTHfC9WrpQzX-qoo8CbRRCuSyTagm3qkpa5hV5RjyKjE7IaOqQGwFOSbTqMy6eghTYSufC-uUxcOWw3OPVa9QzINOn9_tioxj7tH7rpw_eOHzUW_-Cr_HE89DygnuZAqQEsWxBLfYcrBKtnMhxn49E22SyCaJldA
~~~

Be aware of the following:

- This secret token is linked to the `headlamp-admin` service account which exists in the `default` namespace. This is why the command specifies `-n default` rather than `-n kube-system`.

- The command outputs your `headlamp-admin`'s secret token string directly in your shell. Remember to copy and save it somewhere safe such as a password manager.

## Testing Headlamp

Now that you have Headlamp deployed, you can test it:

1. Open a browser in your client system and go to `http://headlamp.homelab.cloud/` (or whatever URL or static IP you may have configured). You'll see the following form:

    ![Headlamp authentication form with secret token](images/g030/headlamp-authentication-token.webp "Headlamp authentication form with secret token")

    See that this form requests an authentication token for signing into Headlamp. Use the secret token you generated previously for the `headlamp-admin` service account and get into Headlamp.

2. After authenticating, you get into Headlamp's `Clusters` page:

    ![Headlamp Clusters main page](images/g030/headlamp-clusters-view.webp "Headlamp Clusters main page")

    You can consider this the main page of Headlamp. It provides you with a summarized view of your cluster status, including statistics about resources usage and a listing of events that have happened in your cluster. Try out the other views Headlamp offers to get familiarized with this tool. In particular, you may like to try out the `Map`:

    ![Headlamp Map view of cluster components](images/g030/headlamp-map-view.webp "Headlamp Map view of cluster components")

    This view provides a zoomable map that can show your cluster components grouped under three different criteria: by namespace, by instance, or by node. This feature will help you to locate more easily any component deployed in your K3s cluster.

## Headlamp's Kustomize project attached to this guide

You can find the Kustomize project for this Headlamp deployment in this attached folder:

- [`k8sprjs/headlamp`](k8sprjs/headlamp/)

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/headlamp`
- `$HOME/k8sprjs/headlamp/patches`
- `$HOME/k8sprjs/headlamp/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/headlamp/kustomization.yaml`
- `$HOME/k8sprjs/headlamp/patches/headlamp.service.patch.yaml`
- `$HOME/k8sprjs/headlamp/resources/cluster-admin-users.clusterrolebinding.yaml`
- `$HOME/k8sprjs/headlamp/resources/headlamp-admin.serviceaccount.yaml`
- `$HOME/k8sprjs/headlamp/resources/headlamp.homelab.cloud.ingressroute.traefik.yaml`

## References

### [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

- [Deploying the Dashboard UI](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui)

### [Headlamp](https://headlamp.dev/)

- [Installation](https://headlamp.dev/docs/latest/installation/)

### [Traefik Reference](https://doc.traefik.io/traefik/reference/)

- [Routing Configuration](https://doc.traefik.io/traefik/reference/routing-configuration/)
  - [Kubernetes. Kubernetes CRD. HTTP. IngressRoute](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/ingressroute/)

## Navigation

[<< Previous (**G029. K3s cluster setup 12**)](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G031. K3s cluster setup 14**) >>](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md)
