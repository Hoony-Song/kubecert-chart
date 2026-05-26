# TASK-006 Open Source Dependency Bundling

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | dependency | database | redis | keda
```

## 브랜치 기준

```text
feature/oss-dependency-bundling
```

## 목표

Normalize bundled and external modes for open-source dependencies used by Kubecert.

## 작업 범위

### 허용

- Add or update chart dependencies for PostgreSQL, Redis, and KEDA.
- Support external PostgreSQL/Redis/KEDA.
- Regenerate `Chart.lock`.
- Document dependency modes.

### 금지

- Do not require manual SQL setup after chart install.
- Do not hardcode production service hosts.
- Do not store DB/Redis passwords in values.
- Do not install Runtime Node operating systems from the chart.

## 필수 변경사항

- Bundled mode works for disposable dev clusters.
- External mode works for production/shared services.
- Credentials use existing Kubernetes Secrets.
- Chart package includes required dependency charts where appropriate.

## 완료 조건

- `helm dependency build charts/kubecert` succeeds.
- Bundled and external values render.
- Dependency behavior is documented.

## Validation

```bash
helm dependency build charts/kubecert
helm template kubecert charts/kubecert -f examples/dev/values.yaml
helm template kubecert charts/kubecert -f examples/external-services/values.yaml
```

## 문서 갱신 항목

- Record dependency versions.
- Record bundled/external mode assumptions.

## Status

Completed.

## Dependency Versions

The chart now defines these Helm dependencies in `charts/kubecert/Chart.yaml`:

| Dependency | Repository | Version | Condition |
|---|---|---:|---|
| `postgresql` | `https://charts.bitnami.com/bitnami` | `18.6.7` | `postgresql.enabled` |
| `redis` | `https://charts.bitnami.com/bitnami` | `25.5.3` | `redis.enabled` |
| `keda` as `kedaOperator` | `https://kedacore.github.io/charts` | `2.19.0` | `kedaOperator.enabled` |

`Chart.lock` was regenerated with `helm dependency build charts/kubecert`.

Dependency archives under `charts/kubecert/charts/*.tgz` are ignored source build outputs. They are recreated by `helm dependency build` and included in packaged chart release artifacts by the chart release flow.

KEDA CRDs are vendored into `charts/kubecert/crds/` from the bundled KEDA chart
version. This lets a fresh cluster install KEDA CRDs before Helm validates the
Kubecert TriggerAuthentication and ScaledObject manifests, so bundled KEDA works
in a single Helm install.

## Bundled Mode

- `postgresql.enabled=true`
- `postgresql.mode=bundled`
- `redis.enabled=true`
- `redis.mode=bundled`
- `kedaOperator.enabled=true`
- `keda.mode=bundled`

Bundled mode is the expected default for disposable dev clusters.

## External Mode

- `postgresql.enabled=false`
- `postgresql.mode=external`
- `postgresql.external.host` points to the existing service.
- `redis.enabled=false`
- `redis.mode=external`
- `redis.external.host` points to the existing service.
- `kedaOperator.enabled=false`
- `keda.mode=external` when KEDA is already installed.

External service credentials are passed through existing Secret references. Public examples only contain placeholder names.

## Validation Result

2026-05-26:

- `helm repo update`
  - Passed.
- `helm search repo bitnami/postgresql --versions`
  - Selected `18.6.7`.
- `helm search repo bitnami/redis --versions`
  - Selected `25.5.3`.
- `helm search repo kedacore/keda --versions`
  - Selected `2.19.0`.
- `helm dependency build charts/kubecert`
  - Passed and saved PostgreSQL, Redis, and KEDA dependency archives locally.
- `helm lint charts/kubecert`
  - Passed: 1 chart linted, 0 failed. Helm reported only the optional icon recommendation.
- `helm template kubecert charts/kubecert -f examples/dev/values.yaml`
  - Passed and rendered bundled PostgreSQL, Redis, KEDA, and app workloads.
- `helm template kubecert charts/kubecert -f examples/external-services/values.yaml --api-versions keda.sh/v1alpha1/ScaledObject --api-versions keda.sh/v1alpha1/TriggerAuthentication`
  - Passed with external KEDA CRDs modeled as preinstalled.
