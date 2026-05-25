# TASK-005 Chart Source Migration

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | migration
```

## 브랜치 기준

```text
feature/chart-source-migration
```

## 목표

Migrate the existing `cert-platform` Helm chart into `charts/kubecert` and rename public chart identity to Kubecert.

## 작업 범위

### 허용

- Migrate chart templates.
- Rename chart metadata, labels, and resource prefixes.
- Migrate schema and README content after scrubbing.
- Keep temporary legacy env var names where application compatibility requires it.

### 금지

- Do not migrate raw `cert-platform/k8s/*.yaml` as active source.
- Do not migrate real production values.
- Do not include application source code.
- Do not include secrets.

## 필수 변경사항

- `Chart.yaml` migrated and renamed.
- Templates migrated and renamed.
- Values/schema aligned with TASK-004.
- Chart README updated.
- Existing chart behavior preserved enough to render.

## 완료 조건

- `helm template` renders.
- `helm lint` passes or documented blockers are limited to missing dependency work assigned to TASK-006.
- Resource names and labels use `kubecert`.

## Validation

```bash
helm lint charts/kubecert
helm template kubecert charts/kubecert -f examples/dev/values.yaml
rg -n "cert-platform" charts/kubecert
```

## 문서 갱신 항목

- Record retained legacy names.
- Record render/lint results.

## Status

Completed initial chart source migration.

## Migration Notes

- Added Kubecert application templates under `charts/kubecert/templates/`:
  - API Deployment/Service.
  - Worker Deployments for provision, grade, and cleanup roles.
  - Terminal Gateway Deployment/Service.
  - Exam Web and Admin Web Deployments/Services.
  - ConfigMap, optional Secrets, Ingress, KEDA ScaledObjects, NetworkPolicy, question-bank PVC/sync Job.
- Renamed chart labels, resource prefixes, and helpers to `kubecert`.
- Switched image contract to the five images produced by the private `kubecert` release metadata:
  - `images.api`
  - `images.worker`
  - `images.terminalGateway`
  - `images.examWeb`
  - `images.adminWeb`
- Added digest support to the image values schema and image helper.
- Preserved safe runtime filesystem defaults only; no environment host, domain, artifact URL, image repository, secret, kubeconfig, or private source value was added to default `values.yaml`.
- Added chart-local README with source/image/secret expectations.

## Retained Legacy Compatibility

- Application env var names beginning with `CERT_` remain compatible with the migrated `kubecert` source.
- Runtime key mount path defaults remain filesystem contracts, not environment-specific hosts.

## Deferred To Later Tasks

- TASK-006 adds actual open-source chart dependencies and lock file regeneration.
- TASK-007 owns migration and seed Job finalization.
- TASK-008 owns final dev/prod placeholder overlay cleanup.

## Validation Result

2026-05-26:

- `helm lint charts/kubecert`
  - Passed: 1 chart linted, 0 failed. Helm reported only the optional icon recommendation.
- `helm template kubecert charts/kubecert -f examples/dev/values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f examples/prod/values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f examples/bundled/values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f examples/external-services/values.yaml`
  - Passed.
- `rg -n "cert-platform" charts/kubecert || true`
  - No matches.
