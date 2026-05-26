# Chart Release

Kubecert chart releases are public. They must contain chart source, rendered-safe defaults, and bundled open source dependency charts only.

## Version Policy

- Update `charts/kubecert/Chart.yaml` `version` for every chart contract change.
- Update `appVersion` only when the private `kubecert` application release baseline changes.
- Do not use `latest`, `main`, or mutable image tags as the release contract.
- Real dev/prod image tags or digests are supplied by values files outside this public repository.
- Project images use `ghcr.io/hoony-song/apps/<image-name>`.
- Development image tags use `v<next-version>-dev.<yyyymmdd>.r<n>`.
- Production image tags use `v<released-version>-<yyyymmdd>.r<n>` or digest
  pinning.
- Production values must never reference dev tags or mutable aliases such as
  `latest`, `current`, `main`, `dev`, `prod`, or `stable`.

## Local Package

```bash
scripts/release/package-chart.sh \
  --destination /tmp/kubecert-chart-dist \
  --repo-url https://Hoony-Song.github.io/kubecert-chart
```

The script runs:

- `helm dependency build`
- `helm lint`
- `helm package`
- bundled dependency validation
- secret/private marker validation
- `helm repo index`

## Public Repository

GitHub Pages publication is handled by `.github/workflows/chart-release.yml`.

Trigger it with a tag:

```bash
git tag kubecert-chart-v0.1.0
git push origin kubecert-chart-v0.1.0
```

After Pages is enabled for the repository, consumers can use:

```bash
helm repo add kubecert https://Hoony-Song.github.io/kubecert-chart
helm repo update
helm upgrade --install kubecert kubecert/kubecert \
  --namespace kubecert \
  --create-namespace \
  -f /path/to/private-values.yaml
```

## Required Release Checks

- Chart package contains `postgresql`, `redis`, and `keda` dependency charts.
- Chart package contains no kubeconfig, private key, `.env`, or secret files.
- `helm show chart <package>` succeeds.
- `helm lint charts/kubecert` succeeds.
- `helm template` succeeds with the public example values.
