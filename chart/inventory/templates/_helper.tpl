{{/* Inventory Init Container Template */}}
{{- define "inventory.labels" }}
{{- range $key, $value := .Values.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
app.kubernetes.io/name: {{ .Release.Name }}-inventory
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/* Inventory Resources */}}
{{- define "inventory.resources" }}
limits:
  memory: {{ .Values.resources.limits.memory }}
requests:
  cpu: {{ .Values.resources.limits.cpu }}
  memory: {{ .Values.resources.requests.memory }}
{{- end }}

{{/* MySQL Init Container Template */}}
{{- define "inventory.mysql.initcontainer" }}
- name: test-mysql
  image: {{ .Values.mysql.image }}:{{ .Values.mysql.imageTag }}
  imagePullPolicy: {{ .Values.mysql.imagePullPolicy }}
  command:
  - "/bin/bash"
  - "-c"
  {{- if or .Values.mysql.password .Values.mysql.existingSecret }}
  - "until mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e status; do echo waiting for mysql; sleep 1; done"
  {{- else }}
  - "until mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u${MYSQL_USER} -e status; do echo waiting for mysql; sleep 1; done"
  {{- end }}
  env:
  {{- include "inventory.mysql.environmentvariables" . | indent 2 }}
{{- end }}

{{/* Inventory MySQL Environment Variables */}}
{{- define "inventory.mysql.environmentvariables" }}
{{- if .Values.travis }}
- name: MYSQL_HOST
  value: {{ .Values.mysql.host | quote }}
  #value: localhost
{{- else}}
- name: MYSQL_HOST
  value: {{ .Release.Name }}-{{ .Values.service.mysql }}
  #value: localhost
{{- end }}
- name: MYSQL_PORT
  value: {{ .Values.mysql.port | quote }}
- name: MYSQL_DATABASE
  value: {{ .Values.mysql.database | quote }}
- name: MYSQL_USER
  value: {{ .Values.mysql.user | quote }}
{{- if or .Values.mysql.password .Values.mysql.existingSecret }}
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "inventory.mysql.secretName" . }}
      key: mysql-password
{{- end }}
{{- end }}

{{/* Inventory MySQL Secret Name */}}
{{- define "inventory.mysql.secretName" }}
  {{- if .Values.mysql.existingSecret }}
    {{- .Values.mysql.existingSecret }}
  {{- else -}}
    {{ .Release.Name }}-{{ .Values.service.name }}-mysql-secret
  {{- end }}
{{- end }}
