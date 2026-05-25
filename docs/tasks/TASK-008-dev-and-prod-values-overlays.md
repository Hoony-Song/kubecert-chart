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

## Status

Completed.

## Overlay Rules

- `examples/dev/values.yaml`
  - Uses bundled PostgreSQL, Redis, and KEDA defaults.
  - Uses `dev-replace-with-shortsha-timestamp` placeholder tags.
  - Uses placeholder dev hosts under `*.dev.example.com`.
  - References placeholder existing Secret names but never stores Secret values.
- `examples/prod/values.yaml`
  - Uses external PostgreSQL, Redis, and KEDA mode.
  - Uses production-style `vYYYYMMDD-release-rN` placeholder tags.
  - Shows digest pinning fields with zero placeholder digests that must be replaced.
  - References placeholder existing Secret names but never stores Secret values.
- `examples/external-services/values.yaml`
  - Documents the external service mode and password key contract.

Real dev/prod values must stay outside this public repository. Public examples are renderable placeholders only.

## Validation Result

2026-05-26:

- `helm template kubecert charts/kubecert -f examples/dev/values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f examples/prod/values.yaml`
  - Passed.
- `helm template kubecert charts/kubecert -f examples/external-services/values.yaml`
  - Passed.
- `rg -n "sweetlabs|192\\.168|BEGIN .*PRIVATE KEY|kubeconfig" examples README.md`
  - No secret/key/IP/domain values found. Only public safety text mentions kubeconfig.
