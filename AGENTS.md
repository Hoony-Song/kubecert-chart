# kubecert-chart 작업 규칙

이 저장소는 Kubecert public Helm chart repository이다. 애플리케이션 소스코드와 실제 secret 값은 이 저장소에 저장하지 않는다.

## 읽기 순서

새 작업을 시작하면 아래 문서를 먼저 읽는다.

```text
1. AGENTS.md
2. docs/tasks/TASK-*.md 중 관련 task
3. 필요 시 docs/architecture/*.md
```

이 저장소의 task는 `TASK-001`부터 시작한다. private source repo인 `kubecert`의 task 번호와 독립적으로 관리한다.

## 작업 원칙

- 사용자가 명시적으로 지시하지 않으면 파일 수정, 테스트 실행, 배포, git 작업을 하지 않는다.
- chart repo에는 공개 가능한 문서, chart source, placeholder 기반 example values만 둔다.
- private code 작업은 `kubecert` 저장소에서 진행한다.
- 실제 secret, private key, kubeconfig, token 값은 절대 저장하지 않는다.
- 운영계 배포는 별도 명시 지시 없이는 수행하지 않는다.

## 포함 대상

- Helm chart source
- `values.yaml`
- `values.schema.json`
- `.helmignore`
- public install/upgrade docs
- placeholder 기반 example values
- chart lint/render/release scripts
- chart package/index publication automation

## Chart Migration Map

기본 매핑:

- `cert-platform/charts/cert-platform` -> `charts/kubecert`
- chart name, labels, release examples, resource prefixes는 `cert-platform`에서 `kubecert`로 변경
- `cert-platform/charts/cert-platform/templates/*.yaml` -> `charts/kubecert/templates/`로 선별 이관
- `cert-platform/charts/cert-platform/values.yaml` -> `charts/kubecert/values.yaml`로 scrub 후 이관
- `cert-platform/charts/cert-platform/values.schema.json` -> `charts/kubecert/values.schema.json`
- `cert-platform/deploy/*.example.yaml` -> `examples/`로 scrub 후 이관
- `cert-platform/scripts/helm-*.sh` -> `scripts/ci` 또는 `scripts/release`

이관하지 않는 것:

- `cert-platform/k8s/*.yaml` raw manifest
- 실제 운영 values
- 실제 secret 값
- application source
- generated `dist`, `node_modules`, cache

오픈소스 dependency는 chart 기준으로 관리한다. source branch에는 dependency 정의와 lock을 두고, chart package/release 산출물에는 필요한 dependency chart가 포함되도록 한다.

## 제외 대상

- backend/frontend/runtime/question-bank 소스코드
- 실제 secret 값과 private key
- token 원문
- kubeconfig
- qcow2, ISO, session data
- private 운영 로그

## 운영계와 개발계

- 운영계는 기존 infra RKE2 cluster를 계속 사용한다.
- 개발계는 public cloud Kubernetes cluster이며 disposable environment이다.
- 개발계 kubeconfig는 Git 밖에서 관리한다.
- 개발계와 운영계 모두 Helm chart가 배포 기준이다.
- source에서 cluster로 직접 배포하지 않는다.

표준 개발 배포 흐름:

```text
kubecert source
-> image/artifact build
-> chart values update
-> helm dependency build
-> helm lint/template
-> helm upgrade --install using dev kubeconfig
-> smoke test
```

## Chart 기준

- `charts/kubecert/values.yaml`은 안전한 generic default만 둔다.
- default values에는 환경별 host/domain/public URL/artifact URL/image repository를 하드코딩하지 않는다.
- 운영/개발 차이는 values override로만 표현한다.
- README에는 실제 배포 시 반드시 설정해야 하는 values 항목을 유지한다.
- 기본 설치는 bundled mode를 지원한다.
- PostgreSQL, Redis, KEDA는 bundled mode와 external mode를 모두 지원하도록 설계한다.
- DB migration Job과 seed Job은 install/upgrade 흐름에서 자동화한다.
- Migration Job은 application image의 migration command를 실행한다.
- Seed Job은 migration 성공 이후 실행하고 idempotent해야 한다.
- Secret은 `existingSecret`, 설치 전 생성, 또는 local-only values 주입만 허용한다.
- Question bank는 source 포함보다 artifact URL/sha256 sync 방식을 우선한다.
- Runtime Node OS 준비는 chart 책임이 아니다.

## DB 변경 반영 기준

- 운영 DB 변경은 chart release에 포함된 migration Job으로만 수행한다.
- dev DB 상태를 운영 DB로 복사하지 않는다.
- migration 파일은 `kubecert` source repo가 소유한다.
- chart는 해당 image tag/digest를 사용해 동일 migration을 dev와 prod에 적용한다.
- destructive migration은 자동 rollback을 전제로 설계하지 않는다.

## Public Repo Safety

- README와 examples는 placeholder만 사용한다.
- 공개 values에는 운영 도메인, 운영 secret 이름, 실제 kubeconfig 경로를 넣지 않는다.
- packaged chart에도 secret, key, kubeconfig, source code가 포함되지 않아야 한다.
