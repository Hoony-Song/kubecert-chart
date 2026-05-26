# TASK-002 Dev Chart Deployment Model

## Goal

Define how the public Helm chart is used to deploy Kubecert to disposable development clusters and later promote validated releases to production.

## Background

Kubecert source code lives in the private `kubecert` repository. This repository owns the public Helm chart. The development environment is a public cloud Kubernetes cluster that can be removed and recreated frequently. Production continues to run on the existing infra RKE2 cluster.

## Deployment Contract

All cluster deployment goes through Helm.

Allowed:

- `helm dependency build`
- `helm lint`
- `helm template`
- `helm upgrade --install`
- `helm uninstall`

Not allowed as a normal deployment path:

- Applying raw source manifests directly to dev or prod.
- Editing live Kubernetes resources by hand and treating that as the release.
- Running DB schema SQL outside the migration Job for normal releases.

## Development Install Flow

```text
kubecert source release candidate
-> image tags/digests
-> question-bank/runtime artifact URLs, when needed
-> chart values
-> helm dependency build
-> helm lint
-> helm template
-> helm upgrade --install --kubeconfig <dev-kubeconfig>
-> smoke test
```

Development cluster assumptions:

- Public cloud Kubernetes.
- Disposable; reinstall must be routine.
- Bundled PostgreSQL/Redis/KEDA should be the default path unless testing external mode.
- Kubeconfig is not committed.
- Namespace can be deleted and recreated.

## Production Promotion Flow

```text
validated dev chart render/install
-> release version fixed
-> image/artifact digests fixed
-> production values reviewed
-> DB backup confirmed
-> helm upgrade --install on production
-> migration Job success
-> seed Job success
-> app rollout success
-> smoke test
```

Production assumptions:

- Existing infra RKE2 cluster remains production.
- Production may use external PostgreSQL/Redis/KEDA mode.
- Production values must be kept outside the public repo if they contain private environment data.
- Production deployment requires explicit user instruction.

## Dependency Modes

Bundled mode:

- Chart installs PostgreSQL, Redis, and KEDA dependencies where enabled.
- Suitable for disposable dev clusters and clean installs.
- Must create a usable platform without manual SQL or Redis setup.

External mode:

- Chart connects to pre-existing PostgreSQL, Redis, and KEDA.
- Suitable for production or shared infrastructure.
- Credentials are provided through existing Kubernetes Secrets.

## Migration and Seed Jobs

Migration:

- Runs on install/upgrade when enabled.
- Uses the application image from the release.
- Executes source-controlled migrations from `kubecert`.
- Failing migration fails the release.

Seed:

- Runs after migration.
- Creates/updates baseline data idempotently.
- Must not store exam results or long-lived candidate result data.

DB promotion rules:

- Dev DB contents are not copied to prod.
- Schema changes are promoted by migration files.
- Manual SQL is break-glass only.
- Destructive changes require staged releases.

## Values Requirements

Values must support:

- Image repositories and immutable tags/digests.
- Bundled/external PostgreSQL.
- Bundled/external Redis.
- Bundled/external KEDA. KEDA is required; disabled mode is not supported.
- Existing Secret references.
- Question-bank artifact URL and sha256.
- Runtime artifact manifest URL and sha256, when needed.
- Ingress enabled/disabled and host configuration.

Values must not contain:

- Real private keys.
- Real token values.
- Raw kubeconfig content.
- Production-only secret data.

## Acceptance Criteria

- Chart deployment path is documented as source -> chart -> deploy.
- Dev cluster disposable model is explicit.
- Production promotion and DB migration rules are explicit.
- Bundled and external dependency modes are documented.
- This task aligns with `kubecert/docs/tasks/TASK-002-dev-release-and-db-promotion.md`.
