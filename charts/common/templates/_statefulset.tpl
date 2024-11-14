{{/* StatefulSet template */}}
{{- define "common.statefulset" }}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "common.helpers.names.fullname" . }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- include "common.helpers.annotations.workloadAnnotations" . | nindent 2 }}
spec:
  {{- if not (.Values.autoscaling).enabled }}
  replicas: {{ .Values.replicaCount | default 1 }}
  {{- end }}
  {{- include "common.tpl.strategy" . | nindent 2 }}
  serviceName: {{ include "common.helpers.names.stsServiceName" . }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 10 }}
  minReadySeconds: {{ .Values.progressDeadlineSeconds | default 0 }}
  selector:
    matchLabels:
      {{- include "common.helpers.labels.selectorLabels" . | nindent 6 }}
  template:
    {{- include "common.tpl.pod" . | nindent 4 }}
  {{- include "common.tpl.volumeClaimTemplates" . | nindent 2 }}
{{- end }}
