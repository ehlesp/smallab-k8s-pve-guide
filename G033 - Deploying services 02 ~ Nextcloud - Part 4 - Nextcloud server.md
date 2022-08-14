# G033 - Deploying services 02 ~ Nextcloud - Part 4 - Nextcloud server

In this fourth part of the Nextcloud platform guide you'll configure the Nextcloud server itself as another component of the whole thing.

## Considerations about the Nextcloud server

The Nextcloud server is a PHP application that needs a web service like Apache or Nginx to render its pages. The default image for Nextcloud is an Apache-based one, which is more straightforward to setup, while using Nginx is rather more complex. In this document I'll show you how to declare the Nextcloud server with Apache. You'll find an alternative configuration with Nginx and other ideas at the [**G911** appendix guide](G911%20-%20Appendix%2011%20~%20Alternative%20Nextcloud%20web%20server%20setups.md).

On the other hand, there's the detail of the certificate required to encrypt communications between clients and the Nextcloud server. The certificate itself is the wildcard one you already created back in the [**G029** guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md#setting-up-a-wildcard-certificate-for-a-domain), where you also deployed the cert-manager service into your Kubernetes cluster. You need to replicate the secret associated to that certificate in the namespace for this whole Nextcloud platform project, but that is something you'll do in the final part of this Nextcloud guide. Here you'll only see how that secret is referenced in the resource definition where is required.

## Nextcloud server Kustomize project's folders

As with the other components, you need a folder structure for this Kustomize project.

~~~bash
$ mkdir -p $HOME/k8sprjs/nextcloud/components/server-nextcloud/{configs,resources,secrets}
~~~

## Nextcloud server configuration files

This Apache-based Nextcloud server needs a couple of configuration files and another one with a bunch of key-value parameters.

### _Configuration file `ports.conf`_

The `ports.conf` file is where you must indicate to Apache which ports it has to listen on.

1. Create the `ports.conf` file under the `configs` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/ports.conf
    ~~~

2. Copy the content below in `ports.conf`.

    ~~~apache
    Listen 443

    # vim: syntax=apache ts=4 sw=4 sts=4 sr noet
    ~~~

    There's only one port configured here, the `443` which is the one used for **HTTPS** connections. The last line is just to inform the `vim` editor about this file's format.

### _Configuration file `000-default.conf`_

The `000-default.conf` is another Apache configuration file in which you set up all the neccesary parameters to make the Nextcloud site available and SSL enabled.

1. Create `000-default.conf` in the `configs` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/000-default.conf
    ~~~

