{{- define "common.dnsEndpoint" }}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $labels := include "common.helpers.labels" . -}}
  {{- range $name, $dnsEndpoint := .Values.dnsEndpoints -}}
    {{- $endpointName := printf "%s-%s" $fullName $name -}}
    {{- if eq "main" $name -}}
      {{- $endpointName = $fullName -}}
    {{- end -}}
    {{- $dnsEndpoints := list -}}
    {{- $tmp := $dnsEndpoint -}}
    {{- if not (kindIs "slice" $dnsEndpoint) -}}
      {{- $tmp = list $dnsEndpoint -}}
    {{- end -}}
    {{- range $ep := $tmp -}}
      {{- $_ := set $ep "recordTTL" ($ep.recordTTL | default 60) -}}
      {{- $_ := required ".Values.dnsEndpoints items require \"dnsName\" key!" $ep.dnsName -}}
      {{- $_ := required ".Values.dnsEndpoints items require \"recordType\" key!" $ep.recordType -}}
      {{- $_ := required ".Values.dnsEndpoints items require \"targets\" key!" $ep.targets -}}
      {{- $dnsEndpoints = append $dnsEndpoints $ep -}}
    {{- end -}}
---
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: {{ $endpointName }}
  labels:
    {{- $labels | nindent 4 }}
spec:
  endpoints:
    {{- toYaml $dnsEndpoints | nindent 2 }}
  {{- end }}
{{- end }}