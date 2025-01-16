<!--- app-name: controlplane -->


## Parameters

### Redis Database Configuration

1. POLLAND/BUILDQD: 0
2. BACKEND: 1
3. HYDRA: 2



### Chart Configuration

| Name               | Description                                      | Value            |
| ------------------ | ------------------------------------------------ | ---------------- |
| `nameOverride`     | String to override the chart's name              | `""`             |
| `fullnameOverride` | String to override the chart's computed fullname | `""`             |
| `domain`           | Domain name for the installation                 | `domain.example` |

### Credentials Configuration

| Name                   | Description            | Value |
| ---------------------- | ---------------------- | ----- |
| `credentials.registry` | Container registry URL | `""`  |
| `credentials.username` | Registry username      | `""`  |
| `credentials.password` | Registry password      | `""`  |
| `credentials.email`    | Registry email address | `""`  |

### Image Configuration

| Name                | Description                                     | Value                  |
| ------------------- | ----------------------------------------------- | ---------------------- |
| `image.repository`  | Devzero container image repository              | `docker.io/devzeroinc` |
| `image.repository`  | Devzero container image repository              | `docker.io/devzeroinc` |
| `image.tag`         | Devzero container image tag                     | `v1.0.0`               |
| `image.pullPolicy`  | Container pull policy                           | `IfNotPresent`         |
| `image.pullSecrets` | Optionally specify an array of imagePullSecrets | `[]`                   |

### Workspace Configuration

| Name                 | Description                   | Value                                         |
| -------------------- | ----------------------------- | --------------------------------------------- |
| `workspace.image`    | Base image for workspaces     | `public.ecr.aws/v1i4e1r2/devzero-devbox-base` |
| `workspace.localTag` | Tag for local workspace image | `base-latest`                                 |

### Global Configuration

| Name                    | Description            | Value |
| ----------------------- | ---------------------- | ----- |
| `global.podAnnotations` | Global pod annotations | `{}`  |

### Service Account Configuration

| Name                         | Description                                           | Value     |
| ---------------------------- | ----------------------------------------------------- | --------- |
| `serviceAccount.create`      | Specifies whether a service account should be created | `false`   |
| `serviceAccount.annotations` | Annotations to add to the service account             | `{}`      |
| `serviceAccount.name`        | The name of the service account to use                | `devzero` |

### API Gateway Configuration

| Name                                                                         | Description                                           | Value                                                                                                                  |
| ---------------------------------------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `gateway.replicas`                                                           | Number of replicas for Api Gateway                    | `3`                                                                                                                    |
| `gateway.imageName`                                                          | Image name for the API Gateway                        | `api-gateway`                                                                                                          |
| `gateway.schedulerName`                                                      | Optionally set the scheduler for pods                 | `""`                                                                                                                   |
| `gateway.priorityClassName`                                                  | Optionally set the name of the PriorityClass for pods | `""`                                                                                                                   |
| `gateway.nodeSelector`                                                       | NodeSelector to pin pods to certain set of nodes      | `{}`                                                                                                                   |
| `gateway.affinity`                                                           | Pod affinity settings                                 | `{}`                                                                                                                   |
| `gateway.tolerations`                                                        | Pod tolerations                                       | `[]`                                                                                                                   |
| `gateway.podLabels`                                                          | Pod labels                                            | `{}`                                                                                                                   |
| `gateway.podAnnotations`                                                     | Pod annotations                                       | `{}`                                                                                                                   |
| `gateway.annotations`                                                        | Annotations                                           | `{}`                                                                                                                   |
| `gateway.autoscaling.enabled`                                                | Enable autoscaling for Api Gateway                    | `false`                                                                                                                |
| `gateway.autoscaling.minReplicas`                                            | Minimum autoscaling replicas for Api Gateway          | `1`                                                                                                                    |
| `gateway.autoscaling.maxReplicas`                                            | Maximum autoscaling replicas for Api Gateway          | `3`                                                                                                                    |
| `gateway.autoscaling.targetCPUUtilizationPercentage`                         | Target CPU utilisation percentage for Api Gateway     | `60`                                                                                                                   |
| `gateway.autoscaling.targetMemoryUtilizationPercentage`                      | Target memory utilisation percentage for Api Gateway  | `80`                                                                                                                   |
| `gateway.resources.limits.cpu`                                               | CPU limit for Api Gateway                             | `1000m`                                                                                                                |
| `gateway.resources.limits.memory`                                            | Memory limit for Api Gateway                          | `1Gi`                                                                                                                  |
| `gateway.resources.requests.cpu`                                             | CPU request for Api Gateway                           | `100m`                                                                                                                 |
| `gateway.resources.requests.memory`                                          | Memory request for Api Gateway                        | `128Mi`                                                                                                                |
| `gateway.service.port`                                                       | Port of the Api Gateway service                       | `8443`                                                                                                                 |
| `gateway.service.metricsPort`                                                | Port of the Api Gateway Metrics service               | `9090`                                                                                                                 |
| `gateway.service.type`                                                       | Type of the Api Gateway service                       | `ClusterIP`                                                                                                            |
| `gateway.service.annotations`                                                | Annotations for the Api Gateway service               | `{}`                                                                                                                   |
| `gateway.service.labels`                                                     | Labels for the Api Gateway service                    | `{}`                                                                                                                   |
| `gateway.ingress.enabled`                                                    | Specify if the Api Gateway Ingress is enabled         | `enable`                                                                                                               |
| `gateway.ingress.ingressClassName`                                           | Ingress Class Name. May be required for k8s >= 1.18   | `nginx`                                                                                                                |
| `gateway.ingress.annotations.cert-manager.io/cluster-issuer`                 | Certificate issuer for ingress                        | `letsencrypt-self-hosted`                                                                                              |
| `gateway.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect` | Force SSL redirect for ingress                        | `{"cert-manager.io/cluster-issuer":"letsencrypt-self-hosted","nginx.ingress.kubernetes.io/force-ssl-redirect":"true"}` |
| `gateway.ingress.tls[0].secretName`                                          | TLS secret name for ingress                           | `devzero-api-tls`                                                                                                      |
| `gateway.ingress.tls[0].hosts`                                               | List of TLS hosts for ingress                         | `["api.{{ .Values.domain }}"]`                                                                                         |
| `gateway.ingress.hosts[0].host`                                              | Host name for ingress                                 | `api.{{ .Values.domain }}`                                                                                             |
| `gateway.ingress.hosts[0].paths[0].path`                                     | Path for ingress route                                | `/`                                                                                                                    |
| `gateway.ingress.hosts[0].paths[0].pathType`                                 | Path type for ingress route                           | `Prefix`                                                                                                               |

