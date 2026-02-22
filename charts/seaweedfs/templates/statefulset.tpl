{{- if .Values.master.enabled -}}
{{- $masterValues := include "seaweedfs.masterValues" . | fromYaml -}}
{{ include "common.statefulset" $masterValues }}
{{ end -}}

{{- if .Values.filer.enabled -}}
{{- $filerValues := include "seaweedfs.filerValues" . | fromYaml -}}
{{ include "common.statefulset" $filerValues }}
{{ end -}}

{{- if .Values.volume.enabled -}}
{{- $volumeValues := include "seaweedfs.volumeValues" . | fromYaml -}}
{{ include "common.statefulset" $volumeValues }}
{{ end -}}