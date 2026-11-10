---
name: airflow-doppler
description: "Use and troubleshoot Doppler in FT data-platform-airflow and team DAG projects: choose project/config, safely check secret names, route connections and variables, diagnose token/operator sync, and use local Docker/Minikube startup. Not a general Doppler administration guide."
metadata:
  scope: local
---

# FT Airflow Doppler

## Choose the lookup before choosing a command

1. Establish `AIRFLOW_ENV`, team and the requested connection/variable/key. Never infer
   runtime environment from the git branch: `EnvConfig.env()` defaults to `localdev`
   when `AIRFLOW_ENV` is missing.
2. Select the project/config below. A valid login to the wrong config can look like a
   missing secret; do not search every project's values to find a match.
3. Check names and routing first. Read a value only when the authorised task requires it,
   and consume it without emitting it to tool output, logs, shell tracing or chat.
4. Classify the failed boundary below. Do not rotate tokens, edit secrets, restart pods,
   resync resources or retry DAGs without explicit authorisation.

| Need | Project | Config | Runtime credential |
| --- | --- | --- | --- |
| Team connection | `data-platform-airflow-<team>` | `<env>_connections` | `<TEAM>_DOPPLER_TOKEN` |
| Airflow variable | `data-platform-airflow` | `<env>_variables` | `AIRFLOW_VARIABLES_DOPPLER_TOKEN` |
| System/pod startup settings | `data-platform-airflow` | `<env>_k8s_app` | App bootstrap service token |
| Team token routing | `data-platform-airflow` | `<env>_k8s_team_tokens` | Team-token bootstrap service token |

These are separate configs, not interchangeable names for `<env>`. Arbitrary team
config reads also exist (`DopplerService.get_secrets`); inspect the caller's config argument.

## Safe CLI reads

Use the repo-pinned CLI through `mise exec -- doppler`. Use an existing authorised CLI
login; if unavailable, ask the user to complete `mise exec -- doppler login`.
Do not read `~/.doppler` or extract SSM/Kubernetes service tokens for an interactive probe.
An existing `DOPPLER_TOKEN` may scope access to a different config: establish the intended
authentication mode without printing the token; do not silently override it or broaden access.

```sh
# Example: confirmed dev / dataplatform connection investigation.
mise exec -- doppler configs --project data-platform-airflow-dataplatform
mise exec -- doppler secrets --only-names \
  --project data-platform-airflow-dataplatform --config dev_connections
```

Always pass `--project` and `--config` for secret operations; do not run `doppler setup`
or change saved CLI scope merely to investigate. `doppler secrets` without `--only-names`
prints values. `--raw` and `--plain` are **not redaction**. Avoid `configure debug`,
`--print-config`, `--debug`, token listings, bulk downloads and `run -- env/printenv`:
they can expose credentials. Name-only output still needs to be scoped to the incident.

For an authorised command that needs secrets, use `doppler run --no-fallback` with
explicit project/config and `--only-secrets <required-key>`; run the actual consumer,
never an echo or environment dump. `--no-fallback` prevents local fallback persistence
and stale fallback reads. Do not inject prod credentials into local commands as a diagnostic.

## Trace the failed boundary

| Evidence | Check next |
| --- | --- |
| CLI authentication/permission error | Intended user/service-token scope and project/config grants; AWS SSO is not Doppler login |
| Missing `<TEAM>_DOPPLER_TOKEN` in runtime | Team token config → synced Secret → core pod reference → worker token injection |
| Connection missing | Team from connection ID's first `_`-separated segment → team project → `<env>_connections` → uppercased full connection ID |
| Connection JSON/shape error | Backend expects JSON with `conn_uri` or Airflow Connection constructor fields; name existence alone does not validate the value |
| Variable missing | System `<env>_variables`, uppercased key, and `AIRFLOW_VARIABLES_DOPPLER_TOKEN`, not the team's connections config |
| Doppler changed but pod setting stale | Operator sync and pod environment snapshot; updating a Kubernetes Secret does not rewrite an existing process environment |
| Local startup cannot retrieve bootstrap token | Correct localdev AWS profile, SSO and named SSM parameters; not a Doppler CLI login workaround |

Runtime connection reads use Doppler's computed value and parse it as JSON. Do not copy
secrets into the Airflow metadata DB to bypass a lookup failure. Variables with prefix
`cosmos_xcom_backup` deliberately fall through to local Airflow storage; the backend also
maps `PythonVirtualenvOperator.cache_key` to `<DATA_TEAM>_PYTHON_VIRTUALENV_OPERATOR_CACHE_KEY`.

Bootstrap chain: SSM `token-<env>-k8s-app` / `token-<env>-k8s-team-tokens` → operator token
Secrets → DopplerSecret resources → `doppler-airflow-k8s-app` in core/team namespaces and
`doppler-airflow-k8s-team-tokens` in the core namespace → pod environment.
Workers receive only their team's token through `PodService._provide_doppler_access`.
Team connections are fetched through the API, not synced as one Kubernetes Secret per connection.

For EKS access load [airflow-operations](../airflow-operations/SKILL.md). Inspect only
resource names, selected references, key names and sync status. Never dump Secrets,
pod environments, full pod specs or `kubectl describe pod`: worker specs may contain
literal tokens. Operator status/errors can contain sensitive details; redact before quoting.
Confirm current manifests instead of relying on older docs' pod/component lists.

## Local startup and ownership

- For a requested local Docker startup, use `mise run docker:up` (default environment:
  `localdev`; profile `FT-Tech-Data-Dev.FT-Engineer-DP-Airflow-Localdev`). It retrieves the
  two SSM bootstrap tokens and uses nested Doppler mounts for Compose. Do not replace it
  with a hand-written `.env` export, print the mounts or add `--fresh` for a secrets issue.
- For a requested local Minikube startup, use `mise run k8s:up`; it retrieves the localdev
  bootstrap tokens and supplies protected temporary Helm values. Do not use it to connect to EKS.
- Do not run either startup task merely to test Doppler access: they build/start workloads.
  Inspect `.mise/tasks/{docker,k8s}/up` and `.mise/lib/aws.sh` for current options/SSO handling.

Source of truth (repository-relative):
- `workflow/lib/ft/security/doppler/{utils/doppler_utils,service/doppler_service,backend/ft_doppler_backend}.py`
  and `workflow/lib/ft/security/common/connection_utils.py`: lookup names and value handling.
- `workflow/lib/airflow/custom/config/env/env.py`: runtime environment selection.
- `workflow/lib/ft/airflow/kubernetes/pod/service/pod_service.py`: worker token injection.
- `docs/source/core/doppler_secrets_backend.rst`: architecture; verify against code/manifests.
- `charts/airflow/values_overrides/localdev/deploy_values.yaml`: local operator wiring.
- Related repo `Financial-Times/data-platform-helm-charts`,
  `doppler-secrets/values_overrides/data_eks/{dev,prod}_values.yaml`: deployed wiring.

Routing was checked against local source and CLI flags against installed CLI help on
**2026-10-30**. No authenticated Doppler read, sync, token validity or secret value was verified.
