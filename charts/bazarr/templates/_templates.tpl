{{- define "bazarr.postStartScript" -}}
#!/usr/bin/with-contenv bash
APIKEY_FILE="${APIKEY_FILE:-/shared/apikey}"

if [[ -f "${APIKEY_FILE}" ]]; then
  sleep 60
  exit 0
fi

APIKEY_DIR=$(dirname "${APIKEY_FILE}")
if [ ! -d "$APIKEY_DIR" ]; then
  echo "Creating directory '$APIKEY_DIR'"
  mkdir -p "${APIKEY_DIR}"
fi
chmod a+rX "${APIKEY_DIR}"

CONFIG_YAML="${CONFIG_YAML:-/config/config/config.yaml}"

echo "Waiting for file '${CONFIG_YAML}' to exist..."
while [[ ! -f "${CONFIG_YAML}" ]]; do sleep 5; done;

echo "Waiting for bazarr apikey..."
APIKEY=""
while true; do
  APIKEY=$(yq -r '.auth.apikey' "${CONFIG_YAML}")
  if [ -z $APIKEY ]; then
    sleep 5
  else
    echo "Read API key."
    echo -n "${APIKEY}" > "$APIKEY_FILE"
    echo "Wrote API key to file: $APIKEY_FILE"
    chmod a+r "${APIKEY_FILE}"
    break
  fi
done
{{- end }}