### Backend Configuration

| Name                                                    | Description                                           | Value                                                                                                      |
| ------------------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `backend.replicas`                                      | Number of replicas for Backend                        | `1`                                                                                                        |
| `backend.imageName`                                     | Image name for Backend service                        | `backend`                                                                                                  |
| `backend.schedulerName`                                 | Optionally set the scheduler for pods                 | `""`                                                                                                       |
| `backend.priorityClassName`                             | Optionally set the name of the PriorityClass for pods | `""`                                                                                                       |
| `backend.nodeSelector`                                  | NodeSelector to pin pods to certain set of nodes      | `{}`                                                                                                       |
| `backend.affinity`                                      | Pod affinity settings                                 | `{}`                                                                                                       |
| `backend.tolerations`                                   | Pod tolerations                                       | `[]`                                                                                                       |
| `backend.podLabels`                                     | Pod labels                                            | `{}`                                                                                                       |
| `backend.podAnnotations`                                | Pod annotations                                       | `{}`                                                                                                       |
| `backend.annotations`                                   | Annotations                                           | `{}`                                                                                                       |
| `backend.redis.url`                                     | Redis URL for Backend                                 | `redis://redis-headless:6379/1`                                                                            |
| `backend.redis.password`                                | Redis password for Backend                            | `""`                                                                                                       |
| `backend.mongo.url`                                     | MongoDB connection URL                                | `mongodb://devzero:backend@devzero-mongodb-0.devzero-mongodb-headless:27017/backend?directConnection=true` |
| `backend.hydra.apiKey`                                  | API key for Hydra service                             | `""`                                                                                                       |
| `backend.logsrv.queue`                                  | LogSrv queue URL                                      | `http://devzero-elasticmq:9324/queue/logsrv.fifo`                                                          |
| `backend.logsrv.region`                                 | LogSrv region                                         | `elasticmq`                                                                                                |
| `backend.github.appId`                                  | GitHub App ID                                         | `""`                                                                                                       |
| `backend.github.appPrivateKey`                          | GitHub App Private Key                                | `""`                                                                                                       |
| `backend.mimir.url`                                     | Mimir service URL                                     | `http://mimir:8080/prometheus`                                                                             |
| `backend.hibernation.enabled`                           | Enable hibernation feature                            | `false`                                                                                                    |
| `backend.sendgrid.apiKey`                               | SendGrid API Key                                      | `test-key`                                                                                                 |
| `backend.grafana.enabled`                               | Enable Grafana integration                            | `true`                                                                                                     |
| `backend.grafana.datasourceId`                          | Main datasource ID                                    | `mimir`                                                                                                    |
| `backend.grafana.doraDatasourceId`                      | DORA metrics datasource ID                            | `pulse`                                                                                                    |
| `backend.grafana.odaDatasourceId`                       | ODA metrics datasource ID                             | `timescale`                                                                                                |
| `backend.grafana.password`                              | Grafana password                                      | `prom-operator`                                                                                            |
| `backend.storage.allowedTeam`                           | Allowed team ID for storage access                    | `team-example-id`                                                                                          |
| `backend.storage.ceph.clusterId`                        | Ceph cluster ID                                       | `""`                                                                                                       |
| `backend.storage.ceph.filesystemName`                   | Ceph filesystem name                                  | `cephfs`                                                                                                   |
| `backend.storage.ceph.filesystemPath`                   | Ceph filesystem path                                  | `cephfs`                                                                                                   |
| `backend.storage.ceph.monitorAddress`                   | Ceph monitor address                                  | `/volumes/cache`                                                                                           |
| `backend.storage.ceph.userCredentials`                  | Ceph user credentials                                 | `""`                                                                                                       |
| `backend.storage.ceph.username`                         | Ceph username                                         | `vuser`                                                                                                    |
| `backend.mainTeamId`                                    | Main team ID                                          | `""`                                                                                                       |
| `backend.licenseKey`                                    | License key                                           | `""`                                                                                                       |
| `backend.arch`                                          | Architecture type                                     | `amd64`                                                                                                    |
| `backend.cortex.key`                                    | Cortex key                                            | `""`                                                                                                       |
| `backend.autoscaling.enabled`                           | Enable autoscaling for Backend                        | `false`                                                                                                    |
| `backend.autoscaling.minReplicas`                       | Minimum autoscaling replicas for Backend              | `1`                                                                                                        |
| `backend.autoscaling.maxReplicas`                       | Maximum autoscaling replicas for Backend              | `3`                                                                                                        |
| `backend.autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilisation percentage for Backend         | `60`                                                                                                       |
| `backend.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilisation percentage for Backend      | `80`                                                                                                       |
| `backend.resources.limits.cpu`                          | CPU resource limits for Backend                       | `1000m`                                                                                                    |
| `backend.resources.limits.memory`                       | Memory resource limits for Backend                    | `1Gi`                                                                                                      |
| `backend.resources.requests.cpu`                        | CPU resource requests for Backend                     | `100m`                                                                                                     |
| `backend.resources.requests.memory`                     | Memory resource requests for Backend                  | `128Mi`                                                                                                    |
| `backend.service.port`                                  | Port of the Backend service                           | `8443`                                                                                                     |
| `backend.service.metricsPort`                           | Port of the Backend Metrics service                   | `9090`                                                                                                     |
| `backend.service.type`                                  | Type of the Backend service                           | `ClusterIP`                                                                                                |
| `backend.service.annotations`                           | Annotations for the Backend service                   | `{}`                                                                                                       |
| `backend.service.labels`                                | Labels for the Backend service                        | `{}`                                                                                                       |

