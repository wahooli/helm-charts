{{- if (.Values.mount).enabled | default false -}}
  {{- $mount := include "seaweedfs-csi-driver.mountValues" . | fromYaml -}}
  {{ include "common.daemonset" $mount }}
{{- end }}
---
{{- if .Values.node.enabled -}}
  {{- $node := include "seaweedfs-csi-driver.nodeValues" . | fromYaml -}}
  {{ include "common.daemonset" $node }}
{{- end }}
---
{{- if .Values.nodeGc.enabled -}}
  {{- $nodeGC := include "seaweedfs-csi-driver.nodeGCValues" . | fromYaml -}}
  {{ include "common.daemonset" $nodeGC }}
{{- end -}}
