{{- if .Values.resticBackup.restoreHook.enabled -}}
{{- $fullname := include "common.helpers.names.fullname" . -}}
{{- $backupValues := include "seaweedfs.backupValues" . | fromYaml -}}
{{- $_ := set $backupValues.Values.env "OPERATION" "restore" -}}
{{- $restartPolicy := $backupValues.Values.restartPolicy -}}
{{- $_ := unset $backupValues.Values "restartPolicy" -}}
{{- $podYaml := include "common.tpl.pod" $backupValues | fromYaml -}}
{{- $_ := set $podYaml.spec "restartPolicy" $restartPolicy | default "Never" -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $fullname }}-restore
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  annotations:
    helm.sh/hook: post-install,post-upgrade
    helm.sh/hook-weight: "100"
    helm.sh/hook-delete-policy: {{ .Values.resticBackup.restoreHook.deletePolicy | default "before-hook-creation,hook-succeeded" }}
spec:
  backoffLimit: {{ .Values.resticBackup.restoreHook.backoffLimit | default 1 }}
  template:
    metadata:
      labels:
        {{- include "common.helpers.labels.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: restore
    spec:
{{- $podYaml.spec | toYaml | nindent 6 }}
{{- end }}
