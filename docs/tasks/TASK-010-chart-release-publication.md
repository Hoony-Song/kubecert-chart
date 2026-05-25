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
