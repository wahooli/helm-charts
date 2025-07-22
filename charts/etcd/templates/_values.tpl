{{- define "etcd.endpoints" -}}
  {{- $podNames := list -}}
  {{- $serviceFQDN := include "common.helpers.names.stsServiceFQDN" . -}}
  {{- range $pod := (include "common.helpers.names.podNames" (list $)) | fromYamlArray -}}
    {{- $podNames = append $podNames (printf "$(URI_SCHEME)://%s.%s:2379" $pod $serviceFQDN) -}}
  {{- end -}}
--endpoints={{- join "," $podNames -}}
{{- end }}

{{- define "etcd.gatewayWaitCommand" -}}

{{- /* Collect candidates from all sources */ -}}
{{- $gord := dict -}}
{{- $gcluster := dict -}}
{{- if hasKey .Values "global" -}}
  {{- $gvals := (get .Values.global "etcd" | default dict) -}}
  {{- $gcluster = get $gvals "cluster" | default dict -}}
  {{- $gord = get $gcluster "ordinals" | default dict -}}
{{- end -}}

{{- $ccluster := get .Values "cluster" | default dict -}}
{{- $cord := get $ccluster "ordinals" | default dict -}}

{{- $directOrd := get .Values "ordinals" | default dict -}}

{{- /* Prioritized selection */ -}}
{{- $ordinalStart := 0 -}}
{{- if hasKey $gord "start" }}
  {{- $ordinalStart = int (index $gord "start") -}}
{{- else if hasKey $cord "start" }}
  {{- $ordinalStart = int (index $cord "start") -}}
{{- else if hasKey $directOrd "start" }}
  {{- $ordinalStart = int (index $directOrd "start") -}}
{{- end -}}

{{- $replicaCount := 0 -}}
{{- if hasKey $gcluster "replicaCount" -}}
  {{- $replicaCount = int (index $gcluster "replicaCount") -}}
{{- else if hasKey $ccluster "replicaCount" -}}
  {{- $replicaCount = int (index $ccluster "replicaCount") -}}
{{- else if hasKey .Values "replicaCount" -}}
  {{- $replicaCount = int (index .Values "replicaCount") -}}
{{- end -}}

{{- $untilEnd := add (int $ordinalStart) (int $replicaCount) -}}
{{- $serviceFQDN := include "common.helpers.names.stsServiceFQDN" . -}}
{{- $fullName := include "common.helpers.names.fullname" . -}}
for i in {{ untilStep $ordinalStart (int $untilEnd) 1 | join " " }}; do
  until wget --spider --timeout=2 http://{{ $fullName }}-$i.{{ $serviceFQDN }}:8080/readyz; do
    echo "Waiting for etcd-$i to be ready..."
    sleep 2
  done
done
{{- end }}

{{- define "etcd.initialCluster" -}}
  {{- $podNames := list -}}
  {{- range $pod := (include "common.helpers.names.podNames" (list $)) | fromYamlArray -}}
    {{- $podNames = append $podNames (printf "%s=$(URI_SCHEME)://%s.%s:2380" $pod $pod "$(SERVICE_FQDN)") -}}
  {{- end -}}
--initial-cluster={{- join "," $podNames -}}
{{- end }}

{{- define "etcd.gatewaySvcName" -}}
  {{- if (.Values.gateway).fullnameOverride -}}
    {{- .Values.gateway.fullnameOverride -}}
  {{- else -}}
    {{- $gatewayName := (.Values.gateway).nameOverride | default "etcd-gateway" -}}
    {{- if contains "etcd" .Release.Name -}}
      {{- (replace "etcd" "etcd-gateway" .Release.Name)  | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- .Release.Name -}}-{{- $gatewayName -}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "etcd.certificateValues" -}}
  {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef -}}
  {{- $dnsNames := include "common.helpers.names.DNSNames" . | fromYamlArray -}}
  {{- $clientDnsNames := $dnsNames -}}
  {{- if (.Values.gateway).enabled -}}
    {{- $gatewaySvcName := include "etcd.gatewaySvcName" . -}}
    {{- $gwNames := (include "common.helpers.names.serviceDNSNames" (list $ $gatewaySvcName false)) | fromYamlArray -}}
    {{- $clientDnsNames = concat $clientDnsNames $gwNames -}}
  {{- end }}
certificates:
  client:
    dnsNames: 
    {{- toYaml $clientDnsNames | nindent 4 }}
    issuerRef:
      {{- (.Values.ssl).issuerRef | toYaml | nindent 6 }}
  server:
    dnsNames: 
    {{- toYaml $dnsNames | nindent 4 }}
    issuerRef:
      {{- (.Values.ssl).issuerRef | toYaml | nindent 6 }}
  {{ end -}}
{{- end }}

{{- define "etcd.stsValues" -}}
{{- $ctx := deepCopy . -}}
{{- $_ := include "etcd.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "etcd.workloadValues" $ctx }}
{{- end }}

{{- define "etcd.workloadValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- if (.Values.ssl).enabled }}
env:
  URI_SCHEME: https
    {{- if and (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}

  ETCDCTL_KEY: /etc/etcd/certs/client/tls.key
  ETCDCTL_CERT: /etc/etcd/certs/client/tls.crt
  ETCDCTL_CACERT: /etc/etcd/certs/client/ca.crt

args:
- {{ include "etcd.initialCluster" . }}
- --client-cert-auth
- --trusted-ca-file=$(ETCDCTL_CACERT)
- --cert-file=$(ETCDCTL_CERT)
- --key-file=$(ETCDCTL_KEY)
- --peer-client-cert-auth
- --peer-trusted-ca-file=/etc/etcd/certs/server/ca.crt
- --peer-cert-file=/etc/etcd/certs/server/tls.crt
- --peer-key-file=/etc/etcd/certs/server/tls.key

persistence:
  client-tls:
    enabled: true
    mount:
    - path: /etc/etcd/certs/client
      readOnly: true
    spec:
      useFromChart: false
      secret:
        name: {{ (.Values.certificates.client).secretName | default (printf "%s-%s" $fullName "client" ) }}
        optional: false
  server-tls:
    enabled: true
    mount:
    - path: /etc/etcd/certs/server
      readOnly: true
    spec:
      useFromChart: false
      secret:
        name: {{ (.Values.certificates.server).secretName | default (printf "%s-%s" $fullName "server" ) }}
        optional: false
    {{- end -}}
  {{- else }}
env:
  URI_SCHEME: http
  {{- end -}}
{{- end }}
