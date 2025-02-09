{{- define "plex.serviceValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- if (.Values.service).main -}}
    {{- $ports := ((.Values.service).main).ports | default list -}}
    {{- if (.Values.metrics).enabled -}}
      {{- $ports = append $ports (dict "name" "metrics" "port" 9000 "protocol" "TCP") -}}
      {{- $newPorts := dict "Values" (dict "service" (dict "main" (dict "ports" $ports ))) -}}
      {{- $_ := merge $newPorts $ctx -}}
      {{- $ctx = $newPorts -}}
    {{- end -}}
  {{- end -}}
  {{- pick $ctx "Values" | toYaml -}}
{{- end }}

{{- define "plex.configMapValues" -}}
{{- $configMaps := dict -}}
{{- range $configMapName, $configMap := .Values.configMaps -}}
  {{- $name := $configMap.name | default $configMapName -}}
  {{- $_ := set $configMaps $name $configMap -}}
{{- end -}}
{{- if (.Values.metrics).enabled -}}
  {{- $_ := set $configMaps "metrics-exporter-entrypoint" (dict "data" (dict "entrypoint-override.sh" (include "plex.metricsEntrypoint" .) "post-startup.sh" (include "plex.postStartScript" .))) -}}
{{- end -}}
configMaps:
  {{- toYaml $configMaps | nindent 2 -}}
{{- end }}

{{- define "plex.workloadValues" -}}
{{ include "plex.configMapValues" . }}
{{- if (.Values.metrics).enabled -}}
{{- $probePath := "/" -}}
{{- $exporterImageRepo := ((.Values.metrics).image).repository | default "ghcr.io/axsuul/plex-media-server-exporter" -}}
{{- if contains "jsclayton/prometheus-plex-exporter" $exporterImageRepo }}
  {{- $probePath = "/metrics" -}}
{{- end }}
env:
  DOCKER_MODS: "linuxserver/mods:universal-package-install"
  INSTALL_PACKAGES: xmlstarlet
persistence:
  shared:
    mount:
    - path: /shared
    spec:
      emptyDir: {}
  metrics-entrypoint:
    enabled: true
    mount:
    - path: /custom-services.d/post-startup.sh
      subPath: post-startup.sh
    spec:
      useFromChart: true
      configMap:
        name: metrics-exporter-entrypoint
        defaultMode: 0777
containers:
  prometheus-exporter:
    image:
      repository: {{ $exporterImageRepo }}
      pullPolicy: {{ ((.Values.metrics).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.metrics).image).tag | default "latest" }}
      {{- with ((.Values.metrics).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
    env:
      PLEX_SERVER: http://127.0.0.1:32400
      PLEX_ADDR: http://127.0.0.1:32400
{{- with .Values.metrics.env }}
      {{- toYaml . | nindent 6 }}
{{- end }}
    command:
    - /entrypoint-override.sh
{{- if contains "jsclayton/prometheus-plex-exporter" $exporterImageRepo }}
    args:
    - /prometheus-plex-exporter
{{- end }}
{{- if contains "axsuul/plex-media-server-exporter" $exporterImageRepo }}
    args:
    - bundle
    - exec
    - puma
    - -b
    - tcp://0.0.0.0:9000
{{- end }}
    ports:
    - containerPort: 9000
      name: metrics
      protocol: TCP
    volumeMounts:
    - name: shared
      mountPath: /shared
      readOnly: true
      {{- if semverCompare ">=1.31-0" .Capabilities.KubeVersion.GitVersion }}
      recursiveReadOnly: IfPossible
      {{- end }}
    - mountPath: /entrypoint-override.sh
      name: metrics-entrypoint
      subPath: entrypoint-override.sh
    probe:
      readiness:
        httpGet:
          default: true
          path: {{ $probePath }}
          port: metrics
        failureThreshold: 10
        initialDelaySeconds: 5
        periodSeconds: 5
        successThreshold: 1
        timeoutSeconds: 1
      liveness:
        httpGet:
          default: true
          path: {{ $probePath }}
          port: metrics
        failureThreshold: 10
        initialDelaySeconds: 5
        periodSeconds: 5
        successThreshold: 1
        timeoutSeconds: 1
      startup:
        exec:
          default: true
          command:
          - sh
          - -c
          - test -e /shared/token
        periodSeconds: 5
        failureThreshold: 120
        successThreshold: 1
        timeoutSeconds: 1
    resources:
      limits:
        cpu: 100m
        memory: 100Mi
{{- end }}
{{- end }}