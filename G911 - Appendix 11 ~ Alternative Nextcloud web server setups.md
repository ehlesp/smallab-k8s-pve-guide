# G911 - Appendix 11 ~ Alternative Nextcloud web server setups

In the [Part 4 of the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md) you saw how to configure Nextcloud with the Apache web server, but you can also use Nginx. In this appendix guide you'll see what configuration to apply to use Nginx, but also a couple of ideas that you can apply to your Apache setup.

## Ideas for the Apache setup

### _Enabling a Traefik IngressRoute_

The Nextcloud server you configured in the guide is directly reachable through an IP assigned by the MetalLB load balancer of your cluster. Instead of this, you could enable an ingress route through the Traefik service.

1. Go to the Kustomize subproject's folder of your Nextcloud server.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud
    ~~~

2. Make a renamed copy of the `000-default.conf` file.

    ~~~bash
    $ cp configs/000-default.conf configs/000-default.no-ssl.conf
    ~~~

    Notice that the copy has a `.no-ssl` suffix.

3. Edit the `000-default.no-ssl.conf`, and just remove the lines related to SSL directives from it.

    ~~~apache
    MinSpareServers 4
    MaxSpareServers 16
    StartServers 10
    MaxConnectionsPerChild 2048

    <VirtualHost *:443>
      Protocols http/1.1
      ServerAdmin root@deimos.cloud
      ServerName nextcloud.deimos.cloud
      ServerAlias nxc.deimos.cloud

      Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"

      DocumentRoot /var/www/html
      DirectoryIndex index.php

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

4. Make a renamed copy of the `server-apache-nextcloud.statefulset.yaml` file.

    ~~~bash
    $ cp resources/server-apache-nextcloud.statefulset.yaml resources/server-apache-nextcloud.statefulset.no-ssl.yaml
    ~~~

5. Edit the new `server-apache-nextcloud.statefulset.no-ssl.yaml` file to remove all the references to the wildcard certificate files. The yaml should end looking like below.

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
          - name: html-storage
            persistentVolumeClaim:
              claimName: html-server-nextcloud
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-nextcloud
    ~~~

    You just have to remove the `wildcard.deimos.cloud-tls` references from the `volumeMounts` list in the `server` container declaration, and also the `certificate` block in the `volumes` list at the end of the yaml.

6. Make a renamed copy of the `server-apache-nextcloud.service.yaml`.

    ~~~bash
    $ cp resources/server-apache-nextcloud.service.yaml resources/server-apache-nextcloud.service.clusterip.yaml
    ~~~

    See the `.clusterip` suffix added to the copy's filename.

7. Edit the `server-apache-nextcloud.service.clusterip.yaml` so the `Service` resource declared inside is set as of the `ClusterIP` kind.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9205"
      name: server-apache-nextcloud
    spec:
      type: ClusterIP
      clusterIP: 10.43.100.3
      ports:
      - port: 443
        protocol: TCP
        name: server
      - port: 9205
        protocol: TCP
        name: metrics
    ~~~

8. Create a new `server-apache-nextcloud.ingressroute.traefik.yaml` file under the `resources` folder for a new Traefik `IngressRoute`.

    ~~~bash
    $ touch resources/server-apache-nextcloud.ingressroute.traefik.yaml
    ~~~

9. Put the following yaml in `server-apache-nextcloud.ingressroute.traefik.yaml`.

    ~~~yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute

    metadata:
      name: server-apache-nextcloud
    spec:
      entryPoints:
        - websecure
      tls:
        secretName: wildcard.deimos.cloud-tls
      routes:
      - match: Host(`nextcloud.deimos.cloud`) || Host(`nxc.deimos.cloud`)
        kind: Rule
        services:
        - name: server-apache-nextcloud
          kind: Service
          port: 443
    ~~~

    This yaml might look familiar to you, since it's very similar to the one you created for accessing the Traefik Dashboard, back in the [**G031** guide](G031%20-%20K3s%20cluster%20setup%2014%20~%20Enabling%20the%20Traefik%20dashboard.md#enabling-the-ingressroute).

    - This `IngressRoute` references the secret of your wildcard certificate, encrypting the traffic with the referenced `server-apache-nextcloud` service.

    - Remember that you'll need to enable in your network the domains you specify in the `IngressRoute`, although remembering that they'll have to point to the Traefik service's IP.

10. Now make a backup of the `kustomization.yaml` file of this subproject.

    ~~~yaml
    $ cp kustomization.yaml kustomization.yaml.bkp
    ~~~

11. Edit the `kustomization.yaml` file so it looks as follows.

    ~~~yaml
    # Nextcloud server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-nextcloud

    resources:
    - resources/data-server-nextcloud.persistentvolumeclaim.yaml
    - resources/html-server-nextcloud.persistentvolumeclaim.yaml
    - resources/server-apache-nextcloud.ingressroute.traefik.yaml
    - resources/server-apache-nextcloud.service.clusterip.yaml
    - resources/server-apache-nextcloud.statefulset.no-ssl.yaml

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
      - 000-default.conf=configs/000-default.no-ssl.conf
      - configs/ports.conf

    secretGenerator:
    - name: server-nextcloud
      files:
      - nextcloud-admin-password=secrets/nextcloud-admin.pwd
    ~~~

    The changes are the three new files at the `resources` list (`server-apache-nextcloud.ingressroute.traefik.yaml`, `server-apache-nextcloud.service.clusterip.yaml`, `server-apache-nextcloud.statefulset.no-ssl.yaml`) and the modified `000-default.no-ssl.conf` file at the `configMapGenerator` block.

12. The next thing for you to do would be validating the Kustomize subproject's output, then also validating the output for the main Kustomize project of the Nextcloud platform and, finally, reapplying the main project. I'll just note down the related `kubectl` commands below for your reference.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/server-nextcloud | less
    $ kubectl kustomize $HOME/k8sprjs/nextcloud | less
    $ kubectl apply -k $HOME/k8sprjs/nextcloud
    ~~~

### _About the HTTP/2 protocol on Apache_

The HTTP/2 protocol is a new version of HTTP that provides new features which increases the performance of HTTP traffic. Apache has its own module identified as `http2_module` which provides the HTTP/2 functionality, but it's incompatible with the default MPM **prefork** module (named `mpm_prefork_module`) that comes enabled in the Nextcloud default Apache image. The `http2_module` requires using one of other the Apache MPM modules that make use of threaded server processes, or _workers_, because the HTTP/2 module needs to launch its own threads for serving the requests it receives.

