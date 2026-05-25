# TASK-004 Values Contract and Required Overrides

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | configuration | documentation
```

## 브랜치 기준

```text
feature/values-contract
```

## 목표

Define a safe values contract: default `values.yaml` must contain only generic non-environment defaults, while dev/prod-specific values are supplied through overrides.

## 작업 범위

### 허용

- Define empty defaults for hosts, public URLs, image repositories, artifact URLs, and ingress hosts.
- Keep safe stable key names for Secret data keys.
- Add README required values table/list.
- Add placeholder dev/prod examples.
- Add schema validation for values shape.

### 금지

- Do not hardcode real hosts/domains.
- Do not hardcode production or development artifact URLs.
- Do not hardcode real image repositories in default values.
- Do not place secret values in public examples.

## 필수 변경사항

- `charts/kubecert/values.yaml` uses safe generic defaults only.
- `README.md` lists required override values.
- `examples/dev/values.yaml` uses placeholder dev values.
- `examples/prod/values.yaml` uses placeholder prod values.
- `values.schema.json` validates major sections.

## 완료 조건

- Default values contain no real environment-specific host or registry.
- README explains Helm override order.
- Required values are documented.

## Validation

```bash
rg -n "sweetlabs|192\\.168|ghcr.io|api\\.sweet|admin\\.sweet|artifacts\\.sweet" charts/kubecert/values.yaml README.md
helm lint charts/kubecert
helm template kubecert charts/kubecert -f examples/dev/values.yaml
helm template kubecert charts/kubecert -f examples/prod/values.yaml
```

## 문서 갱신 항목

- Record default/dev/prod values policy.
- Record required override list.

## Status

Completed for the initial chart skeleton. Re-run validation after TASK-005 migrates the full chart templates.

## Validation Result

2026-05-26:

- `rg -n "sweetlabs|192\\.168|ghcr.io|api\\.sweet|admin\\.sweet|artifacts\\.sweet" charts/kubecert/values.yaml README.md`
  - Passed: no matches.
- `helm lint charts/kubecert`
  - Passed: 1 chart linted, 0 failed. Helm reported only the optional icon recommendation.
- `helm template kubecert charts/kubecert -f examples/dev/values.yaml`
  - Passed for current skeleton chart.
- `helm template kubecert charts/kubecert -f examples/prod/values.yaml`
  - Passed for current skeleton chart.
