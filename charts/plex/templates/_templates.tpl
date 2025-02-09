{{- define "plex.postStartScript" -}}
#!/usr/bin/with-contenv bash
TOKEN_FILE="/shared/token"

if [[ -f "${TOKEN_FILE}" ]]; then
  sleep 60
  exit 0
fi

PREFERENCES_XML="/config/Library/Application Support/Plex Media Server/Preferences.xml"

echo "Waiting for file '${PREFERENCES_XML}' to exist..."
while [[ ! -f "${PREFERENCES_XML}" ]]; do sleep 5; done;

echo "Waiting for plex token..."
PLEX_TOKEN=""
while true; do
  PLEX_TOKEN=$(xmlstarlet sel -T -t -m "/Preferences" -v "@PlexOnlineToken" -n "${PREFERENCES_XML}")
  if [ -z $PLEX_TOKEN ]; then
    sleep 5
  else
    echo "Token registered."
    echo "export PLEX_TOKEN=${PLEX_TOKEN}" > $TOKEN_FILE
    break
  fi
done
{{- end }}


{{- define "plex.metricsEntrypoint" -}}
#!/usr/bin/env sh

TOKEN_FILE="/shared/token"

echo "Waiting for file '${TOKEN_FILE}' to exist..."
while [[ ! -f "${TOKEN_FILE}" ]]; do sleep 5; done;

echo "Waiting for plex server to be ready..."
while true; do
  if wget -q --spider "${PLEX_SERVER}/identity" 2>/dev/null; then
    break
  fi
  sleep 5
done

source /shared/token

exec "$@"
{{- end }}
