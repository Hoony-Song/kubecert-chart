# TASK-011 Values Surface, SSH Key Generation, and Terminal Host Contract

## 저장소

```text
kubecert-chart
```

## 작업 유형

```text
helm | configuration | security | ingress | source-contract
```

## 브랜치 기준

```text
feature/values-surface-and-terminal-host
```

## 배경

이 작업은 컨텍스트 압축 후에도 설계 결정이 손실되지 않도록 남기는 기준 태스크이다.

현재 `charts/kubecert/values.yaml`에는 설치자가 몰라도 되는 내부 구현값이 노출되어 있다. 특히 artifact 기본 주소, Runtime/Terminal SSH key mount path, R2 access key 구조가 default values의 공개 계약처럼 보인다.

또한 terminal websocket은 현재 terminal 전용 host로 분리되어 있지 않다. 새 차트는 API ingress 또는 `sameOriginApi` 경로를 통해 `/exam/{token}/terminal`을 terminal-gateway로 라우팅한다. 사용자는 Cloudflare proxied/DNS-only, 로컬 no-TLS, 운영 TLS 환경을 모두 설정만으로 전환할 수 있도록 terminal host를 명시적으로 분리하기를 원한다.

## 핵심 결정

- Helm default values는 내부 구현 덤프가 아니다.
- default values에는 real host, real artifact URL, 내부 mount path, private key, kubeconfig, token, R2 access key를 두지 않는다.
- 공개 artifact 다운로드는 HTTP(S) public URL만 사용하므로 기본 Helm 설치에는 R2 access key가 필요 없다.
- R2 private object 접근이 필요해지는 경우가 생기더라도 기본 설치 계약이 아니라 별도 advanced/private mode로 격리한다.
- artifact base URL과 runtime manifest/installer 기본 경로는 Helm values에 공개 기본값으로 두지 않는다.
- Runtime/Terminal SSH key path는 설치자가 바꿀 값이 아니므로 values 계약에서 숨긴다.
- Runtime/Terminal SSH keypair는 사용자가 미리 Secret으로 만드는 방식이 아니라 Helm 설치 과정에서 자동 생성한다.
- SSH key Secret은 upgrade 때 재생성하면 기존 Runtime Node/세션 연결이 깨질 수 있으므로 기존 Secret이 있으면 반드시 재사용한다.
- terminal websocket host는 `api` host와 분리 가능해야 한다.
- terminal host는 TLS enabled이면 `wss://`, TLS disabled이면 `ws://`로 동작해야 한다.
- 직접 클러스터에 땜빵하지 않고 Helm chart와 source contract에 반영한 뒤 Helm 루틴으로 검증한다.

## 현재 문제

### Default Values 노출

현재 default values에 아래와 같은 내부/환경 의존 값이 노출되어 있다.

```yaml
config:
  artifactBaseUrl: https://artifacts.sweetlabs.kr
  runtimeNodeInstallerPath: runtime/installer/install.sh
  runtimeNodeManifestPath: runtime/manifests/runtime-node-v20260526-cks-apiserver-probe-r1.json
  runtime:
    root: /var/lib/cert
    healthSshKeyPath: /etc/cert/runtime/id_ed25519
    authorizedKeyPath: /etc/cert/runtime/id_ed25519.pub
    vmAdminSshKeyPath: /etc/cert/terminal/runtime_admin_key
    vmAdminAuthorizedKeyPath: /etc/cert/terminal/runtime_admin_key.pub
  terminal:
    sshKeyPath: /etc/cert/ssh/runtime_admin_key
    sshPublicKeyPath: /etc/cert/ssh/runtime_admin_key.pub
    runtimeSshKeyPath: /etc/cert/runtime/id_ed25519
r2:
  auth:
    accessKeyIdKey: access-key-id
    secretAccessKeyKey: secret-access-key
```

문제점:

- public chart 사용자가 변경할 이유가 없는 내부 path가 values API처럼 보인다.
- sweetlabs artifact 주소가 default values에 고정되어 공개 chart의 환경 독립성을 해친다.
- public artifact download만 하는 설치에 R2 credential이 필요한 것처럼 보인다.
- Secret key material을 사용자가 직접 values로 넣는 경로가 남아 있다.

### Terminal Host 미분리

현재 chart host 계약은 `exam`, `admin`, `api`만 가진다.

```yaml
ingress:
  subdomains:
    exam: exam
    admin: admin
    api: api
  hosts:
    exam: ""
    admin: ""
    api: ""
```

현재 동작:

- 기본: `api.<baseHost>/exam/{token}/terminal` -> terminal-gateway
- `sameOriginApi.enabled=true`: `exam.<baseHost>/exam/{token}/terminal` -> terminal-gateway

원하는 동작:

- `terminal.<baseHost>/exam/{token}/terminal` -> terminal-gateway
- exam/admin/api와 terminal websocket endpoint 설정이 분리된다.
- Cloudflare에서 exam/admin은 proxied로 두고 terminal은 DNS-only로 두는 식의 운영 선택이 가능하다.
- 로컬/no-TLS 환경은 `ws://terminal.<host>`로 동작한다.
- TLS 운영 환경은 `wss://terminal.<host>`로 동작한다.

