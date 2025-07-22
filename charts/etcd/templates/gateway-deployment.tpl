{{- if (.Values.gateway).enabled -}}
  {{- $ctx := deepCopy . -}}
  {{- $valuesBase := omit $ctx.Values "args" "command" "service" "env" "probe" "persistence" "resources" "nodeSelector" "tolerations" "affinity" "serviceAccount" "gateway" "replicaCount" "fullnameOverride" "nameOverride" "initContainers" -}}
  {{- $_ := $ctx.Values.gateway | merge $valuesBase -}}
  {{- $args := $valuesBase.args -}}
  {{- $args = append $args (include "etcd.endpoints" .) -}}
  {{- $_ := set $valuesBase "args" $args -}}
  {{- $_ := include "etcd.stsValues" . | fromYaml | merge $valuesBase -}}
  {{- $_ := set $valuesBase "workloadType" "Deployment" -}}
  {{- if contains "etcd" $ctx.Release.Name -}}
    {{- $release := $ctx.Release -}}
    {{- $_ := set $release "Name" ((replace "etcd" "etcd-gateway" $release.Name)  | trunc 63 | trimSuffix "-") -}}
    {{- $_ := set $ctx "Release" $release -}}
  {{- end -}}
  {{- if not $valuesBase.nameOverride -}}
    {{- $_ := set $valuesBase "nameOverride" "etcd-gateway" -}}
  {{- end -}}

  {{- $_ := set $ctx "Values" $valuesBase -}}

  {{- if ($ctx.Values.ssl).enabled -}}
    {{- $gatewaySvcName := include "etcd.gatewaySvcName" . -}}
    {{- $livenessProbe := omit $ctx.Values.probe.liveness "httpGet" "tcpSocket" "exec" -}}
    {{- $readinessProbe := omit $ctx.Values.probe.readiness "httpGet" "tcpSocket" "exec" -}}
    {{- $values := get $ctx  "Values" -}}
    {{- $probes := get $values "probe" -}}
    {{- $newProbeCommand := list "etcdctl" (printf "--endpoints=https://%s:2379" $gatewaySvcName) "endpoint" "health" -}}
    {{- $exec := dict "command" $newProbeCommand -}}
    {{- $_ := set $livenessProbe "exec" $exec -}}
    {{- $_ := set $readinessProbe "exec" $exec -}}
    {{- $_ := set $probes "liveness" $livenessProbe -}}
    {{- $_ := set $probes "readiness" $readinessProbe -}}
  {{- end -}}
  {{- if (.Values.gateway.waitForEtcd).enabled -}}
    {{- $values := get $ctx "Values" -}}
    {{- $initContainers := get $values "initContainers" | default dict -}}
    {{- $command := list "sh" "-c" (include "etcd.gatewayWaitCommand" .) }}
    {{- $initContainer := dict
        "image" .Values.gateway.waitForEtcd.image
        "imagePullPolicy" (.Values.gateway.waitForEtcd.imagePullPolicy | default "IfNotPresent")
        "command" $command
    -}}
    {{- $_ := set $initContainers "wait-for-etcd" $initContainer -}}
    {{- $_ := set $values "initContainers" $initContainers -}}
  {{- end -}}
{{ include "common.deployment" $ctx }}
---
{{ include "common.service" $ctx }}
{{- end -}}