### Hydra Configuration

| Name                                                                       | Description                                           | Value                                                                                                                  |
| -------------------------------------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `hydra.replicas`                                                           | Number of replicas for Hydra                          | `1`                                                                                                                    |
| `hydra.imageName`                                                          | Image name for Hydra service                          | `hydra`                                                                                                                |
| `hydra.schedulerName`                                                      | Optionally set the scheduler for pods                 | `""`                                                                                                                   |
| `hydra.priorityClassName`                                                  | Optionally set the name of the PriorityClass for pods | `""`                                                                                                                   |
| `hydra.nodeSelector`                                                       | NodeSelector to pin pods to certain set of nodes      | `{}`                                                                                                                   |
| `hydra.affinity`                                                           | Pod affinity settings                                 | `{}`                                                                                                                   |
| `hydra.tolerations`                                                        | Pod tolerations                                       | `[]`                                                                                                                   |
| `hydra.podLabels`                                                          | Pod labels                                            | `{}`                                                                                                                   |
| `hydra.podAnnotations`                                                     | Pod annotations                                       | `{}`                                                                                                                   |
| `hydra.annotations`                                                        | Annotations                                           | `{}`                                                                                                                   |
| `hydra.job`                                                                | Enable job mode                                       | `true`                                                                                                                 |
| `hydra.postgres.host`                                                      | PostgreSQL host                                       | `postgres-hydra-postgresql-hl`                                                                                         |
| `hydra.postgres.port`                                                      | PostgreSQL port                                       | `5432`                                                                                                                 |
| `hydra.postgres.name`                                                      | PostgreSQL database name                              | `postgres`                                                                                                             |
| `hydra.postgres.user`                                                      | PostgreSQL user                                       | `hydra`                                                                                                                |
| `hydra.postgres.password`                                                  | PostgreSQL password                                   | `hydra`                                                                                                                |
| `hydra.redis.url`                                                          | Redis URL for Hydra                                   | `redis://redis-headless:6379/2`                                                                                        |
| `hydra.cidr.v6`                                                            | IPv6 CIDR range                                       | `fd7a:115c:a1e0::/48`                                                                                                  |
| `hydra.cidr.v4`                                                            | IPv4 CIDR range                                       | `100.64.0.0/10`                                                                                                        |
| `hydra.derp.server.enabled`                                                | Enable DERP server                                    | `false`                                                                                                                |
| `hydra.derp.urls`                                                          | DERP server URLs                                      | `["https://controlplane.tailscale.com/derpmap/default"]`                                                               |
| `hydra.derp.paths`                                                         | DERP paths                                            | `[]`                                                                                                                   |
| `hydra.derp.autoUpdateEnabled`                                             | Enable auto-update for DERP                           | `true`                                                                                                                 |
| `hydra.derp.updateFrequency`                                               | Update frequency for DERP                             | `24h`                                                                                                                  |
| `hydra.autoscaling.enabled`                                                | Enable autoscaling for Hydra                          | `false`                                                                                                                |
| `hydra.autoscaling.minReplicas`                                            | Minimum autoscaling replicas for Hydra                | `1`                                                                                                                    |
| `hydra.autoscaling.maxReplicas`                                            | Maximum autoscaling replicas for Hydra                | `3`                                                                                                                    |
| `hydra.autoscaling.targetCPUUtilizationPercentage`                         | Target CPU utilisation percentage for Hydra           | `60`                                                                                                                   |
| `hydra.autoscaling.targetMemoryUtilizationPercentage`                      | Target memory utilisation percentage for Hydra        | `80`                                                                                                                   |
| `hydra.resources.limits.cpu`                                               | CPU resource limits for Hydra                         | `1000m`                                                                                                                |
| `hydra.resources.limits.memory`                                            | Memory resource limits for Hydra                      | `1Gi`                                                                                                                  |
| `hydra.resources.requests.cpu`                                             | CPU resource requests for Hydra                       | `100m`                                                                                                                 |
| `hydra.resources.requests.memory`                                          | Memory resource requests for Hydra                    | `128Mi`                                                                                                                |
| `hydra.service.port`                                                       | Port of the Hydra service                             | `8443`                                                                                                                 |
| `hydra.service.metricsPort`                                                | Port of the Hydra Metrics service                     | `9090`                                                                                                                 |
| `hydra.service.type`                                                       | Type of the Hydra service                             | `ClusterIP`                                                                                                            |
| `hydra.service.annotations`                                                | Annotations for the Hydra service                     | `{}`                                                                                                                   |
| `hydra.service.labels`                                                     | Labels for the Hydra service                          | `{}`                                                                                                                   |
| `hydra.ingress.enabled`                                                    | Specify if the Hydra Ingress is enabled               | `true`                                                                                                                 |
| `hydra.ingress.ingressClassName`                                           | Ingress Class Name                                    | `nginx`                                                                                                                |
| `hydra.ingress.annotations.cert-manager.io/cluster-issuer`                 | Certificate issuer for ingress                        | `letsencrypt-self-hosted`                                                                                              |
| `hydra.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect` | Force SSL redirect for ingress                        | `{"cert-manager.io/cluster-issuer":"letsencrypt-self-hosted","nginx.ingress.kubernetes.io/force-ssl-redirect":"true"}` |
| `hydra.ingress.tls[0].secretName`                                          | TLS secret name for ingress                           | `devzero-hydra-tls`                                                                                                    |
| `hydra.ingress.tls[0].hosts`                                               | List of TLS hosts for ingress                         | `["hydra.{{ .Values.domain }}"]`                                                                                       |
| `hydra.ingress.hosts[0].host`                                              | Host name for ingress                                 | `hydra.{{ .Values.domain }}`                                                                                           |
| `hydra.ingress.hosts[0].paths[0].path`                                     | Path for ingress route                                | `/`                                                                                                                    |
| `hydra.ingress.hosts[0].paths[0].pathType`                                 | Path type for ingress route                           | `Prefix`                                                                                                               |

