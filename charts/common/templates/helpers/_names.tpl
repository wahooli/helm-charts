{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.helpers.names.fullname" -}}
  {{- $chartName := include "common.helpers.variables.getField" (list .Chart "Name") -}}
  {{- include "common.helpers.names.chartFullname" (list . $chartName) -}}
{{- end }}

{{/*
common.helpers.names.chartFullname

Generates a chart-specific fullname, prioritizing:
- If `chartName == ctx.Chart.Name`: behaves like `fullname`
- Else: reads from `.Values.global[chartName].nameOverride` or `fullnameOverride`

Arguments:
  - . (Helm context)
  - chartName (string): which chart key to resolve name for

Usage:
  {{ include "common.helpers.names.chartFullname" (list . "[name of the chart]") }}
*/}}
{{- define "common.helpers.names.chartFullname" -}}
  {{- $ctx := index . 0 -}}
  {{- $chartName := index . 1 -}}
  {{- $ctxChartName := include "common.helpers.variables.getField" (list $ctx.Chart "Name") -}}
  {{- $isSelf := eq $chartName $ctxChartName -}}

  {{- $fullnameOverride := "" -}}
  {{- $nameOverride := "" -}}

  {{- if $isSelf -}}
    {{- $fullnameOverride = $ctx.Values.fullnameOverride | default "" -}}
    {{- $nameOverride = default $ctxChartName $ctx.Values.nameOverride -}}
  {{- else if and (hasKey $ctx.Values "global") (hasKey $ctx.Values.global $chartName) -}}
    {{- $gvals := get $ctx.Values.global $chartName | default dict -}}
    {{- $fullnameOverride = get $gvals "fullnameOverride" | default "" -}}
    {{- $nameOverride = get $gvals "nameOverride" | default $chartName -}}
  {{- else if hasKey $ctx.Values $chartName -}}
    {{- $subchartVals := get $ctx.Values $chartName | default dict -}}
    {{- $fullnameOverride = get $subchartVals "fullnameOverride" | default "" -}}
    {{- $nameOverride = get $subchartVals "nameOverride" | default $chartName -}}
  {{- end -}}

  {{- include "common.helpers.names._generateName" (list $ctx.Release.Name $fullnameOverride $nameOverride) -}}
{{- end }}

{{/*
common.helpers.names._generateName

Internal helper to generate name from overrides.

Arguments:
  - releaseName
  - fullnameOverride
  - nameOverride
*/}}
{{- define "common.helpers.names._generateName" -}}
  {{- $releaseName := index . 0 -}}
  {{- $fullnameOverride := index . 1 -}}
  {{- $nameOverride := index . 2 -}}

  {{- if $fullnameOverride }}
    {{- $fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else if contains $nameOverride $releaseName }}
    {{- $releaseName | trunc 63 | trimSuffix "-" }}
  {{- else if hasPrefix (printf "%s-" $releaseName) $nameOverride }}
    {{- $nameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "%s-%s" $releaseName $nameOverride | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.helpers.name" -}}
  {{- $chartName := include "common.helpers.variables.getField" (list .Chart "Name") -}}
  {{- default $chartName .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.helpers.names.container" -}}
  {{- $chartName := include "common.helpers.variables.getField" (list .Chart "Name") -}}
  {{- default $chartName .Values.containerName -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.helpers.names.chart" -}}
  {{- $chartName := include "common.helpers.variables.getField" (list .Chart "Name") -}}
  {{- $chartVersion := include "common.helpers.variables.getField" (list .Chart "Version") -}}
  {{- printf "%s-%s" $chartName $chartVersion | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/* Returns name of service account, if enabled */}}
{{- define "common.helpers.names.serviceAccount" -}}
  {{- if (.Values.serviceAccount).create -}}
    {{- default (include "common.helpers.names.fullname" .) .Values.serviceAccount.name -}}
  {{- else -}}
    {{- default "default" (.Values.serviceAccount).name -}}
  {{- end -}}
{{- end }}

{{/* Returns service name, headless if enabled */}}
{{- define "common.helpers.names.stsServiceName" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $stsServiceName := "" -}}

  {{- range $name, $service := (.Values.service) -}}
    {{- if and (kindIs "map" $service) (gt (len $service) 0) -}}
      {{- $serviceName := ($service).name | default $name -}}
      {{- if and (eq "" $stsServiceName) $service.isStsService -}}
        {{- $stsServiceName = $serviceName -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- /* try defaulting to main service, if stsService boolean is undefined for any service */ -}}
  {{- if and (eq "" $stsServiceName) (.Values.service).main (eq "None" (.Values.service.main).clusterIP) -}}
    {{- $stsServiceName = (.Values.service.main).name | default "main" -}}
  {{- end -}}
  {{- if ne "" $stsServiceName -}}
    {{- include "common.helpers.names.serviceName" ( list $ $stsServiceName) -}}
  {{- else if ((.Values.service.main).createHeadless | default true) -}}
    {{- include "common.helpers.names.serviceName" ( list $ "headless" false) -}}
  {{- end -}}
{{- end }}

{{/* Returns service name, headless if enabled */}}
{{- define "common.helpers.names.stsServiceFQDN" -}}
  {{- $stsServiceName := include "common.helpers.names.stsServiceName" . -}}
  {{- $stsServiceName -}}.{{- .Release.Namespace -}}.svc.{{- include "common.helpers.names.clusterDomain" . -}}
{{- end }}

{{/* Returns pod FQDNs as list
usage: {{ include "common.helpers.names.podFQDNs" (list $ "[chartName]" "[serviceName (defaults to main)]") }}
*/}}
{{- define "common.helpers.names.podFQDNs" -}}
  {{- $ctx := index . 0 -}}
  {{- $chart := index . 1 -}}
  {{- $svc := "main" -}}
  {{- if ge (len .) 3 -}}
    {{- $svc = index . 2 | default "main" -}}
  {{- end -}}
  {{- $serviceName := include "common.helpers.names.serviceName" (list $ctx $svc false $chart) -}}
  {{- $svcFqdn := printf "%s.%s.svc.%s." $serviceName $ctx.Release.Namespace (include "common.helpers.names.clusterDomain" $ctx) -}}
  {{- $pods := list -}}
  {{- range $podName := (include "common.helpers.names.podNames" (list $ctx $chart) | fromYamlArray) -}}
    {{- $pods = append $pods (printf "%s.%s" $podName $svcFqdn) -}}
  {{- end -}}
  {{- $pods | toYaml -}}
{{- end }}

{{/* Returns pod FQDN
usage: {{ include "common.helpers.names.podFQDN" (list $ "[chartName]" "[podNameSuffix]" "[serviceName (defaults to main)]") }}
*/}}
{{- define "common.helpers.names.podFQDN" -}}
  {{- $ctx := index . 0 -}}
  {{- $chart := index . 1 -}}
  {{- $podNameSuffix := index . 2 -}}
  {{- $svc := "main" -}}
  {{- if ge (len .) 4 -}}
    {{- $svc = index . 3 | default "main" -}}
  {{- end -}}
  {{- $serviceName := include "common.helpers.names.serviceName" (list $ctx $svc false $chart) -}}
  {{- $svcFqdn := printf "%s.%s.svc.%s." $serviceName $ctx.Release.Namespace (include "common.helpers.names.clusterDomain" $ctx) -}}
  {{- $fullName := include "common.helpers.names.chartFullname" (list $ctx $chart) -}}

  {{- printf "%s-%s.%s" $fullName ($podNameSuffix | toString) $svcFqdn -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.helpers.names.clusterDomain" -}}
  {{- default "cluster.local" (.Values.cluster).domain -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.

usage: {{ include "common.helpers.names.serviceDNSNames" ( list $ [name of service]) }}
*/}}
{{- define "common.helpers.names.serviceDNSNames" -}}
  {{- $root := index . 0 -}}
  {{- $serviceName := index . 1 -}}
  {{- $namespace := $root.Release.Namespace -}}
  {{- $clusterDomain := include "common.helpers.names.clusterDomain" $root -}}
  [{{ $serviceName -}}, {{ printf "%s.%s" $serviceName $namespace -}}, {{ printf "%s.%s.svc" $serviceName $namespace -}}, {{ printf "%s.%s.svc.%s" $serviceName $namespace $clusterDomain -}}]
{{- end }}

{{/*
Create chart name and version as used by the chart label.

usage: {{ include "common.helpers.names.serviceFQDN" ( list $ [name of service] [chart] [validate]) }}
*/}}
{{- define "common.helpers.names.serviceFQDN" -}}
  {{- $root := index . 0 -}}
  {{- $serviceName := index . 1 -}}
  {{- $chart := include "common.helpers.variables.getField" (list $root.Chart "Name") -}}
  {{- if ge (len .) 3 -}}
    {{- $chart = index . 2 -}}
  {{- end -}}
  {{- $validate := false -}}
  {{- if ge (len .) 4 -}}
    {{- $validate = index . 3 -}}
  {{- end -}}
  {{- $serviceName = include "common.helpers.names.serviceName" (list $root $serviceName $validate $chart) -}}
  {{- $namespace := $root.Release.Namespace -}}
  {{- $clusterDomain := include "common.helpers.names.clusterDomain" $root -}}
  {{- printf "%s.%s.svc.%s" $serviceName $namespace $clusterDomain -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.

usage: {{ include "common.helpers.names.chartServiceDNSNames" ( list $ [name of service] [validate (true/false)]) }}
*/}}
{{- define "common.helpers.names.chartServiceDNSNames" -}}
  {{- $root := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $validate := true -}}
  {{- if ge (len .) 3 -}}
    {{- $validate = index . 2 -}}
  {{- end -}}
  {{- $serviceName := include "common.helpers.names.serviceName" (list $root $name $validate) -}}
  {{- include "common.helpers.names.serviceDNSNames" (list $root $serviceName) -}}
{{- end }}

{{/*
common.helpers.names.podNames

Generates StatefulSet pod names like ["myapp-0", "myapp-1", ...]

Arguments:
  - . (Helm context)
  - chartName (optional): key under .Values.global[chartName]; falls back to .Chart.Name if not provided

Priority:
  1. .Values.global[chartName].cluster.ordinals.start and replicaCount
  2. .Values.cluster.ordinals.start and replicaCount
  3. .Values.ordinals.start and replicaCount

Usage:
  {{ include "common.helpers.names.podNames" (list . "patroni") | fromYamlArray }}
  {{ include "common.helpers.names.podNames" (list . "") | fromYamlArray }}
  {{ include "common.helpers.names.podNames" (list .) | fromYamlArray }}
*/}}
{{- define "common.helpers.names.podNames" -}}
  {{- $ctx := index . 0 -}}

  {{- $chart := "" -}}
  {{- if ge (len .) 2 -}}
    {{- $chart = index . 1 | default "" -}}
  {{- end -}}
  {{- if eq $chart "" -}}
    {{- $chart = include "common.helpers.variables.getField" (list $ctx.Chart "Name") -}}
  {{- end -}}

  {{- $fullName := include "common.helpers.names.chartFullname" (list $ctx $chart) -}}

  {{- /* Collect candidates from all sources */ -}}
  {{- $gord := dict -}}
  {{- $gcluster := dict -}}
  {{- if hasKey $ctx.Values "global" -}}
    {{- $gvals := (get $ctx.Values.global $chart | default dict) -}}
    {{- $gcluster = get $gvals "cluster" | default dict -}}
    {{- $gord = get $gcluster "ordinals" | default dict -}}
  {{- end -}}

  {{- $ccluster := get $ctx.Values "cluster" | default dict -}}
  {{- $cord := get $ccluster "ordinals" | default dict -}}

  {{- $directOrd := get $ctx.Values "ordinals" | default dict -}}

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
  {{- else if hasKey $ctx.Values "replicaCount" -}}
    {{- $replicaCount = int (index $ctx.Values "replicaCount") -}}
  {{- end -}}

  {{- $untilEnd := add (int $ordinalStart) (int $replicaCount) -}}
  {{- $podNames := list -}}
  {{- range $i := untilStep $ordinalStart (int $untilEnd) 1 -}}
    {{- $podNames = append $podNames (printf "%s-%d" $fullName $i) -}}
  {{- end -}}

  {{- $podNames | toYaml -}}
{{- end }}

{{- define "common.helpers.names.DNSNames" -}}
  {{- $isStatefulSet := eq "StatefulSet" (include "common.helpers.names.workloadType" .) -}}
  {{- $services := .Values.service -}}
  {{- $podNames := list -}}
  {{- $dnsNames := list -}}
  {{- if $isStatefulSet -}}
    {{- $podNames = (include "common.helpers.names.podNames" (list $)) | fromYamlArray -}}
    {{- $dnsNames = concat $dnsNames $podNames -}}
  {{- end -}}
  {{- range $name, $service := $services -}}
    {{- $svcName := $service.name | default $name -}}
    {{- $isHeadlessSvc := eq "None" ($service.clusterIP) -}}
    {{- $podDNS := list -}}
    {{- $serviceDNS := (include "common.helpers.names.chartServiceDNSNames" (list $ $svcName)) | fromYamlArray -}}
    {{- if and (eq "main" $svcName) $isStatefulSet (not $isHeadlessSvc) (ne false ($service.createHeadless)) -}}
      {{- $headlessNames := (include "common.helpers.names.chartServiceDNSNames" (list $ "headless" false)) | fromYamlArray -}}
      {{- $podDNS = concat $podDNS $headlessNames -}}
      {{- $dnsNames = concat $dnsNames $headlessNames -}}
    {{- else if $isHeadlessSvc -}}
      {{- $podDNS = concat $podDNS $serviceDNS -}}
    {{- end -}}
    {{- $dnsNames = concat $dnsNames $serviceDNS -}}
    {{- range $pod := $podNames -}}
      {{- range $serviceDN := $podDNS -}}
        {{- $dnsNames = append $dnsNames (printf "%s.%s" $pod $serviceDN) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $dnsNames | toYaml -}}
{{- end }}

{{/* Return the workload type, defaults to "Deployment" */}}
{{- define "common.helpers.names.workloadType" -}}
  {{- if .Values.workloadType -}}
    {{- if eq (lower .Values.workloadType) "deployment" -}}
      {{- print "Deployment" -}}
    {{- else if eq (lower .Values.workloadType) "statefulset"  -}}
      {{- print "StatefulSet" -}}
    {{- else if eq (lower .Values.workloadType) "daemonset"  -}}
      {{- print "DaemonSet" -}}
    {{- else -}}
      {{- fail (printf "Not a valid workloadType (%s)" .Values.workloadType) -}}
    {{- end -}}
  {{- else -}}
    {{- print "Deployment" -}}
  {{- end -}}
{{- end -}}

{{/*
Return service name
* first param is root, required
* second param is the name of service, returns modified value if chart has service with same name

usage: {{ include "common.helpers.names.serviceName" ( list $ [name of service] [validate (true/false)] [chart name]) }}
*/}}
{{- define "common.helpers.names.serviceName" -}}
  {{- $root := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $ignoreServiceExists := false -}}
  {{- if ge (len .) 3 -}}
    {{- if eq false (index . 2) -}}
      {{- $ignoreServiceExists = true -}}
    {{- end -}}
  {{- end -}}
  {{- $chartName := include "common.helpers.variables.getField" (list $root.Chart "Name") -}}
  {{- if ge (len .) 4 -}}
    {{- $chartName = index . 3 -}}
  {{- end -}}
  {{- $fullName := include "common.helpers.names.chartFullname" (list $root $chartName) -}}
  {{- $names := list -}}
  {{- if eq (include "common.helpers.variables.getField" (list $root.Chart "Name")) $chartName -}}
    {{- range $name, $service := $root.Values.service -}}
      {{- if and (kindIs "map" $service) (gt (len $service) 0) -}}
        {{- $names = append $names ($service.name | default $name) -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- $ignoreServiceExists = true -}}
  {{- end -}}
  {{- if or (has $name $names) $ignoreServiceExists -}}
    {{- $serviceName := printf "%s-%s" $fullName $name -}}
    {{- if eq "main" $name -}}
      {{- $serviceName = $fullName -}}
    {{- end -}}
    {{- $serviceName -}}
  {{- else -}}
    {{- fail (printf "Service definition not found: '%s'" $name) -}}
  {{- end -}}
{{- end }}

{{/* 
Return configMap name
* first param is root, required
* second param is the name of configmap, returns modified value if chart has configmap with same name
* third param is boolean, if false returns second parameter unmodified

usage: {{ include "common.helpers.names.configMapName" ( list $ [name of configmap] [true|false]) }}
*/}}
{{- define "common.helpers.names.configMapName" -}}
  {{- $root := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $useConfigMapFromChart := index . 2 -}}
  {{- $fullName := include "common.helpers.names.fullname" $root -}}
  {{- $names := list -}}
  {{- if $useConfigMapFromChart -}}
    {{- range $name, $configMap := $root.Values.configMaps -}}
      {{- $names = append $names ($configMap.name | default $name) -}}
    {{- end -}}
    {{- if has $name $names -}}
      {{- $name = printf "%s-%s" $fullName $name -}}
    {{- end -}}
  {{- end -}}
  {{- $name -}}
{{- end }}

{{/* 
Return secret name
* first param is root, required
* second param is the name of secret, returns modified value if chart has secret with same name
* third param is boolean, if false returns second parameter unmodified

usage: {{ include "common.helpers.names.secretName" ( list $ [name of secret] [true|false]) }}
*/}}
{{- define "common.helpers.names.secretName" -}}
  {{- $root := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $useSecretFromChart := index . 2 -}}
  {{- $fullName := include "common.helpers.names.fullname" $root -}}
  {{- $names := list -}}
  {{- if $useSecretFromChart -}}
    {{- range $name, $secret := $root.Values.secrets -}}
      {{- $names = append $names ($secret.name | default $name) -}}
    {{- end -}}
    {{- if has $name $names -}}
      {{- $name = printf "%s-%s" $fullName $name -}}
    {{- end -}}
  {{- end -}}
  {{- $name -}}
{{- end }}

{{/* 
Return pvc name
* first param is root, required
* second param is the name of persistence object, returns modified value if third param isn't false
* third param is boolean, if false returns second parameter unmodified

usage: {{ include "common.helpers.names.persistentVolumeClaimName" ( list $ [name of pvc] [true|false]) }}
*/}}
{{- define "common.helpers.names.persistentVolumeClaimName" -}}
  {{- $root := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $useFromChart := index . 2 -}}
  {{- if $useFromChart -}}
    {{- $fullName := include "common.helpers.names.fullname" $root -}}
    {{- $name = printf "%s-%s" $name $fullName -}}
  {{- end -}}
  {{- $name -}}
{{- end }}