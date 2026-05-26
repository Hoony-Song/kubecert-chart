# TASK-012 Session-Scoped Question Bank Bundle Streaming

## 저장소

```text
kubecert
kubecert-chart
```

## 작업 유형

```text
architecture | runtime-contract | question-bank | helm | migration
```

## 브랜치 기준

```text
feature/session-question-bank-bundles
```

## 배경

현재 question-bank artifact는 플랫폼과 Runtime Node 양쪽에서 사용된다.

```text
platform question-bank
-> 문제 본문, 정답, exam set, token/session question list 표시용

runtime question-bank
-> 세션 VM setup, prerequisite, grading 실행용
```

현재 운영 values와 runtime manifest는 같은 tarball을 가리키고 있지만, URL/sha256이 두 군데에 중복으로 존재한다.

```text
prod-values.yaml
  questionBank.artifactUrl
  questionBank.artifactSha256

runtime-node manifest
  questionBank.url
  questionBank.sha256
```

이 구조는 사람이 한쪽만 수정하면 platform과 Runtime Node가 서로 다른 question-bank 버전을 사용할 수 있다.

또한 기존 Runtime Node는 join 시점에 question-bank를 내려받으므로, 이후 question-bank setup/grade가 변경되어도 기존 노드가 자동으로 새 bundle을 받지 않는다.

## 목표

플랫폼 클러스터가 question-bank bundle의 기준점(source of truth)이 되고, 세션 생성 시점에 사용할 question-bank bundle 정보를 provision/grade payload로 Runtime Node에 전달한다.

Runtime Node는 payload의 bundle URL/sha/version을 기준으로 로컬 캐시에 다운로드하고, 세션 setup/grade는 세션에 고정된 bundle 버전으로 실행한다.

핵심 목표:

- Runtime Node에 영구적으로 설치된 question-bank 버전에 의존하지 않는다.
- 기존 Runtime Node와 새 Runtime Node가 같은 세션 payload 계약을 따른다.
- 기존 세션은 생성 당시 question-bank bundle 버전을 유지한다.
- 새 세션은 현재 운영 question-bank bundle 버전을 사용한다.
- question-bank 본문/정답과 setup/grade 버전 불일치를 방지한다.
- 매 세션마다 전체 bundle을 다시 받지 않고 sha256 기반 캐시를 재사용한다.

## 핵심 결정

- 최신 추적보다 세션별 버전 고정이 중요하다.
- 구현과 최종 검증은 개발계에서 먼저 수행한다.
- 세션 생성 시점의 question-bank bundle metadata를 DB에 저장한다.
- Runtime setup/grade payload에는 question-bank bundle metadata를 항상 포함한다.
- Runtime Node는 bundle sha256을 기준으로 캐시한다.
- 캐시 hit이면 재사용하고, 캐시 miss이면 다운로드 후 sha256 검증한다.
- 다운로드/검증 실패 시 provision/grade는 실패해야 하며, 잘못된 bundle로 계속 진행하면 안 된다.
- Runtime Node join installer의 question-bank 설치는 필수 source of truth가 아니라 optional cache warmup으로 격하한다.
- Helm chart는 운영 question-bank artifact 계약을 명확히 표현하되, runtime manifest와 platform question-bank가 따로 놀지 않도록 한다.

## 원하는 최종 흐름

```text
question-bank 수정
-> validate/package
-> versioned tarball publish
-> sha256 생성
-> platform current question-bank artifact 갱신
-> helm upgrade
-> 새 세션 생성
-> DB sessions에 questionBankVersion/url/sha 저장
-> provision payload에 questionBank 포함
-> Runtime Node cache 확인
   -> 있으면 재사용
   -> 없으면 다운로드/sha256 검증/extract
-> 해당 bundle 기준으로 setup 실행
-> grade payload에도 같은 questionBank 포함
-> 같은 bundle 기준으로 grade 실행
```

## 작업 범위

### 1. Platform DB Contract

`sessions`에 question-bank bundle metadata를 저장한다.

예상 컬럼:

```text
question_bank_version
question_bank_url
question_bank_sha256
question_bank_created_at 또는 question_bank_published_at (선택)
```

원칙:

- 세션 생성 시점에 값을 고정한다.
- 기존 세션은 nullable/default migration으로 깨지지 않게 한다.
- 기존 세션에 값이 없으면 기존 Runtime Node local question-bank fallback을 허용할 수 있다.
- Alembic migration을 추가한다.

### 2. Platform Question Bank Artifact Resolver

플랫폼은 현재 운영 question-bank artifact를 한 곳에서 resolve한다.

가능한 입력:

```yaml
questionBank:
  version: v20260527-r1
  artifactUrl: https://...
  artifactSha256: ...
```

또는 runtime manifest 기반:

