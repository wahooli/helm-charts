
{{- define "unbound.redisPort" -}}
  {{- if and (.Values.redis).enabled (.Values.redisSidecar).enabled -}}
    {{- fail ".Values.redisSidecar and .Values.redis cannot be enabled both at same time!" -}}
  {{- end -}}
  {{- $redisPort := "6379" -}}
  {{- if and (.Values.redisSidecar).enabled (.Values.redisSidecar).port -}}
    {{- $redisPort = .Values.redisSidecar.port -}}
  {{- end -}}
  {{- (.Values.unbound.redis).port | default $redisPort }}
{{- end }}

{{- define "unbound.redisHost" -}}
  {{- if and (.Values.redis).enabled (.Values.redisSidecar).enabled -}}
    {{- fail ".Values.redisSidecar and .Values.redis cannot be enabled both at same time!" -}}
  {{- end -}}
  {{- $redisHost := "127.0.0.1" -}}
  {{- if (.Values.redis).enabled -}}
    {{- $redisHost = printf "%s-redis-master" .Release.Name -}}
  {{- end -}}
  {{- (.Values.unbound.redis).host | default $redisHost }}
{{- end }}

{{- define "unbound.redisConfigName" -}}
{{- if and (.Values.redisSidecar.config).existingSecret (.Values.redisSidecar.config).existingConfigMap -}}
  {{- fail ".Values.redisSidecar.config.existingSecret and existingConfigMap are mutually exclusive!" -}}
{{- else if or (.Values.redisSidecar.config).existingSecret (.Values.redisSidecar.config).existingConfigMap -}}
  {{- (.Values.redisSidecar.config).existingSecret | default (.Values.redisSidecar.config).existingConfigMap -}}
{{- else -}}
  redis-config
{{- end -}}
{{- end }}

{{- define "unbound.redisConfigType" -}}
{{- if or (.Values.redisSidecar.config).existingSecret (.Values.redisSidecar.config).secretData -}}
  secret
{{- else -}}
  configMap
{{- end -}}
{{- end }}

{{- define "unbound.unboundConfConfigName" -}}
{{- if and (.Values.unbound.unboundConf).existingSecret (.Values.unbound.unboundConf).existingConfigMap -}}
  {{- fail ".Values.unbound.unboundConf.existingSecret and existingConfigMap are mutually exclusive!" -}}
{{- else if or (.Values.unbound.unboundConf).existingSecret (.Values.unbound.unboundConf).existingConfigMap -}}
  {{- (.Values.unbound.unboundConf).existingSecret | default (.Values.unbound.unboundConf).existingConfigMap -}}
{{- else -}}
  unboundconf
{{- end -}}
{{- end }}

{{- define "unbound.unboundConfType" -}}
{{- if or (.Values.unbound.unboundConf).existingSecret -}}
  secret
{{- else -}}
  configMap
{{- end -}}
{{- end }}

{{- define "unbound.unboundConfigName" -}}
{{- if and (.Values.unbound.config).existingSecret (.Values.unbound.config).existingConfigMap -}}
  {{- fail ".Values.unbound.config.existingSecret and existingConfigMap are mutually exclusive!" -}}
{{- else if or (.Values.unbound.config).existingSecret (.Values.unbound.config).existingConfigMap -}}
  {{- (.Values.unbound.config).existingSecret | default (.Values.unbound.config).existingConfigMap -}}
{{- else -}}
  unbound-config
{{- end -}}
{{- end }}

{{- define "unbound.unboundConfigType" -}}
{{- if or (.Values.unbound.config).existingSecret (.Values.unbound.config).secretData -}}
  secret
{{- else -}}
  configMap
{{- end -}}
{{- end }}

{{- define "unbound.unboundZonesName" -}}
{{- if and (.Values.unbound.zones).existingSecret (.Values.unbound.zones).existingConfigMap -}}
  {{- fail ".Values.unbound.zones.existingSecret and existingConfigMap are mutually exclusive!" -}}
{{- else if or (.Values.unbound.zones).existingSecret (.Values.unbound.zones).existingConfigMap -}}
  {{- (.Values.unbound.zones).existingSecret | default (.Values.unbound.zones).existingConfigMap -}}
{{- else -}}
  unbound-zones
{{- end -}}
{{- end }}

{{- define "unbound.unboundZonesType" -}}
{{- if or (.Values.unbound.zones).existingSecret (.Values.unbound.zones).secretData -}}
  secret
{{- else -}}
  configMap
{{- end -}}
{{- end }}


{{- /*
Renders list of included configuration files for redis
Usage:
{{ include "unbound.redisDefaultConfig" (.Values.redisSidecar.config).secretData }}
{{ include "unbound.redisDefaultConfig" (.Values.redisSidecar.config).data  }}
*/ -}}
{{- define "unbound.redisIncludeConfig" -}}
  {{- $configData := . -}}
  {{- range $configFile, $_ := $configData | default dict -}}
include /usr/local/etc/redis/{{ $configFile }}   
{{ end -}}
{{- end }}

{{- define "unbound.serviceValues" -}}
service:
  main:
    type: ClusterIP
    ports:
    - name: dns-udp
      port: {{ .Values.unbound.port | default 53 }}
      protocol: UDP
    - name: dns-tcp
      port: {{ .Values.unbound.port | default 53 }}
      protocol: TCP
    - name: https
      port: 443
      protocol: TCP
{{- end -}}