I haven't tested this myself, but I can give you a hint about how to enable HTTP/2 in Apache.

1. The first thing to attend to is switching the MPM prefork module to either the **worker** or the **event** module.
    - One way would be by manipulating the declaration of the container executing the Nextcloud Apache image. Adding a `lifecycle.postStart` section to the container, as you saw already in the [Part 4 of the Nextcloud guide](G033%20-%20Deploying%20services%2002%20~%20Nextcloud%20-%20Part%204%20-%20Nextcloud%20server.md), and in it put a command line like the following.

        ~~~bash
        a2dismod mpm_prefork; a2enmod mpm_worker http2; apachectl restart
        ~~~

        The `lifecycle.postStart` portion of the container declaration could look like below.

        ~~~yaml
        lifecycle:
          postStart:
            exec:
              command:
              - "sh"
              - "-c"
              - |
                chown www-data:www-data /var/www/html/data;
                a2dismod mpm_prefork;
                a2enmod mpm_worker http2;
                apachectl restart
        ~~~

        I've based this yaml portion on the container declaration for the Nextcloud server used in the Nextcloud platform guide. This is why you see the `chown` command too.

    - If you have experience building your own Docker images, another procedure would be creating your own version of the Nextcloud Apache image in which you configure the modules as needed to support HTTP/2.

2. After ensuring that the right modules are loaded, then you need to adjust the configuration at the `000-default.conf` file. Essentially, you have to replace the directives used with the MPM prefork module with the ones of the worker or event modules and add the HTTP/2 protocol. Next I leave an example of how `000-default.conf` would look after the change.

    ~~~apache
    ServerLimit          4
    StartServers         2
    MaxRequestWorkers   30
    MinSpareThreads     10
    MaxSpareThreads     30
    ThreadsPerChild     10
    ThreadLimit         20
    MaxConnectionsPerChild 0

    H2MinWorkers         5
    H2MaxWorkers        10

    LoadModule socache_shmcb_module /usr/lib/apache2/modules/mod_socache_shmcb.so
    SSLSessionCache shmcb:/var/tmp/apache_ssl_scache(512000)

    <VirtualHost *:443>
      Protocols h2 http/1.1
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

    Notice all the directives at the top of the file, starting with `ServerLimit` up to `MaxConnectionsPerChild`. Those are all MPM worker module parameters, which are also used in the MPM event module, while the `H2MinWorkers` and `H2MaxWorkers` below them are just a couple of all the ones available at the HTTP/2 module. The HTTP/2 protocol itself is enabled at the `Protocols` directive with the `h2` value.

3. Since there are no new files or resources used in this modification, the Kustomize project wouldn't change at all and you could just validate and apply it as you did in the Nextcloud platform's guide.

## Nginx setup

You've already seen how to deploy Nextcloud with its default Apache image, but you can also make this PHP-based platform be rendered by a Nginx web server. The thing is that there's no Nextcloud image with Nginx integrated, just images with no web server included whatsoever but with an alternative PHP FastCGI process manager called FPM. FPM can improve the performance of any PHP-based website, specially the ones under heavy traffic, but it needs a web server to proxy the requests towards it. So, to run properly the Nextcloud server with FPM you'll need an extra container for Nginx, making the setup use a total of three containers:

- One container executing the FPM image of Nextcloud.
- One container to run the Nginx server acting as reverse proxy for the Nextcloud PHP-FPM instance.
- One container running the Prometheus metrics exporter for Nextcloud.

Next, I'll show you what to add or change in the Nextcloud server's Kustomize subproject (`$HOME/k8sprjs/nextcloud/components/server-nextcloud`) for turning it into a Nextcloud server running on FPM and Nginx.

> **BEWARE!**  
> The following Nginx configurations are **not** compatible with the Apache one. So, if you already had the Apache configurations running, first you'll need to undeploy (`kubectl delete`) the whole Nextcloud platform and clean up the storage volumes (remove and then recreate the `k3smnt` folders) used in the agent node.

### _LoadBalancer configuration_

The Nexcloud server setup you'll see here will have its own IP through the MetalLB load balancer.

#### **Configuration files**

1. You'll need to create three new configuration files in the `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs` folder.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud/configs
    $ touch dhparam.pem nginx.conf zz-docker.conf
    ~~~

2. Copy in `dhparam.pem` the following content.

    ~~~txt
    -----BEGIN DH PARAMETERS-----
    MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
    +8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
    87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
    YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
    7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
    ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
    -----END DH PARAMETERS-----
    ~~~

    This file is for SSL/TLS configuration on the Nginx server. Its content sets the Diffie-Hellman parameter (hence why the file is named `dhparam`) to ensure that at least 2048 bits are used in SSL communications. Any less is considered insecure. This file's content has been taken as-is [from this Mozilla-related URL](https://ssl-config.mozilla.org/ffdhe2048.txt).

