{{- if .Values.controller.enabled -}}
{{- $controllerValues := include "seaweedfs-csi-driver.controllerValues" . | fromYaml -}}
{{- include "common.serviceAccount" $controllerValues }}
{{- end -}}
{{- if and .Values.controller.enabled .Values.node.enabled }}
---
{{- end -}}
{{- if .Values.node.enabled -}}
{{- $nodeValues := include "seaweedfs-csi-driver.nodeValues" . | fromYaml -}}
{{- include "common.serviceAccount" $nodeValues }}
{{- end -}}
{{- if .Values.nodeGc.enabled }}
---
{{- $nodeGcValues := include "seaweedfs-csi-driver.nodeGCValues" . | fromYaml -}}
{{ include "common.serviceAccount" $nodeGcValues }}
{{- end -}}
