{{- if .Values.master.enabled -}}
{{- $masterValues := include "seaweedfs.masterValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $masterValues "Files" $.Files -}}

{{ include "common.secret" $masterValues }}
{{ end -}}

{{- if .Values.filer.enabled -}}
{{- $filerValues := include "seaweedfs.filerValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $filerValues "Files" $.Files -}}

{{ include "common.secret" $filerValues }}
{{ end -}}

{{- if .Values.volume.enabled -}}
{{- $volumeValues := include "seaweedfs.volumeValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $volumeValues "Files" $.Files -}}

{{ include "common.secret" $volumeValues }}
{{ end -}}