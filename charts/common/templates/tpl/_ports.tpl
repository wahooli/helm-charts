{{- define "common.tpl.ports.container" -}}
  {{- if .Values.service -}}
    {{- $ports := list -}}
    {{- $portNames := list -}}
    {{- range $serviceName, $service := .Values.service -}}
      {{- $serviceEnabled := true -}}
      {{- if hasKey $service "enabled" -}}
        {{- $serviceEnabled = $service.enabled -}}
      {{- else if not (hasKey $service "ports") -}}
        {{- $serviceEnabled = false -}}
      {{- end -}}
      {{- if $serviceEnabled -}}
        {{- range $_, $port := $service.ports -}}
          {{- $portName := $port.name | trunc 15 | trimAll "-" -}}
          {{- $portEnabled := true -}}
          {{- $serviceOnly := false -}}
          {{- if hasKey $port "enabled" -}}
            {{- $portEnabled = $port.enabled -}}
          {{- end -}}
          {{- if hasKey $port "serviceOnly" -}}
            {{- $serviceOnly = $port.serviceOnly -}}
          {{- end -}}
          {{- if and $portEnabled (not $serviceOnly) -}}
            {{- if has $portName $portNames -}}
              {{- fail (printf "port name '%s' has been already declared!" $portName) -}}
            {{- end -}}
            {{- $portNames = append $portNames $portName -}}

            {{- $containerPort := $port.containerPort | default $port.port -}}
            {{- $protocol := $port.protocol | default "TCP" -}}
            {{- $containerPortSpec := dict "name" $portName "containerPort" $containerPort "protocol" $protocol -}}
            {{- if $port.hostIP -}}
              {{- $_ := set $containerPortSpec "hostIP" $port.hostIP -}}
            {{- end -}}
            {{- if $port.hostPort -}}
              {{- $_ := set $containerPortSpec "hostPort" $port.hostPort -}}
            {{- end -}}
            {{- $ports = append $ports $containerPortSpec -}}

          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- if $ports -}}
      {{ toYaml (dict "ports" $ports) }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{/*
Renders ports for service, excludes container port specific keus
usage:
{{ include "common.tpl.ports.service" .Values.path.to.service.ports }}
*/}}
{{- define "common.tpl.ports.service" -}}
  {{- if . -}}
ports:
    {{- range $_, $port := . -}}
      {{- $portEnabled := true -}}
      {{- if hasKey $port "enabled" -}}
        {{- $portEnabled = $port.enabled -}}
      {{- end -}}
      {{- if $portEnabled }}
- name: {{ $port.name | trunc 15 | trimAll "-" }}
  targetPort: {{ $port.containerPort | default ($port.name | trunc 15 | trimAll "-") }}
  port: {{ $port.port }}
  protocol: {{ $port.protocol | default "TCP" }}
        {{- with $port.nodePort }}
  nodePort: {{ toYaml . }}
        {{- end -}}
        {{- with $port.appProtocol }}
  appProtocol: {{ toYaml . }}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end }}
