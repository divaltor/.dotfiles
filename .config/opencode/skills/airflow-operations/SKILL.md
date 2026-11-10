---
name: airflow-operations
description: "Investigate deployed FT Airflow in AWS dev/prod: DAG failures, missing task logs, scheduler/parser/triggerer issues, EKS, Splunk, EFS, CloudWatch, deployment drift and permissions. Not for starting local Airflow. For Doppler connections, variables or token routing, also load airflow-doppler."
---

# FT Airflow operations

## Investigation procedure

1. Establish the environment; ask if it is unknown rather than silently probing dev or prod.
   For a task failure, collect DAG, run ID, task ID, attempt, map index and time range.
2. Select the first evidence source below. Read [log commands](references/logs.md) only
   for that source; do not inventory both accounts to investigate one failure.
3. If cluster access is needed, verify account identity and isolate kubeconfig as below.
4. Test the smallest hypothesis supported by the error. On access failure, follow the
   classification below rather than repeating the same request or changing permissions.
5. Report evidence, cause or remaining uncertainty, and the next action. Quote only
   necessary redacted log lines and include the environment and task/run/time identifiers.

**Read-only by default.** Get explicit authorisation before triggering/retrying/clearing
DAGs, running task tests against deployed connections, restarting pods, upgrading Helm,
editing resources, mounting/deleting EFS data, installing collectors or changing permissions.
Never dump pod environments, full pod specs, Secrets, connection URIs, tokens or
`helm get values --all`: worker specs can contain literal team tokens.

| Symptom | First evidence / next step |
| --- | --- |
| Failed task | UI → exact run/task/attempt/map index logs; if unavailable, scoped EFS read |
| Deleted task pod | UI/EFS; deletion is enabled, so repeated `kubectl logs` cannot help |
| Scheduler/API/triggerer failure | Bounded core-namespace container logs or Splunk |
| Missing DAG / import error | UI import errors and DAG processor logs |
| Pending / OOM / eviction | Team pod status, events, resources, affinity/tolerations and quotas |
| Missing Splunk task events | Check collector exclusions first; task pods are excluded in the snapshot |
| Database / proxy error | CloudWatch RDS logs, not a search for task logs there |
| Missing connection/variable or Doppler error | Load [airflow-doppler](../airflow-doppler/SKILL.md) |
| Task AWS AccessDenied | Check task namespace, service account/IRSA and assumed team role, not laptop permissions |
| Unexpected deployed code/version | Check live images and owning repo CI, not just local files |

## Environment and access

**EKS, not MWAA; region `eu-west-1`.** Use `FT-Tech-Data-*`, not the separate
`FT-Tech-Data-Platform-*` accounts or streaming/MLOps clusters.

| | Dev | Prod |
| --- | --- | --- |
| AWS profile | `FT-Tech-Data-Dev.FT-Engineer` | `FT-Tech-Data-Prod.FT-Engineer` |
| Account | `387197786664` | `416899846818` |
| Cluster | `data-dev-green` | `data-prod-green` |
| Core namespace / Helm release | `dev` / `airflow` | `prod` / `airflow` |
| UI (Okta) | https://airflow.dev.dw.in.ft.com | https://airflow.prod.dw.in.ft.com |
| Splunk index | `restricted_data_dev` | `restricted_data_prod` |
| EFS filesystem / directory | `fs-43d3ef8b` / `/airflow_dev/logs` | `fs-84d5614f` / `/airflow_prod/logs` |

Task pods run in `<env>-<team>`; core services run in `<env>`.
EKS endpoints are private-only and Airflow ALBs internal: connect to FT network/VPN.
SSO success does not establish network reachability. UI/Okta, AWS SSO, Kubernetes RBAC
and Splunk access are separate; HTTP 200 on `/` does not prove DAG access.

Use the existing SSO profile. On expiry, ask the user to complete
`aws sso login --profile "$AWS_PROFILE"`; never read SSO caches or extract credentials.
If the profile is missing, use the organisation's SSO setup, not an invented SSO URL.

```sh
# Example for a confirmed dev investigation; select all values together from the table.
export AWS_PROFILE=FT-Tech-Data-Dev.FT-Engineer AWS_REGION=eu-west-1
ENV=dev
CLUSTER=data-dev-green
aws sts get-caller-identity --profile "$AWS_PROFILE"
```

**Stop if Account does not match the table.** Only then create an isolated kubeconfig:

```sh
# Use the session's approved temporary directory when one is provided.
KUBE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/airflow-ops.XXXXXX")
aws eks update-kubeconfig --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --name "$CLUSTER" --alias "airflow-$ENV" --kubeconfig "$KUBE_DIR/config"
kubectl --kubeconfig "$KUBE_DIR/config" --request-timeout=10s -n "$ENV" get deploy,pods
```

Pass `--kubeconfig "$KUBE_DIR/config"` on every subsequent Kubernetes call (including
reference examples), or export `KUBECONFIG` only inside an isolated subshell. Shell
variables do not persist between tool calls: carry the actual path forward explicitly.
Never change the user's default context or use localdev `mise run k8s:up` for EKS access.
Remove only the temporary directory you created when finished.

| Access failure | Action |
| --- | --- |
| Expired AWS SSO | User login, then recheck account |
| EKS timeout / DNS error | Check VPN/private routing |
| Kubernetes Unauthorized / Forbidden | Check authentication / RBAC; do not edit roles |
| UI login / role failure | Inspect `webserver_config.py`, `workflow/lib/ft/security/oidc/`, `docs/source/core/add_new_teams.rst`; never bypass login |

## Drift and ownership

Live snapshot **2026-10-28**, not a version pin: task labels reported Airflow **3.3.1**.
Check current images before using Airflow 2/webserver/API-v1 advice. Core deployments:
`airflow-api-server`, `airflow-scheduler`, `airflow-dag-processor`, `airflow-triggerer`,
`airflow-statsd`. Revalidate only the disputed fact using [deployment evidence](references/deployment.md).

- Core CI: `.circleci/config.yml`, `dev` → dev, `master` → prod; image tags injected into
  `charts/airflow/values_overrides/<env>/deploy_values.yaml`.
- Team DAGs: separate repos under `workflow/dags/<team>`; check their own CI for drift.
- Task permissions: `eksctl-airflow-application-serviceaccount`, namespace-specific IRSA,
  team connections assuming `airflow_<team>_role` with team external IDs. See
  `docs/source/core/aws_roles_setup.rst` before proposing IAM changes.
- Scheduling: `docs/source/core/team_resource_management.rst`. Metrics: https://grafana.ft.com/,
  Data Platform v2 folder (access unverified).

Paths are repository-relative unless linked relative to this skill. The evidence reference
identifies related Helm/IAM/DAG repos and distinguishes verified facts from untested access.
