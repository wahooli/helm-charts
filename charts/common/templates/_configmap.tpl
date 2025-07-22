{{- define "common.configMap" }}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $labels := include "common.helpers.labels" . -}}
  {{- range $name, $configMap := .Values.configMaps -}}
  {{- $enabled := true -}}
  {{- if hasKey $configMap "enabled" -}}
    {{- $enabled = $configMap.enabled -}}
    {{- $configMap = omit $configMap "enabled" -}}
  {{- end -}}
  {{- $name = $configMap.name | default $name -}}
  {{- if $enabled }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName }}-{{ $name }}
  labels:
    {{- $labels | nindent 4 }}
  {{- with $configMap.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
data:
    {{- range $configKey, $configValue := $configMap.data -}}
      {{- $configKey | nindent 2 }}: |
      {{- (tpl $configValue $) | nindent 4 }}
    {{ end -}}
  {{- end -}}
  {{- end -}}
{{- end }}