```yaml
config:
  runtimeNodeManifestUrl: https://.../runtime-node-vYYYYMMDD-rN.json
```

권장 방향:

- 단기: `questionBank.version/artifactUrl/artifactSha256`를 platform source of truth로 둔다.
- 중기: runtime manifest도 이 값으로 자동 생성하거나, platform sync job이 manifest를 읽어 같은 값을 사용하게 한다.
- 운영에서 사람이 `prod-values.yaml`과 runtime manifest를 각각 직접 수정하는 흐름은 제거한다.

### 3. Provision Payload Contract

provision payload에 question-bank bundle metadata를 추가한다.

예상 payload:

```json
{
  "session_id": "sess-...",
  "exam_type": "CKS",
  "exam_set_id": "cks-mock-001",
  "question_ids": ["cks-q001"],
  "question_bank": {
    "version": "v20260527-r1",
    "url": "https://artifacts.sweetlabs.kr/runtime/question-bank/cert-question-bank-v20260527-r1.tar.gz",
    "sha256": "..."
  }
}
```

주의:

- payload에는 raw secret을 넣지 않는다.
- URL은 public artifact URL 또는 signed/authorized URL 계약을 별도 task로 둔다.
- sha256은 필수다.

### 4. Grade Payload Contract

grade payload도 provision과 같은 question-bank metadata를 사용한다.

이유:

- 세션 생성 이후 운영 question-bank가 바뀌어도 해당 세션 채점은 생성 당시 버전으로 해야 한다.
- 문제 본문과 setup/grade 기준이 섞이지 않아야 한다.

### 5. Runtime Cache/Download Layer

Runtime scripts에 question-bank bundle cache resolver를 추가한다.

예상 경로:

```text
/var/lib/cert/question-bank/cache/<sha256>/
/var/lib/cert/question-bank/downloads/<sha256>.tar.gz
```

예상 동작:

```text
if cache/<sha256> exists and marker valid:
  use cache
else:
  download url to downloads/<sha256>.tar.gz.tmp
  verify sha256
  extract to cache/<sha256>.tmp
  write marker metadata
  atomic move to cache/<sha256>
```

필수:

- concurrent provision이 같은 sha를 동시에 받을 수 있으므로 lock이 필요하다.
- 다운로드 실패 시 명확한 오류를 반환한다.
- sha mismatch면 cache를 사용하지 않는다.
- tar extraction path traversal 방어를 검토한다.
- 캐시 GC 정책은 별도 옵션으로 둔다.

### 6. Runtime Script Integration

아래 runtime script가 payload question-bank cache path를 사용해야 한다.

```text
runtime/scripts/provision-session.sh
runtime/scripts/grade-session.sh
runtime/scripts/question setup/prerequisite loader
```

원칙:

- payload에 question_bank가 있으면 해당 bundle cache를 우선 사용한다.
- payload에 question_bank가 없으면 기존 로컬 question-bank 경로 fallback을 유지해 단계적 전환을 허용한다.
- setup과 grade가 서로 다른 bundle을 보지 않게 한다.

### 7. Runtime Node Join Installer 변경

Runtime Node join installer의 question-bank 설치는 필수가 아니라 cache warmup으로 바꾼다.

단기 허용:

- manifest에 questionBank가 있으면 기존처럼 미리 다운로드해 캐시를 채운다.

장기 목표:

- join installer는 runtime binary/script/golden image 준비에 집중한다.
- 세션별 question-bank는 payload 기반 cache resolver가 책임진다.

### 8. Helm Chart 변경

chart는 platform question-bank artifact contract를 명확히 표현한다.

필수:

- default values에는 real artifact URL을 넣지 않는다.
- prod/dev private values가 현재 운영 question-bank artifact를 지정한다.
- question-bank sync Job은 platform 기준 artifact를 sync한다.
- Runtime Node join command가 사용하는 manifest와 platform question-bank artifact가 다르면 lint 또는 preflight에서 잡는다.

가능한 preflight:

```text
if config.runtimeNodeManifestUrl is set:
  fetch manifest
  compare manifest.questionBank.url/sha256 with questionBank.artifactUrl/artifactSha256
  mismatch면 fail 또는 warning
```

## 단계별 구현 계획

### Phase 1. 계약 추가

- DB migration 추가.
- session model/domain/schema에 question-bank artifact 필드 추가.
- current question-bank artifact resolver 추가.
- provision/grade payload에 question_bank 추가.
- 기존 Runtime은 아직 fallback을 사용하므로 기능 영향 최소화.

### Phase 2. Runtime cache resolver

- Runtime script에 download/cache/verify 함수 추가.
- payload question_bank를 받을 수 있게 provision/grade command 인자 또는 payload 파일을 확장.
- cache hit/miss 테스트 추가.
- 기존 local question-bank fallback 유지.

### Phase 3. Runtime setup/grade 전환

