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
automountServiceAccountToken: {{ hasKey .Values.serviceAccount "automount" | ternary .Values.serviceAccount.automount true }}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml .Values.imagePullSecrets | nindent 0 }}
{{- end }}
  {{- end }}
{{- end }}
