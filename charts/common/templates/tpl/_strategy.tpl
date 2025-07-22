{{/*
Return workload deployment strategy/updateStrategy
* first param is root, required
* second param is the workload type
usage: {{ include "common.tpl.strategy" ( list $ [workloadType]) }}
*/}}
{{- define "common.tpl.strategy" -}}
  {{- $root := index . 0 -}}
  {{- $workloadType := index . 1 -}}
  {{- $hasReadWriteOncePodVolumeClaims := false -}}
  {{- $isHostNetwork := ($root.Values).hostNetwork | default false -}}
  {{- if (include "common.helpers.persistence.hasReadWriteOncePodVolumeClaims" $root) -}}
    {{- $hasReadWriteOncePodVolumeClaims = true -}}
  {{- end -}}
  {{- if ne "Deployment" $workloadType -}}
    {{- include "common.tpl.strategy.updateStrategy" $root -}}
  {{- else }}
strategy:
    {{- include "common.tpl.strategy.spec" (list $root.Values.strategy $workloadType $hasReadWriteOncePodVolumeClaims $isHostNetwork) | nindent 2 }}
  {{- end -}}
{{- end }}

{{- define "common.tpl.strategy.updateStrategy" -}}
  {{- $workloadType := include "common.helpers.names.workloadType" . -}}
  {{- $updateStrategySpec := (hasKey .Values "updateStrategy") | ternary .Values.updateStrategy .Values.strategy }}
updateStrategy:
    {{- include "common.tpl.strategy.spec" (list $updateStrategySpec $workloadType false false) | nindent 2 }}
{{- end }}

{{/* 
Render deploymentStrategy / updateStrategy
* first param is strategySpec
* second param is the workloadType
* third param is boolean, does the workload contain persistentVolumeClaims

usage: {{ include "common.tpl.strategy.spec" ( list .Values.path.to.strategy/updateStrategy [workloadType] [true/false]) }}
*/}}
{{- define "common.tpl.strategy.spec" -}}
  {{- $spec := index . 0 | default dict -}}
  {{- $workloadType := index . 1 -}}
  {{- $hasReadWriteOncePodVolumeClaims := index . 2 -}}
  {{- $isHostNetwork := index . 3 -}}
  {{- $forceType := ($spec).forceType | default false -}}
  {{- $spec = omit $spec "forceType" -}}
  {{- /* set default spec.type if not defined */ -}}
  {{- if not ($spec).type -}}
    {{- $spec = merge $spec (dict "type" (ternary "Recreate" "RollingUpdate" (and (eq "Deployment" $workloadType) (or $hasReadWriteOncePodVolumeClaims $isHostNetwork)))) -}}
  {{- else if not $forceType -}}
    {{- if eq "Deployment" $workloadType -}}
      {{- if and $hasReadWriteOncePodVolumeClaims (ne "Recreate" $spec.type) -}}
        {{- fail "Recreate is recommended strategy for Deployments with persistent volumes having ReadWriteOncePod accessMode. You can override this warning by setting .Values.strategy.forceType to true" -}}
      {{- else if and $isHostNetwork (ne "Recreate" $spec.type) -}}
        {{- /* this is more likely of an issue having single replica and assigning the pod to the same node as previously it existed */ -}}
        {{- fail "Recreate is recommended strategy for Deployments using hostNetwork. You can override this warning by setting .Values.strategy.forceType to true" -}}
      {{- else if and (ne "RollingUpdate" $spec.type) (ne "Recreate" $spec.type) -}}
        {{- fail (printf "Unknown strategy type for %s (%s). You can override this warning by setting .Values.strategy.forceType to true" $workloadType $spec.type) -}}
      {{- end -}}
    {{- else if and (ne "RollingUpdate" $spec.type) (ne "OnDelete" $spec.type) -}}
      {{- fail (printf "Unknown strategy type for %s (%s). You can override this warning by setting .Values.strategy.forceType to true" $workloadType $spec.type) -}}
    {{- end -}}
  {{- end -}}
  {{- toYaml $spec -}}
{{- end }}
