{{- define "haproxy.globalConfig" -}}
global
    log stdout format raw local0
    maxconn 2048
    tune.ssl.default-dh-param 2048
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
    ssl-default-bind-ciphers PROFILE=SYSTEM
    stats           socket /var/lib/haproxy/stats
{{- end }}

{{- define "haproxy.defaultsConfig" -}}
defaults
    log                     global
    option                  tcplog
    option                  dontlognull
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
{{- end }}

{{- define "haproxy.statsEndpoint" -}}
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /
    stats refresh 10s
    stats admin if TRUE
{{- end }}

{{- define "haproxy.httpsRedirectFrontend" -}}
frontend http
    bind *:80
    mode http
    redirect scheme https code 301 if !{ ssl_fc }
{{- end }}

{{- define "haproxy.resolversBlock" -}}
  {{- $dnsIP := "" -}}
  {{- if .Capabilities.APIVersions.Has "v1/Service" -}}
    {{- $dns := lookup "v1" "Service" ((.Values.clusterDnsSvc).namespace | default "kube-system") ((.Values.clusterDnsSvc).name | default "kube-dns")  -}}
    {{- if ($dns.spec).clusterIP -}}
      {{- $dnsIP = $dns.spec.clusterIP }}
    {{- else if (.Values.clusterDnsSvc).ipAddress -}}
      {{- $dnsIP = .Values.clusterDnsSvc.ipAddress -}}
    {{- else -}}
      {{- fail "DNS service not found and .Values.clusterDnsSvc.ipAddress not provided" -}}
    {{- end -}}
  {{- end -}}
resolvers k8s
    nameserver dns {{ $dnsIP | default "placeholder" }}:53
    hold valid 5s
{{- end }}

{{- define "haproxy.endConfig" -}}
{{ print "\n#" }}
{{- end }}

{{- define "haproxy.config" }}
{{- include "haproxy.globalConfig" . }}

{{ include "haproxy.defaultsConfig" . }}

{{ include "haproxy.resolversBlock" . }}

{{ include "haproxy.httpsRedirectFrontend" . }}

{{ include "haproxy.statsEndpoint" . }}
{{ end }}

{{- /*
creates haproxy compatible server list from passed values
usage: {{ include "haproxy.servicePodsServerList" (list $ "[destPort]" "[chartName]" "[checkSyntax]" "[serviceName (default main)]" )}}
*/ -}}
{{- define "haproxy.servicePodsServerList" -}}
  {{- $ctx := index . 0 -}}
  {{- $destPort := index . 1 -}}
  {{- $chart := index . 2 -}}
  {{- $checkSyntax := "" -}}
  {{- if ge (len .) 4 -}}
    {{- $checkSyntax = index . 3 -}}
  {{- end -}}

  {{- $svc := "main" -}}
  {{- if ge (len .) 5 -}}
    {{- $svc = index . 4 | default "main" -}}
  {{- end -}}

  {{- $pods := include "common.helpers.names.podFQDNs" (list $ctx $chart $svc) | fromYamlArray -}}
  {{- range $podFQDN := $pods -}}
    {{- $shortName := (split "." $podFQDN)._0 -}}
    {{- printf "server %s %s:%s %s" $shortName $podFQDN $destPort $checkSyntax | nindent 0 -}}
  {{- end -}}
{{- end }}
