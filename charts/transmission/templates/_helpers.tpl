{{- define "transmission.wireguardConfigName" -}}
{{- if and (.Values.wireguard.config).existingSecret (.Values.wireguard.config).existingConfigMap -}}
  {{- fail ".Values.wireguard.config.existingSecret and existingConfigMap are mutually exclusive!" -}}
{{- else if or (.Values.wireguard.config).existingSecret (.Values.wireguard.config).existingConfigMap -}}
  {{- (.Values.wireguard.config).existingSecret | default (.Values.wireguard.config).existingConfigMap -}}
{{- else -}}
  {{- if and (not (.Values.wireguard.config).secretData) (not (.Values.wireguard.config).data) -}}
    {{- fail "Wireguard configuration not defined!" -}}
  {{- end -}}
  {{- include "common.helpers.names.fullname" . -}}-wireguard-config
{{- end -}}
{{- end }}

{{- define "transmission.wireguardConfigType" -}}
{{- if or (.Values.wireguard.config).existingSecret (.Values.wireguard.config).secretData -}}
  secret
{{- else -}}
  configMap
{{- end -}}
{{- end }}


{{- define "transmission.wireguardSidecar" -}}
sidecars:
  wireguard:
    image: "{{ (.Values.wireguard.image).repository | default "ghcr.io/linuxserver/wireguard" }}:{{ (.Values.wireguard.image).tag | default "latest" }}"
    imagePullPolicy: {{ (.Values.wireguard.image).pullPolicy | default "IfNotPresent" }}
    securityContext:
      sysctls:
      - name: net.ipv4.conf.all.src_valid_mark
        value: "1"
      privileged: true
      capabilities:
        add:
        - NET_ADMIN
      readOnlyRootFilesystem: false
    ports:
    - containerPort: {{ (.Values.wireguard).port | default 51820 }}
      name: wg
      protocol: UDP
    volumeMounts:
    - mountPath: {{ (.Values.wireguard.config).mountPath | default "/config/wg_confs/" }}
      name: {{ (.Values.wireguard.config).volumeName | default "wireguard-config" }}

persistence:
  {{ (.Values.wireguard.config).volumeName | default "wireguard-config" }}:
    enabled: true
    mount: []
    spec:
      {{ include "transmission.wireguardConfigType" . }}:
        name: {{ include "transmission.wireguardConfigName" . }}
        defaultMode: 0440
{{- end }}