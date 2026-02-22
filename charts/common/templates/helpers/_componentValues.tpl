{{/*
common.helpers.componentValues - Merge component-specific values with base values

Creates a modified context where .Values contains the merged values of:
- Component-specific values (e.g., .Values.master)
- Base values (with specified keys omitted)

Arguments:
  - context: the Helm context (.)
  - component: the component name (e.g., "master", "filer", "volume")
  - omitKeys: list of keys to omit from base values (typically other component names)

Usage:
  {{- $masterValues := include "common.helpers.componentValues" (list . "master" (list "master" "filer" "volume")) | fromYaml -}}
  {{ include "common.statefulset" $masterValues }}
*/}}
{{- define "common.helpers.componentValues" -}}
  {{- $ctx := deepCopy (index . 0) -}}
  {{- $ctx = omit $ctx "Files" -}}
  {{- $component := index . 1 -}}
  {{- $omitKeys := list -}}
  {{- if ge (len .) 3 -}}
    {{- $omitKeys = index . 2 -}}
  {{- end -}}
  {{- /* Allow nested component keys like "filerSync.siteA" */ -}}
  {{- $componentPath := splitList "." (toString $component) -}}
  {{- $componentVals := $ctx.Values -}}
  {{- range $componentPath -}}
    {{- if kindIs "map" $componentVals -}}
      {{- $componentVals = (index $componentVals . | default dict) -}}
    {{- else -}}
      {{- $componentVals = dict -}}
    {{- end -}}
  {{- end -}}
  {{- $baseVals := $ctx.Values -}}
  {{- range $omitKeys -}}
    {{- $baseVals = omit $baseVals . -}}
  {{- end -}}
  {{- $_ := set $ctx "Values" (merge $componentVals $baseVals) -}}
  {{- toYaml $ctx -}}
{{- end }}
