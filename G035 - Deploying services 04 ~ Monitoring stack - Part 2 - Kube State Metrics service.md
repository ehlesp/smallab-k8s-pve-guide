# G035 - Deploying services 04 ~ Monitoring stack - Part 2 - Kube State Metrics service

- [Start by deploying the Kube State Metrics service](#start-by-deploying-the-kube-state-metrics-service)
- [Kustomize project folders for your monitoring stack and Kube State Metrics](#kustomize-project-folders-for-your-monitoring-stack-and-kube-state-metrics)
- [Kube State Metrics ServiceAccount](#kube-state-metrics-serviceaccount)
- [Kube State Metrics ClusterRole](#kube-state-metrics-clusterrole)
- [Kube State Metrics ClusterRoleBinding](#kube-state-metrics-clusterrolebinding)
- [Kube State Metrics Deployment](#kube-state-metrics-deployment)
- [Kube State Metrics Service](#kube-state-metrics-service)
- [Kube State Metrics Kustomize project](#kube-state-metrics-kustomize-project)
  - [Validating the Kustomize YAML output](#validating-the-kustomize-yaml-output)
- [Do not deploy this Kube State Metrics project on its own](#do-not-deploy-this-kube-state-metrics-project-on-its-own)
- [Relevant system paths](#relevant-system-paths)
  - [Folders in `kubectl` client system](#folders-in-kubectl-client-system)
  - [Files in `kubectl` client system](#files-in-kubectl-client-system)
- [References](#references)
  - [Kube State Metrics](#kube-state-metrics)
  - [Other Kube State Metrics related contents](#other-kube-state-metrics-related-contents)
  - [Kubernetes](#kubernetes)
    - [Security concerns](#security-concerns)
    - [Pods Scheduling](#pods-scheduling)
  - [Other Kubernetes-related contents](#other-kubernetes-related-contents)
    - [About security concerns](#about-security-concerns)
    - [About pods scheduling](#about-pods-scheduling)
- [Navigation](#navigation)

## Start by deploying the Kube State Metrics service

This part shows you how to deploy the _Kube State Metrics_ service to make the "hidden" metrics of your Kubernetes cluster available for the other components of the monitoring stack. This deployment will use a Kustomize configuration based on the [Kubernetes standard deployment example](https://github.com/kubernetes/kube-state-metrics/tree/main/examples/standard) found in [the official GitHub page of the Kube State Metrics project](https://github.com/kubernetes/kube-state-metrics), albeit with some modifications.

## Kustomize project folders for your monitoring stack and Kube State Metrics

The components of your monitoring stack need to be under a common Kustomize project. Create the usual folders as you have seen in previous deployments. Like in those cases, this guide will assume you are working in a special folder for your Kustomize projects, set in a `$HOME/k8sprjs` folder of your `kubectl` client system:

~~~sh
$ mkdir -p $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources
~~~

In the command above, the main Kustomize project folder for the monitoring stack is called `monitoring`, while the directory for the Kube State Metrics service is called `agent-kube-state-metrics`.

## Kube State Metrics ServiceAccount

To deploy the Kube State Metrics service, you need some objects you already saw in the [Headlamp deployment](G031%20-%20K3s%20cluster%20setup%2014%20~%20Deploying%20the%20Headlamp%20dashboard.md). One of those objects is a service account, which provides an identity for processes running in a pod. In other words, this is an standard Kubernetes authentication resource [explained in this official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).

Configure one service account for your Kube State Metrics service as follows:

1. Create an `agent-kube-state-metrics.serviceaccount.yaml` file in the `agent-kube-state-metrics/resources/` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.serviceaccount.yaml
    ~~~

2. Declare a `ServiceAccount` for the Kube State Metrics service in the `resources/agent-kube-state-metrics.serviceaccount.yaml` file:

    ~~~yaml
    # Kube State Metrics ServiceAccount
    apiVersion: v1
    kind: ServiceAccount

    automountServiceAccountToken: false
    metadata:
      name: agent-kube-state-metrics
    ~~~

    As shown above, it is a really simple resource to declare but also has other parameters available. Check them out in its [official API definition](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/).

    Notice that it has the parameter `automountServiceAccountToken` set explicitly to `false` as a security hardening measure, as you have seen applied already in the [Ghost server](G033%20-%20Deploying%20services%2002%20~%20Ghost%20-%20Part%204%20-%20Ghost%20server.md#ghost-server-statefulset) or [Forgejo server](G034%20-%20Deploying%20services%2003%20~%20Forgejo%20-%20Part%204%20-%20Forgejo%20server.md#forgejo-server-statefulset) respective stateful sets.

    > [!NOTE]
    > **Setting to `false` the `automountServiceAccountToken` parameter helps in protecting the cluster's Kubernetes API**\
    > [The need for this measure is well explained in this article](https://hackersvanguard.com/abuse-kubernetes-with-the-automountserviceaccounttoken/). It has to do with how pods get their ability to interact with the Kubernetes API server and the API bearer token used to connect with it.

## Kube State Metrics ClusterRole

For the previous service account to be able to do anything in your cluster, you need to associate it with a role that includes concrete actions to perform. In the case of the Kube State Metrics agents you want to deploy in all your cluster nodes, you will need a reader role able to act cluster-wide. This implies declaring a [ClusterRole resource](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/):

1. Generate a file `agent-kube-state-metrics.clusterrole.yaml` within the `agent-kube-state-metrics/resources/` directory:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrole.yaml
    ~~~

2. Declare the `ClusterRole` object in the `resources/agent-kube-state-metrics.clusterrole.yaml` file:

    ~~~yaml
    # Kube State Metrics read-only ClusterRole to read Kubernetes metrics
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
          - serviceaccounts
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
          - discovery.k8s.io
        resources:
          - endpointslices
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
          - ingressclasses
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
      - apiGroups:
          - rbac.authorization.k8s.io
        resources:
          - clusterrolebindings
          - clusterroles
          - rolebindings
          - roles
        verbs:
          - list
          - watch
    ~~~

    See how the `agent-kube-state-metrics` cluster role is a collection of `rules` that define what actions (`verbs`) can be done on concrete `resources` available in concrete apis (`apiGroups`). Also notice how the verbs are almost always `list` or `watch`, limiting this cluster role to a read-only behavior.

    > [!NOTE]
    > **`ClusterRole` resources are not namespaced**\
    > You will never find a `namespace` parameter in standard `ClusterRole` objects.

## Kube State Metrics ClusterRoleBinding

To link the [cluster role](#kube-state-metrics-clusterrole) with the [service account](#kube-state-metrics-serviceaccount), you need to bind them through a [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/) object:

1. Create the `agent-kube-state-metrics.clusterrolebinding.yaml` file under the `agent-kube-state-metrics/resources/` path:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrolebinding.yaml
    ~~~

2. Declare the `ClusterRoleBinding` object that connects the service account and cluster roles created previously in `resources/agent-kube-state-metrics.clusterrolebinding.yaml`:

    ~~~yaml
    # Kube State Metrics ClusterRoleBinding to bind the service account with the read-only ClusterRole
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

    > [!NOTE]
    > **`ClusterRoleBinding` resources are not namespaced**\
    > You will never see a `namespace` parameter in standard `ClusterRoleBinding` objects.

## Kube State Metrics Deployment

The Kube State Metrics service is just an agent that does not need to store any state. This allows you to deploy it in your K3s cluster with a `Deployment` resource:

1. Generate an `agent-kube-state-metrics.deployment.yaml` file in `agent-kube-state-metrics/resources/`:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.deployment.yaml
    ~~~

2. Declare the `Deployment` object for Kube State Metrics in `resources/agent-kube-state-metrics.deployment.yaml`:

    ~~~yaml
    # Kube State Metrics deployment in a regular pod
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
          - name: agent
            image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 65534
              seccompProfile:
                type: RuntimeDefault
            ports:
            - containerPort: 8080
              name: http-metrics
            - containerPort: 8081
              name: telemetry
            resources:
              requests:
                cpu: 250m
                memory: 32M
            livenessProbe:
              httpGet:
                path: /livez
                port: http-metrics
              initialDelaySeconds: 5
              timeoutSeconds: 5
            readinessProbe:
              httpGet:
                path: /readyz
                port: telemetry
              initialDelaySeconds: 5
              timeoutSeconds: 5
          nodeSelector:
            kubernetes.io/os: linux
          serviceAccountName: agent-kube-state-metrics
          tolerations:
          - effect: NoSchedule
            operator: Exists
    ~~~

    This `Deployment` object deploys just one pod, and comes with some particularities compared with the `StatefulSet` objects you have seen in previous deployments:

    - `automountServiceAccountToken`\
      This parameter appears again in this deployment procedure, but here is set to `true`. Why is `true` here rather than in the `ServiceAccount` resource? It is a matter of hierarchy and precedence within the Kubernetes cluster. The `ServiceAccount` object defines a global policy in which that parameter set to `false` disables the associated feature for any service using that account. On the other hand, setting the parameter to `true` in the pod enables that feature only for that specific pod.

    - `agent` container:
      This container for the Kube State Metrics has a few particularities, beyond being run with a non-root user:

      - `securityContext`\
        This block comes with a couple of new parameters that deserve some clarification:

        - `capabilities`\
          With this section you can add or drop security related capabilities to the container beyond its default setting. In this case, `ALL` possible capabilities are `drop`ped to get a non-privileged container.

        - `seccompProfile`\
          Specifies the [secure computing mode (_seccomp_)](https://kubernetes.io/docs/reference/node/seccomp/) to apply to the container. This mode is applied by the profile set in the `type` parameter. In this case, the `RuntimeDefault` profile represents the default container runtime seccomp profile.

    - `nodeSelector`\
      A selector that makes the pod run only on nodes that have the specified label. In this case, the `kubernetes.io/os` label is ensuring that this pod will be executed only on Linux nodes.

    - `serviceAccountName`\
      The name of the `ServiceAccount` that will be used to run this pod. Here is set the `agent-kube-state-metrics` one you declared earlier in this document.

    - `tolerations`\
      Allows the Kube State Metrics agent to run in the server node of your K3s cluster. You must allow this pod to tolerate the `NoSchedule` node taint [you configured in that node when you installed it](G025%20-%20K3s%20cluster%20setup%2008%20~%20K3s%20Kubernetes%20cluster%20setup.md#the-k3sserver01-nodes-configyaml-file), otherwise it will not run in the server node and you will not get metrics from it.

## Kube State Metrics Service

The last resource you need to describe for your Kube State Metrics setup is a `Service`:

1. Create the file `agent-kube-state-metrics.service.yaml` within `agent-kube-state-metrics/resources/`.

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.service.yaml
    ~~~

2. Declare the `Service` in `resources/agent-kube-state-metrics.service.yaml` :

    ~~~yaml
    # Kube State Metrics headless service
    apiVersion: v1
    kind: Service

    metadata:
      name: agent-kube-state-metrics
    spec:
      type: ClusterIP
      clusterIP: None
      ports:
      - name: http-metrics
        port: 8080
        targetPort: http-metrics
      - name: telemetry
        port: 8081
        targetPort: telemetry
    ~~~

    Since every component of this monitoring stack is going to be under the `monitoring` namespace, this headless service's hostname will be `agent-kube-state-metrics.monitoring`.

## Kube State Metrics Kustomize project

Now put together all the declared resources under a `Kustomization` subproject, declared with the corresponding `kustomization.yaml` file:

1. Generate a `kustomization.yaml` file in the `agent-kube-state-metrics` folder:

    ~~~sh
    $ touch $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/kustomization.yaml
    ~~~

2. In the `kustomization.yaml` file, declare the `Kustomization` assembling the Kube State Metrics setup:

    ~~~yaml
    # Kube State Metrics setup
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    labels:
      - pairs:
          app.kubernetes.io/component: exporter
          app.kubernetes.io/name: kube-state-metrics
        includeSelectors: true
        includeTemplates: true

    resources:
    - resources/agent-kube-state-metrics.serviceaccount.yaml
    - resources/agent-kube-state-metrics.clusterrole.yaml
    - resources/agent-kube-state-metrics.clusterrolebinding.yaml
    - resources/agent-kube-state-metrics.deployment.yaml
    - resources/agent-kube-state-metrics.service.yaml

    replicas:
    - name: agent-kube-state-metrics
      count: 1

    images:
    - name: registry.k8s.io/kube-state-metrics/kube-state-metrics
      newTag: v2.18.0
    ~~~

    Under `labels` there are two labels that also appear in the resources declared in [the official standard example for deploying Kube State Metrics](https://github.com/kubernetes/kube-state-metrics/tree/main/examples/standard). Compared with that example, there is one `version` label missing. I have omitted it because it felt redundant and easy to forget when updating the Kube State Metrics image version.

### Validating the Kustomize YAML output

To ensure that is valid, review the complete YAML output of the Kustomize project for your Kube State Metrics deployment:

1. Dump the output of this Kustomize project in a file named `agent-kube-state-metrics.k.output.yaml` (or just redirect it to your preferred text editor):

    ~~~sh
    $ kubectl kustomize $HOME/k8sprjs/monitoring/components/agent-kube-state-metrics > agent-kube-state-metrics.k.output.yaml
    ~~~

2. Open the `agent-kube-state-metrics.k.output.yaml` file and compare your resulting YAML output with the one below:

    ~~~yaml
    apiVersion: v1
    automountServiceAccountToken: false
    kind: ServiceAccount
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
      name: agent-kube-state-metrics
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
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
      - serviceaccounts
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
      - discovery.k8s.io
      resources:
      - endpointslices
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
      - ingressclasses
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
    - apiGroups:
      - rbac.authorization.k8s.io
      resources:
      - clusterrolebindings
      - clusterroles
      - rolebindings
      - roles
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
      type: ClusterIP
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: kube-state-metrics
      name: agent-kube-state-metrics
    spec:
      replicas: 1
      selector:
        matchLabels:
          app.kubernetes.io/component: exporter
          app.kubernetes.io/name: kube-state-metrics
      template:
        metadata:
          labels:
            app.kubernetes.io/component: exporter
            app.kubernetes.io/name: kube-state-metrics
        spec:
          automountServiceAccountToken: true
          containers:
          - image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.18.0
            livenessProbe:
              httpGet:
                path: /livez
                port: http-metrics
              initialDelaySeconds: 5
              timeoutSeconds: 5
            name: agent
            ports:
            - containerPort: 8080
              name: http-metrics
            - containerPort: 8081
              name: telemetry
            readinessProbe:
              httpGet:
                path: /readyz
                port: telemetry
              initialDelaySeconds: 5
              timeoutSeconds: 5
            resources:
              requests:
                cpu: 250m
                memory: 32M
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
              readOnlyRootFilesystem: true
              runAsNonRoot: true
              runAsUser: 65534
              seccompProfile:
                type: RuntimeDefault
          nodeSelector:
            kubernetes.io/os: linux
          serviceAccountName: agent-kube-state-metrics
          tolerations:
          - effect: NoSchedule
            operator: Exists
    ~~~

    The main thing to notice in the output is how the labels and selectors have been automatically applied on the resources.

## Do not deploy this Kube State Metrics project on its own

This Kube State Metrics agent is a component part of a bigger project yet to be completed: your monitoring stack. Wait until reaching the final part of this chapter G035 where you will have every component ready for deploying in your cluster.

## Relevant system paths

### Folders in `kubectl` client system

- `$HOME/k8sprjs/monitoring`
- `$HOME/k8sprjs/monitoring/components`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources`

### Files in `kubectl` client system

- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/kustomization.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrole.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.clusterrolebinding.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.deployment.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.service.yaml`
- `$HOME/k8sprjs/monitoring/components/agent-kube-state-metrics/resources/agent-kube-state-metrics.serviceaccount.yaml`

## References

### [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)

- [GitHub. Kube State Metrics. Standard Kustomize deployment example](https://github.com/kubernetes/kube-state-metrics/tree/main/examples/standard)

- [Kubernetes Documentation. Concepts. Cluster Administration](https://kubernetes.io/docs/concepts/cluster-administration/)
  - [Metrics for Kubernetes Object States](https://kubernetes.io/docs/concepts/cluster-administration/kube-state-metrics/)

### Other Kube State Metrics related contents

- [Kubex. Guide To Kubernetes Tools](https://kubex.ai/kubernetes-tools/)
  - [Guide To Kube-State-Metrics](https://kubex.ai/kubernetes-tools/kube-state-metrics)

- [DevOpsCube. How To Setup Kube State Metrics on Kubernetes](https://devopscube.com/setup-kube-state-metrics/)

- [GitHub. DevOpsCube. Kube state metrics kubernetes deployment configs](https://github.com/devopscube/kube-state-metrics-configs)

### [Kubernetes](https://kubernetes.io/docs/)

#### Security concerns

- [Tasks. Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)
  - [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

- [Reference. API Access Control](https://kubernetes.io/docs/reference/access-authn-authz/)
  - [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

- [Reference. Kubernetes API](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/)
  - [Authentication Resources](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/)
    - [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
  - [Authorization Resources](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/)
    - [ClusterRole](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/)
    - [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/)
  - [Workload Resources](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/)
    - [Pod. Security Context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context-1)

- [Reference. Node Reference Information](https://kubernetes.io/docs/reference/node/)
  - [Seccomp and Kubernetes](https://kubernetes.io/docs/reference/node/seccomp/)

#### Pods Scheduling

- [Concepts. Scheduling, Preemption and Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/)
  - [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

### Other Kubernetes-related contents

#### About security concerns

- [Hackers Vanguard. Abuse Kubernetes with the AutomountServiceAccountToken](https://hackersvanguard.com/abuse-kubernetes-with-the-automountserviceaccounttoken/)

- [Octopus Deploy. Mixing Kubernetes Roles, RoleBindings, ClusterRoles, and ClusterBindings](https://octopus.com/blog/k8s-rbac-roles-and-bindings)

- [GoLinuxCloud. Kubernetes SecurityContext Capabilities Explained [Examples]](https://www.golinuxcloud.com/kubernetes-securitycontext-capabilities/)

#### About pods scheduling

- [Theodo. Working with taints and tolerations in Kubernetes](https://www.theodo.com/en-fr/blog/working-with-taints-and-tolerations-in-kubernetes)

- [GitHub. K3s. Issues. Node taint k3s-controlplane=true:NoExecute](https://github.com/k3s-io/k3s/issues/1401)

## Navigation

[<< Previous (**G035. Deploying services 04. Monitoring stack Part 1**)](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%201%20-%20Outlining%20setup%20and%20arranging%20storage.md) | [+Table Of Contents+](G000%20-%20Table%20Of%20Contents.md) | [Next (**G035. Deploying services 04. Monitoring stack Part 3**) >>](G035%20-%20Deploying%20services%2004%20~%20Monitoring%20stack%20-%20Part%203%20-%20Prometheus%20Node%20Exporter%20service.md)
