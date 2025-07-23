

{{- define "redis.healthcheckScript" -}}
#!/bin/bash
set -euo pipefail

SOCKET="/var/run/redis/redis.sock"

# Quick check: does socket exist and respond to PING?
if ! redis-cli -s "$SOCKET" ping | grep -q PONG; then
  echo "Redis socket not responding to PING"
  exit 1
fi

# Get role from INFO
role=$(redis-cli -s "$SOCKET" info replication | awk -F: '/^role:/ {print $2}' | tr -d '\r')

case "$role" in
  master)
    # All good
    exit 0
    ;;
  slave)
    # For replicas, ensure they're connected to master
    master_link_status=$(redis-cli -s "$SOCKET" info replication | awk -F: '/^master_link_status:/ {print $2}' | tr -d '\r')
    if [ "$master_link_status" = "up" ]; then
      exit 0
    else
      echo "Replica not connected to master (status: $master_link_status)"
      exit 1
    fi
    ;;
  *)
    # Unknown role or something broken
    echo "Unknown Redis role: $role"
    exit 1
    ;;
esac
{{- end }}

{{- define "redis.entrypoint" -}}
  {{- $sentinelSvcName := include "common.helpers.names.serviceName" ( list $ "sentinel" )  -}}
  {{- $sentinelSvcFQDN := printf "%s.%s.svc.%s." $sentinelSvcName .Release.Namespace ( include "common.helpers.names.clusterDomain" . ) -}}
  {{- $initialMaster := .Values.redis.initialMaster | default "0" -}}
  {{- $isClusterMode := and (or ((.Values.global).redis).cluster (.Values).cluster) .Values.redis.sentinel.enabled -}}
#!/bin/sh
set -e

{{- if $isClusterMode }}
# --- Cluster Mode Configuration and Functions ---
ORDINAL=$(echo "${POD_NAME}" | grep -oE '[0-9]+$')
SENTINEL_HOST="{{ (.Values.redis).sentinelHost | default $sentinelSvcFQDN }}"
SENTINEL_PORT=26379
MASTER_NAME="{{ required ".Values.redis.sentinel.masterName or .Values.global.redis.redis.sentinel.masterName is required!" (((.Values.global.redis.redis).sentinel).masterName | default .Values.redis.sentinel.masterName) }}"
MAX_RETRIES=30
RETRY_INTERVAL=5

query_sentinel() {
  {{- if and (.Values.ssl).generateCertificates (.Values.ssl).issuerRef (.Values.ssl).enabled }}
  redis-cli --tls --cert /certs/tls.crt --key /certs/tls.key --cacert /certs/ca.crt -h "$SENTINEL_HOST" -p "$SENTINEL_PORT" SENTINEL get-master-addr-by-name "$MASTER_NAME" 2>/dev/null || true
  {{- else }}
  redis-cli -h "$SENTINEL_HOST" -p "$SENTINEL_PORT" SENTINEL get-master-addr-by-name "$MASTER_NAME"  2>/dev/null || true
  {{- end }}
}

ping_host() {
    local host="$1"; local port="$2"
    if [ -z "$host" ] || [ -z "$port" ]; then return 1; fi
    local response
  {{- if and (.Values.ssl).generateCertificates (.Values.ssl).issuerRef (.Values.ssl).enabled }}
    response=$(redis-cli --tls --cert /certs/tls.crt --key /certs/tls.key --cacert /certs/ca.crt -h "$host" -p "$port" -t 3 PING 2>/dev/null || true)
  {{- else }}
    response=$(redis-cli -h "$host" -p "$port" -t 3 PING 2>/dev/null || true)
  {{- end }}
    if [ "$response" = "PONG" ]; then return 0; else return 1; fi
}

# --- Cluster Role Discovery Logic ---
echo "Running in Cluster Mode. Determining role for ${POD_NAME}..."
MASTER_HOST=""
MASTER_PORT=""
IS_MASTER=false
ROLE_DECIDED=false

for i in $(seq 1 $MAX_RETRIES); do
    MASTER_INFO=$(query_sentinel)
    CURRENT_MASTER_HOST=$(echo "$MASTER_INFO" | sed -n '1p')
    CURRENT_MASTER_PORT=$(echo "$MASTER_INFO" | sed -n '2p')

    if [ -z "$CURRENT_MASTER_HOST" ]; then
        if [ "$ORDINAL" -eq {{ $initialMaster }} ]; then
            echo "Sentinel has no master. As redis-{{ $initialMaster }}, assuming master role for bootstrap."
            IS_MASTER=true; ROLE_DECIDED=true; break
        else
            echo "Sentinel has no master. Waiting... ($i/$MAX_RETRIES)"; sleep $RETRY_INTERVAL; continue
        fi
    fi

    if [ "${CURRENT_MASTER_HOST%.}" = "${POD_FQDN%.}" ] || [ "$CURRENT_MASTER_HOST" = "$POD_IP" ]; then
        if [ "$ORDINAL" -eq {{ $initialMaster }} ]; then
            echo "This pod is initial master and Sentinel agrees. Reclaiming role."
            IS_MASTER=true; ROLE_DECIDED=true; break
        else
            echo "Replica listed as master but not initial master. Waiting for failover... ($i/$MAX_RETRIES)"; sleep $RETRY_INTERVAL; continue
        fi
    fi

    echo "Sentinel designated master: ${CURRENT_MASTER_HOST}:${CURRENT_MASTER_PORT}. Pinging..."
    if ping_host "$CURRENT_MASTER_HOST" "$CURRENT_MASTER_PORT"; then
        echo "Master reachable. Accepting replica role."
        MASTER_HOST=$CURRENT_MASTER_HOST
        MASTER_PORT=$CURRENT_MASTER_PORT
        IS_MASTER=false
        ROLE_DECIDED=true
        break
    else
        echo "Designated master not reachable. Retrying... ($i/$MAX_RETRIES)"; sleep $RETRY_INTERVAL
    fi