## 작업 범위

### 허용

- `values.yaml`의 public surface를 줄인다.
- 내부 path 값을 values에서 제거하고 chart template 또는 application default contract로 이동한다.
- public artifact 기본값을 chart values에서 제거한다.
- R2 credential block을 제거하거나 advanced/private mode로 격리한다.
- SSH keypair 자동 생성 Job, ServiceAccount, Role, RoleBinding을 추가한다.
- 기존 Secret reuse를 보장한다.
- terminal host values contract를 추가한다.
- terminal 전용 Ingress를 추가한다.
- `kubecert` source의 exam-web terminal websocket base URL contract를 추가한다.
- README, chart README, examples, tasks를 갱신한다.

### 금지

- 실제 R2 access key를 values, examples, docs에 넣지 않는다.
- 실제 private key를 values, examples, docs에 넣지 않는다.
- `sweetlabs.kr` 실주소를 default values에 넣지 않는다.
- 내부 path를 사용자가 반드시 설정해야 하는 required values로 만들지 않는다.
- upgrade 때 SSH key Secret을 재생성하지 않는다.
- kubectl로 운영 클러스터를 직접 수정해서 해결하지 않는다.
- Helm template에 환경별 host나 artifact URL을 하드코딩하지 않는다.

## 필수 변경사항

### 1. Default Values Surface 정리

`charts/kubecert/values.yaml`에서 아래를 제거하거나 advanced/internal 구조로 격리한다.

- `config.artifactBaseUrl`의 실주소 기본값
- `config.runtimeNodeInstallerPath`
- `config.runtimeNodeInstallerUrl`
- `config.runtimeNodeManifestPath`
- `config.runtimeNodeManifestUrl`
- `config.runtime.root`
- `config.runtime.healthSshKeyPath`
- `config.runtime.authorizedKeyPath`
- `config.runtime.vmAdminSshKeyPath`
- `config.runtime.vmAdminAuthorizedKeyPath`
- `config.runtime.sshKeyPath`
- `config.terminal.sshKeyPath`
- `config.terminal.sshPublicKeyPath`
- `config.terminal.runtimeSshKeyPath`
- 기본 설치에 필요 없는 `r2.auth.*`

정리 기준:

- 앱 내부에서 고정되어도 되는 값은 source/application default로 보낸다.
- chart template에서 mount path가 필요하면 values가 아닌 helper/local constant로 둔다.
- 사용자가 실제로 배포 때 바꿔야 하는 값만 values 계약으로 남긴다.

### 2. R2/Public Artifact 계약 정리

기본 설치는 public artifact URL만 사용한다.

원칙:

- `r2.enabled=false`가 기본이다.
- 기본 설치에서 R2 access key Secret은 만들지 않는다.
- question bank/runtime artifact download는 공개 URL 또는 app default contract를 따른다.
- private artifact mode가 필요하면 별도 `artifact.private.enabled` 또는 유사한 advanced block으로 분리한다.

### 3. SSH Key 자동 생성

Helm install/upgrade 과정에서 Runtime health key와 VM admin terminal key를 생성한다.

생성 대상:

```text
<release>-runtime-ssh
<release>-terminal-ssh
```

예상 data keys:

```text
runtime SSH:
- id_ed25519
- id_ed25519.pub

terminal SSH:
- runtime_admin_key
- runtime_admin_key.pub
```

구현 방향:

- pre-install/pre-upgrade Helm hook Job을 추가한다.
- Job은 namespace 안에 Secret이 이미 있는지 확인한다.
- Secret이 있으면 아무것도 바꾸지 않는다.
- Secret이 없을 때만 `ssh-keygen -t ed25519`로 keypair를 생성하고 Secret을 만든다.
- Job에 필요한 최소 RBAC만 부여한다.
- Job 완료 후 Job/Pod는 정리하되 Secret은 유지한다.
- `existingSecret` override는 advanced escape hatch로 유지할 수 있다.

주의:

- Helm template 함수만으로 OpenSSH ed25519 keypair를 제대로 만들 수 없으므로 Job 방식이 맞다.
- upgrade 때 key가 바뀌면 Runtime Node join/health/terminal 접속이 깨질 수 있다.
- key 생성 Job이 실패하면 application Pods가 잘못 뜨지 않도록 install 실패가 명확해야 한다.

### 4. Terminal Host 분리

values contract에 terminal host를 추가한다.

예상 구조:

```yaml
ingress:
  baseHost: ""
  subdomains:
    exam: exam
    admin: admin
    api: api
    terminal: terminal
  hosts:
    exam: ""
    admin: ""
    api: ""
    terminal: ""
```

라우팅:

```text
terminal.<baseHost>/exam/{token}/terminal -> terminal-gateway
```