- setup/prerequisite/grading이 cache path를 기준으로 실행되게 변경.
- CKA/CKS 각 1세션 provision/grade 검증.
- 기존 Runtime Node에서도 새 payload로 동작하는지 확인.

### Phase 4. Helm/Release 싱크 가드

- chart values와 runtime manifest questionBank mismatch 검증 추가.
- prod/dev 운영 루틴 문서화.
- question-bank publish 루틴에서 chart private values 또는 manifest metadata 갱신 절차 정리.

### Phase 5. 기존 join installer 격하

- join installer question-bank download를 cache warmup으로 재정의.
- 새 Runtime Node join 시 최신 payload 기반 세션이 정상 작동하는지 확인.

## 검증 계획

### Unit/Static

```text
API model/schema tests
payload contract tests
runtime cache resolver shell tests
helm lint/template
```

### Integration

```text
1. dev cluster Helm deploy
2. question-bank vA로 CKA 세션 생성
3. question-bank vB publish 후 Helm upgrade
4. 기존 세션은 vA metadata 유지 확인
5. 새 세션은 vB metadata 사용 확인
6. Runtime Node cache에 vA/vB가 sha별로 공존 확인
7. CKA/CKS provision READY 확인
8. CKA/CKS submit/grade/cleanup 확인
```

### Final Dev Acceptance

최종 검증은 개발계에서 CKA answer 추가를 포함해 수행한다.

현재 CKA question-bank에는 answer가 없으므로, CKS answer 구조와 같은 방식으로 CKA answer 파일을 생성한다. 실제 정답 내용은 이번 task의 핵심이 아니므로 아래 수준의 placeholder를 사용한다.

```text
answer 준비중
```

검증 의도:

- CKA answer 파일이 question-bank bundle에 포함되는지 확인한다.
- 새 bundle publish 후 dev Helm upgrade로 platform이 최신 question-bank metadata를 잡는지 확인한다.
- 새 CKA 세션 provision payload에 변경된 question-bank version/url/sha가 들어가는지 확인한다.
- Runtime Node가 기존 노드 재설치 없이 새 bundle을 캐시하고 setup/grade에 사용하는지 확인한다.
- 시험 화면에서 정답 확인 또는 answer 조회 흐름이 최신 bundle 기준으로 반영되는지 확인한다.

### Failure Case

```text
bad sha256 -> provision fail
missing URL -> provision fail
download timeout -> provision fail and cleanup path 확인
cache corrupted -> re-download or fail with clear message
runtime local fallback disabled 상태에서 payload 누락 -> fail
```

## 운영 루틴 목표

최종 운영자는 question-bank 수정 후 아래처럼 처리한다.

```text
question-bank 수정
-> package/publish
-> dev values에 새 artifact version/url/sha 적용
-> dev Helm upgrade
-> dev CKA/CKS 세션 생성/채점 검증
-> prod values에 검증된 artifact version/url/sha 적용
-> prod Helm upgrade
-> 새 세션부터 새 question-bank 적용
```

런타임 노드는 새로 join하지 않아도 새 세션 payload 기준으로 필요한 bundle을 받아 쓴다.

## 비범위

- question-bank 전체를 DB row로 분해해서 저장하는 구조 변경.
- 실시간으로 진행 중인 세션의 setup 상태를 변경하는 기능.
- 시험 진행 중 기존 세션의 grading 기준을 최신으로 바꾸는 기능.
- private artifact signed URL 인증 체계.
- CDN/R2 권한 모델 전면 재설계.

## 위험

- provision/grade runtime path 변경은 CKA/CKS 모두에 영향이 크다.
- cache lock이 부실하면 동시 세션 생성 때 bundle이 깨질 수 있다.
- 운영 중인 세션의 question-bank 버전 고정이 깨지면 채점 신뢰성이 떨어진다.
- tar extraction 보안 검토가 필요하다.

## 완료 조건

- 세션 DB에 question-bank bundle metadata가 저장된다.
- provision/grade payload에 question_bank가 포함된다.
- Runtime Node가 payload bundle을 sha256 검증 후 캐시한다.
- setup/grade는 세션에 고정된 bundle path를 사용한다.
- 기존 Runtime Node도 새 세션 생성 시 최신 bundle을 받을 수 있다.
- 새 Runtime Node join이 question-bank 사전 설치 없이도 세션 생성/채점에 성공한다.
- Helm dev/prod values와 runtime manifest의 question-bank 싱크 정책이 문서화된다.
- 개발계에서 CKA answer placeholder 추가 후 새 bundle이 platform/Runtime 양쪽에 반영되는 것을 확인한다.
- dev에서 CKA/CKS 세션 생성, 터미널 접속, 제출, 채점, cleanup이 통과한다.

## 현재 구현 상태

구현 브랜치:

