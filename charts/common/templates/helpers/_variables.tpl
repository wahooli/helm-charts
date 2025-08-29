{{/*
Dig into a nested map using a dot-separated path.
This helper is internal and used by getValue.
It correctly handles cases where the value might be "falsy" (false, 0, "").

Usage: {{ include "common.helpers.variables.dig" (list $dict "path.to.value") }}
*/}}
{{- define "common.helpers.variables.dig" -}}
  {{- $dict := first . -}}
  {{- $path := last . -}}

  {{- $result := $dict -}}
  {{- $found := true -}}
  {{- range $key := splitList "." $path -}}
    {{- if and $result (kindIs "map" $result) (hasKey $result $key) -}}
      {{- $result = index $result $key -}}
    {{- else -}}
      {{- $found = false -}}
      {{- break -}}
    {{- end -}}
  {{- end -}}

  {{- if $found -}}
    {{- dict "found" true "value" $result | toYaml -}}
  {{- else -}}
    {{- dict "found" false | toYaml -}}
  {{- end -}}
{{- end -}}


{{/*
Get global or local value.
Prioritizes the global value over the local one.
Emits failure by default if value not found, but can be overridden with last parameter

usage: {{ include "common.helpers.variables.get" ( list $ [wanted value path] [optional chart name] [quiet (default false)] ) }}
examples:
  - {{ include "common.helpers.variables.get" (list $ "someValue") }}
  - {{ include "common.helpers.variables.get" (list $ "some.nested.value") }}
  - {{ include "common.helpers.variables.get" (list $ "global.chart.value" "other-chart") }}
*/}}
{{- define "common.helpers.variables.get" -}}
  {{- $root := index . 0 -}}
  {{- $wantedValuePath := index . 1 -}}
  {{- $chartName := $root.Chart.Name -}}
  {{- $quiet := false -}}
  {{- if ge (len .) 3 -}}
    {{- $chartName = index . 2 -}}
  {{- end -}}
  {{- if ge (len .) 4 -}}
    {{- $quiet = index . 3 -}}
  {{- end -}}

  {{/* First, try to find the value in the global scope. */}}
  {{- $globalContext := dict -}}
  {{- if and $root.Values.global (hasKey $root.Values.global $chartName) -}}
    {{- $globalContext = index $root.Values.global $chartName -}}
  {{- end -}}
  {{- $globalResult := include "common.helpers.variables.dig" (list $globalContext $wantedValuePath) | fromYaml -}}

  {{- if $globalResult.found -}}
    {{- tpl $globalResult.value $root -}}
  {{- else -}}
    {{- /* Otherwise, try to find the value in the local scope. */ -}}
    {{- $localResult := include "common.helpers.variables.dig" (list $root.Values $wantedValuePath) | fromYaml -}}
    {{- if $localResult.found -}}
      {{- tpl $localResult.value $root -}}
    {{- else if not $quiet -}}
      {{- $failMsg := printf "Required value not found at .Values.%s or .Values.global.%s.%s" $wantedValuePath $chartName $wantedValuePath -}}
      {{- if ne $root.Chart.Name $chartName -}}
        {{- $failMsg = printf "Required value not found at .Values.global.%s.%s" $chartName $wantedValuePath -}}
      {{- end -}}
      {{- fail $failMsg -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Get global or local value. Call tpl on the returned value
Prioritizes the global value over the local one.
Emits failure by default if value not found, but can be overridden with last parameter

usage: {{ include "common.helpers.variables.getTpl" ( list $ [wanted value path] [optional chart name] [quiet (default false)] ) }}
examples:
  - {{ include "common.helpers.variables.getTpl" (list $ "someValue") }}
  - {{ include "common.helpers.variables.getTpl" (list $ "some.nested.value") }}
  - {{ include "common.helpers.variables.getTpl" (list $ "global.chart.value" "other-chart") }}
*/}}
{{- define "common.helpers.variables.getTpl" -}}
  {{- $root := index . 0 -}}
  {{- $wantedValuePath := index . 1 -}}
  {{- $chartName := $root.Chart.Name -}}
  {{- $quiet := false -}}
  {{- if ge (len .) 3 -}}
    {{- $chartName = index . 2 -}}
  {{- end -}}
  {{- if ge (len .) 4 -}}
    {{- $quiet = index . 3 -}}
  {{- end -}}
  {{- tpl (include "common.helpers.variables.getTpl" (list $root $wantedValuePath $chartName $quiet)) $root -}}
{{- end }}