3. In `nginx.conf`, copy all the configuration below.

    ~~~nginx
    worker_processes auto;

    error_log  /dev/stdout debug;
    pid        /var/run/nginx.pid;

    events {
        worker_connections  8;
    }

    http {
        include   /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format   main '$remote_addr - $remote_user [$time_local]  $status '
                          '"$request" $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log /dev/stdout main; 

        # Disabled because this nginx is acting
        # as a reverse proxy for an application server.
        sendfile        off;

        upstream php-handler {
            server 127.0.0.1:9000;
        }

        server {
            listen 443 ssl http2;
            server_name nextcloud.deimos.cloud nxc.deimos.cloud;

            # You can use Mozilla's SSL Configuration Generator
            # for defining your SSL/TLS settings.
            # https://ssl-config.mozilla.org/
            ssl_certificate /etc/nginx/cert/wildcard.deimos.cloud-tls.crt;
            ssl_certificate_key /etc/nginx/cert/wildcard.deimos.cloud-tls.key;

            ssl_session_timeout 1d;
            ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
            ssl_session_tickets off;

            # SSL/TLS intermediate configuration
            ssl_protocols TLSv1.2 TLSv1.3;
            ssl_dhparam /etc/ssl/dhparam.pem;
            ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
            ssl_prefer_server_ciphers off;

            # HSTS settings
            # WARNING: Only add the preload option once you read about
            # the consequences in https://hstspreload.org/. This option
            # will add the domain to a hardcoded list that is shipped
            # in all major browsers and getting removed from this list
            # could take several months.
            #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

            # set max upload size
            client_max_body_size 10240M;
            fastcgi_buffers 64 4K;

            # Enable gzip but do not remove ETag headers
            gzip on;
            gzip_vary on;
            gzip_comp_level 4;
            gzip_min_length 256;
            gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
            gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

            # Pagespeed is not supported by Nextcloud, so if your server is built
            # with the `ngx_pagespeed` module, uncomment this line to disable it.
            #pagespeed off;

            # HTTP response headers borrowed from Nextcloud `.htaccess`
            add_header Referrer-Policy                      "no-referrer"   always;
            add_header X-Content-Type-Options               "nosniff"       always;
            add_header X-Download-Options                   "noopen"        always;
            add_header X-Frame-Options                      "SAMEORIGIN"    always;
            add_header X-Permitted-Cross-Domain-Policies    "none"          always;
            add_header X-Robots-Tag                         "none"          always;
            add_header X-XSS-Protection                     "1; mode=block" always;

            # Remove X-Powered-By, which is an information leak
            fastcgi_hide_header X-Powered-By;

            # Path to the root of your installation
            root /var/www/html;

            # Specify how to handle directories -- specifying `/index.php$request_uri`
            # here as the fallback means that Nginx always exhibits the desired behaviour
            # when a client requests a path that corresponds to a directory that exists
            # on the server. In particular, if that directory contains an index.php file,
            # that file is correctly served; if it doesn't, then the request is passed to
            # the front-end controller. This consistent behaviour means that we don't need
            # to specify custom rules for certain paths (e.g. images and other assets,
            # `/updater`, `/ocm-provider`, `/ocs-provider`), and thus
            # `try_files $uri $uri/ /index.php$request_uri`
            # always provides the desired behaviour.
            index index.php index.html /index.php$request_uri;

            # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
            location = / {
                if ( $http_user_agent ~ ^DavClnt ) {
                    return 302 /remote.php/webdav/$is_args$args;
                }
            }

            location = /robots.txt {
                allow all;
                log_not_found off;
                access_log off;
            }

            # Make a regex exception for `/.well-known` so that clients can still
            # access it despite the existence of the regex rule
            # `location ~ /(\.|autotest|...)` which would otherwise handle requests
            # for `/.well-known`.
            location ^~ /.well-known {
                # The rules in this block are an adaptation of the rules
                # in `.htaccess` that concern `/.well-known`.

                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }

                location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
                location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

                # Let Nextcloud's API for `/.well-known` URIs handle all other
                # requests by passing them to the front-end controller.
                return 301 /index.php$request_uri;
            }

            # Rules borrowed from `.htaccess` to hide certain paths from clients
            location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
            location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

            # Ensure this block, which passes PHP files to the PHP process, is above the blocks
            # which handle static assets (as seen below). If this block is not declared first,
            # then Nginx will encounter an infinite rewriting loop when it prepends `/index.php`
            # to the URI, resulting in a HTTP 500 error response.
            location ~ \.php(?:$|/) {
                # Required for legacy support
                rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;

                # regex to split $uri to $fastcgi_script_name and $fastcgi_path_info
                fastcgi_split_path_info ^(.+?\.php)(/.*)$;

                # Check that the PHP script exists before passing it
                if (!-f $document_root$fastcgi_script_name) {
                    return 404;
                }

                # Mitigate https://httpoxy.org/ vulnerabilities
                fastcgi_param HTTP_PROXY "";

                # pass the request to the PHP handler
                fastcgi_pass php-handler;

                fastcgi_index index.php;

                # Bypass the fact that try_files resets $fastcgi_path_info
                # see: http://trac.nginx.org/nginx/ticket/321
                set $path_info $fastcgi_path_info;
                fastcgi_param PATH_INFO $path_info;

                # Avoid sending the security headers twice
                fastcgi_param modHeadersAvailable true;
                # Enable pretty urls
                fastcgi_param front_controller_active true;

                # set the standard fcgi paramters
                include fastcgi.conf;

                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
            }

            location ~ \.(?:css|js|svg|gif)$ {
                try_files $uri /index.php$request_uri;
                expires 6M;         # Cache-Control policy borrowed from `.htaccess`
                access_log off;     # Optional: Don't log access to assets
            }

            location ~ \.woff2?$ {
                try_files $uri /index.php$request_uri;
                expires 7d;         # Cache-Control policy borrowed from `.htaccess`
                access_log off;     # Optional: Don't log access to assets
            }

            # Rule borrowed from `.htaccess`
            location /remote {
                return 301 /remote.php$request_uri;
            }

            location / {
                try_files $uri $uri/ /index.php$request_uri;
            }
        }
    }
    ~~~

    This is the configuration file for the Nginx server, based mostly on the one found [in the Nexcloud documentation](https://docs.nextcloud.com/server/stable/admin_manual/installation/nginx.html). To know the meaning of all of its parameters, check its [official documentation](https://nginx.org/en/docs/) and, in particular, the [core functionality section](https://nginx.org/en/docs/ngx_core_module.html). Regardless, notice the following.

    - The `error_log` and the `http.access_log` parameters point to `/dev/stdout`, so those Nginx logs can be seen as logs of the container in which this web server will run.

    - In the `http.server` subsection, the `listen` port is specified as `443` for https connections. Also see that it has the `ssl` and `http2` options enabled, so the SSL communications are active and take advantage of the HTTP/2 protocol.

    - In the `http.server` subsection, notice the paths specified in the `ssl_certificate` and `ssl_certificate_key` parameters. They'll be used later to mount there the corresponding files from the `wildcard.deimos.cloud-tls` secret you enabled earlier in the `nextcloud` namespace.

    - Again in the `http.server` subsection, look for the `root` parameter set there. It has the path, within the Nginx container, to the webroot of your Nextcloud server (`/var/www/html`), where Nextcloud will install all the files it needs to run.

4. Put in `zz-docker.conf` the following parameters.

    ~~~properties
    [global]
    daemonize = no

    [www]
    listen = 9000
    pm = dynamic
    pm.max_children = 16
    pm.start_servers = 10
    pm.min_spare_servers = 4
    pm.max_spare_servers = 16
    pm.max_requests = 512
    ~~~

    This is a configuration file for the PHP-FPM engine running the Nextcloud server. Meant to be used for reconfiguring values of FPM, such as the number of child processes it can run.

    - Based on the one defined in [the Dockerfile for the PHP 8 FPM Alpine image](https://github.com/docker-library/php/blob/master/8.0/alpine3.14/fpm/Dockerfile), found at the Dockerfile's bottom.

    - Notice all the `pm` (process manager) parameters set in the file, they control how the FPM child server processes are spawned and in what number. Set here because the Nextcloud FPM image comes with default values that won't give you the best performance on your setup. You'll have to estimate how many processes you can run in your container, mainly depending on how much RAM it has. To help you calculate the `pm` values, you can use [this FPM process calculator](https://spot13.com/pmcalculator/) or just estimate that each FPM child process can use up to 32 MiB of RAM.

    - You can find the meaning of all the parameters in this [official PHP FPM documentation page](https://www.php.net/manual/en/install.fpm.configuration.php).

#### **Resources**

1. You need to declare a new `Service` and a new `StatefulSet`, so create their respective files under the `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources` path.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources
    $ touch server-nginx-nextcloud.service.loadbalancer.yaml server-nginx-nextcloud.statefulset.yaml
    ~~~

2. In the `server-nginx-nextcloud.service.loadbalancer.yaml` file, copy the `Service` resource declaration next.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9205"
      name: server-nginx-nextcloud
    spec:
      type: LoadBalancer
      clusterIP: 10.43.100.3
      loadBalancerIP: 192.168.1.42
      ports:
      - port: 443
        protocol: TCP
        name: server
      - port: 9205
        protocol: TCP
        name: metrics
    ~~~

    You'll notice that the `Service` declared above is exactly the same as the one you used with the Apache configuration, except only in the `metadata.name` parameter. As you can see, the `Service` only cares about the ports and the protocols used to communicate with the service or app it connects with. In fact, you could have used the very same `Service` resource, although setting it with a bit more generic name such as `server-nextcloud`.

3. At `server-nginx-nextcloud.statefulset.yaml` set the `StatefulSet` resource below.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-nginx-nextcloud
    spec:
      replicas: 1
      serviceName: server-nginx-nextcloud
      template:
        spec:
          containers:
          - name: fpm
            image: nextcloud:22.2-fpm-alpine
            ports:
            - containerPort: 9000
            env:
            - name: NEXTCLOUD_ADMIN_USER
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            - name: NEXTCLOUD_TRUSTED_DOMAINS
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
                  key: nextcloud-trusted-domains
            - name: MYSQL_HOST
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
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
                  name: server-nginx-nextcloud
                  key: cache-redis-svc-cluster-ip
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            lifecycle:
              postStart:
                exec:
                  command: ["chown", "www-data", "/var/www/html/data"]
            resources:
              limits:
                memory: 512Mi
            volumeMounts:
            - name: fpm-config
              subPath: zz-docker.conf
              mountPath: /usr/local/etc/php-fpm.d/zz-docker.conf
            - name: html-storage
              mountPath: /var/www/html
            - name: data-storage
              mountPath: /var/www/html/data
          - name: server
            image: nginx:1.21-alpine
            ports:
            - containerPort: 443
            volumeMounts:
            - name: certificates
              subPath: wildcard.deimos.cloud-tls.crt
              mountPath: /etc/nginx/cert/wildcard.deimos.cloud-tls.crt
            - name: certificates
              subPath: wildcard.deimos.cloud-tls.key
              mountPath: /etc/nginx/cert/wildcard.deimos.cloud-tls.key
            - name: nginx-config
              subPath: dhparam.pem
              mountPath: /etc/ssl/dhparam.pem
            - name: nginx-config
              subPath: nginx.conf
              mountPath: /etc/nginx/nginx.conf
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
                  name: server-nginx-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            resources:
              limits:
                memory: 32Mi
          hostNetwork: true
          volumes:
          - name: nginx-config
            configMap:
              name: server-nginx-nextcloud
              defaultMode: 0444
              items:
              - key: dhparam.pem
                path: dhparam.pem
              - key: nginx.conf
                path: nginx.conf
              - key: zz-docker.conf
                path: zz-docker.conf
          - name: certificates
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

    The `StatefulSet` above might feel similar to the one you used with the Apache setup, but in this case it describes a pod holding three containers instead of two in a sidecar pattern.

    - `fpm` container: executes the Nextcloud server itself.
        - The `image` is an Alpine Linux variant running [the FPM-based stable 22.2 version of Nexcloud](https://hub.docker.com/_/nextcloud).
        - `env` section: notice that some values are taken from the secrets and config maps defined for the Redis and MariaDB pods.
            - `NEXTCLOUD_ADMIN_USER` and `NEXTCLOUD_ADMIN_PASSWORD`: define the administrator user for the Nextcloud server, creating it when the server autoinstalls itself.
            - `NEXTCLOUD_TRUSTED_DOMAINS`: where the list of trusted domains must be set.
            - `MYSQL_HOST` and `MYSQL_DATABASE`: the IP of the MariaDB service and the database instance's name Nextcloud has to use.
            - `MYSQL_USER` and `MYSQL_PASSWORD`: the user Nextcloud has to use to connect to its own database on the MariaDB server.
            - `REDIS_HOST` and `REDIS_HOST_PASSWORD`: the IP to the Redis service and the password require to authenticate in that server.
        - `lifecycle.postStart.exec.command`: this defines a command meant to be executed right after the container has started. In this case, a `chown` is executed because the folder in which Nextcloud has to store the user data happens to be owned by `root` but it needs to be owned by `www-data`, which is the user that runs the Nextcloud service in the container.
        - `volumeMounts` section: mounts a configuration file and two storage volumes.
            - `/usr/local/etc/php-fpm.d/zz-docker.conf`: the path for the extra configuration file for the PHP FPM engine executing Nextcloud.
            - `/var/www/html`: the path where Nextcloud is installed.
            - `/var/www/html/data`: where Nextcloud stores the user data. This folder must be owned by the `www-data` user that exists within the container.

    - `server` container: runs the Nginx server.
        - The `image` is an Alpine Linux variant running [the latest 1.21 version of Nginx](https://hub.docker.com/_/nginx).
        - `volumeMounts` section: it has several files mounted and also the same volumes used in the Nextcloud FPM container.
            - `wildcard.deimos.cloud-tls.crt` and `wildcard.deimos.cloud-tls.key`: the files that make up the certificate and both must be in the `/etc/nginx/cert` path, since is the one set in the `nginx.conf` file for them.
            - `/etc/ssl/dhparam.pem`: the file with parameters for SSL encryption.
            - `/etc/nginx/nginx.conf`: path for the Nginx configuration file, defined in the config map at the top of this yaml manifest.
            - `/var/www/html` and `/var/www/html/data`: they're the same folders used by Nextcloud. Nginx need to access them to serve their content to clients.

    - `metrics` container: runs the Prometheus metrics exporter of Nextcloud.
        - The `image` for this Prometheus exporter is set to be [the latest one available](https://hub.docker.com/r/xperimental/nextcloud-exporter), and probably runs on a Debian system but its not specified.
        - `env` section:
            - `NEXTCLOUD_SERVER`: since this container runs on the same pod as the Nextcloud server, it's set as `localhost`.
            - `NEXTCLOUD_TLS_SKIP_VERIFY`: since the certificate is self-signed and this service is running on the same pod, there's little need of checking the certificate when this service connects to Nextcloud.
            - `NEXTCLOUD_USERNAME` and `NEXTCLOUD_PASSWORD`: here you'll be forced to use the same administrator user you defined for the Nextcloud server, since its the only one you have at this point.

    - `template.spec.volumes`: here you have enabled the two volumes prepared for Nextcloud, but also the configuration files for FPM and Nginx, and the certificate files available in the `wildcard.deimos.cloud-tls` secret. Notice how all the files are enabled with a read-only permission mode, using the `defaultMode` parameter.

#### **Kustomize subproject**

Now you need to modify the `kustomization.yaml` file of the Nextcloud server subproject.

1. Make a backup of the `kustomization.yaml` file.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud
    $ cp kustomization.yaml kustomization.yaml.bkp
    ~~~

2. Edit the `kustomization.yaml` file to make it look like below.

    ~~~yaml
    # Nextcloud server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-nextcloud

    resources:
    - resources/data-server-nextcloud.persistentvolumeclaim.yaml
    - resources/html-server-nextcloud.persistentvolumeclaim.yaml
    - resources/server-nginx-nextcloud.service.loadbalancer.yaml
    - resources/server-nginx-nextcloud.statefulset.yaml

    replicas:
    - name: server-nginx-nextcloud
      count: 1

    images:
    - name: nextcloud
      newTag: 22.2-fpm-alpine
    - name: nginx
      newTag: 1.21-alpine
    - name: xperimental/nextcloud-exporter
      newTag: 0.4.0-15-gbb88fb6

    configMapGenerator:
    - name: server-nginx-nextcloud
      envs:
      - configs/params.properties
      files:
      - configs/dhparam.pem
      - configs/nginx.conf
      - configs/zz-docker.conf

    secretGenerator:
    - name: server-nextcloud
      files:
      - nextcloud-admin-password=secrets/nextcloud-admin.pwd
    ~~~

    The things that have changed are:
    - In the `resources` list, the `server-nginx-nextcloud` files.
    - In the `images` list, the `newTag` for the `nextcloud` image and the adding of the `nginx` image.
    - In the `configMapGenerator`, the name of the only config map there has changed to `server-nginx-nextcloud` and in its `files` list are all the configuration files that correspond to the Nginx setup.

3. The only thing remaining here would be to validate the yaml of this Kustomize subproject and the main Nextcloud platform project and, finally, to deploy it on your cluster.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/server-nextcloud | less
    $ kubectl kustomize $HOME/k8sprjs/nextcloud | less
    $ kubectl apply -k $HOME/k8sprjs/nextcloud
    ~~~

    > **BEWARE!**  
    If you had already deployed the Apache version of Nextcloud as explained in the G033 guide, you'll have to delete it from your cluster and remake the `k3smnt` folders in the corresponding storage volumes.

### _Traefik IngressRoute configuration_

Instead of exposing your Nginx-based Nextcloud server through an external IP provided by the MetalLB load balancer, you can enable an ingress access through Traefik to expose its service. Next, you'll see how to transform the previous load balancer setup into one using a Traefik `IngressRoute`.

#### **Adapting the configuration**

You only need to modify a bit the `nginx.conf` file to remove all the lines related to the SSL certificate.

1. Make a renamed copy of the `nginx.conf` file.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud/configs
    $ cp nginx.conf nginx.no-ssl.conf
    ~~~

    See that I've added a `.no-ssl` suffix to the renamed copy.

2. Edit the copy `nginx.no-ssl.conf` to remove from it only the lines related to the SSL certificate. The file should end looking like the content next.

    ~~~yaml
    worker_processes auto;

    error_log  /dev/stdout debug;
    pid        /var/run/nginx.pid;

    events {
        worker_connections  8;
    }

    http {
        include   /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format   main '$remote_addr - $remote_user [$time_local]  $status '
                          '"$request" $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log /dev/stdout main; 

        # Disabled because this nginx is acting
        # as a reverse proxy for an application server.
        sendfile        off;

        upstream php-handler {
            server 127.0.0.1:9000;
        }

        server {
            listen 443 http2;
            server_name nextcloud.deimos.cloud nxc.deimos.cloud;

            # HSTS settings
            # WARNING: Only add the preload option once you read about
            # the consequences in https://hstspreload.org/. This option
            # will add the domain to a hardcoded list that is shipped
            # in all major browsers and getting removed from this list
            # could take several months.
            #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;

            # set max upload size
            client_max_body_size 10240M;
            fastcgi_buffers 64 4K;

            # Enable gzip but do not remove ETag headers
            gzip on;
            gzip_vary on;
            gzip_comp_level 4;
            gzip_min_length 256;
            gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
            gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

            # Pagespeed is not supported by Nextcloud, so if your server is built
            # with the `ngx_pagespeed` module, uncomment this line to disable it.
            #pagespeed off;

            # HTTP response headers borrowed from Nextcloud `.htaccess`
            add_header Referrer-Policy                      "no-referrer"   always;
            add_header X-Content-Type-Options               "nosniff"       always;
            add_header X-Download-Options                   "noopen"        always;
            add_header X-Frame-Options                      "SAMEORIGIN"    always;
            add_header X-Permitted-Cross-Domain-Policies    "none"          always;
            add_header X-Robots-Tag                         "none"          always;
            add_header X-XSS-Protection                     "1; mode=block" always;

            # Remove X-Powered-By, which is an information leak
            fastcgi_hide_header X-Powered-By;

            # Path to the root of your installation
            root /var/www/html;

            # Specify how to handle directories -- specifying `/index.php$request_uri`
            # here as the fallback means that Nginx always exhibits the desired behaviour
            # when a client requests a path that corresponds to a directory that exists
            # on the server. In particular, if that directory contains an index.php file,
            # that file is correctly served; if it doesn't, then the request is passed to
            # the front-end controller. This consistent behaviour means that we don't need
            # to specify custom rules for certain paths (e.g. images and other assets,
            # `/updater`, `/ocm-provider`, `/ocs-provider`), and thus
            # `try_files $uri $uri/ /index.php$request_uri`
            # always provides the desired behaviour.
            index index.php index.html /index.php$request_uri;

            # Rule borrowed from `.htaccess` to handle Microsoft DAV clients
            location = / {
                if ( $http_user_agent ~ ^DavClnt ) {
                    return 302 /remote.php/webdav/$is_args$args;
                }
            }

            location = /robots.txt {
                allow all;
                log_not_found off;
                access_log off;
            }

            # Make a regex exception for `/.well-known` so that clients can still
            # access it despite the existence of the regex rule
            # `location ~ /(\.|autotest|...)` which would otherwise handle requests
            # for `/.well-known`.
            location ^~ /.well-known {
                # The rules in this block are an adaptation of the rules
                # in `.htaccess` that concern `/.well-known`.

                location = /.well-known/carddav { return 301 /remote.php/dav/; }
                location = /.well-known/caldav  { return 301 /remote.php/dav/; }

                location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
                location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

                # Let Nextcloud's API for `/.well-known` URIs handle all other
                # requests by passing them to the front-end controller.
                return 301 /index.php$request_uri;
            }

            # Rules borrowed from `.htaccess` to hide certain paths from clients
            location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
            location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

            # Ensure this block, which passes PHP files to the PHP process, is above the blocks
            # which handle static assets (as seen below). If this block is not declared first,
            # then Nginx will encounter an infinite rewriting loop when it prepends `/index.php`
            # to the URI, resulting in a HTTP 500 error response.
            location ~ \.php(?:$|/) {
                # Required for legacy support
                rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;

                # regex to split $uri to $fastcgi_script_name and $fastcgi_path_info
                fastcgi_split_path_info ^(.+?\.php)(/.*)$;

                # Check that the PHP script exists before passing it
                if (!-f $document_root$fastcgi_script_name) {
                    return 404;
                }

                # Mitigate https://httpoxy.org/ vulnerabilities
                fastcgi_param HTTP_PROXY "";

                # pass the request to the PHP handler
                fastcgi_pass php-handler;

                fastcgi_index index.php;

                # Bypass the fact that try_files resets $fastcgi_path_info
                # see: http://trac.nginx.org/nginx/ticket/321
                set $path_info $fastcgi_path_info;
                fastcgi_param PATH_INFO $path_info;

                # Avoid sending the security headers twice
                fastcgi_param modHeadersAvailable true;
                # Enable pretty urls
                fastcgi_param front_controller_active true;

                # set the standard fcgi paramters
                include fastcgi.conf;

                fastcgi_intercept_errors on;
                fastcgi_request_buffering off;
            }

            location ~ \.(?:css|js|svg|gif)$ {
                try_files $uri /index.php$request_uri;
                expires 6M;         # Cache-Control policy borrowed from `.htaccess`
                access_log off;     # Optional: Don't log access to assets
            }

            location ~ \.woff2?$ {
                try_files $uri /index.php$request_uri;
                expires 7d;         # Cache-Control policy borrowed from `.htaccess`
                access_log off;     # Optional: Don't log access to assets
            }

            # Rule borrowed from `.htaccess`
            location /remote {
                return 301 /remote.php$request_uri;
            }

            location / {
                try_files $uri $uri/ /index.php$request_uri;
            }
        }
    }
    ~~~

    All the changes have been done inside the server block, in particular, all the lines starting with the `ssl_` string and the `ssl` value in the listen directive have been all removed.

#### **Resources**

You need to declare slightly different `Service` and `StatefulSet` resources than in the load balancer case, plus a Traefik `IngressRoute`.

1. Go to the subproject's `resources` folder.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud/resources
    ~~~

2. You need to make a renamed copy of `server-nginx-nextcloud.service.loadbalancer.yaml` and `server-nginx-nextcloud.statefulset.yaml`.

    ~~~bash
    $ cp server-nginx-nextcloud.service.loadbalancer.yaml server-nginx-nextcloud.service.clusterip.yaml
    $ cp server-nginx-nextcloud.statefulset.yaml server-nginx-nextcloud.statefulset.no-ssl.yaml
    ~~~

    The `Service` resource copy changes the `.loadbalancer` string with `.clusterip`, while the `StatefulSet` yaml gets a `.no-ssl` suffix.

3. Edit the `server-nginx-nextcloud.service.clusterip.yaml` file to make the `Service` of the `ClusterIP` type.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9205"
      name: server-nginx-nextcloud
    spec:
      type: ClusterIP
      clusterIP: 10.43.100.3
      ports:
      - port: 443
        protocol: TCP
        name: server
      - port: 9205
        protocol: TCP
        name: metrics
    ~~~

    As it happened in the load balancer setup, this file is almost identic to the one used in the Apache scenario, except in the `metadata.name`.

4. Edit `server-nginx-nextcloud.statefulset.no-ssl.yaml` and just remove from it the lines related to the wildcard certificate.

    ~~~yaml
    apiVersion: apps/v1
    kind: StatefulSet

    metadata:
      name: server-nginx-nextcloud
    spec:
      replicas: 1
      serviceName: server-nginx-nextcloud
      template:
        spec:
          containers:
          - name: fpm
            image: nextcloud:22.2-fpm-alpine
            ports:
            - containerPort: 9000
            env:
            - name: NEXTCLOUD_ADMIN_USER
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            - name: NEXTCLOUD_TRUSTED_DOMAINS
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
                  key: nextcloud-trusted-domains
            - name: MYSQL_HOST
              valueFrom:
                configMapKeyRef:
                  name: server-nginx-nextcloud
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
                  name: server-nginx-nextcloud
                  key: cache-redis-svc-cluster-ip
            - name: REDIS_HOST_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cache-redis
                  key: redis-password
            lifecycle:
              postStart:
                exec:
                  command: ["chown", "www-data", "/var/www/html/data"]
            resources:
              limits:
                memory: 512Mi
            volumeMounts:
            - name: fpm-config
              subPath: zz-docker.conf
              mountPath: /usr/local/etc/php-fpm.d/zz-docker.conf
            - name: html-storage
              mountPath: /var/www/html
            - name: data-storage
              mountPath: /var/www/html/data
          - name: server
            image: nginx:1.21-alpine
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              subPath: dhparam.pem
              mountPath: /etc/ssl/dhparam.pem
            - name: nginx-config
              subPath: nginx.conf
              mountPath: /etc/nginx/nginx.conf
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
                  name: server-nginx-nextcloud
                  key: nextcloud-admin-username
            - name: NEXTCLOUD_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: server-nextcloud
                  key: nextcloud-admin-password
            resources:
              limits:
                memory: 32Mi
          hostNetwork: true
          volumes:
          - name: nginx-config
            configMap:
              name: server-nginx-nextcloud
              defaultMode: 0444
              items:
              - key: dhparam.pem
                path: dhparam.pem
              - key: nginx.conf
                path: nginx.conf
              - key: zz-docker.conf
                path: zz-docker.conf
          - name: html-storage
            persistentVolumeClaim:
              claimName: html-server-nextcloud
          - name: data-storage
            persistentVolumeClaim:
              claimName: data-server-nextcloud
    ~~~

    The elements to remove are all the `wildcard.deimos.cloud-tls` references from the `volumeMounts` list in the `server` container declaration, and also the `certificate` block in the `volumes` list at the end of the yaml.

5. Create a new file for the Traefik `IngressRoute`.

    ~~~bash
    $ touch server-nginx-nextcloud.ingressroute.traefik.yaml
    ~~~

6. Put in `server-nginx-nextcloud.ingressroute.traefik.yaml` the yaml below.

    ~~~yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute

    metadata:
      name: server-nginx-nextcloud
    spec:
      entryPoints:
        - websecure
      tls:
        secretName: wildcard.deimos.cloud-tls
      routes:
      - match: Host(`nextcloud.deimos.cloud`) || Host(`nxc.deimos.cloud`)
        kind: Rule
        services:
        - name: server-nginx-nextcloud
          kind: Service
          port: 443
    ~~~

    You might notice that this `IngressRoute` is exactly the same, except in the `metadata.name` and the referenced service `name`, as the one used in the Apache scenario.

#### **Kustomize subproject**

You have to make the final changes at the `kustomization.yaml` file of this Nextcloud server Kustomize subproject.

1. Make a backup of your current `kustomization.yaml` file.

    ~~~bash
    $ cd $HOME/k8sprjs/nextcloud/components/server-nextcloud
    $ cp kustomization.yaml kustomization.yaml.bkp
    ~~~

2. Edit the `kustomization.yaml` file and apply the yaml below.

    ~~~yaml
    # Nextcloud server setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app: server-nextcloud

    resources:
    - resources/data-server-nextcloud.persistentvolumeclaim.yaml
    - resources/html-server-nextcloud.persistentvolumeclaim.yaml
    - resources/server-nginx-nextcloud.ingressroute.traefik.yaml
    - resources/server-nginx-nextcloud.service.clusterip.yaml
    - resources/server-nginx-nextcloud.statefulset.no-ssl.yaml

    replicas:
    - name: server-nginx-nextcloud
      count: 1

    images:
    - name: nextcloud
      newTag: 22.2-fpm-alpine
    - name: nginx
      newTag: 1.21-alpine
    - name: xperimental/nextcloud-exporter
      newTag: 0.4.0-15-gbb88fb6

    configMapGenerator:
    - name: server-nginx-nextcloud
      envs:
      - configs/params.properties
      files:
      - nginx.conf=configs/nginx.no-ssl.conf
      - configs/zz-docker.conf

    secretGenerator:
    - name: server-nextcloud
      files:
      - nextcloud-admin-password=secrets/nextcloud-admin.pwd
    ~~~

    The modifications done above are:
    - In the `resources` list, the `server-nginx-nextcloud` files.
    - In the `configMapGenerator`, one file has been removed (`dhparam.pem`), and the `nginx.no-ssl.conf` file replaces the original `nginx.conf`.

3. The last things to do are the validations and, then, deploy it on your cluster.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/nextcloud/components/server-nextcloud | less
    $ kubectl kustomize $HOME/k8sprjs/nextcloud | less
    $ kubectl apply -k $HOME/k8sprjs/nextcloud
    ~~~

    > **BEWARE!**  
    > If you had already deployed the Apache version of Nextcloud as explained in the G033 guide, you'll have to delete it from your cluster and remake the `k3smnt` folders in the corresponding storage volumes.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/kustomization.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/kustomization.yaml.bkp`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/000-default.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/000-default.no-ssl.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/dhparam.pem`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/nginx.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/configs/zz-docker.conf`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.ingressroute.traefik.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.service.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.service.clusterip.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.statefulset.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-apache-nextcloud.statefulset.no-ssl.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-nginx-nextcloud.ingressroute.traefik.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-nginx-nextcloud.service.clusterip.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-nginx-nextcloud.service.loadbalancer.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-nginx-nextcloud.statefulset.yaml`
- `$HOME/k8sprjs/nextcloud/components/server-nextcloud/resources/server-nginx-nextcloud.statefulset.no-ssl.yaml`

## References

### _Kubernetes_

#### **Executing multiple commands in lifecycle (postStart/preStop) of containers**

- [Kubernetes - Passing multiple commands to the container](https://stackoverflow.com/questions/33979501/kubernetes-passing-multiple-commands-to-the-container)
- [multiple command in postStart hook of a container](https://stackoverflow.com/questions/39436845/multiple-command-in-poststart-hook-of-a-container)

### _Nextcloud_

- [Official Docker build of Nextcloud](https://hub.docker.com/_/nextcloud)
- [Official Docker build of Nextcloud on GitHub](https://github.com/nextcloud/docker)
- [Prometheus exporter for getting some metrics of a Nextcloud server instance](https://hub.docker.com/r/xperimental/nextcloud-exporter)
- [Installation and server configuration](https://docs.nextcloud.com/server/stable/admin_manual/installation/index.html)
- [Installation on Linux](https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html#installation-on-linux)
- [Database configuration](https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/linux_database_configuration.html)
- [How to Fix Common NextCloud Performance Issues](https://autoize.com/nextcloud-performance-troubleshooting/)
- [Nextcloud on Kubernetes, by modzilla99](https://github.com/modzilla99/kubernetes-nextcloud)
- [Nextcloud on Kubernetes, by andremotz](https://github.com/andremotz/nextcloud-kubernetes)
- [Deploy Nextcloud - Yaml with application and database container and a configure a secret](https://www.debontonline.com/2021/05/part-15-deploy-nextcloud-yaml-with.html)
- [Self-Host Nextcloud Using Kubernetes](https://blog.true-kubernetes.com/self-host-nextcloud-using-kubernetes/)
- [Deploying NextCloud on Kubernetes with Kustomize](https://medium.com/@acheaito/nextcloud-on-kubernetes-19658785b565)
- [A NextCloud Kubernetes deployment](https://github.com/acheaito/nextcloud-kubernetes)
- [Install NextCloud on Ubuntu 20.04 with Apache (LAMP Stack)](https://www.techwizcr.com/install-nextcloud-on-ubuntu-20-04-with-apache-lamp-stack/nextcloud/)
- [Nextcloud Setup with Nginx](https://dev.to/yparam98/nextcloud-setup-with-nginx-2cm1)
- [Nextcloud server installation with NGINX](https://wiki.mageia.org/en/Nextcloud_server_installation_with_NGINX)
- [Nextcloud self-hosting on K8s](https://eramons.github.io/techblog/post/nextcloud/)
- [Nextcloud self-hosting on K8s on GitHub](https://github.com/eramons/kubenextcloud)
- [Installing Nextcloud on Ubuntu with Redis, APCu, SSL & Apache](https://bayton.org/docs/nextcloud/installing-nextcloud-on-ubuntu-16-04-lts-with-redis-apcu-ssl-apache/)
- [Setup NextCloud Server with Nginx SSL Reverse-Proxy and Apache2 Backend](https://breuer.dev/tutorial/Setup-NextCloud-FrontEnd-Nginx-SSL-Backend-Apache2)
- [Install Nextcloud with Apache2 on Debian 10](https://vectops.com/2021/01/install-nextcloud-with-apache2-on-debian-10/)
- [Nextcloud scale-out using Kubernetes](https://faun.pub/nextcloud-scale-out-using-kubernetes-93c9cac9e493)
- [PHP-FPM, Nginx, Kubernetes, and Docker](https://matthewpalmer.net/kubernetes-app-developer/articles/php-fpm-nginx-kubernetes.html)
- [nginx nextcloud config](https://pastebin.com/iTybBRBC)
- [How to install Nextcloud with Nginx and PHP7-FPM on CentOS 7](https://kreationnext.com/support/how-to-install-nextcloud-with-nginx-and-php7-fpm-on-centos-7/)
- [Nextcloud and PHP-FPM adjustments](https://www.reddit.com/r/NextCloud/comments/9e5ljv/nextcloud_and_phpfpm_adjustments/)
- [How to tune Nextcloud on-premise cloud server for better performance](https://www.techrepublic.com/article/how-to-tune-nextcloud-on-premise-cloud-server-for-better-performance/)
- [Nextcloud Installationsanleitung auf Basis von Ubuntu Server 20.04 focal fossa oder Debian 11 bullseye mit nginx, MariaDB, PHP 8 fpm, Let’s Encrypt (acme), Redis, ufw, Fail2ban, postfix und netdata](https://www.c-rieger.de/nextcloud-installationsanleitung/)

### _Apache httpd_

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)
- [apachectl - Apache HTTP Server Control Interface](https://httpd.apache.org/docs/2.4/programs/apachectl.html)
- [Apache Module mod_http2](https://httpd.apache.org/docs/2.4/mod/mod_http2.html)
- [Multi-Processing Modules (MPMs)](https://httpd.apache.org/docs/2.4/mpm.html)
- [Apache MPM prefork](https://httpd.apache.org/docs/2.4/mod/prefork.html)
- [Apache MPM worker](https://httpd.apache.org/docs/2.4/mod/worker.html)
- [Apache MPM event](https://httpd.apache.org/docs/2.4/mod/event.html)
- [How to enable or disable Apache modules](https://www.simplified.guide/apache/enable-disable-module)
- [How to enable HTTP/2 support in Apache](https://http2.pro/doc/Apache)
- [Using HTTP/2 with Nextcloud](https://feutl.github.io/nextcloud-http2/)

### _PHP-FPM_

- [FastCGI Process Manager (FPM) Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [PHP-FPM Process Calculator](https://spot13.com/pmcalculator/)
- [PHP 8 Alpine 3.14 FPM image Dockerfile](https://github.com/docker-library/php/blob/master/8.0/alpine3.14/fpm/Dockerfile)
- [How and where to configure pm.max_children for php-fpm with Docker?](https://serverfault.com/questions/884256/how-and-where-to-configure-pm-max-children-for-php-fpm-with-docker)
- [A better way to run PHP-FPM](https://ma.ttias.be/a-better-way-to-run-php-fpm/)
- [How to reduce PHP-FPM (php5-fpm) RAM usage by about 50%](https://linuxbsdos.com/2015/02/17/how-to-reduce-php-fpm-php5-fpm-ram-usage-by-about-50/)
- [PHP-FPM settings tutorial. max_servers, min_servers, etc.](https://thisinterestsme.com/php-fpm-settings/)
- [Optimizar y reducir el uso de memoria de PHP-FPM](https://rm-rf.es/optimizar-reducir-consumo-memoria-php-fpm/)

### _Nginx_

- [Official Docker build of Nginx](https://hub.docker.com/_/nginx)
- [Configuring NGINX and NGINX Plus as a Web Server](https://docs.nginx.com/nginx/admin-guide/web-server/web-server/)
- [Full Example Configuration](https://www.nginx.com/resources/wiki/start/topics/examples/full/)
- [PHP FastCGI Example](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [Nginx + phpFPM: PATH_INFO always empty](https://stackoverflow.com/questions/20848899/nginx-phpfpm-path-info-always-empty)
- [Nginx $document_root$fastcgi_script_name vs $request_filename](https://serverfault.com/questions/465607/nginx-document-rootfastcgi-script-name-vs-request-filename)
- [fastcgi_params Versus fastcgi.conf – Nginx Config History](https://blog.martinfjordvald.com/nginx-config-history-fastcgi_params-versus-fastcgi-conf/)
- [Problem configuring php-fpm with nginx](https://serverfault.com/questions/226779/problem-configuring-php-fpm-with-nginx)
- [Two ways of communication between nginx and PHP FPM](https://developpaper.com/two-ways-of-communication-between-nginx-and-php-fpm/)
- [Using a custom nginx.conf on GKE](https://cloud.google.com/endpoints/docs/openapi/custom-nginx)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Setup SSL on NGINX and configure for best security](https://www.ssltrust.com.au/help/setup-guides/setup-ssl-nginx-configure-best-security)
- [How To Create a Self-Signed SSL Certificate for Nginx in Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-20-04-1)

## Navigation

[<< Previous (**G910. Appendix 10**)](G910%20-%20Appendix%2010%20~%20Setting%20up%20virtual%20network%20with%20Open%20vSwitch.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G912. Appendix 12**) >>](G912%20-%20Appendix%2012%20~%20Adapting%20MetalLB%20config%20to%20CR.md)
