# TASK-008 Dev and Prod Values Overlays

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
feature/dev-prod-values-overlays
```

## 목표

Provide safe public placeholder values overlays and clear guidance for private real dev/prod values.

## 작업 범위

### 허용

- Maintain `examples/dev/values.yaml`.
- Maintain `examples/prod/values.yaml`.
- Maintain external services and external secrets examples.
- Document how private values override default values.

### 금지

- Do not commit real dev/prod values if they include private hosts or secrets.
- Do not commit kubeconfig paths that identify real local machines.
- Do not include raw secret values.

## 필수 변경사항

- Dev values example uses bundled defaults and placeholder hosts.
- Prod values example uses external service mode and placeholder hosts.
- README lists required override values.
- Examples are renderable.

## 완료 조건

- Dev example renders.
- Prod example renders.
- README tells users where real values should live.

## Validation

```bash
helm template kubecert charts/kubecert -f examples/dev/values.yaml
helm template kubecert charts/kubecert -f examples/prod/values.yaml
rg -n "sweetlabs|192\\.168|BEGIN .*PRIVATE KEY|kubeconfig" examples README.md
```

## 문서 갱신 항목

- Record values overlay rules.
- Record render result summary.
