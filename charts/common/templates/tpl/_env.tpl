{{- define "common.tpl.env" -}}
  {{- $envVals := (.Values).env | default .env -}}
  {{- $envs := list -}}
  {{- range $name, $env := $envVals | default dict -}}
    {{- if kindIs "map" $env -}}
      {{- $envs = append $envs (merge (dict "name" $name) $env) -}}
    {{- else -}}
      {{- $envs = append $envs (dict "name" $name "value" ($env | toString)) -}}
    {{- end -}}
  {{- end -}}
  {{- if $envs -}}
env:
{{ toYaml $envs -}}
  {{- end -}}
{{- end }}

{{/*
usage: {{ include "common.tpl.env.envFrom" (list $ .) }}
*/}}
{{- define "common.tpl.env.envFrom" -}}
  {{- $root := index . 0 -}}
  {{- $context := index . 1 -}}
  {{- $envsFromVals := (($context).Values).envFrom | default $context.envFrom -}}
  {{- $envsFrom := list -}}
  {{- range $name, $envFrom := $envsFromVals | default dict -}}
    {{- $ref := false -}}
    {{- $useFromChart := or $envFrom.useFromChart (not (hasKey $envFrom "useFromChart")) -}}
    {{- if eq ($envFrom).type "secret" -}}
      {{- $secretName := include "common.helpers.names.secretName" ( list $root (($envFrom).name | default $name) $useFromChart ) -}}
      {{- $ref = dict "secretRef" (dict "name" $secretName) -}}

    {{- else if eq ($envFrom).type "configMap" -}}
      {{- $configMapName := include "common.helpers.names.configMapName" ( list $root (($envFrom).name | default $name) $useFromChart ) -}}
      {{- $ref = dict "configMapRef" (dict "name" $configMapName) -}}
      
    {{- end -}}
    {{- if $ref -}}
      {{- $envsFrom = append $envsFrom $ref -}}
    {{- end -}}
  {{- end -}}
  {{- if $envsFrom -}}
envFrom:
{{ toYaml $envsFrom -}}
  {{- end -}}
{{- end }}