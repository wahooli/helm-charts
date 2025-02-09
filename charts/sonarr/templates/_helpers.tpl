{{- define "sonarr.serviceValues" -}}
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

{{- define "sonarr.workloadValues" -}}
  {{- if (.Values.metrics).enabled -}}
    {{- $configVolumeName := (.Values.metrics).configVolumeName | default "config" -}}
containers:
  exportarr:
    image:
      repository: {{ ((.Values.metrics).image).repository | default "ghcr.io/onedr0p/exportarr" }}
      pullPolicy: {{ ((.Values.metrics).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.metrics).image).tag | default "latest" }}
      {{- with ((.Values.metrics).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
    env:
      URL: http://127.0.0.1:8989
      CONFIG: /config/config.xml
      PORT: {{ ((.Values.metrics).port | default "9707") | quote }}
{{- with .Values.metrics.env }}
      {{- toYaml . | nindent 6 }}
{{- end }}
    args:
    - sonarr
    ports:
    - containerPort: {{ (.Values.metrics).port | default 9707 }}
      name: metrics
      protocol: TCP
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
    resources:
      limits:
        cpu: 100m
        memory: 100Mi
    {{- if hasKey .Values.persistence $configVolumeName }}
    volumeMounts:
    - name: {{ $configVolumeName }}
      mountPath: /config
      readOnly: true
      recursiveReadOnly: IfPossible
    {{- end }}
  {{- end }}
{{- end }}