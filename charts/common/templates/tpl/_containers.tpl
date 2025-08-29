{{- define "common.tpl.containers" -}}
  {{- $containers := merge (.Values.containers | default dict) (dict "main" dict) -}}
  {{- /* append sidecars into containers, if kubernetes version is less than 1.29.0 */ -}}
  {{- if semverCompare "<1.29-0" .Capabilities.KubeVersion.GitVersion -}}
    {{- range $name, $sidecar := .Values.sidecars -}}
      {{- $_ := (dict $name (merge $sidecar (dict "name" $name))) | merge $containers -}}
    {{- end -}}
  {{- end -}}
  {{- if not $containers.main.name -}}
    {{- $_ := set $containers.main "name" (include "common.helpers.names.container" .) -}}
  {{- end -}}
  {{- $mainImage := dict "repository" .Values.image.repository "tag" (.Values.image.tag | default .Chart.AppVersion) "pullPolicy" (.Values.image.pullPolicy | default "IfNotPresent") -}}
  {{- if .Values.image.digest -}}
    {{- $_ := set $mainImage "digest" .Values.image.digest -}}
  {{- end -}}
  {{- /* iterate trough keys in .Values to append into "main" container. There's no mapping for volumeDevices, might need to add that later */ -}}
  {{- range $_, $key := (list "probe" "args" "command" "env" "envFrom" "lifecycle" "resizePolicy" "resources" "restartPolicy" "securityContext" "stdin" "stdinOnce" "terminationMessagePath" "terminationMessagePolicy" "tty" "workingDir") -}}
    {{- if hasKey $.Values $key -}}
      {{- $_ := set $containers.main $key (get $.Values $key) -}}
    {{- end -}}
  {{- end -}}
  {{- $_ := set $containers.main "image" $mainImage -}}
  {{- range $containerName, $container := $containers -}}
    {{- if not (and (hasKey $container "enabled") (not $container.enabled)) -}}
      {{- $_ := set $container "name" ($container.name | default $containerName) -}}
      {{- include "common.tpl.container" (list $ $container (eq "main" $containerName)) | nindent 0 -}}
    {{- end -}}
{{- end -}}
{{- end }}

{{- define "common.tpl.container.args" }}
  {{- $root := index . 0 -}}
  {{- $args := index . 1 -}}
  {{- with $args -}}
args:
{{- tpl (toYaml .) $root | nindent 0 -}}
  {{- end -}}
{{- end }}

{{- define "common.tpl.container.command" }}
  {{- $root := index . 0 -}}
  {{- $command := index . 1 -}}
  {{- with $command -}}
command:
{{- tpl (toYaml .) $root | nindent 0 -}}
  {{- end -}}
{{- end }}

{{/*
usage: {{ include "common.tpl.container" (list $ [container spec] [bool: is main container] ) }}
*/}}
{{- define "common.tpl.container" -}}
  {{- $root := index . 0 -}}
  {{- $container := index . 1 -}}
  {{- $isMain := index . 2 -}}

  {{- /* fallback logic not to break previous sidecar implementations */ -}}
  {{- $image := $container.image -}}
  {{- $containerEnabled := true -}}
  {{- if hasKey $container "enabled" -}}
    {{- $containerEnabled = $container.enabled -}}
  {{- end -}}
  {{- $imagePullPolicy := $container.imagePullPolicy | default "IfNotPresent" -}}
  {{- if kindIs "map" $container.image -}}
    {{- $imagePullPolicy = ($container.image).pullPolicy | default "IfNotPresent"  -}}
    {{- $tag := $container.image.tag -}}
    {{- if $container.image.digest -}}
      {{- $digest := $container.image.digest -}}
      {{- /* if digest doesn't contain ':', prepend "sha256:" before digest value */ -}}
      {{- if not (contains ":" $digest) -}}
        {{- $digest = printf "sha256:%s" $digest -}}
      {{- end -}}
      {{- $tag = printf "%s@%s" $tag $digest -}}
    {{- end -}}
    {{- $image = printf "%s:%s" $container.image.repository $tag -}}
  {{- end -}}
  {{- if $containerEnabled -}}
