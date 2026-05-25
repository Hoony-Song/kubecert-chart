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
