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
