# G033 - Deploying services 02 ~ Ghost - Part 4 - Ghost server

- [Deploy the Ghost server just like another component](#deploy-the-ghost-server-just-like-another-component)
- [Considerations about the Ghost server](#considerations-about-the-ghost-server)
- [Ghost server Kustomize subproject's folders](#ghost-server-kustomize-subprojects-folders)
- [Ghost server configuration file](#ghost-server-configuration-file)
- [Ghost server environment variables](#ghost-server-environment-variables)
- [Ghost server persistent storage claim](#ghost-server-persistent-storage-claim)
- [Ghost server StatefulSet](#ghost-server-statefulset)
- [Ghost server Service](#ghost-server-service)
- [Ghost server Kustomize project](#ghost-server-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Ghost server project on its own](#do-not-deploy-this-ghost-server-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Ghost](#ghost)
  - [SREDevOps.org](#sredevopsorg)
  - [Kubernetes](#kubernetes)
    - [ConfigMaps](#configmaps)
    - [Storage](#storage)
    - [StatefulSets](#statefulsets)
    - [Environment variables](#environment-variables)
  - [Configuration of Pods and Containers](#configuration-of-pods-and-containers)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
    - [About ConfigMaps and Secrets](#about-configmaps-and-secrets)
    - [About Kubernetes storage](#about-kubernetes-storage)
    - [About the Security Context](#about-the-security-context)
- [Navigation](#navigation)

## Deploy the Ghost server just like another component

This part covers the Kustomize configuration of the Ghost server as another component of the whole Ghost platform setup. The main particularity of the Ghost server deployment setup explained here is that it is not going to use the official Ghost container. It is going to use an alternative custom image produced by the people at [SREDevOps.org](https://www.sredevops.org/). The particularity of this image is that it comes with some improvements and hardenings that make the resulting container lighter and secure.

The Kubernetes deployment itself is an adaptation of [the one found in the GitHub repo for SREDevOps.org's Ghost on Kubernetes project](https://github.com/sredevopsorg/ghost-on-kubernetes), with the declaration files kept within [its `deploy` folder](https://github.com/sredevopsorg/ghost-on-kubernetes/tree/main/deploy). If you want to understand the original SREDevOps.org Kubernetes deployment of Ghost, [check out their own detailed explanation](https://www.sredevops.org/en/how-to-deploy-ghost-cms-on-kubernetes/).

## Considerations about the Ghost server

The SREDevOps.org container image of Ghost already includes what is necessary to run the server itself. Therefore, the main concerns to cover in this part are:

- Configuration of the the Ghost server to use the Valkey and MariaDB services prepared in the previous parts of this Ghost deployment procedure.

- Declaration of the Ghost server's persistent volume claim for the storage volume that will keep its data.

- Since the server is going to store "state" (meaning data), its deployment must be declared as a StatefulSet and use the persistent volume claim to use its corresponding storage volume.

## Ghost server Kustomize subproject's folders

As with the other components, you need a folder structure to contain the Ghost server Kustomize subproject:

~~~sh
$ mkdir -p $HOME/k8sprjs/ghost/components/server-ghost/{configs,resources,secrets}
~~~

Notice that, unlike for the other components, there is no `configs` folder here. This is because the single configuration file required for setting up Ghost will be treated as a secret. [Learn why in the next section](#ghost-server-configuration-file).

## Ghost server configuration file

The whole configuration of Ghost goes into a single JSON file. Among other parameters, it contains the users and passwords to connect with the Valkey and MariaDB instances. This circumstance justifies treating this file as a secret:

1. Create a `config.production.json` file under the `secrets` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/secrets/config.production.json
    ~~~

    The `production` suffix is because Ghost has "environment support, essentially meaning that you could switch the same Ghost instance from being a production environment to a development one if needed.

2. Enter the configuration for your Ghost server in `secrets/config.production.json`:

    ~~~json
    {
      "url": "https://ghost.homelab.cloud",
      "admin": {
        "url": "https://ghostadmin.homelab.cloud"
      },
      "server": {
        "host": "0.0.0.0",
        "port": 2368
      },
      "logging": {
        "transports": [
            "stdout"
        ]
      },
      "mail": {
        "transport": "SMTP",
        "from": "info@ghost.homelab.cloud",
        "options": {
          "service": "Google",
          "host": "smtp.gmail.com",
          "port": 465,
          "secure": true,
          "auth": {
            "user": "your_ghost_email@gmail.com",
            "pass": "Y0ur_6hO5t_eM41l_P4SsvvoRd"
          }
        }
      },
      "adapters": {
        "cache": {
          "Redis": {
            "host": "cache-valkey.ghost",
            "port": 6379,
            "username": "ghostcache",
            "password": "pAS2wORT_f0r_T#e_Gh05T_Us3R",
            "keyPrefix": "ghost:",
            "ttl": 3600,
            "reuseConnection": true,
            "refreshAheadFactor": 0.8,
            "getTimeoutMilliseconds": 5000,
            "storeConfig": {
              "retryConnectSeconds": 10,
              "lazyConnect": true,
              "enableOfflineQueue": true,
              "maxRetriesPerRequest": 3
            }
          },
          "gscan": {
            "adapter": "Redis",
            "ttl": 43200,
            "refreshAheadFactor": 0.9,
            "keyPrefix": "ghost:gscan."
          },
          "imageSizes": {
            "adapter": "Redis",
            "ttl": 86400,
            "refreshAheadFactor": 0.95,
            "keyPrefix": "ghost:imageSizes."
          },
          "linkRedirectsPublic": {
            "adapter": "Redis",
            "ttl": 7200,
            "refreshAheadFactor": 0.9,
            "keyPrefix": "ghost:linkRedirectsPublic."
          },
          "postsPublic": {
            "adapter": "Redis",
            "ttl": 1800,
            "refreshAheadFactor": 0.7,
            "keyPrefix": "ghost:postsPublic."
          },
          "stats": {
            "adapter": "Redis",
            "ttl": 900,
            "refreshAheadFactor": 0.8,
            "keyPrefix": "ghost:stats."
          },
          "tagsPublic": {
            "adapter": "Redis",
            "ttl": 3600,
            "refreshAheadFactor": 0.8,
            "keyPrefix": "ghost:tagsPublic."
          }
        }
      },
      "hostSettings": {
        "linkRedirectsPublicCache": {
          "enabled": true
        },
        "postsPublicCache": {
          "enabled": true
        },
        "statsCache": {
          "enabled": true
        },
        "tagsPublicCache": {
          "enabled": true
        }
      },
      "database": {
        "client": "mysql",
        "connection": {
          "host": "db-mariadb.ghost",
          "user": "ghostdb",
          "password": "l0nG.Pl4in_T3xt_sEkRet_p4s5wORD-FoR_6h0sT_uZ3r!",
          "database": "ghost-db",
          "port": "3306"
        }
      },
      "process": "local",
      "paths": {
        "contentPath": "/home/nonroot/app/ghost/content"
      }
    }
    ~~~

    This configuration file is particularly long due to all the parameters involved in configuring the cache adapter that enables Ghost to use the Valkey instance:

    - `url`\
      Ghost instance's base url. Remember to enable the domain specified here in your local network.

    - `admin.url`\
      Ghost instance's alternative url only for accessing its [Admin API](https://docs.ghost.org/admin-api). This is a hardening measure to allow differentiate between the regular traffic towards the Ghost instance and requests meant only for the Admin API. Notice that the domain name for the Admin API is different from the one in the `url` parameter set before.

      > [!NOTE]
      > **Remember to associate the hostnames in both URLs to the Traefik service's IP**\
      > As you could have done for accessing the Traefik dashboard or Headlamp, you can add in the `hosts` file of your client system another entry right below the one you may have setup already:
      >
      > ~~~txt
      > 10.7.0.1 traefik.homelab.cloud headlamp.homelab.cloud
      > 10.7.0.1 ghost.homelab.cloud ghostadmin.homelab.cloud
      > ~~~
      >
      > This way, rather than having one bloated `hosts` line with all the DNS names related to the Traefik service IP, you can have those hostnames separated for clarity.

    - `server`\
      This block has the parameters declaring through which IP (the `host` value) and `port` the Ghost instance has to listen. In this case, Ghost will listen through all available IPs (`0.0.0.0`) in the port 2368, which is the default one for Ghost.

    - `logging`\
      Where to define where and how Ghost must deliver its logs. In this case, it is configured to print them in the standard output (`stdout`) rather than putting them in a file.

    - `email`\
      In Ghost deployments configured as production ones, it is required to configure an email service for sending notifications to Ghost users. Enter the proper values for the email service of your choice, knowing that:

      - The `from` parameter is where you specify the email representing your Ghost instance.

      - You have to enter the user and password of your email service of choice in the `options.auth` section.

    - `adapters.cache`\
      This section is about configuring the cache adapter for Ghost. Ghost has an adapter to connect with Redis, which also works with [the Valkey instance configured previously](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md):

      - `Redis`\
        Configures the Redis connection to the Valkey instance. It is not clear if it is necessary to call this entry `Redis` or if it can be called in some other way, like `Valkey` for instance.

        Among all the parameters configuring the connection with the Valkey instance, pay attention to the `keyPrefix` entry. It has the same `ghost:` prefix that was configured [in the ACL rule for the `ghostcache` user in the Valkey setup](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#valkey-acl-user-list).

        Also notice how the `host` value is the internal cluster hostname of the Valkey service that will be running in the setup.

      - `gscan`, `imageSizes`, `linkRedirectsPublic`, `postsPublic`, `stats`, `tagsPublic`\
        These blocks enable adapters for caching particular contents that Ghost can handle. Notice that all of them inherit the configuration from the `Redis` adapter, but have their own particular settings in some specific parameters like the `keyPrefix` (although while keeping the `ghost:` prefix).

      > [!NOTE]
      > **The cache configuration is not properly explained in Ghost's official documentation**\
      > [The official documentation of Ghost gives a very incomplete explanation about the configuration of its Redis cache adapter](https://docs.ghost.org/config#ghost%E2%80%99s-built-in-redis-cache-adapter). Therefore, the setup shown here is the result of combining what is said in the following sources:
      >
      > - [The thread "Redis set up with ghost" in the Ghost Forum](https://forum.ghost.org/t/redis-set-up-with-ghost/56051).
      > - [MagicPages article "How CarExplore Achieved 70% Faster Page Loads with Ghost's Built-in Redis Caching"](https://www.magicpages.co/blog/how-carexplore-achieved-70-faster-page-loads-with-ghosts-built-in-redis-caching/) linked in the previous Ghost forum thread.

    - `hostSettings`\
      This is another configuration section not properly explained in the Ghost documentation. Here it is used only to enable certain cache features already configured in the previous `adapters.cache` block.

    - `database`\
      This is the section where to configure the connection with your MariaDB instance. In particular, see how the host value points to the internal cluster hostname of the MariaDB service that will be running in this deployment.

    - `process`\
      This parameter allows to pick which process manager to use for handling the Ghost server process, and supports only the `local` and `systemd` options. Beyond this, there is no further explanation about this parameter as you can see [in the _Service options_ section found here](https://docs.ghost.org/ghost-cli#options).

    - `paths.contentPath`\
      This path is where Ghost will keep contents like data, images, logs and adapters. The path specified here is correlated to the ones you will see configured in the custom Ghost container image specified in the `StateFulSet` declared later in this part.

    > [!WARNING]
    > **The passwords are put in `secrets/config.production.json` as plain unencrypted text**\
    > Be careful of who can access this `config.production.json` file.

## Ghost server environment variables

There are a few environment variables you will have to declare in the Ghost server deployment that are better put together in one configuration file:

1. Create a new `env.properties` file under `configs`:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/configs/env.properties
    ~~~

2. Put the following environment variables in `configs/env.properties`:

    ~~~properties
    GHOST_INSTALL=/home/nonroot/app/ghost
    GHOST_CONTENT=/home/nonroot/app/ghost/content
    NODE_ENV=production
    ~~~

    The meaning of these environment variables is:

    - `GHOST_INSTALL`\
      Path where the Ghost server software will be installed.

    - `GHOST_CONTENT`\
      Path where the contents stored by Ghost will be kept.

    - `NODE_ENV`\
      Determines the mode in which the Ghost server is going to run. Ghost supports the `production` and `development` modes which, among other details, determine which type of database is used with Ghost. In `production` mode, Ghost requires using a MySQL database, whereas in `development` mode it is possible to use an SQLite one.

## Ghost server persistent storage claim

Here you will declare the `PersistentVolumeClaim` that links your Ghost server with the persistent volume (declared in the last part of this Ghost deployment procedure) that will hold its contents:

1. Create a `server-ghost.persistentvolumeclaim.yaml` file under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.persistentvolumeclaim.yaml
    ~~~

2. Declare the `PersistentVolumeClaim` in `resources/server-ghost.persistentvolumeclaim.yaml` with the declaration next:

    ~~~yaml
    # Ghost server claim of persistent storage
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: server-ghost
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: ghost-hdd-srv
      resources:
        requests:
          storage: 9.3G
    ~~~

    The most relevant thing to notice is that this claim uses the persistent volume you will declare later (in the last part of this Ghost deployment procedure) on the LVM light volume created in the Proxmox VE host's HDD drive.

## Ghost server StatefulSet

The Ghost server stores content, making necessary to deploy it as a `StatefulSet` rather than a `Deployment` resource:

1. Create a `server-ghost.statefulset.yaml` file under the `resources` path:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.statefulset.yaml
    ~~~

2. Declare the `StatefulSet` for the Ghost server in `resources/server-ghost.statefulset.yaml`:

    ~~~yaml
    # Ghost server StatefulSet for an initialized regular pod
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-ghost
    spec:
      replicas: 1
      serviceName: server-ghost
      template:
        spec:
          initContainers:
          - name: permissions-fix
            image: docker.io/busybox:stable-musl
            env:
            - name: GHOST_CONTENT
              valueFrom:
                configMapKeyRef:
                  name: server-ghost-env-vars
                  key: GHOST_CONTENT
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

                export DIRS='files logs apps themes data public settings images media'
                echo 'Check if base dirs exists, if not, create them'
                echo "Directories to check: $DIRS"
                for dir in $DIRS; do
                  if [ ! -d $GHOST_CONTENT/$dir ]; then
                    echo "Creating $GHOST_CONTENT/$dir directory"
                    mkdir -pv $GHOST_CONTENT/$dir || echo "Error creating $GHOST_CONTENT/$dir directory"
                  fi
                  chown -Rfv 65532:65532 $GHOST_CONTENT/$dir && echo "chown ok on $dir" || echo "Error changing ownership of $GHOST_CONTENT/$dir directory"
                done
                exit 0
            volumeMounts:
            - name: ghost-storage
              mountPath: /home/nonroot/app/ghost/content
              readOnly: false
          containers:
          - name: server
            image: ghcr.io/sredevopsorg/ghost-on-kubernetes:main
            ports:
            - name: server
              containerPort: 2368
              protocol: TCP
            readinessProbe:
              httpGet:
                path: /ghost/api/admin/site/
                port: server
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
              periodSeconds: 10
              timeoutSeconds: 3
              successThreshold: 1
              failureThreshold: 3
              initialDelaySeconds: 10
            livenessProbe:
              httpGet:
                path: /ghost/api/admin/site/
                port: server
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
              periodSeconds: 300
              timeoutSeconds: 3
              successThreshold: 1
              failureThreshold: 1
              initialDelaySeconds: 30
            envFrom:
            - configMapRef:
                name: server-ghost-env-vars
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
            volumeMounts:
            - name: ghost-storage
              mountPath: /home/nonroot/app/ghost/content
            - name: ghost-config
              readOnly: true
              mountPath: /home/nonroot/app/ghost/config.production.json
              subPath: config.production.json
            - name: tmp
              mountPath: /tmp
            securityContext:
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false
              runAsNonRoot: true
              runAsUser: 65532
          automountServiceAccountToken: false
          hostAliases:
          - ip: "10.7.0.1"
            hostnames:
            - "ghost.homelab.cloud"
            - "ghostadmin.homelab.cloud"
          volumes:
          - name: ghost-storage
            persistentVolumeClaim:
              claimName: server-ghost
          - name: ghost-config
            secret:
              secretName: server-ghost-config
              defaultMode: 420
              items:
              - key: config.production.json
                path: config.production.json
          - name: tmp
            emptyDir:
              sizeLimit: 64Mi
    ~~~

    First thing you must know about this particular `StatefulSet` declaration is that it is an adaptation of [the one included in the _Ghost on Kubernetes_ project](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml).

    > [!NOTE]
    > **_Ghost on Kubernetes_ is a project maintained by the people at SREDevOps**\
    > The _Ghost on Kubernetes_ project is freely available [in its own GitHub repository](https://github.com/sredevopsorg/ghost-on-kubernetes).
    >
    > [Check out this SREDevOps article to better understand it](https://www.sredevops.org/en/how-to-deploy-ghost-cms-on-kubernetes/).

    Beyond the parameters you have already seen declared in the `StatefulSet` for the Valkey and MariaDB instances, this StatefulSet for the Ghost server characterizes itself in:

    - Having an init container that prepares the Ghost folder structure to be run by a non-root user.

    - Configuring a hardened container where the Ghost instance is run by a non-root user.

    Lets review those and other relevant details present in this `StatefulSet` for the Ghost server instance:

    - `spec.template.spec.initContainers`\
      [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) run and finish before the app containers start. In this case, just one init container named `permissions-fix` is used to execute a script for setting the proper permissions and non-root user ownership of the content folder structure for the Ghost server.

      - The init container `image` is of a BusyBox utility environment. This is a lightweight utility system that comes with a set of common tools helpful in managing Kubernetes clusters.

      - The `GHOST_CONTENT` environment variable is the path to where the Ghost server will store all its contents. Notice that this variable is loaded in a `ConfigMap` resource you will set later in the corresponding Kustomize declaration for this Ghost server subproject.

      - The init container has a `securityContext` to limit its security footprint:

        - `readOnlyRootFilesystem` is enabled to ensure that the init container's root filesystem cannot be modified while the container is running. This makes necessary to enable an ephemeral _in-memory_ volume where changes can be written outside the container's root filesystem. This temporary path is an `emptyDir` feature that is explained later in this section.

        - With `allowPrivilegeEscalation` set as `false`, the general intention is to restrict the processes running within the init container from gaining more privileges than the ones they got originally. In reality, disabling `allowPrivilegeEscalation` just sets a `NO_NEW_PRIVS` Linux flag within the container that only prevents:

          - SUID binaries from working.
          - Blocking-file capabilities from taking effect.
          - Ptrace-based privilege escalation.

          > [!IMPORTANT]
          > To better understand how disabling the `allowPrivilegeEscalation` option affects the security of a Kubernetes setup, [check this detailed explainer by Harsha Koushik](https://medium.com/kernel-space/allowprivilegeescalation-false-the-kubernetes-security-flag-with-a-hidden-catch-e81292a0f43c).

      - The `command` parameter contains the script that creates the folder structure for storing the Ghost server contents under the path indicated by the `GHOST_CONTENT` environment variable. Within the script there is a DIR environment variable that specifies the names of the folders to be created in the `GHOST_CONTENT` path.

        Also notice in the script the `chown` command applied to each folder that ensures that the non-root `65532` user is the one with access to those folders. The `65532` user is the one under which the Ghost server will run.

    - `spec.template.spec.containers.server`\
      In the containers block there is only the container for the Ghost server itself, which is called `server`:

      - This container's `image` is not an official Ghost one, but the customized version prepared by the people at SREDevOps.org to run with the non-root `65532` user. This customized image uses different "non-root" paths to store the Ghost installation files and the contents, plus it is configured to run in production mode by default.

      - This container has two probes enabled, one to check if the Ghost server is ready (the `readinessProbe` section) and the other to test if the server is live (the `livenessProbe` section). Both probes have a similar configuration, where they make an HTTP Get request every `periodSeconds` to a specific [Ghost Admin API `/site/` endpoint](https://docs.ghost.org/admin-api#endpoints) to see if it responds within `timeoutSeconds`.

        A detail to notice is that the `Host` value in the `httpGet` block of both probes points to the internal cluster hostname of this Ghost server's service. Usually, you would enter here the public DNS name of the server. Since this guide's setup does not contemplate having a DNS system available in the local network, you can either put the external IP that will be assigned to the Ghost `Service` resource, the internal cluster IP or the internal cluster hostname of the corresponding Ghost service running in this setup. Remember that, [in the Ghost server's configuration file](#ghost-server-configuration-file), the Ghost server is set to listen through all its available interfaces (`0.0.0.0`).

        > [!NOTE]
        > [Learn more about how to configure these probes in this official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes).

      - The `envFrom` block loads the environment variables configured in the file declared earlier that will be handled by a `ConfigMap` resource you will enable in the Kustomize declaration for this Ghost server subproject.

      - The `volumeMounts` connects the Ghost server container with three storage resources:

        - The storage for contents in the `/home/nonroot/app/ghost/content` path.

        - The configuration file of the Ghost server in `/home/nonroot/app/ghost/config.production.json`.

        - An ephemeral in-memory storage that provides the Ghost server with a `tmp` folder where to put temporary data. This temporary storage is necessary since the Ghost server container's filesystem is set up as read-only in the `securityContext` and the server needs a place where it can write data while running.

        > [!NOTE]
        > **Using an ephemeral path outside of the container's filesystem for temporary operations is a hardening action**
        > By using this type of storage, you avoid modifying the container's filesystem which should be kept as-is since it only has to be executed by the Kubernetes cluster. Since read-only containers cannot be written, you need to use this type of ephemeral storage to enable writing operations in the pod.
        >
        > [Learn more about the need for ephemeral storages when using read-only filesystems in this article by Thorsten Hans](https://www.thorsten-hans.com/read-only-filesystems-in-docker-and-kubernetes/).

      - The `securityContext` for the Ghost server container has the same options as the init container, plus two more to make the container be executed by a non-root user:

        - The `runAsNonRoot` forces to run the container under a Linux user that has a UID different than `0`, which is the one identifying the root user in any Linux environment.

        - The `runAsUser` parameter is where you specify which user the container is going to run under. In this case, it is the unnamed non-root user `65532`.

        > [!WARNING]
        > **The container image must be prepared to be run by a non-root user**\
        > To be able to run a container with a non-root user, its image must have been prepared explicitly to be run with such user. Before running a container with a non-root user, investigate if its image has been already prepared for it, and which user is using to configurate the pod accordingly.

    - The `automountServiceAccountToken` is another security option related to how Kubernetes gives access to its control plane API. For pods that are not supposed to use the control plane API, you can block their access to that API by not linking them with [the security token of the default `ServiceAccount` existing in their namespace](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). This essentially disables the capacity of the pod to authenticate with the Kubernetes control plane, effectively blocking its access to such API.

    - The `hostAliases` block allows adding entries to the `/etc/hosts` file of the pod generated by this StatefulSet. Since Ghost needs to find its own `url` active, and there is no external DNS service resolving its hostname, it is necessary to enable it within the pod's `/etc/hosts` file.

      The `ip` value is the static IP of the Traefik service through which the Ghost server will be reachable. The `hostnames` list has the two hostnames entered [in the `url` and `admin.url` parameters of the Ghost configuration file](#ghost-server-configuration-file).

    - In the `volumes` block you have the three storage resources needed in this Ghost server pod:

      - The `ghost-storage` item links to the claim of the persistent volume enabling the LVM existing in the K3s agent node.

      - The `ghost-config` entry makes the Ghost server's `config.production.json` configuration available in the pod.

      - The `tmp` entry is an emptyDir that enables the ephemeral in-memory storage for temporary operations happening in the Ghost server.

## Ghost server Service

Your Ghost server's `StatefulSet` requires a `Service` called `server-ghost` to run:

1. Create a file called `server-ghost.service.yaml` under `resources`:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.service.yaml
    ~~~

2. Declare the `Service` for the Ghost server in `resources/server-ghost.service.yaml`:

    ~~~yaml
    # Ghost server headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: server-ghost
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - port: 2368
        targetPort: server
        protocol: TCP
        name: server
    ~~~

    This Service's `type` is `LoadBalancer`, meaning that it would take the next available IP from the MetalLB pool to use as external public IP in your network:

    - Since this guide's local network setup lacks a DNS service (do not confuse it with the internal CoreDNS service running within the K3s cluster), it is better to ensure the service always uses the same external IP. In services of the type `LoadBalancer` like this one, you can specify a specific external IP from the range available in you Kubernetes cluster's load balancer (MetalLB in this guide's setup) in the `loadBalancerIP` parameter. In the YAML above, `10.7.0.3` is the address right the next one after the IP already assigned to the [Headlamp service (`10.7.0.2`)](G030%20-%20K3s%20cluster%20setup%2013%20~%20Enabling%20the%20Traefik%20dashboard.md).

    - A `LoadBalancer` type service can also have an internal `clusterIP`, but Kubernetes does not allow to set it as `None`. Since this IP is not going to be used in this setup, the `clusterIP` parameter is not specified.

    - Since there is no Prometheus metric exporter nor a port through which the Ghost server could provide such metrics, there is only one port declared in this `Service` resource that redirects all traffic to the Ghost server container's `server` port. Notice that the port number specified here is the same one set in the container, which is the default Ghost server's `2368`.

## Ghost server Kustomize project

With all the necessary elements for your Ghost server component declared in their respective files, you can put them together as a Kustomize project:

1. Create a `kustomization.yaml` file in the `server-ghost` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/ghost/components/server-ghost/kustomization.yaml
    ~~~

2. Declare your Ghost server `Kustomization` in `kustomization.yaml`:

    ~~~yaml
    # Ghost server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app: server-ghost
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/server-ghost.persistentvolumeclaim.yaml
    - resources/server-ghost.service.yaml
    - resources/server-ghost.statefulset.yaml

    replicas:
    - name: server-ghost
      count: 1

    images:
    - name: docker.io/busybox
      newTag: stable-musl
    - name: ghcr.io/sredevopsorg/ghost-on-kubernetes
      newTag: main

    configMapGenerator:
    - name: server-ghost-env-vars
      envs:
      - configs/env.properties

    secretGenerator:
    - name: server-ghost-config
      files:
      - secrets/config.production.json
    ~~~

    This `kustomization.yaml`, compared to the ones you have already set up for the Valkey and MariaDB components, does not have anything in particular to highlight. All the parameters specified there should be familiar to you at this point.

### Validating the Kustomize YAML output

As with the other components, you should check the output generated by the Ghost server's Kustomize subproject:

1. Generate the YAML with `kubectl kustomize` as usual:

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/ghost/components/server-ghost | less
    ~~~

2. See if your YAML output looks like the one below:

    ~~~yaml
    apiVersion: v1
    data:
      GHOST_CONTENT: /home/nonroot/app/ghost/content
      GHOST_INSTALL: /home/nonroot/app/ghost
      NODE_ENV: production
    kind: ConfigMap
    metadata:
      labels:
        app: server-ghost
      name: server-ghost-env-vars-9ggkgtdt7b
    ---
    apiVersion: v1
    data:
      config.production.json: |
        ewogICJ1cmwiOiAiaHR0cHM6Ly9naG9zdC5ob21lbGFiLmNsb3VkIiwKICAiYWRtaW4iOi
        B7CiAgICAidXJsIjogImh0dHBzOi8vZ2hvc3RhZG1pbi5ob21lbGFiLmNsb3VkIgogIH0s
        CiAgInNlcnZlciI6IHsKICAgICJob3N0IjogIjAuMC4wLjAiLAogICAgInBvcnQiOiAyMz
        Y4CiAgfSwKICAibG9nZ2luZyI6IHsKICAgICJ0cmFuc3BvcnRzIjogWwogICAgICAgICJz
        dGRvdXQiCiAgICBdCiAgfSwKICAibWFpbCI6IHsKICAgICJ0cmFuc3BvcnQiOiAiU01UUC
        IsCiAgICAiZnJvbSI6ICJpbmZvQGdob3N0LmhvbWVsYWIuY2xvdWQiLAogICAgIm9wdGlv
        bnMiOiB7CiAgICAgICJzZXJ2aWNlIjogIkdvb2dsZSIsCiAgICAgICJob3N0IjogInNtdH
        AuZ21haWwuY29tIiwKICAgICAgInBvcnQiOiA0NjUsCiAgICAgICJzZWN1cmUiOiB0cnVl
        LAogICAgICAiYXV0aCI6IHsKICAgICAgICAidXNlciI6ICJ2YXJpZWRyb0BnbWFpbC5jb2
        0iLAogICAgICAgICJwYXNzIjogIkQzczFnTmVSITpsRTdhdl9BLiIKICAgICAgfQogICAg
        fQogIH0sCiAgImFkYXB0ZXJzIjogewogICAgImNhY2hlIjogewogICAgICAiUmVkaXMiOi
        B7CiAgICAgICAgImhvc3QiOiAiY2FjaGUtdmFsa2V5Lmdob3N0IiwKICAgICAgICAicG9y
        dCI6IDYzNzksCiAgICAgICAgInVzZXJuYW1lIjogImdob3N0Y2FjaGUiLAogICAgICAgIC
        JwYXNzd29yZCI6ICJwQVMyd09SVF9mMHJfVCNlX0doMDVUX1VzM1IiLAogICAgICAgICJr
        ZXlQcmVmaXgiOiAiZ2hvc3Q6IiwKICAgICAgICAidHRsIjogMzYwMCwKICAgICAgICAicm
        V1c2VDb25uZWN0aW9uIjogdHJ1ZSwKICAgICAgICAicmVmcmVzaEFoZWFkRmFjdG9yIjog
        MC44LAogICAgICAgICJnZXRUaW1lb3V0TWlsbGlzZWNvbmRzIjogNTAwMCwKICAgICAgIC
        Aic3RvcmVDb25maWciOiB7CiAgICAgICAgICAicmV0cnlDb25uZWN0U2Vjb25kcyI6IDEw
        LAogICAgICAgICAgImxhenlDb25uZWN0IjogdHJ1ZSwKICAgICAgICAgICJlbmFibGVPZm
        ZsaW5lUXVldWUiOiB0cnVlLAogICAgICAgICAgIm1heFJldHJpZXNQZXJSZXF1ZXN0Ijog
        MwogICAgICAgIH0KICAgICAgfSwKICAgICAgImdzY2FuIjogewogICAgICAgICJhZGFwdG
        VyIjogIlJlZGlzIiwKICAgICAgICAidHRsIjogNDMyMDAsCiAgICAgICAgInJlZnJlc2hB
        aGVhZEZhY3RvciI6IDAuOSwKICAgICAgICAia2V5UHJlZml4IjogImdob3N0OmdzY2FuLi
        IKICAgICAgfSwKICAgICAgImltYWdlU2l6ZXMiOiB7CiAgICAgICAgImFkYXB0ZXIiOiAi
        UmVkaXMiLAogICAgICAgICJ0dGwiOiA4NjQwMCwKICAgICAgICAicmVmcmVzaEFoZWFkRm
        FjdG9yIjogMC45NSwKICAgICAgICAia2V5UHJlZml4IjogImdob3N0OmltYWdlU2l6ZXMu
        IgogICAgICB9LAogICAgICAibGlua1JlZGlyZWN0c1B1YmxpYyI6IHsKICAgICAgICAiYW
        RhcHRlciI6ICJSZWRpcyIsCiAgICAgICAgInR0bCI6IDcyMDAsCiAgICAgICAgInJlZnJl
        c2hBaGVhZEZhY3RvciI6IDAuOSwKICAgICAgICAia2V5UHJlZml4IjogImdob3N0Omxpbm
        tSZWRpcmVjdHNQdWJsaWMuIgogICAgICB9LAogICAgICAicG9zdHNQdWJsaWMiOiB7CiAg
        ICAgICAgImFkYXB0ZXIiOiAiUmVkaXMiLAogICAgICAgICJ0dGwiOiAxODAwLAogICAgIC
        AgICJyZWZyZXNoQWhlYWRGYWN0b3IiOiAwLjcsCiAgICAgICAgImtleVByZWZpeCI6ICJn
        aG9zdDpwb3N0c1B1YmxpYy4iCiAgICAgIH0sCiAgICAgICJzdGF0cyI6IHsKICAgICAgIC
        AiYWRhcHRlciI6ICJSZWRpcyIsCiAgICAgICAgInR0bCI6IDkwMCwKICAgICAgICAicmVm
        cmVzaEFoZWFkRmFjdG9yIjogMC44LAogICAgICAgICJrZXlQcmVmaXgiOiAiZ2hvc3Q6c3
        RhdHMuIgogICAgICB9LAogICAgICAidGFnc1B1YmxpYyI6IHsKICAgICAgICAiYWRhcHRl
        ciI6ICJSZWRpcyIsCiAgICAgICAgInR0bCI6IDM2MDAsCiAgICAgICAgInJlZnJlc2hBaG
        VhZEZhY3RvciI6IDAuOCwKICAgICAgICAia2V5UHJlZml4IjogImdob3N0OnRhZ3NQdWJs
        aWMuIgogICAgICB9CiAgICB9CiAgfSwKICAiaG9zdFNldHRpbmdzIjogewogICAgImxpbm
        tSZWRpcmVjdHNQdWJsaWNDYWNoZSI6IHsKICAgICAgImVuYWJsZWQiOiB0cnVlCiAgICB9
        LAogICAgInBvc3RzUHVibGljQ2FjaGUiOiB7CiAgICAgICJlbmFibGVkIjogdHJ1ZQogIC
        AgfSwKICAgICJzdGF0c0NhY2hlIjogewogICAgICAiZW5hYmxlZCI6IHRydWUKICAgIH0s
        CiAgICAidGFnc1B1YmxpY0NhY2hlIjogewogICAgICAiZW5hYmxlZCI6IHRydWUKICAgIH
        0KICB9LAogICJkYXRhYmFzZSI6IHsKICAgICJjbGllbnQiOiAibXlzcWwiLAogICAgImNv
        bm5lY3Rpb24iOiB7CiAgICAgICJob3N0IjogImRiLW1hcmlhZGIuZ2hvc3QiLAogICAgIC
        AidXNlciI6ICJnaG9zdGRiIiwKICAgICAgInBhc3N3b3JkIjogImwwbkcuUGw0aW5fVDN4
        dF9zRWtSZXRfcDRzNXdPUkQtRm9SXzZoMHNUX3VaM3IhIiwKICAgICAgImRhdGFiYXNlIj
        ogImdob3N0LWRiIiwKICAgICAgInBvcnQiOiAiMzMwNiIKICAgIH0KICB9LAogICJwcm9j
        ZXNzIjogImxvY2FsIiwKICAicGF0aHMiOiB7CiAgICAiY29udGVudFBhdGgiOiAiL2hvbW
        Uvbm9ucm9vdC9hcHAvZ2hvc3QvY29udGVudCIKICB9Cn0=
    kind: Secret
    metadata:
      labels:
        app: server-ghost
      name: server-ghost-config-6dbcdffbdc
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: server-ghost
      name: server-ghost
    spec:
      clusterIP: None
      ports:
      - name: server
        port: 2368
        protocol: TCP
        targetPort: server
      selector:
        app: server-ghost
      type: ClusterIP
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-ghost
      name: server-ghost
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.3G
      storageClassName: local-path
      volumeName: ghost-hdd-srv
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-ghost
      name: server-ghost
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-ghost
      serviceName: server-ghost
      template:
        metadata:
          labels:
            app: server-ghost
        spec:
          automountServiceAccountToken: false
          containers:
          - envFrom:
            - configMapRef:
                name: server-ghost-env-vars-9ggkgtdt7b
            image: ghcr.io/sredevopsorg/ghost-on-kubernetes:main
            livenessProbe:
              failureThreshold: 1
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
                path: /ghost/api/admin/site/
                port: server
              initialDelaySeconds: 30
              periodSeconds: 300
              successThreshold: 1
              timeoutSeconds: 3
            name: server
            ports:
            - containerPort: 2368
              name: server
              protocol: TCP
            readinessProbe:
              failureThreshold: 3
              httpGet:
                httpHeaders:
                - name: X-Forwarded-Proto
                  value: https
                - name: Host
                  value: server-ghost.ghost
                path: /ghost/api/admin/site/
                port: server
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 3
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 65532
            volumeMounts:
            - mountPath: /home/nonroot/app/ghost/content
              name: ghost-storage
            - mountPath: /home/nonroot/app/ghost/config.production.json
              name: ghost-config
              readOnly: true
              subPath: config.production.json
            - mountPath: /tmp
              name: tmp
          hostAliases:
          - hostnames:
            - ghost.homelab.cloud
            - ghostadmin.homelab.cloud
            ip: 10.7.0.1
          initContainers:
          - command:
            - /bin/sh
            - -c
            - |
              set -e

              export DIRS='files logs apps themes data public settings images media'
              echo 'Check if base dirs exists, if not, create them'
              echo "Directories to check: $DIRS"
              for dir in $DIRS; do
                if [ ! -d $GHOST_CONTENT/$dir ]; then
                  echo "Creating $GHOST_CONTENT/$dir directory"
                  mkdir -pv $GHOST_CONTENT/$dir || echo "Error creating $GHOST_CONTENT/$dir directory"
                fi
                chown -Rfv 65532:65532 $GHOST_CONTENT/$dir && echo "chown ok on $dir" || echo "Error changing ownership of $GHOST_CONTENT/$dir directory"
              done
              exit 0
            env:
            - name: GHOST_CONTENT
              valueFrom:
                configMapKeyRef:
                  key: GHOST_CONTENT
                  name: server-ghost-env-vars-9ggkgtdt7b
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
            - mountPath: /home/nonroot/app/ghost/content
              name: ghost-storage
              readOnly: false
          volumes:
          - name: ghost-storage
            persistentVolumeClaim:
              claimName: server-ghost
          - name: ghost-config
            secret:
              defaultMode: 420
              items:
              - key: config.production.json
                path: config.production.json
              secretName: server-ghost-config-6dbcdffbdc
          - emptyDir:
              sizeLimit: 64Mi
            name: tmp
    ~~~

    There are a few details you must notice in this YAML:

    - As expected, the `ConfigMap` and `Secret` resources you have declared in this Kustomize project have their names appended with a hash suffix.

    - Since the `config.production.json` file is a `Secret` resource, it has been fully encoded in base64.

    - Remember that Kustomize transforms the values you put at the `defaultMode` parameters set for the files you configure as `volumes`. [You already saw this happening while preparing the Valkey Kustomize subproject](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%202%20-%20Valkey%20cache%20server.md#validating-the-kustomize-yaml-output).

## Do not deploy this Ghost server project on its own

This Ghost server cannot be deployed on its own because is missing several things:

- The persistent volume it needs to store its data.

- It needs the Valkey cache server and the MariaDB server to run.

- Both the ingress resource and the TLS certificate for encrypted communications with the Ghost server will be declared in the last part of this deployment procedure.

Again I must tell you to wait to the upcoming final part of this Ghost deployment procedure. There you will add the missing parts, tie everything together and deploy the whole setup in one go.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/server-ghost`
- `$HOME/k8sprjs/ghost/components/server-ghost/configs`
- `$HOME/k8sprjs/ghost/components/server-ghost/resources`
- `$HOME/k8sprjs/ghost/components/server-ghost/secrets`

### Files in `kubectl` client system

- `$HOME/k8sprjs/ghost/components/server-ghost/kustomization.yaml`
- `$HOME/k8sprjs/ghost/components/server-ghost/configs/env.properties`
- `$HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.service.yaml`
- `$HOME/k8sprjs/ghost/components/server-ghost/resources/server-ghost.statefulset.yaml`
- `$HOME/k8sprjs/ghost/components/server-ghost/secrets/config.production.json`

## References

### [Ghost](https://ghost.org/)

- [Documentation. Core Concepts. Overview](https://docs.ghost.org/product)
  - [Configuration. Adapters](https://docs.ghost.org/config#adapters)
    - [Cache adapters. Ghost’s built-in Redis cache adapter](https://docs.ghost.org/config#ghost%E2%80%99s-built-in-redis-cache-adapter)

- [Documentation. Advanced Tools. Ghost CLI](https://docs.ghost.org/ghost-cli)
  - [Commands](https://docs.ghost.org/ghost-cli#commands)
    - [Ghost config. Options](https://docs.ghost.org/ghost-cli#options)

- [Documentation. Advanced Tools. Admin API](https://docs.ghost.org/admin-api)
  - [Structure. Base URL](https://docs.ghost.org/admin-api#base-url)
  - [Endpoints](https://docs.ghost.org/admin-api#endpoints)

- [Forum](https://forum.ghost.org/)
  - [HOWTO: Deploy ghost with helm on kubernetes](https://forum.ghost.org/t/howto-deploy-ghost-with-helm-on-kubernetes/47053)

### [SREDevOps.org](https://www.sredevops.org/)

- [GitHub. Ghost on Kubernetes](https://github.com/sredevopsorg/ghost-on-kubernetes)
- [How to deploy Ghost CMS on Kubernetes](https://www.sredevops.org/en/how-to-deploy-ghost-cms-on-kubernetes/)

### [Kubernetes](https://kubernetes.io/docs/)

#### ConfigMaps

- [Kubernetes Documentation. Concepts. Configuration](https://kubernetes.io/docs/concepts/configuration/)
  - [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

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

#### StatefulSets

- [Kubernetes Documentation. Concepts. Workloads. Workload Management](https://kubernetes.io/docs/concepts/workloads/controllers/)
  - [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### Environment variables

- [Kubernetes Documentation. Tasks. Inject Data Into Applications](https://kubernetes.io/docs/tasks/inject-data-application/)
  - [Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)
  - [Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

### Configuration of Pods and Containers

- [Kubernetes Documentation. Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
  - [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
  - [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
    - [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes)

### Other Kubernetes-related contents

#### About ConfigMaps and Secrets

- [OpenSource.com. An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Dev. Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [GoLinuxCloud. Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [StackOverflow. Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### About Kubernetes storage

- [Rancher K3s. Add-Ons. Volumes and Storage](https://docs.k3s.io/add-ons/storage)
  - [Setting up the Local Storage Provider](https://docs.k3s.io/add-ons/storage#setting-up-the-local-storage-provider)

- [GitHub. Rancher. Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

- [GitHub. K3s. Issue. Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)

- [StackOverflow. Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)

- [GitHub. Helm. Issue. distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)

- [Thorsten Hans. Read-only filesystems in Docker and Kubernetes](https://www.thorsten-hans.com/read-only-filesystems-in-docker-and-kubernetes/)

#### About the Security Context

- [Harsha Koushik. allowPrivilegeEscalation: false: The Kubernetes Security Flag With a Hidden Catch](https://medium.com/kernel-space/allowprivilegeescalation-false-the-kubernetes-security-flag-with-a-hidden-catch-e81292a0f43c)

## Navigation

[<< Previous (**G033. Deploying services 02. Ghost Part 3**)](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%203%20-%20MariaDB%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Ghost Part 5**) >>](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%205%20-%20Complete%20Ghost%20platform.md)