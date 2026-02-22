{{- define "seaweedfs.certificateValues" -}}
  {{- $root := . -}}
  {{- if and (.Values.tls).enabled (.Values.tls).generateCertificates (.Values.tls).issuerRef -}}
  {{- $dnsNames := list -}}
  {{- $components := list "master" "filer" "volume" -}}
  {{- range $component := $components -}}
    {{- $componentValues := include "common.helpers.componentValues" (list $root $component $components) | fromYaml -}}
    {{- $chartName := printf "%s-%s" $componentValues.Chart.Name $component -}}
    {{- $_ := set $componentValues.Chart "name" $chartName -}}
    {{- $_ := set $componentValues.Chart "Name" $chartName -}}
    {{- $componentDns := include "common.helpers.names.DNSNames" $componentValues | fromYamlArray -}}
    {{- $dnsNames = concat $dnsNames $componentDns -}}
  {{- end -}}
certificates:
  shared:
    dnsNames: 
    - localhost
    - 127.0.0.1
    {{- toYaml $dnsNames | nindent 4 }}
    issuerRef:
      {{- (.Values.tls).issuerRef | toYaml | nindent 6 }}
    usages:
    - digital signature
    - key encipherment
    - server auth
    - client auth
  {{ end -}}
{{- end }}

{{- define "seaweedfs.healthSidecar" -}}
  {{- $ctx := index . 0 -}}
  {{- $sourceProbeName := index . 1 -}}
  {{- $sourceProbe := get $ctx.Values.probe $sourceProbeName -}}
  {{- if $ctx.Values.tls.enabled -}}
probe:
  liveness:
    enabled: false
  readiness:
    enabled: false
  startup:
    enabled: false
containers:
  healthcheck:
    image:
      repository: curlimages/curl
      tag: latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        # Probe the endpoint with full mTLS
        # --cert + --key = client auth
        # --cacert = trust server cert
        # --insecure = skip hostname verification (localhost != cert CN, usually needed)
        curl -s -f --max-time 4 \
          --cert /certs/tls.crt \
          --key /certs/tls.key \
          --cacert /certs/ca.crt \
          --insecure \
          https://127.0.0.1:{{- $sourceProbe.httpGet.port -}}{{- $sourceProbe.httpGet.path }} > /dev/null

        if [ $? -eq 0 ]; then
          touch /tmp/health
        else
          rm -f /tmp/health 2>/dev/null
        fi

        sleep {{ $sourceProbe.periodSeconds | default "15" }}
      done
    volumeMounts:
    - name: shared-tls
      mountPath: /certs
      readOnly: true
    probe:
{{- if ($ctx.Values.probe).liveness }}
      liveness:
        {{- (toYaml (omit $ctx.Values.probe.liveness "httpGet")) | nindent 8 }}
        exec:
          command: ["sh", "-c", "test -f /tmp/health"]
{{- end }}
{{- if ($ctx.Values.probe).readiness }}
      readiness:
        {{- (toYaml (omit $ctx.Values.probe.readiness "httpGet")) | nindent 8 }}
        exec:
          command: ["sh", "-c", "test -f /tmp/health"]
{{- end }}
{{- if ($ctx.Values.probe).startup }}
      startup:
        {{- (toYaml (omit $ctx.Values.probe.startup "httpGet")) | nindent 8 }}
        exec:
          command: ["sh", "-c", "test -f /tmp/health"]
{{- end }}
{{- end }}
{{- end }}

{{- define "seaweedfs.tlsPersistence" -}}
  {{- $componentValues := index . 0 -}}
  {{- $fullName := index . 1 -}}
  {{- if ($componentValues.Values.tls).enabled -}}
    {{- $secretName := ($componentValues.Values.tls).existingSecret -}}
    {{- if ($componentValues.Values.tls).generateCertificates -}}
      {{- $secretName = dig "certificates" "shared" "secretName" "" $componentValues.Values | default (printf "%s-%s" $fullName "shared") -}}
    {{- end -}}
    {{- if $secretName -}}
