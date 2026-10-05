{{- define "common.configMap" }}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $commonLabels := fromYaml (include "common.helpers.labels" .) -}}
  {{- range $name, $configMap := .Values.configMaps -}}
    {{- $enabled := true -}}
    {{- $labels := $configMap.labels | default dict -}}
    {{- $_ := $commonLabels | merge $labels -}}
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
  {{- with $labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $configMap.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
data:
    {{- range $configKey, $configValue := $configMap.data }}
      {{- $rendered := tpl $configValue $ }}
      {{- $parsed := fromYaml (printf "value: |%s\n" ($rendered | nindent 2)) }}
      {{- $value := $rendered }}
      {{- if hasKey $parsed "value" }}{{ $value = $parsed.value | default "" }}{{ end }}
  {{ $configKey }}: {{ $value | toJson }}
    {{- end }}
  {{- end -}}
  {{- end -}}
{{- end }}