{{- define "unbound.workloadValues" -}}
{{ include "unbound.configMapValues" . }}
{{ include "unbound.secretValues" . }}
env:
  HEALTHCHECK_PORT: "{{ .Values.unbound.port | default 53 }}"

{{ if (.Values.redisSidecar).enabled }}
sidecars:
  unbound-db:
    image: "{{ (.Values.redisSidecar.image).repository | default "docker.io/redis" }}:{{ (.Values.redisSidecar.image).tag | default "latest" }}"
    imagePullPolicy: {{ (.Values.redisSidecar.image).pullPolicy | default "IfNotPresent" }}
    securityContext:
      privileged: false
    args:
    - redis-server
    - {{ (.Values.redisSidecar.config).mountPath | default "/usr/local/etc/redis" }}/redis.conf
{{ if (.Values.redisSidecar).port }}
    ports:
    - containerPort: {{ (.Values.redisSidecar).port }}
      name: redis
      protocol: TCP
    readinessProbe:
      failureThreshold: 10
      tcpSocket:
        port: {{ (.Values.redisSidecar).port }}
      initialDelaySeconds: 5
      successThreshold: 1
      periodSeconds: 10
    startupProbe:
      failureThreshold: 10
      exec:
        command:
        - redis-cli
        - -s
        - ping
      initialDelaySeconds: 1
      successThreshold: 1
      periodSeconds: 10
    livenessProbe:
      failureThreshold: 10
      exec:
        command:
        - redis-cli
        - -s
        - ping
      successThreshold: 1
      periodSeconds: 10
{{ else }}
    readinessProbe:
      failureThreshold: 10
      exec:
        command:
        - test
        - -S
        - /usr/local/unbound/cachedb.d/redis.sock
      initialDelaySeconds: 1
      successThreshold: 1
      periodSeconds: 10
    startupProbe:
      failureThreshold: 10
      exec:
        command:
        - redis-cli
        - -s
        - /usr/local/unbound/cachedb.d/redis.sock
        - ping
      initialDelaySeconds: 1
      successThreshold: 1
      periodSeconds: 10
    livenessProbe:
      failureThreshold: 10
      exec:
        command:
        - redis-cli
        - -s
        - /usr/local/unbound/cachedb.d/redis.sock
        - ping
      successThreshold: 1
      periodSeconds: 10
{{ end }}
    volumeMounts:
{{ if not (.Values.redisSidecar).port }}
    - name: redis-socket
      mountPath: /usr/local/unbound/cachedb.d
{{ end }}
    - name: {{ (.Values.redisSidecar.data).volumeName | default "redis-data" }}
      mountPath: {{ (.Values.redisSidecar.data).mountPath | default "/data" }}
    - mountPath: {{ (.Values.redisSidecar.config).mountPath | default "/usr/local/etc/redis" }}
      name: {{ (.Values.redisSidecar.config).volumeName | default "redis-config" }}
{{ end }}

{{ include "unbound.serviceValues" . }}

persistence:
{{ if and (.Values.redisSidecar).enabled (not (.Values.redisSidecar).port) }}
  redis-socket:
    enabled: true
    mount:
    - path: /usr/local/unbound/cachedb.d
    spec:
      emptyDir:
        sizeLimit: 5Mi
        medium: Memory
{{ end }}
{{ if and (.Values.redisSidecar).enabled }}
  {{ (.Values.redisSidecar.config).volumeName | default "redis-config" }}:
    enabled: true
    mount: []
    spec:
      {{ include "unbound.redisConfigType" . }}:
        name: {{ include "unbound.redisConfigName" . }}
        defaultMode: 0444
  {{ (.Values.redisSidecar.data).volumeName | default "redis-data" }}:
    enabled: true
    mount: []
    spec:
      {{ ((.Values.redisSidecar.data).spec | default (dict "emptyDir" dict)) | toYaml | nindent 8 }}
{{ end }}
  {{ (.Values.unbound.config).volumeName | default "unbound-config" }}:
    enabled: true
    mount:
    - path: {{ (.Values.unbound.config).mountPath | default "/usr/local/unbound/conf.d" }}
    spec:
      useFromChart: {{ not (or (.Values.unbound.config).existingSecret (.Values.unbound.config).existingConfigMap) }}
      {{ include "unbound.unboundConfigType" . }}:
        name: {{ include "unbound.unboundConfigName" . }}
        defaultMode: 0444
  {{ (.Values.unbound.zones).volumeName | default "unbound-zones" }}:
    enabled: true
    mount:
    - path: {{ (.Values.unbound.zones).mountPath | default "/usr/local/unbound/zones.d" }}
    spec:
      useFromChart: {{ not (or (.Values.unbound.zones).existingSecret (.Values.unbound.zones).existingConfigMap) }}
      {{ include "unbound.unboundZonesType" . }}:
        name: {{ include "unbound.unboundZonesName" . }}
        defaultMode: 0444
  {{ (.Values.unbound.unboundConf).volumeName | default "unbound-conf" }}:
    enabled: true
    mount:
    - path: /usr/local/unbound/unbound.conf
      subPath: unbound.conf
    spec:
      useFromChart: {{ not (or (.Values.unbound.unboundConf).existingSecret (.Values.unbound.unboundConf).existingConfigMap) }}
      {{ include "unbound.unboundConfType" . }}:
        name: {{ include "unbound.unboundConfConfigName" . }}
        defaultMode: 0444
{{- end }}