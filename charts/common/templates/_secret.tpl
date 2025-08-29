{{- define "common.secret" }}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $commonLabels := fromYaml (include "common.helpers.labels" .) -}}
  {{- range $name, $secret := .Values.secrets -}}
    {{- $enabled := true -}}
    {{- $labels := $secret.labels | default dict -}}
    {{- $_ := $commonLabels | merge $labels -}}
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
  {{- with $labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $secret.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
type: {{ $secret.type | default "Opaque" }}
data:
    {{- range $secretKey, $secretValue := $secret.data }}
      {{- $secretKey | nindent 2 }}: {{ (tpl $secretValue $) | toString | b64enc }}
    {{- end }}
  {{- end }}
  {{- end -}}
{{- end }}