{{- define "unbound.unboundConf" -}}
    {{- if (.Values.unbound.unboundConf).override -}}
        {{- .Values.unbound.unboundConf.override -}}
    {{- else -}}
include: "/usr/local/unbound/conf.d/*.conf"
include: "/usr/local/unbound/zones.d/*.conf"

server:
  interface: 0.0.0.0@{{ .Values.unbound.port | default "53" }}
  module-config: "validator {{ if .Values.redisSidecar.enabled }}cachedb {{ end }}iterator"
  directory: "/usr/local/unbound"
  do-daemonize: no
  chroot: ""
  root-hints: /usr/local/unbound/iana.d/root.hints
  tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
{{ if or (.Values.redisSidecar).enabled (.Values.redis).enabled (.Values.unbound.redis).host }}
cachedb:
  backend: "redis"
  redis-expire-records: no
{{ if and .Values.redisSidecar.enabled (not .Values.redisSidecar.port) }}
  redis-server-path: /usr/local/unbound/cachedb.d/redis.sock
{{ else }}
  redis-server-host: {{ include "unbound.redisHost" . }} # The hostname or IP of your Redis server
  redis-server-port: {{ include "unbound.redisPort" . }}
{{ end }}
{{ end }}
    {{- end -}}
{{- end }}

{{- define "unbound.authZone" -}}
# Authority zones
# The data for these zones is kept locally, from a file or downloaded.
# The data can be served to downstream clients, or used instead of the
# upstream (which saves a lookup to the upstream).  The first example
# has a copy of the root for local usage.  The second serves example.org
# authoritatively.  zonefile: reads from file (and writes to it if you also
# download it), primary: fetches with AXFR and IXFR, or url to zonefile.
# With allow-notify: you can give additional (apart from primaries and urls)
# sources of notifies.

auth-zone:
  name: "."
  primary: 170.247.170.2        # b.root-servers.net
  primary: 192.33.4.12          # c.root-servers.net
  primary: 199.7.91.13          # d.root-servers.net
  primary: 192.5.5.241          # f.root-servers.net
  primary: 192.112.36.4         # g.root-servers.net
  primary: 193.0.14.129         # k.root-servers.net
  primary: 192.0.47.132         # iad.xfr.dns.icann.org
  primary: 192.0.32.132         # lax.xfr.dns.icann.org
  primary: 2801:1b8:10::b       # b.root-servers.net
  primary: 2001:500:2::c        # c.root-servers.net
  primary: 2001:500:2d::d       # d.root-servers.net
  primary: 2001:500:2f::f       # f.root-servers.net
  primary: 2001:500:12::d0d     # g.root-servers.net
  primary: 2001:7fd::1          # k.root-servers.net
  primary: 2620:0:2830:202::132 # iad.xfr.dns.icann.org
  primary: 2620:0:2d0:202::132  # lax.xfr.dns.icann.org
  #url: "https://www.internic.net/domain/root.zone"
  fallback-enabled: yes
  for-downstream: no
  for-upstream: yes
  zonemd-check: yes
  zonemd-reject-absence: no
  zonefile: "/usr/local/unbound/iana.d/root.zone"
{{- end }}

{{- define "unbound.localZone" -}}
server:	
  local-zone: "localhost." nodefault
  local-zone: "127.in-addr.arpa." nodefault
  local-zone: "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa." nodefault
  local-zone: "home.arpa." nodefault
  local-zone: "onion." nodefault
  local-zone: "test." nodefault
  local-zone: "invalid." nodefault
  local-zone: "10.in-addr.arpa." nodefault
  local-zone: "16.172.in-addr.arpa." nodefault
  local-zone: "17.172.in-addr.arpa." nodefault
  local-zone: "18.172.in-addr.arpa." nodefault
  local-zone: "19.172.in-addr.arpa." nodefault
  local-zone: "20.172.in-addr.arpa." nodefault
  local-zone: "21.172.in-addr.arpa." nodefault
  local-zone: "22.172.in-addr.arpa." nodefault
  local-zone: "23.172.in-addr.arpa." nodefault
  local-zone: "24.172.in-addr.arpa." nodefault
  local-zone: "25.172.in-addr.arpa." nodefault
  local-zone: "26.172.in-addr.arpa." nodefault
  local-zone: "27.172.in-addr.arpa." nodefault
  local-zone: "28.172.in-addr.arpa." nodefault
  local-zone: "29.172.in-addr.arpa." nodefault
  local-zone: "30.172.in-addr.arpa." nodefault
  local-zone: "31.172.in-addr.arpa." nodefault
  local-zone: "168.192.in-addr.arpa." nodefault
  local-zone: "0.in-addr.arpa." nodefault
  local-zone: "254.169.in-addr.arpa." nodefault
  local-zone: "2.0.192.in-addr.arpa." nodefault
  local-zone: "100.51.198.in-addr.arpa." nodefault
  local-zone: "113.0.203.in-addr.arpa." nodefault
  local-zone: "255.255.255.255.in-addr.arpa." nodefault
  local-zone: "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa." nodefault
  local-zone: "d.f.ip6.arpa." nodefault
  local-zone: "8.e.f.ip6.arpa." nodefault
  local-zone: "9.e.f.ip6.arpa." nodefault
  local-zone: "a.e.f.ip6.arpa." nodefault
  local-zone: "b.e.f.ip6.arpa." nodefault
  local-zone: "8.b.d.0.1.0.0.2.ip6.arpa." nodefault
  # And for 64.100.in-addr.arpa. to 127.100.in-addr.arpa.
{{- end }}

{{- define "unbound.defaultConfig" -}}
#
# Example configuration file.
#
# See unbound.conf(5) man page, version @version@.
#
# this is a comment.

# Use this anywhere in the file to include other text into this file.
#include: "otherfile.conf"

#include: "/usr/local/unbound/conf.d/*.conf"
#include: "/usr/local/unbound/zones.d/*.conf"

# Use this anywhere in the file to include other text, that explicitly starts a
# clause, into this file. Text after this directive needs to start a clause.
#include-toplevel: "otherfile.conf"