2. Fill `000-default.conf` with the following Apache configuration.

    ~~~apache
    MinSpareServers 4
    MaxSpareServers 16
    StartServers 10
    MaxConnectionsPerChild 2048

    LoadModule socache_shmcb_module /usr/lib/apache2/modules/mod_socache_shmcb.so
    SSLSessionCache shmcb:/var/tmp/apache_ssl_scache(512000)

    <VirtualHost *:443>
      Protocols http/1.1
      ServerAdmin root@deimos.cloud
      ServerName nextcloud.deimos.cloud
      ServerAlias nxc.deimos.cloud

      Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"

      DocumentRoot /var/www/html
      DirectoryIndex index.php

      LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so
      SSLEngine on
      SSLCertificateFile /etc/ssl/certs/wildcard.deimos.cloud-tls.crt
      SSLCertificateKeyFile /etc/ssl/certs/wildcard.deimos.cloud-tls.key

      <Directory /var/www/html/>
        Options FollowSymlinks MultiViews
        AllowOverride All
        Require all granted

        <IfModule mod_dav.c>
          Dav off
        </IfModule>

        SetEnv HOME /var/www/html
        SetEnv HTTP_HOME /var/www/html
        Satisfy Any

      </Directory>

      ErrorLog ${APACHE_LOG_DIR}/error.log
      CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
    ~~~

    This configuration above is a modified version of [one found in the official Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html#apache-web-server-configuration).

    - The first thing you must be aware of is that the Apache instance you're going to run uses the default MPM (Multi-Processing Module) prefork module. This influences what parameters you have available and their effects to the configuration of the processes spawned by Apache.
        - The parameters at the top of the configuration adjust the number of Apache processes running in parallel in your setup. The `MaxConnectionsPerChild` indicates how many connections each process can handle before being respawned. To know more about these parameters, check [the official Apache MPM prefork documentation](https://httpd.apache.org/docs/2.4/mod/prefork.html).

    - For Apache to be able to maintain a cache of SSL sessions, it requires to load (with the `LoadModule` directive) the `socache_shmcb_module` since it doesn't come loaded by default. As you might suppose, the path to the `mod_socache_shmcb.so` library exists only within the container.

    - Notice how the `VirtualHost` is configured with the port `443` for listening to incoming requests.

    - Since the SSL module, named `ssl_module`, doesn't come loaded by default in Apache either, you also need to load it with its corresponding `LoadModule` directive.

    - Below the SSL load module directive, you can see how the SSL engine is enabled and the certificate is expected to be found in the `/etc/ssl/certs` path within the container.

### _Properties file `params.properties`_

There are a few values you want to load as parameters in your Kustomize project.

1. Create the file `params.properties` under the `configs` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/params.properties
    ~~~

2. Set the parameters below in `params.properties`.

    ~~~properties
    nextcloud-admin-username=admin
    nextcloud-trusted-domains=192.168.1.42 nextcloud.deimos.cloud nxc.deimos.cloud
    cache-redis-svc-cluster-ip=10.43.100.1
    db-mariadb-svc-cluster-ip=10.43.100.2
    ~~~

    The key-values above mean the following.

    - `nextcloud-admin-username`: the name given to the administrator user of your Nextcloud server.

    - `nextcloud-trusted-domains`: security restriction which tells the Nextcloud server on what IPs or domains can users log into the platform. In other words, these are the only IPs or domains Nextcloud will be accessible from. In this case, I've included the IP that will be assigned by the MetalLB load balancer to the corresponding service resource, and a couple of domains which should be enabled in the network or router's DNS, or on each client's `hosts` file.

    - `cache-redis-svc-cluster-ip` and `db-mariadb-svc-cluster-ip`: the internal cluster IPs of the Redis and MariaDB services. Put here so its easier to locate and change them if necessary.

## Nextcloud server password

You need to set one password for Nextcloud's administrator user as a Secret resource.

1. Create a `nextcloud-admin.pwd` file in the `secrets` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/secrets/nextcloud-admin.pwd
    ~~~

2. In the `nextcloud-admin.pwd` file, put just the string you want to use as password.

    ~~~properties
    Yo4R_P4s5wORd-f0r_The.n3x7clouD_Adm1niS7r6tor.us3r
    ~~~

    Like in other cases, the string is just a plain unencrypted text. Take care of who can access this file.

## Nextcloud server storage

Setting aside the database, which you already configured in the [previous part of this guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md), you need two persistent volumes for Nextcloud.

- One PV for storing the files (htmls essentially) of the Nextcloud server itself.
- One PV to store the Nextcloud users' files.

This means that you have to declare two different claim resources, one per PV.

### _Claim for the server html files PV_

1. Create a file named `html-server-nextcloud.persistentvolumeclaim.yaml` under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/html-server-nextcloud.persistentvolumeclaim.yaml
    ~~~

2. Copy the yaml below in `html-server-nextcloud.persistentvolumeclaim.yaml`.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: html-server-nextcloud
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: html-nextcloud
      resources:
        requests:
          storage: 1.2G
    ~~~

    If you compared the yaml above with the sole PVC you created for MariaDB, you'll see that the parameters used are exactly the same except in some values (names and storage requested).

### _Claim for the users data PV_

1. Create a `data-server-nextcloud.persistentvolumeclaim.yaml` file under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/data-server-nextcloud.persistentvolumeclaim.yaml
    ~~~

2. Fill `data-server-nextcloud.persistentvolumeclaim.yaml` with the declaration next.

    ~~~yaml
    apiVersion: v1
    kind: PersistentVolumeClaim

    metadata:
      name: data-server-nextcloud
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: local-path
      volumeName: data-nextcloud
      resources:
        requests:
          storage: 9.3G
    ~~~

## Nextcloud server Stateful resource

Since the Nextcloud server stores data, it's more adequate to deploy it as a `StatefulSet` rather than a `Deployment` resource.

1. Create a `server-apache-nextcloud.statefulset.yaml` file under the `resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.statefulset.yaml
    ~~~

2. Put the yaml declaration below in `server-apache-nextcloud.statefulset.yaml`.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-apache-nextcloud
    spec:
      replicas: 1
      serviceName: server-apache-nextcloud
      template:
        spec:
          containers:
          - name: server
            image: nextcloud:22.2-apache
            ports:
            - containerPort: 443
            env:
            - name: NEXTCLOUD_ADMIN_USER
              valueFrom:
                configMapKeyRef:
                  name: server-apache-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            - name: NEXTCLOUD_TRUSTED_DOMAINS
              valueFrom:
                configMapKeyRef:
                  name: server-apache-nextcloud
                  key: nextcloud-trusted-domains
            - name: MYSQL_HOST
              valueFrom:
                configMapKeyRef:
                  name: server-apache-nextcloud
                  key: db-mariadb-svc-cluster-ip
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: nextcloud-db-name
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  name: db-mariadb
                  key: nextcloud-username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-mariadb
                  key: nextcloud-user-password
            - name: REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  name: server-apache-nextcloud
                  key: cache-redis-svc-cluster-ip
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            - name: APACHE_ULIMIT_MAX_FILES
              value: 'ulimit -n 65536'
            lifecycle:
              postStart:
                exec:
                  command:
                  - "sh"
                  - "-c"
                  - |
                    chown www-data:www-data /var/www/html/data
            resources:
              limits:
                memory: 512Mi
            volumeMounts:
            - name: certificate
              subPath: wildcard.deimos.cloud-tls.crt
              mountPath: /etc/ssl/certs/wildcard.deimos.cloud-tls.crt
            - name: certificate
              subPath: wildcard.deimos.cloud-tls.key
              mountPath: /etc/ssl/certs/wildcard.deimos.cloud-tls.key
            - name: apache-config
              subPath: ports.conf
              mountPath: /etc/apache2/ports.conf
            - name: apache-config
              subPath: 000-default.conf
              mountPath: /etc/apache2/sites-available/000-default.conf
            - name: html-storage
              mountPath: /var/www/html
            - name: data-storage
              mountPath: /var/www/html/data
          - name: metrics
            image: xperimental/nextcloud-exporter:0.4.0-15-gbb88fb6
            ports:
            - containerPort: 9205
            env:
            - name: NEXTCLOUD_SERVER
              value: "https://localhost"
            - name: NEXTCLOUD_TLS_SKIP_VERIFY
              value: "true"
            - name: NEXTCLOUD_USERNAME
              valueFrom:
                configMapKeyRef:
                  name: server-apache-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            resources:
              limits:
                memory: 32Mi
          volumes:
          - name: apache-config
            configMap:
              name: server-apache-nextcloud
              defaultMode: 0644
              items:
              - key: ports.conf
                path: ports.conf
              - key: 000-default.conf
                path: 000-default.conf
          - name: certificate
            secret:
              secretName: wildcard.deimos.cloud-tls
              defaultMode: 0444
              items:
              - key: tls.crt
                path: wildcard.deimos.cloud-tls.crt
              - key: tls.key
                path: wildcard.deimos.cloud-tls.key
          - name: html-storage
            persistentVolumeClaim:
              claimName: html-server-nextcloud
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-nextcloud
    ~~~

    Like with Redis and MariaDB, the pod configured in the `StatefulSet` above has two containers in sidecar pattern.

    - `server` container: executes the Nextcloud server with its associated Apache service.
        - The `image` used here provides [the stable version of Nextcloud](https://hub.docker.com/_/nextcloud), running on a Debian setup.

        - `env` section: notice that some values are taken from the secrets and config maps defined for the Redis and MariaDB pods.
            - `NEXTCLOUD_ADMIN_USER` and `NEXTCLOUD_ADMIN_PASSWORD`: define the administrator user for the Nextcloud server, creating it when the server autoinstalls itself.
            - `NEXTCLOUD_TRUSTED_DOMAINS`: where the list of trusted domains must be set.
            - `MYSQL_HOST` and `MYSQL_DATABASE`: the IP of the MariaDB service and the database instance's name Nextcloud has to use.
            - `MYSQL_USER` and `MYSQL_PASSWORD`: the user Nextcloud has to use to connect to its own database on the MariaDB server.
            - `REDIS_HOST` and `REDIS_HOST_PASSWORD`: the IP to the Redis service and the password require to authenticate in that server.
            - `APACHE_ULIMIT_MAX_FILES`: increases the number of files Apache can open at the same time.

        - `lifecycle.postStart.exec.command`: this defines a command meant to be executed right after the container has started. In this case, a `chown` is executed because the folder in which Nextcloud has to store the user data happens to be owned by `root` but it needs to be owned by `www-data`, which is the user that runs the Nextcloud service in the container.

        - `volumeMounts` section: mounts the certificate and the two Apache configuration files, and also the two storage volumes needed by this Nextcloud setup.
            - `wildcard.deimos.cloud-tls.crt` and `wildcard.deimos.cloud-tls.key`: these two files set up the certificate and all must be in the `/etc/ssl/certs` path, since is the one set in the `000-default.conf` Apache file. These files are found within the `Secret` resource associated to the `wildcard.deimos.cloud-tls` certificate you created in the [G029 guide](G029%20-%20K3s%20cluster%20setup%2012%20~%20Setting%20up%20cert-manager%20and%20wildcard%20certificate.md).
            - `ports.conf` is mounted in the default path expected by Apache, `/etc/apache2/ports.conf`.
            - `000-default.conf` is also put in a default Apache path, `/etc/apache2/sites-available/000-default.conf`.
            - `/var/www/html`: the path where Nextcloud is installed.
            - `/var/www/html/data`: where Nextcloud stores the users' data. This folder must be owned by the `www-data` user that exists within the container.

    - `metrics` container: runs the Prometheus metrics exporter of Nextcloud.
        - The `image` for this Prometheus exporter is set to be always [the latest one available](https://hub.docker.com/r/xperimental/nextcloud-exporter), and probably runs on a Debian system but its not specified.

        - `env` section:
            - `NEXTCLOUD_SERVER`: since this container runs on the same pod as the Nextcloud server, it's set as `localhost`.
            - `NEXTCLOUD_TLS_SKIP_VERIFY`: since the certificate is self-signed and this service is running on the same pod, there's little need of checking the certificate when this service connects to Nextcloud.
            - `NEXTCLOUD_USERNAME` and `NEXTCLOUD_PASSWORD`: here you'll be forced to use the same administrator user you defined for the Nextcloud server, since its the only one you have at this point.

    - `template.spec.volumes`: here you have enabled the two volumes prepared for Nextcloud, but also the configuration files for Apache, and the certificate files available in the `wildcard.deimos.cloud-tls` secret. Notice how the permission mode of these files are handled with the `defaultMode` parameter.

## Nextcloud server Service resource

Your Nextcloud server requires a Service resource named `server-apache-nextcloud` to offer its functionality.

1. Create a `server-apache-nextcloud.service.yaml` file under `resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.service.yaml
    ~~~

2. Copy in `server-apache-nextcloud.service.yaml` the `Service` declaration next.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9205"
      name: server-apache-nextcloud
    spec:
      type: LoadBalancer
      clusterIP: 10.43.100.3
      loadBalancerIP: 192.168.1.42
      ports:
      - port: 443
        protocol: TCP
        name: apache
      - port: 9205
        protocol: TCP
        name: metrics
    ~~~

    This `Service` resource is mostly like the others you've seen before, but with the following differences.

    - This Service's `type` is `LoadBalancer`, meaning that it'll take the next available IP from the MetalLB pool to use as external public IP in your network. But you can also set manually an IP, picked from the ones available in the load balancer's pool, with the `loadBalancerIP` parameter set below.

    - A `LoadBalancer` type service can also have an internal `clusterIP`, and you can see how I've chosen to set it with an IP that follows the ones assigned to the Redis and MariaDB services. You could leave this value unassigned and allow Kubernetes to give it any internal cluster IP, but consider that having a known static IP can be an advantage on certain situations.

    - With the `loadBalancerIP` parameter you can tell a `LoadBalancer` type service what IP you want it to get from your cluster's load balancer (MetalLB in this case). In the yaml above, `192.168.1.42` is right the next one after the IP already assigned to the Traefik service (`192.168.1.41`). By setting this manually, you ensure that the service has the same IP as the one specified in the `nextcloud-trusted-domains` parameter declared in the `params.properties` file.

## Nextcloud server Kustomize project

With all the necessary elements for your Nextcloud server component declared in their respective files, you can put them together as a Kustomize project.

1. Create a `kustomization.yaml` file in the `server-nextcloud` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/nextcloud/components/server-nextcloud/kustomization.yaml
    ~~~

2. Fill `kustomization.yaml` with the following yaml.

    ~~~yaml
    # Nextcloud server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-nextcloud

    resources:
   - resources/data-server-nextcloud.persistentvolumeclaim.yaml
   - resources/html-server-nextcloud.persistentvolumeclaim.yaml
   - resources/server-apache-nextcloud.service.yaml
   - resources/server-apache-nextcloud.statefulset.yaml

    replicas:
    - name: server-apache-nextcloud
      count: 1

    images:
    - name: nextcloud
      newTag: 22.2-apache
    - name: xperimental/nextcloud-exporter
      newTag: 0.4.0-15-gbb88fb6

    configMapGenerator:
    - name: server-apache-nextcloud
      envs:
      - configs/params.properties
      files:
      - configs/000-default.conf
      - configs/ports.conf

    secretGenerator:
    - name: server-nextcloud
      files:
      - nextcloud-admin-password=secrets/nextcloud-admin.pwd
    ~~~

    This `kustomization.yaml`, compared to the ones you've already set up for the Redis and MariaDB cases, doesn't have anything in particular to highlight. All the parameters specified there should be familiar to you at this point.

### _Validating the Kustomize yaml output_

As with the other components, you should check the output generated by this Kustomize project.

1. Generate the yaml with `kubectl kustomize` as usual.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/server-nextcloud | less
    ~~~

2. See if your yaml output looks like the one below.

    ~~~yaml
    apiVersion: v1
    data:
      000-default.conf: |
        MinSpareServers 4
        MaxSpareServers 16
        StartServers 10
        MaxConnectionsPerChild 2048

        LoadModule socache_shmcb_module /usr/lib/apache2/modules/mod_socache_shmcb.so
        SSLSessionCache shmcb:/var/tmp/apache_ssl_scache(512000)

        <VirtualHost *:443>
          Protocols http/1.1
          ServerAdmin root@deimos.cloud
          ServerName nextcloud.deimos.cloud
          ServerAlias nxc.deimos.cloud

          Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"

          DocumentRoot /var/www/html
          DirectoryIndex index.php

          LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so
          SSLEngine on
          SSLCertificateFile /etc/ssl/certs/wildcard.deimos.cloud-tls.crt
          SSLCertificateKeyFile /etc/ssl/certs/wildcard.deimos.cloud-tls.key

          <Directory /var/www/html/>
            Options FollowSymlinks MultiViews
            AllowOverride All
            Require all granted

            <IfModule mod_dav.c>
              Dav off
            </IfModule>

            SetEnv HOME /var/www/html
            SetEnv HTTP_HOME /var/www/html
            Satisfy Any

          </Directory>

          ErrorLog ${APACHE_LOG_DIR}/error.log
          CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>
      cache-redis-svc-cluster-ip: 10.43.100.1
      db-mariadb-svc-cluster-ip: 10.43.100.2
      nextcloud-admin-username: admin
      nextcloud-trusted-domains: 192.168.1.42 nextcloud.deimos.cloud nxc.deimos.cloud
      ports.conf: |
        Listen 443

        # vim: syntax=apache ts=4 sw=4 sts=4 sr noet
    kind: ConfigMap
    metadata:
      labels:
        app: server-nextcloud
      name: server-apache-nextcloud-fcckh8bk2d
    ---
    apiVersion: v1
    data:
      nextcloud-admin-password: |
        OXE0OHVvbmJvaXU0ODkwdW9paG5nw6x1eTM0ODkwOTIzdWttbmFwamTEusOxamdwYmFpdTM5MHVp
        b3UzOTAzMnVpMDl1bmdhb3BpamRkYcOxejM5a2zDkXFla2oK
    kind: Secret
    metadata:
      labels:
        app: server-nextcloud
      name: server-nextcloud-mmd5t7577c
    type: Opaque
    ---
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        prometheus.io/port: "9205"
        prometheus.io/scrape: "true"
      labels:
        app: server-nextcloud
      name: server-apache-nextcloud
    spec:
      clusterIP: 10.43.100.3
      loadBalancerIP: 192.168.1.42
      ports:
      - name: server
        port: 443
        protocol: TCP
      - name: metrics
        port: 9205
        protocol: TCP
      selector:
        app: server-nextcloud
      type: LoadBalancer
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-nextcloud
      name: data-server-nextcloud
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 9.3G
      storageClassName: local-path
      volumeName: data-nextcloud
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      labels:
        app: server-nextcloud
      name: html-server-nextcloud
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1.2G
      storageClassName: local-path
      volumeName: html-nextcloud
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      labels:
        app: server-nextcloud
      name: server-apache-nextcloud
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: server-nextcloud
      serviceName: server-apache-nextcloud
      template:
        metadata:
          labels:
            app: server-nextcloud
        spec:
          containers:
          - env:
            - name: NEXTCLOUD_ADMIN_USER
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-admin-username
                  name: server-apache-nextcloud-fcckh8bk2d
            - name: NEXTCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: nextcloud-admin-password
                  name: server-nextcloud-mmd5t7577c
            - name: NEXTCLOUD_TRUSTED_DOMAINS
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-trusted-domains
                  name: server-apache-nextcloud-fcckh8bk2d
            - name: MYSQL_HOST
              valueFrom:
                configMapKeyRef:
                  key: db-mariadb-svc-cluster-ip
                  name: server-apache-nextcloud-fcckh8bk2d
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-db-name
                  name: db-mariadb
            - name: MYSQL_USER
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-username
                  name: db-mariadb
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: nextcloud-user-password
                  name: db-mariadb
            - name: REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  key: cache-redis-svc-cluster-ip
                  name: server-apache-nextcloud-fcckh8bk2d
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: redis-password
                  name: cache-redis
            - name: APACHE_ULIMIT_MAX_FILES
              value: ulimit -n 65536
            image: nextcloud:22.2-apache
            lifecycle:
              postStart:
                exec:
                  command:
                  - sh
                  - -c
                  - |
                    chown www-data:www-data /var/www/html/data
            name: server
            ports:
            - containerPort: 443
            resources:
              limits:
                memory: 512Mi
            volumeMounts:
            - mountPath: /etc/ssl/certs/wildcard.deimos.cloud-tls.crt
              name: certificate
              subPath: wildcard.deimos.cloud-tls.crt
            - mountPath: /etc/ssl/certs/wildcard.deimos.cloud-tls.key
              name: certificate
              subPath: wildcard.deimos.cloud-tls.key
            - mountPath: /etc/apache2/ports.conf
              name: apache-config
              subPath: ports.conf
            - mountPath: /etc/apache2/sites-available/000-default.conf
              name: apache-config
              subPath: 000-default.conf
            - mountPath: /var/www/html
              name: html-storage
            - mountPath: /var/www/html/data
              name: data-storage
          - env:
            - name: NEXTCLOUD_SERVER
              value: https://localhost
            - name: NEXTCLOUD_TLS_SKIP_VERIFY
              value: "true"
            - name: NEXTCLOUD_USERNAME
              valueFrom:
                configMapKeyRef:
                  key: nextcloud-admin-username
                  name: server-apache-nextcloud-fcckh8bk2d
            - name: NEXTCLOUD_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: nextcloud-admin-password
                  name: server-nextcloud-mmd5t7577c
            image: xperimental/nextcloud-exporter:0.4.0-15-gbb88fb6
            name: metrics
            ports:
            - containerPort: 9205
            resources:
              limits:
                memory: 32Mi
          volumes:
          - configMap:
              defaultMode: 420
              items:
              - key: ports.conf
                path: ports.conf
              - key: 000-default.conf
                path: 000-default.conf
              name: server-apache-nextcloud-fcckh8bk2d
            name: apache-config
          - name: certificate
            secret:
              defaultMode: 292
              items:
              - key: tls.crt
                path: wildcard.deimos.cloud-tls.crt
              - key: tls.key
                path: wildcard.deimos.cloud-tls.key
              secretName: wildcard.deimos.cloud-tls
          - name: html-storage
            persistentVolumeClaim:
              claimName: html-server-nextcloud
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-nextcloud
    ~~~

    There's one particular but important thing you must notice in this yaml:

    - As expected, the `ConfigMap` and `Secret` resources you've defined in this Kustomize project have their names appended with a hash suffix.

    - On the other hand, the names of the config map `db-mariadb` and the secrets `db-mariadb` and `cache-redis` remain unchanged, because they haven't been defined in this particular Kustomize project, they're external resources just being referenced here. But don't worry, this is also expected and that will be fixed in the final part of this guide.

    - Remember that Kustomize transforms the values you put at the `defaultMode` parameters set for the files you configure as `volumes`. You already saw this happening while preparing the Redis Kustomize project.

## Don't deploy this Nextcloud server project on its own

This Nextcloud server cannot be deployed on its own because is missing several things.

- The two persistent volumes it needs to store it's server files and users data.

- It won't find the external resources it needs to run, like the config maps or secrets of the other components. Their names won't match with the ones this Kustomize project has, and also the certificate's secret isn't replicated in the right namespace.

So, again I must tell you to wait to the upcoming final part of this Nextcloud guide, where you'll add the missing parts, tie everything together and deploy the whole setup in one go.

## Background jobs on Nextcloud

There's a particular thing that I've left out of this guide, and is the configuration of a cronjob for the background tasks Nextcloud requires to do regularly. The problem is that I haven't found a proper or convincing setup to apply in this guide, so I'll leave you here a bunch of references about this matter.

- First, check the official documentation about the [Nextcloud's background jobs configuration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/background_jobs_configuration.html).

- By default, Nextcloud uses a method that relies on user interaction with the platform to launch background jobs. This method is referred to as [the AJAX method in the official documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/background_jobs_configuration.html#ajax) and, officially at least, is not considered a reliable way of launching the required background tasks.

- There's a Docker image that you could use as an extra sidecarized container in the Nextcloud pod setup of this guide. This image is offered as the [Nextcloud Cron Job Docker Container](https://hub.docker.com/r/rcdailey/nextcloud-cronjob).

- Be aware that there's a type of resource in Kubernetes particularly designed to run automated tasks periodically: [the CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/).

- In [this thread on the official Nextcloud's help forum](https://help.nextcloud.com/t/verifying-where-to-add-cron-jobs-docker-compose-cron/104110) and in [this issue thread on Nextcloud's GitHub site](https://github.com/nextcloud/helm/issues/55) you'll see some interesting comments about Nextcloud's cronjob.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/server-nextcloud`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/secrets`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/kustomization.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/000-default.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/params.properties`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/ports.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/data-server-nextcloud.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/html-server-nextcloud.persistentvolumeclaim.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.service.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.statefulset.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/secrets/nextcloud-admin.pwd`

## References

### _Kubernetes_

#### **ConfigMaps and secrets**

- [Official Doc - ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Official Doc - Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [An Introduction to Kubernetes Secrets and ConfigMaps](https://opensource.com/article/19/6/introduction-kubernetes-secrets-and-configmaps)
- [Kubernetes - Using ConfigMap SubPaths to Mount Files](https://dev.to/joshduffney/kubernetes-using-configmap-subpaths-to-mount-files-3a1i)
- [Kubernetes Secrets | Declare confidential data with examples](https://www.golinuxcloud.com/kubernetes-secrets/)
- [Kubernetes ConfigMaps and Secrets](https://shravan-kuchkula.github.io/kubernetes/configmaps-secrets/)
- [Import data to config map from kubernetes secret](https://stackoverflow.com/questions/50452665/import-data-to-config-map-from-kubernetes-secret)

#### **Storage**

- [Official Doc - Local Storage Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#local)
- [Official Doc - Local Persistent Volumes for Kubernetes Goes Beta](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/)
- [Official Doc - Reserving a PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume)
- [Official Doc - Local StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)
- [Official Doc - Reclaiming Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)
- [Kubernetes API - PersistentVolume](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
- [Kubernetes API - PersistentVolumeClaim](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-claim-v1/)
- [Kubernetes Persistent Volumes, Claims, Storage Classes, and More](https://cloud.netapp.com/blog/kubernetes-persistent-storage-why-where-and-how)
- [Rancher K3s - Setting up the Local Storage Provider](https://rancher.com/docs/k3s/latest/en/storage/)
- [K3s local path provisioner on GitHub](https://github.com/rancher/local-path-provisioner)
- [Using "local-path" in persistent volume requires sudo to edit files on host node?](https://github.com/k3s-io/k3s/issues/1823)
- [Kubernetes size definitions: What's the difference of "Gi" and "G"?](https://stackoverflow.com/questions/50804915/kubernetes-size-definitions-whats-the-difference-of-gi-and-g)
- [distinguish unset and empty values for storageClassName](https://github.com/helm/helm/issues/2600)
- [Kubernetes Mounting Volumes in Pods. Mount Path Ownership and Permissions](https://kb.novaordis.com/index.php/Kubernetes_Mounting_Volumes_in_Pods#Mount_Path_Ownership_and_Permissions)

#### **StatefulSets**

- [Official Doc](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

#### **Environment variables**

- [Official Doc - Define Environment Variables for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [Official Doc - Define Dependent Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/)

#### **Executing multiple commands in lifecycle (postStart/preStop) of containers**

- [Kubernetes - Passing multiple commands to the container](https://stackoverflow.com/questions/33979501/kubernetes-passing-multiple-commands-to-the-container)
- [multiple command in postStart hook of a container](https://stackoverflow.com/questions/39436845/multiple-command-in-poststart-hook-of-a-container)

#### _Cronjob_

- [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)
- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

### _Nextcloud_

- [Official Docker build of Nextcloud](https://hub.docker.com/_/nextcloud)
- [Official Docker build of Nextcloud on GitHub](https://github.com/nextcloud/docker)
- [Prometheus exporter for getting some metrics of a Nextcloud server instance](https://hub.docker.com/r/xperimental/nextcloud-exporter)
- [Installation and server configuration](https://docs.nextcloud.com/server/stable/admin_manual/installation/index.html)
- [Installation on Linux](https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html#installation-on-linux)
- [Nextcloud on Kubernetes, by modzilla99](https://github.com/modzilla99/kubernetes-nextcloud)
- [Nextcloud on Kubernetes, by andremotz](https://github.com/andremotz/nextcloud-kubernetes)
- [Deploy Nextcloud - Yaml with application and database container and a configure a secret](https://www.debontonline.com/2021/05/part-15-deploy-nextcloud-yaml-with.html)
- [Self-Host Nextcloud Using Kubernetes](https://blog.true-kubernetes.com/self-host-nextcloud-using-kubernetes/)
- [Deploying NextCloud on Kubernetes with Kustomize](https://medium.com/@acheaito/nextcloud-on-kubernetes-19658785b565)
- [A NextCloud Kubernetes deployment](https://github.com/acheaito/nextcloud-kubernetes)
- [Nextcloud self-hosting on K8s](https://eramons.github.io/techblog/post/nextcloud/)
- [Nextcloud self-hosting on K8s on GitHub](https://github.com/eramons/kubenextcloud)
- [Installing Nextcloud on Ubuntu with Redis, APCu, SSL & Apache](https://bayton.org/docs/nextcloud/installing-nextcloud-on-ubuntu-16-04-lts-with-redis-apcu-ssl-apache/)
- [Setup NextCloud Server with Nginx SSL Reverse-Proxy and Apache2 Backend](https://breuer.dev/tutorial/Setup-NextCloud-FrontEnd-Nginx-SSL-Backend-Apache2)
- [Install Nextcloud with Apache2 on Debian 10](https://vectops.com/2021/01/install-nextcloud-with-apache2-on-debian-10/)
- [Nextcloud scale-out using Kubernetes](https://faun.pub/nextcloud-scale-out-using-kubernetes-93c9cac9e493)
- [How to tune Nextcloud on-premise cloud server for better performance](https://www.techrepublic.com/article/how-to-tune-nextcloud-on-premise-cloud-server-for-better-performance/)
- [Nextcloud's background jobs configuration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/background_jobs_configuration.html)
- [Nextcloud Cron Job Docker Container](https://hub.docker.com/r/rcdailey/nextcloud-cronjob)
- [Verifying where to add cron jobs docker-compose + cron](https://help.nextcloud.com/t/verifying-where-to-add-cron-jobs-docker-compose-cron/104110)
- [System cron instead of webcron?](https://github.com/nextcloud/helm/issues/55)

### _Apache httpd_

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)
- [Apache MPM prefork](https://httpd.apache.org/docs/2.4/mod/prefork.html)
- [Apache Module mod_ssl](http://httpd.apache.org/docs/current/mod/mod_ssl.html)
- [Kubernetes: Cannot deploy flask web app with apache and https](https://stackoverflow.com/questions/38043415/kubernetes-cannot-deploy-flask-web-app-with-apache-and-https)
- [SSLSessionCache](https://cwiki.apache.org/confluence/display/httpd/SSLSessionCache)
- [XAMPP - Session Cache is not configured [hint: SSLSessionCache]](https://stackoverflow.com/questions/16644064/xampp-session-cache-is-not-configured-hint-sslsessioncache)
- [SSLSessionCache: ‘shmcb’ session cache not supported](https://bobcares.com/blog/sslsessioncache-shmcb-session-cache-not-supported/)

## Navigation

[<< Previous (**G033. Deploying services 02. Nextcloud Part 3**)](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%203%20-%20MariaDB%20database%20server.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G033. Deploying services 02. Nextcloud Part 5**) >>](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%205%20-%20Complete%20Nextcloud%20platform.md)
