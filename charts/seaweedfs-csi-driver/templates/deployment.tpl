{{- if .Values.controller.enabled -}}
  {{- $controller := include "seaweedfs-csi-driver.controllerValues" . | fromYaml -}}
  {{ include "common.deployment" $controller }}
{{- end -}}
