# Log retrieval

Use the environment and isolated kubeconfig from [the main skill](../SKILL.md).
Read only the section selected by its symptom table. Commands are templates: replace
angle-bracket placeholders and set `KUBE_DIR` to the created temporary directory before
execution. Snapshot: **2026-10-28**, not a live guarantee.

### Splunk: core container logs, not every task

Search UI: https://financialtimes.splunkcloud.com/en-US/app/search/search (organisation sign-in).
The `http-inputs-financialtimes.splunkcloud.com` hostname is **HEC ingestion**, not search.
Start with a bounded time window around the failure, then widen it deliberately.

```spl
index=restricted_data_prod earliest=-30m latest=now kubernetes.namespace_name=prod
| stats count by kubernetes.pod_name kubernetes.container_name
```

```spl
index=restricted_data_prod earliest=-30m latest=now
kubernetes.namespace_name=prod kubernetes.pod_name="airflow-scheduler-*"
| table _time kubernetes.pod_name log
```

Substitute the dev index/namespace as a pair. Change the pod pattern to
`airflow-dag-processor-*`, `airflow-api-server-*`, or `airflow-triggerer-*` as appropriate.
These are **query templates based on the live collector's Kubernetes metadata**, not
queries verified against Splunk search. If fields are not extracted, start with
`index=restricted_data_prod earliest=-30m "airflow-scheduler"` and inspect an event.
Splunk retention/search entitlements were not verified.

**Important:** the live `default/fluentbit-fluent-bit` DaemonSet excludes pods labelled
`kubernetes_executor=True` or `kubernetes_pod_operator=True`. It also skips container
paths for `kube-system`, `monitoring`, `default`, and `doppler` namespaces.
**A missing task in Splunk is therefore not evidence the task never ran.** Both clusters
had no EFS Fluent Bit deployment in `default` at verification time. Old `deploy_values_efs.yaml`
files in the Helm repository are not proof that task files are currently shipped to Splunk.

### Kubernetes: current pods and recent restarts

```sh
# All scheduler replicas, rather than an arbitrary single pod:
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV" logs -l component=scheduler,release=airflow -c scheduler \
  --since=30m --tail=200 --prefix
# Replace component/container with dag-processor, api-server, or triggerer as needed.

TEAM=dataplatform
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV-$TEAM" get pods -l dag_id=<dag-id> -o wide
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV-$TEAM" get pod <pod-name> \
  -o jsonpath='{.status.phase}{"\n"}{.status.containerStatuses}{"\n"}'
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV-$TEAM" get events --sort-by=.metadata.creationTimestamp
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV-$TEAM" logs <pod-name> -c base --since=30m --tail=200
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV-$TEAM" logs <pod-name> -c base --previous --tail=200
```

Never use full pod YAML or `describe pod` here: worker environment entries can contain
literal team tokens. Select status/resource fields and events instead.
Task pods use container `base` and labels including `dag_id`, `task_id`, `run_id`,
`try_number`, and `team`. Kubernetes label
values may be normalised/truncated/hashed; obtain actual labels if a selector finds nothing.
`--previous` only works for a restarted container in a pod that still exists.
Both `delete_worker_pods` and `delete_worker_pods_on_failure` are enabled: completed/deleted
pods and expired events cannot be recovered with `kubectl logs`.

For Fluent Bit itself, inspect
`kubectl --kubeconfig "$KUBE_DIR/config" -n default get ds,pods,cm` and bounded logs from
`ds/fluentbit-fluent-bit`. Its normal image lacks `printenv`; don't assume it has a shell.
Inspect the collector ConfigMap if routing has changed. Never dump its token/whole Secret.

### Durable task logs: EFS, normally through the Airflow UI

The `logs-airflow` PVC/PV mounts the environment's EFS logs at **`/opt/airflow/logs`**,
including on scheduler pods. Task logs live under the usual
`dag_id=<dag>/run_id=<run>/task_id=<task>/...attempt=<n>.log` hierarchy (mapped tasks add
a map-index segment). Get the exact run ID and attempt from the UI, not the normalised pod label.

When UI log access is broken, use a **read-only, narrowly scoped** command in an existing
scheduler pod; no debug workload or direct laptop NFS mount is necessary:

```sh
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV" exec deploy/airflow-scheduler -c scheduler -- \
  ls '/opt/airflow/logs/dag_id=<exact-dag-id>'
# List only the matching run/task directory, then tail a specific file:
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV" exec deploy/airflow-scheduler -c scheduler -- \
  tail -n 200 '/opt/airflow/logs/<exact-relative-file-path>'
```

Do not recursively list/read the entire shared filesystem. DAG parsing logs also have
`/opt/airflow/logs/dag-processor`; older `scheduler` and `dag_processor_manager` directories
can remain from previous versions. `config/log_config.py` configures an alternative
`/opt/airflow/logs/unfiltered_task_logs`, but that directory was **absent in both environments**
when checked. Do not promise an unfiltered copy exists or assume EFS has unlimited retention.

### AWS CloudWatch: database logs, not an automatic task-log fallback

Verified groups in both accounts (30-day retention):

| Environment | PostgreSQL | RDS proxy |
| --- | --- | --- |
| Dev | `/aws/rds/instance/ft-dw-airflow/postgresql` | `/aws/rds/proxy/ft-dw-airflow` |
| Prod | `/aws/rds/instance/ft-dw-airflow-prod/postgresql` | `/aws/rds/proxy/ft-dw-airflow` |

```sh
aws logs tail /aws/rds/proxy/ft-dw-airflow --since 30m \
  --profile "$AWS_PROFILE" --region "$AWS_REGION"
```

This is a fallback command, not a guarantee every group has recent events. No EKS
Container Insights application-log groups were found for these clusters. EKS control-plane
logging was **disabled in both**. Prod has an existing `/aws/eks/data-prod-green/cluster`
group with 30-day retention; its existence does not mean it is currently receiving logs.
EKS control-plane `scheduler` logs, if enabled later, are **not Airflow scheduler logs**.
Do not enable logging or install collectors without approval.