shared-tls:
  enabled: true
  mount:
  - path: /certs
    readOnly: true
  spec:
    useFromChart: false
    secret:
      name: {{ $secretName }}
      optional: false
shared-config:
  enabled: true
  mount:
  - path: /etc/seaweedfs/security.toml
    readOnly: true
    subPath: security.toml
  spec:
    useFromChart: false
    configMap:
      name: {{ printf "%s-shared-config" $fullName }}
      optional: false
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "seaweedfs.masterServerList" -}}
  {{- $ctx := index . 0 -}}
  {{- $omitKeys := index . 1 -}}
  {{- $masterValues := include "common.helpers.componentValues" (list $ctx "master" $omitKeys) | fromYaml -}}
  {{- $_ := set $masterValues.Chart "name" (printf "%s-master" $ctx.Chart.Name) -}}
  {{- $_ := set $masterValues.Chart "Name" (printf "%s-master" $ctx.Chart.Name) -}}
  {{- $servers := list -}}
  {{- $serviceFQDN := include "common.helpers.names.stsServiceFQDN" $masterValues -}}
  {{- range $pod := (include "common.helpers.names.podNames" (list $masterValues)) | fromYamlArray -}}
    {{- $servers = append $servers (printf "%s.%s:9333" $pod $serviceFQDN) -}}
  {{- end -}}
  {{- toYaml $servers -}}
{{- end }}

{{- define "seaweedfs.masterValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := include "seaweedfs.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}

  {{- $masterValues := include "common.helpers.componentValues" (list $ctx "master" (list "master" "filer" "volume" "filerSync")) | fromYaml -}}
  {{- $chartName := printf "%s-master" $ctx.Chart.Name -}}
  {{- $_ := set $masterValues.Chart "name" $chartName -}}
  {{- $_ := set $masterValues.Chart "Name" $chartName -}}

  {{- $_ := (include "seaweedfs.healthSidecar" (list $masterValues "liveness")) | fromYaml | merge $masterValues.Values -}}

  {{- /* master pods */ -}}
  {{- $peers := include "seaweedfs.masterServerList" (list $ctx (list "master" "filer" "volume" "filerSync")) | fromYamlArray -}}

  {{- /* setting container args */ -}}
  {{- $args := $masterValues.Values.args | default list -}}
  {{- $args = concat $args (list "-port=9333" "-port.grpc=19333" (printf "-peers=%s" (join "," $peers)) (printf "-defaultReplication=%s" ($masterValues.Values.defaultReplication | toString))) -}}

  {{- /* certificate args and mount */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $masterValues $fullName) | fromYaml | merge $masterValues.Values.persistence -}}

  {{- $_ := set $masterValues.Values "args" (concat $args ($masterValues.Values.sharedArgs | default list)) -}}
  {{- $masterValues | toYaml -}}
{{- end }}

{{- define "seaweedfs.filerValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := include "seaweedfs.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}

  {{- $filerValues := include "common.helpers.componentValues" (list $ctx "filer" (list "master" "filer" "volume" "filerSync")) | fromYaml -}}
  {{- $chartName := printf "%s-filer" $ctx.Chart.Name -}}
  {{- $_ := set $filerValues.Chart "name" $chartName -}}
  {{- $_ := set $filerValues.Chart "Name" $chartName -}}

  {{- $_ := (include "seaweedfs.healthSidecar" (list $filerValues "liveness")) | fromYaml | merge $filerValues.Values -}}

  {{- /* master pods */ -}}
  {{- $masters := include "seaweedfs.masterServerList" (list $ctx (list "master" "filer" "volume" "filerSync")) | fromYamlArray -}}

  {{- /* setting container args */ -}}
  {{- $args := $filerValues.Values.args | default list -}}
  {{- $args = concat $args (list "-port.grpc=18888" "-s3" "-s3.port=8333" "-port.readonly=28888" (printf "-master=%s" (join "," $masters)) (printf "-defaultReplicaPlacement=%s" ($ctx.Values.defaultReplication | toString))) -}}
  {{- if $filerValues.Values.dataCenter -}}
    {{- $args = append $args (printf "-dataCenter=%s" $filerValues.Values.dataCenter) -}}
  {{- end -}}
  {{- if $filerValues.Values.rack -}}
    {{- $args = append $args (printf "-rack=%s" $filerValues.Values.rack) -}}
  {{- end -}}

  {{- /* certificate configuration and mount */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $filerValues $fullName) | fromYaml | merge $filerValues.Values.persistence -}}

  {{- $_ := set $filerValues.Values "args" (concat $args ($filerValues.Values.sharedArgs | default list)) -}}
  {{- $filerValues | toYaml -}}
{{- end }}

