# Dev Helm Smoke

Kubecert development deployment must use Helm only. Do not apply raw manifests.

## Inputs

Keep these outside Git:

- dev kubeconfig
- private dev values file
- real image tags or digests from `kubecert` release metadata
- real artifact URLs and sha256 values
- real Secret objects or private local values used to create temporary Secrets

Public `examples/dev/values.yaml` is a renderable placeholder and must not be used directly for a real smoke.

## Preflight

```bash
scripts/ci/helm-dev-smoke-preflight.sh \
  --kubeconfig /path/to/dev-config \
  --values /path/to/private-dev-values.yaml
```

The preflight runs dependency build, lint, placeholder checks, and a Helm dry-run.

## Install

```bash
helm dependency build charts/kubecert
helm upgrade --install kubecert charts/kubecert \
  --namespace kubecert \
  --create-namespace \
  --kubeconfig /path/to/dev-config \
  -f /path/to/private-dev-values.yaml \
  --wait \
  --timeout 15m
```

## Smoke Checklist

- All Pods become Ready.
- Migration Job succeeds.
- Seed Job succeeds.
- API `/healthz` returns `{"status":"ok"}`.
- Admin login succeeds.
- Token issue succeeds.
- Exam start succeeds.
- Terminal websocket path reaches the terminal gateway when Runtime Node prerequisites are available.
- Grading path succeeds when Runtime Node prerequisites are available.

## Reinstall

```bash
helm uninstall kubecert \
  --namespace kubecert \
  --kubeconfig /path/to/dev-config

kubectl delete namespace kubecert \
  --kubeconfig /path/to/dev-config \
  --ignore-not-found
```

Deleting the namespace removes chart-owned bundled dev resources. External cloud resources and private Secrets outside the namespace must be managed separately.
