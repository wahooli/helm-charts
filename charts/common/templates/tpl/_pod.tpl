{{- define "common.tpl.pod" }}
metadata:
  {{- include "common.helpers.annotations.podAnnotations" . | nindent 2 }}
  labels:
    {{- include "common.helpers.labels.podLabels" . | nindent 4 }}
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .Values.runtimeClassName }}
  runtimeClassName: {{ toYaml . }}
  {{- end }}
  {{- with .Values.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ toYaml . }}
  {{- end }}
  {{- with .Values.automountServiceAccountToken }}
  automountServiceAccountToken: {{ toYaml . }}
  {{- end }}
  {{- with .Values.enableServiceLinks }}
  enableServiceLinks: {{ toYaml . }}
  {{- end }}
  {{- with .Values.priorityClassName }}
  priorityClassName: {{ toYaml . }}
  {{- end }}
  {{- with (.Values.restartPolicy | default "Always") }}
  restartPolicy: {{ toYaml . }}
  {{- end }}
  serviceAccountName: {{ include "common.helpers.names.serviceAccount" . }}
  dnsPolicy: {{ .Values.dnsPolicy | default "ClusterFirst" }}
  dnsConfig:
    {{- toYaml (.Values.dnsConfig | default dict) | nindent 4 }}
  {{- with .Values.hostname }}
  hostname: {{ toYaml . }}
  {{- end }}
  {{- with .Values.hostIPC }}
  hostIPC: {{ toYaml . }}
  {{- end }}
  {{- with .Values.hostNetwork }}
  hostNetwork: {{ toYaml . }}
  {{- end }}
  {{- with .Values.hostPID }}
  hostPID: {{ toYaml . }}
  {{- end }}
  {{- with .Values.hostUsers }}
  hostUsers: {{ toYaml . }}
  {{- end }}
  {{- with .Values.subdomain }}
  subdomain: {{ toYaml . }}
  {{- end }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- include "common.tpl.initContainers" . | nindent 2 }}
  {{- include "common.tpl.ephemeralContainers" . | nindent 2 }}
  containers:
  {{- include "common.tpl.containers" .  | nindent 2 }}
  {{- with .Values.nodeName }}
  nodeName: {{ toYaml . }}
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.readinessGates }}
  readinessGates:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .Values.schedulingGates }}
  schedulingGates:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ toYaml . }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.topologySpreadConstraints }}
  topologySpreadConstraints:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- include "common.tpl.volumes" . | nindent 2 -}}
{{- end }}