#!/bin/sh
set -eu

CSI_DIR=${CSI_DIR:-/var/lib/kubelet/plugins/kubernetes.io/csi/seaweedfs-csi-driver}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-300} # 5 minutes
SLEEP_STEP=10                        # check every 10 seconds
terminated=false
LOG_LEVEL=${LOG_LEVEL:-info}  # default log level
export LOG_LEVEL

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

# Handle SIGTERM gracefully
trap 'log info "Termination signal received, exiting..."; terminated=true' SIGTERM SIGINT

while true; do
  log info "Running GC loop..."

  # Iterate over all volume dirs
  for voldir in "$CSI_DIR"/*; do
    [ -d "$voldir" ] || continue

    vol_data_file="$voldir/vol_data.json"
    globalmount="$voldir/globalmount"

    volume_handle=""
    driver_name=""

    if [ -f "$vol_data_file" ]; then
      volume_handle=$(jq -r '.volumeHandle' "$vol_data_file")
      driver_name=$(jq -r '.driverName' "$vol_data_file")
    else
      log debug "No vol_data.json found, treating as orphan candidate: $voldir"
    fi

    if [ -n "$volume_handle" ]; then
      log debug "checking from api that does $volume_handle have live attachment..."
      pv_name=$(kubectl get pv -o json | jq -r ".items[] | select(.spec.csi.volumeHandle==\"$volume_handle\") | .metadata.name")
      if [ -z "$pv_name" ]; then
        log debug "No PV found for volumeHandle: $volume_handle"
      else
        log debug "Found PV $pv_name for volumeHandle: $volume_handle"
        attached=$(kubectl get volumeattachment -o json | jq -r ".items[] | select(.spec.source.persistentVolumeName==\"$pv_name\" and .spec.attacher==\"$driver_name\" and .status.attached==true) | .metadata.name")
        if [ -n "$attached" ]; then
          log debug "Skipping live volume: $volume_handle (VolumeAttachment exists: $attached)"
          continue
        fi
      fi
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
