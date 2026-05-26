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

With `keda.mode=bundled`, the same Helm install must create the bundled KEDA
operator, chart-vendored KEDA CRDs, and the Kubecert
TriggerAuthentication/ScaledObject resources.

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

When `ingress.sameOriginApi.enabled=true`, leave frontend API base values empty
and verify API paths through the frontend hosts:

```bash
curl http://exam.example.test/exam-types
curl http://admin.example.test/admin/tokens
```

If cluster-internal websocket checks pass but external websocket requests reset
before nginx-ingress logs, fix the external load balancer or front proxy path
instead of patching application resources by hand.

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