# The server clause sets the main parameters.
server:
  # verbosity number, 0 is least verbose. 1 is default.
  verbosity: 1
  # number of threads to create. 1 disables threading.
  num-threads: 1
  # port to answer queries from
  # port: 5335
  # Specify a netblock to use remainder 64 bits as random bits for
  # upstream queries.  Uses freebind option (Linux).
  # outgoing-interface: 2001:DB8::/64
  # Also (Linux:) ip -6 addr add 2001:db8::/64 dev lo
  # And: ip -6 route add local 2001:db8::/64 dev lo
  # And set prefer-ip6: yes to use the ip6 randomness from a netblock.
  # Set this to yes to prefer ipv6 upstream servers over ipv4.
  prefer-ip6: no
  # Prefer ipv4 upstream servers, even if ipv6 is available.
  prefer-ip4: yes
  # number of ports to allocate per thread, determines the size of the
  # port range that can be open simultaneously.  About double the
  # num-queries-per-thread, or, use as many as the OS will allow you.
  outgoing-range: 4096
  # permit Unbound to use this port number or port range for
  # making outgoing queries, using an outgoing interface.
  outgoing-port-permit: 32768
  # the amount of memory to use for the message cache.
  # plain value in bytes or you can append k, m or G. default is "4Mb".
  msg-cache-size: 4m
  # the number of slabs to use for the message cache.
  # the number of slabs must be a power of 2.
  # more slabs reduce lock contention, but fragment memory usage.
  msg-cache-slabs: 4
  # the number of queries that a thread gets to service.
  num-queries-per-thread: 4096
  # perform connect for UDP sockets to mitigate ICMP side channel.
  udp-connect: yes
  # the amount of memory to use for the RRset cache.
  # plain value in bytes or you can append k, m or G. default is "4Mb".
  rrset-cache-size: 4m
  # the number of slabs to use for the RRset cache.
  # the number of slabs must be a power of 2.
  # more slabs reduce lock contention, but fragment memory usage.
  rrset-cache-slabs: 4
  # the time to live (TTL) value lower bound, in seconds. Default 0.
  # If more than an hour could easily give trouble due to stale data.
  cache-min-ttl: 0
  # the time to live (TTL) value cap for RRsets and messages in the
  # cache. Items are not cached for longer. In seconds.
  cache-max-ttl: 86400
  # the number of slabs to use for the Infrastructure cache.
  # the number of slabs must be a power of 2.
  # more slabs reduce lock contention, but fragment memory usage.
  infra-cache-slabs: 4
  # Enable IPv4, "yes" or "no".
  do-ip4: yes
  # Enable IPv6, "yes" or "no".
  do-ip6: no
  # Enable UDP, "yes" or "no".
  do-udp: yes
  # Enable TCP, "yes" or "no".
  do-tcp: yes
  # Use systemd socket activation for UDP, TCP, and control sockets.
  use-systemd: no
  # control which clients are allowed to make (recursive) queries
  # to this server. Specify classless netblocks with /size and action.
  # By default everything is refused, except for localhost.
  # Choose deny (drop message), refuse (polite error reply),
  # allow (recursive ok), allow_setrd (recursive ok, rd bit is forced on),
  # allow_snoop (recursive and nonrecursive ok)
  # deny_non_local (drop queries unless can be answered from local-data)
  # refuse_non_local (like deny_non_local but polite error reply).

  # access-control: 127.0.0.0/8 allow
  # access-control: ::1 allow
  # access-control: ::ffff:127.0.0.1 allow
  access-control: 0.0.0.0/0 allow
  # if given, a chroot(2) is done to the given directory.
  # i.e. you can chroot to the working directory, for example,
  # for extra security, but make sure all files are in that directory.
  #
  # If chroot is enabled, you should pass the configfile (from the
  # commandline) as a full path from the original root. After the
  # chroot has been performed the now defunct portion of the config
  # file path is removed to be able to reread the config after a reload.
  #
  # All other file paths (working dir, logfile, roothints, and
  # key files) can be specified in several ways:
  # o as an absolute path relative to the new root.
  # o as a relative path to the working directory.
  # o as an absolute path relative to the original root.
  # In the last case the path is adjusted to remove the unused portion.
  #
  # The pid file can be absolute and outside of the chroot, it is
  # written just prior to performing the chroot and dropping permissions.
  #
  # Additionally, Unbound may need to access /dev/urandom (for entropy).
  # How to do this is specific to your OS.
  #
  # If you give "" no chroot is performed. The path must not end in a /.
  # chroot: "@UNBOUND_CHROOT_DIR@"
  chroot: ""
  # if given, user privileges are dropped (after binding port),
  # and the given username is assumed. Default is user "unbound".
  # If you give "" no privileges are dropped.
  username: ""
  # the log file, "" means log to stderr.
  # Use of this option sets use-syslog to "no".
  logfile: ""
  # Log to syslog(3) if yes. The log facility LOG_DAEMON is used to
  # log to. If yes, it overrides the logfile.
  use-syslog: no
  # print UTC timestamp in ascii to logfile, default is epoch in seconds.
  log-time-ascii: yes
  # print log lines that say why queries return SERVFAIL to clients.
  log-servfail: yes
  # the pid file. Can be an absolute path outside of chroot/work dir.
  pidfile: "/usr/local/unbound/unbound.d/unbound.pid"
  # file to read root hints from.
  # get one from https://www.internic.net/domain/named.cache
  # root-hints: ""
  # root-hints: "/usr/local/unbound/iana.d/root.hints"
  # enable to not answer id.server and hostname.bind queries.
  hide-identity: yes
  # enable to not answer version.server and version.bind queries.
  hide-version: yes
  # enable to not answer trustanchor.unbound queries.
  hide-trustanchor: yes
  # Harden against very small EDNS buffer sizes.
  harden-short-bufsize: yes
  # Harden against unseemly large queries.
  harden-large-queries: yes
  # Harden against out of zone rrsets, to avoid spoofing attempts.
  harden-glue: yes
  # Harden against receiving dnssec-stripped data. If you turn it
  # off, failing to validate dnskey data for a trustanchor will
  # trigger insecure mode for that zone (like without a trustanchor).
  # Default on, which insists on dnssec data for trust-anchored zones.
  harden-dnssec-stripped: yes
  # Harden against queries that fall under dnssec-signed nxdomain names.
  harden-below-nxdomain: yes

  # Harden against algorithm downgrade when multiple algorithms are
  # advertised in the DS record.  If no, allows the weakest algorithm
  # to validate the zone.
  harden-algo-downgrade: yes
  # Sent minimum amount of information to upstream servers to enhance
  # privacy. Only sent minimum required labels of the QNAME and set QTYPE
  # to A when possible.
  qname-minimisation: yes
  # Aggressive NSEC uses the DNSSEC NSEC chain to synthesize NXDOMAIN
  # and other denials, using information from previous NXDOMAINs answers.
  aggressive-nsec: yes
  # Use 0x20-encoded random bits in the query to foil spoof attempts.
  # This feature is an experimental implementation of draft dns-0x20.
  use-caps-for-id: no
  # Enforce privacy of these addresses. Strips them away from answers.
  # It may cause DNSSEC validation to additionally mark it as bogus.
  # Protects against 'DNS Rebinding' (uses browser as network proxy).
  # Only 'private-domain' and 'local-data' names are allowed to have
  # these private addresses. No default.
  private-address: 10.0.0.0/8
  private-address: 172.16.0.0/12
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: fd00::/8
  private-address: fe80::/10
  private-address: ::ffff:0:0/96
  # if yes, the above default do-not-query-address entries are present.
  # if no, localhost can be queried (for testing and debugging).
  do-not-query-localhost: yes
  # deny queries of type ANY with an empty response.
  deny-any: yes
  # if yes, Unbound rotates RRSet order in response.
  rrset-roundrobin: yes
  # if yes, Unbound doesn't insert authority/additional sections
  # into response messages when those sections are not required.
  minimal-responses: yes
  # true to disable DNSSEC lameness check in iterator.
  disable-dnssec-lame-check: no
  # module configuration of the server. A string with identifiers
  # separated by spaces. Syntax: "[dns64] [validator] iterator"
  # most modules have to be listed at the beginning of the line,
  # except cachedb(just before iterator), and python (at the beginning,
  # or, just before the iterator).
  module-config: "validator iterator"
  # File with trusted keys, kept uptodate using RFC5011 probes,
  # initial file like trust-anchor-file, then it stores metadata.
  # Use several entries, one per domain name, to track multiple zones.
  #
  # If you want to perform DNSSEC validation, run unbound-anchor before
  # you start Unbound (i.e. in the system boot scripts).
  # And then enable the auto-trust-anchor-file config item.
  # Please note usage of unbound-anchor root anchor is at your own risk
  # and under the terms of our LICENSE (see that file in the source).
  # auto-trust-anchor-file: "@UNBOUND_ROOTKEY_FILE@"

  auto-trust-anchor-file: "/usr/local/unbound/iana.d/root.key"
  # trust anchor signaling sends a RFC8145 key tag query after priming.
  trust-anchor-signaling: yes
  # Root key trust anchor sentinel (draft-ietf-dnsop-kskroll-sentinel)
  root-key-sentinel: yes
  # The maximum number the validator should restart validation with
  # another authority in case of failed validation.
  val-max-restart: 5
  # Should additional section of secure message also be kept clean of
  # unsecure data. Useful to shield the users of this validator from
  # potential bogus data in the additional section. All unsigned data
  # in the additional section is removed from secure messages.
  val-clean-additional: yes
  # Turn permissive mode on to permit bogus messages. Thus, messages
  # for which security checks failed will be returned to clients,
  # instead of SERVFAIL. It still performs the security checks, which
  # result in interesting log files and possibly the AD bit in
  # replies if the message is found secure. The default is off.
  val-permissive-mode: no
  # Ignore the CD flag in incoming queries and refuse them bogus data.
  # Enable it if the only clients of Unbound are legacy servers (w2008)
  # that set CD but cannot validate themselves.
  ignore-cd-flag: no
  # Serve expired responses from cache, with serve-expired-reply-ttl in
  # the response, and then attempt to fetch the data afresh.
  serve-expired: no
  # Have the validator log failed validations for your diagnosis.
  # 0: off. 1: A line per failed user query. 2: With reason and bad IP.
  val-log-level: 2
  # if enabled, ZONEMD verification failures do not block the zone.
  zonemd-permissive-mode: no
  # the amount of memory to use for the key cache.
  # plain value in bytes or you can append k, m or G. default is "4Mb".
  key-cache-size: 4m
  # the number of slabs to use for the key cache.
  # the number of slabs must be a power of 2.
  # more slabs reduce lock contention, but fragment memory usage.
  key-cache-slabs: 4
  # the amount of memory to use for the negative cache.
  # plain value in bytes or you can append k, m or G. default is "1Mb".
  neg-cache-size: 1m
  # If Unbound is running service for the local host then it is useful
  # to perform lan-wide lookups to the upstream, and unblock the
  # long list of local-zones above.  If this Unbound is a dns server
  # for a network of computers, disabled is better and stops information
  # leakage of local lan information.
  unblock-lan-zones: no
  # The insecure-lan-zones option disables validation for
  # these zones, as if they were all listed as domain-insecure.
  insecure-lan-zones: yes

