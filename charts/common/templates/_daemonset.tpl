{{/*
DaemonSet template
*/}}
{{- define "common.daemonset" }}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ include "common.helpers.names.fullname" . }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- include "common.helpers.annotations.workloadAnnotations" . | nindent 2 }}
spec:
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 10 }}
  minReadySeconds: {{ .Values.minReadySeconds | default 0 }}
  {{- include "common.tpl.strategy" (list $ "DaemonSet") | nindent 2 }}
  selector:
    matchLabels:
      {{- include "common.helpers.labels.selectorLabels" . | nindent 6 }}
  template:
    {{- include "common.tpl.pod" . | nindent 4 }}
{{- end }}
