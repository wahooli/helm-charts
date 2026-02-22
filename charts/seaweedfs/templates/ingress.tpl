{{- if .Values.master.enabled -}}
{{- $masterValues := include "seaweedfs.masterValues" . | fromYaml -}}
{{ include "common.ingress" $masterValues }}
{{ end -}}

{{- if .Values.filer.enabled -}}
{{- $filerValues := include "seaweedfs.filerValues" . | fromYaml -}}
{{ include "common.ingress" $filerValues }}
{{ end -}}

{{- if .Values.volume.enabled -}}
{{- $volumeValues := include "seaweedfs.volumeValues" . | fromYaml -}}
{{ include "common.ingress" $volumeValues }}
{{ end -}}