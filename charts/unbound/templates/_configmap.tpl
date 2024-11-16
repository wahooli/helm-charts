{{- define "unbound.configMapValues" -}}
  {{- $configMaps := dict -}}
  {{- /* Redis configmap */ -}}
  {{- if and (.Values.redisSidecar).enabled (not (.Values.redisSidecar.config).existingSecret) (not (.Values.redisSidecar.config).existingConfigMap) (not (.Values.redisSidecar.config).secretData) -}}
    {{- $config := (.Values.redisSidecar.config).data | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if not (.Values.redisSidecar.config).data -}}
      {{- $config = dict "default.conf" (regexReplaceAll "#.*\n" (include "unbound.redisDefaultConfig" . ) "") | merge $config -}}
    {{- end -}}
    {{- /* add redis.conf key to config to include all other config files */ -}}
    {{- if not (hasKey (.Values.redisSidecar.config).data "redis.conf" ) -}}
      {{- $config = dict "redis.conf" (include "unbound.redisIncludeConfig" $config ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.redisConfigName" .) $data | merge $configMaps -}}
  {{- end }}

  {{- /* unbound.conf configmap */ -}}
  {{- if and (not (.Values.unbound.unboundConf).existingSecret) (not (.Values.unbound.unboundConf).existingConfigMap) -}}
    {{- $config := dict "unbound.conf" (include "unbound.unboundConf" .) -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.unboundConfConfigName" .) $data | merge $configMaps -}}
  {{- end }}

  {{- /* unbound.conf.d configmap */ -}}
  {{- if and (not (.Values.unbound.config).existingSecret) (not (.Values.unbound.config).existingConfigMap) (not (.Values.unbound.config).secretData) -}}
    {{- $config := (.Values.unbound.config).data | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if not (.Values.unbound.config).data -}}
      {{- $config = dict "default.conf" (include "unbound.defaultConfig" . ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.unboundConfigName" .) $data | merge $configMaps -}}
  {{- end }}

  {{- /* unbound.zones.d configmap */ -}}
  {{- if and (not (.Values.unbound.zones).existingSecret) (not (.Values.unbound.zones).existingConfigMap) (not (.Values.unbound.zones).secretData) -}}
    {{- $config := (.Values.unbound.zones).data | default dict -}}
    {{- /* append default configuration if none is defined */ -}}
    {{- if or (not (.Values.unbound.zones).data) ((.Values.unbound.zones).includeDefault | default false) -}}
      {{- $config = dict "auth-zone.conf" (include "unbound.authZone" . ) | merge $config -}}
      {{- $config = dict "local-zone.conf" (include "unbound.localZone" . ) | merge $config -}}
    {{- end -}}
    {{- $data := dict "data" $config -}}
    {{- $_ := dict (include "unbound.unboundZonesName" .) $data | merge $configMaps -}}
  {{- end }}
  {{- dict "configMaps" $configMaps | toYaml -}}
{{- end }}
