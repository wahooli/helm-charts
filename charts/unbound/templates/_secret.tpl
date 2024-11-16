{{- define "unbound.secretValues" -}}
  {{- $secrets := dict -}}
  {{- /* Redis secret */ -}}
  {{- if and (.Values.redisSidecar).enabled (not (.Values.redisSidecar.config).existingSecret) (not (.Values.redisSidecar.config).existingConfigMap) (.Values.redisSidecar.config).secretData -}}
    {{- $config := (.Values.redisSidecar.config).secretData | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if not (.Values.redisSidecar.config).secretData -}}
      {{- $config = dict "default.conf" (regexReplaceAll "#.*\n" (include "unbound.redisDefaultConfig" . ) "") | merge $config -}}
    {{- end -}}
    {{- /* add redis.conf key to config to include all other config files */ -}}
    {{- if not (hasKey (.Values.redisSidecar.config).secretData "redis.conf" ) -}}
      {{- $config = dict "redis.conf" (include "unbound.redisIncludeConfig" $config ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.redisConfigName" .) $data | merge $secrets -}}
  {{- end }}

  {{- /* unbound.conf.d secret */ -}}
  {{- if and (not (.Values.unbound.config).existingSecret) (not (.Values.unbound.config).existingConfigMap) (.Values.unbound.config).secretData -}}
    {{- $config := (.Values.unbound.config).secretData | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if not (.Values.unbound.config).secretData -}}
      {{- $config = dict "default.conf" (include "unbound.defaultConfig" . ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.unboundConfigName" .) $data | merge $secrets -}}
  {{- end }}

  {{- /* unbound.zones.d secret */ -}}
  {{- if and (not (.Values.unbound.zones).existingSecret) (not (.Values.unbound.zones).existingConfigMap) (.Values.unbound.zones).secretData -}}
    {{- $config := (.Values.unbound.zones).secretData | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if or (not (.Values.unbound.zones).secretData) ((.Values.unbound.zones).includeDefault | default false) -}}
      {{- $config = dict "auth-zone.conf" (include "unbound.authZone" . ) | merge $config -}}
      {{- $config = dict "local-zone.conf" (include "unbound.localZone" . ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.unboundZonesName" .) $data | merge $secrets -}}
  {{- end }}
  {{- dict "secrets" $secrets | toYaml -}}
{{- end }}
