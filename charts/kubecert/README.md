# Kubecert Chart

This chart deploys the Kubecert exam platform application workloads and the Helm-managed contracts around them. It does not contain private application source, private keys, kubeconfigs, Runtime Node images, or real secret values.

## Release Defaults

The chart `values.yaml` carries the official Kubecert release defaults:

- component image repositories and immutable release tags
- the default question-bank artifact URL and SHA256
- default ports, resources, and application policy values

Kubecert project images use the `ghcr.io/hoony-song/apps/<image-name>`
repository namespace. Development tags use
`v<next-version>-dev.<yyyymmdd>.r<n>`, while production tags use
`v<released-version>-<yyyymmdd>.r<n>` or digest pinning. Do not use mutable tags
such as `latest`, `current`, `main`, `dev`, `prod`, or `stable`.

Production values should normally not override image or question-bank release
fields. Development values should override image tags when using dev images, and
should override question-bank artifact fields only when testing a dev
question-bank bundle.

## Dependency Modes

PostgreSQL, Redis, and KEDA are modeled with bundled and external modes.

Bundled mode uses Helm dependencies:

- Bitnami PostgreSQL
- Bitnami Redis
- KEDA

Run `helm dependency build charts/kubecert` before local install or packaging. Dependency archives are build/release outputs and are not committed to source.

KEDA is required for worker autoscaling. In `keda.mode=bundled`, the bundled
KEDA dependency installs the operator and this chart vendors the KEDA CRDs under
`crds/` so TriggerAuthentication and ScaledObject resources can be created in
the same Helm install. In `keda.mode=external`, the KEDA CRDs must already exist
or the chart fails fast.

## Secrets

Use existing Secrets for admin bootstrap credentials, Runtime Node SSH keys,
terminal SSH keys, external service credentials, and private R2 credentials.
The application JWT Secret is chart-owned: Helm reuses the existing Secret value
with `lookup`, and creates a random value only on first install.
When Runtime/Terminal SSH existing Secrets are not supplied, the chart runs a
pre-install/pre-upgrade Job that creates missing OpenSSH ed25519 keypairs and
reuses existing Secrets.

Do not commit real passwords, SSH keys, JWT secrets, token values, or kubeconfig content.

## Cloudflare R2

Public artifact downloads use the official question-bank artifact defaults or
explicit artifact URL overrides. Public downloads do not require R2 credentials.
If a workload must access private R2 objects, set
`r2.enabled=true` and provide an existing Secret through `r2.auth.existingSecret`.

The chart injects `CERT_R2_ACCESS_KEY_ID`, `CERT_R2_SECRET_ACCESS_KEY`,
`R2_ACCESS_KEY_ID`, and `R2_SECRET_ACCESS_KEY` into backend workloads when R2
is enabled. Do not put raw R2 keys in public values.

## Frontend API Routing

When ingress is enabled, the chart derives `exam`, `admin`, `api`, and `terminal` hosts
from `ingress.subdomains.* + ingress.baseHost` unless `ingress.hosts.*` provides
an explicit override. The public API URL, CORS origins, and terminal allowed
origins are derived from those hosts and `ingress.tls.enabled`.

By default, the exam frontend uses the current exam page origin for terminal
websockets. A browser that upgrades `http://exam...` to `https://exam...` will
therefore use `wss://exam.../exam/<token>/terminal`, avoiding a separate
terminal-host TLS trust requirement. Set `config.frontend.terminalHost` or
`config.frontend.terminalWsBaseUrl` only when the terminal endpoint has its own
valid external host and TLS/DNS behavior.
Default CORS and terminal allowed-origin lists include both `http://` and
`https://` forms for the derived exam/admin hosts to support external TLS or
browser HSTS upgrades.

The frontend runtime config can still point to a separate API host through
`config.frontend.examApiBaseUrl` and `config.frontend.adminApiBaseUrl` when an
environment needs that override.

For environments where the external ingress or TLS layer should keep browser
traffic on the same host, set `ingress.sameOriginApi.enabled=true` and leave the
frontend API base values empty. The chart then routes exam API paths and the
terminal websocket path through the exam host, and admin API paths through the
admin host.
