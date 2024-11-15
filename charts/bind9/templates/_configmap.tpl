{{- define "bind9.entrypointOverride" -}}
{{- $forwardersPath := trimSuffix "/" (((.Values.bind9).forwarderGenerator).path | default "/etc/bind/conf.d") -}}
#!/bin/sh
CMDLINE_ARGS="${@}"
if [ -z "${CMDLINE_ARGS}" ]; then
    CMDLINE_ARGS="-f -c /etc/bind/named.conf"
    echo "Using default cmdline args \"${CMDLINE_ARGS}\""
fi
{{- if ((.Values.bind9).forwarderGenerator).forwarders -}}
{{- range $conf, $values := .Values.bind9.forwarderGenerator.forwarders }}
    {{- if hasKey $values "dns" }}
DNS_ADDRESSES_{{ $conf }}="{{ $values.dns | join " " }}"
    {{- end -}}
    {{- if hasKey $values "ip" }}
IP_ADDRESSES_{{ $conf }}="{{ $values.ip | join " " }}"
    {{- end -}}
{{- end }}

mkdir -p {{ $forwardersPath }}
for configName in {{ keys (.Values.bind9.forwarderGenerator).forwarders | join " " }}; do
    forwarder_addresses=""
    dns_addresses_var="DNS_ADDRESSES_${configName}"
    for dns_addr in $(eval "echo \${$dns_addresses_var}"); do
        dns_ips=$(dig +short $dns_addr)
        if [ -z "${dns_ips}" ]; then
            echo "Could not resolve: $dns_addr, exiting!"
            exit 1
        fi
        for ip_addr in $dns_ips; do
            forwarder_addresses="${forwarder_addresses} ${ip_addr}"
        done
        unset ip_addr
        unset dns_ips
    done
    unset dns_addr

    ip_addresses_var="IP_ADDRESSES_${configName}"
    for ip_addr in $(eval "echo \${$ip_addresses_var}"); do
        forwarder_addresses="${forwarder_addresses} ${ip_addr}"
    done
    unset ip_addr

    if [ -z "${forwarder_addresses}" ]; then
        echo "No forwarder addresses defined in config \"${configName}\", skipping"
        continue
    fi
    echo "forwarders {" > {{ $forwardersPath }}/forwarders.${configName}.conf
    for ip_addr in $forwarder_addresses; do
        echo "    ${ip_addr};" >> {{ $forwardersPath }}/forwarders.${configName}.conf
    done
    unset ip_addr
    echo "};" >> {{ $forwardersPath }}/forwarders.${configName}.conf
    chmod 0644 {{ $forwardersPath }}/forwarders.${configName}.conf
    chown root:bind {{ $forwardersPath }}/forwarders.${configName}.conf
    echo "Generated file: {{ $forwardersPath }}/forwarders.${configName}.conf"
done
{{- end }}
{{- if ((.Values.bind9).keyGenerator).enabled }}
for keyname in {{ (.Values.bind9.keyGenerator).keys | join " " }}; do
    keyfile="{{ trimSuffix "/" (.Values.bind9.keyGenerator).path | default "/etc/bind/conf.d" }}/key.${keyname}.conf"
    if [ ! -f $keyfile ]; then
        echo "Generating keyfile: ${keyfile}"
        tsig-keygen -a hmac-sha256 $keyname > $keyfile
    fi
done
{{- end }}
{{- if ((.Values.bind9).zoneCopy).enabled }}
if [ -d {{ trimSuffix "/" ((.Values.bind9.zoneCopy).source | default "/etc/bind/zones") }} ]; then
  for zonefile in {{ trimSuffix "/" ((.Values.bind9.zoneCopy).source | default "/etc/bind/zones") }}/*; do
      cp -L {{- ((.Values.bind9.zoneCopy).overwrite | default false) | ternary "" " -n" }} $zonefile {{ trimSuffix "/" (.Values.bind9.zoneCopy).destination | default "/var/cache/bind" }} || true
  done
fi
{{- end }}
chown -R bind:bind /var/cache/bind
{{- if ((.Values.bind9).namedConfGenerator).enabled }}
truncate -s 0 /etc/bind/named.conf
for filename in {{ trimSuffix "/" (((.Values.bind9).namedConfGenerator).includes | default "/etc/bind/named.d") }}/*; do
    [ -e "$filename" ] || continue
    # ... rest of the loop body
    echo "include \"$filename\";" >> /etc/bind/named.conf
done
chmod 0644 /etc/bind/named.conf
chown root:bind /etc/bind/named.conf
{{- end }}

echo "Checking bind config"
/usr/bin/named-checkconf /etc/bind/named.conf

echo "Starting server: \"/usr/sbin/named -u bind $CMDLINE_ARGS\""
/usr/sbin/named -u bind $CMDLINE_ARGS
{{- end }}