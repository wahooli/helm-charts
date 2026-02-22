{{- if .Values.master.enabled -}}
{{- $masterValues := include "seaweedfs.masterValues" . | fromYaml -}}
{{ include "common.service" $masterValues }}
{{ end -}}

{{- if .Values.filer.enabled -}}
{{- $filerValues := include "seaweedfs.filerValues" . | fromYaml -}}
{{ include "common.service" $filerValues }}
{{ end -}}

{{- if .Values.volume.enabled -}}
{{- $volumeValues := include "seaweedfs.volumeValues" . | fromYaml -}}
{{ include "common.service" $volumeValues }}
{{ end -}}