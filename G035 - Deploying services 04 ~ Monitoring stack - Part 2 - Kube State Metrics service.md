# G035 - Deploying services 04 ~ Monitoring stack - Part 2 - Kube State Metrics service

[In the previous part](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md#outlining-your-monitoring-stack-setup), I've indicated what components will make up your monitoring stack for your K3s cluster. Here you'll start with the _Kube State Metrics_ service, by declaring a configuration based on the [Kubernetes standard deployment example](https://github.com/kubernetes/kube-state-metrics/tree/master/examples/standard) found in [the official GitHub page](https://github.com/kubernetes/kube-state-metrics) of the Kube State Metrics project, although with some modifications.

## Kustomize project folders for your monitoring stack and Kube State Metrics

Your monitoring stack components need to be under a common Kustomize project, so let's create the usual folders as you've seen in previous guides. Like in those cases, I'll assume you're working in a special folder for your Kustomize projects, set in a `$HOME/k8sprjs` folder of your kubectl client system.

~~~bash
$ mkdir -p $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources
~~~

In the command above, the main Kustomize project folder for the monitoring stack is called `monitoring`, while the directory for the Kube State Metrics service is called `agent-kube-state-metrics`.

## Kube State Metrics ServiceAccount resource

To deploy the Kube State Metrics service, you'll need some objects that you didn't need to declare in your Nextcloud or Gitea platforms. One of those objects is a service account, which provides an identity for processes running in a pod. In other words, this is an standard Kubernetes authentication resource which [is explained in this official documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).

1. Create an `agent-kube-state-metrics.serviceaccount.yaml` file in the `agent-kube-state-metrics/resources` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.serviceaccount.yaml
    ~~~

2. Fill `agent-kube-state-metrics.serviceaccount.yaml` with the following yaml declaration.

    ~~~yaml
    apiVersion: v1
    automountServiceAccountToken: false
    kind: ServiceAccount

    metadata:
      name: agent-kube-state-metrics
    ~~~

    As you see above, it's a really simple resource to declare but also has other parameters available. Check them out in its [official API definition](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/).

    - Notice the parameter `automountServiceAccountToken`, which is the first time that appears in this guide series. It's a boolean value that here's set explicitly to `false` as a security measure. The reason for this is well explained [in this article](https://hackersvanguard.com/abuse-kubernetes-with-the-automountserviceaccounttoken/), but it has to do with how pods get their ability to interact with the Kubernetes API server and the API bearer token used to connect with it.

## Kube State Metrics ClusterRole resource

For the previous service account to be able to do anything in your cluster, you need to associate it with a role that includes concrete actions to perform. In the case of the Kube State Metrics agents you want to deploy in all your cluster nodes, you'll need a reader role able to act cluster-wide. This means you'll need to declare a [ClusterRole resource](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/).

1. Generate the file `agent-kube-state-metrics.clusterrole.yaml` within the `agent-kube-state-metrics/resources` directory.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrole.yaml
    ~~~

2. Put the following yaml declaration in the file `agent-kube-state-metrics.clusterrole.yaml`.

    ~~~yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole

    metadata:
      name: agent-kube-state-metrics
    rules:
    - apiGroups:
      - ""
      resources:
      - configmaps
      - secrets
      - nodes
      - pods
      - services
      - resourcequotas
      - replicationcontrollers
      - limitranges
      - persistentvolumeclaims
      - persistentvolumes
      - namespaces
      - endpoints
      verbs:
      - list
      - watch
    - apiGroups:
      - apps
      resources:
      - statefulsets
      - daemonsets
      - deployments
      - replicasets
      verbs:
      - list
      - watch
    - apiGroups:
      - batch
      resources:
      - cronjobs
      - jobs
      verbs:
      - list
      - watch
    - apiGroups:
      - autoscaling
      resources:
      - horizontalpodautoscalers
      verbs:
      - list
      - watch
    - apiGroups:
      - authentication.k8s.io
      resources:
      - tokenreviews
      verbs:
      - create
    - apiGroups:
      - authorization.k8s.io
      resources:
      - subjectaccessreviews
      verbs:
      - create
    - apiGroups:
      - policy
      resources:
      - poddisruptionbudgets
      verbs:
      - list
      - watch
    - apiGroups:
      - certificates.k8s.io
      resources:
      - certificatesigningrequests
      verbs:
      - list
      - watch
    - apiGroups:
      - storage.k8s.io
      resources:
      - storageclasses
      - volumeattachments
      verbs:
      - list
      - watch
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - mutatingwebhookconfigurations
      - validatingwebhookconfigurations
      verbs:
      - list
      - watch
    - apiGroups:
      - networking.k8s.io
      resources:
      - networkpolicies
      - ingresses
      verbs:
      - list
      - watch
    - apiGroups:
      - coordination.k8s.io
      resources:
      - leases
      verbs:
      - list
      - watch
    ~~~

    See how the `agent-kube-state-metrics` cluster role is a collection of `rules` that define what actions (`verbs`) can be done on concrete `resources` available in concrete apis (`apiGroups`). Also notice how the verbs are almost always `list` or `watch`, limiting to a read-only behaviour this cluster role.

    > **BEWARE!**  
    > `ClusterRole` resources are **not** namespaced, so you won't see a `namespace` parameter in them.

## Kube State Metrics ClusterRoleBinding resource

To link the cluster role with your service account, you need a binding resource such as the [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/).

1. Create the `agent-kube-state-metrics.clusterrolebinding.yaml` file under the `agent-kube-state-metrics/resources` path.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrolebinding.yaml
    ~~~

2. Copy the following yaml in `agent-kube-state-metrics.clusterrolebinding.yaml`.

    ~~~yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding

    metadata:
      name: agent-kube-state-metrics
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: agent-kube-state-metrics
    subjects:
    - kind: ServiceAccount
      name: agent-kube-state-metrics
    ~~~

    This cluster role binding specifies in `roleRef` what is the role to bind, and in `subjects` you have a list of resources which is limited here to the `agent-kube-state-metrics` service account. Notice how the `kind` of the resources being binded is also specified.

    > **BEWARE!**  
    > `ClusterRoleBinding` resources are **not** namespaced, so you won't see a `namespace` parameter in them.

## Kube State Metrics Deployment resource

The Kube State Metric service is just an agent that doesn't store anything, so you can use a deployment resource for deploying it in your K3s cluster.

1. Generate an `agent-kube-state-metrics.deployment.yaml` file in `agent-kube-state-metrics/resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.deployment.yaml
    ~~~

2. Put the yaml below in `agent-kube-state-metrics.deployment.yaml`.

    ~~~yaml
    apiVersion: apps/v1
    kind: Deployment

    metadata:
      name: agent-kube-state-metrics
    spec:
      replicas: 1
      template:
        spec:
          automountServiceAccountToken: true
          containers:
          - name: server
            image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.5.0
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
              readOnlyRootFilesystem: true
              runAsUser: 65534
            ports:
            - containerPort: 8080
              name: http-metrics
            - containerPort: 8081
              name: telemetry
            resources:
              requests:
                cpu: 250m
                memory: 64Mi
              limits:
                cpu: 500m
                memory: 128Mi
            livenessProbe:
              httpGet:
                path: /healthz
                port: 8080
              initialDelaySeconds: 5
              timeoutSeconds: 5
            readinessProbe:
              httpGet:
                path: /
                port: 8081
              initialDelaySeconds: 5
              timeoutSeconds: 5
          nodeSelector:
            kubernetes.io/os: linux
          serviceAccountName: agent-kube-state-metrics
          tolerations:
          - effect: NoExecute
            operator: Exists
    ~~~

    This `Deployment` resource is about just one pod, and comes with some particularities compared with the other deployment objects you've declared in previous guides.

    - `automountServiceAccountToken`: this parameter appears again in this guide, but here is set to `true`. Why here is true rather than in the `ServiceAccount` resource? I haven't found a concrete explanation, but again you can assume that it's related to the security concerns related to the token used for connecting with the Kubernetes API available in your cluster.

    - `server` container: executes the Kube State Metrics service.
        - `securityContext`: section for adjusting the security conditions of the container.
            - `allowPrivilegeEscalation`: controls whether a process can gain more privileges than its parent process. Here set to `false` to contrain this container within its given privileges.
            - `capabilities`: with this section you can add or drop security related capabilities to the container beyond its default setting. In this case, `ALL` possible capabilities are `drop`ped to get a non-privileged container.
            - `readOnlyRootFilesystem`: to set or not the `root` filesystem within the container as read-only.
            - `runAsUser`: specifies the UID of the user running the container. In this deployment will be one with the UID `65534` that it's already prepared in the Kube State Metrics image.
        - `livenessProbe`: enables a periodic probe of the container liveness. If the probe fails, the container will be restarted.
        - `readinessProbe`: sets a periodic probe of the container service readiness. The container will be removed from service endpoints if the probe fails.

    - `nodeSelector`: a selector that makes the pod run only on nodes that have the specified label. In this case, the `kubernetes.io/os` label is ensuring that this pod will be executed only on Linux nodes.

    - `serviceAccountName`: the name of the `ServiceAccount` that will be used to run this pod. Here is set the one you declared earlier in this document, the `agent-kube-state-metrics` one.

    - `tolerations`: to allow the Kube State Metrics agent to run in the master node of your K3s cluster, you must allow this pod to tolerate the `NoExecute` taint you set in that node.

## Kube State Metrics Service resource

The last resource you need to describe for your Kube State Metrics setup is a Service resource.

1. Create the file `agent-kube-state-metrics.service.yaml` within `agent-kube-state-metrics/resources`.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.service.yaml
    ~~~

2. Fill `agent-kube-state-metrics.service.yaml` with the yaml declaration next.

    ~~~yaml
    apiVersion: v1
    kind: Service

    metadata:
      name: agent-kube-state-metrics
    spec:
      clusterIP: None
      ports:
      - name: http-metrics
        port: 8080
        targetPort: http-metrics
      - name: telemetry
        port: 8081
        targetPort: telemetry
    ~~~

    The main particularity of this service is that is declared to have no cluster IP associated to it. This implies that its internal cluster FQDN will be needed to reach it.

### _Kube State Metrics `Service`'s FQDN or DNS record_

The Prometheus server you'll setup in a later guide needs to know the DNS record assigned to this `Service` within your cluster. To deduce it, do as you did with the services of [the Gitea platform like the Redis one](G034%20-%20Deploying%20services%2003%20~%20Gitea%20-%20Part%202%20-%20Redis%20cache%20server.md#redis-services-fqdn-or-dns-record).

- The string format for any `Service` resource's FQDN is `<metadata.name>.<namespace>.svc.<internal.cluster.domain>`.
- The namespace for all resources of the monitoring stack will be `monitoring`.
- The internal cluster domain that was set back [in the **G025** guide](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file) is `deimos.cluster.io`.
- All the components of this monitoring stack will also have a `mntr-` prefix added to their `metadata.name` string.

Knowing all that, this `Service`'s FQDN will be the following one.

~~~http
mntr-agent-kube-state-metrics.monitoring.svc.deimos.cluster.io
~~~

## Kube State Metrics Kustomize project

Now you need to associate all the resources with a Kustomization project, declared with the corresponding `kustomization.yaml` file.

1. Produce a `kustomization.yaml` file in the `agent-kube-state-metrics` folder.

    ~~~bash
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/kustomization.yaml
    ~~~

2. In `kustomization.yaml`, copy the following yaml.

    ~~~yaml
    # Kube State Metrics setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    commonLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: kube-state-metrics
      app.kubernetes.io/version: 2.5.0

    resources:
    - resources/agent-kube-state-metrics.clusterrolebinding.yaml
    - resources/agent-kube-state-metrics.clusterrole.yaml
    - resources/agent-kube-state-metrics.deployment.yaml
    - resources/agent-kube-state-metrics.serviceaccount.yaml
    - resources/agent-kube-state-metrics.service.yaml

    replicas:
    - name: agent-kube-state-metrics
      count: 1

    images:
    - name: registry.k8s.io/kube-state-metrics/kube-state-metrics
      newTag: v2.5.0
    ~~~

    Under `commonLabels` I've set three labels that also appear in the resources declared in [the official standard example for deploying Kube State Metrics](https://github.com/kubernetes/kube-state-metrics/blob/master/examples/standard). Be aware of the one named `version`: whenever you update the Kube State Metrics' image version, you'll have to update that value too.

### _Validating the Kustomize yaml output_

Let's validate the Kustomize project for your Kube State Metrics service.

1. Dump the output of this Kustomize project in a file named `agent-kube-state-metrics.k.output.yaml`.

    ~~~bash
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics > agent-kube-state-metrics.k.output.yaml
    ~~~

2. Open the `agent-kube-state-metrics.k.output.yaml` file and compare your resulting yaml output with the one below.

    ~~~yaml
    apiVersion: v1
    automountServiceAccountToken: false
    kind: ServiceAccount
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
      name: agent-kube-state-metrics
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
      name: agent-kube-state-metrics
    rules:
    - apiGroups:
      - ""
      resources:
      - configmaps
      - secrets
      - nodes
      - pods
      - services
      - resourcequotas
      - replicationcontrollers
      - limitranges
      - persistentvolumeclaims
      - persistentvolumes
      - namespaces
      - endpoints
      verbs:
      - list
      - watch
    - apiGroups:
      - apps
      resources:
      - statefulsets
      - daemonsets
      - deployments
      - replicasets
      verbs:
      - list
      - watch
    - apiGroups:
      - batch
      resources:
      - cronjobs
      - jobs
      verbs:
      - list
      - watch
    - apiGroups:
      - autoscaling
      resources:
      - horizontalpodautoscalers
      verbs:
      - list
      - watch
    - apiGroups:
      - authentication.k8s.io
      resources:
      - tokenreviews
      verbs:
      - create
    - apiGroups:
      - authorization.k8s.io
      resources:
      - subjectaccessreviews
      verbs:
      - create
    - apiGroups:
      - policy
      resources:
      - poddisruptionbudgets
      verbs:
      - list
      - watch
    - apiGroups:
      - certificates.k8s.io
      resources:
      - certificatesigningrequests
      verbs:
      - list
      - watch
    - apiGroups:
      - storage.k8s.io
      resources:
      - storageclasses
      - volumeattachments
      verbs:
      - list
      - watch
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - mutatingwebhookconfigurations
      - validatingwebhookconfigurations
      verbs:
      - list
      - watch
    - apiGroups:
      - networking.k8s.io
      resources:
      - networkpolicies
      - ingresses
      verbs:
      - list
      - watch
    - apiGroups:
      - coordination.k8s.io
      resources:
      - leases
      verbs:
      - list
      - watch
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
      name: agent-kube-state-metrics
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: agent-kube-state-metrics
    subjects:
    - kind: ServiceAccount
      name: agent-kube-state-metrics
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
      name: agent-kube-state-metrics
    spec:
      clusterIP: None
      ports:
      - name: http-metrics
        port: 8080
        targetPort: http-metrics
      - name: telemetry
        port: 8081
        targetPort: telemetry
      selector:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 2.5.0
      name: agent-kube-state-metrics
    spec:
      replicas: 1
      selector:
        matchLabels:
          app.kubernetes.io/component: exporter
          app.kubernetes.io/name: kube-state-metrics
          app.kubernetes.io/version: 2.5.0
      template:
        metadata:
          labels:
            app.kubernetes.io/component: exporter
            app.kubernetes.io/name: kube-state-metrics
            app.kubernetes.io/version: 2.5.0
        spec:
          automountServiceAccountToken: true
          containers:
          - image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.5.0
            livenessProbe:
              httpGet:
                path: /healthz
                port: 8080
              initialDelaySeconds: 5
              timeoutSeconds: 5
            name: server
            ports:
            - containerPort: 8080
              name: http-metrics
            - containerPort: 8081
              name: telemetry
            readinessProbe:
              httpGet:
                path: /
                port: 8081
              initialDelaySeconds: 5
              timeoutSeconds: 5
            resources:
              limits:
                cpu: 500m
                memory: 128Mi
              requests:
                cpu: 250m
                memory: 64Mi
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
              readOnlyRootFilesystem: true
              runAsUser: 65534
          nodeSelector:
            kubernetes.io/os: linux
          serviceAccountName: agent-kube-state-metrics
          tolerations:
          - effect: NoExecute
            operator: Exists
    ~~~

    The main thing to notice in the output is how the labels and selectors have been automatically applied on the resources.

## Don't deploy this Kube State Metrics project on its own

My usual reminder. This component is part of a bigger project yet to be completed: your monitoring stack. Wait till you have every component ready for deploying in your cluster.

## Relevant system paths

### _Folders in `kubectl` client system_

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources`

### _Files in `kubectl` client system_

- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrole.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrolebinding.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.deployment.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.service.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.serviceaccount.yaml`

## References

### _Kubernetes_

- [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
- [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Abuse Kubernetes with the AutomountServiceAccountToken](https://hackersvanguard.com/abuse-kubernetes-with-the-automountserviceaccounttoken/)
- [ClusterRole](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/)
- [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Mixing Kubernetes Roles, RoleBindings, ClusterRoles, and ClusterBindings](https://octopus.com/blog/k8s-rbac-roles-and-bindings)
- [Kubernetes Pod. Security context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context-1)
- [Kubernetes SecurityContext Capabilities Explained [Examples]](https://www.golinuxcloud.com/kubernetes-securitycontext-capabilities/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Working with taints and tolerations in Kubernetes](https://www.padok.fr/en/blog/add-taint-nodes-tolerations)
- [Node taint k3s-controlplane=true:NoExecute](https://github.com/k3s-io/k3s/issues/1401)

### _Kube State Metrics_

- [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
- [Kube State Metrics standard deployment example for v2.5.0](https://github.com/kubernetes/kube-state-metrics/tree/master/examples/standard)
- [The Guide To Kube-State-Metrics](https://www.densify.com/kubernetes-tools/kube-state-metrics)
- [How To Setup Kube State Metrics on Kubernetes](https://devopscube.com/setup-kube-state-metrics/)
- [Kube state metrics kubernetes deployment configs](https://github.com/devopscube/kube-state-metrics-configs)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 1**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 3**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md)
