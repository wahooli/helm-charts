{{/* StatefulSet template */}}
{{- define "common.statefulset" }}
---
{{- $serviceName := (include "common.helpers.names.stsServiceName" .) }}
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
  {{- include "common.tpl.strategy" (list $ "StatefulSet") | nindent 2 }}
  {{- if $serviceName }}
  serviceName: {{ $serviceName }}
  {{- end }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 10 }}
  minReadySeconds: {{ .Values.minReadySeconds | default 0 }}
  {{- with .Values.persistentVolumeClaimRetentionPolicy }}
  persistentVolumeClaimRetentionPolicy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.ordinals }}
  ordinals:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.podManagementPolicy }}
  podManagementPolicy: {{ toYaml . }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.helpers.labels.selectorLabels" . | nindent 6 }}
  template:
    {{- include "common.tpl.pod" . | nindent 4 }}
  {{- include "common.tpl.volumeClaimTemplates" . | nindent 2 }}
{{- end }}