기존 compatibility:

- API host terminal path는 유지할 수 있다.
- `sameOriginApi.enabled=true`의 exam host terminal path는 유지할 수 있다.
- terminal 전용 host가 설정되면 frontend websocket base는 terminal host를 우선한다.

### 5. Source Contract 변경

`kubecert` source에 terminal websocket base URL 설정을 추가한다.

예상 env/config:

```text
VITE_TERMINAL_WS_BASE_URL
```

동작:

- 값이 있으면 exam-web은 해당 base URL로 terminal websocket을 연다.
- 값이 없으면 기존 fallback을 사용한다.
- TLS disabled 환경에서는 `ws://...`
- TLS enabled 환경에서는 `wss://...`

Helm chart는 `ingress.tls.enabled`와 terminal host를 기준으로 frontend env를 생성한다.

### 6. Documentation and Harness

아래 문서에 정책을 반영한다.

- `README.md`
- `charts/kubecert/README.md`
- `docs/tasks/README.md`
- `examples/dev/values.yaml`
- `examples/prod/values.yaml`
- 루트 `/root/Certifications/ref.md`

문서에 남길 핵심:

- default values는 설치 surface만 가진다.
- R2 access key는 public artifact download에는 필요 없다.
- SSH keypair는 chart가 생성하고 기존 Secret은 재사용한다.
- terminal host는 API host와 분리 가능하다.
- no-TLS는 `http/ws`, TLS는 `https/wss`로 자동 파생한다.

## 완료 조건

- `charts/kubecert/values.yaml`에 `sweetlabs.kr`, `artifacts.sweetlabs.kr`, `/var/lib/cert`, `/etc/cert/runtime`, `/etc/cert/terminal`, `/etc/cert/ssh` 같은 내부/환경 의존 default가 없다.
- 기본 install에 R2 access key 입력이 필요 없다.
- `helm install` 한 번으로 SSH key Secret이 생성된다.
- `helm upgrade` 후에도 기존 SSH key Secret data가 유지된다.
- terminal 전용 host가 렌더링된다.
- exam-web이 terminal host websocket URL을 사용할 수 있다.
- no-TLS dev values는 `ws://terminal.<host>`를 생성한다.
- TLS prod values는 `wss://terminal.<host>`를 생성한다.
- examples는 secret 값과 real private values를 포함하지 않는다.

## Validation

Static checks:

```bash
rg -n "sweetlabs|artifacts\\.sweetlabs|/var/lib/cert|/etc/cert/runtime|/etc/cert/terminal|/etc/cert/ssh|accessKeyIdValue|secretAccessKeyValue" charts/kubecert/values.yaml
helm lint charts/kubecert -f examples/dev/values.yaml
helm template kubecert charts/kubecert -f examples/dev/values.yaml >/tmp/kubecert-dev-render.yaml
helm template kubecert charts/kubecert -f examples/prod/values.yaml --api-versions keda.sh/v1alpha1/ScaledObject --api-versions keda.sh/v1alpha1/TriggerAuthentication >/tmp/kubecert-prod-render.yaml
```

Rendered manifest checks:

```bash
rg -n "kind: Secret|runtime-ssh|terminal-ssh|ssh-keygen|terminal\\." /tmp/kubecert-dev-render.yaml /tmp/kubecert-prod-render.yaml
rg -n "ws://terminal|wss://terminal|VITE_TERMINAL_WS_BASE_URL|CERT_TERMINAL" /tmp/kubecert-dev-render.yaml /tmp/kubecert-prod-render.yaml
```

Cluster smoke checks:

```bash
helm install kubecert charts/kubecert -n kubecert --create-namespace -f dev-values.yaml
kubectl -n kubecert get secret kubecert-runtime-ssh kubecert-terminal-ssh
kubectl -n kubecert get secret kubecert-runtime-ssh -o jsonpath='{.data.id_ed25519}' | wc -c
kubectl -n kubecert get secret kubecert-terminal-ssh -o jsonpath='{.data.runtime_admin_key}' | wc -c
helm upgrade kubecert charts/kubecert -n kubecert -f dev-values.yaml
kubectl -n kubecert get secret kubecert-runtime-ssh -o jsonpath='{.metadata.resourceVersion}'
kubectl -n kubecert get ingress
```

Application smoke checks:

```text
1. Admin login succeeds.
2. Runtime Node join command includes generated public keys.
3. Runtime Node health check succeeds.
4. CKA/CKS token issue succeeds.
5. Exam page opens.
6. Terminal websocket connects through terminal host.
7. Session cleanup succeeds.
```

## 문서 갱신 항목

- Required values list must focus on image, ingress, external DB/Redis, admin bootstrap, resource sizing.
- Explicitly state that default values do not expose internal paths or artifact provider credentials.
- Explain SSH key Secret generation and reuse.
- Explain terminal host split and Cloudflare DNS-only/proxied tradeoff.

## Status

Planned. This task supersedes the parts of TASK-004 that became stale after the full chart migration.

