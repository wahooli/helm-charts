{{- define "common.secret" }}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $labels := include "common.helpers.labels" . -}}
  {{- range $name, $secret := .Values.secrets -}}
  {{- $enabled := true -}}
  {{- if hasKey $secret "enabled" -}}
    {{- $enabled = $secret.enabled -}}
    {{- $secret = omit $secret "enabled" -}}
  {{- end -}}
  {{- $name = $secret.name | default $name -}}
  {{- if $enabled }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $fullName }}-{{ $name }}
  labels:
    {{- $labels | nindent 4 }}
  {{- with $secret.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
type: {{ $secret.type | default "Opaque" }}
data:
    {{- range $secretKey, $secretValue := $secret.data }}
      {{- $secretKey | nindent 2 }}: {{ $secretValue | toString | b64enc }}
    {{- end }}
  {{- end }}
  {{- end -}}
{{- end }}