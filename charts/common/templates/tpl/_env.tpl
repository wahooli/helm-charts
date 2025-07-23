{{- define "common.tpl.env" -}}
  {{- $root := index . 0 -}}
  {{- $context := index . 1 -}}
  {{- $envVals := ($context.Values).env | default $context.env -}}
  {{- $envs := list -}}
  {{- $variableEnvs := list -}}
  {{- range $name, $env := $envVals | default dict -}}
    {{- if kindIs "map" $env -}}
      {{- $envs = prepend $envs (merge (dict "name" $name) $env) -}}
    {{- else -}}
      {{- $replaced := regexReplaceAll `\$\([A-Za-z_][A-Za-z0-9_]*\)` ($env | toString) "" -}}
      {{- $envListItem := dict "name" $name "value" (tpl ($env | toString) $root) -}}
      {{- /* contained $(VAR) pattern variable, will be placed in bottom of the envs list */ -}}
      {{- if ne $replaced ($env | toString) }}
        {{- $variableEnvs = append $variableEnvs $envListItem -}}
      {{- else }}
        {{- $envs = append $envs $envListItem -}}
      {{- end }}
    {{- end -}}
  {{- end -}}
  {{- range $envVar := $variableEnvs -}}
    {{- $envs = append $envs $envVar -}}
  {{- end -}}
  {{- if $envs -}}
env:
{{- toYaml $envs | nindent 0 -}}
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
{{- toYaml $envsFrom | nindent 0 -}}
  {{- end -}}
{{- end }}