{{- /* Render base configMaps */ -}}
{{ include "common.configMap" . }}

{{- /* Render controller component configMaps */ -}}
{{- if .Values.controller.enabled -}}
{{- $controllerValues := include "seaweedfs-csi-driver.controllerValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $controllerValues "Files" $.Files -}}

{{ include "common.configMap" $controllerValues }}
{{- end -}}

{{- /* Render node component configMaps */ -}}
{{- if .Values.node.enabled -}}
{{- $nodeValues := include "seaweedfs-csi-driver.nodeValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $nodeValues "Files" $.Files -}}

{{ include "common.configMap" $nodeValues }}
{{- end -}}

{{- /* Render mount component configMaps */ -}}
{{- if .Values.mount.enabled -}}
{{- $mountValues := include "seaweedfs-csi-driver.mountValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $mountValues "Files" $.Files -}}

{{ include "common.configMap" $mountValues }}
{{- end -}}

{{- /* Render mount component configMaps */ -}}
{{- if .Values.nodeGc.enabled -}}
{{- $nodeGcValues := include "seaweedfs-csi-driver.nodeGCValues" . | fromYaml -}}

{{- /* Setting Files key since it cannot be properly serialized/deserialized */ -}}
{{- $_ := set $nodeGcValues "Files" $.Files -}}

{{ include "common.configMap" $nodeGcValues }}
{{- end -}}