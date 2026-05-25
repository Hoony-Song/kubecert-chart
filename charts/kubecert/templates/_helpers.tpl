{{/*
Common template helpers for Kubecert.
*/}}
{{- define "kubecert.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubecert.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "kubecert.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: kubecert
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- range $key, $value := .Values.global.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{- define "kubecert.selectorLabels" -}}
app.kubernetes.io/part-of: kubecert
{{- end -}}

{{- define "kubecert.image" -}}
{{- $root := .root -}}
{{- $image := .image -}}
{{- $repository := default "" $image.repository -}}
{{- if and $root.Values.global.imageRegistry $repository -}}
{{- $repository = printf "%s/%s" ($root.Values.global.imageRegistry | trimSuffix "/") ($repository | trimPrefix "/") -}}
{{- end -}}
{{- if and $repository $image.digest -}}
{{- printf "%s@%s" $repository $image.digest -}}
{{- else if and $repository $image.tag -}}
{{- printf "%s:%s" $repository $image.tag -}}
{{- else -}}
{{- $repository -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kubecert.configMapName" -}}
{{- printf "%s-config" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.apiName" -}}
{{- printf "%s-api" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.workerName" -}}
{{- printf "%s-worker" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.terminalGatewayName" -}}
{{- printf "%s-terminal-gateway" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.examWebName" -}}
{{- printf "%s-exam-web" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.adminWebName" -}}
{{- printf "%s-admin-web" (include "kubecert.fullname" .) -}}
{{- end -}}

{{- define "kubecert.appSecretName" -}}
{{- coalesce .Values.secrets.app.existingSecret .Values.secrets.app.name (printf "%s-app" (include "kubecert.fullname" .)) -}}
{{- end -}}

{{- define "kubecert.adminSecretName" -}}
{{- coalesce .Values.secrets.admin.existingSecret .Values.secrets.admin.name (printf "%s-admin" (include "kubecert.fullname" .)) -}}
{{- end -}}

{{- define "kubecert.runtimeSshSecretName" -}}
{{- coalesce .Values.secrets.runtimeSsh.existingSecret .Values.secrets.runtimeSsh.name (printf "%s-runtime-ssh" (include "kubecert.fullname" .)) -}}
{{- end -}}

{{- define "kubecert.terminalSshSecretName" -}}
{{- coalesce .Values.secrets.terminalSsh.existingSecret .Values.secrets.terminalSsh.name (printf "%s-terminal-ssh" (include "kubecert.fullname" .)) -}}
{{- end -}}

{{- define "kubecert.postgresqlSecretName" -}}
{{- coalesce .Values.postgresql.auth.existingSecret .Values.postgresql.auth.name (printf "%s-postgresql" .Release.Name) -}}
{{- end -}}

{{- define "kubecert.redisSecretName" -}}
{{- coalesce .Values.redis.auth.existingSecret .Values.redis.auth.name (printf "%s-redis" .Release.Name) -}}
{{- end -}}

{{- define "kubecert.postgresqlHost" -}}
{{- if eq .Values.postgresql.mode "external" -}}
{{- required "postgresql.external.host is required when postgresql.mode=external" .Values.postgresql.external.host -}}
{{- else -}}
{{- default (printf "%s-postgresql" .Release.Name) .Values.postgresql.bundled.host -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.postgresqlPort" -}}
{{- if eq .Values.postgresql.mode "external" -}}
{{- .Values.postgresql.external.port -}}
{{- else -}}
{{- .Values.postgresql.bundled.port -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.redisHost" -}}
{{- if eq .Values.redis.mode "external" -}}
{{- required "redis.external.host is required when redis.mode=external" .Values.redis.external.host -}}
{{- else -}}
{{- default (printf "%s-redis-master" .Release.Name) .Values.redis.bundled.host -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.redisPort" -}}
{{- if eq .Values.redis.mode "external" -}}
{{- .Values.redis.external.port -}}
{{- else -}}
{{- .Values.redis.bundled.port -}}
{{- end -}}
{{- end -}}

{{- define "kubecert.redisAddress" -}}
{{- printf "%s:%v" (include "kubecert.redisHost" .) (include "kubecert.redisPort" .) -}}
{{- end -}}

{{- define "kubecert.questionBankClaimName" -}}
{{- coalesce .Values.questionBank.persistence.existingClaim .Values.questionBank.claimName (printf "%s-question-bank" (include "kubecert.fullname" .)) -}}
{{- end -}}

{{- define "kubecert.databaseEnv" -}}
- name: POSTGRES_USER
  value: {{ .Values.postgresql.auth.username | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "kubecert.postgresqlSecretName" . }}
      key: {{ .Values.postgresql.auth.passwordKey }}
- name: POSTGRES_DATABASE
  value: {{ .Values.postgresql.auth.database | quote }}
- name: POSTGRES_HOST
  value: {{ include "kubecert.postgresqlHost" . | quote }}
- name: POSTGRES_PORT
  value: {{ include "kubecert.postgresqlPort" . | quote }}
{{- end -}}

{{- define "kubecert.redisEnv" -}}
- name: REDIS_HOST
  value: {{ include "kubecert.redisHost" . | quote }}
- name: REDIS_PORT
  value: {{ include "kubecert.redisPort" . | quote }}
- name: REDIS_DATABASE
  value: {{ .Values.redis.database | quote }}
{{- if .Values.redis.auth.enabled }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "kubecert.redisSecretName" . }}
      key: {{ coalesce .Values.redis.auth.passwordKey .Values.redis.auth.existingSecretPasswordKey "redis-password" }}
{{- end }}
{{- end -}}

{{- define "kubecert.jwtEnv" -}}
- name: CERT_JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "kubecert.appSecretName" . }}
      key: {{ .Values.secrets.app.jwtSecretKey }}
{{- end -}}

{{- define "kubecert.waitForDependenciesInitContainers" -}}
initContainers:
  - name: wait-for-db-redis
    image: {{ include "kubecert.image" (dict "root" . "image" .Values.images.api) | quote }}
    imagePullPolicy: {{ .Values.images.api.pullPolicy }}
    command:
      - /bin/sh
      - -ec
      - |
        python - <<'PY'
        import sys
        import time

        from app.db import make_engine
        from app.redis_queue import RedisQueues

        deadline = time.time() + 300
        last_error = None
        while time.time() < deadline:
            try:
                connection = make_engine().connect()
                connection.close()
                RedisQueues().client().ping()
                sys.exit(0)
            except Exception as exc:
                last_error = exc
                time.sleep(3)
        raise SystemExit(f"dependencies not ready: {last_error}")
        PY
    env:
      {{- include "kubecert.databaseEnv" . | nindent 6 }}
      {{- include "kubecert.redisEnv" . | nindent 6 }}
{{- end -}}
