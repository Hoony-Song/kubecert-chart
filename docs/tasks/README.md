# Tasks

Tasks in this repository start from `TASK-001`.

Keep chart publication tasks separate from private application implementation
tasks in `kubecert`.

## Roadmap

| Task | Title | Purpose |
|---|---|---|
| TASK-001 | Chart Repository Skeleton | Create public chart repo skeleton. |
| TASK-002 | Dev Chart Deployment Model | Define source -> chart -> deploy flow. |
| TASK-003 | Chart Migration Map | Define existing chart migration mapping. |
| TASK-004 | Values Contract and Required Overrides | Keep defaults generic and document required overrides. |
| TASK-005 | Chart Source Migration | Migrate existing Helm chart into `charts/kubecert`. |
| TASK-006 | Open Source Dependency Bundling | Normalize PostgreSQL, Redis, and KEDA bundled/external modes. |
| TASK-007 | Migration and Seed Jobs | Make DB migration and seed Jobs first-class chart behavior. |
| TASK-008 | Dev and Prod Values Overlays | Provide safe placeholder overlays and private values guidance. |
| TASK-009 | Dev Cluster Helm Smoke | Install to disposable dev cluster using Helm only. |
| TASK-010 | Chart Release Publication | Package and publish the public chart repository. |
| TASK-011 | Values Surface, SSH Key Generation, and Terminal Host Contract | Hide internal defaults, generate SSH keys, and split terminal host. |
| TASK-012 | Session-Scoped Question Bank Bundle Streaming | Make platform-managed question-bank bundles the source of truth for Runtime setup/grade. |