python:

dynlib:

# Remote control config section.
remote-control:

{{- end }}

{{- define "unbound.redisDefaultConfig" -}}
# Unless specified otherwise, by default Redis will save the DB:
#   * After 1800 seconds (30 minutes) if at least 1 change was performed
#   * After 600 seconds (10 minutes) if at least 10 changes were performed
#   * After 180 seconds if at least 100 changes were performed
#   * After 60 seconds if at least 1000 changes were performed
save 1800 1 600 10 180 100 60 1000
# Protected mode is a layer of security protection, in order to avoid that
# Redis instances left open on the internet are accessed and exploited.
#
# When protected mode is on and the default user has no password, the server
# only accepts local connections from the IPv4 address (127.0.0.1), IPv6 address
# (::1) or Unix domain sockets.
#
# By default protected mode is enabled. You should disable it only if
# you are sure you want clients from other hosts to connect to Redis
# even if no authentication is configured.
protected-mode yes

# Accept connections on the specified port, default is 6379 (IANA #815344).
# If port 0 is specified Redis will not listen on a TCP socket.
#port 6379
port {{ (.Values.redisSidecar).port | default "0" }}

# TCP listen() backlog.
#
# In high requests-per-second environments you need a high backlog in order
# to avoid slow clients connection issues. Note that the Linux kernel
# will silently truncate it to the value of /proc/sys/net/core/somaxconn so
# make sure to raise both the value of somaxconn and tcp_max_syn_backlog
# in order to get the desired effect.
tcp-backlog 4096

# Unix socket.
#
# Specify the path for the Unix socket that will be used to listen for
# incoming connections. There is no default, so Redis will not listen
# on a unix socket when not specified.
#
{{ if not (.Values.redisSidecar).port }}
unixsocket /usr/local/unbound/cachedb.d/redis.sock
unixsocketperm 777
{{ end }}
# Close the connection after a client is idle for N seconds (0 to disable)
timeout 0

# TCP keepalive.
#
# If non-zero, use SO_KEEPALIVE to send TCP ACKs to clients in absence
# of communication. This is useful for two reasons:
#
# 1) Detect dead peers.
# 2) Force network equipment in the middle to consider the connection to be
#    alive.
#
# On Linux, the specified value (in seconds) is the period used to send ACKs.
# Note that to close the connection the double of the time is needed.
# On other kernels the period depends on the kernel configuration.
#
# A reasonable value for this option is 300 seconds, which is the new
# Redis default starting with Redis 3.2.1.
tcp-keepalive 300

# By default Redis does not run as a daemon. Use 'yes' if you need it.
# Note that Redis will write a pid file in /var/run/redis.pid when daemonized.
# When Redis is supervised by upstart or systemd, this parameter has no impact.
daemonize no

# Specify the server verbosity level.
# This can be one of:
# debug (a lot of information, useful for development/testing)
# verbose (many rarely useful info, but not a mess like the debug level)
# notice (moderately verbose, what you want in production probably)
# warning (only very important / critical messages are logged)
# nothing (nothing is logged)
loglevel notice

# Specify the log file name. Also the empty string can be used to force
# Redis to log on the standard output. Note that if you use standard
# output for logging but daemonize, logs will be sent to /dev/null
logfile ""

# Set the number of databases. The default database is DB 0, you can select
# a different one on a per-connection basis using SELECT <dbid> where
# dbid is a number between 0 and 'databases'-1
databases 1

# By default Redis shows an ASCII art logo only when started to log to the
# standard output and if the standard output is a TTY and syslog logging is
# disabled. Basically this means that normally a logo is displayed only in
# interactive sessions.
#
# However it is possible to force the pre-4.0 behavior and always show a
# ASCII art logo in startup logs by setting the following option to yes.
always-show-logo no

# By default, Redis modifies the process title (as seen in 'top' and 'ps') to
# provide some runtime information. It is possible to disable this and leave
# the process name as executed by setting the following to no.
set-proc-title yes