### LogSrv Configuration

| Name                                                                        | Description                          | Value                                                                                                                  |
| --------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `logsrv.replicas`                                                           | Number of replicas for LogSrv        | `1`                                                                                                                    |
| `logsrv.imageName`                                                          | Image name for LogSrv                | `logsrv`                                                                                                               |
| `logsrv.schedulerName`                                                      | Scheduler name for LogSrv pods       | `""`                                                                                                                   |
| `logsrv.priorityClassName`                                                  | Priority class name for LogSrv pods  | `""`                                                                                                                   |
| `logsrv.nodeSelector`                                                       | Node selector for LogSrv pods        | `{}`                                                                                                                   |
| `logsrv.affinity`                                                           | Affinity settings for LogSrv pods    | `{}`                                                                                                                   |
| `logsrv.tolerations`                                                        | Tolerations for LogSrv pods          | `[]`                                                                                                                   |
| `logsrv.podLabels`                                                          | Pod labels for LogSrv                | `{}`                                                                                                                   |
| `logsrv.podAnnotations`                                                     | Pod annotations for LogSrv           | `{}`                                                                                                                   |
| `logsrv.annotations`                                                        | Annotations for LogSrv               | `{}`                                                                                                                   |
| `logsrv.queue.url`                                                          | Queue URL for LogSrv                 | `http://devzero-elasticmq:9324/queue/logsrv.fifo`                                                                      |
| `logsrv.postgres.url`                                                       | PostgreSQL URL for LogSrv            | `postgresql://logsrv:logsrv@postgres-logsrv-postgresql-hl:5432/logsrv`                                                 |
| `logsrv.postgres.password`                                                  | PostgreSQL password for LogSrv       | `logsrv`                                                                                                               |
| `logsrv.refreshJwksTimer`                                                   | JWKS refresh timer in seconds        | `3600`                                                                                                                 |
| `logsrv.autoscaling.enabled`                                                | Enable autoscaling for LogSrv        | `false`                                                                                                                |
| `logsrv.autoscaling.minReplicas`                                            | Minimum replicas for LogSrv          | `1`                                                                                                                    |
| `logsrv.autoscaling.maxReplicas`                                            | Maximum replicas for LogSrv          | `3`                                                                                                                    |
| `logsrv.autoscaling.targetCPUUtilizationPercentage`                         | Target CPU utilization percentage    | `60`                                                                                                                   |
| `logsrv.autoscaling.targetMemoryUtilizationPercentage`                      | Target memory utilization percentage | `80`                                                                                                                   |
| `logsrv.resources.limits.cpu`                                               | CPU resource limits for LogSrv       | `1000m`                                                                                                                |
| `logsrv.resources.limits.memory`                                            | Memory resource limits for LogSrv    | `1Gi`                                                                                                                  |
| `logsrv.resources.requests.cpu`                                             | CPU resource requests for LogSrv     | `100m`                                                                                                                 |
| `logsrv.resources.requests.memory`                                          | Memory resource requests for LogSrv  | `128Mi`                                                                                                                |
| `logsrv.service.port`                                                       | Service port for LogSrv              | `8443`                                                                                                                 |
| `logsrv.service.metricsPort`                                                | Metrics port for LogSrv              | `9090`                                                                                                                 |
| `logsrv.service.type`                                                       | Service type for LogSrv              | `ClusterIP`                                                                                                            |
| `logsrv.service.annotations`                                                | Service annotations for LogSrv       | `{}`                                                                                                                   |
| `logsrv.service.labels`                                                     | Service labels for LogSrv            | `{}`                                                                                                                   |
| `logsrv.ingress.enabled`                                                    | Enable ingress for LogSrv            | `true`                                                                                                                 |
| `logsrv.ingress.ingressClassName`                                           | Ingress class name for LogSrv        | `nginx`                                                                                                                |
| `logsrv.ingress.annotations.cert-manager.io/cluster-issuer`                 | Certificate issuer for ingress       | `letsencrypt-self-hosted`                                                                                              |
| `logsrv.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect` | Force SSL redirect for ingress       | `{"cert-manager.io/cluster-issuer":"letsencrypt-self-hosted","nginx.ingress.kubernetes.io/force-ssl-redirect":"true"}` |
| `logsrv.ingress.tls[0].secretName`                                          | TLS secret name for ingress          | `devzero-logsrv-tls`                                                                                                   |
| `logsrv.ingress.tls[0].hosts`                                               | List of TLS hosts for ingress        | `["logsrv.{{ .Values.domain }}"]`                                                                                      |
| `logsrv.ingress.hosts[0].host`                                              | Host name for ingress                | `logsrv.{{ .Values.domain }}`                                                                                          |
| `logsrv.ingress.hosts[0].paths[0].path`                                     | Path for ingress route               | `/`                                                                                                                    |
| `logsrv.ingress.hosts[0].paths[0].pathType`                                 | Path type for ingress route          | `Prefix`                                                                                                               |

### Polland Configuration

