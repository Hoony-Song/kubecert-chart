# TASK-003 Chart Migration Map

## Goal

Define how the existing Helm chart and deployment examples are migrated into the public `kubecert-chart` repository.

## Decision

The Helm chart is the deployment source of truth for both disposable development clusters and production upgrades. Raw Kubernetes manifests are not migrated as an active deployment path.

## Source Mapping

| Source | Target | Notes |
|---|---|---|
| `cert-platform/charts/cert-platform/Chart.yaml` | `charts/kubecert/Chart.yaml` | Rename chart to `kubecert`; update metadata and dependencies. |
| `cert-platform/charts/cert-platform/Chart.lock` | `charts/kubecert/Chart.lock` | Regenerate after dependency decisions. |
| `cert-platform/charts/cert-platform/templates` | `charts/kubecert/templates` | Migrate selectively and rename resource prefixes/labels. |
| `cert-platform/charts/cert-platform/values.yaml` | `charts/kubecert/values.yaml` | Scrub production-specific defaults. |
| `cert-platform/charts/cert-platform/values.schema.json` | `charts/kubecert/values.schema.json` | Update names and required values. |
| `cert-platform/charts/cert-platform/README.md` | `charts/kubecert/README.md` and root `README.md` | Split chart-specific and repository-level docs. |
| `cert-platform/deploy/*.example.yaml` | `examples/` | Scrub domains, secret names, and private environment assumptions. |
| `cert-platform/scripts/helm-render.sh` | `scripts/ci/helm-render.sh` | Chart render helper. |
| `cert-platform/scripts/helm-upgrade.sh` | `scripts/release/helm-upgrade.sh` | Release helper; must accept explicit kubeconfig/namespace/values. |

## Resource Rename Rules

Rename public-facing chart identity from `cert-platform` to `kubecert`.

Examples:

- chart name: `cert-platform` -> `kubecert`
- release examples: `cert-platform` -> `kubecert`
- labels: `app.kubernetes.io/part-of: kubecert`
- resource prefixes: prefer `kubecert-*`
- values keys: prefer product-neutral names where possible

Legacy env var names may remain temporarily if changing them would force large application changes. Document retained legacy env vars and migrate them in a later compatibility task.

## Templates To Migrate

Migrate and rename:

- backend/API deployment
- worker deployments
- terminal-gateway deployment
- exam/admin frontend deployments
- configmap
- secrets
- migration/seed jobs
- ingress
- network policies
- question-bank sync job
- service accounts, services, and RBAC if present or needed

Review before migrating:

- current hand-written PostgreSQL template
- current hand-written Redis template
- KEDA templates and dependency behavior

## Open Source Dependency Policy

The chart must support bundled and external modes.

Bundled mode:

- Development default.
- Installs required open-source dependencies with the chart.
- Packaged chart releases must include dependency charts as needed.

External mode:

- Production-capable.
- Uses existing PostgreSQL, Redis, KEDA, and secrets.
- Must not require manual SQL setup.

Migration strategy:

1. First preserve the existing chart behavior enough to render/install.
2. Then normalize PostgreSQL/Redis/KEDA dependency handling.
3. Regenerate `Chart.lock` from `Chart.yaml`.
4. Ensure packaged chart releases contain required dependency charts.

## Values Policy

Values must support:

- immutable image tags or digests
- bundled/external PostgreSQL
- bundled/external Redis
- bundled/external KEDA. KEDA is required; disabled mode is not supported.
- existing Secret references
- migration and seed job toggles
- question-bank artifact URL and sha256
- runtime artifact manifest URL and sha256
- ingress hosts and TLS configuration

Default `charts/kubecert/values.yaml` rules:

- Must contain safe generic defaults only.
- Must not hardcode environment hosts, domains, public URLs, artifact URLs, or image repositories.
- May define stable non-secret key names and safe feature defaults.
- Environment-specific values must be supplied through dev/prod override files.
- README must document every value that a real deployment has to override.

Values must not contain:

- real private keys
- token values
- kubeconfig content
- production credentials
- private source paths

## Files Not Migrated As Active Chart Source

Do not migrate as active deployment source:

- `cert-platform/k8s/*.yaml`
- generated frontend `dist`
- `node_modules`
- backend virtualenv/cache files
- real production values
- Kubernetes Secret manifests with real data

Raw manifests may be used only as a temporary reference while porting chart templates.

## Development Deployment Contract

Dev deployment uses:

```text
helm dependency build charts/kubecert
helm lint charts/kubecert
helm template kubecert charts/kubecert -f examples/bundled/values.yaml
helm upgrade --install kubecert charts/kubecert --namespace kubecert --create-namespace --kubeconfig <dev-kubeconfig>
```

The exact commands may move into scripts, but the path remains Helm-only.

## Production Promotion Contract

Production deployment requires:

- fixed chart version
- fixed image tags/digests
- fixed artifact URLs and sha256
- reviewed production values outside the public repo if private
- DB backup confirmation
- successful migration Job
- successful seed Job
- smoke test

## Acceptance Criteria

- Existing chart source has a clear migration map.
- Raw manifest exclusion is explicit.
- Resource rename rules are defined.
- Dependency bundling/external mode policy is explicit.
- Values safety policy is explicit.
