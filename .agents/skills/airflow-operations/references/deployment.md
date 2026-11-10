# Verification and ownership

## Evidence snapshot: 2026-10-28

Read-only AWS/Kubernetes investigation used the existing FT-Engineer SSO profiles.
A temporary isolated kubeconfig was used; no deployed resources were changed.

| Check | Result |
| --- | --- |
| `sts get-caller-identity` | Dev `387197786664`; prod `416899846818` |
| `eks list-clusters` | Airflow on `data-dev-green` / `data-prod-green`, confirmed by live ingress/deployments |
| `eks describe-cluster` | Both ACTIVE, private endpoint enabled, public endpoint disabled; all control-plane log types disabled |
| Core deployments/ingress | Namespace `dev`/`prod`; release label `airflow`; API-server service port 8080; UI hosts match the skill |
| Deployed images | Dev `data-platform-airflow:26380`; prod `data-platform-airflow:26369`, in their respective account ECR registries |
| Worker metadata | `airflow_version=3.3.1`, `kubernetes_executor=True`, container `base`, team namespaces |
| Scheduler logs | `kubectl logs` succeeded in both environments |
| PV `logs-airflow` | NFS EFS endpoints and `/airflow_<env>/logs` paths match the skill |
| Scheduler filesystem | `dag_id=...` directories and `dag-processor` present; `unfiltered_task_logs` absent in both |
| Collector | `default/fluentbit-fluent-bit` DaemonSet and ConfigMap present in both; no EFS collector deployment in that namespace |
| Splunk routing | Live ConfigMap sends to Splunk HEC, `event_index ${SPLUNK_INDEX}`; see [log retrieval](logs.md) for metadata and exclusions |
| Splunk index names | Read **only** `.data.SPLUNK_INDEX` from `default/doppler-secret-splunk-hec`; no token read or persisted |
| CloudWatch | Groups/retentions enumerated; RDS groups and prod EKS group as documented; no EKS application-log groups found |
| HTTP probes | Both Airflow roots returned 200; Splunk search URL returned 303 (sign-in redirect) |
| IRSA examples | `arn:aws:iam::387197786664:role/eksctl-airflow-application-dataplatform-role-data-dev-green` and prod equivalent in account `416899846818` |

Not verified: authenticated Airflow/Okta login, authenticated Splunk searches or field
extraction/retention, Grafana access, task-log retention policy, alternate-log handler
runtime behaviour, recent events in every CloudWatch group. Distinguish verified routing
configuration from successful end-to-end log ingestion.

## Revalidate only the relevant fact

Use the selected profile and `KUBE_DIR` from [the main skill](../SKILL.md).
Run only the read relevant to the disputed fact, not a whole-account inventory:

```sh
aws eks describe-cluster --name "$CLUSTER" --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --query 'cluster.{name:name,status:status,network:resourcesVpcConfig,logging:logging}'
kubectl --kubeconfig "$KUBE_DIR/config" -n "$ENV" get deploy,svc,ingress -o wide
kubectl --kubeconfig "$KUBE_DIR/config" get pv logs-airflow -o jsonpath='{.spec.nfs}'
kubectl --kubeconfig "$KUBE_DIR/config" -n default get cm fluentbit-fluent-bit \
  -o jsonpath='{.data.fluent-bit\.conf}'
aws logs describe-log-groups --log-group-name-prefix /aws/rds/ \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --query 'logGroups[].{name:logGroupName,days:retentionInDays}'
```

The index name is non-secret but is stored next to a credential. If it genuinely needs
rechecking and access is authorised, request **only that key**, never the entire Secret:

```sh
kubectl --kubeconfig "$KUBE_DIR/config" -n default get secret doppler-secret-splunk-hec \
  -o jsonpath='{.data.SPLUNK_INDEX}' | base64 --decode
```

## Source-of-truth locations

Repository-local paths are relative to the repository root, not this reference directory.

- `charts/airflow/values.yaml`: executor, component definitions, config, log PVC, worker
  deletion behaviour, service-account name. Environment overrides:
  `charts/airflow/values_overrides/{dev,prod}/deploy_values.yaml`: UI, EFS, ECR, ALB.
- `config/log_config.py`: custom task filtering and alternative file handler.
- `webserver_config.py`, `workflow/lib/ft/security/oidc/`: Okta/FAB integration.
- `.circleci/config.yml`: core image/chart build and deployment branches/release.
- `docs/source/core/{aws_roles_setup,doppler_secrets_backend,team_resource_management,add_new_teams}.rst`:
  IAM, secrets, scheduling and team access. Some docs describe older component names;
  prefer the actual live manifests when they disagree.

Related repositories (available through project references where configured; otherwise
read via `gh api` or GitHub without cloning unrelated work into this repo):

- https://github.com/Financial-Times/data-platform-helm-charts
  - `fluentbit/values_overrides/{dev,prod}/deploy_values.yaml`: container-to-Splunk config.
  - `fluentbit/values_overrides/{dev,prod}/deploy_values_efs.yaml`: **historical/optional**
    EFS collector; do not assume deployed. These files tail old scheduler/parser paths.
  - `doppler-secrets/values_overrides/data_eks/`: deployed secrets wiring.
  - `data-platform-prometheus/{README,RUNBOOK}.md`: Grafana/metrics guidance.
- https://github.com/Financial-Times/aws-composer-account-data-dev and
  https://github.com/Financial-Times/aws-composer-account-data-prod
  - `cloudformation/roles/airflow_<team>_role.yaml`: team IAM permissions/trust.
  - `cloudformation/policies/AirflowAssumeRolePermissions.yaml`: system assume-role policy.
- https://github.com/Financial-Times/data-platform-eks-provisioner: cluster provisioning
  ownership, referenced by the metrics runbook; not inspected during this investigation.
- https://github.com/Financial-Times/data-platform-ci-common: deployment/DAG-sync orb
  implementation when CI configuration alone is insufficient.
- `Financial-Times/data-platform-dags-<team>`: team DAG source and team-specific deployment.
