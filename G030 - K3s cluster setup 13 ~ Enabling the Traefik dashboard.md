# G030 - K3s cluster setup 13 ~ Enabling the Traefik dashboard

- [Traefik is the embedded ingress controller of K3s](#traefik-is-the-embedded-ingress-controller-of-k3s)
- [Enabling access to the Traefik dashboard](#enabling-access-to-the-traefik-dashboard)
  - [Creating a user for the Traefik dashboard](#creating-a-user-for-the-traefik-dashboard)
  - [Kustomize project for enabling access to the Traefik dashboard](#kustomize-project-for-enabling-access-to-the-traefik-dashboard)
- [Getting into the Traefik dashboard](#getting-into-the-traefik-dashboard)
- [What to do if Traefik's dashboard has bad performance](#what-to-do-if-traefiks-dashboard-has-bad-performance)
- [Traefik dashboard's Kustomize project attached to this guide](#traefik-dashboards-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Traefik documentation](#traefik-documentation)
  - [Traefik in K3s](#traefik-in-k3s)
  - [Kubernetes Documentation](#kubernetes-documentation)
  - [Traefik IngressRoute Vs Ingress](#traefik-ingressroute-vs-ingress)
  - [Kustomize](#kustomize)
- [Navigation](#navigation)

## Traefik is the embedded ingress controller of K3s

Traefik is the default ingress controller that already comes embedded in K3s. In other words, you can enable access to services running in your cluster through Traefik ingresses, instead of just assigning them external IPs directly (in particular, with the MetalLB load balancer).

Traefik in K3s comes with its embedded web dashboard enabled by default, but reaching it requires a particular setup not clearly explained in the official documentation of neither [Traefik](https://doc.traefik.io/traefik/reference/install-configuration/api-dashboard/) nor [K3s](https://docs.k3s.io/networking/networking-services?_highlight=traefik#traefik-ingress-controller).

## Enabling access to the Traefik dashboard

This chapter shows you how to enable HTTPS access to your Traefik dashboard by doing the following:

1. Creating a user to restrict access into the Traefik dashboard.
2. Declaring an `IngressRoute` that enables access to a `TraefikService` where the dashboard is available. This `IngressRoute` enforces authentication with the user created in the previous step.

The first step is just the execution of a command on your `kubectl` client. The other is resolved in the corresponding Kustomize project.

### Creating a user for the Traefik dashboard

Secure the access to your Traefik dashboard by defining at least one user with a password. Traefik demands passwords hashed using MD5, SHA1, or BCrypt, and recommends using the `htpasswd` command to generate them:

1. Start by installing, in your `kubectl` client system, the package providing the `htpasswd` command. The package is `apache2-utils` and, on a Debian based system, you can install it with `apt`:

    ~~~sh
    $ sudo apt install -y apache2-utils
    ~~~

2. Next, use `htpasswd` to generate a user called, for instance, `tfkuser` with the password hashed with the BCrypt encryption:

    ~~~sh
    $ htpasswd -nb -B -C 9 tfkuser Pu7Y0urV3ryS3cr3tP4ssw0rdH3r3
    tfkuser:$2y$17$0mdP4WLdbj8BWj1lIJMDb.bXyYK75qR5AfRNzuunZuCamvAlqDlo.
    ~~~

    > [!IMPORTANT]
    > **Be careful with the value you set to the `-C` option!**\
    > This option indicates the computing time used by the BCrypt algorithm for hashing and, if you set it too high, the Traefik dashboard could end not loading at all. The value you can type here must be between 4 and 17, and the default is 5.

Keep the `htpasswd`'s output at hand, you will use that encrypted string in the next procedure.

### Kustomize project for enabling access to the Traefik dashboard

The next steps set up and deploy the Kustomize project enabling access to your Traefik dashboard:

1. Create the Kustomize project's folder structure:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/traefik-dashboard/{resources,secrets}
    ~~~

    This project has one `resources` subfolder for storing Kubenetes resources declarations, and a `secrets` one to keep a file with the secret string describing the user for accessing the Traefik dashboard.

2. Create the following files within the Kustomize project:

    ~~~sh
    $ touch $HOME/k8sprjs/traefik-dashboard/resources/{traefik-dashboard-basicauth.middleware.traefik.yaml,traefik-dashboard.ingressroute.traefik.yaml} $HOME/k8sprjs/traefik-dashboard/secrets/users
    ~~~

3. In `resources/traefik-dashboard-basicauth.middleware.traefik.yaml` declare the authorization method to use for login in the Traefik dashboard:

    ~~~yaml
    # Basic authentication method for Traefik dashboard
    apiVersion: traefik.io/v1alpha1
    kind: Middleware

    metadata:
      name: traefik-dashboard-basicauth
    spec:
      basicAuth:
        secret: traefik-dashboard-basicauth-secret
    ~~~

    A `Middleware` is a custom Traefik resource, used in this case for configuring a basic authentication method (a user and password login system). In the `spec.basicAuth.secret` parameter, this middleware invokes a `secret` resource which you will declare in a later step of this procedure.

4. Declare in `resources/traefik-dashboard.ingressroute.traefik.yaml` the `IngressRoute` resource enabling access to the Traefik dashboard:

    ~~~yaml
    # HTTPS ingress for Traefik dashboard and API
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute

    metadata:
      name: traefik-dashboard
    spec:
      routes:
      - kind: Rule
        match: Host(`traefik.homelab.cloud`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))
        services:
        - name: api@internal
          kind: TraefikService
        middlewares:
        - name: traefik-dashboard-basicauth
    ~~~

    This is a Traefik `IngressRoute` resource defining the route and the authentication method to access your Traefik dashboard:

    > [!IMPORTANT]
    > **The `IngressRoute` is NOT a standard Kubernetes resource**\
    > It is a customized alternative to the standard `Ingress` Kubernetes object **offered only by Traefik**. Other Ingress controllers may have their own alternatives to the standard Kubernetes Ingress object.

    - In the `spec.entryPoints` there is only the `websecure` option enabled. This means that only the `443` port is enabled as entry point to this route.

    - The `spec.routes.match` parameter indicates to Traefik the valid URL patterns reachable through this `IngressRoute`:

      - First in the pattern is the hostname of the Traefik service set as `Host` value. Next go the possible paths in Traefik, one for its API and the other for the Traefik dashboard.

        Notice the logic operators `&&` (and) and `||` (or) that allow connecting the hostname with the available paths in the service.

        > [!NOTE]
        > **The domains or subdomains you set up as `Host` values will not work just by being put there**\
        > You have to enable them in your network's router or gateway, local DNS or associate them with their corresponding IP in the `hosts` file of any client systems connected to your network that require to know the correct IP for those domains or subdomains.

      - Do not forget any of the backticks characters ( \` ) enclosing the strings in the `Host` directives.

      - The `spec.routes.services` links the `IngressRoute` with the `TraefikService` (a custom Traefik-specific type of Kubernetes `Service`) called `api@internal` through which you can access the Traefik dashboard. Also notice that no service port is specified.

        > [!NOTE]
        > **I have not found a proper explanation for this `api@internal` `TraefikService`**\
        > My bet is for `api@internal` to be some sort of alias or wrapper of the real `traefik` `Service` running in the K3s cluster. This may also explain why it is not necessary to specify which port to connect to in the service.

      - The `spec.routes.match.middlewares` only invokes the basic authentication middleware.

5. In the `secrets/users` file, just paste the encrypted string you got from the `htpasswd` command earlier:

    ~~~sh
    tfkuser:$2y$17$0mdP4WLdbj8BWj1lIJMDb.bXyYK75qR5AfRNzuunZuCamvAlqDlo.
    ~~~

6. Generate a `kustomization.yaml` file at the root folder of this Kustomization project:

    ~~~sh
    $ touch $HOME/k8sprjs/traefik-dashboard/kustomization.yaml
    ~~~

7. In the `kustomization.yaml` file declare your `Kustomization` object for enabling the Traefik dashboard:

    ~~~yaml
    # Traefik dashboard ingress setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: kube-system

    resources:
    - resources/traefik-dashboard-basicauth.middleware.traefik.yaml
    - resources/traefik-dashboard.ingressroute.traefik.yaml

    secretGenerator:
    - name: traefik-dashboard-basicauth-secret
      files:
      - secrets/users
      options:
        disableNameSuffixHash: true
    ~~~

    See that there is a `secretGenerator` block in this `Kustomization` declaration:

    - This is a Kustomize feature that generates `Secret` objects in a Kubernetes cluster from a given configuration.

    - The `namespace` makes all the resources and the secret generated by this Kustomize project to be put under the `kube-system` namespace.

    - The secret is configured with a concrete `name` and `namespace`.  It also has under `files` a reference to the `users` file you created previously under the `secrets` subfolder.

    - The `disableNameSuffixHash` option is required to be `true`. Otherwise, Kustomize will add a hash suffix to the secret's name and your `Middleware` will not be able to find it in the cluster.

      > [!NOTE]
      > **This is an issue between Traefik and Kubernetes Kustomize**\
      > The suffix problem happens because the `Middleware` declares the `Secret`'s name in a non-Kubernetes-standard parameter which Kustomize does not recognize. Therefore, Kustomize cannot replace the name with its hashed version in the `spec.basicAuth.secret` parameter.

    To see how the `Secret` object would look, you can review it with `kubectl kustomize`:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/traefik-dashboard | less
    ~~~

    Look for the `Secret` object in the resulting paginated YAML, it should look like below:

    ~~~yaml
    apiVersion: v1
    data:
      users: |
        dGZrdXNlcjokMnkkMTckMG1kUDRXTGRiajhCV2oxbElKTURiLmJYeVlLNzVxUjVBZlJOenV1blp1
        Q2FtdkFscURsby4K
    kind: Secret
    metadata:
      name: traefik.homelab.cloud-basic-auth-secret
      namespace: kube-system
    type: Opaque
    ~~~

    Notice the following details in this `Secret` object:

    - In the `data.users` parameter there is an odd looking string. This is the content of the `secrets/user` file referenced in the `secretGenerator` block, automatically encoded by Kustomize in base64. You can check that it is the same string on the file by decoding it with `base64 -d` as follows.

        ~~~sh
        $ echo dGZrdXNlcjokMnkkMTckMG1kUDRXTGRiajhCV2oxbElKTURiLmJYeVlLNzVxUjVBZlJOenV1blp1Q2FtdkFscURsby4K | base64 -d
        tfkuser:$2y$17$0mdP4WLdbj8BWj1lIJMDb.bXyYK75qR5AfRNzuunZuCamvAlqDlo.
        ~~~

        See that I've entered the base64 string in one line, while it has been returned split in two in the `Secret` object.

    - The `metadata.name` and `metadata.namespace` are exactly as specified in the `kustomization.yaml` file.

    - The `type` `Opaque` means that the content under `data` is base64-encoded.

8. At last, apply this `Kustomization`:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/traefik-dashboard
    ~~~

## Getting into the Traefik dashboard

Assuming you have enabled the subdomain for the Traefik service as `traefik.homelab.cloud` in your LAN, try to access the URL `https://traefik.homelab.cloud/dashboard`:

1. The first thing you will probably see is a browser warning telling you that the connection is not secure because the certificate is not either. If you check the certificate's information, you will see it being one self-generated by Traefik itself ("verified" by `CN=TRAEFIK DEFAULT CERT`).

2. Right after accepting "the risk" in the security warning, a generic login window will pop up in your browser:

    ![Traefik dashboard window for basic authentication](images/g030/traefik-dashboard_sign-in.webp "Traefik dashboard window for basic authentication")

3. Type your user and password, press on `Sign in` and you will be redirected to the Traefik dashboard's main page available under the `/dashboard/#/` path:

    ![Traefik dashboard main page](images/g030/traefik-dashboard_main-page.webp "Traefik dashboard main page")

## What to do if Traefik's dashboard has bad performance

If your Traefik dashboard seems to load extremely slowly, or just returning a blank page, it could be that you set the `-C` value in the `htpasswd` command too high. For some reason this affects the Traefik dashboard's performance, hitting badly the node were the traefik service is being executed. So, if this is happening to you, try the following.

1. Generate a new user string with `htpasswd` as you saw previously, but with a lower `-C` value than the one you used in the first place. Then replace the string you already have in the `secrets/users` file with the new one.

2. Delete and then reapply the Kustomize project again.

    ~~~sh
    $ kubectl delete -k $HOME/k8sprjs/traefik-dashboard
    $ kubectl apply -k $HOME/k8sprjs/traefik-dashboard
    ~~~

    The `delete` command is just to make sure that the `IngressRoute` resource is regenerated with the change applied.

3. Try to access your Traefik dashboard and see how it runs now.

## Traefik dashboard's Kustomize project attached to this guide

Find the Kustomize project for this Traefik dashboard deployment in the following attached folder:

- [`k8sprjs/traefik-dashboard`](k8sprjs/traefik-dashboard/)

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/traefik-dashboard`
- `$HOME/k8sprjs/traefik-dashboard/resources`
- `$HOME/k8sprjs/traefik-dashboard/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/traefik-dashboard/kustomization.yaml`
- `$HOME/k8sprjs/traefik-dashboard/resources/traefik-dashboard.ingressroute.traefik.yaml`
- `$HOME/k8sprjs/traefik-dashboard/resources/traefik-dashboard.service.yaml`
- `$HOME/k8sprjs/traefik-dashboard/resources/traefik-dashboard-basicauth.middleware.traefik.yaml`
- `$HOME/k8sprjs/traefik-dashboard/secrets/users`

## References

### [Traefik documentation](https://doc.traefik.io/)

- [Reference. Install Configuration. API & Dashboard](https://doc.traefik.io/traefik/reference/install-configuration/api-dashboard/)
- [Reference. Routing Configuration. Kubernetes. Ingress](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/ingress/)
- [Reference. Routing Configuration. Kubernetes. Kubernetes CRD. HTTP. IngressRoute](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/ingressroute/)
- [Reference. Routing Configuration. Kubernetes. Kubernetes CRD. HTTP. Middleware](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/middleware/)

### Traefik in K3s

- [K3s docs. Networking](https://docs.k3s.io/networking)
  - [Traefik Ingress Controller](https://docs.k3s.io/networking/networking-services?_highlight=traefik#traefik-ingress-controller)

- [K3s Rocks. Traefik dashboard](https://k3s.rocks/traefik-dashboard/)
- [Exposing services in a K3S/K3D cluster with Traefik](https://www.ivankrizsan.se/2024/07/12/exposing-services-in-a-k3s-k3d-cluster-with-traefik/)

### [Kubernetes Documentation](https://kubernetes.io/docs/home/)

- [Concepts. Overview. Objects In Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
  - [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)
    - [Labels selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)
    - [Equality-based requirement](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#equality-based-requirement)

- [Concepts. Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/)
  - [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

### Traefik IngressRoute Vs Ingress

- [What is the difference between a Kubernetes Ingress and a IngressRoute?](https://stackoverflow.com/questions/60177488/what-is-the-difference-between-a-kubernetes-ingress-and-a-ingressroute)
- [Steps to expose services using Kubernetes Ingress](https://www.golinuxcloud.com/steps-to-expose-services-using-kubernetes-ingress/)
- [Directing Kubernetes traffic with Traefik](https://opensource.com/article/20/3/kubernetes-traefik)
- [Ingress with Traefik on K3s](https://itnext.io/ingress-with-treafik-on-k3s-53db6e751ed3)
- [K3s issue. Documentation on ingress](https://github.com/k3s-io/k3s/issues/436)

### [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)

- [configMapGenerator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/)
- [secretGenerator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/secretgenerator/)
- [generatorOptions](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/generatoroptions/)

## Navigation

[<< Previous (**G029. K3s cluster setup 12**)](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20self-signed%20CA.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G031. K3s cluster setup 14**) >>](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md)
