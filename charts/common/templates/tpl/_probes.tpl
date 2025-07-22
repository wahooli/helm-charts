{{- define "common.tpl.probes" -}}
  {{- $probes := (.Values).probe | default .probe -}}
  {{- range $probeType, $probe := $probes -}}
    {{- $failureThresholdDefault := eq "startup" ($probeType | lower) | ternary 30 10 -}}
    {{- $successThreshold := eq "readiness" ($probeType | lower) | ternary $probe.successThreshold 1 -}}
    {{- $probeEnabled := hasKey $probe "enabled" | ternary $probe.enabled true }}
    {{- if $probeEnabled -}}
      {{- /* loops over known probe types */ -}}
      {{- $probeSpec := dict -}}
      {{- $probeSpecType := false -}}
      {{- /* loops over known probe types */ -}}
      {{- range $i, $_probeSpecType := (list "exec" "httpGet" "tcpSocket" "grpc") -}}
        {{- $currentIsDefault := hasKey $probeSpec "default" | ternary $probeSpec.default false -}}
        {{- $currentIsOverride := hasKey $probeSpec "override" | ternary $probeSpec.override false -}}
        {{- if hasKey $probe $_probeSpecType -}}
          {{- if not $probeSpec -}}
            {{- $probeSpecType = $_probeSpecType -}}
            {{- $probeSpec = index $probe $_probeSpecType | deepCopy -}}
          {{- else -}}
            {{- /* there are multiple probe spec definitions, determine the correct one */ -}}
            {{- $otherIsDefault := hasKey (index $probe $_probeSpecType) "default" | ternary (index $probe $_probeSpecType).default false -}}
            {{- /* if other is default and current probe is defined, just skip it */ -}}
            {{- if not $otherIsDefault -}}
              {{- /* if current is default, override existing */ -}}
              {{- if $currentIsDefault -}}
                {{- $probeSpecType = $_probeSpecType -}}
                {{- $probeSpec = index $probe $_probeSpecType | deepCopy -}}
              {{- /* check if other is override */ -}}
              {{- else if (hasKey (index $probe $_probeSpecType) "override" | ternary (index $probe $_probeSpecType).override false) -}}
                {{- if not $currentIsOverride -}}
                  {{- $probeSpecType = $_probeSpecType -}}
                  {{- $probeSpec = index $probe $_probeSpecType | deepCopy -}}
                {{- else -}}
                  {{- printf "%sProbe has %s and %s probes defined as overrides!" $probeType $probeSpecType $_probeSpecType | fail -}}
                {{- end -}}
              {{- else -}}
                {{- /* neither has override or default booleans, maybe fail here? */ -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- if not $probeSpec -}}
        {{- $probeType | printf "%sProbe doesn't have command, http request, tcpSocket or grpc probe defined!" | fail -}}
      {{- end -}}
      {{- $probeSpec = omit $probeSpec "default" "override" -}}
{{- $probeType | lower | nindent 0 }}Probe:
  {{- $probeSpecType | nindent 2 -}}:
      {{- $probeSpec | toYaml | nindent 4 }}
  initialDelaySeconds: {{ $probe.initialDelaySeconds | default 0 }}
  periodSeconds: {{ $probe.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probe.timeoutSeconds | default 1 }}
  successThreshold: {{ $successThreshold | default 1 }}
  failureThreshold: {{ $probe.failureThreshold | default $failureThresholdDefault }}
    {{- end -}}
  {{- end -}}
{{- end }}