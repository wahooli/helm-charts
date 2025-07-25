{{- define "common.serviceAccount" -}}
  {{- if (.Values.serviceAccount).create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.helpers.names.serviceAccount" . }}
  labels:
    {{- include "common.helpers.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ (.Values.serviceAccount).automount | default true }}
  {{- end }}
{{- end }}