# When changing the process title, Redis uses the following template to construct
# the modified title.
#
# Template variables are specified in curly brackets. The following variables are
# supported:
#
# {title}           Name of process as executed if parent, or type of child process.
# {listen-addr}     Bind address or '*' followed by TCP or TLS port listening on, or
#                   Unix socket if only that's available.
# {server-mode}     Special mode, i.e. "[sentinel]" or "[cluster]".
# {port}            TCP port listening on, or 0.
# {tls-port}        TLS port listening on, or 0.
# {unixsocket}      Unix domain socket listening on, or "".
# {config-file}     Name of configuration file used.
#
proc-title-template "{title} {listen-addr} {server-mode}"

# Set the local environment which is used for string comparison operations, and
# also affect the performance of Lua scripts. Empty String indicates the locale
# is derived from the environment variables.
locale-collate ""

# By default Redis will stop accepting writes if RDB snapshots are enabled
# (at least one save point) and the latest background save failed.
# This will make the user aware (in a hard way) that data is not persisting
# on disk properly, otherwise chances are that no one will notice and some
# disaster will happen.
#
# If the background saving process will start working again Redis will
# automatically allow writes again.
#
# However if you have setup your proper monitoring of the Redis server
# and persistence, you may want to disable this feature so that Redis will
# continue to work as usual even if there are problems with disk,
# permissions, and so forth.
stop-writes-on-bgsave-error no

# Compress string objects using LZF when dump .rdb databases?
# By default compression is enabled as it's almost always a win.
# If you want to save some CPU in the saving child set it to 'no' but
# the dataset will likely be bigger if you have compressible values or keys.
rdbcompression yes

# Since version 5 of RDB a CRC64 checksum is placed at the end of the file.
# This makes the format more resistant to corruption but there is a performance
# hit to pay (around 10%) when saving and loading RDB files, so you can disable it
# for maximum performances.
#
# RDB files created with checksum disabled have a checksum of zero that will
# tell the loading code to skip the check.
rdbchecksum no

# The filename where to dump the DB
dbfilename dump.rdb

# Remove RDB files used by replication in instances without persistence
# enabled. By default this option is disabled, however there are environments
# where for regulations or other security concerns, RDB files persisted on
# disk by masters in order to feed replicas, or stored on disk by replicas
# in order to load them for the initial synchronization, should be deleted
# ASAP. Note that this option ONLY WORKS in instances that have both AOF
# and RDB persistence disabled, otherwise is completely ignored.
#
# An alternative (and sometimes better) way to obtain the same effect is
# to use diskless replication on both master and replicas instances. However
# in the case of replicas, diskless is not always an option.
rdb-del-sync-files no

# The working directory.
#
# The DB will be written inside this directory, with the filename specified
# above using the 'dbfilename' configuration directive.
#
# The Append Only File will also be created inside this directory.
#
# Note that you must specify a directory here, not a file name.
dir ./

# When a replica loses its connection with the master, or when the replication
# is still in progress, the replica can act in two different ways:
#
# 1) if replica-serve-stale-data is set to 'yes' (the default) the replica will
#    still reply to client requests, possibly with out of date data, or the
#    data set may just be empty if this is the first synchronization.
#
# 2) If replica-serve-stale-data is set to 'no' the replica will reply with error
#    "MASTERDOWN Link with MASTER is down and replica-serve-stale-data is set to 'no'"
#    to all data access commands, excluding commands such as:
#    INFO, REPLICAOF, AUTH, SHUTDOWN, REPLCONF, ROLE, CONFIG, SUBSCRIBE,
#    UNSUBSCRIBE, PSUBSCRIBE, PUNSUBSCRIBE, PUBLISH, PUBSUB, COMMAND, POST,
#    HOST and LATENCY.
#
replica-serve-stale-data yes

# You can configure a replica instance to accept writes or not. Writing against
# a replica instance may be useful to store some ephemeral data (because data
# written on a replica will be easily deleted after resync with the master) but
# may also cause problems if clients are writing to it because of a
# misconfiguration.
#
# Since Redis 2.6 by default replicas are read-only.
#
# Note: read only replicas are not designed to be exposed to untrusted clients
# on the internet. It's just a protection layer against misuse of the instance.
# Still a read only replica exports by default all the administrative commands
# such as CONFIG, DEBUG, and so forth. To a limited extent you can improve
# security of read only replicas using 'rename-command' to shadow all the
# administrative / dangerous commands.
replica-read-only yes

# Replication SYNC strategy: disk or socket.
#
# New replicas and reconnecting replicas that are not able to continue the
# replication process just receiving differences, need to do what is called a
# "full synchronization". An RDB file is transmitted from the master to the
# replicas.
#
# The transmission can happen in two different ways:
#
# 1) Disk-backed: The Redis master creates a new process that writes the RDB
#                 file on disk. Later the file is transferred by the parent
#                 process to the replicas incrementally.
# 2) Diskless: The Redis master creates a new process that directly writes the
#              RDB file to replica sockets, without touching the disk at all.
#
# With disk-backed replication, while the RDB file is generated, more replicas
# can be queued and served with the RDB file as soon as the current child
# producing the RDB file finishes its work. With diskless replication instead
# once the transfer starts, new replicas arriving will be queued and a new
# transfer will start when the current one terminates.
#
# When diskless replication is used, the master waits a configurable amount of
# time (in seconds) before starting the transfer in the hope that multiple
# replicas will arrive and the transfer can be parallelized.
#
# With slow disks and fast (large bandwidth) networks, diskless replication
# works better.
repl-diskless-sync yes

# When diskless replication is enabled, it is possible to configure the delay
# the server waits in order to spawn the child that transfers the RDB via socket
# to the replicas.
#
# This is important since once the transfer starts, it is not possible to serve
# new replicas arriving, that will be queued for the next RDB transfer, so the
# server waits a delay in order to let more replicas arrive.
#
# The delay is specified in seconds, and by default is 5 seconds. To disable
# it entirely just set it to 0 seconds and the transfer will start ASAP.
repl-diskless-sync-delay 5

# When diskless replication is enabled with a delay, it is possible to let
# the replication start before the maximum delay is reached if the maximum
# number of replicas expected have connected. Default of 0 means that the
# maximum is not defined and Redis will wait the full delay.
repl-diskless-sync-max-replicas 0

# -----------------------------------------------------------------------------
# WARNING: Since in this setup the replica does not immediately store an RDB on
# disk, it may cause data loss during failovers. RDB diskless load + Redis
# modules not handling I/O reads may cause Redis to abort in case of I/O errors
# during the initial synchronization stage with the master.
# -----------------------------------------------------------------------------
#
# Replica can load the RDB it reads from the replication link directly from the
# socket, or store the RDB to a file and read that file after it was completely
# received from the master.
#
# In many cases the disk is slower than the network, and storing and loading
# the RDB file may increase replication time (and even increase the master's
# Copy on Write memory and replica buffers).
# However, when parsing the RDB file directly from the socket, in order to avoid
# data loss it's only safe to flush the current dataset when the new dataset is
# fully loaded in memory, resulting in higher memory usage.
# For this reason we have the following options:
#
# "disabled"    - Don't use diskless load (store the rdb file to the disk first)
# "swapdb"      - Keep current db contents in RAM while parsing the data directly
#                 from the socket. Replicas in this mode can keep serving current
#                 dataset while replication is in progress, except for cases where
#                 they can't recognize master as having a data set from same
#                 replication history.
#                 Note that this requires sufficient memory, if you don't have it,
#                 you risk an OOM kill.
# "on-empty-db" - Use diskless load only when current dataset is empty. This is
#                 safer and avoid having old and new dataset loaded side by side
#                 during replication.
repl-diskless-load disabled