{{- define "seaweedfs.volumeValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := include "seaweedfs.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}

  {{- $volumeValues := include "common.helpers.componentValues" (list $ctx "volume" (list "master" "filer" "volume" "filerSync")) | fromYaml -}}
  {{- $chartName := printf "%s-volume" $ctx.Chart.Name -}}
  {{- $_ := set $volumeValues.Chart "name" $chartName -}}
  {{- $_ := set $volumeValues.Chart "Name" $chartName -}}

  {{- $_ := (include "seaweedfs.healthSidecar" (list $volumeValues "liveness")) | fromYaml | merge $volumeValues.Values -}}

  {{- /* master pods */ -}}
  {{- $masters := include "seaweedfs.masterServerList" (list $ctx (list "master" "filer" "volume" "filerSync")) | fromYamlArray -}}

  {{- /* setting container args */ -}}
  {{- $args := $volumeValues.Values.args | default list -}}
  {{- $args = concat $args (list "-port.grpc=18080" (printf "-mserver=%s" (join "," $masters))) -}}
  {{- if $volumeValues.Values.dataCenter -}}
    {{- $args = append $args (printf "-dataCenter=%s" $volumeValues.Values.dataCenter) -}}
  {{- end -}}
  {{- if $volumeValues.Values.rack -}}
    {{- $args = append $args (printf "-rack=%s" $volumeValues.Values.rack) -}}
  {{- end -}}

  {{- /* certificate args and mount */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $volumeValues $fullName) | fromYaml | merge $volumeValues.Values.persistence -}}

  {{- $_ := set $volumeValues.Values "args" (concat $args ($volumeValues.Values.sharedArgs | default list)) -}}
  {{- $volumeValues | toYaml -}}
{{- end }}

