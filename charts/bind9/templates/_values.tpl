{{- define "bind9.configMapValues" -}}
  {{- $configMaps := dict -}}
  {{- /* Entrypoint override */ -}}
  {{- $entrypointConfigMap := dict -}}
  {{- $entrypointConfigMap = dict "entrypoint-override.sh" (include "bind9.entrypointOverride" . ) | merge $entrypointConfigMap -}}
  {{- $data := dict "data" $entrypointConfigMap -}}
  {{- $_ := dict "entrypoint-override" $data | merge $configMaps -}}

  {{- dict "configMaps" $configMaps | toYaml -}}
{{- end }}


{{- define "bind9.workloadValues" -}}
{{ include "bind9.configMapValues" . }}

command:
- /entrypoint.d/entrypoint-override.sh
persistence:
  entrypoint-override:
    enabled: true
    mount:
    - path: /entrypoint.d/
    spec:
      useFromChart: true
      configMap:
        name: entrypoint-override
        defaultMode: 0555
{{- end }}