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
