# G029 - K3s cluster setup 12 ~ Setting up cert-manager and self-signed CA

- [Use cert-manager to handle certificates in your cluster](#use-cert-manager-to-handle-certificates-in-your-cluster)
- [Warning about cert-manager performance](#warning-about-cert-manager-performance)
- [Deploying cert-manager](#deploying-cert-manager)
  - [Verifying the deployment of cert-manager](#verifying-the-deployment-of-cert-manager)
  - [Installing the cert-manager plugin in your `kubectl` client system](#installing-the-cert-manager-plugin-in-your-kubectl-client-system)
- [Setting up a self-signed CA for your cluster](#setting-up-a-self-signed-ca-for-your-cluster)
- [Checking your certificates with the cert-manager command line tool](#checking-your-certificates-with-the-cert-manager-command-line-tool)
- [Cert-manager's Kustomize project attached to this guide](#cert-managers-kustomize-project-attached-to-this-guide)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [cert-manager](#cert-manager)
  - [About setting up cert-manager](#about-setting-up-cert-manager)
  - [About the self-signed CA](#about-the-self-signed-ca)
- [Navigation](#navigation)

## Use cert-manager to handle certificates in your cluster

Although Traefik has some capabilities to handle certificates, it's better to use a service specialized on such task. Enter **cert-manager**, a popular certificate management service in the Kubernetes landscape.

## Warning about cert-manager performance

The first time I tried to deploy cert-manager, the deployment failed because the nodes (in particular the server node) didn't have enough CPU cores to run the process properly. And when I managed to deploy cert-manager successfully, I noticed how my cluster's performance degraded severely. Eventually, I could fix these performance issues just by increasing the cores assigned as vCPUs to each VM in my K3s cluster.

Therefore, if you face the same performance issues, improve the hardware capabilities (CPU in particular) assigned to your cluster VMs to deploy and run cert-manager.

## Deploying cert-manager

At the time of writing this, there is no official Kustomize way for deploying cert-manager. The default method is by applying a yaml manifest, but you can build your own Kustomize procedure with it (as you've done for the `metrics-server` deployment in the [previous **G028** guide](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deployment-of-metrics-server)).

1. In your `kubectl` client system, create a folder structure for cert-manager:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/cert-manager/deployment/{patches,resources}
    ~~~

    The deployment project has to be put in its own `deployment` subfolder because, later, you will need to create another project for creating a self-signed root CA ([_Certificate Authority_](https://en.wikipedia.org/wiki/Certificate_authority)).

2. Create a `certificates.namespace.yaml` file under `deployment/resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/cert-manager/deployment/resources/certificates.namespace.yaml
    ~~~

3. Declare a `certificates` namespace in the `certificates.namespace.yaml` file:

    ~~~yaml
    # Namespace for certificates
    apiVersion: v1
    kind: Namespace

    metadata:
      name: certificates
    ~~~

    By default, cert-manager looks for the certificates secrets in its own `cert-manager` namespace. The idea with this `certificates` namespace is to keep separated the certificates and their secrets from the cert-manager components.

4. Create a `cert-manager.deployment.patch.yaml` file under `deployment/patches`:

    ~~~sh
    $ touch $HOME/k8sprjs/cert-manager/deployment/patches/cert-manager.deployment.patch.yaml
    ~~~

5. Declare this deployment patch into `cert-manager.deployment.patch.yaml`:

    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: cert-manager
      namespace: cert-manager
    spec:
      template:
        spec:
          containers:
            - name: cert-manager-controller
              args:
              - --v=2
              - --cluster-resource-namespace=certificates
              - --leader-election-namespace=kube-system
              - --acme-http01-solver-image=quay.io/jetstack/cert-manager-acmesolver:v1.18.2
              - --max-concurrent-challenges=60
    ~~~

    This is a patch to make cert-manager look for the certificates' secrets in the `certificates` namespace. The argument to edit to adjust this namespace is `--cluster-resource-namespace`, while the others are left with the values they have in the original deployment declaration for the cert-manager _controller_ component.

    > [!IMPORTANT]
    > **Review this patch whenever you update the cert-manager!**\
    > Every time you update the cert-manager service in your setup, do not forget to see how the patched values look in the official deployment declaration of the newer version you deploy. Otherwise, you could end up having errors due to using deprecated arguments or incorrect values.

6. Create a `kustomization.yaml` file in the `deployment` subfolder:

    ~~~sh
    $ touch $HOME/k8sprjs/cert-manager/deployment/kustomization.yaml
    ~~~

7. Declare the cert-manager complete setup in the `kustomization.yaml` file:

    ~~~yaml
    # cert-manager setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - resources/certificates.namespace.yaml
    - https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml

    patches:
    - path: patches/cert-manager.deployment.patch.yaml
    ~~~

    > [!NOTE]
    > **Find the URL for the newest cert-manager version [in its official installation procedure with `kubectl`](https://cert-manager.io/docs/installation/kubectl/)**\
    > You can also find the YAML file in the assets list of [each release](https://github.com/jetstack/cert-manager/releases).

8. Deploy cert-manager with `kubectl`:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/cert-manager/deployment/
    ~~~

    This command prints a long output of lines indicating the many components that get created in the deployment of cert-manager.

### Verifying the deployment of cert-manager

After the deployment has finished successfully, give it around a minute to allow cert-manager to initialize itself and start its pods. Then, you can verify that cert-manager has deployed properly just by checking if its pods are `Running`:

~~~sh
$ kubectl -n cert-manager get pods
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-b5cc5b7c5-84x2m               1/1     Running   0          63s
cert-manager-cainjector-7cf6557c49-2bdr2   1/1     Running   0          63s
cert-manager-webhook-58f4cff74d-v6chb      1/1     Running   0          63s
~~~

Notice the namespace `cert-manager` specified with the `-n` option in the `kubectl` command. The cert-manager service deploys itself in its own `cert-manager` namespace.

> [!NOTE]
> **Use `kubectl` to discover the namespaces existing in your cluster**\
> Get a list of all the existing namespaces within your K3s cluster with `kubectl` like this:
>
> ~~~sh
> $ kubectl get namespaces
> NAME              STATUS   AGE
> cert-manager      Active   94s
> certificates      Active   94s
> default           Active   14d
> kube-node-lease   Active   14d
> kube-public       Active   14d
> kube-system       Active   14d
> metallb-system    Active   11d
> ~~~

### Installing the cert-manager plugin in your `kubectl` client system

To help you to manage the certificates you put in your cluster, [cert-manager offers an independent command line tool](https://cert-manager.io/docs/reference/cmctl/). You have to install it in your `kubectl` client system, then add it to your user's `$PATH`.

You can install this cert-manager command line tool in a `kubectl` client system like the one configured in the [**G026** chapter](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md) as follows:

1. From the [cert-manager command line tool GitHub releases page](https://github.com/cert-manager/cmctl/releases), download the `tar.gz` file that corresponds to the cert-manager version you installed in your cluster and to your `kubectl` client system:

    ~~~sh
    $ wget https://github.com/cert-manager/cmctl/releases/download/v2.3.0/cmctl_linux_amd64.tar.gz -O $HOME/bin/cmctl_linux_amd64.tar.gz
    ~~~

2. Extract the content of the downloaded `cmctl_linux_amd64.tar.gz`:

    ~~~sh
    $ cd $HOME/bin
    $ tar xf cmctl_linux_amd64.tar.gz
    ~~~

    This will extract these files:

    - The command line tool as a `cmctl` binary.

    - A `LICENSE` and a `README.md` file that you can remove together with the `cmctl_linux_amd64.tar.gz`:

      ~~~sh
      $ rm cmctl_linux_amd64.tar.gz LICENSE README.md
      ~~~

3. Restrict the binary's permissions:

    ~~~sh
    $ chmod 700 cmctl
    ~~~

4. Make a symbolic link to the new `cmctl` command named `kubectl-cert_manager`:

    ~~~sh
    $ ln -s cmctl kubectl-cert_manager
    ~~~

    This allows you to use the `cmctl` command as a plugin integrated with `kubectl`.

5. Test `cmctl` with `kubectl` by checking its version:

    ~~~sh
    $ kubectl cert-manager version
    Client Version: util.Version{GitVersion:"v2.3.0", GitCommit:"29b59b934c5a6f533b2d278f4541dca89d1eb288", GitTreeState:"", GoVersion:"go1.24.5", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: &versionchecker.Version{Detected:"v1.18.2", Sources:map[string]string{"crdLabelVersion":"v1.18.2"}}
    ~~~

6. You can also check if the cert-manager API is accessible:

    ~~~sh
    $ kubectl cert-manager check api
    The cert-manager API is ready
    ~~~

Know that the cert-manager's `kubectl` plugin has other commands available, [check them out in its official page](https://cert-manager.io/docs/reference/cmctl/).

## Setting up a self-signed CA for your cluster

You have the tools deployed in your cluster, now you can create a self-signed CA for it. This CA will be necessary to be able to issue self-signed certificates for the other services you will deploy in later chapters of this guide:

1. Create a folder structure for a Kustomize project within the already existing `cert-manager` path:

    ~~~sh
    $ mkdir -p $HOME/k8sprjs/cert-manager/certificates/resources
    ~~~

2. In the `resources` directory, create five empty YAML files:

    ~~~sh
    $ touch $HOME/k8sprjs/cert-manager/certificates/resources/{homelab.cloud-root-ca-issuer-selfsigned.cluster-issuer.cert-manager.yaml,homelab.cloud-root-ca-crt.certificate.cert-manager.yaml,homelab.cloud-root-ca-issuer.cluster-issuer.cert-manager.yaml,homelab.cloud-intm-ca01-crt.certificate.cert-manager.yaml,homelab.cloud-intm-ca01-issuer.cluster-issuer.cert-manager.yaml}
    ~~~

    Each YAML will describe a particular resource required for setting up the root CA properly.

3. In the `homelab.cloud-root-ca-issuer-selfsigned.cluster-issuer.cert-manager.yaml` file enter this YAML:

    ~~~yaml
    # # Self-signed cluster-wide issuer for the root CA's certificate
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer

    metadata:
      name: homelab.cloud-root-ca-issuer-selfsigned
    spec:
      selfSigned: {}
    ~~~

    This is the issuer that will "self-sign" your root CA's certificate:

    - The `apiVersion` points to the cert-manager API, not to the Kubernetes one.

    - The `kind` is `ClusterIssuer` (a cert-manager kind, not a Kubernetes one), meaning this particular issuer will be available for all the namespaces in your cluster.

    - The `name` is a descriptive string, like the YAML filename.

    - Within the `spec` section, you see the empty parameter `selfSigned`. This means that this issuer is of the simplest type you can have, the self-signed one. **It is not trusted by browsers**, but it is enough to generate certificates that you can use within your own local or home network.

4. Copy in `homelab-cloud-root-ca-crt.certificate.cert-manager.yaml` this YAML:

    ~~~yaml
    # Certificate for root CA
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: homelab.cloud-root-ca-crt
      namespace: certificates
    spec:
      isCA: true
      commonName: homelab.cloud-root-ca-crt
      secretName: homelab.cloud-root-ca-crt-secret
      duration: 8760h # 1 year
      renewBefore: 720h # Certificates must be renewed some time before they expire (30 days)
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      issuerRef:
        name: homelab.cloud-root-ca-issuer-selfsigned
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    To know more about all the parameters shown above, check [the cert-manager v1 api document here](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1). Still, I'll explain you some particularities of this certificate declaration:

    - Many of the parameters are optional, and there are more that are not used here.

    - Here the API is also a cert-manager one. Be careful of the `apiVersion` you use. Cert-manager has several, [each with its own API documentation](https://cert-manager.io/docs/reference/api-docs/).

    - The `namespace` is the one declared in the deployment of cert-manager, `certificates`. As intended, this certificate for the root CA and its secret will be kept under the `certificates` namespace together with other certificates.

    - This certificate is not associated to any particular domain for security reasons. Root CA certificates are not meant to be exposed in any HTTPS communication, they are only used to sign other certificates.

    - The `duration` determines how long the certificate lasts. Since this particular certificate is only used to sign others, you want it to last longer than the ones generated from it. On the other hand, it is also good to refresh it as frequently as possible. Therefore, a duration of one year is a good compromise, at least for a homelab environment.

    - The `renewBefore` is about when to start the renewal of the certificate. This time period should be as short as possible, but always bearing in mind that the certificates derived from this one will also have to be renewed. In a small homelab setup, this period could be even shorter than the thirty days specified in the YAML above.

    - The parameter `spec.isCA` allows you to turn a certificate into a Certificate Authority. When the value is `true`, you can use this certificate to sign other certificates issued by other issuers that rely on this CA's secret.

    - In the `spec.privateKey` section, be careful of always having `rotationPolicy` set as `Always`. This makes cert-manager regenerate the certificate's secret rather than reusing the current one. This policy about private key rotation is also [described in the cert-manager documentation](https://cert-manager.io/docs/usage/certificate/#configuring-private-key-rotation).

    - In the `spec.issuerRef` you specify the issuer of this certificate, in this case the `homelab.cloud-root-ca-issuer-selfsigned` one you created in previous steps. Be careful of always also specifying its `kind`, in particular for `ClusterIssuer` types, so you know clearly what kind of issuer you are using with each certificate.

5. Fill the `homelab.cloud-root-ca-issuer.cluster-issuer.cert-manager.yaml` file like this:

    ~~~yaml
    # Cluster-wide issuer using root CA's secret
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: homelab.cloud-root-ca-issuer
    spec:
      ca:
        secretName: homelab.cloud-root-ca-crt-secret
    ~~~

    This is a different cluster wide issuer that uses the root CA's secret to issue and sign other certificates.

6. Put the following YAML in the `homelab.cloud-intm-ca01-crt.certificate.cert-manager.yaml`:

    ~~~yaml
    # Certificate for intermediate CA 01
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: homelab.cloud-intm-ca01-crt
      namespace: certificates
    spec:
      isCA: true
      commonName: homelab.cloud-intm-ca01-crt
      secretName: homelab.cloud-intm-ca01-crt-secret
      duration: 4380h # 6 months
      renewBefore: 360h # Certificates must be renewed some time before they expire (15 days)
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      issuerRef:
        name: homelab.cloud-root-ca-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    This certificate is like the one for the root CA, but is meant to be an _intermediate_ CA. Since this certificate's secret will be the one used to issue and sign the certificates for the services you will deploy in later chapters, it has a shorter `duration` and `renewBefore` time periods. Also notice that this certificate's name is numbered (`01`), hinting at the possibility of having more than one intermediate CA. And like the root CA's certificate, see how this certificate is not attached to any particular domain.

7. Copy in `homelab.cloud-intm-ca01-issuer.cluster-issuer.cert-manager.yaml` this other YAML:

    ~~~yaml
    # Cluster-wide issuer using intermediate CA 01's secret
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: homelab.cloud-intm-ca01-issuer
    spec:
      ca:
        secretName: homelab.cloud-intm-ca01-crt-secret
    ~~~

    This is the intermediate CA cluster issuer you will use to issue and sign the certificates for the apps and services you will deploy in later chapters. In this case, this issuer uses the corresponding secret of the intermediate CA 01's certificate declared in the previous step.

    > [!NOTE]
    > **Cluster issuers can issue certificates in any namespace**\
    > The apps and services you will deploy in later chapters of this guide are going to run in different namespaces. This makes necessary the use of a cluster issuer to issue the certificates and their corresponding secrets, since **secrets in Kubernetes are not shared among namespaces**.

8. Next, create the `kustomization.yaml` file in the `certificates` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/cert-manager/certificates/kustomization.yaml
    ~~~

9. Copy in `kustomization.yaml` the following yaml.

    ~~~yaml
    # Certificates deployment
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - resources/homelab.cloud-root-ca-issuer-selfsigned.cluster-issuer.cert-manager.yaml
    - resources/homelab.cloud-root-ca-crt.certificate.cert-manager.yaml
    - resources/homelab.cloud-root-ca-issuer.cluster-issuer.cert-manager.yaml
    - resources/homelab.cloud-intm-ca01-crt.certificate.cert-manager.yaml
    - resources/homelab.cloud-intm-ca01-issuer.cluster-issuer.cert-manager.yaml
    ~~~

    See how the resources are ordered to ensure that first the root CA is created, then the intermediate CA 01.

10. Apply the Kustomize project into your cluster:

    ~~~sh
    $ kubectl apply -k $HOME/k8sprjs/cert-manager/certificates
    ~~~

11. Confirm that the resources have been deployed in the cluster:

    ~~~sh
    $ kubectl -n kube-system get clusterissuer
    NAME                                      READY   AGE
    homelab.cloud-intm-ca01-issuer            True    36s
    homelab.cloud-root-ca-issuer              True    36s
    homelab.cloud-root-ca-issuer-selfsigned   True    36s

    $ kubectl -n certificates get certificate
    NAME                          READY   SECRET                               AGE
    homelab.cloud-intm-ca01-crt   True    homelab.cloud-intm-ca01-crt-secret   67s
    homelab.cloud-root-ca-crt     True    homelab.cloud-root-ca-crt-secret     67s

    $ kubectl -n certificates get secrets
    NAME                                 TYPE                DATA   AGE
    homelab.cloud-intm-ca01-crt-secret   kubernetes.io/tls   3      100s
    homelab.cloud-root-ca-crt-secret     kubernetes.io/tls   3      101s
    ~~~

12. As a final verification, use `kubectl` to get a detailed description of your new issuers' current status:

    ~~~sh
    $ kubectl describe ClusterIssuer
    Name:         homelab.cloud-intm-ca01-issuer
    Namespace:    
    Labels:       <none>
    Annotations:  <none>
    API Version:  cert-manager.io/v1
    Kind:         ClusterIssuer
    Metadata:
      Creation Timestamp:  2025-09-25T10:12:17Z
      Generation:          1
      Resource Version:    58766
      UID:                 56bc5d19-b6e5-4f98-8a16-677923e09d1d
    Spec:
      Ca:
        Secret Name:  homelab.cloud-intm-ca01-crt-secret
    Status:
      Conditions:
        Last Transition Time:  2025-09-25T10:12:18Z
        Message:               Signing CA verified
        Observed Generation:   1
        Reason:                KeyPairVerified
        Status:                True
        Type:                  Ready
    Events:
      Type     Reason           Age                    From                         Message
      ----     ------           ----                   ----                         -------
      Warning  ErrGetKeyPair    5m23s (x2 over 5m23s)  cert-manager-clusterissuers  Error getting keypair for CA issuer: secrets "homelab.cloud-intm-ca01-crt-secret" not found
      Warning  ErrInitIssuer    5m23s (x2 over 5m23s)  cert-manager-clusterissuers  Error initializing issuer: secrets "homelab.cloud-intm-ca01-crt-secret" not found
      Normal   KeyPairVerified  5m18s (x3 over 5m22s)  cert-manager-clusterissuers  Signing CA verified


    Name:         homelab.cloud-root-ca-issuer
    Namespace:    
    Labels:       <none>
    Annotations:  <none>
    API Version:  cert-manager.io/v1
    Kind:         ClusterIssuer
    Metadata:
      Creation Timestamp:  2025-09-25T10:12:17Z
      Generation:          1
      Resource Version:    58755
      UID:                 8c23cbc5-abf0-44f8-abf4-6240e6ce9149
    Spec:
      Ca:
        Secret Name:  homelab.cloud-root-ca-crt-secret
    Status:
      Conditions:
        Last Transition Time:  2025-09-25T10:12:17Z
        Message:               Signing CA verified
        Observed Generation:   1
        Reason:                KeyPairVerified
        Status:                True
        Type:                  Ready
    Events:
      Type     Reason           Age                    From                         Message
      ----     ------           ----                   ----                         -------
      Warning  ErrGetKeyPair    5m23s (x2 over 5m23s)  cert-manager-clusterissuers  Error getting keypair for CA issuer: secrets "homelab.cloud-root-ca-crt-secret" not found
      Warning  ErrInitIssuer    5m23s (x2 over 5m23s)  cert-manager-clusterissuers  Error initializing issuer: secrets "homelab.cloud-root-ca-crt-secret" not found
      Normal   KeyPairVerified  5m18s (x3 over 5m23s)  cert-manager-clusterissuers  Signing CA verified


    Name:         homelab.cloud-root-ca-issuer-selfsigned
    Namespace:    
    Labels:       <none>
    Annotations:  <none>
    API Version:  cert-manager.io/v1
    Kind:         ClusterIssuer
    Metadata:
      Creation Timestamp:  2025-09-25T10:12:17Z
      Generation:          1
      Resource Version:    58724
      UID:                 25a212c9-5353-443d-a209-19cdce8b8e4a
    Spec:
      Self Signed:
    Status:
      Conditions:
        Last Transition Time:  2025-09-25T10:12:17Z
        Observed Generation:   1
        Reason:                IsReady
        Status:                True
        Type:                  Ready
    Events:                    <none>
    ~~~

    The three issuers are ready, although the `homelab.cloud-intm-ca01-issuer` and `homelab.cloud-root-ca-issuer` ones had initialization problems (reported as `Warning` events) due probably to the delay in the creation of the secrets they use.

## Checking your certificates with the cert-manager command line tool

Remember that the cert-manager command line tool can help you in handling your certificates. For instance, you can execute the following command to see the status of the root CA certificate you have created before:

~~~sh
$ kubectl cert-manager status certificate -n certificates homelab.cloud-root-CA-crt
Name: homelab.cloud-root-ca-crt
Namespace: certificates
Created at: 2025-09-25T12:12:17+02:00
Conditions:
  Ready: True, Reason: Ready, Message: Certificate is up to date and has not expired
DNS Names:
Events:
  Type    Reason     Age   From                                       Message
  ----    ------     ----  ----                                       -------
  Normal  Issuing    17m   cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  17m   cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "homelab.cloud-root-ca-crt-qg2gw"
  Normal  Requested  17m   cert-manager-certificates-request-manager  Created new CertificateRequest resource "homelab.cloud-root-ca-crt-1"
  Normal  Issuing    17m   cert-manager-certificates-issuing          The certificate has been successfully issued
Issuer:
  Name: homelab.cloud-root-ca-issuer-selfsigned
  Kind: ClusterIssuer
  Conditions:
    Ready: True, Reason: IsReady, Message: 
  Events:  <none>
Secret:
  Name: homelab.cloud-root-ca-crt-secret
  Issuer Country: 
  Issuer Organisation: 
  Issuer Common Name: homelab.cloud-root-ca-crt
  Key Usage: Digital Signature, Key Encipherment, Cert Sign
  Extended Key Usages: 
  Public Key Algorithm: Ed25519
  Signature Algorithm: Ed25519
  Subject Key ID: aa363d5fa86d4c050ed1c1c03e288cf69ee86065
  Authority Key ID: 
  Serial Number: 0f41d655e213c9f7c6a9edcb1c6c4cda
  Events:  <none>
Not Before: 2025-09-25T12:12:17+02:00
Not After: 2026-09-25T12:12:17+02:00
Renewal Time: 2026-08-26T12:12:17+02:00
No CertificateRequest found for this Certificate
~~~

## Cert-manager's Kustomize project attached to this guide

You can find the Kustomize project for the cert-manager deployment in this folder:

- [`k8sprjs/cert-manager`](k8sprjs/cert-manager/)

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/bin`
- `$HOME/k8sprjs/cert-manager`
- `$HOME/k8sprjs/cert-manager/deployment`
- `$HOME/k8sprjs/cert-manager/deployment/patches`
- `$HOME/k8sprjs/cert-manager/deployment/resources`
- `$HOME/k8sprjs/cert-manager/certificates`
- `$HOME/k8sprjs/cert-manager/certificates/resources`

### Files in `kubectl` client system

- `$HOME/bin/cmctl`
- `$HOME/bin/kubectl-cert_manager`
- `$HOME/k8sprjs/cert-manager/deployment/kustomization.yaml`
- `$HOME/k8sprjs/cert-manager/deployment/patches/cert-manager.deployment.patch.yaml`
- `$HOME/k8sprjs/cert-manager/deployment/resources/certificates.namespace.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/kustomization.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/homelab.cloud-intm-ca01-crt.certificate.cert-manager.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/homelab.cloud-intm-ca01-issuer.cluster-issuer.cert-manager.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/homelab.cloud-root-ca-crt.certificate.cert-manager.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/homelab.cloud-root-ca-issuer.cluster-issuer.cert-manager.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/homelab.cloud-root-ca-issuer-selfsigned.cluster-issuer.cert-manager.yaml`

## References

### [cert-manager](https://cert-manager.io/)

- [Documentation](https://cert-manager.io/docs/)
  - [cert-manager installation with Kubectl](https://cert-manager.io/docs/installation/kubectl/)
  - [The cert-manager Command Line Tool (cmctl)](https://cert-manager.io/docs/reference/cmctl/)
  - [API reference](https://cert-manager.io/docs/reference/api-docs/)

- [cert-manager on GitHub](https://github.com/jetstack/cert-manager)

### About setting up cert-manager

- [Deep Dive into cert-manager and Cluster Issuers in Kubernetes](https://support.tools/cert-manager-deep-dive/)
- [Setting up HTTPS with cert-manager (self-signed, LetsEncrypt) in kubernetes](https://someweb.github.io/devops/cert-manager-kubernetes/)
- [Creating Self Signed Certificates on Kubernetes](https://tech.paulcz.net/blog/creating-self-signed-certs-on-kubernetes/)
- [Install Certificate Manager Controller in Kubernetes](https://blog.zachinachshon.com/cert-manager/#self-signed-certificate)
- [How to configure Traefik on Kubernetes with Cert-manager?](https://cloud.theodo.com/en/blog/traefik-kubernetes-certmanager)
- [PKCS#1 and PKCS#8 format for RSA private key](https://stackoverflow.com/questions/48958304/pkcs1-and-pkcs8-format-for-rsa-private-key)

### About the self-signed CA

- [Self-signed Root CA in Kubernetes with k3s, cert-manager and traefik. Bonus howto on regular certificates](https://raymii.org/s/tutorials/Self_signed_Root_CA_in_Kubernetes_with_k3s_cert-manager_and_traefik.html)
- [Wikipedia. Certificate authority](https://en.wikipedia.org/wiki/Certificate_authority)

## Navigation

[<< Previous (**G028. K3s cluster setup 11**)](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G030. K3s cluster setup 13**) >>](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Headlamp%20dashboard.md)
