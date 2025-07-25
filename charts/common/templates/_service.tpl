{{- /* Creates service definition. By default StatefulSet workload also creates service, which can be disabled with .Values.service.headless: false */ -}}
{{- define "common.service" }}
  {{- if .Values.service -}}
    {{- $fullName := include "common.helpers.names.fullname" . -}}
    {{- $commonLabels := (include "common.helpers.labels" .) | fromYaml -}}
    {{- $selectorLabels := (include "common.helpers.labels.selectorLabels" .) | fromYaml -}}
    {{- $isSts := eq "StatefulSet" (include "common.helpers.names.workloadType" .) -}}
    {{- $services := .Values.service -}}
    {{- range $name, $service := $services -}}
      {{- $createService := true -}}
      {{- if hasKey $service "enabled" -}}
        {{- $createService = $service.enabled -}}
      {{- else if and (not (hasKey $service "ports")) (not (hasKey $service "portsFrom"))  -}}
        {{- $createService = false -}}
      {{- end -}}

      {{- /* Creates headless service copy if is only "main" named service  */ -}}
      {{- $createHeadlessCopy := hasKey $service "createHeadless" | ternary $service.createHeadless (and $isSts (eq "main" $name)) -}}
      {{- if and $createHeadlessCopy (eq "None" ($service.clusterIP)) -}}
        {{- $createHeadlessCopy = false -}}
      {{- end -}}
      {{- $serviceSpec := omit $service "createHeadless" "annotations" "name" "labels" "ports" "enabled" "isStsService" "portsFrom" -}}
      {{- $servicePorts := $service.ports -}}
      {{- if $service.portsFrom -}}
        {{- $servicePorts = (index $services $service.portsFrom).ports -}}
      {{- end -}}
      {{- if not (hasKey $serviceSpec "type") -}}
        {{- $serviceSpec = merge (dict "type" "ClusterIP") $serviceSpec -}}
      {{- end -}}
      {{- if and (ne $serviceSpec.type "LoadBalancer") (ne $serviceSpec.type "NodePort") -}}
        {{- $serviceSpec = omit $serviceSpec "externalTrafficPolicy" -}}
      {{- end -}}
      {{- $serviceLabels := merge $commonLabels ($service.labels | default dict) -}}

      {{- $serviceSpec = merge (dict "selector" $selectorLabels) $serviceSpec -}}
      {{- $headlessSpec := omit $serviceSpec "type" "clusterIP" -}}
      {{- $serviceName := (include "common.helpers.names.serviceName" ( list $ ($service.name | default $name))) -}}
      {{- if $createService }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName }}
  {{- with $service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- toYaml $serviceLabels | nindent 4 }}
spec:
  {{- include "common.tpl.ports.service" $servicePorts | nindent 2 }}
  {{- toYaml $serviceSpec | nindent 2 }}
        {{- if $createHeadlessCopy }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName }}-headless
  {{- with $service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- toYaml $serviceLabels | nindent 4 }}
spec:
  type: ClusterIP
  clusterIP: None
  {{- include "common.tpl.ports.service" $service.ports | nindent 2 }}
  {{- toYaml $headlessSpec | nindent 2 }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
