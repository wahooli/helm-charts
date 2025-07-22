{{- define "common.certificate" }}
  {{- if (.Capabilities.APIVersions.Has "cert-manager.io/v1") -}}
    {{- $fullName := include "common.helpers.names.fullname" . -}}
    {{- $commonLabels := (include "common.helpers.labels" .) | fromYaml -}}
    {{- $namespace := .Release.Namespace | default "default" -}}
    {{- range $name, $certificate := .Values.certificates -}}
      {{- $labels := merge $commonLabels ($certificate.labels | default dict) -}}
      {{- $certificateName := printf "%s-%s" $fullName ($certificate.name | default $name) -}}
      {{- if eq "main" ($certificate.name | default $name) -}}
        {{- $certificateName = $fullName -}}
      {{- end -}}
      {{- $certificateNamespace := $certificate.namespace | default $namespace -}}
      {{- $certificateSpec := omit $certificate "name" "annotations" "labels" "namespace" "enabled" -}}
      {{- $issuerRef := required ".Values.certificates items require \"issuerRef\" key!" $certificateSpec.issuerRef -}}
      {{- if not $certificateSpec.secretName -}}
        {{- $certificateSpec = merge (dict "secretName" $certificateName) $certificateSpec -}}
      {{- end }}
      {{- $enabled := true -}}
      {{- if hasKey $certificate "enabled" -}}
        {{- $enabled = $certificate.enabled -}}
      {{- end -}}
      {{- if $enabled }}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ $certificateName }}
  namespace: {{ $certificateNamespace }}
  {{- with $certificate.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- toYaml $labels | nindent 4 }}
spec:
  {{- toYaml $certificateSpec | nindent 2 }}
  {{- end }}
  {{- end -}}
  {{- end -}}
{{- end }}