- name: {{ $container.name }}
  {{- with $container.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  image: {{ toYaml $image }}
  imagePullPolicy: {{ toYaml $imagePullPolicy }}
  {{- if and $container.env (kindIs "map" $container.env) -}}
    {{- include "common.tpl.env" (list $root $container) | nindent 2 -}}
  {{- else -}}
    {{- with $container.env }}
  env:
    {{- toYaml . | nindent 2 -}}
    {{- end -}}
  {{- end -}}
  {{- if and $container.envFrom (kindIs "map" $container.envFrom) -}}
    {{- include "common.tpl.env.envFrom" (list $root $container) | nindent 2 -}}
  {{- else -}}
    {{- with $container.envFrom }}
  envFrom:
    {{- toYaml . | nindent 2 -}}
    {{- end -}}
  {{- end -}}
  {{- with $container.workingDir }}
  workingDir: {{ toYaml . }}
  {{- end }}
  {{- include "common.tpl.container.command" (list $root $container.command) | nindent 2 -}}
  {{- include "common.tpl.container.args" (list $root $container.args) | nindent 2 -}}
  {{- with $container.lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{- with $container.resizePolicy }}
  resizePolicy:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{- if $isMain -}}
    {{- include "common.tpl.volumeMounts" $root | nindent 2 -}}
  {{- else -}}
    {{- with $container.volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 2 -}}
    {{- end -}}
  {{- end -}}
  {{- if and $container.probe (kindIs "map" $container.probe) -}}
    {{- include "common.tpl.probes" $container | nindent 2 -}}
  {{- else -}}
    {{- with $container.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 -}}
    {{- end -}}
    {{- with $container.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 -}}
    {{- end -}}
    {{- with $container.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 -}}
    {{- end -}}
  {{- end }}
  {{- if $isMain -}}
    {{- include "common.tpl.ports.container" $root | nindent 2 }}
  {{- else -}}
    {{- with $container.ports }}
  ports:
    {{- toYaml . | nindent 2 }}
    {{- end }}
  {{- end }}
  {{- with $container.restartPolicy }}
  restartPolicy: {{ toYaml . }}
  {{- end }}
  {{- with $container.stdin }}
  stdin: {{ toYaml . }}
  {{- end }}
  {{- with $container.stdinOnce }}
  stdinOnce: {{ toYaml . }}
  {{- end }}
  {{- with $container.terminationMessagePath }}
  terminationMessagePath: {{ toYaml . }}
  {{- end }}
  {{- with $container.terminationMessagePolicy }}
  terminationMessagePolicy: {{ toYaml . }}
  {{- end }}
  {{- with $container.tty }}
  tty: {{ toYaml . }}
  {{- end }}
  {{- with $container.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "common.tpl.initContainers" }}
  {{- $initContainers := .Values.initContainers | default dict -}}

  {{- /* use native sidecar implementation if version is equal or above 1.29.0 */ -}}
  {{- if semverCompare ">=1.29-0" .Capabilities.KubeVersion.GitVersion -}}
    {{- range $name, $sidecar := .Values.sidecars -}}
      {{- $_ := set $sidecar "restartPolicy" "Always" -}}
      {{- $_ := (dict $name (merge $sidecar (dict "name" $name))) | merge $initContainers -}}
    {{- end -}}
  {{- end -}}

  {{- if $initContainers -}}
initContainers:
  {{- range $containerName, $initContainer := $initContainers -}}
    {{- $_ := set $initContainer "name" ($initContainer.name | default $containerName) }}
{{ include "common.tpl.container" (list $ $initContainer false) -}}
    {{- end -}}
  {{- end }}
{{- end }}


{{- define "common.tpl.ephemeralContainers" }}
  {{- $ephemeralContainers := .Values.ephemeralContainers | default dict -}}

  {{- if $ephemeralContainers -}}
ephemeralContainers:
  {{- range $containerName, $ephemeralContainer := $ephemeralContainers -}}
    {{- $_ := set $ephemeralContainer "name" ($ephemeralContainer.name | default $containerName) }}
{{ include "common.tpl.container" (list $ $ephemeralContainer false) -}}
    {{- end -}}
  {{- end }}
{{- end }}
