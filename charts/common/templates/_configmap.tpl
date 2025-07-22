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
    {{- range $configKey, $configValue := $configMap.data -}}
      {{- $configKey | nindent 2 }}: |
      {{- (tpl $configValue $) | nindent 4 }}
    {{ end -}}
  {{- end -}}
  {{- end -}}
{{- end }}