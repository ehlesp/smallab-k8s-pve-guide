# G029 - K3s cluster setup 12 ~ Setting up cert-manager and wildcard certificate

Although Traefik has some capabilities to handle certificates, it's better to use a service specialized on such task. Enter **cert-manager**, a popular certificate management service in the Kubernetes landscape.

## Warning about cert-manager performance

The first time I tried to deploy cert-manager, the deployment failed because the nodes (in particular the server node) didn't had enough CPU cores to run the process properly. And when I managed to deploy cert-manager successfully, I noticed how my cluster's performance degraded severely. Eventually, I could fix these performance issues just by increasing the cores assigned as vCPUs to each VM in my K3s cluster.

Therefore, be aware that, depending on how you've configured your VMs, you may need to improve their assigned hardware capabilities (CPU in particular).

## Deploying cert-manager

At the time of writing this, there's no official Kustomize way for deploying cert-manager. The default method is by applying a yaml manifest, but you can build your own Kustomize procedure with it (as you've done for the `metrics-server` deployment in the previous [**G028** guide](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md#deployment-of-metrics-server)).

1. In your kubectl client system, create a folder structure for cert-manager.

    ~~~bash
    $ mkdir -p $HOME/k8sprjs/cert-manager/deployment
    ~~~

    The deployment project will be in its own `deployment` subfolder because, later, you'll need to create another project for creating a self-signed wildcard certificate. This second Kustomize project will require the cert-manager service already deployed in your cluster, but must be kept independent from its deployment process.

2. Create a `kustomization.yaml` file in the `deployment` subfolder.

    ~~~bash
    $ touch $HOME/k8sprjs/cert-manager/deployment/kustomization.yaml
    ~~~

3. Edit the `kustomization.yaml` file so it has the yaml content below.

    ~~~yaml
    # cert-manager setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - 'https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml'
    ~~~

    You can find the URL for the most recent version of cert-manager right [in the official documentation about the installation procedure](https://cert-manager.io/docs/installation/), although you can also find it on the assets list of [each release](https://github.com/jetstack/cert-manager/releases).

4. Deploy cert-manager with `kubectl`.

    ~~~bash
    $ kubect apply -k $HOME/k8sprjs/cert-manager/deployment/
    ~~~

    You'll get a long output of lines indicating the many resources created by the  deployment.

### _Verifying the deployment of cert-manager_

After the deployment has finished successfully, give it a minute or so to allow cert-manager to initialize itself and start its pods. Then, you can verify that cert-manager has deployed properly just by checking if its pods are `Running`.

~~~bash
$ kubectl -n cert-manager get pods
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-cainjector-967788869-wg8pd   1/1     Running   0          116s
cert-manager-55658cdf68-6m5k2             1/1     Running   0          116s
cert-manager-webhook-6668fbb57d-f5xmc     1/1     Running   0          116s
~~~

Notice the namespace `cert-manager` specified with the `-n` option in the `kubectl` command. The cert-manager service deploys itself in its own `cert-manager` namespace, as MetalLB deployed in its own `metallb-system` namespace.

Remember that you can also check out the all existing namespaces in your K3s cluster with `kubectl`.

~~~bash
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   2d1h
kube-system       Active   2d1h
kube-public       Active   2d1h
kube-node-lease   Active   2d1h
metallb-system    Active   47h
cert-manager      Active   2m51s
~~~

### _Installing the cert-manager plugin in your kubectl client system_

To help you to manage the certificates you put in your cluster, [cert-manager has a plugin for kubectl](https://cert-manager.io/docs/usage/kubectl-plugin/). You'll have to install it in your kubectl client system and make it reachable through your user's `$PATH`. Assuming the same scenario as in the [**G026** guide](G026%20-%20K3s%20cluster%20setup%2009%20~%20Setting%20up%20a%20kubectl%20client%20for%20remote%20access.md), where you saw how to set up your kubectl client system, the installation of this cert-manager plugin requires the following steps

1. From the [cert-manager GitHub releases page](https://github.com/jetstack/cert-manager/releases), download the `tar.gz` file that corresponds to the cert-manager version you installed in your cluster and to your kubectl client system. In this guide, you'll install cert-manager `v1.6.1` and the client system is assumed to be a Linux OS running on an amd64 hardware.

    ~~~bash
    $ wget https://github.com/jetstack/cert-manager/releases/download/v1.6.1/kubectl-cert_manager-linux-amd64.tar.gz -O $HOME/bin/kubectl-cert_manager-linux-amd64.tar.gz
    ~~~

2. Extract the content of the downloaded `kubectl-cert_manager-linux-amd64.tar.gz`.

    ~~~bash
    $ cd $HOME/bin
    $ tar xf kubectl-cert_manager-linux-amd64.tar.gz
    ~~~

    This will extract two files, the `kubectl-cert_manager` binary and a `LICENSES` text file that you can remove together with the `kubectl-cert_manager-linux-amd64.tar.gz`.

    ~~~bash
    $ rm kubectl-cert_manager-linux-amd64.tar.gz LICENSES
    ~~~

3. Restrict the binary's permissions.

    ~~~bash
    $ chmod 700 kubectl-cert_manager
    ~~~

4. Test the cert-manager plugin with `kubectl` by checking its version.

    ~~~bash
    $ kubectl cert-manager version
    Client Version: util.Version{GitVersion:"v1.6.1", GitCommit:"5ecf5b5617a4813ea8115da5dcfe3cd18b8ff047", GitTreeState:"clean", GoVersion:"go1.17.1", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: &versionchecker.Version{Detected:"v1.6.1", Sources:map[string]string{"crdLabelVersion":"v1.6.1", "webhookPodImageVersion":"v1.6.1", "webhookPodLabelVersion":"v1.6.1", "webhookServiceLabelVersion":"v1.6.1"}}
    ~~~

5. You can also check if the cert-manager API is accessible.

    ~~~bash
    $ kubectl cert-manager check api
    The cert-manager API is ready
    ~~~

Know that the cert-manager's kubectl plugin has other several commands available, [check them out in its official page](https://cert-manager.io/docs/usage/kubectl-plugin/).

## Reflector, a solution for syncing secrets and configmaps

In Kubernetes, a certificate has an associated _secret_ object which is what truly contains the encrypted key. This is a problem in the sense that **secret and configmap objects are not shared among namespaces**. For instance, if you created a certificate in the `cert-manager` namespace, you wouldn't be able to use it directly (meaning, its associated secret) in the `kube-system` namespace. You need to replicate, or sync, the secret somehow in all the namespaces you want to use it.

### _Solving the problem of syncing secrets clusterwide_

What can you do to sync secrets among namespaces in your K3s cluster? There are some options to solve this problem.

- The most basic procedure would be to create a certificate on each namespace in which it's required. This method would force you to create those certificates configured for concrete domains, since you don't want to have several different certificates for the same wildcard domain. Doable only when dealing with a small number of certificates, hard to maintain when their number increases.

- Other procedure is creating one certificate and then cloning it on each namespace. The problem is that, although initially the certificates' secrets would be the same, right after the first renovation, those secrets would change and stop being in sync. This would force you to "sync" them (that is, overwriting the cloned secrets with the one you want to have in common) manually, something you can imagine is rather cumbersome.

- [In this GitHub page](https://github.com/zakkg3/ClusterSecret) there's a definition for a Kubernetes object called **ClusterSecret**. As it's name implies, this object is designed to be a secret shared clusterwide. It's a very interesting and valid option, but it has been designed with only secret objects in mind, and also implies some manual tinkering on your certificates' secrets.

- The ideal option is to have an addon capable of handling certificates clusterwide properly. And no, cert-manager is not capable of doing this, but [in its documentation](https://cert-manager.io/docs/faq/kubed/) they recommend using an addon called [**kubed**](https://github.com/kubeops/kubed): "_Kubed can keep ConfigMaps and Secrets synchronized across namespaces and/or clusters_". Although it sounds that it could fit our case, this addon presents two problems:
    - Kubed doesn't handle the cert-manager certificates themselves, you would still be forced to tinker with their corresponding secrets so they can be handled properly by kubed.
    - Kubed [needs Helm to be installed](https://appscode.com/products/kubed/v0.12.0/setup/install/), no matter what. This is not a problem per se (it would only imply installing Helm in your kubectl client system), but in this guide series I want to stick with `kubectl` since it's the standard basic way of managing any Kubernetes cluster.

- There's another addon, called [Reflector](https://github.com/EmberStack/kubernetes-reflector), which not only handles "mirroring" of **secrets and configmaps** among different namespaces present in a cluster, but also has an extension that explicitly manages the secrets of cert-manager certificates **automatically**. Furthermore, it has a manifest file deployable with `kubectl`. Hence why I've chosen this addon to make your domain's certificate available clusterwide.

### _Deploying Reflector_

Let's create its own Kustomize project for Reflector and deploy it in your K3s cluster.

1. Create the folder for the Kustomize project.

    ~~~bash
    $ mkdir -p $HOME/k8prjs/reflector
    ~~~

2. Create the `kustomization.yaml` file.

    ~~~bash
    $ touch $HOME/k8prjs/reflector/kustomization.yaml
    ~~~

3. Put in `kustomization.yaml` the following content.

    ~~~yaml
    # Reflector setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: kube-system

    resources:
    - https://github.com/emberstack/kubernetes-reflector/releases/latest/download/reflector.yaml
    ~~~

    See that the link to the yaml manifest specifies "_latest_" as version which, at the time of writing this, is [the _v6.0.42_ one](https://github.com/emberstack/kubernetes-reflector/releases/tag/v6.0.42). Also notice how there's a `namespace` parameter pointing to `kube-system`, this will make Reflector be deployed in that namespace.

4. Deploy the Reflector Kustomize project.

    ~~~bash
    $ kubectl apply -k $HOME/k8prjs/reflector/
    ~~~

5. The addon will be deployed in the `kube-system` namespace and start a pod on one of your agents. Check it out with `kubectl`.

    ~~~bash
    $ kubectl -n kube-system get pods
    NAME                                     READY   STATUS       RESTARTS       AGE
    helm-install-traefik-crd--1-bjv95        0/1     Completed    0              2d4h
    helm-install-traefik--1-zb5gb            0/1     Completed    1              2d4h
    local-path-provisioner-64ffb68fd-zxm2v   1/1     Terminated   5 (60m ago)    2d4h
    coredns-85cb69466-9l6ws                  1/1     Terminated   5 (146m ago)   2d4h
    traefik-74dd4975f9-tdv42                 1/1     Terminated   5 (146m ago)   2d2h
    metrics-server-5b45cf8dbb-nv477          1/1     Terminated   3 (146m ago)   21h
    reflector-5f484c4868-8wgkz               1/1     Running      0              64s
    ~~~

    Also notice how other pods appear with their `STATUS` as `Terminated`, although they count as `READY` and, therefore, they should have the `Running` status like your newest reflector pod. This is an example of an odd consequence of configuring the graceful shutdown on your K3s nodes, as I already warned you about in the last section of the [G025 guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md).

## Setting up a wildcard certificate for a domain

You have the tools deployed in your cluster, now you can create a wildcard certificate for a domain. In this case, I'll configure the certificate for the domain I've been using all along this guide series, `deimos.cloud`, as an example.

1. Create a folder structure for a Kustomize project within the already existing `cert-manager` path.

    ~~~bash
    $ mkdir -p $HOME/k8sprjs/cert-manager/certificates/resources
    ~~~

2. In the `resources` directory, create three empty files as follows.

    ~~~bash
    $ touch $HOME/k8sprjs/cert-manager/certificates/resources/{certificates.namespace.yaml,cluster-issuer-selfsigned.cluster-issuer.cert-manager.yaml,wildcard.deimos.cloud-tls.certificate.cert-manager.yaml}
    ~~~

    Each one will contain the yaml describing a particular resource required for setting up the certificate.

3. In `certificates.namespace.yaml` put the following yaml.

    ~~~yaml
    apiVersion: v1
    kind: Namespace

    metadata:
      name: certificates
    ~~~

    This is the `certificates` namespace, which will help you to organize your own certificates and distinguish them from any other certificates and secrets already present in your cluster.

4. In the `cluster-issuer-selfsigned.cluster-issuer.cert-manager.yaml` file, copy the yaml below.

    ~~~yaml
    # Generic self-signed cluster-wide issuer for certificates
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer

    metadata:
      name: cluster-issuer-selfsigned
    spec:
      selfSigned: {}
    ~~~

    This is the issuer that will sign your certificates. Notice several things in the short yaml above.

    - The `apiVersion` points to the cert-manager API, not to the Kubernetes one.

    - The `kind` is `ClusterIssuer` (a cert-manager kind, not a Kubernetes one), meaning this particular issuer will be available cluster wide.

    - The `name` is a descriptive string, like the yaml filename.

    - Within the `spec` section, you see the empty parameter `selfSigned`. This means that this issuer is of the simplest type you can have, the self signed one. It's **not trusted** by browsers, but it's enough to generate certificates that you can use within your own local or home network.

5. In `wildcard.deimos.cloud-tls.certificate.cert-manager.yaml`, copy the whole yaml below.

    ~~~yaml
    # Wilcard certificate for deimos.cloud
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: wildcard.deimos.cloud-tls
      namespace: certificates
    spec:
      secretName: wildcard.deimos.cloud-tls
      secretTemplate:
        annotations:
          reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
          reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "kube-system"
          reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
          reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "kube-system"
      duration: 8760h # No certificate should last more than a year
      renewBefore: 720h # Certificates must be renewed some time before they expire (30 days)
      isCA: false
      subject:
        organizations:
        - "Deimos"
      privateKey:
        algorithm: ECDSA
        size: 384
        encoding: PKCS8
        rotationPolicy: Always
      dnsNames:
      - "*.deimos.cloud"
      - "deimos.cloud"
      issuerRef:
        name: cluster-issuer-selfsigned
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    To know more about all the parameters shown above, check [the cert-manager v1 api document here](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1) and also [the Reflector's documentation about its cert-manager support](https://github.com/EmberStack/kubernetes-reflector#cert-manager-support). Still, I'll explain below some particular details of this yaml file.

    - Many of the parameters are optional, and there are more that are not used here.

    - Here the API is also a cert-manager one. Be careful of the `apiVersion` you use. Cert-manager has several, [each with its own API documentation](https://cert-manager.io/docs/reference/api-docs/).

    - The `spec.secretTemplate` section allows you to put metadata annotations in the secret generated for this certificate, something you need to use to put the values Reflector needs to clone this secret in other namespaces. The `reflector.v1.k8s.emberstack.com` parameters are the ones that enable Reflector to manage the secret of this certificate.
        - `reflection-allowed` allows Reflector to mirror this certificate's secret in other namespaces.
        - `reflection-allowed-namespaces` contains the list of namespaces in which Reflector has to clone this certificate's secret.
        - `reflection-auto-enabled` allows Reflector to clone automatically this certificate's secret in other namespaces.
        - `reflection-auto-namespaces` is the list of namespaces in which Reflector can clone this certificate's secret automatically.
        > **BEWARE!**  
        > Reflector won't notices the changes done to the annotations in the certificate resource itself. It's only aware of what's specified in the directly related secret generated from this certificate. In upcoming guides I'll show you how to deal with changes in these annotations so Reflector does its thing as expected.

    - The parameter `spec.isCA` allows you to turn a certificate into a Certificate Authority. When the value is `true`, you can use this certificate to sign other certificates issued by other issuers that rely on this CA's secret. In this case is left as `false` for not complicating things further at this point. You can find an example of how to boostrap an issuer with a self-signed CA [in this cert-manager page](https://cert-manager.io/docs/configuration/selfsigned/#bootstrapping-ca-issuers).

    - In the `spec.privateKey` section, be careful of always having `rotationPolicy` set as `Always`. This makes cert-manager regenerate the certificate's secret rather than reusing the current one. This policy about private key rotation is also [described in the cert-manager documentation](https://cert-manager.io/docs/usage/certificate/#configuring-private-key-rotation).

    - In the `spec.dnsNames` you can put any domain names you like, not necessarily just the ones related to a particular main domain. For instance, you can have `your.domain.com` and `another.domain.io` put in that list.

    - In the `spec.issuerRef` you specify the issuer of this certificate, in this case the `cluster-issuer-selfsigned-main` one you created in previous steps. Be careful of always also specifying its `kind`, in particular for `ClusterIssuer` types, so you know clearly what kind of issuer you've used with each certificate.

6. Next, create the `kustomization.yaml` file in the `certificates` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/cert-manager/certificates/kustomization.yaml
    ~~~

7. Copy in `kustomization.yaml` the following yaml.

    ~~~yaml
    # Certificates deployment
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - resources/certificates.namespace.yaml
    - resources/cluster-issuer-selfsigned.cluster-issuer.cert-manager.yaml
    - resources/wildcard.deimos.cloud-tls.certificate.cert-manager.yaml
    ~~~

8. Apply the Kustomize project into your cluster.

    ~~~bash
    $ kubectl apply -k $HOME/k8sprjs/cert-manager/certificates
    ~~~

9. Confirm that the resources have been deployed in the cluster.

    ~~~bash
    $ kubectl get namespaces 
    NAME              STATUS   AGE
    default           Active   2d6h
    kube-system       Active   2d6h
    kube-public       Active   2d6h
    kube-node-lease   Active   2d6h
    metallb-system    Active   2d4h
    cert-manager      Active   4h41m
    certificates      Active   87s

    $ kubectl -n kube-system get clusterissuer
    NAME                        READY   AGE
    cluster-issuer-selfsigned   True    3m22s

    $ kubectl -n certificates get certificate
    NAME                        READY   SECRET                      AGE
    wildcard.deimos.cloud-tls   True    wildcard.deimos.cloud-tls   4m

    $ kubectl get secrets -A | grep wildcard
    certificates      wildcard.deimos.cloud-tls                            kubernetes.io/tls                     3      4m30s
    kube-system       wildcard.deimos.cloud-tls                            kubernetes.io/tls                     3      4m29s
    ~~~

    The cluster issuer shows up and also your certificate is there, in the namespace `certificates`. Your certificate's secret is too in the same `certificates` namespace, but Reflector has done its job automatically and has reflected the secret in the `kube-system` namespace.

> **BEWARE!**  
> If you delete the certificate from the cluster, the copies of its secret won't be removed with it. You'll have to delete them manually.

## Checking your certificate with the `kubectl` cert-manager plugin

Remember that the kubectl cert-manager plugin can help you in handling your certificates. For instance, you would execute the following command to see the status of the certificate you've created before.

~~~bash
$ kubectl cert-manager status certificate -n certificates wildcard.deimos.cloud-tls
Name: wildcard.deimos.cloud-tls
Namespace: certificates
Created at: 2021-11-30T18:41:42+01:00
Conditions:
  Ready: True, Reason: Ready, Message: Certificate is up to date and has not expired
DNS Names:
- *.deimos.cloud
- deimos.cloud
Events:
  Type    Reason     Age   From          Message
  ----    ------     ----  ----          -------
  Normal  Issuing    10m   cert-manager  Issuing certificate as Secret does not exist
  Normal  Generated  10m   cert-manager  Stored new private key in temporary Secret resource "wildcard.deimos.cloud-tls-6rfrc"
  Normal  Requested  10m   cert-manager  Created new CertificateRequest resource "wildcard.deimos.cloud-tls-b4jx4"
  Normal  Issuing    10m   cert-manager  The certificate has been successfully issued
Issuer:
  Name: cluster-issuer-selfsigned
  Kind: ClusterIssuer
  Conditions:
    Ready: True, Reason: IsReady, Message: 
  Events:  <none>
Secret:
  Name: wildcard.deimos.cloud-tls
  Issuer Country: 
  Issuer Organisation: Deimos
  Issuer Common Name: 
  Key Usage: Digital Signature, Key Encipherment
  Extended Key Usages: 
  Public Key Algorithm: ECDSA
  Signature Algorithm: ECDSA-SHA384
  Subject Key ID: 
  Authority Key ID: 
  Serial Number: efd14f0cb15d9f179b9e5c68bb6a3205
  Events:  <none>
Not Before: 2021-11-30T18:41:43+01:00
Not After: 2022-11-30T18:41:43+01:00
Renewal Time: 2022-10-31T18:41:43+01:00
No CertificateRequest found for this Certificate
~~~

## Cert-manager and Reflector's Kustomize projects attached to this guide series

You can find the Kustomize projects for the cert-manager and Reflector deployments in the following attached folders.

- `k8sprjs/cert-manager`
- `k8sprjs/reflector`

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/bin`
- `$HOME/k8sprjs/cert-manager`
- `$HOME/k8sprjs/cert-manager/deployment`
- `$HOME/k8sprjs/cert-manager/certificates`
- `$HOME/k8sprjs/cert-manager/certificates/resources`
- `$HOME/k8sprjs/reflector`

### _Files in `kubectl` client system_

- `$HOME/bin/kubectl-cert_manager`
- `$HOME/k8sprjs/cert-manager/deployment/kustomization.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/kustomization.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/certificates.namespace.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/cluster-issuer-selfsigned.cluster-issuer.cert-manager.yaml`
- `$HOME/k8sprjs/cert-manager/certificates/resources/wildcard.deimos.cloud-tls.certificate.cert-manager.yaml`
- `$HOME/k8sprjs/reflector/kustomization.yaml`

## References

### _cert-manager_

- [cert-manager official site](https://cert-manager.io/)
- [cert-manager on GitHub](https://github.com/jetstack/cert-manager)
- [cert-manager installation with Kubectl](https://cert-manager.io/docs/installation/kubectl/)
- [Using Kubectl's new Kustomize support for per-environment deployment of cert-manager resources](https://www.jetstack.io/blog/kustomize-cert-manager/)
- [cert-manager compatibility with Kubernetes Platform Providers](https://cert-manager.io/docs/installation/compatibility/)
- [cert-manager kubectl plugin](https://cert-manager.io/docs/usage/kubectl-plugin/)
- [cert-manager API reference docs](https://cert-manager.io/docs/reference/api-docs/)
- [cert-manager docs](https://cert-manager.io/docs/)
- [cert-manager on GitHub](https://github.com/jetstack/cert-manager)
- [Installing and using Cert-Manager in Kubernetes](https://headworq.eu/en/installing-and-using-cert-manager-in-kubernetes/)
- [Use of Let's Encrypt wildcard certs in Kubernetes](https://rimusz.net/lets-encrypt-wildcard-certs-in-kubernetes)
- [Setting up HTTPS with cert-manager (self-signed, LetsEncrypt) in kubernetes](https://someweb.github.io/devops/cert-manager-kubernetes/)
- [Creating Self Signed Certificates on Kubernetes](https://tech.paulcz.net/blog/creating-self-signed-certs-on-kubernetes/)
- [Installing and using Cert-Manager in Kubernetes](https://headworq.eu/en/installing-and-using-cert-manager-in-kubernetes/)
- [Install Certificate Manager Controller in Kubernetes](https://blog.zachinachshon.com/cert-manager/#self-signed-certificate)
- [How to configure Traefik on Kubernetes with Cert-manager?](https://www.padok.fr/en/blog/traefik-kubernetes-certmanager)
- [PKCS#1 and PKCS#8 format for RSA private key](https://stackoverflow.com/questions/48958304/pkcs1-and-pkcs8-format-for-rsa-private-key)
- [Add to documentation: change default port of webhook when using hostNetwork and default Kubelet port settings](https://github.com/jetstack/cert-manager/issues/3472)
- [add "webhook.hostNetwork" to helm chart](https://github.com/jetstack/cert-manager/issues/3163)
- [Compatibility with Kubernetes Platform Providers. AWS EKS](https://cert-manager.io/docs/installation/compatibility/#aws-eks)

### _Reflector_

- [Reflector on GitHub](https://github.com/EmberStack/kubernetes-reflector)

### _The problem of syncing secrets_

- [ClusterSecret](https://github.com/zakkg3/ClusterSecret)
- [Kubed official page](https://appscode.com/products/kubed/)
- [Kubed on GitHub](https://github.com/kubeops/kubed)
- [Faq cert-manager. Syncing Secrets Across Namespaces](https://cert-manager.io/docs/faq/kubed/)
- [Sharing secret across namespaces](https://stackoverflow.com/questions/46297949/sharing-secret-across-namespaces)

## Navigation

[<< Previous (**G028. K3s cluster setup 11**)](G028%20-%20K3s%20cluster%20setup%2011%20~%20Deploying%20the%20metrics-server%20service.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G030. K3s cluster setup 13**) >>](G030%20-%20K3s%20cluster%20setup%2013%20~%20Deploying%20the%20Kubernetes%20Dashboard.md)