# Master send PINGs to its replicas in a predefined interval. It's possible to
# change this interval with the repl_ping_replica_period option. The default
# value is 10 seconds.
#
# repl-ping-replica-period 10

# The following option sets the replication timeout for:
#
# 1) Bulk transfer I/O during SYNC, from the point of view of replica.
# 2) Master timeout from the point of view of replicas (data, pings).
# 3) Replica timeout from the point of view of masters (REPLCONF ACK pings).
#
# It is important to make sure that this value is greater than the value
# specified for repl-ping-replica-period otherwise a timeout will be detected
# every time there is low traffic between the master and the replica. The default
# value is 60 seconds.
#
# repl-timeout 60

# Disable TCP_NODELAY on the replica socket after SYNC?
#
# If you select "yes" Redis will use a smaller number of TCP packets and
# less bandwidth to send data to replicas. But this can add a delay for
# the data to appear on the replica side, up to 40 milliseconds with
# Linux kernels using a default configuration.
#
# If you select "no" the delay for data to appear on the replica side will
# be reduced but more bandwidth will be used for replication.
#
# By default we optimize for low latency, but in very high traffic conditions
# or when the master and replicas are many hops away, turning this to "yes" may
# be a good idea.
repl-disable-tcp-nodelay no

# Set the replication backlog size. The backlog is a buffer that accumulates
# replica data when replicas are disconnected for some time, so that when a
# replica wants to reconnect again, often a full resync is not needed, but a
# partial resync is enough, just passing the portion of data the replica
# missed while disconnected.
#
# The bigger the replication backlog, the longer the replica can endure the
# disconnect and later be able to perform a partial resynchronization.
#
# The backlog is only allocated if there is at least one replica connected.
#
# repl-backlog-size 1mb

# After a master has no connected replicas for some time, the backlog will be
# freed. The following option configures the amount of seconds that need to
# elapse, starting from the time the last replica disconnected, for the backlog
# buffer to be freed.
#
# Note that replicas never free the backlog for timeout, since they may be
# promoted to masters later, and should be able to correctly "partially
# resynchronize" with other replicas: hence they should always accumulate backlog.
#
# A value of 0 means to never release the backlog.
#
# repl-backlog-ttl 3600

# The replica priority is an integer number published by Redis in the INFO
# output. It is used by Redis Sentinel in order to select a replica to promote
# into a master if the master is no longer working correctly.
#
# A replica with a low priority number is considered better for promotion, so
# for instance if there are three replicas with priority 10, 100, 25 Sentinel
# will pick the one with priority 10, that is the lowest.
#
# However a special priority of 0 marks the replica as not able to perform the
# role of master, so a replica with priority of 0 will never be selected by
# Redis Sentinel for promotion.
#
# By default the priority is 100.
replica-priority 100

# ACL LOG
#
# The ACL Log tracks failed commands and authentication events associated
# with ACLs. The ACL Log is useful to troubleshoot failed commands blocked
# by ACLs. The ACL Log is stored in memory. You can reclaim memory with
# ACL LOG RESET. Define the maximum entry length of the ACL Log below.
acllog-max-len 128

# MAXMEMORY POLICY: how Redis will select what to remove when maxmemory
# is reached. You can select one from the following behaviors:
#
# volatile-lru -> Evict using approximated LRU, only keys with an expire set.
# allkeys-lru -> Evict any key using approximated LRU.
# volatile-lfu -> Evict using approximated LFU, only keys with an expire set.
# allkeys-lfu -> Evict any key using approximated LFU.
# volatile-random -> Remove a random key having an expire set.
# allkeys-random -> Remove a random key, any key.
# volatile-ttl -> Remove the key with the nearest expire time (minor TTL)
# noeviction -> Don't evict anything, just return an error on write operations.
#
# LRU means Least Recently Used
# LFU means Least Frequently Used
#
# Both LRU, LFU and volatile-ttl are implemented using approximated
# randomized algorithms.
#
# Note: with any of the above policies, when there are no suitable keys for
# eviction, Redis will return an error on write operations that require
# more memory. These are usually commands that create new keys, add data or
# modify existing keys. A few examples are: SET, INCR, HSET, LPUSH, SUNIONSTORE,
# SORT (due to the STORE argument), and EXEC (if the transaction includes any
# command that requires memory).
#
# The default is:
#
maxmemory 4mb
maxmemory-policy allkeys-lru

############################# LAZY FREEING ####################################

# Redis has two primitives to delete keys. One is called DEL and is a blocking
# deletion of the object. It means that the server stops processing new commands
# in order to reclaim all the memory associated with an object in a synchronous
# way. If the key deleted is associated with a small object, the time needed
# in order to execute the DEL command is very small and comparable to most other
# O(1) or O(log_N) commands in Redis. However if the key is associated with an
# aggregated value containing millions of elements, the server can block for
# a long time (even seconds) in order to complete the operation.
#
# For the above reasons Redis also offers non blocking deletion primitives
# such as UNLINK (non blocking DEL) and the ASYNC option of FLUSHALL and
# FLUSHDB commands, in order to reclaim memory in background. Those commands
# are executed in constant time. Another thread will incrementally free the
# object in the background as fast as possible.
#
# DEL, UNLINK and ASYNC option of FLUSHALL and FLUSHDB are user-controlled.
# It's up to the design of the application to understand when it is a good
# idea to use one or the other. However the Redis server sometimes has to
# delete keys or flush the whole database as a side effect of other operations.
# Specifically Redis deletes objects independently of a user call in the
# following scenarios:
#
# 1) On eviction, because of the maxmemory and maxmemory policy configurations,
#    in order to make room for new data, without going over the specified
#    memory limit.
# 2) Because of expire: when a key with an associated time to live (see the
#    EXPIRE command) must be deleted from memory.
# 3) Because of a side effect of a command that stores data on a key that may
#    already exist. For example the RENAME command may delete the old key
#    content when it is replaced with another one. Similarly SUNIONSTORE
#    or SORT with STORE option may delete existing keys. The SET command
#    itself removes any old content of the specified key in order to replace
#    it with the specified string.
# 4) During replication, when a replica performs a full resynchronization with
#    its master, the content of the whole database is removed in order to
#    load the RDB file just transferred.
#
# In all the above cases the default is to delete objects in a blocking way,
# like if DEL was called. However you can configure each case specifically
# in order to instead release memory in a non-blocking way like if UNLINK
# was called, using the following configuration directives.

lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no

# It is also possible, for the case when to replace the user code DEL calls
# with UNLINK calls is not easy, to modify the default behavior of the DEL
# command to act exactly like UNLINK, using the following configuration
# directive:

lazyfree-lazy-user-del no

# FLUSHDB, FLUSHALL, SCRIPT FLUSH and FUNCTION FLUSH support both asynchronous and synchronous
# deletion, which can be controlled by passing the [SYNC|ASYNC] flags into the
# commands. When neither flag is passed, this directive will be used to determine
# if the data should be deleted asynchronously.

lazyfree-lazy-user-flush no

############################ KERNEL OOM CONTROL ##############################

# On Linux, it is possible to hint the kernel OOM killer on what processes
# should be killed first when out of memory.
#
# Enabling this feature makes Redis actively control the oom_score_adj value
# for all its processes, depending on their role. The default scores will
# attempt to have background child processes killed before all others, and
# replicas killed before masters.
#
# Redis supports these options:
#
# no:       Don't make changes to oom-score-adj (default).
# yes:      Alias to "relative" see below.
# absolute: Values in oom-score-adj-values are written as is to the kernel.
# relative: Values are used relative to the initial value of oom_score_adj when
#           the server starts and are then clamped to a range of -1000 to 1000.
#           Because typically the initial value is 0, they will often match the
#           absolute values.
oom-score-adj no

# When oom-score-adj is used, this directive controls the specific values used
# for master, replica and background child processes. Values range -2000 to
# 2000 (higher means more likely to be killed).
#
# Unprivileged processes (not root, and without CAP_SYS_RESOURCE capabilities)
# can freely increase their value, but not decrease it below its initial
# settings. This means that setting oom-score-adj to "relative" and setting the
# oom-score-adj-values to positive values will always succeed.
oom-score-adj-values 0 200 800


#################### KERNEL transparent hugepage CONTROL ######################

# Usually the kernel Transparent Huge Pages control is set to "madvise" or
# or "never" by default (/sys/kernel/mm/transparent_hugepage/enabled), in which
# case this config has no effect. On systems in which it is set to "always",
# redis will attempt to disable it specifically for the redis process in order
# to avoid latency problems specifically with fork(2) and CoW.
# If for some reason you prefer to keep it enabled, you can set this config to
# "no" and the kernel global to "always".

disable-thp yes

############################## APPEND ONLY MODE ###############################

# By default Redis asynchronously dumps the dataset on disk. This mode is
# good enough in many applications, but an issue with the Redis process or
# a power outage may result into a few minutes of writes lost (depending on
# the configured save points).
#
# The Append Only File is an alternative persistence mode that provides
# much better durability. For instance using the default data fsync policy
# (see later in the config file) Redis can lose just one second of writes in a
# dramatic event like a server power outage, or a single write if something
# wrong with the Redis process itself happens, but the operating system is
# still running correctly.
#
# AOF and RDB persistence can be enabled at the same time without problems.
# If the AOF is enabled on startup Redis will load the AOF, that is the file
# with the better durability guarantees.
#
# Note that changing this value in a config file of an existing database and
# restarting the server can lead to data loss. A conversion needs to be done
# by setting it via CONFIG command on a live server first.
#
# Please check https://redis.io/topics/persistence for more information.

appendonly no

# The base name of the append only file.
#
# Redis 7 and newer use a set of append-only files to persist the dataset
# and changes applied to it. There are two basic types of files in use:
#
# - Base files, which are a snapshot representing the complete state of the
#   dataset at the time the file was created. Base files can be either in
#   the form of RDB (binary serialized) or AOF (textual commands).
# - Incremental files, which contain additional commands that were applied
#   to the dataset following the previous file.
#
# In addition, manifest files are used to track the files and the order in
# which they were created and should be applied.
#
# Append-only file names are created by Redis following a specific pattern.
# The file name's prefix is based on the 'appendfilename' configuration
# parameter, followed by additional information about the sequence and type.
#
# For example, if appendfilename is set to appendonly.aof, the following file
# names could be derived:
#
# - appendonly.aof.1.base.rdb as a base file.
# - appendonly.aof.1.incr.aof, appendonly.aof.2.incr.aof as incremental files.
# - appendonly.aof.manifest as a manifest file.

appendfilename "appendonly.aof"

# For convenience, Redis stores all persistent append-only files in a dedicated
# directory. The name of the directory is determined by the appenddirname
# configuration parameter.

appenddirname "appendonlydir"

# The fsync() call tells the Operating System to actually write data on disk
# instead of waiting for more data in the output buffer. Some OS will really flush
# data on disk, some other OS will just try to do it ASAP.
#
# Redis supports three different modes:
#
# no: don't fsync, just let the OS flush the data when it wants. Faster.
# always: fsync after every write to the append only log. Slow, Safest.
# everysec: fsync only one time every second. Compromise.
#
# The default is "everysec", as that's usually the right compromise between
# speed and data safety. It's up to you to understand if you can relax this to
# "no" that will let the operating system flush the output buffer when
# it wants, for better performances (but if you can live with the idea of
# some data loss consider the default persistence mode that's snapshotting),
# or on the contrary, use "always" that's very slow but a bit safer than
# everysec.
#
# More details please check the following article:
# http://antirez.com/post/redis-persistence-demystified.html
#
# If unsure, use "everysec".

# appendfsync always
appendfsync everysec
# appendfsync no

# When the AOF fsync policy is set to always or everysec, and a background
# saving process (a background save or AOF log background rewriting) is
# performing a lot of I/O against the disk, in some Linux configurations
# Redis may block too long on the fsync() call. Note that there is no fix for
# this currently, as even performing fsync in a different thread will block
# our synchronous write(2) call.
#
# In order to mitigate this problem it's possible to use the following option
# that will prevent fsync() from being called in the main process while a
# BGSAVE or BGREWRITEAOF is in progress.
#
# This means that while another child is saving, the durability of Redis is
# the same as "appendfsync no". In practical terms, this means that it is
# possible to lose up to 30 seconds of log in the worst scenario (with the
# default Linux settings).
#
# If you have latency problems turn this to "yes". Otherwise leave it as
# "no" that is the safest pick from the point of view of durability.

no-appendfsync-on-rewrite no

# Automatic rewrite of the append only file.
# Redis is able to automatically rewrite the log file implicitly calling
# BGREWRITEAOF when the AOF log size grows by the specified percentage.
#
# This is how it works: Redis remembers the size of the AOF file after the
# latest rewrite (if no rewrite has happened since the restart, the size of
# the AOF at startup is used).
#
# This base size is compared to the current size. If the current size is
# bigger than the specified percentage, the rewrite is triggered. Also
# you need to specify a minimal size for the AOF file to be rewritten, this
# is useful to avoid rewriting the AOF file even if the percentage increase
# is reached but it is still pretty small.
#
# Specify a percentage of zero in order to disable the automatic AOF
# rewrite feature.

auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# An AOF file may be found to be truncated at the end during the Redis
# startup process, when the AOF data gets loaded back into memory.
# This may happen when the system where Redis is running
# crashes, especially when an ext4 filesystem is mounted without the
# data=ordered option (however this can't happen when Redis itself
# crashes or aborts but the operating system still works correctly).
#
# Redis can either exit with an error when this happens, or load as much
# data as possible (the default now) and start if the AOF file is found
# to be truncated at the end. The following option controls this behavior.
#
# If aof-load-truncated is set to yes, a truncated AOF file is loaded and
# the Redis server starts emitting a log to inform the user of the event.
# Otherwise if the option is set to no, the server aborts with an error
# and refuses to start. When the option is set to no, the user requires
# to fix the AOF file using the "redis-check-aof" utility before to restart
# the server.
#
# Note that if the AOF file will be found to be corrupted in the middle
# the server will still exit with an error. This option only applies when
# Redis will try to read more data from the AOF file but not enough bytes
# will be found.
aof-load-truncated yes

# Redis can create append-only base files in either RDB or AOF formats. Using
# the RDB format is always faster and more efficient, and disabling it is only
# supported for backward compatibility purposes.
aof-use-rdb-preamble yes

# Redis supports recording timestamp annotations in the AOF to support restoring
# the data from a specific point-in-time. However, using this capability changes
# the AOF format in a way that may not be compatible with existing AOF parsers.
aof-timestamp-enabled no

################################## SLOW LOG ###################################

# The Redis Slow Log is a system to log queries that exceeded a specified
# execution time. The execution time does not include the I/O operations
# like talking with the client, sending the reply and so forth,
# but just the time needed to actually execute the command (this is the only
# stage of command execution where the thread is blocked and can not serve
# other requests in the meantime).
#
# You can configure the slow log with two parameters: one tells Redis
# what is the execution time, in microseconds, to exceed in order for the
# command to get logged, and the other parameter is the length of the
# slow log. When a new command is logged the oldest one is removed from the
# queue of logged commands.

# The following time is expressed in microseconds, so 1000000 is equivalent
# to one second. Note that a negative number disables the slow log, while
# a value of zero forces the logging of every command.
slowlog-log-slower-than 10000

# There is no limit to this length. Just be aware that it will consume memory.
# You can reclaim memory used by the slow log with SLOWLOG RESET.
slowlog-max-len 16

################################ LATENCY MONITOR ##############################

# The Redis latency monitoring subsystem samples different operations
# at runtime in order to collect data related to possible sources of
# latency of a Redis instance.
#
# Via the LATENCY command this information is available to the user that can
# print graphs and obtain reports.
#
# The system only logs operations that were performed in a time equal or
# greater than the amount of milliseconds specified via the
# latency-monitor-threshold configuration directive. When its value is set
# to zero, the latency monitor is turned off.
#
# By default latency monitoring is disabled since it is mostly not needed
# if you don't have latency issues, and collecting data has a performance
# impact, that while very small, can be measured under big load. Latency
# monitoring can easily be enabled at runtime using the command
# "CONFIG SET latency-monitor-threshold <milliseconds>" if needed.
latency-monitor-threshold 0

############################# EVENT NOTIFICATION ##############################

# Redis can notify Pub/Sub clients about events happening in the key space.
# This feature is documented at https://redis.io/topics/notifications
#
# For instance if keyspace events notification is enabled, and a client
# performs a DEL operation on key "foo" stored in the Database 0, two
# messages will be published via Pub/Sub:
#
# PUBLISH __keyspace@0__:foo del
# PUBLISH __keyevent@0__:del foo
#
# It is possible to select the events that Redis will notify among a set
# of classes. Every class is identified by a single character:
#
#  K     Keyspace events, published with __keyspace@<db>__ prefix.
#  E     Keyevent events, published with __keyevent@<db>__ prefix.
#  g     Generic commands (non-type specific) like DEL, EXPIRE, RENAME, ...
#  $     String commands
#  l     List commands
#  s     Set commands
#  h     Hash commands
#  z     Sorted set commands
#  x     Expired events (events generated every time a key expires)
#  e     Evicted events (events generated when a key is evicted for maxmemory)
#  n     New key events (Note: not included in the 'A' class)
#  t     Stream commands
#  d     Module key type events
#  m     Key-miss events (Note: It is not included in the 'A' class)
#  A     Alias for g$lshzxetd, so that the "AKE" string means all the events
#        (Except key-miss events which are excluded from 'A' due to their
#         unique nature).
#
#  The "notify-keyspace-events" takes as argument a string that is composed
#  of zero or multiple characters. The empty string means that notifications
#  are disabled.
#
#  Example: to enable list and generic events, from the point of view of the
#           event name, use:
#
#  notify-keyspace-events Elg
#
#  Example 2: to get the stream of the expired keys subscribing to channel
#             name __keyevent@0__:expired use:
#
#  notify-keyspace-events Ex
#
#  By default all notifications are disabled because most users don't need
#  this feature and the feature has some overhead. Note that if you don't
#  specify at least one of K or E, no events will be delivered.
notify-keyspace-events ""

############################### ADVANCED CONFIG ###############################

# Hashes are encoded using a memory efficient data structure when they have a
# small number of entries, and the biggest entry does not exceed a given
# threshold. These thresholds can be configured using the following directives.
hash-max-listpack-entries 512
hash-max-listpack-value 64

# Lists are also encoded in a special way to save a lot of space.
# The number of entries allowed per internal list node can be specified
# as a fixed maximum size or a maximum number of elements.
# For a fixed maximum size, use -5 through -1, meaning:
# -5: max size: 64 Kb  <-- not recommended for normal workloads
# -4: max size: 32 Kb  <-- not recommended
# -3: max size: 16 Kb  <-- probably not recommended
# -2: max size: 8 Kb   <-- good
# -1: max size: 4 Kb   <-- good
# Positive numbers mean store up to _exactly_ that number of elements
# per list node.
# The highest performing option is usually -2 (8 Kb size) or -1 (4 Kb size),
# but if your use case is unique, adjust the settings as necessary.
list-max-listpack-size -2

# Lists may also be compressed.
# Compress depth is the number of quicklist ziplist nodes from *each* side of
# the list to *exclude* from compression.  The head and tail of the list
# are always uncompressed for fast push/pop operations.  Settings are:
# 0: disable all list compression
# 1: depth 1 means "don't start compressing until after 1 node into the list,
#    going from either the head or tail"
#    So: [head]->node->node->...->node->[tail]
#    [head], [tail] will always be uncompressed; inner nodes will compress.
# 2: [head]->[next]->node->node->...->node->[prev]->[tail]
#    2 here means: don't compress head or head->next or tail->prev or tail,
#    but compress all nodes between them.
# 3: [head]->[next]->[next]->node->node->...->node->[prev]->[prev]->[tail]
# etc.
list-compress-depth 0

# Sets have a special encoding when a set is composed
# of just strings that happen to be integers in radix 10 in the range
# of 64 bit signed integers.
# The following configuration setting sets the limit in the size of the
# set in order to use this special memory saving encoding.
set-max-intset-entries 512

