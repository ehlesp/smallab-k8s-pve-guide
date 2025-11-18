# G033 - Deploying services 02 ~ Seafile - Part 4 - Seafile server

- [Seafile server is deployed as another component](#seafile-server-is-deployed-as-another-component)
- [Considerations about the Seafile server](#considerations-about-the-seafile-server)
- [Seafile server Kustomize subproject's folders](#seafile-server-kustomize-subprojects-folders)
- [Seafile server configuration file](#seafile-server-configuration-file)
- [Seafile server secrets](#seafile-server-secrets)
- [Seafile server storage](#seafile-server-storage)
- [Seafile server TLS certificate](#seafile-server-tls-certificate)
- [Seafile server StatefulSet resource](#seafile-server-statefulset-resource)
- [Seafile server Service resource](#seafile-server-service-resource)
- [Seafile server Kustomize project](#seafile-server-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Seafile server project on its own](#do-not-deploy-this-seafile-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Seafile](#seafile)
  - [Kubernetes](#kubernetes)
    - [ConfigMaps](#configmaps)
    - [Related contents about ConfigMaps and Secrets](#related-contents-about-configmaps-and-secrets)
    - [Storage](#storage)
    - [Related contents about Kubernetes storage](#related-contents-about-kubernetes-storage)
    - [StatefulSets](#statefulsets)
    - [Environment variables](#environment-variables)
  - [UTC offset](#utc-offset)
- [Navigation](#navigation)

## Seafile server is deployed as another component

This part covers the Kustomize configuration of the Seafile server as another component components of the whole Seafile platform setup. It is an adapted version from the [single node Kubernetes setup explained in the Seafile official documentation](https://manual.seafile.com/latest/setup/k8s_single_node/).

## Considerations about the Seafile server

The Seafile server prepared in this part is the [_Community Edition_ (_CE_) version](https://manual.seafile.com/latest/setup/setup_ce_by_docker/), and is just the main web application for file syncing and sharing. Seafile has some other optional extensions that are left out of this guide.

The Seafile server comes in its own container image. This image also includes a preconfigured Caddy web server for serving the Seafile web application, so the main remaining concerns are:

- Configure the Seafile server to use the Valkey and MariaDB services prepared in the previous parts of this Seafile deployment procedure.
- Make the Seafile server claim the storage volume prepared for storing users data.
- Configure an ingress to the Seafile server with a TLS certificate.

## Seafile server Kustomize subproject's folders

As with the other components, you need a folder structure for the Seafile server Kustomize subproject:

~~~sh
$ mkdir -p $HOME/k8sprjs/seafile/components/server-seafile/{configs,resources,secrets}
~~~

## Seafile server configuration file

The Seafile server configuration is handled with a set of environment variables that are better put together in the same `ConfigMap` resource. This resource can be invoked from the `StatefulSet` you declare later for deploying the Seafile server. The problem is that certain values to be specified in that `ConfigMap` have to be injected from the `ConfigMap` and `Secret` resources declared for the Valkey and MariaDB servers to avoid duplications. Kubernetes does not allow for injecting values into ConfigMaps or Secrets, forcing to declare those particular environment variables directly in the `StatefulSet` so their values can be injected, [as it was done with MariaDB in the previous part](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource).

Knowing this, the `ConfigMap` resource for your Seafile server must only contain the environment variables that have non-injected values:

1. Create a `envs.properties` file under the `configs` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/configs/env.properties
    ~~~

2. Put in the new `envs.properties` file the following environment variables:

    ~~~properties
    # General options
    TIME_ZONE=UTC+1
    SEAFILE_LOG_TO_STDOUT=true
    SITE_ROOT=/
    INIT_SEAFILE_ADMIN_EMAIL=admin@seafile.homelab.cloud

    # Connectivity parameters
    SEAFILE_SERVER_HOSTNAME=seafile.homelab.cloud
    SEAFILE_SERVER_PROTOCOL=https

    # Cache server connection
    CACHE_PROVIDER=redis
    REDIS_HOST=10.43.100.2
    REDIS_PORT=6379

    # Database server connection
    SEAFILE_MYSQL_DB_HOST=10.43.100.3
    SEAFILE_MYSQL_DB_PORT=3306
    ~~~

    These environment variables are just the ones needed to run a basic Seafile server:

    - `TIME_ZONE`\
      Specify here the [time zone in UTC offset format](https://en.wikipedia.org/wiki/List_of_UTC_offsets) that is most convenient for you.

    - `SEAFILE_LOG_TO_STDOUT`\
      Enabling this option makes the Seafile server to print all its logs directly in the standard output of the system (usually the shell) where is running rather than storing them in a log file. This is common for services executed in a container, although it also means that those logs are lost when the container is stopped.

    - `SITE_ROOT`\
      Indicates the root path for the Seafile web app. In other words, if the hostname of the Seafile server is `seafile.homelab.cloud`, this value would be added after the hostname like `seafile.homelab.cloud/SITE_ROOT/`.

      > [!NOTE]
      > **This environment variable is not explained in the Seafile official documentation**\
      > This explanation is just my take on this value based on my experience with other web application servers.

    - `INIT_SEAFILE_ADMIN_EMAIL`\
      The email to use as login for the Seafile server administrator, which will be set automatically during the initialization of Seafile server. The password has a similar environment variable, but that will be injected in the `StatefulSet` from a `Secret` resource you will create right in the next section.

    - `SEAFILE_SERVER_HOSTNAME`\
      The hostname for the Seafile server.

    - `SEAFILE_SERVER_PROTOCOL`\
      To make your Seafile server encrypt its communications with clients with the TLS certificate you will declare later, specify `https` here.

    - `CACHE_PROVIDER`\
      Seafile server can use one of two different types of caching systems, Memcached and Redis. Since Valkey is a compatible alternative to Redis, you have to specify `Redis` here.

    - `REDIS_HOST`\
      Specify here the cluster IP of your [Seafile's Valkey service](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service-resource).

    - `REDIS_PORT`\
      Specify here the same server TCP port number from your [Seafile's Valkey service](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service-resource).

    - `SEAFILE_MYSQL_DB_HOST`\
      Set here the cluster IP of your [Seafile's MariaDB service](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-service-resource).

    - `SEAFILE_MYSQL_DB_PORT`\
      Set here the same server TCP port number from your [Seafile's MariaDB service](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-service-resource)

## Seafile server secrets

There are two secrets you need to declare as `Secret` resources for your Seafile server, the password for the administrator user and a JWT private key that Seafile requires to run:

1. Create a new `seafile.pwd` in the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/secrets/seafile.pwd
    ~~~

2. In `secrets/seafile.pwd` declare the secrets for Seafile:

    ~~~properties
    seafile_admin_password=Y0ur_rE3e41Ly.lOng-S3kreT_P4s5woRd-heRE!
    seafile_jwt_private_key=aR4ND0mAlF4nUmeR1k5Tr1nGOfNol3s57h4n32Ch4RaKt3Rs
    ~~~

    > [!WARNING]
    > **The secrets have to be put in `seafile.pwd` as plain unencrypted text**\
    > Be careful of who can access this `seafile.pwd` file.

    While you can put any string as your administrator password, be aware that your JWT private key has to be a random alphanumeric string of **no less than 32 characters**. To generate it, Seafile's official documentation recommends using the command `pwgen -s 40 1` which you could execute in your `kubectl` client system.

## Seafile server storage

Like its [MariaDB database](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-storage), Seafile needs storage to persist data. Here you will declare the `PersistentVolumeClaim` that links your Seafile server with the persistent volume (declared in the last part of this Seafile deployment procedure) that will hold its users data:

1. Create a `server-seafile.persistentvolumeclaim.yaml` file under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.persistentvolumeclaim.yaml
    ~~~

2. Declare the `PersistentVolumeClaim` in `resources/server-seafile.persistentvolumeclaim.yaml` with the declaration next:

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-seafile
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: data-seafile
      resources:
        requests:
          storage: 9.8G
    ~~~

## Seafile server TLS certificate

To encrypt the communications between your Seafile server and its clients, you need a TLS certificate [like the one created previously in the deployment of Headlamp back in the chapter **G031**](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md#deploying-headlamp).

1. Create a `seafile.homelab.cloud-tls.certificate.cert-manager.yaml` file under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/resources/seafile.homelab.cloud-tls.certificate.cert-manager.yaml
    ~~~

2. Declare the certificate in `resources/seafile.homelab.cloud-tls.certificate.cert-manager.yaml`:

    ~~~yaml
    # Certificate for Seafile
    apiVersion: cert-manager.io/v1
    kind: Certificate

    metadata:
      name: seafile.homelab.cloud-tls
    spec:
      isCA: false
      secretName: seafile.homelab.cloud-tls
      duration: 2190h # 3 months
      renewBefore: 168h # Certificates must be renewed some time before they expire (7 days)
      dnsNames:
        - seafile.homelab.cloud
        - sfl.homelab.cloud
      ipAddresses:
        - 10.7.0.3
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      issuerRef:
        name: homelab.cloud-intm-ca01-issuer
        kind: ClusterIssuer
        group: cert-manager.io
    ~~~

    This certificate is adjusted to work with the DNS names and external IP address the Seafile server will have in the local network.

## Seafile server StatefulSet resource

Since the Seafile server stores data, it is more adequate to deploy it as a `StatefulSet` rather than a `Deployment` resource:

1. Create a `server-seafile.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.statefulset.yaml
    ~~~

2. Declaration the `StatefulSet` below in `resources/server-seafile.statefulset.yaml`:

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-seafile
    spec:
      replicas: 1
      serviceName: server-seafile
      template:
        spec:
          containers:
          - name: server
            image: seafileltd/seafile-mc:13.0-latest
            ports:
            - containerPort: 443
              name: server-seafile-https
            env:
            - name: JWT_PRIVATE_KEY
              valueFrom:
                secretKeyRef:
                  name: server-seafile
                  key: seafile_jwt_private_key
            - name: INIT_SEAFILE_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-seafile
                  key: seafile_admin_password
            - name: SEAFILE_MYSQL_DB_SEAFILE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: seafile-db-name
            - name: SEAFILE_MYSQL_DB_USER
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: seafile-username
            - name: SEAFILE_MYSQL_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: seafile-user-password
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-valkey
                  key: valkey-password
            envFrom:
            - configMapRef:
                name: seafile-env
            resources:
              limits:
                cpu: "0.75"
                memory: 512Mi
            volumeMounts:
            - name: server-seafile-storage
              mountPath: /opt/seafile-data
            - name: certificate
              subPath: seafile.homelab.cloud-tls.crt
              mountPath: /opt/seafile-caddy/certs/seafile.homelab.cloud-tls.crt
            - name: certificate
              subPath: seafile.homelab.cloud-tls.key
              mountPath: /opt/seafile-caddy/certs/seafile.homelab.cloud-tls.key
          volumes:
          - name: server-seafile-storage
            persistentVolumeClaim:
              claimName: server-seafile
          - name: certificate
            secret:
              secretName: seafile.homelab.cloud-tls
              defaultMode: 0444
              items:
              - key: tls.crt
                path: seafile.homelab.cloud-tls.crt
              - key: tls.key
                path: seafile.homelab.cloud-tls.key
    ~~~

    Unlike with the pods for the [Valkey](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-deployment-resource) and [MariaDB](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%203%20-%20MariaDB%20database%20server.md#mariadb-statefulset-resource) components, the pod within Seafile server's `StatefulSet` is composed only by one `server` container. This is because, at the time of writing this, there is no Prometheus metrics exporter for Seafile:

    - `server` container\
      This container runs the Community Edition of the Seafile server.

      - The container `image` deployed is the one for the version 13.0 of Seafile.

      - The `containerPort` enables the `443` port for HTTPS communication, and its given a name for clarity when invoked from a `Service` resource [as you will see later](#seafile-server-service-resource).

      - The `env` section declares all the Seafile environment variables that have their values injected from other `ConfigMap` and `Secret` resources.

      - The `envFrom` loads all the environment values from [the `configs/env.properties` file you set earlier](#seafile-server-configuration-file).

      - The `resources.limits` block imposes an upper limit to the CPU and RAM the Seafile server can consume.

      - Under `volumeMounts` are three mount points declared:

        - MountPath `/opt/seafile-data` where all Seafile-related data will be stored.

        - MountPath `/opt/seafile-caddy/certs/seafile.homelab.cloud-tls.crt` is the path for the Seafile certificate _crt_ file.

        - MountPath `/opt/seafile-caddy/certs/seafile.homelab.cloud-tls.key` is the path for the file containing the Seafile certificate's private key.

        > [!NOTE]
        > **Caddy handles the HTTPS connections**\
        > Seafile uses [Caddy](https://caddyserver.com/) as its web server. This is why the certificate's files must be put in the `/opt/seafile-caddy/certs/` path to allow Caddy to find and use them to encrypt HTTPS connections with clients.

    - In `template.spec.volumes` is declared the `PersistentVolumeClaim` that enables the Seafile data storage and also the files that exist within [the TLS certificate declared earlier](#seafile-server-tls-certificate). Notice how the certificate files are restricted to be read-only with the `defaultMode` parameter.

## Seafile server Service resource

Your Seafile StatefulSet requires a `Service` called `server-seafile` to run:

1. Create a file called `server-seafile.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.service.yaml
    ~~~

2. Declare the `Service` in `resources/server-seafile.service.yaml`:

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: server-seafile
    spec:
      type: LoadBalancer
      clusterIP: 10.43.100.1
      loadBalancerIP: 10.7.0.3
      ports:
      - name: server-seafile-https
        port: 443
        targetPort: server-seafile-https
        protocol: TCP
    ~~~

    This `Service` resource has a number of differences compared with the ones you have declared before for the other Seafile platform components:

    - This Service's `type` is `LoadBalancer`, meaning that it would take the next available IP from the MetalLB pool to use as external public IP in your network. But you can also set an IP manually, picked from the ones available in the load balancer's pool, with the `loadBalancerIP` parameter.

    - A `LoadBalancer` type service can also have an internal `clusterIP`, and you can see how I have chosen to set it [with the IP picked previously in the part 1 of this Seafile procedure](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%201%20-%20Outlining%20setup,%20arranging%20storage%20and%20choosing%20service%20IPs.md#choosing-static-cluster-ips-for-seafile-related-services). You could leave this value unassigned and allow Kubernetes to give it any internal cluster IP, but consider that having a known static IP can be also advantageous.

    - With the `loadBalancerIP` parameter you set a `LoadBalancer` type `Service` with the IP you want it to get from your cluster's load balancer (MetalLB in this case). In the YAML above, `10.7.0.3` is right the next one after the IP already assigned to the [Headlamp service (`10.7.0.2`)](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md).

    - Since there is no Prometheus metric exporter nor a port through which the Seafile server could provide such metrics, there is only one port declared in this `Service` resource:

      - The `port` this service exposes is for enabling HTTPS connections with clients.

      - The `targetPort` ensures that the service redirects all TCP traffic coming through its `port` towards the Seafile server container's port called `server-seafile-https`. Thanks to using the container port's name rather than its number, you can change the port in the container and the `Service` resource will keep its port pointing to the right container port.

## Seafile server Kustomize project

With all the necessary elements for your Seafile server component declared in their respective files, you can put them together as a Kustomize project:

1. Create a `kustomization.yaml` file in the `server-seafile` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/seafile/components/server-seafile/kustomization.yaml
    ~~~

2. Declare your Seafile server `Kustomization` in `kustomization.yaml`:

    ~~~yaml
    # Seafile server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-seafile

    resources:
    - resources/seafile.homelab.cloud-tls.certificate.cert-manager.yaml
    - resources/server-seafile.persistentvolumeclaim.yaml
    - resources/server-seafile.service.yaml
    - resources/server-seafile.statefulset.yaml

    replicas:
    - name: server-seafile
      count: 1

    images:
    - name: seafileltd/seafile-mc
      newTag: 13.0-latest

    configMapGenerator:
    - name: server-seafile
      envs:
      - configs/env.properties

    secretGenerator:
    - name: server-seafile
      envs:
      - secrets/seafile.pwd
    ~~~

    This `kustomization.yaml`, compared to the ones you have already set up for the Valkey and MariaDB components, does not have anything in particular to highlight. All the parameters specified there should be familiar to you at this point. The only major difference to notice is the presence of only one image, since the Seafile server pod is not composed by two containers put together in sidecar mode.

### Validating the Kustomize YAML output

As with the other components, you should check the output generated by this Kustomize project:

1. Generate the YAML with `kubectl kustomize` as usual:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/seafile/components/server-seafile | less
    ~~~

2. See if your YAML output looks like the one below:

    ~~~yaml
    apiVersion: v1
    data:
      CACHE_PROVIDER: redis
      INIT_SEAFILE_ADMIN_EMAIL: admin@seafile.homelab.cloud
      REDIS_HOST: 10.43.100.2
      REDIS_PORT: "6379"
      SEAFILE_LOG_TO_STDOUT: "true"
      SEAFILE_MYSQL_DB_HOST: 10.43.100.3
      SEAFILE_MYSQL_DB_PORT: "3306"
      SEAFILE_SERVER_HOSTNAME: seafile.homelab.cloud
      SEAFILE_SERVER_PROTOCOL: https
      SITE_ROOT: /
      TIME_ZONE: UTC+1
    kind: ConfigMap
    metadata:
      labels:
        app: server-seafile
      name: server-seafile-6h884959tc
    ---
    apiVersion: v1
    data:
      seafile_admin_password: |
        WTB1cl9yRTNlNDFMeS5sT25nLVMza3JlVF9QNHM1d29SZC1oZVJFIQo=
      seafile_jwt_private_key: YVI0TkQwbUFsRjRuVW1lUjFrNVRyMW5HT2ZOb2wzczU3aDRuMzJDaDRSYUt0M1JzCg==
    kind: Secret
    metadata:
      labels:
        app: server-seafile
      name: server-seafile-k749htgc28
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: server-seafile
      name: server-seafile
    spec:
      clusterIP: 10.43.100.1
      loadBalancerIP: 10.7.0.3
      ports:
      - name: server-seafile-https
        port: 443
        protocol: TCP
        targetPort: server-seafile-https
      selector:
        app: server-seafile
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-seafile
      name: server-seafile
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.8G
      storageClassName: local-path
      volumeName: data-seafile
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-seafile
      name: server-seafile
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-seafile
      serviceName: server-seafile
      template:
        metadata:
          labels:
            app: server-seafile
        spec:
          containers:
          - env:
            - name: JWT_PRIVATE_KEY
              valueFrom:
                secretKeyRef:
                  key: seafile_jwt_private_key
                  name: server-seafile-k749htgc28
            - name: INIT_SEAFILE_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: seafile_admin_password
                  name: server-seafile-k749htgc28
            - name: SEAFILE_MYSQL_DB_SEAFILE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  key: seafile-db-name
                  name: db-mariadb
            - name: SEAFILE_MYSQL_DB_USER
              valueFrom:
                configMapKeyRef:
                  key: seafile-username
                  name: db-mariadb
            - name: SEAFILE_MYSQL_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: seafile-user-password
                  name: db-mariadb
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: valkey-password
                  name: cache-valkey
            envFrom:
            - configMapRef:
                name: seafile-env
            image: seafileltd/seafile-mc:13.0-latest
            name: server
            ports:
            - containerPort: 443
              name: server-seafile-https
            resources:
              limits:
                cpu: "0.75"
                memory: 512Mi
            volumeMounts:
        - mountPath: /opt/seafile-data
          name: server-seafile-storage
        - mountPath: /opt/seafile-caddy/certs/seafile.homelab.cloud-tls.crt
          name: certificate
          subPath: seafile.homelab.cloud-tls.crt
        - mountPath: /opt/seafile-caddy/certs/seafile.homelab.cloud-tls.key
          name: certificate
          subPath: seafile.homelab.cloud-tls.key
      volumes:
      - name: server-seafile-storage
        persistentVolumeClaim:
          claimName: server-seafile
      - name: certificate
        secret:
          defaultMode: 292
          items:
          - key: tls.crt
            path: seafile.homelab.cloud-tls.crt
          - key: tls.key
            path: seafile.homelab.cloud-tls.key
          secretName: seafile.homelab.cloud-tls
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      labels:
        app: server-seafile
      name: seafile.homelab.cloud-tls
    spec:
      dnsNames:
      - seafile.homelab.cloud
      - sfl.homelab.cloud
      duration: 2190h
      ipAddresses:
      - 10.7.0.3
      isCA: false
      issuerRef:
        group: cert-manager.io
        kind: ClusterIssuer
        name: homelab.cloud-intm-ca01-issuer
      privateKey:
        algorithm: Ed25519
        encoding: PKCS8
        rotationPolicy: Always
      renewBefore: 168h
      secretName: seafile.homelab.cloud-tls
    ~~~

    There are a few details you must notice in this YAML:

    - As expected, the `ConfigMap` and `Secret` resources you've defined in this Kustomize project have their names appended with a hash suffix.

    - On the other hand, the names of the config map `db-mariadb` and the secrets `db-mariadb` and `cache-valkey` remain unchanged, because they have not been defined in this particular Kustomize subproject. They are external resources just being referenced here that will get together with this Seafile server in the next part of this Kustomize project.

    - Remember that Kustomize transforms the values you put at the `defaultMode` parameters set for the files you configure as `volumes`. [You already saw this happening while preparing the Valkey Kustomize subproject](G033%20-%20Deploying%20services%2002%20~%20Seafile%20-%20Part%202%20-%20Valkey%20cache%20server.md#validating-the-kustomize-yaml-output).

## Do not deploy this Seafile server project on its own

This Seafile server cannot be deployed on its own because is missing several things:

- The persistent volume it needs to store its data.

- It will not find the external resources it needs to run, like the `ConfigMaps` or `Secret` resources of the other components. Their names will not match with the ones this Kustomize subproject has.

So, again I must tell you to wait to the upcoming final part of this Seafile deployment procedure, where you'll add the missing parts, tie everything together and deploy the whole setup in one go.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/seafile/components/server-seafile`
- `$HOME/k8sprjs/seafile/components/server-seafile/configs`
- `$HOME/k8sprjs/seafile/components/server-seafile/resources`
- `$HOME/k8sprjs/seafile/components/server-seafile/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/seafile/components/server-seafile/kustomization.yaml`
- `$HOME/k8sprjs/seafile/components/server-seafile/configs/env.properties`
- `$HOME/k8sprjs/seafile/components/server-seafile/resources/seafile.homelab.cloud-tls.certificate.cert-manager.yaml`
- `$HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.service.yaml`
- `$HOME/k8sprjs/seafile/components/server-seafile/resources/server-seafile.statefulset.yaml`
- `$HOME/k8sprjs/seafile/components/server-seafile/secrets/seafile.pwd`

## References

### [Seafile](https://www.seafile.com/en/home/)

- [Seafile Admin Manual](https://manual.seafile.com/latest/)
  - [Setup. HTTPS and Caddy](https://manual.seafile.com/latest/setup/caddy/)
  - [Setup. Single node installation. Setup community edition. Installation of Seafile Server Community Edition with Docker](https://manual.seafile.com/latest/setup/setup_ce_by_docker/)
  - [Setup. Setup with Kubernetes (K8S). By K8S resource files. Single node. Setup Seafile with a single K8S pod with K8S resources files](https://manual.seafile.com/latest/setup/k8s_single_node/)
  - [Setup. Seafile K8S advanced management](https://manual.seafile.com/latest/setup/k8s_advanced_management/)

- [Hub. Docker. Seafile MC image](https://hub.docker.com/r/seafileltd/seafile-mc)

### [Kubernetes](https://kubernetes.io/docs/)

#### ConfigMaps

- [Kubernetes Documentation. Concepts. Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

#### Related contents about ConfigMaps and Secrets

- [OpenSource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### Storage

- [Kubernetes Blog. 2018. Local Persistent Volumes for Kubernetes Goes Beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)

- [Kubernetes Documentation. Concepts. Storage](https://kubernetes.io/docs/concepts/storage/)
  - [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
    - [local](https://kubernetes.io/docs/concepts/storage/volumes/#local)
  - [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
    - [Reserving a PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume)
    - [Reclaiming Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)
  - [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
    - [Local](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)

- [Kubernetes Documentation. Reference. Kubernetes API. Config and Storage Resources](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/)
  - [PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
  - [PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)

#### Related contents about Kubernetes storage

- [Rancher K3s. Add-Ons. Volumes and Storage](https://docs.k3s.io/add-ons/storage)
  - [Setting up the Local Storage Provider](https://docs.k3s.io/add-ons/storage#setting-up-the-local-storage-provider)

- [GitHub. Rancher. Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

- [GitHub. K3s. Issue. Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)

- [StackOverflow. Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)

- [GitHub. Helm. Issue. distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)

#### StatefulSets

- [Kubernetes Documentation. Concepts. Workloads. Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
  - [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### Environment variables

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

### [UTC offset](https://en.wikipedia.org/wiki/UTC_offset)

- [Wikipedia. List of UTC offsets](https://en.wikipedia.org/wiki/List_of_UTC_offsets)

## Navigation

[<< Previous (**G033. Deploying services 02. Nextcloud Part 3**)](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Nextcloud Part 5**) >>](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md)