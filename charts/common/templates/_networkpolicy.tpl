{{- define "common.networkPolicy" }}
  {{- /* currently only supports CiliumNetworkPolicy, since I'm lazy */ -}}
  {{- if (.Capabilities.APIVersions.Has "cilium.io/v2") -}}
    {{- $fullName := include "common.helpers.names.fullname" . -}}
    {{- $commonLabels := (include "common.helpers.labels" .) | fromYaml -}}
    {{- $namespace := .Release.Namespace | default "default" -}}
    {{- $policies := .Values.ciliumNetworkPolicies | default .Values.networkPolicies -}}
    {{- range $name, $networkPolicy := $policies -}}
      {{- $labels := merge $commonLabels ($networkPolicy.labels | default dict) -}}
      {{- $networkPolicyName := printf "%s-%s" $fullName ($networkPolicy.name | default $name) -}}
      {{- if eq "main" ($networkPolicy.name | default $name) -}}
        {{- $networkPolicyName = $fullName -}}
      {{- end -}}
      {{- $networkPolicyNameNamespace := $networkPolicy.namespace | default $namespace -}}
      {{- $networkPolicySpec := omit $networkPolicy "name" "annotations" "labels" "namespace" "enabled" -}}
      {{- $enabled := true -}}
      {{- if hasKey $networkPolicy "enabled" -}}
        {{- $enabled = $networkPolicy.enabled -}}
      {{- end -}}
      {{- if $enabled }}
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: {{ $networkPolicyName }}
  namespace: {{ $networkPolicyNameNamespace }}
  {{- with $networkPolicy.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- toYaml $labels | nindent 4 }}
spec:
  {{- toYaml $networkPolicySpec | nindent 2 }}
  {{- end }}
  {{- end -}}
  {{- else -}}
    {{- /* TODO: Reference NetworkPolicy spec */ -}}
  {{- end -}}
{{- end }}