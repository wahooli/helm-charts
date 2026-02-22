{{- define "patroni.postgres_exporter_yaml" -}}
{{ .Files.Get "configs/0110-pg.yml" }}

{{ .Files.Get "configs/0120-pg_meta.yml" }}

{{ .Files.Get "configs/0130-pg_setting.yml" }}

{{ .Files.Get "configs/0210-pg_repl.yml" }}

{{ .Files.Get "configs/0220-pg_sync_standby.yml" }}

{{ .Files.Get "configs/0230-pg_downstream.yml" }}

{{ .Files.Get "configs/0240-pg_slot.yml" }}

{{ .Files.Get "configs/0250-pg_recv.yml" }}

{{ .Files.Get "configs/0260-pg_sub.yml" }}

{{ .Files.Get "configs/0270-pg_origin.yml" }}

{{ .Files.Get "configs/0300-pg_io.yml" }}

{{ .Files.Get "configs/0310-pg_size.yml" }}

{{ .Files.Get "configs/0320-pg_archiver.yml" }}

{{ .Files.Get "configs/0330-pg_bgwriter.yml" }}

{{ .Files.Get "configs/0331-pg_checkpointer.yml" }}

{{ .Files.Get "configs/0340-pg_ssl.yml" }}

{{ .Files.Get "configs/0350-pg_checkpoint.yml" }}

{{ .Files.Get "configs/0360-pg_recovery.yml" }}

{{ .Files.Get "configs/0370-pg_slru.yml" }}

{{ .Files.Get "configs/0380-pg_shmem.yml" }}

{{ .Files.Get "configs/0390-pg_wal.yml" }}

{{ .Files.Get "configs/0410-pg_activity.yml" }}

{{ .Files.Get "configs/0420-pg_wait.yml" }}

{{ .Files.Get "configs/0430-pg_backend.yml" }}

{{ .Files.Get "configs/0440-pg_xact.yml" }}

{{ .Files.Get "configs/0450-pg_lock.yml" }}

{{ .Files.Get "configs/0460-pg_query.yml" }}

{{ .Files.Get "configs/0510-pg_vacuuming.yml" }}

{{ .Files.Get "configs/0520-pg_indexing.yml" }}

{{ .Files.Get "configs/0530-pg_clustering.yml" }}

{{ .Files.Get "configs/0540-pg_backup.yml" }}

{{ .Files.Get "configs/0610-pg_db.yml" }}

{{ .Files.Get "configs/0620-pg_db_confl.yml" }}

{{ .Files.Get "configs/0640-pg_pubrel.yml" }}

{{ .Files.Get "configs/0650-pg_subrel.yml" }}

{{ .Files.Get "configs/0700-pg_table.yml" }}

{{ .Files.Get "configs/0710-pg_index.yml" }}

{{ .Files.Get "configs/0720-pg_func.yml" }}

{{ .Files.Get "configs/0730-pg_seq.yml" }}

{{ .Files.Get "configs/0740-pg_relkind.yml" }}

{{ .Files.Get "configs/0750-pg_defpart.yml" }}

{{ .Files.Get "configs/0810-pg_table_size.yml" }}

{{ .Files.Get "configs/0820-pg_table_bloat.yml" }}

{{ .Files.Get "configs/0830-pg_index_bloat.yml" }}
{{- end }}

{{- define "patroni.pgbouncer_exporter_yaml" -}}
{{ .Files.Get "configs/0910-pgbouncer_list.yml" }}

{{ .Files.Get "configs/0920-pgbouncer_database.yml" }}

{{ .Files.Get "configs/0930-pgbouncer_stat.yml" }}

{{ .Files.Get "configs/0940-pgbouncer_pool.yml" }}
{{- end }}

{{- define "patroni.replicationUsername" -}}
  {{- if hasKey (.Values).env "PATRONI_REPLICATION_USERNAME" -}}
    {{- .Values.env.PATRONI_REPLICATION_USERNAME -}}
  {{- else if hasKey (((.Values.patroni.config).postgresql).authentication).replication "username" -}}
    {{- .Values.patroni.config.postgresql.authentication.replication.username -}}
  {{- else -}}
    replicator
  {{- end -}}
{{- end }}