# Sets containing non-integer values are also encoded using a memory efficient
# data structure when they have a small number of entries, and the biggest entry
# does not exceed a given threshold. These thresholds can be configured using
# the following directives.
set-max-listpack-entries 128
set-max-listpack-value 64

# Similarly to hashes and lists, sorted sets are also specially encoded in
# order to save a lot of space. This encoding is only used when the length and
# elements of a sorted set are below the following limits:
zset-max-listpack-entries 128
zset-max-listpack-value 64

# HyperLogLog sparse representation bytes limit. The limit includes the
# 16 bytes header. When a HyperLogLog using the sparse representation crosses
# this limit, it is converted into the dense representation.
#
# A value greater than 16000 is totally useless, since at that point the
# dense representation is more memory efficient.
#
# The suggested value is ~ 3000 in order to have the benefits of
# the space efficient encoding without slowing down too much PFADD,
# which is O(N) with the sparse encoding. The value can be raised to
# ~ 10000 when CPU is not a concern, but space is, and the data set is
# composed of many HyperLogLogs with cardinality in the 0 - 15000 range.
hll-sparse-max-bytes 3000

# Streams macro node max size / items. The stream data structure is a radix
# tree of big nodes that encode multiple items inside. Using this configuration
# it is possible to configure how big a single node can be in bytes, and the
# maximum number of items it may contain before switching to a new node when
# appending new stream entries. If any of the following settings are set to
# zero, the limit is ignored, so for instance it is possible to set just a
# max entries limit by setting max-bytes to 0 and max-entries to the desired
# value.
stream-node-max-bytes 4096
stream-node-max-entries 100

# Active rehashing uses 1 millisecond every 100 milliseconds of CPU time in
# order to help rehashing the main Redis hash table (the one mapping top-level
# keys to values). The hash table implementation Redis uses (see dict.c)
# performs a lazy rehashing: the more operation you run into a hash table
# that is rehashing, the more rehashing "steps" are performed, so if the
# server is idle the rehashing is never complete and some more memory is used
# by the hash table.
#
# The default is to use this millisecond 10 times every second in order to
# actively rehash the main dictionaries, freeing memory when possible.
#
# If unsure:
# use "activerehashing no" if you have hard latency requirements and it is
# not a good thing in your environment that Redis can reply from time to time
# to queries with 2 milliseconds delay.
#
# use "activerehashing yes" if you don't have such hard requirements but
# want to free memory asap when possible.
activerehashing yes

# The client output buffer limits can be used to force disconnection of clients
# that are not reading data from the server fast enough for some reason (a
# common reason is that a Pub/Sub client can't consume messages as fast as the
# publisher can produce them).
#
# The limit can be set differently for the three different classes of clients:
#
# normal -> normal clients including MONITOR clients
# replica -> replica clients
# pubsub -> clients subscribed to at least one pubsub channel or pattern
#
# The syntax of every client-output-buffer-limit directive is the following:
#
# client-output-buffer-limit <class> <hard limit> <soft limit> <soft seconds>
#
# A client is immediately disconnected once the hard limit is reached, or if
# the soft limit is reached and remains reached for the specified number of
# seconds (continuously).
# So for instance if the hard limit is 32 megabytes and the soft limit is
# 16 megabytes / 10 seconds, the client will get disconnected immediately
# if the size of the output buffers reach 32 megabytes, but will also get
# disconnected if the client reaches 16 megabytes and continuously overcomes
# the limit for 10 seconds.
#
# By default normal clients are not limited because they don't receive data
# without asking (in a push way), but just after a request, so only
# asynchronous clients may create a scenario where data is requested faster
# than it can read.
#
# Instead there is a default limit for pubsub and replica clients, since
# subscribers and replicas receive data in a push fashion.
#
# Note that it doesn't make sense to set the replica clients output buffer
# limit lower than the repl-backlog-size config (partial sync will succeed
# and then replica will get disconnected).
# Such a configuration is ignored (the size of repl-backlog-size will be used).
# This doesn't have memory consumption implications since the replica client
# will share the backlog buffers memory.
#
# Both the hard or the soft limit can be disabled by setting them to zero.
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Client query buffers accumulate new commands. They are limited to a fixed
# amount by default in order to avoid that a protocol desynchronization (for
# instance due to a bug in the client) will lead to unbound memory usage in
# the query buffer. However you can configure it here if you have very special
# needs, such us huge multi/exec requests or alike.
#
# client-query-buffer-limit 1gb

# In some scenarios client connections can hog up memory leading to OOM
# errors or data eviction. To avoid this we can cap the accumulated memory
# used by all client connections (all pubsub and normal clients). Once we
# reach that limit connections will be dropped by the server freeing up
# memory. The server will attempt to drop the connections using the most
# memory first. We call this mechanism "client eviction".
#
# Client eviction is configured using the maxmemory-clients setting as follows:
# 0 - client eviction is disabled (default)
#
# A memory value can be used for the client eviction threshold,
# for example:
# maxmemory-clients 1g
#
# A percentage value (between 1% and 100%) means the client eviction threshold
# is based on a percentage of the maxmemory setting. For example to set client
# eviction at 5% of maxmemory:
# maxmemory-clients 5%

# In the Redis protocol, bulk requests, that are, elements representing single
# strings, are normally limited to 512 mb. However you can change this limit
# here, but must be 1mb or greater
#
# proto-max-bulk-len 512mb

# Redis calls an internal function to perform many background tasks, like
# closing connections of clients in timeout, purging expired keys that are
# never requested, and so forth.
#
# Not all tasks are performed with the same frequency, but Redis checks for
# tasks to perform according to the specified "hz" value.
#
# By default "hz" is set to 10. Raising the value will use more CPU when
# Redis is idle, but at the same time will make Redis more responsive when
# there are many keys expiring at the same time, and timeouts may be
# handled with more precision.
#
# The range is between 1 and 500, however a value over 100 is usually not
# a good idea. Most users should use the default of 10 and raise this up to
# 100 only in environments where very low latency is required.
hz 10

# Normally it is useful to have an HZ value which is proportional to the
# number of clients connected. This is useful in order, for instance, to
# avoid too many clients are processed for each background task invocation
# in order to avoid latency spikes.
#
# Since the default HZ value by default is conservatively set to 10, Redis
# offers, and enables by default, the ability to use an adaptive HZ value
# which will temporarily raise when there are many connected clients.
#
# When dynamic HZ is enabled, the actual configured HZ will be used
# as a baseline, but multiples of the configured HZ value will be actually
# used as needed once more clients are connected. In this way an idle
# instance will use very little CPU time while a busy instance will be
# more responsive.
dynamic-hz yes

# When a child rewrites the AOF file, if the following option is enabled
# the file will be fsync-ed every 4 MB of data generated. This is useful
# in order to commit the file to the disk more incrementally and avoid
# big latency spikes.
aof-rewrite-incremental-fsync yes

# When redis saves RDB file, if the following option is enabled
# the file will be fsync-ed every 4 MB of data generated. This is useful
# in order to commit the file to the disk more incrementally and avoid
# big latency spikes.
rdb-save-incremental-fsync yes

# Jemalloc background thread for purging will be enabled by default
jemalloc-bg-thread yes
{{- end }}