| Name                                                    | Description                                      | Value                                             |
| ------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------- |
| `polland.worker.replicas`                               | Number of replicas for Polland Worker            | `3`                                               |
| `polland.worker.terminationGracePeriodSeconds`          | Termination grace period in seconds              | `3600`                                            |
| `polland.worker.queues[0].name`                         | Configuration for the fast queue                 | `fast`                                            |
| `polland.worker.queues[0].replicaCount`                 | Number of replicas for queue                     | `1`                                               |
| `polland.worker.queues[0].autoscaling.enabled`          | Enable autoscaling for queue                     | `false`                                           |
| `polland.worker.queues[0].autoscaling.minReplicas`      | Minimum autoscaling replicas for queue           | `3`                                               |
| `polland.worker.queues[0].autoscaling.maxReplicas`      | Maximum autoscaling replicas for queue           | `5`                                               |
| `polland.worker.queues[1].name`                         | Configuration for the build queue                | `build`                                           |
| `polland.worker.queues[1].replicaCount`                 | Number of replicas for queue                     | `1`                                               |
| `polland.worker.queues[1].autoscaling.enabled`          | Enable autoscaling for queue                     | `false`                                           |
| `polland.worker.queues[1].autoscaling.minReplicas`      | Minimum autoscaling replicas for queue           | `3`                                               |
| `polland.worker.queues[1].autoscaling.maxReplicas`      | Maximum autoscaling replicas for queue           | `5`                                               |
| `polland.worker.queues[2].name`                         | Configuration for the workload queue             | `workload`                                        |
| `polland.worker.queues[2].replicaCount`                 | Number of replicas for queue                     | `1`                                               |
| `polland.worker.queues[2].autoscaling.enabled`          | Enable autoscaling for queue                     | `false`                                           |
| `polland.worker.queues[2].autoscaling.minReplicas`      | Minimum autoscaling replicas for queue           | `3`                                               |
| `polland.worker.queues[2].autoscaling.maxReplicas`      | Maximum autoscaling replicas for queue           | `5`                                               |
| `polland.worker.queues[3].name`                         | Configuration for the cluster queue              | `cluster`                                         |
| `polland.worker.queues[3].replicaCount`                 | Number of replicas for queue                     | `1`                                               |
| `polland.worker.queues[3].autoscaling.enabled`          | Enable autoscaling for queue                     | `false`                                           |
| `polland.worker.queues[3].autoscaling.minReplicas`      | Minimum autoscaling replicas for queue           | `3`                                               |
| `polland.worker.queues[3].autoscaling.maxReplicas`      | Maximum autoscaling replicas for queue           | `5`                                               |
| `polland.worker.queues[4].name`                         | Configuration for the hibernation queue          | `hibernation`                                     |
| `polland.worker.queues[4].replicaCount`                 | Number of replicas for queue                     | `1`                                               |
| `polland.worker.queues[4].autoscaling.enabled`          | Enable autoscaling for queue                     | `false`                                           |
| `polland.worker.queues[4].autoscaling.minReplicas`      | Minimum autoscaling replicas for queue           | `1`                                               |
| `polland.worker.queues[4].autoscaling.maxReplicas`      | Maximum autoscaling replicas for queue           | `1`                                               |
| `polland.beat.replicas`                                 | Number of replicas for Polland Beat              | `1`                                               |
| `polland.flower.replicas`                               | Number of replicas for Polland Flower            | `1`                                               |
| `polland.flower.service.port`                           | Port for Flower service                          | `5555`                                            |
| `polland.flower.service.type`                           | Type of Flower service                           | `ClusterIP`                                       |
| `polland.celeryExporter.replicas`                       | Number of replicas for Celery Exporter           | `1`                                               |
| `polland.replicas`                                      | Number of replicas for Polland                   | `1`                                               |
| `polland.imageName`                                     | Image name for Polland                           | `polland`                                         |
| `polland.schedulerName`                                 | Scheduler name for Polland pods                  | `""`                                              |
| `polland.priorityClassName`                             | Priority class name for Polland pods             | `""`                                              |
| `polland.nodeSelector`                                  | Node selector for Polland pods                   | `{}`                                              |
| `polland.affinity`                                      | Affinity settings for Polland pods               | `{}`                                              |
| `polland.tolerations`                                   | Tolerations for Polland pods                     | `[]`                                              |
| `polland.podLabels`                                     | Pod labels for Polland                           | `{}`                                              |
| `polland.podAnnotations`                                | Pod annotations for Polland                      | `{}`                                              |
| `polland.annotations`                                   | Annotations for Polland                          | `{}`                                              |
| `polland.env.USE_POSTGRES_DB`                           | Use PostgreSQL database                          | `true`                                            |
| `polland.env.POSTGRES_PORT`                             | PostgreSQL port                                  | `5432`                                            |
| `polland.env.POSTGRES_DB`                               | PostgreSQL database name                         | `polland`                                         |
| `polland.env.POSTGRES_USER`                             | PostgreSQL user                                  | `polland`                                         |
| `polland.env.POSTGRES_PASSWORD`                         | PostgreSQL password                              | `polland`                                         |
| `polland.env.POSTGRES_HOST`                             | PostgreSQL host                                  | `postgres-polland-postgresql-hl`                  |
| `polland.env.REDIS_URL`                                 | Redis URL                                        | `redis://redis-headless:6379/0`                   |
| `polland.env.USE_DOCKER`                                | Use Docker                                       | `yes`                                             |
| `polland.env.CONN_MAX_AGE`                              | Connection max age                               | `60`                                              |
| `polland.env.DJANGO_ALLOWED_HOSTS`                      | Allowed hosts for Django                         | `*`                                               |
| `polland.env.DJANGO_SETTINGS_MODULE`                    | Django settings module                           | `config.settings.production`                      |
| `polland.env.DJANGO_SECRET_KEY`                         | Django secret key                                | `super_secret_key`                                |
| `polland.env.CELERY_FLOWER_USER`                        | Celery Flower user                               | `devzero`                                         |
| `polland.env.CELERY_FLOWER_PASSWORD`                    | Celery Flower password                           | `devzero`                                         |
| `polland.env.SELF_HOSTED`                               | Self-hosted mode                                 | `True`                                            |
| `polland.env.USE_INSECURE_REGISTRY`                     | Use insecure registry                            | `True`                                            |
| `polland.env.USE_ECR_REGISTRY`                          | Use ECR registry                                 | `False`                                           |
| `polland.env.USE_LOCAL_LOGSRV`                          | Use local LogSrv                                 | `True`                                            |
| `polland.env.VAULT_AUTH_METHOD`                         | Vault auth method                                | `kubernetes`                                      |
| `polland.env.VAULT_SECRETS_MOUNT_POINT`                 | Vault secrets mount point                        | `vault-csi-production-writer`                     |
| `polland.env.LOGSRV_DEFAULT_QUEUE`                      | Default LogSrv queue URL                         | `http://devzero-elasticmq:9324/queue/logsrv.fifo` |
| `polland.env.LOGSRV_DEFAULT_REGION`                     | Default LogSrv region                            | `elasticmq`                                       |
| `polland.autoscaling.enabled`                           | Enable autoscaling for Polland                   | `false`                                           |
| `polland.autoscaling.minReplicas`                       | Minimum autoscaling replicas for Polland         | `1`                                               |
| `polland.autoscaling.maxReplicas`                       | Maximum autoscaling replicas for Polland         | `3`                                               |
| `polland.autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilisation percentage for Polland    | `60`                                              |
| `polland.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilisation percentage for Polland | `80`                                              |
| `polland.resources.limits.cpu`                          | CPU resource limits for Polland                  | `1000m`                                           |
| `polland.resources.limits.memory`                       | Memory resource limits for Polland               | `1Gi`                                             |
| `polland.resources.requests.cpu`                        | CPU resource requests for Polland                | `100m`                                            |
| `polland.resources.requests.memory`                     | Memory resource requests for Polland             | `128Mi`                                           |
| `polland.service.port`                                  | Port of the Polland service                      | `8000`                                            |
| `polland.service.metricsPort`                           | Port of the Polland Metrics service              | `9090`                                            |
| `polland.service.type`                                  | Type of the Polland service                      | `ClusterIP`                                       |
| `polland.service.annotations`                           | Annotations for the Polland service              | `{}`                                              |
| `polland.service.labels`                                | Labels for the Polland service                   | `{}`                                              |

