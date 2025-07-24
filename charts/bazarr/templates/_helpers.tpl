{{- define "bazarr.serviceValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- if (.Values.service).main -}}
    {{- $ports := ((.Values.service).main).ports | default list -}}
    {{- if (.Values.metrics).enabled -}}
      {{- $ports = append $ports (dict "name" "metrics" "port" ((.Values.metrics).port | default 9707) "protocol" "TCP") -}}
      {{- $newPorts := dict "Values" (dict "service" (dict "main" (dict "ports" $ports ))) -}}
      {{- $_ := merge $newPorts $ctx -}}
      {{- $ctx = $newPorts -}}
    {{- end -}}
  {{- end -}}
  {{- pick $ctx "Values" | toYaml -}}
{{- end }}

{{- define "bazarr.configMapValues" -}}
{{- $configMaps := dict -}}
{{- range $configMapName, $configMap := .Values.configMaps -}}
  {{- $name := $configMap.name | default $configMapName -}}
  {{- $_ := set $configMaps $name $configMap -}}
{{- end -}}
{{- if (.Values.metrics).enabled -}}
  {{- $_ := set $configMaps "metrics-exporter-scripts" (dict "data" (dict "post-startup.sh" (include "bazarr.postStartScript" .))) -}}
{{- end -}}
configMaps:
  {{- toYaml $configMaps | nindent 2 -}}
{{- end }}

{{- define "bazarr.metricsProbes" -}}
  {{- /* use defaults if probes is not defined.  */ -}}
  {{- if hasKey (.Values).metrics "probe" }}
probe:
    {{- toYaml .Values.metrics.probe | nindent 2 }}
  {{- else }}
probe:
  readiness:
    httpGet:
      default: true
      path: /
      port: metrics
    failureThreshold: 10
    initialDelaySeconds: 5
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 1
  liveness:
    httpGet:
      default: true
      path: /
      port: metrics
    failureThreshold: 10
    initialDelaySeconds: 5
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 1
  {{- end -}}
{{- end }}

{{- define "bazarr.metricsEnv" -}}
  {{- /* use defaults if envs is not defined.  */ -}}
  {{- if hasKey (.Values).metrics "env" }}
env:
    {{- toYaml .Values.metrics.env | nindent 2 }}
  {{- else }}
env:
  URL: http://127.0.0.1:6767
  API_KEY_FILE: /shared/apikey
  PORT: {{ ((.Values.metrics).port | default "9707") | quote }}
  {{- end -}}
{{- end }}

{{- define "bazarr.workloadValues" -}}
  {{- if (.Values.metrics).enabled -}}
    {{- $configVolumeName := (.Values.metrics).configVolumeName -}}
    {{- if and (.Values.metrics).enabled (not (hasKey (.Values).metrics "configVolumeName")) -}}
      {{- $configVolumeName = "config" -}}
    {{- end -}}
    {{- include "bazarr.configMapValues" . }}
env:
  DOCKER_MODS: "{{ (.Values.metrics).dockerModsUrl | default "lscr.io/linuxserver/mods" }}:universal-package-install"
  INSTALL_PACKAGES: yq
{{- if hasKey .Values.persistence $configVolumeName }}
  APIKEY_FILE: /config/shared/apikey
{{- end }}
persistence:
{{- if not (hasKey .Values.persistence $configVolumeName) }}
  shared:
    mount:
    - path: /shared
    spec:
      emptyDir: {}
{{- end }}
  metrics-entrypoint:
    enabled: true
    mount:
    - path: /custom-services.d/post-startup.sh
      subPath: post-startup.sh
    spec:
      useFromChart: true
      configMap:
        name: metrics-exporter-scripts
        defaultMode: 0777
containers:
  bazarr-exporter:
    image:
      repository: {{ ((.Values.metrics).image).repository | default "ghcr.io/onedr0p/exportarr" }}
      pullPolicy: {{ ((.Values.metrics).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.metrics).image).tag | default "latest" }}
      {{- with ((.Values.metrics).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
    {{- include "bazarr.metricsEnv" . | nindent 4 }}
{{- with .Values.metrics.extraEnv }}
      {{- toYaml . | nindent 6 }}
{{- end }}
    args:
    - bazarr
    ports:
    - containerPort: {{ (.Values.metrics).port | default 9707 }}
      name: metrics
      protocol: TCP
    {{- include "bazarr.metricsProbes" . | nindent 4 }}
    {{- with (.Values.metrics).resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{ end -}}
    {{- if hasKey .Values.persistence $configVolumeName }}
    volumeMounts:
    - name: {{ $configVolumeName }}
      mountPath: /shared
      subPath: shared
      readOnly: true
      {{- if semverCompare ">=1.31-0" .Capabilities.KubeVersion.GitVersion }}
      recursiveReadOnly: IfPossible
      {{- end }}
    {{- else }}
    volumeMounts:
    - name: shared
      mountPath: /shared
      readOnly: true
      {{- if semverCompare ">=1.31-0" .Capabilities.KubeVersion.GitVersion }}
      recursiveReadOnly: IfPossible
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}