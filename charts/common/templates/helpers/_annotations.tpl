{{/*
Contains .Values.podAnnotations with envSecret template checksum
*/}}
{{- define "common.helpers.annotations.podAnnotations" -}}
  {{- $workloadType := (include "common.helpers.names.workloadType" .) -}}
  {{- $podAnnotations := .Values.podAnnotations -}}
  {{- if .Values.secrets -}}
    {{- $podAnnotations = merge $podAnnotations (dict "checksum/secrets" (.Values.secrets | toYaml | sha256sum)) -}}
  {{- end -}}
  {{- if .Values.configMaps -}}
    {{- $podAnnotations = merge $podAnnotations (dict "checksum/configMaps" (.Values.configMaps | toYaml | sha256sum)) -}}
  {{- end -}}
  {{- if eq "StatefulSet" $workloadType -}}
    {{- $podAnnotations = merge $podAnnotations (dict "serviceName" (include "common.helpers.names.stsServiceName" .) ) -}}
    {{- $podAnnotations = merge $podAnnotations (dict "serviceFQDN" (include "common.helpers.names.stsServiceFQDN" .) ) -}}
  {{- end -}}
  {{- $podAnnotations = merge $podAnnotations (dict "kubectl.kubernetes.io/default-container" (include "common.helpers.names.container" .) ) -}}
  {{- with $podAnnotations -}}
annotations:
    {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "common.helpers.annotations.workloadAnnotations" -}}
  {{- $annotations := merge ((.Values.global).annotations | default dict) ((.Values.workload).annotations | default dict) -}}
  {{- if eq "Deployment" (include "common.helpers.names.workloadType" .) -}}
    {{- $annotations = merge $annotations ((.Values.deployment).annotations | default dict) -}}
  {{- else if eq "StatefulSet" (include "common.helpers.names.workloadType" .) -}}
    {{- $annotations = merge $annotations ((.Values.statefulset).annotations | default dict) -}}
  {{- else if eq "DaemonSet" (include "common.helpers.names.workloadType" .) -}}
    {{- $annotations = merge $annotations ((.Values.daemonset).annotations | default dict) -}}
  {{- end -}}
  {{- with $annotations -}}
annotations:
    {{- range $k, $v := . }}
      {{- $name := $k -}}
      {{- $value := tpl $v $ -}}
{{ $name | nindent 2 }}: {{ quote $value }}
    {{- end -}}
  {{- end -}}
{{- end }}