{{- define "patroni.scope" -}}
  {{- if hasKey (.Values).env "PATRONI_SCOPE" -}}
    {{- .Values.env.PATRONI_SCOPE -}}
  {{- else if hasKey (.Values.patroni).config "scope" -}}
    {{- .Values.patroni.config.scope -}}
  {{- else -}}
    {{- required ".Values.patroni.scope is required value!" .Values.patroni.scope -}}
  {{- end -}}
{{- end }}

{{- define "patroni.config" -}}
  {{- $config := dict -}}
  {{- if (.Values.patroni).config -}}
    {{- $config = deepCopy .Values.patroni.config -}}
    {{- if or (.Values.ssl).etcdClientCertSecret ((index .Values.persistence "etcd-tls").spec) -}}
      {{- $etcdKey := "" -}}
      {{- if hasKey $config "etcd" -}}
        {{- $etcdKey = "etcd" -}}
      {{- else if hasKey $config "etcd3" -}}
        {{- $etcdKey = "etcd3" -}}
      {{- end -}}
      {{- if ne "" $etcdKey -}}
        {{- $etcdConfig := get $config $etcdKey -}}
        {{- $_ := set $etcdConfig "cacert" "/home/postgres/certs/etcd/ca.crt" -}}
        {{- $_ := set $etcdConfig "cert" "/home/postgres/certs/etcd/tls.crt" -}}
        {{- $_ := set $etcdConfig "key" "/home/postgres/certs/etcd/tls.key" -}}
      {{- end -}}
    {{- end -}}
    {{- if (.Values.patroni).jsonLog | default false -}}
      {{- $logConfig := get $config "log" | default dict -}}
      {{- $_ := set $logConfig "type" "json" -}}
      {{- $_ := set $config "log" $logConfig -}}
    {{- end -}}
    {{- if and (not (hasKey (.Values).env "PATRONI_SCOPE")) (not (hasKey $config "scope")) -}}
      {{- $_ := set $config "scope" (required ".Values.patroni.scope is required value!" .Values.patroni.scope ) -}}
    {{- end -}}
    {{- $postgresqlConfig := get $config "postgresql" | default dict -}}
    {{- $postgresqlAuthConfig := get $postgresqlConfig "authentication" | default dict -}}

    {{- $superuserAuth := get $postgresqlAuthConfig "superuser" | default (dict "username" "postgres") -}}
    {{- if and (not (hasKey (.Values).env "PATRONI_SUPERUSER_PASSWORD")) (not (hasKey $superuserAuth "password")) -}}
      {{- $_ := set $superuserAuth "password" (required ".Values.patroni.superuserPassword is required value!" .Values.patroni.superuserPassword ) -}}
      {{- $_ := set $postgresqlAuthConfig "superuser" $superuserAuth -}}
    {{- end -}}

    {{- $replicationAuth := get $postgresqlAuthConfig "replication" | default (dict "username" "replicator") -}}
    {{- if and (not (hasKey (.Values).env "PATRONI_REPLICATION_PASSWORD")) (not (hasKey $replicationAuth "password")) -}}
      {{- $_ := set $replicationAuth "password" (required ".Values.patroni.replicationPassword is required value!" .Values.patroni.replicationPassword ) -}}
      {{- $_ := set $postgresqlAuthConfig "replication" $replicationAuth -}}
    {{- end -}}

    {{- $rewindAuth := get $postgresqlAuthConfig "rewind" | default (dict "username" "rewind_user") -}}
    {{- if and (not (hasKey (.Values).env "PATRONI_REWIND_PASSWORD")) (not (hasKey $rewindAuth "password")) -}}
      {{- $_ := set $rewindAuth "password" (required ".Values.patroni.rewindPassword is required value!" .Values.patroni.rewindPassword ) -}}
      {{- $_ := set $postgresqlAuthConfig "rewind" $rewindAuth -}}
    {{- end -}}
    {{- $_ := set $postgresqlConfig "authentication" $postgresqlAuthConfig -}}
    {{- $postgresqlConfig := get $config "postgresql" | default dict -}}
    {{- $postgresqlParametersConfig := get $postgresqlConfig "parameters" | default dict -}}
    {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (hasKey (.Values.patroni.config.bootstrap.dcs.postgresql) "parameters") -}}
      {{- $bootstrapConfig := get $config "bootstrap" -}}
      {{- $bootstrapDCSConfig := get $bootstrapConfig "dcs" -}}
      {{- $bootstrapPostgresqlConfig := get $bootstrapDCSConfig "postgresql" -}}
      {{- $bootstrapPostgresqlParameters := get $bootstrapPostgresqlConfig "parameters" -}}
      {{- $_ := set $bootstrapPostgresqlParameters "ssl" "on" -}}
      {{- $_ := set $bootstrapPostgresqlParameters "ssl_cert_file" "/home/postgres/certs/postgres/tls.crt" -}}
      {{- $_ := set $bootstrapPostgresqlParameters "ssl_key_file" "/home/postgres/certs/postgres/tls.key" -}}
      {{- $_ := set $bootstrapPostgresqlParameters "ssl_ca_file" "/home/postgres/certs/postgres/ca.crt" -}}

      {{- $_ := set $postgresqlParametersConfig "ssl" "on" -}}
      {{- $_ := set $postgresqlParametersConfig "ssl_cert_file" "/home/postgres/certs/postgres/tls.crt" -}}
      {{- $_ := set $postgresqlParametersConfig "ssl_key_file" "/home/postgres/certs/postgres/tls.key" -}}
      {{- $_ := set $postgresqlParametersConfig "ssl_ca_file" "/home/postgres/certs/postgres/ca.crt" -}}
    {{- end -}}
    {{- if (.Values.patroni).jsonLog | default false -}}
      {{- $_ := set $postgresqlParametersConfig "logging_collector" "on" -}}
      {{- $_ := set $postgresqlParametersConfig "log_destination" "jsonlog" -}}
      {{- $_ := set $postgresqlParametersConfig "log_directory" "pg_log" -}}
      {{- $_ := set $postgresqlParametersConfig "log_filename" "postgresql" -}}
      {{- $_ := set $postgresqlParametersConfig "log_rotation_age" 0 -}}
      {{- $_ := set $postgresqlParametersConfig "log_rotation_size" 0 -}}
      {{- $_ := set $postgresqlParametersConfig "log_rotation_size" 0 -}}
      {{- $_ := set $postgresqlParametersConfig "log_line_prefix" ($postgresqlParametersConfig.log_line_prefix | default "%m [%p] %q%u@%d ") -}}
    {{- end -}}
    {{- $pg_hba := get $postgresqlConfig "pg_hba" | default list -}}
    {{- $replicationUser := (include "patroni.replicationUsername" .) -}}
    {{- $sslEnabled := (.Values.ssl).enabled | default false -}}
    {{- range $ip := (.Values.patroni).allowReplicationFrom -}}
      {{- if $sslEnabled -}}
        {{- $pg_hba = append $pg_hba (printf "hostssl replication %s %s scram-sha-256" $replicationUser $ip) -}}
      {{- else -}}
        {{- $pg_hba = append $pg_hba (printf "host replication %s %s scram-sha-256" $replicationUser $ip) -}}
      {{- end -}}
    {{- end -}}
    {{- if (.Values.postgresql.bootstrap.specialAccounts).enabled -}}
      {{- $allowList := list -}}
      {{- $allowList = append $allowList (printf "local pgbouncer_auth %s scram-sha-256" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer")) -}}
      {{- $allowList = append $allowList (printf "local all %s scram-sha-256" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter")) -}}
      {{- $allowList = append $allowList (printf "local all %s scram-sha-256" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter")) -}}
      {{- $pg_hba = concat $allowList $pg_hba -}}
      {{- $denyList := list -}}
      {{- $denyList = append $denyList (printf "host all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer")) -}}
      {{- $denyList = append $denyList (printf "host all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter")) -}}
      {{- $denyList = append $denyList (printf "host all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter")) -}}
      {{- $denyList = append $denyList (printf "hostssl all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer")) -}}
      {{- $denyList = append $denyList (printf "hostssl all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter")) -}}
      {{- $denyList = append $denyList (printf "hostssl all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter")) -}}
      {{- $pg_hba = concat $pg_hba $denyList -}}
    {{- end -}}
    {{- $allowLoginFromUsers := (.Values.patroni).allowLoginFromUsers | default (list "all") -}}
    {{- range $ip := (.Values.patroni).allowLoginFrom -}}
      {{- range $user := $allowLoginFromUsers -}}
        {{- if $sslEnabled -}}
          {{- $pg_hba = append $pg_hba (printf "hostssl all %s %s scram-sha-256" $user $ip) -}}
        {{- else -}}
          {{- $pg_hba = append $pg_hba (printf "host all %s %s scram-sha-256" $user $ip) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $_ := set $postgresqlConfig "pg_hba" $pg_hba -}}
    {{- $_ := set $postgresqlConfig "parameters" $postgresqlParametersConfig -}}
    {{- $_ := set $config "postgresql" $postgresqlConfig -}}
  {{- end -}}
  {{- toYaml $config -}}
{{- end }}

{{- define "patroni.pgbouncerHbaConf" -}}
  {{- $sslEnabled := (.Values.ssl).enabled | default false -}}
  {{- $pg_hba := list "" -}}
  {{- $pgBouncerUser := (.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer" -}}
  {{- $pgBouncerExporterUser := (.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter" -}}
  {{- range $ip := list "127.0.0.1/32" "::1/128" -}}
    {{- if $sslEnabled -}}
      {{- $pg_hba = append $pg_hba (printf "hostssl all %s %s scram-sha-256" $pgBouncerUser $ip) -}}
      {{- $pg_hba = append $pg_hba (printf "hostssl all %s %s scram-sha-256" $pgBouncerExporterUser $ip) -}}
    {{- else -}}
      {{- $pg_hba = append $pg_hba (printf "host all %s %s scram-sha-256" $pgBouncerUser $ip) -}}
      {{- $pg_hba = append $pg_hba (printf "host all %s %s scram-sha-256" $pgBouncerExporterUser $ip) -}}
    {{- end -}}
  {{- end -}}
  {{- $pg_hba = append $pg_hba (printf "host all %s 0.0.0.0/0 reject" $pgBouncerUser) -}}
  {{- $pg_hba = append $pg_hba (printf "host all %s 0.0.0.0/0 reject" $pgBouncerExporterUser) -}}
  {{- $pg_hba = append $pg_hba (printf "host all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter")) -}}
  {{- $pg_hba = append $pg_hba (printf "hostssl all %s 0.0.0.0/0 reject" $pgBouncerUser) -}}
  {{- $pg_hba = append $pg_hba (printf "hostssl all %s 0.0.0.0/0 reject" $pgBouncerExporterUser) -}}
  {{- $pg_hba = append $pg_hba (printf "hostssl all %s 0.0.0.0/0 reject" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter")) -}}
  {{- $allowLoginFromUsers := (.Values.patroni).allowLoginFromUsers | default (list "all") -}}
  {{- range $ip := (.Values.patroni).allowLoginFrom -}}
    {{- range $user := $allowLoginFromUsers -}}
      {{- if $sslEnabled -}}
        {{- $pg_hba = append $pg_hba (printf "hostssl all %s %s scram-sha-256" $user $ip) -}}
      {{- else -}}
        {{- $pg_hba = append $pg_hba (printf "host all %s %s scram-sha-256" $user $ip) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
# type database user address method
  {{- range $line := $pg_hba -}}
    {{- $line | nindent 0 }}
  {{- end -}}
{{- end }}

{{- define "patroni.serviceValues" -}}
  {{- $ctx := deepCopy . -}}
  {{- if and (or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled) (.Values.service).main -}}
    {{- $ports := ((.Values.service).main).ports | default list -}}
    {{- $ports = append $ports (dict "name" "pgbouncer" "port" ((.Values.pgbouncer).port | default 6432) "protocol" "TCP") -}}
    {{- $newPorts := dict "Values" (dict "service" (dict "main" (dict "ports" $ports ))) -}}
    {{- $_ := merge $newPorts $ctx -}}
    {{- $ctx = $newPorts -}}
  {{- end -}}
  {{- pick $ctx "Values" | toYaml -}}
{{- end }}

{{- define "pgbouncer.env" -}}
{{- $adminUsers := list -}}
{{- if ((.Values.pgbouncer).adminUser).username -}}
  {{- $adminUsers = append $adminUsers ((.Values.pgbouncer).adminUser).username -}}
{{- else -}}
  {{- $adminUsers = append $adminUsers "postgres" -}}
{{- end -}}
{{- if (.Values.metrics).enabled -}}
  {{- $adminUsers = append $adminUsers ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter") -}}
{{- end }}
env:
{{- if (.Values.postgresql.bootstrap.specialAccounts).enabled -}}
  {{- $dbUser := (.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer" -}}
  {{- $dbPass := (.Values.postgresql.bootstrap.specialAccounts.pgbouncer).password | default "pgbouncer_pass" }}
  DB_USER: {{ $dbUser }}
  DB_PASSWORD: {{ $dbPass }}
{{- end }}
{{- if not (.Values.pgbouncer.env).ADMIN_USERS }}
  ADMIN_USERS: {{ join "," $adminUsers }}
{{- end }}
  LISTEN_PORT: {{ ((.Values.pgbouncer).port | default 6432) | quote }}
{{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
  CLIENT_TLS_KEY_FILE: /certs/tls.key
  CLIENT_TLS_CERT_FILE: /certs/tls.crt
  CLIENT_TLS_CA_FILE: /certs/ca.crt
  CLIENT_TLS_SSLMODE: require
  SERVER_TLS_KEY_FILE: /certs/tls.key
  SERVER_TLS_CERT_FILE: /certs/tls.crt
  SERVER_TLS_CA_FILE: /certs/ca.crt
  SERVER_TLS_SSLMODE: verify-full
{{- end -}}
{{- range $env, $val := (.Values.pgbouncer).env }}
  {{- $env | nindent 2 }}: {{ $val }}
{{- end }}
{{- if (.Values.pgbouncer).envFrom }}
envFrom:
  {{- toYaml .Values.pgbouncer.envFrom | nindent 2 }}
{{- end }}
{{- end }}

{{- define "patroni.configMapValues" -}}

configMaps:
{{- if or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled }}
  pgbouncer-config:
    enabled: true
{{- end }}
{{- if (.Values.metrics).enabled }}
  pg-exporter:
    enabled: true
{{- end }}
  {{- if and (.Values.postgresql).bootstrap (or (or (.Values.postgresql.bootstrap).database (.Values.postgresql.bootstrap).username) (.Values.postgresql.bootstrap).extraSql) }}
  post-bootstrap:
    data:
    {{- if or (.Values.postgresql.bootstrap).database (.Values.postgresql.bootstrap).username }}
      02_helm_bootstrap.sql: | 
        {{- if and (.Values.postgresql.bootstrap).username (.Values.postgresql.bootstrap).password }}
        CREATE USER {{ .Values.postgresql.bootstrap.username }} WITH PASSWORD '{{ .Values.postgresql.bootstrap.password }}';
        {{- end }}
        {{- if and (.Values.postgresql.bootstrap).username (.Values.postgresql.bootstrap).database }}
        CREATE DATABASE {{ .Values.postgresql.bootstrap.database }} OWNER {{ .Values.postgresql.bootstrap.username }};
        GRANT ALL PRIVILEGES ON DATABASE {{ .Values.postgresql.bootstrap.database }} TO {{ .Values.postgresql.bootstrap.username }};
        {{- else if (.Values.postgresql.bootstrap).database }}
        CREATE DATABASE {{ .Values.postgresql.bootstrap.database }};
        {{- end }}
        {{- if (.Values.postgresql.bootstrap.specialAccounts).enabled }}
        REVOKE CREATE, TEMP ON DATABASE {{ .Values.postgresql.bootstrap.database }} FROM {{ (.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter" }};
        -- REVOKE CREATE, TEMP ON DATABASE {{ .Values.postgresql.bootstrap.database }} FROM {{ (.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter" }};
        REVOKE CREATE, TEMP ON DATABASE {{ .Values.postgresql.bootstrap.database }} FROM {{ (.Values.postgresql.bootstrap.specialAccounts.pgbouncer).username | default "pgbouncer" }};
        {{- end }}
    {{- end }}
    {{- with (.Values.postgresql.bootstrap).extraSql -}}
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "patroni.certificateValues" -}}
  {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef -}}
  {{- $dnsNames := include "common.helpers.names.DNSNames" . | fromYamlArray -}}
  {{- $clientDnsNames := $dnsNames -}}
  {{- if (.Values.haproxy).enabled -}}
    {{- $haproxySvcName := include "common.helpers.names.chartFullname" (list . "haproxy") -}}
    {{- $gwNames := (include "common.helpers.names.serviceDNSNames" (list $ $haproxySvcName false)) | fromYamlArray -}}
    {{- $clientDnsNames = concat $clientDnsNames $gwNames -}}
    {{- $clientDnsNames = append $clientDnsNames "localhost" -}}
  {{- end }}
certificates:
  server:
    dnsNames: 
    {{- toYaml $clientDnsNames | nindent 4 }}
    issuerRef:
      {{- (.Values.ssl).issuerRef | toYaml | nindent 6 }}
    ipAddresses:
    - 127.0.0.1
  {{ end -}}
{{- end }}

{{- define "patroni.stsValues" -}}
{{- $ctx := deepCopy . -}}
{{- $_ := include "patroni.certificateValues" . | fromYaml | merge $ctx.Values -}}
{{ include "patroni.workloadValues" $ctx }}
{{- end }}

{{- define "patroni.postgresLogContainer" -}}
{{- $image := .Values.image -}}
{{- if not $image.tag -}}
  {{- $_ := set $image "tag" .Chart.AppVersion -}}
{{- end -}}
{{- if not $image.pullPolicy -}}
  {{- $_ := set $image "pullPolicy" "IfNotPresent" -}}
{{- end -}}
postgres-log:
  enabled: true
  {{- with $image }}
  image:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  command: [ "/log-manager.sh" ]
  env:
    LOG_FORMAT: json
  {{- toYaml .Values.env | nindent 4 }}
  volumeMounts:
  - name: pgdata
    mountPath: /data-volume
{{- end }}

{{- define "patroni.workloadValues" -}}
  {{- $fullName := include "common.helpers.names.fullname" . -}}
{{- if or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled -}}
initContainers:
  copy-pgbouncer-config:
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    command:
    - sh
    - -c
    - cp -L /mnt/config-source/* /mnt/dest/ && chmod 666 /mnt/dest/*
    volumeMounts:
    - name: pgbouncer-configmap
      mountPath: /mnt/config-source
    - name: pgbouncer-config
      mountPath: /mnt/dest
{{- end }}
containers:
{{- if (.Values.patroni).jsonLog }}
  {{- include "patroni.postgresLogContainer" . | nindent 2 }}
{{- end }}
  {{- if or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled -}}
    {{- $volumeMounts := .Values.pgbouncer.volumeMounts | default list -}}
  {{- if and (.Values.ssl).enabled (.Values.ssl).generateCertificates (.Values.ssl).issuerRef -}}
    {{- $volumeMounts = append $volumeMounts (dict "name" "server-tls" "mountPath" "/certs" ) -}}
  {{- end }}
  pgbouncer:
    enabled: true
    image:
      repository: {{ ((.Values.pgbouncer).image).repository | default "edoburu/pgbouncer" }}
      pullPolicy: {{ ((.Values.pgbouncer).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.pgbouncer).image).tag | default "latest" }}
      {{- with ((.Values.pgbouncer).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
    {{- include "pgbouncer.env" . | nindent 4 }}
    ports:
    - containerPort: {{ (.Values.pgbouncer).port | default 6432 }}
      name: pgbouncer
      protocol: TCP
    probe:
    {{- toYaml .Values.pgbouncer.probe | nindent 6 }}
    {{- with $volumeMounts }}
    volumeMounts:
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with (.Values.pgbouncer).resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with (.Values.pgbouncer).securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end }}
{{- if (.Values.metrics).enabled }}
  postgres-exporter:
    enabled: true
    image:
      repository: {{ ((.Values.metrics).image).repository | default "pgsty/pg_exporter" }}
      pullPolicy: {{ ((.Values.metrics).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.metrics).image).tag | default "latest" }}
      {{- with ((.Values.metrics).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
{{- if (.Values.patroni).jsonLog -}}
  {{ $args := (index ((.Values).containers) "postgres-exporter" | default dict).args | default list -}}
  {{ $args = append $args "--log.format=json" }}
    args:
    {{- toYaml $args | nindent 4 }}
{{- end }}
    env:
{{- if not ((index ((.Values).containers) "postgres-exporter" | default dict).env).PG_EXPORTER_URL }}
      PG_EXPORTER_URL: {{ printf "postgres://%s:%s@:5432/postgres?host=/var/run/postgresql" ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).username | default "postgres_exporter") ((.Values.postgresql.bootstrap.specialAccounts.postgres_exporter).password | default "postgres_exporter_pass") }}
{{- end }}
  pgbouncer-exporter:
    enabled: true
    image:
      repository: {{ ((.Values.metrics).image).repository | default "pgsty/pg_exporter" }}
      pullPolicy: {{ ((.Values.metrics).image).pullPolicy | default "IfNotPresent" }}
      tag: {{ ((.Values.metrics).image).tag | default "latest" }}
      {{- with ((.Values.metrics).image).digest }}
      digest: {{ toYaml . }}
      {{- end }}
{{- if (.Values.patroni).jsonLog -}}
  {{ $args := (index ((.Values).containers) "pgbouncer-exporter" | default dict).args | default list -}}
  {{ $args = append $args "--log.format=json" }}
    args:
    {{- toYaml $args | nindent 4 }}
{{- end }}
    env:
{{- if not ((index ((.Values).containers) "pgbouncer-exporter" | default dict).env).PG_EXPORTER_URL -}}
  {{- if (.Values.ssl).enabled }}
      PG_EXPORTER_URL: {{ printf "postgres://%s:%s@127.0.0.1:6432/pgbouncer?sslmode=require" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter") ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).password | default "pgbouncer_exporter_pass") }}
  {{- else }}
      PG_EXPORTER_URL: {{ printf "postgres://%s:%s@127.0.0.1:6432/pgbouncer" ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).username | default "pgbouncer_exporter") ((.Values.postgresql.bootstrap.specialAccounts.pgbouncer_exporter).password | default "pgbouncer_exporter_pass") }}
  {{- end -}}
{{- end }}
{{- end }}
  {{- if (.Values.ssl).enabled }}
env:
    {{- if and (.Values.ssl).generateCertificates (.Values.ssl).issuerRef }}
  PGSSLROOTCERT: /home/postgres/certs/postgres/ca.crt
  PGSSLCERT: /home/postgres/certs/postgres/tls.crt
  PGSSLKEY: /home/postgres/certs/postgres/tls.key
  PGSSLMODE: require

  PATRONI_REWIND_SSLROOTCERT: $(PGSSLROOTCERT)
  PATRONI_REWIND_SSLCERT: $(PGSSLCERT)
  PATRONI_REWIND_SSLKEY: $(PGSSLKEY)
  PATRONI_REWIND_SSLMODE: require

  PATRONI_REPLICATION_SSLROOTCERT: $(PGSSLROOTCERT)
  PATRONI_REPLICATION_SSLCERT: $(PGSSLCERT)
  PATRONI_REPLICATION_SSLKEY: $(PGSSLKEY)
  PATRONI_REPLICATION_SSLMODE: require

  PATRONI_SUPERUSER_SSLROOTCERT: $(PGSSLROOTCERT)
  PATRONI_SUPERUSER_SSLCERT: $(PGSSLCERT)
  PATRONI_SUPERUSER_SSLKEY: $(PGSSLKEY)
  PATRONI_SUPERUSER_SSLMODE: require
{{- if (.Values.patroni).jsonLog | default false }}
  LOG_FORMAT: json
{{- end }}
{{- if or (.Values.global.patroni.pgbouncer).enabled (.Values.pgbouncer).enabled }}
  PATRONI_POSTGRESQL_PROXY_ADDRESS: $(POD_IP):{{ ((.Values.pgbouncer).port | default 6432) }}
{{ end }}

persistence:
{{- if or (.Values.global.patroni.pgbouncer).enabled (.Values.pgbouncer).enabled }}
  pgbouncer-config:
    enabled: true
  pgbouncer-configmap:
    enabled: true
    spec:
      useFromChart: true
      configMap:
        name: pgbouncer-config
        defaultMode: 0400
{{- end }}
{{- if (.Values.metrics).enabled }}
  exporter-config:
    enabled: true
{{- end }}
  config:
    enabled: true
    mount:
    - path: /home/postgres/config
    spec:
      useFromChart: true
      configMap:
        name: config
        defaultMode: 0400
{{ if and (.Values.postgresql).bootstrap (or (or (.Values.postgresql.bootstrap).database (.Values.postgresql.bootstrap).username) (.Values.postgresql.bootstrap).extraSql) }}
  post-bootstrap:
    enabled: true
    mount:
    - path: /docker-entrypoint-bootstrap.d
    spec:
      useFromChart: true
      configMap:
        name: post-bootstrap
        defaultMode: 0400
{{ end }}
{{ if (.Values.ssl).etcdClientCertSecret }}
  etcd-tls:
    enabled: true
    mount:
    - path: /home/postgres/certs/etcd
      readOnly: true
{{- if not (index .Values.persistence "etcd-tls").spec }}
    spec:
      useFromChart: false
      secret:
        name: {{ (.Values.ssl).etcdClientCertSecret }}
        optional: false
        defaultMode: 0400
{{- end }}
{{ end }}
  server-tls:
    enabled: true
    mount:
    - path: /home/postgres/certs/postgres
      readOnly: true
    spec:
      useFromChart: false
      secret:
        defaultMode: 0400
        name: {{ (.Values.certificates.server).secretName | default (printf "%s-%s" $fullName "server" ) }}
        optional: false
    {{ end -}}
  {{- else }}
env:
  {{- if (.Values.patroni).jsonLog | default false }}
  LOG_FORMAT: json
  {{- end }}
  PATRONI_SUPERUSER_SSLMODE: disable
  PATRONI_REPLICATION_SSLMODE: disable
  PATRONI_REWIND_SSLMODE: disable
  PGSSLMODE: disable
{{- if or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled }}
  PATRONI_POSTGRESQL_PROXY_ADDRESS: $(POD_IP):{{ ((.Values.pgbouncer).port | default 6432) }}
{{ end }}
persistence:
{{- if or (((.Values.global).patroni).pgbouncer).enabled (.Values.pgbouncer).enabled }}
  pgbouncer-config:
    enabled: true
{{- end }}
{{- if (.Values.metrics).enabled }}
  exporter-config:
    enabled: true
{{- end }}
  config:
    enabled: true
    mount:
    - path: /home/postgres/config
    spec:
      useFromChart: true
      configMap:
        name: config
        defaultMode: 0400
{{ if and (.Values.postgresql).bootstrap (or (or (.Values.postgresql.bootstrap).database (.Values.postgresql.bootstrap).username) (.Values.postgresql.bootstrap).extraSql) }}
  post-bootstrap:
    enabled: true
    mount:
    - path: /docker-entrypoint-bootstrap.d
    spec:
      useFromChart: true
      configMap:
        name: post-bootstrap
        defaultMode: 0400
{{ end }}
{{ if (.Values.ssl).etcdClientCertSecret }}
  etcd-tls:
    enabled: true
    mount:
    - path: /home/postgres/certs/etcd
      readOnly: true
    spec:
      useFromChart: false
      secret:
        name: {{ (.Values.ssl).etcdClientCertSecret }}
        optional: false
{{ end }}
  {{- end }}
{{ include "patroni.configMapValues" . }}
{{- end }}
