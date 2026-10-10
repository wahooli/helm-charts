#!/bin/sh
set -eu

CSI_DIR=${CSI_DIR:-/var/lib/kubelet/plugins/kubernetes.io/csi/seaweedfs-csi-driver}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-300} # 5 minutes
SLEEP_STEP=10                        # check every 10 seconds
terminated=false
LOG_LEVEL=${LOG_LEVEL:-info}  # default log level
export LOG_LEVEL
NODE_ID=${NODE_ID:?NODE_ID must be set}

log() {
  level=$1
  shift
  case "$level" in
    debug)
      if [ "${LOG_LEVEL:-}" = "debug" ]; then
        echo "$(date -Is) [GC] [DEBUG] $*"
      fi
      ;;
    info)
      echo "$(date -Is) [GC] [INFO] $*"
      ;;
    warn)
      echo "$(date -Is) [GC] [WARN] $*" >&2
      ;;
    *)
      echo "$(date -Is) [GC] [UNKNOWN] $*"
      ;;
  esac
}

has_vol_data() {
  for f in "$CSI_DIR"/*/vol_data.json; do
    [ -f "$f" ] && return 0
  done
  return 1
}

# Print volumeHandles of PVs attached to this node by their own CSI driver
list_live_handles() {
  pvs=$(kubectl get --raw /api/v1/persistentvolumes) || return 1
  vas=$(kubectl get --raw /apis/storage.k8s.io/v1/volumeattachments) || return 1
  printf '%s\n%s\n' "$pvs" "$vas" | jq -rs --arg node "$NODE_ID" '
    (.[0].items | map(select(.spec.csi) | {key: .metadata.name, value: .spec.csi}) | from_entries) as $csi
    | .[1].items[]
    | select(.spec.nodeName == $node and .status.attached == true and .spec.source.persistentVolumeName != null)
    | $csi[.spec.source.persistentVolumeName] as $pv
    | select($pv != null and $pv.driver == .spec.attacher)
    | $pv.volumeHandle'
}

# Handle SIGTERM gracefully
trap 'log info "Termination signal received, exiting..."; terminated=true' SIGTERM SIGINT

while true; do
  log info "Running GC loop..."

  live_handles=""
  api_ok=true
  if has_vol_data && ! live_handles=$(list_live_handles); then
    log warn "Failed to list PVs and VolumeAttachments, skipping volumes with vol_data.json"
    api_ok=false
  fi

  # Iterate over all volume dirs
  for voldir in "$CSI_DIR"/*; do
    [ -d "$voldir" ] || continue

    vol_data_file="$voldir/vol_data.json"
    globalmount="$voldir/globalmount"

    volume_handle=""

    if [ -f "$vol_data_file" ]; then
      volume_handle=$(jq -r '.volumeHandle // empty' "$vol_data_file")
    else
      log debug "No vol_data.json found, treating as orphan candidate: $voldir"
    fi

    if [ -n "$volume_handle" ]; then
      if [ "$api_ok" = false ]; then
        log debug "API unavailable, skipping: $voldir"
        continue
      fi
      if printf '%s\n' "$live_handles" | grep -qxF "$volume_handle"; then
        log debug "Skipping live volume: $volume_handle (attached to $NODE_ID)"
        continue
      fi
      log debug "No VolumeAttachment on $NODE_ID for volumeHandle: $volume_handle"
    fi

    if [ -e "$globalmount" ]; then
      if mountpoint -q "$globalmount"; then
        log debug "Skipping mounted globalmount: $globalmount"
        continue
      fi
    fi

    contents=$(find "$voldir" -mindepth 1 ! -name 'vol_data.json' -print -quit 2>/dev/null || true)
    if [ -z "$contents" ]; then
      log info "Removing stale CSI dir: $voldir"
      umount "$globalmount" 2>/dev/null || true
      rm -rf "$voldir"
    else
      log debug "Directory exists and has content, skipping: $voldir"
    fi
  done

  log debug "GC loop complete, sleeping $SLEEP_INTERVAL seconds..."
  
  # Interruptible sleep
  remaining=$SLEEP_INTERVAL
  while [ $remaining -gt 0 ] && [ "$terminated" = false ]; do
    sleep_time=$(( remaining < SLEEP_STEP ? remaining : SLEEP_STEP ))
    sleep "$sleep_time"
    remaining=$(( remaining - sleep_time ))
  done

  # Exit immediately if termination signal received
  [ "$terminated" = true ] && break
done
log info "GC script exiting."
exit 0