### Pulse Configuration

| Name                                                                       | Description                                         | Value                                                                                                                  |
| -------------------------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `pulse.replicas`                                                           | Number of replicas for Pulse                        | `1`                                                                                                                    |
| `pulse.imageName`                                                          | Image name for Pulse                                | `pulse`                                                                                                                |
| `pulse.schedulerName`                                                      | Scheduler name for Pulse pods                       | `""`                                                                                                                   |
| `pulse.priorityClassName`                                                  | Priority class name for Pulse pods                  | `""`                                                                                                                   |
| `pulse.nodeSelector`                                                       | Node selector for Pulse pods                        | `{}`                                                                                                                   |
| `pulse.affinity`                                                           | Affinity settings for Pulse pods                    | `{}`                                                                                                                   |
| `pulse.tolerations`                                                        | Tolerations for Pulse pods                          | `[]`                                                                                                                   |
| `pulse.podLabels`                                                          | Pod labels for Pulse                                | `{}`                                                                                                                   |
| `pulse.podAnnotations`                                                     | Pod annotations for Pulse                           | `{}`                                                                                                                   |
| `pulse.annotations`                                                        | Annotations for Pulse                               | `{}`                                                                                                                   |
| `pulse.postgres.password`                                                  | PostgreSQL password for Pulse                       | `pulse`                                                                                                                |
| `pulse.postgres.user`                                                      | PostgreSQL user for Pulse                           | `postgres`                                                                                                             |
| `pulse.postgres.host`                                                      | PostgreSQL host for Pulse                           | `timescaledb-single`                                                                                                   |
| `pulse.postgres.port`                                                      | PostgreSQL port for Pulse                           | `5432`                                                                                                                 |
| `pulse.postgres.database`                                                  | PostgreSQL database for Pulse                       | `postgres`                                                                                                             |
| `pulse.postgres.ssl`                                                       | SSL mode for PostgreSQL                             | `allow`                                                                                                                |
| `pulse.mysql.user`                                                         | MySQL user for Pulse                                | `pulse`                                                                                                                |
| `pulse.mysql.password`                                                     | MySQL password for Pulse                            | `pulse`                                                                                                                |
| `pulse.mysql.host`                                                         | MySQL host for Pulse                                | `mysql-pulse-headless`                                                                                                 |
| `pulse.mysql.port`                                                         | MySQL port for Pulse                                | `3306`                                                                                                                 |
| `pulse.mysql.database`                                                     | MySQL database for Pulse                            | `pulse`                                                                                                                |
| `pulse.devlake.secret`                                                     | Devlake secret for Pulse                            | `""`                                                                                                                   |
| `pulse.openApi.token`                                                      | OpenAPI token for Pulse                             | `""`                                                                                                                   |
| `pulse.autoscaling.enabled`                                                | Enable autoscaling for Pulse                        | `false`                                                                                                                |
| `pulse.autoscaling.minReplicas`                                            | Minimum autoscaling replicas for Pulse              | `1`                                                                                                                    |
| `pulse.autoscaling.maxReplicas`                                            | Maximum autoscaling replicas for Pulse              | `3`                                                                                                                    |
| `pulse.autoscaling.targetCPUUtilizationPercentage`                         | Target CPU utilisation percentage for Pulse         | `60`                                                                                                                   |
| `pulse.autoscaling.targetMemoryUtilizationPercentage`                      | Target memory utilisation percentage for Pulse      | `80`                                                                                                                   |
| `pulse.resources.limits.cpu`                                               | CPU resource limits for Pulse                       | `1000m`                                                                                                                |
| `pulse.resources.limits.memory`                                            | Memory resource limits for Pulse                    | `1Gi`                                                                                                                  |
| `pulse.resources.requests.cpu`                                             | CPU resource requests for Pulse                     | `100m`                                                                                                                 |
| `pulse.resources.requests.memory`                                          | Memory resource requests for Pulse                  | `128Mi`                                                                                                                |
| `pulse.service.port`                                                       | Port of the Pulse service                           | `8443`                                                                                                                 |
| `pulse.service.metricsPort`                                                | Port of the Pulse Metrics service                   | `9090`                                                                                                                 |
| `pulse.service.type`                                                       | Type of the Pulse service                           | `ClusterIP`                                                                                                            |
| `pulse.service.annotations`                                                | Annotations for the Pulse service                   | `{}`                                                                                                                   |
| `pulse.service.labels`                                                     | Labels for the Pulse service                        | `{}`                                                                                                                   |
| `pulse.ingress.enabled`                                                    | Specify if the Pulse Ingress is enabled             | `true`                                                                                                                 |
| `pulse.ingress.ingressClassName`                                           | Ingress Class Name. May be required for k8s >= 1.18 | `nginx`                                                                                                                |
| `pulse.ingress.annotations.cert-manager.io/cluster-issuer`                 | Cluster issuer for ingress                          | `letsencrypt-self-hosted`                                                                                              |
| `pulse.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect` | Force SSL redirect for ingress                      | `{"cert-manager.io/cluster-issuer":"letsencrypt-self-hosted","nginx.ingress.kubernetes.io/force-ssl-redirect":"true"}` |
| `pulse.ingress.tls[0].secretName`                                          | TLS secret name for ingress                         | `devzero-pulse-tls`                                                                                                    |
| `pulse.ingress.tls[0].hosts`                                               | List of TLS hosts for ingress                       | `["pulse.{{ .Values.domain }}"]`                                                                                       |
| `pulse.ingress.hosts[0].host`                                              | Host name for ingress                               | `pulse.{{ .Values.domain }}`                                                                                           |
| `pulse.ingress.hosts[0].paths[0].path`                                     | Path for ingress                                    | `/`                                                                                                                    |
| `pulse.ingress.hosts[0].paths[0].pathType`                                 | Path type for ingress                               | `Prefix`                                                                                                               |

