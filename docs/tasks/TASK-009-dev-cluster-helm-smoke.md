# TASK-009 Dev Cluster Helm Smoke

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | deployment | validation
```

## 브랜치 기준

```text
feature/dev-helm-smoke
```

## 목표

Install Kubecert into a disposable public cloud development cluster using Helm only.

## 작업 범위

### 허용

- Use a kubeconfig supplied outside Git.
- Install chart into a dev namespace.
- Validate bundled dependencies.
- Validate migration/seed Jobs.
- Run smoke tests.

### 금지

- Do not commit kubeconfig.
- Do not deploy to production.
- Do not apply raw manifests directly.
- Do not store real secret values in public repo.

## 필수 변경사항

- Dev install command documented.
- Dev uninstall/reinstall command documented.
- Smoke checklist documented.
- Known cloud provider assumptions documented.

## 완료 조건

- Helm install succeeds on dev cluster.
- Backend health check passes.
- Admin login smoke passes.
- Token issue smoke passes where Runtime Node prerequisites are available.
- Helm uninstall or namespace deletion cleans up chart-owned resources.

## Validation

```bash
helm dependency build charts/kubecert
helm upgrade --install kubecert charts/kubecert \
  --namespace kubecert \
  --create-namespace \
  --kubeconfig <dev-kubeconfig> \
  -f <private-dev-values.yaml>
```

## 문서 갱신 항목

- Record smoke test result summary.
- Record any dev cloud cluster prerequisites.

## Status

In progress. A real dev cluster install is running from local private values.

## Implemented Files

- `docs/operations/dev-helm-smoke.md`
  - Documents preflight, install, smoke checklist, and uninstall/reinstall commands.
- `scripts/ci/helm-dev-smoke-preflight.sh`
  - Runs dependency build, lint, placeholder scan, and Helm dry-run.
  - Requires kubeconfig and private values file paths outside Git.
  - Refuses public placeholder values by default.

## Dev Cluster Prerequisites

- Disposable public cloud Kubernetes cluster.
- Kubeconfig stored outside Git.
- Private dev values file stored outside Git.
- Dev image tags/digests from `kubecert` release metadata.
- Question-bank artifact URL and sha256.
- Runtime artifact manifest URL and sha256 when Runtime Node join is tested.
- Existing Secrets or private local values for:
  - initial admin credentials
  - Runtime SSH key
  - Terminal SSH key
  - external DB/Redis credentials when external mode is used
- The app JWT Secret is chart-owned and is generated/reused internally.

## Smoke Result

2026-05-26 dev cluster:

- `helm upgrade --install` succeeded with local private `dev-values.yaml`.
- Release `kubecert` in namespace `kubecert` is deployed at revision 9.
- Migration, seed, and question-bank sync Jobs completed.
- Exam/admin runtime config now supports same-origin API routing.
- Same-origin exam API route `/exam-types` returns active exam metadata.
- Same-origin admin API route `/admin/*` reaches the API.
- Cluster-internal nginx-ingress websocket route returns `101 Switching Protocols`.
- External `210.178.39.84:80` websocket Upgrade requests are reset before
  reaching nginx-ingress logs. This remains an external frontend/LB path issue,
  not an application Ingress render issue.
- After deleting the release, namespace, and KEDA CRDs, a single fresh
  `helm upgrade --install` created KEDA CRDs, TriggerAuthentication,
  ScaledObjects, HPAs, DB migration/seed Jobs, question-bank sync Job, and all
  app workloads. Release `kubecert` is deployed at revision 1.

## Validation Result

2026-05-26:

- `bash -n scripts/ci/helm-dev-smoke-preflight.sh`
  - Passed.
- `scripts/ci/helm-dev-smoke-preflight.sh --help`
  - Passed.
- `helm dependency build charts/kubecert`
  - Passed.
- `helm lint charts/kubecert -f examples/dev/values.yaml`
  - Passed: 1 chart linted, 0 failed. Helm reported only the optional icon recommendation.
- `helm template kubecert charts/kubecert -f examples/dev/values.yaml`
  - Passed.
- `scripts/ci/helm-dev-smoke-preflight.sh --kubeconfig /root/Certifications/dev-config --values examples/dev/values.yaml`
  - Passed as an expected safety rejection: public placeholder values are refused before any dry-run install.
- `helm lint charts/kubecert -f dev-values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f dev-values.yaml`
  - Passed.
- `helm upgrade --install kubecert charts/kubecert --namespace kubecert --create-namespace --kubeconfig /root/Certifications/dev-config -f dev-values.yaml --timeout 10m --wait`
  - Passed.
- Fresh single-install validation:
  - Deleted the previous release, namespace, and KEDA CRDs.
  - Applied local private `secrets.yaml` to a new `kubecert` namespace.
  - Ran `helm upgrade --install kubecert charts/kubecert --namespace kubecert --kubeconfig /root/Certifications/dev-config -f dev-values.yaml --timeout 15m --wait`.
  - Passed: release revision 1 deployed successfully.
  - Passed: KEDA CRDs, TriggerAuthentication, ScaledObjects, and HPAs were created during the same install.
  - Passed: DB migration, seed, and question-bank sync Jobs completed.
  - Passed: all deployments and bundled PostgreSQL/Redis StatefulSets are Ready.
