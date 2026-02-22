{{- define "seaweedfs-csi-driver.controllerValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}
  
  {{- $controllerValues := include "common.helpers.componentValues" (list $ctx "controller" (list "controller" "node" "mount" "nodeGc")) | fromYaml -}}
  {{- $chartName := printf "%s-controller" ($controllerValues.Chart.Name | default $controllerValues.Chart.name) -}}
  {{- $_ := set $controllerValues.Chart "name" $chartName -}}
  {{- $_ := set $controllerValues.Chart "Name" $chartName -}}
  
  {{- /* Populate container images from csi values and set enabled flag */ -}}
  {{- $containers := $controllerValues.Values.containers | default dict -}}
  
  {{- /* csi-provisioner */ -}}
  {{- if hasKey $containers "csi-provisioner" -}}
    {{- $provisioner := get $containers "csi-provisioner" -}}
    {{- if hasKey $ctx.Values.csi.provisioner "enabled" -}}
      {{- $_ := set $provisioner "enabled" $ctx.Values.csi.provisioner.enabled -}}
    {{- else -}}
      {{- $_ := set $provisioner "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $provisioner "image") -}}
      {{- $_ := set $provisioner "image" dict -}}
    {{- end -}}
    {{- $_ := set $provisioner.image "repository" $ctx.Values.csi.provisioner.image.repository -}}
    {{- $_ := set $provisioner.image "tag" $ctx.Values.csi.provisioner.image.tag -}}
    {{- $_ := set $provisioner.image "pullPolicy" $ctx.Values.csi.provisioner.image.pullPolicy -}}
  {{- end -}}
  
  {{- /* csi-resizer */ -}}
  {{- if hasKey $containers "csi-resizer" -}}
    {{- $resizer := get $containers "csi-resizer" -}}
    {{- if hasKey $ctx.Values.csi.resizer "enabled" -}}
      {{- $_ := set $resizer "enabled" $ctx.Values.csi.resizer.enabled -}}
    {{- else -}}
      {{- $_ := set $resizer "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $resizer "image") -}}
      {{- $_ := set $resizer "image" dict -}}
    {{- end -}}
    {{- $_ := set $resizer.image "repository" $ctx.Values.csi.resizer.image.repository -}}
    {{- $_ := set $resizer.image "tag" $ctx.Values.csi.resizer.image.tag -}}
    {{- $_ := set $resizer.image "pullPolicy" $ctx.Values.csi.resizer.image.pullPolicy -}}
  {{- end -}}
  
  {{- /* csi-attacher */ -}}
  {{- if hasKey $containers "csi-attacher" -}}
    {{- $attacher := get $containers "csi-attacher" -}}
    {{- if hasKey $ctx.Values.csi.attacher "enabled" -}}
      {{- $_ := set $attacher "enabled" $ctx.Values.csi.attacher.enabled -}}
    {{- else -}}
      {{- $_ := set $attacher "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $attacher "image") -}}
      {{- $_ := set $attacher "image" dict -}}
    {{- end -}}
    {{- $_ := set $attacher.image "repository" $ctx.Values.csi.attacher.image.repository -}}
    {{- $_ := set $attacher.image "tag" $ctx.Values.csi.attacher.image.tag -}}
    {{- $_ := set $attacher.image "pullPolicy" $ctx.Values.csi.attacher.image.pullPolicy -}}
  {{- end -}}
  
  {{- /* csi-liveness-probe */ -}}
  {{- if hasKey $containers "csi-liveness-probe" -}}
    {{- $liveness := get $containers "csi-liveness-probe" -}}
    {{- if hasKey $ctx.Values.csi.livenessProbe "enabled" -}}
      {{- $_ := set $liveness "enabled" $ctx.Values.csi.livenessProbe.enabled -}}
    {{- else -}}
      {{- $_ := set $liveness "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $liveness "image") -}}
      {{- $_ := set $liveness "image" dict -}}
    {{- end -}}
    {{- $_ := set $liveness.image "repository" $ctx.Values.csi.livenessProbe.image.repository -}}
    {{- $_ := set $liveness.image "tag" $ctx.Values.csi.livenessProbe.image.tag -}}
    {{- $_ := set $liveness.image "pullPolicy" $ctx.Values.csi.livenessProbe.image.pullPolicy -}}
  {{- end -}}
  
  {{- $_ := set $controllerValues.Values "containers" $containers -}}
  
  {{- /* Add TLS environment variables if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- if not (hasKey $controllerValues.Values "env") -}}
      {{- $_ := set $controllerValues.Values "env" dict -}}
    {{- end -}}
    {{- $_ := set $controllerValues.Values.env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
    {{- $_ := set $controllerValues.Values.env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $controllerValues.Values.env "WEED_GRPC_CA" "/certs/ca.crt" -}}
  {{- end -}}

  {{- /* Add TLS volume and mounts if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- $fullName := include "common.helpers.names.fullname" $ctx -}}
    {{- /* Add tls volume to persistence */ -}}
    {{- if not (hasKey $controllerValues.Values "persistence") -}}
      {{- $_ := set $controllerValues.Values "persistence" dict -}}
    {{- end -}}
    {{- $tlsVolume := dict "enabled" true "mount" (list (dict "path" "/certs" "readOnly" true)) "spec" (dict "secret" (dict "secretName" $ctx.Values.tls.existingSecret) "useFromChart" false) -}}
    {{- $_ := set $controllerValues.Values.persistence "tls" $tlsVolume -}}
    
    {{- /* Add security.toml ConfigMap */ -}}
    {{- $sharedConfig := dict "enabled" true "mount" (list (dict "path" "/etc/seaweedfs/security.toml" "readOnly" true "subPath" "security.toml")) -}}
    {{- $_ := set $sharedConfig "spec" (dict "useFromChart" false "configMap" (dict "name" (printf "%s-%s" $fullName "shared-config") "optional" false)) -}}
    {{- $_ := set $controllerValues.Values.persistence "shared-config" $sharedConfig -}}
  {{- end -}}
  
  {{- $controllerValues | toYaml -}}
{{- end }}

{{- define "seaweedfs-csi-driver.nodeValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}
  
  {{- $nodeValues := include "common.helpers.componentValues" (list $ctx "node" (list "controller" "node" "mount" "nodeGc")) | fromYaml -}}
  {{- $chartName := printf "%s-node" ($nodeValues.Chart.Name | default $nodeValues.Chart.name) -}}
  {{- $_ := set $nodeValues.Chart "name" $chartName -}}
  {{- $_ := set $nodeValues.Chart "Name" $chartName -}}

  {{- /* Build args list */ -}}
  {{- $args := $nodeValues.Values.args | default list -}}
  
  {{- /* Add dataLocality if not "none" */ -}}
  {{- if and (hasKey $ctx.Values "seaweedfs") (ne ($ctx.Values.seaweedfs.dataLocality | default "none") "none") -}}
    {{- $args = append $args (printf "--dataLocality=%s" $ctx.Values.seaweedfs.dataLocality) -}}
  {{- end -}}

  {{- /* Add pod annotation, arg, and env for dataCenter if defined */ -}}
  {{- if and (hasKey $ctx.Values.seaweedfs "dataCenter") $ctx.Values.seaweedfs.dataCenter -}}
    {{- $args = append $args "--dataCenter=$(DATACENTER)" -}}
    
    {{- /* Add pod annotation */ -}}
    {{- if not (hasKey $nodeValues.Values "podAnnotations") -}}
      {{- $_ := set $nodeValues.Values "podAnnotations" dict -}}
    {{- end -}}
    {{- $_ := set $nodeValues.Values.podAnnotations "dataCenter" $ctx.Values.seaweedfs.dataCenter -}}
    
    {{- /* Add DATACENTER environment variable only if not already defined */ -}}
    {{- if not (hasKey $nodeValues.Values "env") -}}
      {{- $_ := set $nodeValues.Values "env" dict -}}
    {{- end -}}
    {{- if not (hasKey $nodeValues.Values.env "DATACENTER") -}}
      {{- $_ := set $nodeValues.Values.env "DATACENTER" (dict "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.annotations['dataCenter']"))) -}}
    {{- end -}}
  {{- end -}}
  
  
  {{- /* Add concurrentWriters if set */ -}}
  {{- if hasKey $nodeValues.Values "concurrentWriters" -}}
    {{- $args = append $args (printf "--concurrentWriters=%v" $nodeValues.Values.concurrentWriters) -}}
  {{- end -}}
  
  {{- /* Add cacheCapacityMB if set */ -}}
  {{- if hasKey $nodeValues.Values "cacheCapacityMB" -}}
    {{- $args = append $args (printf "--cacheCapacityMB=%v" $nodeValues.Values.cacheCapacityMB) -}}
  {{- end -}}

  {{- $_ := set $nodeValues.Values "args" $args -}}

  {{- /* Populate container images from csi values and set enabled flag */ -}}
  {{- $containers := $nodeValues.Values.containers | default dict -}}
  
  {{- /* driver-registrar */ -}}
  {{- if hasKey $containers "driver-registrar" -}}
    {{- $registrar := get $containers "driver-registrar" -}}
    {{- if hasKey $ctx.Values.csi.nodeDriverRegistrar "enabled" -}}
      {{- $_ := set $registrar "enabled" $ctx.Values.csi.nodeDriverRegistrar.enabled -}}
    {{- else -}}
      {{- $_ := set $registrar "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $registrar "image") -}}
      {{- $_ := set $registrar "image" dict -}}
    {{- end -}}
    {{- $_ := set $registrar.image "repository" $ctx.Values.csi.nodeDriverRegistrar.image.repository -}}
    {{- $_ := set $registrar.image "tag" $ctx.Values.csi.nodeDriverRegistrar.image.tag -}}
    {{- $_ := set $registrar.image "pullPolicy" $ctx.Values.csi.nodeDriverRegistrar.image.pullPolicy -}}
  {{- end -}}
  
  {{- /* csi-liveness-probe */ -}}
  {{- if hasKey $containers "csi-liveness-probe" -}}
    {{- $liveness := get $containers "csi-liveness-probe" -}}
    {{- if hasKey $ctx.Values.csi.livenessProbe "enabled" -}}
      {{- $_ := set $liveness "enabled" $ctx.Values.csi.livenessProbe.enabled -}}
    {{- else -}}
      {{- $_ := set $liveness "enabled" true -}}
    {{- end -}}
    {{- if not (hasKey $liveness "image") -}}
      {{- $_ := set $liveness "image" dict -}}
    {{- end -}}
    {{- $_ := set $liveness.image "repository" $ctx.Values.csi.livenessProbe.image.repository -}}
    {{- $_ := set $liveness.image "tag" $ctx.Values.csi.livenessProbe.image.tag -}}
    {{- $_ := set $liveness.image "pullPolicy" $ctx.Values.csi.livenessProbe.image.pullPolicy -}}
  {{- end -}}
  
  {{- $_ := set $nodeValues.Values "containers" $containers -}}

  {{- /* Add TLS environment variables if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- if not (hasKey $nodeValues.Values "env") -}}
      {{- $_ := set $nodeValues.Values "env" dict -}}
    {{- end -}}
    {{- $_ := set $nodeValues.Values.env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
    {{- $_ := set $nodeValues.Values.env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $nodeValues.Values.env "WEED_GRPC_CA" "/certs/ca.crt" -}}
  {{- end -}}

  {{- /* Add TLS volume and mounts if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- $fullName := include "common.helpers.names.fullname" $ctx -}}
    {{- /* Add tls volume to persistence */ -}}
    {{- if not (hasKey $nodeValues.Values "persistence") -}}
      {{- $_ := set $nodeValues.Values "persistence" dict -}}
    {{- end -}}
    {{- $tlsVolume := dict "enabled" true "mount" (list (dict "path" "/certs" "readOnly" true)) "spec" (dict "secret" (dict "secretName" $ctx.Values.tls.existingSecret) "useFromChart" false) -}}
    {{- $_ := set $nodeValues.Values.persistence "tls" $tlsVolume -}}
    
    {{- /* Add security.toml ConfigMap */ -}}
    {{- $sharedConfig := dict "enabled" true "mount" (list (dict "path" "/etc/seaweedfs/security.toml" "readOnly" true "subPath" "security.toml")) -}}
    {{- $_ := set $sharedConfig "spec" (dict "useFromChart" false "configMap" (dict "name" (printf "%s-%s" $fullName "shared-config") "optional" false)) -}}
    {{- $_ := set $nodeValues.Values.persistence "shared-config" $sharedConfig -}}
  {{- end -}}

  {{- $nodeValues | toYaml -}}
{{- end }}

{{- define "seaweedfs-csi-driver.mountValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}
  
  {{- $mountValues := include "common.helpers.componentValues" (list $ctx "mount" (list "controller" "node" "mount" "nodeGc")) | fromYaml -}}
  {{- $chartName := printf "%s-mount" ($mountValues.Chart.Name | default $mountValues.Chart.name) -}}
  {{- $_ := set $mountValues.Chart "name" $chartName -}}
  {{- $_ := set $mountValues.Chart "Name" $chartName -}}
  
  {{- /* Override image if mount-specific image is set */ -}}
  {{- if and (hasKey $mountValues.Values "image") (hasKey $mountValues.Values.image "repository") -}}
    {{- /* Image is already set from mount values, no need to override */ -}}
  {{- end -}}

  {{- /* csi-liveness-probe */ -}}
  {{- if hasKey $mountValues.Values.csi "mount" -}}
    {{- if hasKey $ctx.Values.csi.mount "enabled" -}}
      {{- $_ := set $mountValues.Values "enabled" $ctx.Values.csi.mount.enabled -}}
    {{- end -}}
    {{- if hasKey $ctx.Values.csi.mount "image" -}}
      {{- $_ := set $mountValues.Values.image "repository" $ctx.Values.csi.mount.image.repository -}}
      {{- $_ := set $mountValues.Values.image "tag" $ctx.Values.csi.mount.image.tag -}}
      {{- $_ := set $mountValues.Values.image "pullPolicy" $ctx.Values.csi.mount.image.pullPolicy -}}
    {{- end -}}

  {{- end -}}

  {{- /* Use node ServiceAccount for mount component */ -}}
  {{- $nodeServiceAccountName := printf "%s-node" (include "common.helpers.names.fullname" $ctx) -}}
  {{- if not (hasKey $mountValues.Values "serviceAccount") -}}
    {{- $_ := set $mountValues.Values "serviceAccount" dict -}}
  {{- end -}}
  {{- $_ := set $mountValues.Values.serviceAccount "create" false -}}
  {{- $_ := set $mountValues.Values.serviceAccount "name" $nodeServiceAccountName -}}
  
  {{- /* Add TLS environment variables if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- if not (hasKey $mountValues.Values "env") -}}
      {{- $_ := set $mountValues.Values "env" dict -}}
    {{- end -}}
    {{- $_ := set $mountValues.Values.env "WEED_GRPC_CLIENT_KEY" "/certs/tls.key" -}}
    {{- $_ := set $mountValues.Values.env "WEED_GRPC_CLIENT_CERT" "/certs/tls.crt" -}}
    {{- $_ := set $mountValues.Values.env "WEED_GRPC_CA" "/certs/ca.crt" -}}
  {{- end -}}

  {{- /* Add TLS volume and mounts if enabled */ -}}
  {{- if and $ctx.Values.tls.enabled $ctx.Values.tls.existingSecret (ne $ctx.Values.tls.existingSecret "") -}}
    {{- $fullName := include "common.helpers.names.fullname" $ctx -}}
    {{- /* Add tls volume to persistence */ -}}
    {{- if not (hasKey $mountValues.Values "persistence") -}}
      {{- $_ := set $mountValues.Values "persistence" dict -}}
    {{- end -}}
    {{- $tlsVolume := dict "enabled" true "mount" (list (dict "path" "/certs" "readOnly" true)) "spec" (dict "secret" (dict "secretName" $ctx.Values.tls.existingSecret) "useFromChart" false) -}}
    {{- $_ := set $mountValues.Values.persistence "tls" $tlsVolume -}}
    
    {{- /* Add security.toml ConfigMap */ -}}
    {{- $sharedConfig := dict "enabled" true "mount" (list (dict "path" "/etc/seaweedfs/security.toml" "readOnly" true "subPath" "security.toml")) -}}
    {{- $_ := set $sharedConfig "spec" (dict "useFromChart" false "configMap" (dict "name" (printf "%s-%s" $fullName "shared-config") "optional" false)) -}}
    {{- $_ := set $mountValues.Values.persistence "shared-config" $sharedConfig -}}
  {{- end -}}
  
  {{- $mountValues | toYaml -}}
{{- end }}

{{- define "seaweedfs-csi-driver.nodeGCValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- $_ := set $ctx.Values "configMaps" dict -}}
  {{- $_ := set $ctx.Values "secrets" dict -}}
  
  {{- $nodeGCValues := include "common.helpers.componentValues" (list $ctx "nodeGc" (list "controller" "node" "mount" "nodeGc")) | fromYaml -}}
  {{- $chartName := printf "%s-node-gc" ($nodeGCValues.Chart.Name | default $nodeGCValues.Chart.name) -}}
  {{- $_ := set $nodeGCValues.Chart "name" $chartName -}}
  {{- $_ := set $nodeGCValues.Chart "Name" $chartName -}}

  {{- /* Use node ServiceAccount for mount component */ -}}
  {{- $nodeGCServiceAccountName := printf "%s-node-gc" (include "common.helpers.names.fullname" $ctx) -}}
  {{- if not (hasKey $nodeGCValues.Values "serviceAccount") -}}
    {{- $_ := set $nodeGCValues.Values "serviceAccount" dict -}}
  {{- end -}}
  {{- $_ := set $nodeGCValues.Values.serviceAccount "create" true -}}
  {{- $_ := set $nodeGCValues.Values.serviceAccount "name" $nodeGCServiceAccountName -}}
  
  {{- $nodeGCValues | toYaml -}}
{{- end }}


{{- define "seaweedfs-csi-driver.storageClassParameters" -}}
  {{- $params := .Values.storageClass.parameters | default dict -}}
  {{- if ne "none" .Values.seaweedfs.dataLocality -}}
    {{- $_ := set $params "dataLocality" .Values.seaweedfs.dataLocality -}}
  {{- end -}}
  {{- with $params }}
parameters:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
{{- end }}