done

if [ "$ROLE_DECIDED" = "false" ]; then
    echo "FATAL: Could not determine role. Exiting."; exit 1
fi
{{- else }}
# --- Standalone Mode ---
echo "Running in Standalone Mode."
# In standalone, this pod is always the master.
IS_MASTER=true
{{- end }}

# --- Unified Config Generation ---
COMMON_CONFIG=$(cat <<EOF
{{- if (.Values.ssl).enabled }}
tls-port 6379
port 0
tls-protocols "TLSv1.2 TLSv1.3"
  {{- if and (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
tls-cert-file /certs/tls.crt
tls-key-file /certs/tls.key
tls-ca-cert-file /certs/ca.crt
tls-auth-clients no
    {{- if $isClusterMode }}
# This line is only added for cluster mode.
tls-replication yes
    {{- end }}
  {{- end }}
{{- else }}
port 6379
{{- end }}
{{ tpl .Values.redis.config . -}}
EOF
)

# --- Unified Config Writing and Execution ---
rm -f /data/redis.conf
if [ "$IS_MASTER" = true ]; then
    echo "Writing master config..."
    echo "$COMMON_CONFIG" > /data/redis.conf
else
    # This block is only reachable in Cluster Mode, and MASTER_HOST/PORT are guaranteed to be set.
    echo "Writing replica config for master ${MASTER_HOST}:${MASTER_PORT}..."
    {
        echo "$COMMON_CONFIG"
        echo "replicaof $MASTER_HOST $MASTER_PORT"
    } > /data/redis.conf
fi

touch /tmp/ready
echo "Launching redis-server..."
exec redis-server /data/redis.conf
{{- end }}

{{- define "redis.sentinelEntrypoint" -}}
#!/bin/sh
set -e

# MASTER_IP=$(getent hosts "{{ include "common.helpers.names.podFQDN" (list . "redis" .Values.redis.initialMaster "main" )}}" | awk '{print $1}')
# [ -z "$MASTER_IP" ] && MASTER_IP="${POD_IP}"

MASTER_ADDRESS="{{ include "common.helpers.names.podFQDN" (list . "redis" .Values.redis.initialMaster "main" )}}"

cat <<EOF > /data/redis-sentinel.conf
{{- if (.Values.ssl).enabled }}
tls-port 26379
port 0
{{- else }}
port 26379
{{- end }}
{{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
tls-cert-file /certs/tls.crt
tls-key-file /certs/tls.key
tls-ca-cert-file /certs/ca.crt
tls-auth-clients no
tls-replication yes
{{- end }}
{{ tpl .Values.redis.sentinel.config . }}

EOF

echo "Starting redis sentinel"
exec redis-server /data/redis-sentinel.conf --sentinel

{{- end }}

{{- define "redis.configMapValues" -}}
configMaps:
  entrypoint-override:
    data:
      redis-server.sh: |
        {{- include "redis.entrypoint" . | nindent 8 }}
      redis-sentinel.sh: |
        {{- include "redis.sentinelEntrypoint" . | nindent 8 }}
      healthcheck.sh: |
        {{- include "redis.healthcheckScript" . | nindent 8 }}
{{- end }}

{{- define "redis.certificateValues" -}}
  {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef -}}
  {{- $dnsNames := include "common.helpers.names.DNSNames" . | fromYamlArray -}}
  {{- $clientDnsNames := $dnsNames -}}
  {{- if (.Values.haproxy).enabled -}}
    {{- $haproxySvcName := include "common.helpers.names.subchartSvcName" (list . "haproxy") -}}
    {{- $gwNames := (include "common.helpers.names.serviceDNSNames" (list $ $haproxySvcName false)) | fromYamlArray -}}
    {{- $clientDnsNames = concat $clientDnsNames $gwNames -}}
  {{- end }}
certificates:
  server:
    dnsNames: 
    {{- toYaml $clientDnsNames | nindent 4 }}
    issuerRef:
      {{- (.Values.ssl).issuerRef | toYaml | nindent 6 }}
  {{ end -}}
{{- end }}

{{- define "redis.stsValues" -}}
{{- $ctx := deepCopy . -}}
{{- $_ := include "redis.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "redis.workloadValues" $ctx }}
{{- end }}

{{- define "redis.sentinelProbe" -}}
{{- $probe := .Values.redis.sentinel.probe -}}
{{- $masterName := default ((((.Values.global).redis).redis).sentinel).masterName (.Values.redis.sentinel).masterName | required "masterName is required!" -}}
{{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef -}}
  {{- $cmd := printf "redis-cli --tls --cert /certs/tls.crt --key /certs/tls.key --cacert /certs/ca.crt -h 127.0.0.1 -p 26379 SENTINEL get-master-addr-by-name %s | wc -l | grep -q '^2$'" $masterName -}}
  {{- $command := list "sh" "-c" $cmd -}}
  {{- $exec := dict "command" $command -}}

  {{- $liveness := get $probe "liveness" -}}
  {{- $liveness = omit $liveness "tcpSocket" -}}
  {{- $_ := set $liveness "exec" $exec -}}
  {{- $_ := set $probe "liveness" $liveness -}}

  {{- $readiness := get $probe "readiness" -}}
  {{- $readiness = omit $readiness "tcpSocket" -}}
  {{- $_ := set $readiness "exec" $exec -}}
  {{- $_ := set $probe "readiness" $readiness -}}

{{- end -}}
{{- toYaml $probe -}}
{{- end }}

{{- define "redis.sentinelContainer" -}}
{{- $image := .Values.image -}}
{{- if not $image.tag -}}
  {{- $_ := set $image "tag" .Chart.AppVersion -}}
{{- end -}}
{{- if not $image.pullPolicy -}}
  {{- $_ := set $image "pullPolicy" "IfNotPresent" -}}
{{- end -}}
containers:
  redis-sentinel:
  {{- with $image }}
    image:
      {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- with (.Values.redis.sentinel).command }}
    command:
      {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- with .Values.env }}
    env:
      {{- toYaml . | nindent 6}}
  {{- end }}
    ports:
    - containerPort: {{ (.Values.redis.sentinel).port | default 26379 }}
      name: sentinel
      protocol: TCP
    volumeMounts:
    - mountPath: /data
      name: {{ (.Values.redis.sentinel).dataVolume | default "sentinel-data" }}
    - mountPath: /redis-sentinel.sh
      name: entrypoint
      subPath: redis-sentinel.sh
    {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
    - mountPath: /certs
      name: server-tls
      readOnly: true
    {{- end }}
    probe:
    {{- include "redis.sentinelProbe" . | nindent 6 }}
  {{- with (.Values.redis.sentinel).resources }}
    resources:
    {{- toYaml . | nindent 6 }}
  {{- end }}
  {{- with (.Values.redis.sentinel).securityContext }}
    securityContext:
    {{- toYaml . | nindent 6 }}
  {{- end }}
{{- end }}

{{- define "redis.serviceValues" -}}
service:
{{- if (.Values.redis.sentinel).enabled | default false }}
  main:
    ports:
    - name: redis
      port: 6379
      serviceOnly: {{ not (.Values.redis).enabled }}
      protocol: TCP
    - name: sentinel
      port: 26379
      serviceOnly: {{ (.Values.redis).enabled }}
      protocol: TCP
{{- end }}
  sentinel:
    enabled: {{ (.Values.redis.sentinel).enabled | default false }}
{{- end }}

{{- define "redis.workloadValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $sentinelDataVolume := (.Values.redis.sentinel).dataVolume | default "sentinel-data" -}}
{{- if and (.Values.redis).enabled (.Values.redis.sentinel).enabled }}
  {{- include "redis.sentinelContainer" . }}
{{- else if not (.Values.redis).enabled }}
containerName: redis-sentinel
command:
- "/redis-sentinel.sh"
service:
  main:
    ports:
    - name: redis
      port: 6379
      protocol: TCP
      serviceOnly: true
  sentinel:
    ports:
    - name: sentinel
      port: 26379
      protocol: TCP
probe:
  {{- include "redis.sentinelProbe" . | nindent 2 }}
{{- end }}
persistence:
{{- if and (.Values.redis.sentinel).enabled (.Values.redis).enabled (not (hasKey .Values.persistence $sentinelDataVolume)) }}
  {{ $sentinelDataVolume }}:
    enabled: true
    spec:
      emptyDir: {}
{{- end }}
  entrypoint:
    enabled: true
    mount:
{{- if (.Values.redis).enabled }}
    - path: /healthcheck.sh
      subPath: healthcheck.sh
    - path: /redis-server.sh
      subPath: redis-server.sh
{{- else if and (not ((.Values.redis).enabled )) ((.Values.redis.sentinel).enabled | default false) }}
    - path: /redis-sentinel.sh
      subPath: redis-sentinel.sh
{{- end }}
    spec:
      useFromChart: true
      configMap:
        name: entrypoint-override
        defaultMode: 0555
  {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
  server-tls:
    enabled: true
    mount:
    - path: /certs
      readOnly: true
    spec:
      useFromChart: false
      secret:
        defaultMode: 0400
        name: {{ (.Values.certificates.server).secretName | default (printf "%s-%s" $fullName "server" ) }}
        optional: false
  {{ end }}
{{ include "redis.configMapValues" . }}

{{ include "redis.serviceValues" . }}
{{- end }}
