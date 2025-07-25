{{/*
Deployment template
*/}}
{{- define "common.deployment" }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.helpers.names.fullname" . }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- include "common.helpers.annotations.workloadAnnotations" . | nindent 2 }}
spec:
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 10 }}
  progressDeadlineSeconds: {{ .Values.progressDeadlineSeconds | default 10 }}
  {{- if not (.Values.autoscaling).enabled }}
  replicas: {{ .Values.replicaCount | default 1 }}
  {{- end }}
  {{- include "common.tpl.strategy" (list $ "Deployment") | nindent 2 }}
  selector:
    matchLabels:
      {{- include "common.helpers.labels.selectorLabels" . | nindent 6 }}
  template:
    {{- include "common.tpl.pod" . | nindent 4 }}
{{- end }}