```text
kubecert:       feature/session-question-bank-bundles
kubecert-chart: feature/session-question-bank-bundles
```

반영 완료:

- API session DB/model/domain에 `question_bank_version`, `question_bank_url`, `question_bank_sha256` 계약 추가.
- 세션 생성 시점 question-bank bundle metadata freeze 처리.
- provision/grade payload와 Runtime SSH executor 인자에 `question_bank` 전달.
- Runtime bundle resolver 추가: sha256 기반 download/cache/extract, lock, path traversal 방어, local fallback.
- `provision-session.sh`, `grade-session.sh`가 세션 payload의 question-bank bundle path를 사용하도록 전환.
- Runtime installer의 question-bank download를 필수 설치에서 optional cache warmup으로 격하.
- Runtime manifest에 `questionBank.version` 포함.
- CKA answer placeholder를 CKS와 같은 `answer/solution.md` 구조로 추가.
- Helm chart가 sync Job에서 `.kubecert-question-bank.json` metadata를 쓰고 API/Worker env로 전달.
- README required overrides에 `questionBank.version/artifactUrl/artifactSha256` 계약 문서화.

검증 완료:

```text
bash -n runtime scripts/installer/release scripts
question-bank validator
question-bank package tarball 생성
Runtime resolver file:// bundle download/cache/sha 검증
provision-session.sh --dry-run question-bank payload 검증
grade-session.sh --dry-run question-bank payload 검증
helm lint charts/kubecert --values dev-values.yaml
helm template charts/kubecert --values dev-values.yaml
API pytest: test_db_schema.py, test_backend_flow.py
```

주의/남은 정리:

- `/root/Certifications/dev-config`는 client cert/key가 있으나 API 서버 인증서 SAN이 `api.210-178-39-81.nip.io`와 맞지 않는다.
- 개발계 검증은 SSH로 dev 단일 노드에 접속한 뒤 `/etc/rancher/rke2/rke2.yaml`을 사용했다.
- dev Runtime Node에는 검증을 위해 현재 source의 `runtime/` bundle을 반영했다. 운영 반영 전에는 runtime artifact publish 루틴으로 정식 bundle/installer를 배포해야 한다.

## 개발계 검증 기록

개발 단일 노드는 SSH 접속 후 `/etc/rancher/rke2/rke2.yaml`을 사용해 검증했다.

```text
ssh -i key.pem ubuntu@210.178.39.80 -p 20011
KUBECONFIG=/etc/rancher/rke2/rke2.yaml
```

검증 중 발견/수정한 항목:

- Alembic revision ID `0009_session_question_bank_bundle`가 `alembic_version.version_num varchar(32)`보다 길어 migration이 실패했다.
  - revision ID를 `0009_qb_bundle`로 줄여 해결했다.
- dev Runtime Node의 `/var/lib/cert/runtime`이 구버전이라 `--question-bank-url` 인자를 받지 못했다.
  - dev 검증용 Runtime Node에 현재 source의 `runtime/` bundle을 반영했다.
  - 이후 `provision-session.sh`, `grade-session.sh`, `resolve-question-bank-bundle.sh` 계약이 맞는 것을 확인했다.
- source `package-question-bank` tarball은 `question-bank/...` 루트를 포함한다.
  - chart sync Job이 nested `question-bank/` 루트를 감지해 target root로 normalize하도록 수정했다.

검증 완료:

```text
image build/push:
  ghcr.io/hoony-song/apps/*:v1.0.0-dev.20260526.r3

helm:
  revision 8: app image + migration 성공
  revision 9: answer 포함 dev question-bank artifact sync
  revision 10: nested question-bank root normalize 후 sync 성공
  revision 11: 정식 R2 artifact URL로 question-bank sync 성공

db:
  alembic_version = 0009_qb_bundle
  sessions.question_bank_version
  sessions.question_bank_url
  sessions.question_bank_sha256

official question-bank artifact:
  version = v20260526-dev-answer-stream-r2
  url = https://artifacts.sweetlabs.kr/question-bank/kubecert-question-bank-v20260526-dev-answer-stream-r2.tar.gz
  sha256 = 1d94dc27a170d4d6533c730bfa3ae7aac11408e12058b297375a093cfd7580d6

question-bank:
  platform metadata = v20260526-dev-answer-stream-r2
  runtime cache contains old sha and new sha side by side

smoke:
  CKA token created
  CKA provision READY
  Start Exam 성공
  questions count = 16
  first question = cka-q002
  answer endpoint body = "# 정답 ... answer 준비중"
  smoke sessions cleanup = CLEANED
  CKS token created
  CKS provision READY
  CKS cleanup = CLEANED

db session freeze check:
  CKA session question_bank_version/url/sha = official artifact r2
  CKS session question_bank_version/url/sha = official artifact r2
```