### Buildqd Configuration

| Name                                                    | Description                                      | Value                                                                            |
| ------------------------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------- |
| `buildqd.replicas`                                      | Number of replicas for Buildqd                   | `1`                                                                              |
| `buildqd.imageName`                                     | Image name for Buildqd                           | `buildqd`                                                                        |
| `buildqd.schedulerName`                                 | Scheduler name for Buildqd pods                  | `""`                                                                             |
| `buildqd.priorityClassName`                             | Priority class name for Buildqd pods             | `""`                                                                             |
| `buildqd.nodeSelector`                                  | Node selector for Buildqd pods                   | `{}`                                                                             |
| `buildqd.affinity`                                      | Affinity settings for Buildqd pods               | `{}`                                                                             |
| `buildqd.tolerations`                                   | Tolerations for Buildqd pods                     | `[]`                                                                             |
| `buildqd.logsrv.queue`                                  | Queue URL for LogSrv                             | `http://devzero-elasticmq:9324/queue/logsrv.fifo`                                |
| `buildqd.logsrv.region`                                 | Region for LogSrv                                | `elasticmq`                                                                      |
| `buildqd.redis.url`                                     | Redis URL for Buildqd                            | `redis://redis-headless:6379/0`                                                  |
| `buildqd.autoscaling.enabled`                           | Enable autoscaling for Buildqd                   | `false`                                                                          |
| `buildqd.autoscaling.minReplicas`                       | Minimum autoscaling replicas for Buildqd         | `1`                                                                              |
| `buildqd.autoscaling.maxReplicas`                       | Maximum autoscaling replicas for Buildqd         | `3`                                                                              |
| `buildqd.autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilisation percentage for Buildqd    | `60`                                                                             |
| `buildqd.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilisation percentage for Buildqd | `80`                                                                             |
| `buildqd.resources.limits.cpu`                          | CPU resource limits for Buildqd                  | `1000m`                                                                          |
| `buildqd.resources.limits.memory`                       | Memory resource limits for Buildqd               | `1Gi`                                                                            |
| `buildqd.resources.requests.cpu`                        | CPU resource requests for Buildqd                | `100m`                                                                           |
| `buildqd.resources.requests.memory`                     | Memory resource requests for Buildqd             | `128Mi`                                                                          |
| `buildqd.service.port`                                  | Port of the Buildqd service                      | `8443`                                                                           |
| `buildqd.service.metricsPort`                           | Port of the Buildqd Metrics service              | `9090`                                                                           |
| `buildqd.service.type`                                  | Type of the Buildqd service                      | `ClusterIP`                                                                      |
| `buildqd.service.annotations`                           | Annotations for the Buildqd service              | `{}`                                                                             |
| `buildqd.service.labels`                                | Labels for the Buildqd service                   | `{}`                                                                             |
| `buildqd.buildkit.image.repository`                     | Buildkit repository                              | `docker.io/moby/buildkit`                                                        |
| `buildqd.buildkit.image.pullPolicy`                     | Buildkit image policy                            | `IfNotPresent`                                                                   |
| `buildqd.buildkit.image.tag`                            | Buildkit image tag                               | `v0.15.1`                                                                        |
| `buildqd.buildkit.securityContext.privileged`           | Privileged mode for Buildkit container           | `true`                                                                           |
| `buildqd.buildkit.command`                              | Buildkit command                                 | `buildkitd`                                                                      |
| `buildqd.buildkit.args`                                 | Buildkit args                                    | `["--addr","unix:///run/buildkit/buildkitd.sock","--addr","tcp://0.0.0.0:1234"]` |
| `buildqd.buildkit.resources.limits.cpu`                 | CPU resource limits for Buildkit                 | `1000m`                                                                          |
| `buildqd.buildkit.resources.limits.memory`              | Memory resource limits for Buildkit              | `1Gi`                                                                            |
| `buildqd.buildkit.resources.requests.cpu`               | CPU resource requests for Buildkit               | `100m`                                                                           |
| `buildqd.buildkit.resources.requests.memory`            | Memory resource requests for Buildkit            | `128Mi`                                                                          |
| `buildqd.buildkit.persistentVolumeClaim.storageSize`    | Storage size for Buildkit shared cache           | `100Gi`                                                                          |

