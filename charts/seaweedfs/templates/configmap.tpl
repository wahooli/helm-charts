{{ include "common.configMap" . }}

{{- if .Values.master.enabled -}}
{{- $masterValues := include "seaweedfs.masterValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $masterValues "Files" $.Files -}}

{{ include "common.configMap" $masterValues }}
{{ end -}}

{{- if .Values.filer.enabled -}}
{{- $filerValues := include "seaweedfs.filerValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $filerValues "Files" $.Files -}}

{{ include "common.configMap" $filerValues }}
{{ end -}}

{{- if .Values.volume.enabled -}}
{{- $volumeValues := include "seaweedfs.volumeValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $volumeValues "Files" $.Files -}}

{{ include "common.configMap" $volumeValues }}
{{ end -}}

{{- if .Values.resticBackup.enabled -}}
{{- $backupValues := include "seaweedfs.backupValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $backupValues "Files" $.Files -}}

{{ include "common.configMap" $backupValues }}
{{ end -}}

{{- if and .Values.postUp.enabled .Values.postUp.collections -}}
{{- $postUpValues := include "seaweedfs.postUpValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $postUpValues "Files" $.Files -}}

{{ include "common.configMap" $postUpValues }}
{{ end -}}