{{- define "seaweedfs.filerSyncValues" -}}
  {{- $ctx := index . 0 -}}
  {{- $instance := index . 1 -}}
  {{- $fullName := include "common.helpers.names.fullname" $ctx -}}

  {{- $_ := include "seaweedfs.certificateValues" $ctx | fromYaml | merge $ctx.Values -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}

  {{- $filerSyncBase := include "common.helpers.componentValues" (list $ctx "filerSync.__base__" (list "master" "filer" "volume" "filerSync")) | fromYaml -}}
  {{- $filerSyncInstanceValues := include "common.helpers.componentValues" (list $ctx (printf "filerSync.%s" $instance) (list "master" "filer" "volume" "filerSync")) | fromYaml -}}

  {{- $filerSyncValues := merge $filerSyncBase $filerSyncInstanceValues -}}
  {{- $instanceName := regexReplaceAll "[^a-z0-9-]+" (lower ($filerSyncValues.name | default $instance)) "-" -}}

  {{- if not (hasKey $filerSyncValues "workloadType") -}}
    {{- $_ := set $filerSyncValues "workloadType" "Deployment" -}}
  {{- end -}}
  {{- /* Set SOURCE_FILER env to filer lb service FQDN if not explicitly set */ -}}
  {{- $env := (omit $filerSyncValues.Values.env "SERVICE_FQDN" "POD_FQDN") | default dict -}}
  {{- if not (hasKey $env "SOURCE_FILER") -}}
    {{- $filerValues := include "common.helpers.componentValues" (list $ctx "filer" (list "master" "filer" "volume" "filerSync")) | fromYaml -}}
    {{- $_ := set $filerValues.Chart "Name" (printf "%s-filer" $ctx.Chart.Name) -}}
    {{- $filerLbFQDN := include "common.helpers.names.serviceFQDN" (list $filerValues "lb" "seaweedfs-filer" true) -}}
    {{- $_ := set $env "SOURCE_FILER" (printf "%s:8888" $filerLbFQDN) -}}
  {{- end -}}
  {{- $_ := set $filerSyncValues.Values "env" $env -}}

  {{- $chartName := printf "%s-filer-sync-%s" $filerSyncValues.Chart.Name $instanceName -}}
  {{- $_ := set $filerSyncValues.Chart "Name" $chartName -}}

  {{- /* setting container args */ -}}
  {{- $args := $filerSyncValues.Values.args | default list -}}
  {{- $args = concat (list "-a=$(SOURCE_FILER)" "-b=$(TARGET_FILER)") $args -}}


  {{- if $ctx.Values.tls.enabled -}}
    {{- $env := $filerSyncValues.Values.env | default dict -}}
    {{- $_ := set $env "WEED_GRPC_CA" "/certs/ca.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
    {{- $_ := set $filerSyncValues.Values "env" $env -}}
  {{- end -}}

  {{- /* certificate args and mount */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $filerSyncValues $fullName) | fromYaml | merge $filerSyncValues.Values.persistence -}}

  {{- $_ := set $filerSyncValues.Values "args" (uniq $args) -}}
  {{- $filerSyncValues | toYaml -}}
{{- end }}

{{- define "seaweedfs.filerSyncs" -}}
  {{- $ctx := deepCopy . -}}
  {{- range $key, $filerSync := .Values.filerSync -}}
    {{- $enabled := hasKey $filerSync "enabled" | ternary (index $filerSync "enabled") true -}}
    {{- if and (ne $key "__base__") $enabled -}}
      {{- $filerSyncValues := include "seaweedfs.filerSyncValues" (list $ctx $key) | fromYaml -}}
      {{ include "common.deployment" $filerSyncValues }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- define "seaweedfs.backupValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $fullName := include "common.helpers.names.fullname" $ctx -}}
  {{- $_ := include "seaweedfs.certificateValues" . | fromYaml | merge $ctx.Values -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}
  {{- $backupValues := include "common.helpers.componentValues" (list $ctx "resticBackup" (list "master" "filer" "volume" "resticBackup")) | fromYaml -}}

  {{- /* Set workload type to CronJob */ -}}
  {{- $_ := set $backupValues.Values "workloadType" "Deployment" -}}

  {{- /* Get filer and master service FQDNs */ -}}
  {{- $filerValues := include "common.helpers.componentValues" (list $ctx "filer" (list "master" "filer" "volume" "resticBackup")) | fromYaml -}}
  {{- $_ := set $filerValues.Chart "Name" (printf "%s-filer" $backupValues.Chart.Name) -}}
  {{- $filerLbFQDN := include "common.helpers.names.serviceFQDN" (list $filerValues "lb" "seaweedfs-filer" true) -}}

  {{- $masterValues := include "common.helpers.componentValues" (list $ctx "master" (list "master" "filer" "volume" "resticBackup")) | fromYaml -}}
  {{- $_ := set $masterValues.Chart "Name" (printf "%s-master" $backupValues.Chart.Name) -}}
  {{- $masterServiceFQDN := include "common.helpers.names.serviceFQDN" (list $masterValues "main" "seaweedfs-master" true) -}}

  {{- $chartName := printf "%s-backup" $backupValues.Chart.Name -}}
  {{- $_ := set $backupValues.Chart "Name" $chartName -}}

  {{- /* Set up environment variables */ -}}
  {{- $env := (omit $backupValues.Values.env "SERVICE_FQDN" "POD_FQDN") | default dict -}}

  {{- /* Add SEAWEEDFS_FILER if not already defined */ -}}
  {{- if not (hasKey $env "SEAWEEDFS_FILER") -}}
    {{- $_ := set $env "SEAWEEDFS_FILER" (printf "%s:8888" $filerLbFQDN) -}}
  {{- end -}}

  {{- /* Add SEAWEEDFS_MASTER if not already defined */ -}}
  {{- if not (hasKey $env "SEAWEEDFS_MASTER") -}}
    {{- $_ := set $env "SEAWEEDFS_MASTER" (printf "%s:9333" $masterServiceFQDN) -}}
  {{- end -}}

  {{- /* Add TLS env vars if TLS enabled */ -}}
  {{- if $ctx.Values.tls.enabled -}}
    {{- $_ := set $env "WEED_GRPC_CA" "/certs/ca.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
  {{- end -}}

  {{- $_ := set $backupValues.Values "env" $env -}}

  {{- /* Propagate main env to initContainers (do not overwrite explicit init container envs) */ -}}
  {{- if $backupValues.Values.initContainers -}}
    {{- $ics := $backupValues.Values.initContainers -}}
    {{- range $icName, $ic := $ics -}}
      {{- $_ := set $ic "env" (merge ($ic.env | default dict) $env) -}}
    {{- end -}}
    {{- /* Set seaweedfsBinary to use main image */ -}}
    {{- if $ics.seaweedfsBinary -}}
      {{- $seaweedfsImage := $ctx.Values.image | deepCopy -}}
      {{- if not $seaweedfsImage.tag -}}
        {{- $_ := set $seaweedfsImage "tag" $ctx.Chart.AppVersion -}}
      {{- end -}}
      {{- $_ := set $ics.seaweedfsBinary "image" $seaweedfsImage -}}
    {{- end -}}
  {{- end -}}

  {{- /* Add TLS certificate volume and config if enabled */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $backupValues $fullName) | fromYaml | merge $backupValues.Values.persistence -}}

  {{- $backupValues | toYaml -}}
{{- end }}

{{- define "seaweedfs.postUpValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $fullName := include "common.helpers.names.fullname" $ctx -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}

  {{- $omitKeys := list "master" "filer" "volume" "filerSync" "resticBackup" "postUp" -}}
  {{- $postUpValues := include "common.helpers.componentValues" (list $ctx "postUp" $omitKeys) | fromYaml -}}

  {{- $_ := set $postUpValues.Values "workloadType" "Deployment" -}}
  {{- $chartName := printf "%s-post-up" $postUpValues.Chart.Name -}}
  {{- $_ := set $postUpValues.Chart "Name" $chartName -}}

  {{- /* Get master service FQDN */ -}}
  {{- $masterValues := include "common.helpers.componentValues" (list $ctx "master" $omitKeys) | fromYaml -}}
  {{- $_ := set $masterValues.Chart "Name" (printf "%s-master" $ctx.Chart.Name) -}}
  {{- $masterServiceFQDN := include "common.helpers.names.serviceFQDN" (list $masterValues "main" "seaweedfs-master" true) -}}

  {{- /* Build COLLECTIONS env var from postUp.collections */ -}}
  {{- $collections := list -}}
  {{- range ($postUpValues.Values.collections | default list) -}}
    {{- $collections = append $collections (printf "%s:%s" .name (.replication | default "")) -}}
  {{- end -}}

  {{- /* Set env vars */ -}}
  {{- $env := (omit $postUpValues.Values.env "SERVICE_FQDN" "POD_FQDN") | default dict -}}
  {{- $_ := set $env "SEAWEEDFS_MASTER" (printf "%s:9333" $masterServiceFQDN) -}}
  {{- $_ := set $env "COLLECTIONS" (join "\n" $collections) -}}

  {{- if $ctx.Values.tls.enabled -}}
    {{- $_ := set $env "WEED_GRPC_CA" "/certs/ca.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
  {{- end -}}

  {{- $_ := set $postUpValues.Values "env" $env -}}

  {{- /* Add TLS certificate volume and config if enabled */ -}}
  {{- $_ := include "seaweedfs.tlsPersistence" (list $postUpValues $fullName) | fromYaml | merge $postUpValues.Values.persistence -}}

  {{- $postUpValues | toYaml -}}
{{- end }}
