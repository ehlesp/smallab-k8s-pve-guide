# G034 - Deploying services 03 ~ Gitea - Part 4 - Gitea server

- [The Gitea server is another component of this setup](#the-gitea-server-is-another-component-of-this-setup)
- [Considerations about the Gitea server](#considerations-about-the-gitea-server)
- [Gitea server Kustomize project's folders](#gitea-server-kustomize-projects-folders)
- [Gitea server configuration with environment variables](#gitea-server-configuration-with-environment-variables)
  - [Non-secret Gitea configuration parameters](#non-secret-gitea-configuration-parameters)
  - [Secret Gitea configuration parameters](#secret-gitea-configuration-parameters)
- [Gitea server persistent storage claims](#gitea-server-persistent-storage-claims)
  - [Persistent storage claim for Gitea server's data](#persistent-storage-claim-for-gitea-servers-data)
  - [Persistent storage claim for users' Git repositories](#persistent-storage-claim-for-users-git-repositories)
- [Gitea server StatefulSet](#gitea-server-statefulset)
- [Gitea server Service](#gitea-server-service)
- [Gitea Kustomize project](#gitea-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Gitea server project on its own](#do-not-deploy-this-gitea-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Gitea](#gitea)
  - [Other Gitea-related contents](#other-gitea-related-contents)
  - [Kubernetes](#kubernetes)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
- [Navigation](#navigation)

## The Gitea server is another component of this setup

The last component to setup in its own Kustomize subproject is the Gitea server itself.

## Considerations about the Gitea server

Gitea is a platform specialized in storing and handling Git repositories, which you can upload to Gitea through HTTP or SSH connections. Moreover, Gitea comes with a web console and embedded Prometheus-formatted metrics. All of this means that you will run one Gitea container with two open ports.

## Gitea server Kustomize project's folders

Prepare your Gitea's Kustomize project folder tree as follows.

~~~bash
$ mkdir -p $HOME/k8sprjs/gitea/components/server-gitea/{configs,resources,secrets}
~~~

## Gitea server configuration with environment variables

Gitea can be fully configured either with an `app.ini` file or with environment variables. Since certain values have to be injected as environment variables already, this section shows you how to declare certain Gitea parameters as environment variables.

### Non-secret Gitea configuration parameters

See here how to configure as environment variables in a separated properties file those Gitea parameters that are not secrets (meaning passwords or similar values) with values not injected from somewhere else:

1. Create an `env.properties` files under the `configs` path:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/configs/env.properties
    ~~~

2. Set the Gitea parameters as environment variables in the `configs/env.properties`:

    ~~~properties
    GITEA__server__DOMAIN=gitea.homelab.cloud
    GITEA__server__HTTP_ADDR=0.0.0.0
    GITEA__repository__ROOT=/data/gitea/repos
    GITEA__metrics__ENABLED=true
    GITEA__database__HOST=db-postgresql.gitea:5432
    GITEA__database__DB_TYPE=postgres
    GITEA__database__SSL_MODE=disable
    GITEA__cache__ENABLED=true
    GITEA__cache__ADAPTER=redis
    GITEA__queue__TYPE=redis
    GITEA__session__PROVIDER=redis
    GITEA__session__COOKIE_NAME=gitea_cookie
    ~~~

    The environment variables set above mean the following:

    - `GITEA__server__DOMAIN`\
      The domain name for the Gitea server. As in other cases, you will have to enable the domain in your network or directly in your client systems using the `hosts` file.

    - `GITEA__server__HTTP_ADDR`\
      On which IP address this server will listen on.

    - `GITEA__repository__ROOT`\
      Absolute path to the directory where the Git repositories of the users are kept.

    - `GITEA__metrics__ENABLED`\
      For enabling the Prometheus metrics feature included in the Gitea server.

    - `GITEA__database__HOST`\
      The host address and port of the database server this Gitea server has to connect to. The value in this case is the [corresponding hostname and `server` port of the PostgreSQL `Service` created in the previous part](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-service).

    - `GITEA__database__DB_TYPE`\
      Indicates the type of database Gitea must use.

    - `GITEA__database__SSL_MODE`\
      For enabling or disabling encryption in the communication with the database.

    - `GITEA__cache__ENABLED`\
      For enabling the cache on the Gitea instance.

    - `GITEA__cache__ADAPTER`\
      Depending on what caching engine you want to use, you will have to set the proper adapter here to connect to that engine. To use Valkey, you have to specify `redis` here.

    - `GITEA__queue__TYPE`\
      Type of queue to be used. In this case, since Valkey is also used for this feature, you must set this value to `redis`.

    - `GITEA__session__PROVIDER`\
      Indicates what session engine provider you want to use.

    - `GITEA__session__COOKIE_NAME`\
      Name of the cookie used for the session ID.

### Secret Gitea configuration parameters

The only secret values to configure are those corresponding to [the `giteacache` user prepared for Gitea in the ACL user list of the Valkey server setup](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-acl-user-list):

1. Create a `valkey_user_env.properties` files in the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/secrets/valkey_user_env.properties
    ~~~

2. Enter the values of Gitea's Valkey user as environment variables in the `secrets/valkey_user_env.properties`:

    ~~~properties
    GITEA_VALKEY_USERNAME=giteacache
    GITEA_VALKEY_PASSWORD="pAS2wOrD_f0r_T#e_G17e4_Us3R"
    ~~~

    These two environment variables are just custom non-Gitea parameters that will be used later in this part when declaring the URI for calling the Valkey server host. They are necessary because it is not possible to reuse the values from Valkey's ACL file for injecting them somewhere else.

## Gitea server persistent storage claims

The Gitea server requires two distinct `PersistentVolume` resources (to be declared in the final part of this Gitea deployment procedure), each for a specific purpose:

- One is dedicated to store Gitea server's own data files.
- The other one is meant for storing the users' Git repositories that Gitea will manage.

Hence you need two `PersistentVolumeClaim`s, one per persistent volume.

### Persistent storage claim for Gitea server's data

Declare the `PersistentVolumeClaim` to claim the storage where to put the Gitea server's data:

1. Create a `server-gitea-srv.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea-srv.persistentvolumeclaim.yaml
    ~~~

2. Declare the `server-gitea-srv` claim in `resources/server-gitea-srv.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Gitea server claim of persistent storage for server data
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-gitea-srv
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: gitea-ssd-srv
      resources:
        requests:
          storage: 1.9G
    ~~~

### Persistent storage claim for users' Git repositories

Declare the `PersistentVolumeClaim` to claim the storage for keeping the Git repositories of the Gitea server's users:

1. Create a `server-gitea-repos.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea-repos.persistentvolumeclaim.yaml
    ~~~

2. Declare the `server-gitea-srv` claim in `resources/server-gitea-repos.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Gitea server claim of persistent storage for Gitea users' Git repositories
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-gitea-repos
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: gitea-hdd-repos
      resources:
        requests:
          storage: 9.3G
    ~~~

## Gitea server StatefulSet

Since Gitea is a server that stores data, it is better to deploy it with a `StatefulSet` resource.

1. Create a `server-gitea.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for your Gitea server in `resources/server-gitea.statefulset.yaml`:

    ~~~yaml
    # Gitea StatefulSet for a server pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-gitea
    spec:
      replicas: 1
      serviceName: server-gitea
      template:
        spec:
          containers:
          - name: server
            image: gitea/gitea:1.25-rootless
            ports:
            - containerPort: 3000
              name: server
            - containerPort: 2222
              name: ssh
            readinessProbe:
              httpGet:
                path: /api/healthz
                port: server
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-gitea.gitea
              initialDelaySeconds: 100
              timeoutSeconds: 5
              periodSeconds: 10
              successThreshold: 1
              failureThreshold: 10
            livenessProbe:
              httpGet:
                path: /api/healthz
                port: server
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-gitea.gitea
              initialDelaySeconds: 120
              timeoutSeconds: 5
              periodSeconds: 10
              successThreshold: 1
              failureThreshold: 10
            envFrom:
            - configMapRef:
                name: server-gitea-env-vars
            - secretRef:
                name: server-gitea-valkey-user
            env:
            - name: GITEA__database__NAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: postgresql-db-name
            - name: GITEA__database__USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: gitea-username
            - name: GITEA__database__PASSWD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: gitea-user-password
            - name: GITEA__cache__HOST
              value: "redis://$(GITEA_VALKEY_USERNAME):$(GITEA_VALKEY_PASSWORD)@cache-valkey.gitea:6379/0?pool_size=100&idle_timeout=180s&prefix=gitea:"
            - name: GITEA__session__PROVIDER_CONFIG
              value: $(GITEA__cache__HOST)
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - name: gitea-data-storage
              mountPath: /data
            - name: gitea-repos-storage
              mountPath: /data/gitea/repos
            - name: tmp
              mountPath: /tmp/gitea
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              runAsNonRoot: true
              runAsUser: 1000
          automountServiceAccountToken: false
          hostAliases:
          - ip: "10.7.0.1"
            hostnames:
            - "gitea.homelab.cloud"
          volumes:
          - name: gitea-data-storage
            persistentVolumeClaim:
              claimName: server-gitea-srv
          - name: gitea-repos-storage
            persistentVolumeClaim:
              claimName: server-gitea-repos
          - name: tmp
            emptyDir:
              sizeLimit: 64Mi
    ~~~

    This `StatefulSet` for the Gitea server is similar to [the one declared for the Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-statefulset), with the following differences:

    - `spec.template.spec.container.server`\
      There is the only the `server` container in the pod. Since Gitea already provides Prometheus metrics, you do not need another sidecar container to run a service providing those metrics.

      - The `image` is for the version `1.25-rootless` of Gitea, built on an Alpine Linux system. Notice that it is the `rootless` version of Gitea's image, which is prepared to run the Gitea server with an unnamed non-root user identified by the UID `1000`.

      - In `ports` you have two ports declared, the `server` one to access Gitea (it listens on the port `3000` by default) and the `ssh` for connecting with this Gitea server through that protocol (the rootless image is configured to use the port `2222`).

      - The `readinessProbe` and `livenessProbe` probes call the `/api/healthz` endpoint `path` to check on the Gitea server status.

      - The `envFrom` block invokes the `ConfigMap` and `Secret` that will be declared later in the Kustomize manifest for this Gitea server subproject. The `server-gitea-env-vars` config map loads [the environment variables set previously in the `configs/env.properties` file](#non-secret-gitea-configuration-parameters), while the `server-gitea-valkey-user` secret loads [the variables set in the `secrets/valkey_user_env.properties` file](#secret-gitea-configuration-parameters).

      - The `env` section only declares the environment variables that have values injected from parameters set somewhere else:

        - `GITEA__database__NAME`\
          The name of the database reserved for Gitea. [This value was set in the configuration of the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#properties-file-dbnamesproperties).

        - `GITEA__database__USER`\
          The name of the user assigned to Gitea in the database server. [This value was also set in the configuration of the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#properties-file-dbnamesproperties)

        - `GITEA__database__PASSWD`\
          This is the password of the Gitea user in the database server. This value is [one of the passwords declared in the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-passwords).

        - `GITEA__cache__HOST`\
          This is the URL to connect to the cache server host:

          - Notice that the application layer protocol specified is `redis`, not `http`.

          - The values for the user credentials are injected in the URL with the environment variables `GITEA_VALKEY_USERNAME` and `GITEA_VALKEY_PASSWORD`.

          - `cache-valkey.gitea:6379` indicates the hostname and port of the Valkey `Service` to connect to.

          - The `/0` specifies which Valkey instance to use. This value is always `0` when only using a single Valkey server instance. When working in a High Availability (HA) environment (where there is a cluster of Valkey instances), this value could point to any Valkey instance available in the environment.

          - The query parameters are options that affect how the client side (Gitea in this case) connects with Valkey. In particular, notice how the `prefix` parameter specifies the same `gitea:` prefix configured for the Gitea user [in the Valkey ACL user list](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-acl-user-list).

        - `GITEA__session__PROVIDER_CONFIG`\
          Connection string pointing to the system providing sessions support. Since the session provider is also Valkey in this case, the connection string is the same one specified in the `GITEA__cache__HOST` variable.

      - The `volumeMounts` block links the Gitea server with three storage resources:

        - The storage for the Gitea server data, which is mounted under the `/data` path.

        - The storage for the users Git repositories, that is mounted in the `/data/gitea/repos` directory.

        - An ephemeral in-memory storage for Gitea mounted in `/tmp/gitea`, which is the path set as the temporary directory in the rootless Gitea image.

      - The `securityContext` hardens the container by making the filesystem read-only, and avoiding using the root user to run the container. Instead, the `runAsUser` specifies the user `1000` which is the one prepared in the rootless Gitea image.

    - The `automountServiceAccountToken` parameter set to `false` blocks the access to the Kubernetes cluster's control plane from the pod generated by this `StatefulSet`.

    - In the `hostAliases`, the hostname for the Gitea server (`gitea.homelab.cloud`) is associated with the IP address of Traefik (`10.7.0.1`). This allows Gitea to reach itself through the proper IP when necessary.

    - The `volumes` block declares the three storages used in the Gitea `server` container:

      - The `gitea-data-storage` item uses the `server-gitea-srv` persistent volume claim to connect with the LVM meant to store the Gitea server data.

      - The `gitea-repos-storage` item uses the `server-gitea-repos` persistent volume claim to connect with the LVM created for storing Gitea users' repositories.

      - The `tmp` entry is an emptyDir that enables the ephemeral in-memory storage for temporary operations happening in the Ghost server.

## Gitea server Service

Your Gitea server's `StatefulSet` needs a `Service` called `server-ghost` to work:

1. Create a file called `server-gitea.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.service.yaml
    ~~~

2. Declare the `Service` for the Ghost server in `resources/server-ghost.service.yaml`:

    ~~~yaml
    # Gitea server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-gitea
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: /metrics
        prometheus.io/port: "3000"
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - port: 3000
        targetPort: server
        protocol: TCP
        name: server
      - port: 22
        targetPort: ssh
        protocol: TCP
        name: ssh
    ~~~

    Like the services for the other components, this `Service` for the Gitea server does not have an specific IP permanently assigned in the Kubernetes cluster. Since the namespace for the complete Gitea deployment is going to be `gitea`, the hostname to reach this service will be `server-gitea.gitea`. Also notice that:

    - In the `metadata.annotations` section, there is a new `prometheus.io/path` entry you have not seen in the other Services you have declared up till now. This parameter is the relative URL to the Prometheus metrics endpoint. By default this path is expected to be located at `/metrics`, as it is in this case. If the Prometheus metrics had been served by another endpoint, you would have been forced to specify its relative path in this annotation entry.

    - The port `3000` is used both for regular access into the Gitea server and for scraping the server's Prometheus metrics endpoint.

    - The `ssh` port declared in this `Service` is the standard SSH one, but it connects with the `ssh` `2222` port previously [declared in the Gitea server `StatefulSet`](#gitea-server-statefulset).

## Gitea Kustomize project

Declare the main `kustomization.yaml` manifest describing the Gitea server's Kustomize subproject:

1. In the main `server-gitea` folder, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml
    ~~~

2. Enter in the `kustomization.yaml` file the `Kustomization` declaration for deploying the Gitea server:

    ~~~yaml
    # Gitea server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app: server-gitea
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/server-gitea-srv.persistentvolumeclaim.yaml
    - resources/server-gitea-repos.persistentvolumeclaim.yaml
    - resources/server-gitea.service.yaml
    - resources/server-gitea.statefulset.yaml

    replicas:
    - name: server-gitea
      count: 1

    images:
    - name: gitea/gitea
      newTag: 1.25-rootless

    configMapGenerator:
    - name: server-gitea-env-vars
      envs:
      - configs/env.properties

    secretGenerator:
    - name: server-gitea-valkey-user
      envs:
      - secrets/valkey_user_env.properties
    ~~~

    This `Kustomization` manifest is like the others you have created for other components, with just a few particularities to highlight:

    - There is only one image to manage in the `images` list because Gitea already provides Prometheus metrics without requiring some extra container to enable them.

    - In the `resources` block are listed the two files declaring `PersistentVolumeClaim` resources used to enable persistent storage in the Gitea server, together with the other usual declarations for the corresponding `StatefulSet` and `Service`.

    - The `configMapGenerator` block declares the `server-gitea-env-vars`  `ConfigMap` object containing only [the `configs/env.properties` file with the specific environment variables that adjust the configuration of the Gitea server](#non-secret-gitea-configuration-parameters).

    - The `secretGenerator` block is configured to produce a `Secret` object only containing the environment variables with the credentials of the Gitea server's Valkey user.

### Validating the Kustomize YAML output

At this point, you have completed the Gitea server Kustomize subproject. It is time to test it out with `kubectl`:

1. Execute the `kubectl kustomize` command on the Gitea server Kustomize subproject's root folder, piped to `less` to get the output paginated:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/gitea/components/server-gitea | less
    ~~~

2. The resulting YAML should look like this:

    ~~~yaml
    apiVersion: v1
    data:
      GITEA__cache__ADAPTER: redis
      GITEA__cache__ENABLED: "true"
      GITEA__database__DB_TYPE: postgres
      GITEA__database__HOST: db-postgresql.gitea:5432
      GITEA__database__SSL_MODE: disable
      GITEA__metrics__ENABLED: "true"
      GITEA__queue__TYPE: redis
      GITEA__repository__ROOT: /data/gitea/repos
      GITEA__server__DOMAIN: gitea.homelab.cloud
      GITEA__server__HTTP_ADDR: 0.0.0.0
      GITEA__session__COOKIE_NAME: gitea_cookie
      GITEA__session__PROVIDER: redis
    kind: ConfigMap
    metadata:
      labels:
        app: server-gitea
      name: server-gitea-env-vars-dmth7bdc25
    ---
    apiVersion: v1
    data:
      GITEA_VALKEY_PASSWORD: InBBUzJ3T3JEX2Ywcl9UI2VfRzE3ZTRfVXMzUiI=
      GITEA_VALKEY_USERNAME: Z2l0ZWFjYWNoZQ==
    kind: Secret
    metadata:
      labels:
        app: server-gitea
      name: server-gitea-valkey-user-hbk4b87t87
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/path: /metrics
        prometheus.io/port: "3000"
        prometheus.io/scrape: "true"
      labels:
        app: server-gitea
      name: server-gitea
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 3000
        protocol: TCP
        targetPort: server
      - name: ssh
        port: 22
        protocol: TCP
        targetPort: ssh
      selector:
        app: server-gitea
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-gitea
      name: server-gitea-repos
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.3G
      storageClassName: local-path
      volumeName: gitea-hdd-repos
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-gitea
      name: server-gitea-srv
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.9G
      storageClassName: local-path
      volumeName: gitea-ssd-srv
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-gitea
      name: server-gitea
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-gitea
      serviceName: server-gitea
      template:
        metadata:
          labels:
            app: server-gitea
        spec:
          automountServiceAccountToken: false
          containers:
          - env:
            - name: GITEA__database__NAME
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql-config
            - name: GITEA__database__USER
              valueFrom:
                configMapKeyRef:
                  key: gitea-username
                  name: db-postgresql-config
            - name: GITEA__database__PASSWD
              valueFrom:
                secretKeyRef:
                  key: gitea-user-password
                  name: db-postgresql-secrets
            - name: GITEA__cache__HOST
              value: 'redis://$(GITEA_VALKEY_USERNAME):$(GITEA_VALKEY_PASSWORD)@cache-valkey.gitea:6379/0?pool_size=100&idle_timeout=180s&prefix=gitea:'
            - name: GITEA__session__PROVIDER_CONFIG
              value: $(GITEA__cache__HOST)
            envFrom:
            - configMapRef:
                name: server-gitea-env-vars-dmth7bdc25
            - secretRef:
                name: server-gitea-valkey-user-hbk4b87t87
            image: gitea/gitea:1.25-rootless
            livenessProbe:
              failureThreshold: 10
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-gitea.gitea
                path: /api/healthz
                port: server
              initialDelaySeconds: 120
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 5
            name: server
            ports:
            - containerPort: 3000
              name: server
            - containerPort: 2222
              name: ssh
            readinessProbe:
              failureThreshold: 10
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-gitea.gitea
                path: /api/healthz
                port: server
              initialDelaySeconds: 100
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 5
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 1000
            volumeMounts:
            - mountPath: /data
              name: gitea-data-storage
            - mountPath: /data/gitea/repos
              name: gitea-repos-storage
            - mountPath: /tmp/gitea
              name: tmp
          hostAliases:
          - hostnames:
            - gitea.homelab.cloud
            ip: 10.7.0.1
          volumes:
          - name: gitea-data-storage
            persistentVolumeClaim:
              claimName: server-gitea-srv
          - name: gitea-repos-storage
            persistentVolumeClaim:
              claimName: server-gitea-repos
          - emptyDir:
              sizeLimit: 64Mi
            name: tmp
    ~~~

## Do not deploy this Gitea server project on its own

This Gitea server setup is missing two critical element, the persistent volumes it needs to store its working directory data and users Git repositories. Do not confuse them with the claims you have configured for your Gitea server. Those persistent volumes and other elements will be declared in the main Kustomize project you will declare in the final part of this Gitea deployment procedure. Until then, do not deploy this Gitea server subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/gitea`
- `$HOME/k8sprjs/gitea/components`
- `$HOME/k8sprjs/gitea/components/server-gitea`
- `$HOME/k8sprjs/gitea/components/server-gitea/configs`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources`
- `$HOME/k8sprjs/gitea/components/server-gitea/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/gitea/components/server-gitea/kustomization.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/configs/env.properties`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea-repos.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea-srv.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.service.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/resources/server-gitea.statefulset.yaml`
- `$HOME/k8sprjs/gitea/components/server-gitea/secrets/valkey_user_env.properties`

## References

### [Gitea](https://about.gitea.com/)

- [Docs. What is Gitea?](https://docs.gitea.com/)
  - [Installation](https://docs.gitea.com/installation/install-on-kubernetes)
    - [Install on Kubernetes](https://docs.gitea.com/installation/install-on-kubernetes)
    - [Installation with Docker (rootless)](https://docs.gitea.com/installation/install-with-docker-rootless/)
    - [Installation with Docker. Managing Deployments With Environment Variables](https://docs.gitea.com/next/installation/install-with-docker#managing-deployments-with-environment-variables)

  - [Administration](https://docs.gitea.com/administration/)
    - [Gitea Command Line. Global options](https://docs.gitea.com/next/administration/command-line#global-options)
    - [Configuration Cheat Sheet](https://docs.gitea.com/administration/config-cheat-sheet)

  - [FAQ](https://docs.gitea.com/next/help/faq)
    - [Where does Gitea store what file](https://docs.gitea.com/next/help/faq#where-does-gitea-store-what-file)

- [GitHub. Gitea](https://github.com/go-gitea/gitea)
  - [app.example.ini](https://github.com/go-gitea/gitea/blob/main/custom/conf/app.example.ini)
  - [Dockerfile.rootles](https://github.com/go-gitea/gitea/blob/release/v1.25/Dockerfile.rootless)

- [Docker Hub. Gitea](https://hub.docker.com/r/gitea/gitea)

### Other Gitea-related contents

- [ServerFault. Monitor Gitea with Prometheus](https://serverfault.com/questions/999413/monitor-gitea-with-prometheus)
- [Computing for Geeks. Install and Configure Gitea Git Service on Kubernetes / OpenShift](https://computingforgeeks.com/install-gitea-git-service-on-kubernetes-openshift/)
- [DEV. Setup a Self-Hosted Git Service with Gitea](https://dev.to/ruanbekker/setup-a-self-hosted-git-service-with-gitea-11ce)

- [Ralph's Open Source Blog](https://ralph.blog.imixs.com/)
  - [Running Gitea on Kubernetes](https://ralph.blog.imixs.com/2021/02/25/running-gitea-on-kubernetes/)
  - [Running Gitea on a Virtual Cloud Server](https://ralph.blog.imixs.com/2021/02/26/running-gitea-on-a-virtual-cloud-server/)

### [Kubernetes](https://kubernetes.io/docs/)

- [Reference. Kubernetes API. Workload Resources. Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
  - [Ports](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports)

### Other Kubernetes-related contents

- [StackOverflow. Why do we need a port/containerPort in a Kubernetes deployment/container definition?](https://stackoverflow.com/questions/57197095/why-do-we-need-a-port-containerport-in-a-kuberntes-deployment-container-definiti)
- [DevOpsCube. How to Setup Prometheus Monitoring On Kubernetes Cluster](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
- [ACA Group. Blog. How to set up auto-discovery of Kubernetes endpoint services in Prometheus](https://www.acagroup.be/en/blog/auto-discovery-of-kubernetes-endpoint-services-prometheus/)

## Navigation

[<< Previous (**G034. Deploying services 03. Gitea Part 3**)](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%203%20-%20PostgreSQL%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Gitea Part 5**) >>](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%205%20-%20Complete%20Gitea%20platform.md)
