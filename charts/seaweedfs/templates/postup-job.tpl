{{- if and .Values.postUp.enabled .Values.postUp.collections -}}
{{- $fullname := include "common.helpers.names.fullname" . -}}
{{- $postUpValues := include "seaweedfs.postUpValues" . | fromYaml -}}
{{- $restartPolicy := $postUpValues.Values.restartPolicy -}}
{{- $_ := unset $postUpValues.Values "restartPolicy" -}}
{{- $podYaml := include "common.tpl.pod" $postUpValues | fromYaml -}}
{{- $_ := set $podYaml.spec "restartPolicy" $restartPolicy | default "Never" -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $fullname }}-post-up
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  annotations:
    helm.sh/hook: post-install,post-upgrade
    helm.sh/hook-weight: {{ .Values.postUp.hookWeight | default "50" | quote }}
    helm.sh/hook-delete-policy: {{ .Values.postUp.deletePolicy | default "before-hook-creation,hook-succeeded" }}
spec:
  backoffLimit: {{ .Values.postUp.backoffLimit | default 3 }}
  template:
    metadata:
      labels:
        {{- include "common.helpers.labels.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: post-up
    spec:
{{- $podYaml.spec | toYaml | nindent 6 }}
{{- end }}
