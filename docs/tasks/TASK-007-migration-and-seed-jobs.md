# TASK-007 Migration and Seed Jobs

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | database | release
```

## 브랜치 기준

```text
feature/migration-seed-jobs
```

## 목표

Make database migration and seed execution first-class Helm install/upgrade behavior.

## 작업 범위

### 허용

- Add migration Job template.
- Add seed Job template.
- Wire image, env, DB, Redis, and Secret references.
- Add Helm hooks or deterministic Job ordering.
- Support enabling/disabling for controlled operations.

### 금지

- Do not require manual SQL for normal install/upgrade.
- Do not store long-lived exam result data.
- Do not assume DB rollback is automatic or safe.
- Do not put credentials in public values.

## 필수 변경사항

- Migration Job runs application migration command.
- Seed Job runs after migration.
- Job failure fails install/upgrade.
- Jobs use the same image tag/digest as the release.
- Jobs work with bundled and external PostgreSQL.

## 완료 조건

- Fresh install migrates and seeds DB.
- Upgrade runs migration safely.
- Seed is idempotent.
- Documentation explains DB promotion policy.

## Validation

```bash
helm template kubecert charts/kubecert -f examples/dev/values.yaml | rg -n "kind: Job|migration|seed"
```

## 문서 갱신 항목

- Record migration/seed commands.
- Record hook/order behavior.

## Status

Completed.

## Job Behavior

- Migration Job:
  - Template: `charts/kubecert/templates/db-jobs.yaml`
  - Name: `<release>-kubecert-db-migrate`
  - Hook: `post-install,post-upgrade`
  - Hook weight: `-20`
  - Command:

```bash
python -m app.migration_adopt && alembic upgrade head
```

- Seed Job:
  - Template: `charts/kubecert/templates/db-jobs.yaml`
  - Name: `<release>-kubecert-db-seed`
  - Hook: `post-install,post-upgrade`
  - Hook weight: `-10`
  - Command:

```bash
python -m app.seed
```

The seed Job runs after migration by hook weight ordering. Both Jobs use the same API image tag/digest as the release.

## Secret and Env Contract

- Both Jobs use the chart DB env helper and support bundled/external PostgreSQL.
- Seed reads `CERT_INITIAL_ADMIN_USERNAME` and `CERT_INITIAL_ADMIN_PASSWORD` from the configured admin Secret.
- Public values do not contain secret values. Real deployments must provide existing Secrets or private local values enabling temporary Secret creation.

## Validation Result

2026-05-26:

- `helm template kubecert charts/kubecert -f examples/dev/values.yaml | rg -n "kind: Job|migration|seed"`
  - Passed: migration and seed Jobs render.
- `helm template kubecert charts/kubecert -f examples/external-services/values.yaml | rg -n "kind: Job|migration|seed"`
  - Passed: Jobs render with external PostgreSQL values.
- `helm lint charts/kubecert`
  - Passed: 1 chart linted, 0 failed. Helm reported only the optional icon recommendation.
