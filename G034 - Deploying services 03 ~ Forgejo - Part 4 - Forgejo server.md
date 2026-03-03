# G034 - Deploying services 03 ~ Forgejo - Part 4 - Forgejo server

- [Considerations about the Forgejo server](#considerations-about-the-forgejo-server)
- [Forgejo server Kustomize project's folders](#forgejo-server-kustomize-projects-folders)
- [Forgejo server configuration with environment variables](#forgejo-server-configuration-with-environment-variables)
  - [Non-secret Forgejo configuration parameters](#non-secret-forgejo-configuration-parameters)
  - [Secret Forgejo configuration parameters](#secret-forgejo-configuration-parameters)
- [Forgejo server persistent storage claims](#forgejo-server-persistent-storage-claims)
  - [Persistent storage claim for Forgejo server's data](#persistent-storage-claim-for-forgejo-servers-data)
  - [Persistent storage claim for users' Git repositories and LFS contents](#persistent-storage-claim-for-users-git-repositories-and-lfs-contents)
- [Forgejo server StatefulSet](#forgejo-server-statefulset)
- [Forgejo server Service](#forgejo-server-service)
  - [Forgejo Service's FQDN](#forgejo-services-fqdn)
- [Forgejo Kustomize project](#forgejo-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Forgejo server project on its own](#do-not-deploy-this-forgejo-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Forgejo](#forgejo)
  - [Gitea](#gitea)
  - [Other Gitea-related contents](#other-gitea-related-contents)
  - [Kubernetes](#kubernetes)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
- [Navigation](#navigation)

## Considerations about the Forgejo server

The last component to setup in its own Kustomize subproject is the Forgejo server itself. [Forgejo](https://forgejo.org/) is a platform specialized in storing and managing Git repositories, which you can upload to Forgejo through HTTP or SSH connections. In fact, Forgejo is a hard fork of an equivalent platform called [Gitea](https://about.gitea.com/). Internally, some configuration parameters still use Gitea-related values. In particular, this happens with some paths which will be indicated later in this chapter.

Like Gitea, Forgejo comes with a web console and embedded Prometheus-formatted metrics. All of this means that you are going to run in your K3s cluster one Forgejo container with two open ports.

## Forgejo server Kustomize project's folders

Prepare your Forgejo's Kustomize project folder tree with this `mkdir` command:

~~~sh
$ mkdir -p $HOME/k8sprjs/forgejo/components/server-forgejo/{configs,resources,secrets}
~~~

## Forgejo server configuration with environment variables

Forgejo can be fully configured either with an `app.ini` file or with environment variables. This section shows you how to declare the necessary Forgejo parameters as environment variables.

### Non-secret Forgejo configuration parameters

See here how to configure as environment variables, and in a separated properties file, the necessary Forgejo parameters that are not secrets (meaning passwords, paths or similar values) with values not injected from somewhere else:

1. Create an `env.properties` files under the `configs` path:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/configs/env.properties
    ~~~

2. Set the Forgejo parameters as environment variables in the `configs/env.properties`:

    ~~~properties
    FORGEJO__server__DOMAIN=forgejo.homelab.cloud
    FORGEJO__server__HTTP_ADDR=0.0.0.0
    FORGEJO__server__LFS_START_SERVER=true
    FORGEJO__metrics__ENABLED=true
    FORGEJO__database__HOST=db-postgresql.forgejo.svc.homelab.cluster.:5432
    FORGEJO__database__DB_TYPE=postgres
    FORGEJO__database__SSL_MODE=disable
    FORGEJO__cache__ENABLED=true
    FORGEJO__cache__ADAPTER=redis
    FORGEJO__session__PROVIDER=redis
    FORGEJO__session__COOKIE_NAME=forgejo_cookie
    FORGEJO__queue__TYPE=redis
    FORGEJO__queue__QUEUE_NAME=_queue_forgejo
    FORGEJO__queue__SET_NAME=_uniqueue_forgejo
    ~~~

    The environment variables set above mean the following:

    - `FORGEJO__server__DOMAIN`\
      The domain name for the Forgejo server. As in other cases, you have to enable the domain in your network or directly in your client systems using the `hosts` file.

    - `FORGEJO__server__HTTP_ADDR`\
      On which IP address this server will listen on.

    - `FORGEJO__server_LFS_START_SERVER`\
      Enables Forgejo's support of the Git Large File Storage extension.

    - `FORGEJO__metrics__ENABLED`\
      For enabling the Prometheus metrics feature included in the Forgejo server.

    - `FORGEJO__database__HOST`\
      The host address and port of the database server this Forgejo server has to connect to. Its value here [is the combination of the absolute FQDN with the `server` port number of the PostgreSQL `Service` created in the previous part](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-service).

    - `FORGEJO__database__DB_TYPE`\
      Indicates the type of database Forgejo must use.

    - `FORGEJO__database__SSL_MODE`\
      For enabling or disabling encryption in the communication with the database.

    - `FORGEJO__cache__ENABLED`\
      For enabling the cache on the Forgejo instance.

    - `FORGEJO__cache__ADAPTER`\
      Depending on what caching engine you want to use, you have to set the proper adapter here to connect to that engine. To use Valkey, you have to specify `redis` here.

    - `FORGEJO__session__PROVIDER`\
      Indicates what session engine provider you want to use.

    - `FORGEJO__session__COOKIE_NAME`\
      Name of the cookie used for the session ID.

    - `FORGEJO__queue__TYPE`\
      Type of queue server to be used. In this case, since Valkey is also used for this feature, you must set this value to `redis`.

    - `FORGEJO__queue__QUEUE_NAME`\
      Suffix added to the name of default and regular non-unique queues.

    - `FORGEJO__queue__SET_NAME`\
      Suffix added specifically to the name of unique queues.

    > [!WARNING]
    > **Careful with the underscore characters**\
    > When typing these environment variables, be very careful of not missing or misplacing their underscore characters or the Forgejo server will not be able to read them.
    >
    > The double underscore separates categories. `FORGEJO` is the root category, while those like `server`, `lfs` or `database` are subcategories (notice these are in lowercase). The third part (always in UPPERCASE) on each environment variable represents the Forgejo configuration parameter itself.

### Secret Forgejo configuration parameters

The only secret values to configure are those corresponding to [the `forgejocache` user prepared for Forgejo in the ACL user list of the Valkey server setup](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-acl-user-list):

1. Create a `valkey_user_env.properties` files in the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/secrets/valkey_user_env.properties
    ~~~

2. Enter the values of Forgejo's Valkey user as environment variables in the `secrets/valkey_user_env.properties`:

    ~~~properties
    FORGEJO_VALKEY_USERNAME=forgejocache
    FORGEJO_VALKEY_PASSWORD=pAS2wOrD_f0r_The_F0rgEJ0_Us3R
    ~~~

    These two environment variables are just custom non-Forgejo parameters used later in this part when declaring the URI for calling the Valkey server host. They are necessary because it is not possible to reuse the values from Valkey's ACL file for injecting them somewhere else.

    > [!WARNING]
    > **URL encode any special character found in these values**\
    > You will see later how these environment variables are inserted in the connection string for connecting with the Valkey cache server. This forces you to URL-encode any special character you might have either in the username or the password. Otherwise, the connection attempt may fail. You could also consider just using alphanumeric values to avoid such issues.

## Forgejo server persistent storage claims

The Forgejo server requires two distinct `PersistentVolume` resources (to be declared in the final part of this Forgejo deployment procedure), each for a specific purpose:

- One stores Forgejo server's own data files.
- Other for storing the users' Git repositories and LFS contents that Forgejo will manage.

Hence you need two `PersistentVolumeClaim`s, one per persistent volume.

### Persistent storage claim for Forgejo server's data

Declare the `PersistentVolumeClaim` to claim the storage where to put the Forgejo server's data:

1. Create a `server-forgejo-data.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo-data.persistentvolumeclaim.yaml
    ~~~

2. Declare the `server-forgejo-data` claim in `resources/server-forgejo-data.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Forgejo server claim of persistent storage for server data
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-forgejo-data
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: forgejo-ssd-data
      resources:
        requests:
          storage: 1.9G
    ~~~

### Persistent storage claim for users' Git repositories and LFS contents

Declare the `PersistentVolumeClaim` to claim the storage for keeping the Git repositories and LFS contents of the Forgejo server's users:

1. Create a `server-forgejo-git.persistentvolumeclaim.yaml` file under the `resources` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo-git.persistentvolumeclaim.yaml
    ~~~

2. Declare the `server-forgejo-git` claim in `resources/server-forgejo-git.persistentvolumeclaim.yaml`:

    ~~~yaml
    # Forgejo server claim of persistent storage for Forgejo users' Git repositories and LFS contents
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-forgejo-git
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: forgejo-hdd-git
      resources:
        requests:
          storage: 19G
    ~~~

## Forgejo server StatefulSet

Since Forgejo is a server that stores data, it is better to deploy it with a `StatefulSet` resource:

1. Create a `server-forgejo.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for your Forgejo server in `resources/server-forgejo.statefulset.yaml`:

    ~~~yaml
    # Forgejo StatefulSet for a server pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-forgejo
    spec:
      replicas: 1
      serviceName: server-forgejo
      template:
        spec:
          securityContext:
            fsGroup: 1000
            fsGroupChangePolicy: OnRootMismatch
          initContainers:
          - name: permissions-fix
            image: docker.io/busybox:stable-musl
            env:
            - name: FORGEJO_APP_DATA_PATH
              value: /var/lib/gitea
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
            command:
              - /bin/sh
              - '-c'
              - |
                set -e

                chown -Rfv 1000:1000 $FORGEJO_APP_DATA_PATH && echo "chown ok on $FORGEJO_APP_DATA_PATH" || echo "Error changing ownership of $FORGEJO_APP_DATA_PATH directory"
                chown -Rfv 1000:1000 /tmp/forgejo && echo "chown ok on /tmp/forgejo" || echo "Error changing ownership of /tmp/forgejo directory"

                export DIRS='git git/custom git/repositories git/lfs'
                echo 'Check if base dirs exists, if not, create them'
                echo "Directories to check: $DIRS"
                for dir in $DIRS; do
                  if [ ! -d $FORGEJO_APP_DATA_PATH/$dir ]; then
                    echo "Creating $FORGEJO_APP_DATA_PATH/$dir directory"
                    mkdir -pv $FORGEJO_APP_DATA_PATH/$dir || echo "Error creating $FORGEJO_APP_DATA_PATH/$dir directory"
                  fi
                  chown -Rfv 1000:1000 $FORGEJO_APP_DATA_PATH/$dir && echo "chown ok on $dir" || echo "Error changing ownership of $FORGEJO_APP_DATA_PATH/$dir directory"
                done

                exit 0
            volumeMounts:
            - name: forgejo-data-storage
              mountPath: /var/lib/gitea
              readOnly: false
            - name: forgejo-git-storage
              mountPath: /var/lib/gitea/git
              readOnly: false
            - name: tmp
              mountPath: /tmp/gitea
              readOnly: false
          containers:
          - name: server
            image: codeberg.org/forgejo/forgejo:14.0-rootless
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
                  value: forgejo.homelab.cloud
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
                  value: forgejo.homelab.cloud
              initialDelaySeconds: 120
              timeoutSeconds: 5
              periodSeconds: 10
              successThreshold: 1
              failureThreshold: 10
            envFrom:
            - configMapRef:
                name: server-forgejo-env-vars
            - secretRef:
                name: server-forgejo-valkey-user
            env:
            - name: FORGEJO__database__NAME
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: postgresql-db-name
            - name: FORGEJO__database__USER
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: forgejo-username
            - name: FORGEJO__database__PASSWD
              valueFrom:
                secretKeyRef:
                  name: db-postgresql-secrets
                  key: forgejo-user-password
            - name: FORGEJO__database__SCHEMA
              valueFrom:
                configMapKeyRef:
                  name: db-postgresql-config
                  key: forgejo-username
            - name: FORGEJO__cache__HOST
              value: 'redis://$(FORGEJO_VALKEY_USERNAME):$(FORGEJO_VALKEY_PASSWORD)@cache-valkey.forgejo.svc.homelab.cluster.:6379/0?pool_size=100&idle_timeout=180s&prefix=forgejo%3A'
            - name: FORGEJO__session__PROVIDER_CONFIG
              value: $(FORGEJO__cache__HOST)
            - name: FORGEJO__queue__CONN_STR
              value: $(FORGEJO__cache__HOST)
            resources:
              requests:
                cpu: 250m
                memory: 128Mi
            volumeMounts:
            - name: forgejo-data-storage
              mountPath: /var/lib/gitea
              readOnly: false
            - name: forgejo-git-storage
              mountPath: /var/lib/gitea/git
              readOnly: false
            - name: tmp
              mountPath: /tmp/gitea
              readOnly: false
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              runAsNonRoot: true
              runAsUser: 1000
              runAsGroup: 1000
          automountServiceAccountToken: false
          hostAliases:
          - ip: "10.7.0.1"
            hostnames:
            - "forgejo.homelab.cloud"
          volumes:
          - name: forgejo-data-storage
            persistentVolumeClaim:
              claimName: server-forgejo-data
          - name: forgejo-git-storage
            persistentVolumeClaim:
              claimName: server-forgejo-git
          - name: tmp
            emptyDir:
              sizeLimit: 64Mi
    ~~~

    This `StatefulSet` for the Forgejo server is similar to [the one declared for the Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-statefulset), with the following differences:

    - `spec.template.spec.securityContext`\
      This section applies security hardening features on all the containers running in the pod produced by this `StatefulSet`:

      - The `fsGroup` ensures that the filesystem of the containers is owned by the group identified by its GID here. The GID `1000` set in this parameter corresponds to the `git` group that already exists in the Forgejo rootless container image.

        The rootless image of Forgejo used in this `StatefulSet` is prepared to run under the `git` user and group, making necessary to ensure that the filesystem can be managed by that user.

      - The `fsGroupChangePolicy` is a feature that can be used to avoid costly changes of ownership on files or folders already existing in the mounted storage volumes. With the `OnRootMismatch` value, this feature ensures that ownership is adjusted only when there is a mismatch between the current filesystem owner and the one set in a file.

    - `spec.template.spec.initContainers.permissions-fix`\
      This block enables one `permissions-fix` init container that runs a script to change the ownership of certain key Forgejo folders to be owned by the `git` user and group. This init container also has a security context applied to harden it.

    - `spec.template.spec.container.server`\
      There is the only the `server` container in the pod. Since Forgejo already provides Prometheus metrics, you do not need another sidecar container to run a service providing those metrics.

      - The `image` is for the version `14.0-rootless` of Forgejo, built on an Alpine Linux system. Notice that it is the `rootless` version of Forgejo's image, which is prepared to run the Forgejo server with an unnamed non-root user identified by the UID `1000`.

      - In `ports` you have two ports declared, the `server` one to access Forgejo (it listens on the port `3000` by default) and the `ssh` for connecting with this Forgejo server through that protocol (the rootless image is configured to use the port `2222`).

      - The `readinessProbe` and `livenessProbe` probes call the `/api/healthz` endpoint `path` to check on the Forgejo server status.

      - The `envFrom` block invokes the `ConfigMap` and `Secret` that will be declared later in the Kustomize manifest for this Forgejo server subproject. The `server-forgejo-env-vars` config map loads [the environment variables set previously in the `configs/env.properties` file](#non-secret-forgejo-configuration-parameters), while the `server-forgejo-valkey-user` secret loads [the variables set in the `secrets/valkey_user_env.properties` file](#secret-forgejo-configuration-parameters).

      - The `env` section only declares the environment variables that have values injected from parameters set somewhere else:

        - `FORGEJO__database__NAME`\
          The name of the database reserved for Forgejo. [This value was set in the configuration of the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#properties-file-dbnamesproperties).

        - `FORGEJO__database__USER`\
          The name of the user assigned to Forgejo in the database server. [This value was also set in the configuration of the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#properties-file-dbnamesproperties)

        - `FORGEJO__database__PASSWD`\
          This is the password of the Forgejo user in the database server. This value is [one of the passwords declared in the PostgreSQL deployment subproject](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#postgresql-passwords).

        - `FORGEJO__database__SCHEMA`\
          This is a PostgreSQL-specific option that indicates the schema to use with the user specified by the `FORGEJO__database__USER` environment parameter. In this case, the schema has the same name as the Forgejo user (which is the default approach in PostgreSQL).

          Remember that this schema is created, together with the Forgejo database user itself, by [the `initdb.sh` initializer shell script declared for the PostgreSQL server configuration](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md#initializer-shell-script-initdbsh).

        - `FORGEJO__cache__HOST`\
          This is the URL to connect to the cache server host:

          - Notice that the application layer protocol specified is `redis`, not `http`. Here you could also specify `valkey` instead of `redis`.

          - The values for the user credentials are injected in the URL with the environment variables `FORGEJO_VALKEY_USERNAME` and `FORGEJO_VALKEY_PASSWORD`.

            > [!IMPORTANT]
            > **Remember to URL encode any special character you may have in these variables**\
            > Otherwise, you may end up being unable to connect your Forgejo server with your Valkey instance.

          - `cache-valkey.forgejo.svc.homelab.cluster.:6379` specifies the absolute FQDN and the `server` port number of [the Valkey `Service`](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-service).

          - The `/0` specifies which logic database to use in the Valkey instance.

          - The query parameters are options that affect how the client side (Forgejo in this case) connections perform.

            > [!IMPORTANT]
            > **Do not forget to URL encode any special character you may enter in the query parameters**\
            > For instance, see how the `:` character included in the `forgejo:` value of the `prefix` query parameter has been encoded as `%3A`.

        - `FORGEJO__session__PROVIDER_CONFIG`\
          Connection string pointing to the server providing sessions support. Since the session provider is also Valkey in this case, the connection string is the same one specified in the `FORGEJO__cache__HOST` variable.

        - `FORGEJO__queue__CONN_STR`\
          Connection string to connect with the server providing queuing support, which is Valkey again.

      - The `volumeMounts` block links the Forgejo server with three storage resources:

        - The storage for the Forgejo server data, mounted under the `/var/lib/gitea` path. Notice here the use of a Gitea-related path, as set [in the Forgejo rootless container image's Dockerfile](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/Dockerfile.rootless).

        - The storage for the users' Git repositories and LFS contents, mounted in the `/var/lib/gitea/git` directory. This path is also a remnant from Gitea yet to be changed in Forgejo (at the time of writing this).

        - An ephemeral in-memory storage for Forgejo mounted in `/tmp/gitea`, which is the path set as the temporary directory in the rootless Forgejo image.

      - The `securityContext` hardens the container by running it with the non-root user identified by the UID `1000`, which corresponds to the `git` user already existing in the container image. Also protects the root filesystem by making it read-only and disables (up to a point) the possibility of privilege escalation.

    - The `automountServiceAccountToken` parameter set to `false` blocks the access to the Kubernetes cluster's control plane from the pod generated by this `StatefulSet`.

    - In the `hostAliases`, the hostname for the Forgejo server (`forgejo.homelab.cloud`) is associated with the IP address of Traefik (`10.7.0.1`). This allows Forgejo to reach itself through the proper IP when necessary.

    - The `volumes` block declares the three storages used in the Forgejo `server` container:

      - The `forgejo-data-storage` item uses the `server-forgejo-data` persistent volume claim to connect with the LVM meant to store the Forgejo server data.

      - The `forgejo-git-storage` item uses the `server-forgejo-git` persistent volume claim to connect with the LVM created for storing Forgejo users' Git repositories and LFS contents.

      - The `tmp` entry is an emptyDir that enables the ephemeral in-memory storage for temporary operations happening in the Ghost server.

## Forgejo server Service

Your Forgejo server's `StatefulSet` needs a `Service` called `server-ghost` to work:

1. Create a file called `server-forgejo.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo.service.yaml
    ~~~

2. Declare the `Service` for the Ghost server in `resources/server-ghost.service.yaml`:

    ~~~yaml
    # Forgejo server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-forgejo
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

    Like the services for the other components, this `Service` for the Forgejo server does not have an specific IP permanently assigned in the Kubernetes cluster:

    - In the `metadata.annotations` section, there is a new `prometheus.io/path` entry you have not seen in the other Kubernetes services you have declared up till now. This parameter is the relative URL to the Prometheus metrics endpoint. By default this path is expected to be located at `/metrics`, as it is in this case. If the Prometheus metrics had been served by another endpoint, you would have been forced to specify its relative path in this annotation entry.

    - The port `3000` is used both for regular access into the Forgejo server and for scraping the server's Prometheus metrics endpoint.

    - The `ssh` port declared in this `Service` is the standard SSH `22` one, but it connects with the `ssh` `2222` port previously [declared in the Forgejo server `StatefulSet`](#forgejo-server-statefulset).

### Forgejo Service's FQDN

The absolute FQDN for the Forgejo headless service deployed in the `forgejo` namespace will be:

~~~txt
server-forgejo.forgejo.svc.homelab.cluster.
~~~

## Forgejo Kustomize project

Declare the main `kustomization.yaml` manifest describing the Forgejo server's Kustomize subproject:

1. In the main `server-forgejo` folder, create a `kustomization.yaml` file:

    ~~~sh
    $ touch $HOME/k8sprjs/forgejo/components/server-forgejo/kustomization.yaml
    ~~~

2. Enter in the `kustomization.yaml` file the `Kustomization` declaration for deploying the Forgejo server:

    ~~~yaml
    # Forgejo server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
    - pairs:
        app: server-forgejo
      includeSelectors: true
      includeTemplates: true

    resources:
    - resources/server-forgejo-data.persistentvolumeclaim.yaml
    - resources/server-forgejo-git.persistentvolumeclaim.yaml
    - resources/server-forgejo.service.yaml
    - resources/server-forgejo.statefulset.yaml

    replicas:
    - name: server-forgejo
      count: 1

    images:
    - name: docker.io/busybox
      newTag: stable-musl
    - name: codeberg.org/forgejo/forgejo
      newTag: 14.0-rootless

    configMapGenerator:
    - name: server-forgejo-env-vars
      envs:
      - configs/env.properties

    secretGenerator:
    - name: server-forgejo-valkey-user
      envs:
      - secrets/valkey_user_env.properties
    ~~~

    This `Kustomization` manifest is like the others you have created for other components, with just a few particularities to highlight:

    - The two images listed correspond to the containers used in the `StatefulSet`, one for the init container and the other for the Forgejo server.

    - In the `resources` block are listed the files declaring the `PersistentVolumeClaim` resources used to enable persistent storage in the Forgejo server, together with the other usual declarations for the corresponding `StatefulSet` and `Service`.

    - The `configMapGenerator` block declares the `server-forgejo-env-vars`  `ConfigMap` object containing only [the `configs/env.properties` file with the specific environment variables that adjust the configuration of the Forgejo server](#non-secret-forgejo-configuration-parameters).

    - The `secretGenerator` block is configured to produce a `Secret` object only containing the environment variables with the credentials of the Forgejo server's Valkey user.

### Validating the Kustomize YAML output

At this point, you have completed the Forgejo server Kustomize subproject. It is time to test it out with `kubectl`:

1. Execute the `kubectl kustomize` command on the Forgejo server Kustomize subproject's root folder, piped to `less` (or to your preferred text editor) to get the output paginated:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/forgejo/components/server-forgejo | less
    ~~~

2. The resulting YAML should look like this:

    ~~~yaml
    apiVersion: v1
    data:
      FORGEJO__cache__ADAPTER: redis
      FORGEJO__cache__ENABLED: "true"
      FORGEJO__database__DB_TYPE: postgres
      FORGEJO__database__HOST: db-postgresql.forgejo.svc.homelab.cluster.:5432
      FORGEJO__database__SSL_MODE: disable
      FORGEJO__metrics__ENABLED: "true"
      FORGEJO__queue__QUEUE_NAME: _queue_forgejo
      FORGEJO__queue__SET_NAME: _uniqueue_forgejo
      FORGEJO__queue__TYPE: redis
      FORGEJO__server__DOMAIN: forgejo.homelab.cloud
      FORGEJO__server__HTTP_ADDR: 0.0.0.0
      FORGEJO__server__LFS_START_SERVER: "true"
      FORGEJO__session__COOKIE_NAME: forgejo_cookie
      FORGEJO__session__PROVIDER: redis
    kind: ConfigMap
    metadata:
      labels:
        app: server-forgejo
      name: server-forgejo-env-vars-bht2m829kt
    ---
    apiVersion: v1
    data:
      FORGEJO_VALKEY_PASSWORD: cEFTMndPckRfZjByX1RoZV9GMHJnRUowX1VzM1I=
      FORGEJO_VALKEY_USERNAME: Zm9yZ2Vqb2NhY2hl
    kind: Secret
    metadata:
      labels:
        app: server-forgejo
      name: server-forgejo-valkey-user-5k8kmm9bk4
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
        app: server-forgejo
      name: server-forgejo
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
        app: server-forgejo
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-forgejo
      name: server-forgejo-data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.9G
      storageClassName: local-path
      volumeName: forgejo-ssd-data
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-forgejo
      name: server-forgejo-git
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 19G
      storageClassName: local-path
      volumeName: forgejo-hdd-git
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-forgejo
      name: server-forgejo
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-forgejo
      serviceName: server-forgejo
      template:
        metadata:
          labels:
            app: server-forgejo
        spec:
          automountServiceAccountToken: false
          containers:
          - env:
            - name: FORGEJO__database__NAME
              valueFrom:
                configMapKeyRef:
                  key: postgresql-db-name
                  name: db-postgresql-config
            - name: FORGEJO__database__USER
              valueFrom:
                configMapKeyRef:
                  key: forgejo-username
                  name: db-postgresql-config
            - name: FORGEJO__database__PASSWD
              valueFrom:
                secretKeyRef:
                  key: forgejo-user-password
                  name: db-postgresql-secrets
            - name: FORGEJO__database__SCHEMA
              valueFrom:
                configMapKeyRef:
                  key: forgejo-username
                  name: db-postgresql-config
            - name: FORGEJO__cache__HOST
              value: redis://$(FORGEJO_VALKEY_USERNAME):$(FORGEJO_VALKEY_PASSWORD)@cache-valkey.forgejo.svc.homelab.cluster.:6379/0?pool_size=100&idle_timeout=180s&prefix=forgejo%3A
            - name: FORGEJO__session__PROVIDER_CONFIG
              value: $(FORGEJO__cache__HOST)
            - name: FORGEJO__queue__CONN_STR
              value: $(FORGEJO__cache__HOST)
            envFrom:
            - configMapRef:
                name: server-forgejo-env-vars-bht2m829kt
            - secretRef:
                name: server-forgejo-valkey-user-5k8kmm9bk4
            image: codeberg.org/forgejo/forgejo:14.0-rootless
            livenessProbe:
              failureThreshold: 10
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: forgejo.homelab.cloud
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
                  value: forgejo.homelab.cloud
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
              runAsGroup: 1000
              runAsNonRoot: true
              runAsUser: 1000
            volumeMounts:
            - mountPath: /var/lib/gitea
              name: forgejo-data-storage
              readOnly: false
            - mountPath: /var/lib/gitea/git
              name: forgejo-git-storage
              readOnly: false
            - mountPath: /tmp/gitea
              name: tmp
              readOnly: false
          hostAliases:
          - hostnames:
            - forgejo.homelab.cloud
            ip: 10.7.0.1
          initContainers:
          - command:
            - /bin/sh
            - -c
            - |
              set -e

              chown -Rfv 1000:1000 $FORGEJO_APP_DATA_PATH && echo "chown ok on $FORGEJO_APP_DATA_PATH" || echo "Error changing ownership of $FORGEJO_APP_DATA_PATH directory"
              chown -Rfv 1000:1000 /tmp/forgejo && echo "chown ok on /tmp/forgejo" || echo "Error changing ownership of /tmp/forgejo directory"

              export DIRS='git git/custom git/repositories git/lfs'
              echo 'Check if base dirs exists, if not, create them'
              echo "Directories to check: $DIRS"
              for dir in $DIRS; do
                if [ ! -d $FORGEJO_APP_DATA_PATH/$dir ]; then
                  echo "Creating $FORGEJO_APP_DATA_PATH/$dir directory"
                  mkdir -pv $FORGEJO_APP_DATA_PATH/$dir || echo "Error creating $FORGEJO_APP_DATA_PATH/$dir directory"
                fi
                chown -Rfv 1000:1000 $FORGEJO_APP_DATA_PATH/$dir && echo "chown ok on $dir" || echo "Error changing ownership of $FORGEJO_APP_DATA_PATH/$dir directory"
              done

              exit 0
            env:
            - name: FORGEJO_APP_DATA_PATH
              value: /var/lib/gitea
            image: docker.io/busybox:stable-musl
            name: permissions-fix
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
            volumeMounts:
            - mountPath: /var/lib/gitea
              name: forgejo-data-storage
              readOnly: false
            - mountPath: /var/lib/gitea/git
              name: forgejo-git-storage
              readOnly: false
            - mountPath: /tmp/gitea
              name: tmp
              readOnly: false
          securityContext:
            fsGroup: 1000
            fsGroupChangePolicy: OnRootMismatch
          volumes:
          - name: forgejo-data-storage
            persistentVolumeClaim:
              claimName: server-forgejo-data
          - name: forgejo-git-storage
            persistentVolumeClaim:
              claimName: server-forgejo-git
          - emptyDir:
              sizeLimit: 64Mi
            name: tmp
    ~~~

## Do not deploy this Forgejo server project on its own

This Forgejo server setup is missing two critical element, the persistent volumes it needs to store its working directory data and the users Git repositories and LFS contents. Do not confuse them with the claims you have configured for your Forgejo server. Those persistent volumes and other elements to be declared in the main Kustomize project you will declare in the final part of this Forgejo deployment procedure. Until then, do not deploy this Forgejo server subproject.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/forgejo`
- `$HOME/k8sprjs/forgejo/components`
- `$HOME/k8sprjs/forgejo/components/server-forgejo`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/configs`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/resources`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/forgejo/components/server-forgejo/kustomization.yaml`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/configs/env.properties`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo-data.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo-git.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo.service.yaml`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/resources/server-forgejo.statefulset.yaml`
- `$HOME/k8sprjs/forgejo/components/server-forgejo/secrets/valkey_user_env.properties`

## References

### [Forgejo](https://forgejo.org/)

- [Forgejo Administrator Guide](https://forgejo.org/docs/latest/admin/)
  - [Configuration Cheat Sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/)
  - [Installation](https://forgejo.org/docs/latest/admin/installation/)
    - [Installation with Docker](https://forgejo.org/docs/latest/admin/installation/docker/)
  - [Setup](https://forgejo.org/docs/latest/admin/setup/)
    - [Storage settings](https://forgejo.org/docs/latest/admin/setup/storage/)

- [Codeberg. Forgejo](https://codeberg.org/forgejo/forgejo)
  - [Forgejo 14.0.1 container image](https://codeberg.org/forgejo/-/packages/container/forgejo/14.0.1)
  - [`custom/conf/app.example.ini`](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini)
  - [Dockerfile](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/Dockerfile)
  - [Dockerfile.rootless](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/Dockerfile.rootless)

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

- [Kubernetes Documentation. Tasks. Configure Pods and Containers. Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

- [Kubernetes Documentation. Reference. Kubernetes API. Workload Resources. Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
  - [Ports](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports)

### Other Kubernetes-related contents

- [StackOverFlow. Kubernetes: how to set VolumeMount user group and file permissions](https://stackoverflow.com/questions/43544370/kubernetes-how-to-set-volumemount-user-group-and-file-permissions)
- [StackOverflow. Why do we need a port/containerPort in a Kubernetes deployment/container definition?](https://stackoverflow.com/questions/57197095/why-do-we-need-a-port-containerport-in-a-kuberntes-deployment-container-definiti)
- [DevOpsCube. How to Setup Prometheus Monitoring On Kubernetes Cluster](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)
- [ACA Group. Blog. How to set up auto-discovery of Kubernetes endpoint services in Prometheus](https://www.acagroup.be/en/blog/auto-discovery-of-kubernetes-endpoint-services-prometheus/)

## Navigation

[<< Previous (**G034. Deploying services 03. Forgejo Part 3**)](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%203%20-%20PostgreSQL%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G034. Deploying services 03. Forgejo Part 5**) >>](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%205%20-%20Complete%20Forgejo%20platform.md)
