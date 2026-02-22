{{- if .Values.resticBackup.enabled -}}
{{- $fullname := include "common.helpers.names.fullname" . -}}
{{- $backupValues := include "seaweedfs.backupValues" . | fromYaml -}}
{{- $_ := set $backupValues.Values.env "OPERATION" "backup" -}}
{{- $restartPolicy := $backupValues.Values.restartPolicy -}}
{{- $_ := unset $backupValues.Values "restartPolicy" -}}
{{- $podYaml := include "common.tpl.pod" $backupValues | fromYaml -}}
{{- $_ := set $podYaml.spec "restartPolicy" $restartPolicy | default "Never" -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $fullname }}-backup
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
spec:
  schedule: {{ .Values.resticBackup.schedule | quote }}
  successfulJobsHistoryLimit: {{ .Values.resticBackup.successfulJobsHistoryLimit | default 1 }}
  failedJobsHistoryLimit: {{ .Values.resticBackup.failedJobsHistoryLimit | default 1 }}
  concurrencyPolicy: Forbid
  jobTemplate:
    metadata:
      labels:
        {{- include "common.helpers.labels.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: backup
    spec:
      backoffLimit: 1
      template:
        metadata:
          labels:
            {{- include "common.helpers.labels.selectorLabels" . | nindent 12 }}
            app.kubernetes.io/component: backup
        spec:
          restartPolicy: {{ $restartPolicy | default "Never" }}
{{- $podYaml.spec | toYaml | nindent 10 }}
{{- end }}