### Web Configuration

| Name                                                                     | Description                                         | Value                                                                                                                  |
| ------------------------------------------------------------------------ | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `web.replicas`                                                           | Number of replicas for Web                          | `1`                                                                                                                    |
| `web.imageName`                                                          | Image name for Web                                  | `web`                                                                                                                  |
| `web.schedulerName`                                                      | Scheduler name for Web pods                         | `""`                                                                                                                   |
| `web.priorityClassName`                                                  | Priority class name for Web pods                    | `""`                                                                                                                   |
| `web.nodeSelector`                                                       | Node selector for Web pods                          | `{}`                                                                                                                   |
| `web.affinity`                                                           | Affinity settings for Web pods                      | `{}`                                                                                                                   |
| `web.tolerations`                                                        | Tolerations for Web pods                            | `[]`                                                                                                                   |
| `web.podLabels`                                                          | Pod labels for Web                                  | `{}`                                                                                                                   |
| `web.podAnnotations`                                                     | Pod annotations for Web                             | `{}`                                                                                                                   |
| `web.annotations`                                                        | Annotations for Web                                 | `{}`                                                                                                                   |
| `web.env.NEXT_AUTH_ENABLE_CREDENTIALS_PROVIDER`                          | Enable credentials provider for NextAuth            | `true`                                                                                                                 |
| `web.env.NEXT_PUBLIC_BYPASS_AUTH0_FLOW`                                  | Bypass Auth0 flow for Next.js                       | `true`                                                                                                                 |
| `web.env.NEXT_PUBLIC_SELF_HOSTED`                                        | Self-hosted mode for Next.js                        | `true`                                                                                                                 |
| `web.autoscaling.enabled`                                                | Enable autoscaling for Web                          | `false`                                                                                                                |
| `web.autoscaling.minReplicas`                                            | Minimum autoscaling replicas for Web                | `1`                                                                                                                    |
| `web.autoscaling.maxReplicas`                                            | Maximum autoscaling replicas for Web                | `3`                                                                                                                    |
| `web.autoscaling.targetCPUUtilizationPercentage`                         | Target CPU utilisation percentage for Web           | `60`                                                                                                                   |
| `web.autoscaling.targetMemoryUtilizationPercentage`                      | Target memory utilisation percentage for Web        | `80`                                                                                                                   |
| `web.resources.limits.cpu`                                               | CPU resource limits for Web                         | `2000m`                                                                                                                |
| `web.resources.limits.memory`                                            | Memory resource limits for Web                      | `4Gi`                                                                                                                  |
| `web.resources.requests.cpu`                                             | CPU resource requests for Web                       | `1000m`                                                                                                                |
| `web.resources.requests.memory`                                          | Memory resource requests for Web                    | `2Gi`                                                                                                                  |
| `web.service.port`                                                       | Port of the Web service                             | `3000`                                                                                                                 |
| `web.service.type`                                                       | Type of the Web service                             | `ClusterIP`                                                                                                            |
| `web.service.annotations`                                                | Annotations for the Web service                     | `{}`                                                                                                                   |
| `web.service.labels`                                                     | Labels for the Web service                          | `{}`                                                                                                                   |
| `web.ingress.enabled`                                                    | Specify if the Web Ingress is enabled               | `true`                                                                                                                 |
| `web.ingress.ingressClassName`                                           | Ingress Class Name. May be required for k8s >= 1.18 | `nginx`                                                                                                                |
| `web.ingress.annotations.cert-manager.io/cluster-issuer`                 | Cluster issuer for ingress                          | `letsencrypt-self-hosted`                                                                                              |
| `web.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect` | Force SSL redirect for ingress                      | `{"cert-manager.io/cluster-issuer":"letsencrypt-self-hosted","nginx.ingress.kubernetes.io/force-ssl-redirect":"true"}` |
| `web.ingress.tls[0].secretName`                                          | TLS secret name for ingress                         | `devzero-web-tls`                                                                                                      |
| `web.ingress.tls[0].hosts`                                               | List of TLS hosts for ingress                       | `["{{ .Values.domain }}"]`                                                                                             |
| `web.ingress.hosts[0].host`                                              | Host name for ingress                               | `{{ .Values.domain }}`                                                                                                 |
| `web.ingress.hosts[0].paths[0].path`                                     | Path for ingress                                    | `/`                                                                                                                    |
| `web.ingress.hosts[0].paths[0].pathType`                                 | Path type for ingress                               | `Prefix`                                                                                                               |

### Cluster Issuer Configuration

| Name             | Description                              | Value                                            |
| ---------------- | ---------------------------------------- | ------------------------------------------------ |
| `issuer.enabled` | Enable Cluster Issuer                    | `true`                                           |
| `issuer.acme`    | ACME server URL                          | `https://acme-v02.api.letsencrypt.org/directory` |
| `issuer.email`   | Email address used for ACME registration | `email@selfzero.net`                             |

### Vault Configuration

| Name                    | Description           | Value        |
| ----------------------- | --------------------- | ------------ |
| `vault.job.enabled`     | Enable Vault job      | `true`       |
| `vault.job.address`     | Vault address for job | `vault:8200` |
| `vault.ingress.enabled` | Enable Vault ingress  | `false`      |

### Mimir Configuration

| Name                    | Description          | Value   |
| ----------------------- | -------------------- | ------- |
| `mimir.ingress.enabled` | Enable Mimir ingress | `false` |

### Grafana Configuration

| Name                      | Description            | Value   |
| ------------------------- | ---------------------- | ------- |
| `grafana.ingress.enabled` | Enable Grafana ingress | `false` |

### Registry Configuration

| Name                       | Description             | Value   |
| -------------------------- | ----------------------- | ------- |
| `registry.ingress.enabled` | Enable Registry ingress | `false` |
