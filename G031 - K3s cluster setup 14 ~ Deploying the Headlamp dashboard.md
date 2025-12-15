# G031 - K3s cluster setup 14 ~ Deploying the Headlamp dashboard

- [Headlamp is an alternative to the Kubernetes Dashboard](#headlamp-is-an-alternative-to-the-kubernetes-dashboard)
- [Deploying Headlamp](#deploying-headlamp)
  - [Getting the administrator user's service account token](#getting-the-administrator-users-service-account-token)
- [Testing Headlamp](#testing-headlamp)
- [Headlamp's Kustomize project attached to this guide](#headlamps-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Headlamp](#headlamp)
  - [Kubernetes Documentation](#kubernetes-documentation)
  - [Traefik Reference](#traefik-reference)
  - [Cert-manager](#cert-manager)
- [Navigation](#navigation)

## Headlamp is an alternative to the Kubernetes Dashboard

To monitor what is going on in your K3s cluster in a more visual manner, [Kubernetes offers its own native web-based dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/). That one is fine, but I discovered an interesting alternative dashboard called [Headlamp](https://headlamp.dev/) also worth trying out.

> [!WARNING]
> **Ensure having the metrics-server service running in your cluster first!**\
> To be able to show stats from your K3s cluster, Headlamp (like the Kubernetes Dashboard) requires having [the **metrics-server** service already running in your cluster](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md).

## Deploying Headlamp

For deploying Headlamp in your homelab cluster, you need:

- A user with the cluster administrator role.

- A TLS certificate to secure communications with Headlamp.

- An HTTPS ingress to access Headlamp that uses the previously mentioned TLS certificate.

All these components will be part of the same Kustomize project for deploying Headlamp:

1. In your `kubectl` client system, create the folder structure for the Headlamp Kustomize project:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/headlamp/resources
    ~~~

2. Create the necessary files under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/headlamp/resources/{headlamp-admin.serviceaccount,cluster-admin-users.clusterrolebinding,headlamp.homelab.cloud-tls.certificate.cert-manager,headlamp.ingressroute.traefik}.yaml
    ~~~

3. In `resources/headlamp-admin.serviceaccount.yaml`, declare the `headlamp-admin` service account:

    ~~~yaml
    # Headlamp administrator user
    apiVersion: v1
    kind: ServiceAccount

    metadata:
      name: headlamp-admin
    ~~~

    This service account will be your administrator user for Headlamp:

    - The name `headlamp-admin` is the one expected in the official Headlamp installation. Its deployment YAML already points to a secret token for a service account called `headlamp-admin`.

    - This declaration only creates the `headlamp-admin` service account without any special privileges in the cluster. The account needs to be bound to a cluster role to be authorized to access your K3s cluster information, something you will declare in the next step.

    > [!IMPORTANT]
    > **Service accounts are not meant for regular users**\
    > For Kubernetes, [user accounts are for humans and service accounts are for application processes](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#user-accounts-versus-service-accounts). Still, [Headlamp's official installation documentation explicitly **recommends** (at the time of writing this) using a service account](https://headlamp.dev/docs/latest/installation/).

4. In `resources/cluster-admin-users.clusterrolebinding.yaml`, bind the `headlamp-admin` with the `cluster-admin` cluster role:

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

    With this declaration, you make the `headlamp-admin` account an administrator of your cluster under the `kube-system` namespace:

    - The `roleRef` attribute specifies that the cluster role to be bound is `cluster-admin`.

    - In `subjects` you list all the users you want bounded to the role indicated in `roleRef`. In this case, there is only the `headlamp-admin` service account.

5. Declare a self-signed "leaf" certificate in `resources/headlamp.homelab.cloud-tls.certificate.cert-manager.yaml`:_

    ~~~yaml
    # TLS certificate for Headlamp
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: headlamp.homelab.cloud-tls
    spec:
      isCA: false
      secretName: headlamp.homelab.cloud-tls
      duration: 2190h # 3 months
      renewBefore: 168h # Certificates must be renewed some time before they expire (7 days)
      dnsNames:
        - headlamp.homelab.cloud
      privateKey:
        algorithm: ECDSA
        size: 521
        encoding: PKCS8
        rotationPolicy: Always
      issuerRef:
        name: homelab.cloud-intm-ca01-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    This certificate is similar to the ones created for the [self-signed CA issuers already explained in the chapter **G029**](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md), except for:

    - The `spec.isCA` parameter set to `false` makes this certificate a "leaf" one that cannot be used to issue other certificates.

    - There is no `spec.commonName` because the official cert-manager documentation recommends setting this attribute only in CA certificates, and leaving it unset in "leaf" certificates.

    - Its `duration` and `renewBefore` values are half of the ones set to the certificate of the intermediate CA issuing this Headlamp certificate.

    - The list in `spec.dnsNames` specifies which domains this certificate corresponds to.

    - The `spec.issuerRef` invokes the intermediate CA already available in your cluster as issuer of this Headlamp certificate.

6. In `resources/headlamp.ingressroute.traefik.yaml`, specify the Traefik `IngressRoute` resource for accessing Headlamp through HTTPS:

    ~~~yaml
    # HTTPS ingress for Headlamp
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute

    metadata:
      name: headlamp
    spec:
      entryPoints:
        - websecure
      routes:
      - match: Host(`headlamp.homelab.cloud`)
        kind: Rule
        services:
        - name: headlamp
          kind: Service
          port: 80
      tls:
        secretName: headlamp.homelab.cloud-tls
    ~~~

    Details to highlight in this Traefik `IngressRoute` declaration are:

    - The `spec.entryPoints` is set to `websecure` only, which corresponds to the Traefik service's HTTPS port.

    - The `spec.routes.match` enables the URL to reach Headlamp through Traefik.

      > [!NOTE]
      > **The domain name must be enabled in your local network**\
      > Your equivalent of the hostname seen in the YAML above will not be reachable unless you enable it from a DNS service (your local network's router could provide it), or specify it in the `hosts` file of the clients you want to access from.

    - The `spec.routes.services` only has an entry for the Headlamp service, linking it to this IngressRoute.

    - The `spec.tls.secretName` points to the secret associated to the Headlamp certificate declared in the previous step. This enables the TLS termination at the ingress level, while the communication with Headlamp will still be done in HTTP.

7. Create the `kustomization.yaml` file for the Kustomize project:

    ~~~sh
    $ touch $HOME/k8sprjs/headlamp/kustomization.yaml
    ~~~

8. Put in the `kustomization.yaml` file the following lines:

    ~~~yaml
    # Headlamp setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: kube-system

    resources:
    - resources/headlamp-admin.serviceaccount.yaml
    - resources/cluster-admin-users.clusterrolebinding.yaml
    - resources/headlamp.homelab.cloud-tls.certificate.cert-manager.yaml
    - resources/headlamp.ingressroute.traefik.yaml
    - https://raw.githubusercontent.com/kubernetes-sigs/headlamp/main/kubernetes-headlamp.yaml
    ~~~

    The `namespace` declaration sets the `kube-system` namespace to all the namespaced resources (the `ClusterRoleBinding` object is not namespaced since it has a cluster-wide nature) declared in this Kustomize project, and also to their invocations within standard Kubernetes objects (not in custom ones). The `kube-system` namespace is where the Headlamp service is going to be deployed. It is important that all namespaced resources are in the same namespace as Headlamp. In particular, the service account must be in the same namespace as Headlamp to authorize this service to access the cluster information it needs to work.

9. Apply the Kustomize project to your cluster:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/headlamp
    ~~~

10. Give Headlamp around a minute to boot up, then verify that its corresponding pod and service are running under the `kube-system` namespace:

    ~~~sh
    $ kubectl get pods,svc -n kube-system | grep headlamp
    pod/headlamp-747b5f4d5-tntzn                  1/1     Running     0          53s
    service/headlamp         ClusterIP      10.43.27.248   <none>        80/TCP                       55s
    ~~~

### Getting the administrator user's service account token

To log in Headlamp with the `headlamp-admin` user you created in its deployment, you need to authenticate with a service account token associated to that user. This is a secret token you can create with `kubectl`:

~~~sh
$ kubectl -n kube-system create token headlamp-admin --duration=8760h
eyJhbGciOiJSUzI1NiIsImtpZCI6ImtxNzh0bmk3cDAzVU4zXzFnMVgwZXVSR3c0U1FnNVZ3OUtSdDBSTkw2WmsifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXFiMnQ1Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI4MjU4Mjc4ZC02YjBmLTQwZDItOTI1Yy1kMzEwMmY3MTkxYzQiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.PG-4qfeT3C6vFfwhdGDoXVmjDEU7TJDTftcmIa2kQO0HtWM8ZN45wDGk4ZSWUR5mO5HlXpYORiGkKHq6GNPFRr_qCo4tKIONyZbgXtV98P6OpOIrfDTJCwxjFf0aqOmEs1N3BqViFs3MgBRCLElx98rD6AXehdxPADXlAksnaypKKx6q1WFgNmOTHfC9WrpQzX-qoo8CbRRCuSyTagm3qkpa5hV5RjyKjE7IaOqQGwFOSbTqMy6eghTYSufC-uUxcOWw3OPVa9QzINOn9_tioxj7tH7rpw_eOHzUW_-Cr_HE89DygnuZAqQEsWxBLfYcrBKtnMhxn49E22SyCaJldA
~~~

Be aware of the following:

- This service account token is associated to the `headlamp-admin` service account which exists in the `kube-system` namespace.

- **The command outputs your `headlamp-admin`'s secret token string directly in your shell**. Remember to copy and save it somewhere safe such as a password manager.

- The `--duration=8760h` makes this token last for 365 days, although you may prefer it to expire sooner for security reasons. [By default, a service account token
  expires after one hour, but it can also expire when the associated pod is deleted](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume). By setting a specific duration, the token will last for the time period set with `--duration`, regardless of what happens to the pod.

  > [!IMPORTANT]
  > **Use the `kubectl create token` command again for refreshing the service account token**\
  > Whenever your current secret token for your `headlamp-admin` service account becomes invalid, generate a new service account token with the same `kubectl` command.

## Testing Headlamp

Now that you have Headlamp deployed, you can test it:

1. Open a browser in your client system and go to `https://headlamp.homelab.cloud/`, or whatever hostname you may have configured for your Headlamp dashboard. The browser will warn you about the connection being insecure. Accept the warning to reach Headlamp's authentication form:

    ![Headlamp authentication form with secret token](images/g031/headlamp-authentication-token.webp "Headlamp authentication form with secret token")

    This form requests an authentication token for signing into Headlamp. Use the `headlamp-admin` service account's token you generated previously to authenticate into Headlamp.

2. After authenticating, you get directly into Headlamp's `Clusters` page:

    ![Headlamp Clusters main page](images/g031/headlamp-clusters-view.webp "Headlamp Clusters main page")

    This the main page of Headlamp. It provides you with a summarized view of your cluster status, including statistics about resources usage and a listing of events that have happened in your cluster. If you happen to have warning events, this page will automatically enable the "Only warnings" mode to show you just warning events.

    Try out the other views Headlamp offers to get familiarized with this tool. In particular, you may like to try out the `Map`:

    ![Headlamp Map view of cluster components](images/g031/headlamp-map-view.webp "Headlamp Map view of cluster components")

    This view provides a zoomable map that can show your cluster components grouped under three different criteria: by namespace, by instance, or by node. This feature will help you to locate more easily any component deployed in your K3s cluster.

## Headlamp's Kustomize project attached to this guide

You can find the Kustomize project for this Headlamp deployment in this attached folder:

- [`k8sprjs/headlamp`](k8sprjs/headlamp/)

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/headlamp`
- `$HOME/k8sprjs/headlamp/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/headlamp/kustomization.yaml`
- `$HOME/k8sprjs/headlamp/resources/cluster-admin-users.clusterrolebinding.yaml`
- `$HOME/k8sprjs/headlamp/resources/headlamp-admin.serviceaccount.yaml`
- `$HOME/k8sprjs/headlamp/resources/headlamp.homelab.cloud-tls.certificate.cert-manager.yaml`
- `$HOME/k8sprjs/headlamp/resources/headlamp.ingressroute.traefik.yaml`

## References

### [Headlamp](https://headlamp.dev/)

- [Installation](https://headlamp.dev/docs/latest/installation/)

### [Kubernetes Documentation](https://kubernetes.io/docs/)

- [Reference. API Access Control. Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
  - [User accounts versus service accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#user-accounts-versus-service-accounts)
  - [Bound service account token volume mechanism](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume)

- [Reference. Command line tool (kubectl)](https://kubernetes.io/docs/reference/kubectl/)
  - [kubectl reference. kubectl create. kubectl create token](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_token/)

### [Traefik Reference](https://doc.traefik.io/traefik/reference/)

- [Routing Configuration](https://doc.traefik.io/traefik/reference/routing-configuration/)
  - [Kubernetes. Kubernetes CRD. HTTP. IngressRoute](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/ingressroute/)

### [Cert-manager](https://cert-manager.io/docs/)

- [Requesting Certificates. Certificate resource](https://cert-manager.io/docs/usage/certificate/)
- [Reference. API Reference. cert-manager.io/v1](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1)
  - [CertificateSpec](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec)

## Navigation

[<< Previous (**G030. K3s cluster setup 13**)](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G032. Deploying services 01**) >>](G032%20-%20Deploying%20services%2001%20~%20Considerations.md)
