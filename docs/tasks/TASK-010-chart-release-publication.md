# TASK-010 Chart Release Publication

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | release | ci
```

## 브랜치 기준

```text
feature/chart-release-publication
```

## 목표

Package and publish the public Kubecert Helm chart repository.

## 작업 범위

### 허용

- Add chart package script.
- Add chart index generation.
- Add GitHub Pages or equivalent chart repository publication.
- Add chart release CI.

### 금지

- Do not publish real secrets.
- Do not publish private application source.
- Do not publish unvalidated chart packages.
- Do not use `latest` as the release contract.

## 필수 변경사항

- Chart versioning policy.
- App version/image tag policy.
- `helm package` automation.
- `helm repo index` automation.
- Release validation workflow.

## 완료 조건

- Public chart package can be downloaded.
- `helm repo add` works against the published index.
- Published chart contains dependency charts as intended.
- Published chart contains no secrets or private source.

## Validation

```bash
helm dependency build charts/kubecert
helm lint charts/kubecert
helm package charts/kubecert --destination dist
helm repo index dist
helm show chart dist/kubecert-*.tgz
```

## 문서 갱신 항목

- Record chart repository URL.
- Record release command summary.

## Status

Completed for package and GitHub Pages publication tooling. Actual public Pages
deployment runs from GitHub Actions after a `kubecert-chart-v*` tag is pushed
and Pages is enabled for the repository.

## Implemented Files

- `scripts/release/package-chart.sh`
  - Builds dependencies, lints, packages, validates, and generates `index.yaml`.
- `scripts/release/validate-chart-package.sh`
  - Verifies Helm can read the package.
  - Verifies bundled PostgreSQL, Redis, and KEDA dependency charts exist.
  - Rejects known private file names and private marker content.
- `.github/workflows/chart-release.yml`
  - Packages the chart and publishes the generated repository with GitHub Pages.
- `docs/operations/chart-release.md`
  - Documents version policy, local package command, public repo URL, and release checks.
- `README.md`
  - Documents the release script and bundled dependency validation.

## Release Policy

- Public chart repo URL: `https://Hoony-Song.github.io/kubecert-chart`.
- Chart version is controlled by `charts/kubecert/Chart.yaml` `version`.
- Application image version is controlled by immutable tags or digests in private values.
- Do not use `latest`, `main`, or mutable image tags as release contracts.
- Do not commit packaged `.tgz` files or generated `index.yaml`; GitHub Pages receives generated artifacts from CI.

## Validation Result

2026-05-26:

```bash
chmod +x scripts/release/package-chart.sh scripts/release/validate-chart-package.sh
bash -n scripts/release/package-chart.sh
bash -n scripts/release/validate-chart-package.sh
helm dependency build charts/kubecert
helm lint charts/kubecert
scripts/release/package-chart.sh --destination /tmp/kubecert-chart-dist --repo-url https://Hoony-Song.github.io/kubecert-chart
helm show chart /tmp/kubecert-chart-dist/kubecert-0.1.0.tgz
tar -tzf /tmp/kubecert-chart-dist/kubecert-0.1.0.tgz | rg 'kubecert/charts/(postgresql|redis|keda)(-|/)'
```

All commands passed.

Observed package structure:

- `kubecert/charts/postgresql/...`
- `kubecert/charts/redis/...`
- `kubecert/charts/keda/...`

Helm packages the dependency charts as expanded subchart directories inside the
final `.tgz`, so the release validator accepts either dependency archives or
expanded subchart directories.

Additional safety checks passed:

- No forbidden secret/private file names in the chart package.
- No first-party `values.yaml` private markers such as private key headers,
  old host markers, placeholder image tags, or placeholder digests.
