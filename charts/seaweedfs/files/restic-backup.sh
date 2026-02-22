#!/bin/sh
set -e

# Configuration
OPERATION="${OPERATION:-backup}"  # backup or restore
SEAWEEDFS_PATH="${SEAWEEDFS_PATH:-/mnt/seaweedfs}"
SEAWEEDFS_FILER="${SEAWEEDFS_FILER}"
SEAWEEDFS_MASTER="${SEAWEEDFS_MASTER}"
WEED_BIN="${WEED_BIN:-/shared/weed}"
BACKUP_PATH="${BACKUP_PATH:-${SEAWEEDFS_PATH}/buckets}"
RESTORE_TARGET="${RESTORE_TARGET:-${SEAWEEDFS_PATH}}"
RESTORE_SNAPSHOT="${RESTORE_SNAPSHOT:-latest}"  # 'latest' or specific snapshot ID
BACKUP_TAG="${BACKUP_TAG:-seaweedfs}"
METADATA_DIR=".backup-metadata"
METADATA_FILE="collections.json"
FORCE_RESTORE="${FORCE_RESTORE:-false}"  # Set to 'true' to force restore even if data exists
KEEP_LAST="${KEEP_LAST:-4}"
KEEP_DAILY="${KEEP_DAILY:-7}"
KEEP_WEEKLY="${KEEP_WEEKLY:-4}"
KEEP_MONTHLY="${KEEP_MONTHLY:-6}"

# Mount SeaweedFS FUSE
mount_seaweedfs() {
    mkdir -p "${SEAWEEDFS_PATH}"
    
    # Check if already mounted
    if mountpoint -q "${SEAWEEDFS_PATH}" 2>/dev/null; then
        echo "SeaweedFS already mounted at ${SEAWEEDFS_PATH}"
        return 0
    fi
    
    echo "Mounting SeaweedFS at ${SEAWEEDFS_PATH}..."
    ${WEED_BIN} mount \
        -filer="${SEAWEEDFS_FILER}" \
        -dir="${SEAWEEDFS_PATH}" \
        >/var/log/weed-mount.log 2>&1 &
    
    # Wait for mount to be ready
    echo "Waiting for FUSE mount..."
    for i in $(seq 1 30); do
        if mountpoint -q "${SEAWEEDFS_PATH}" 2>/dev/null; then
            echo "Mount ready!"
            return 0
        fi
        sleep 1
    done
    
    echo "ERROR: Mount failed."
    cat /var/log/weed-mount.log
    return 1
}

# Export collection metadata to JSON
export_metadata() {
    local metadata_dir="${1}/${METADATA_DIR}"
    local metadata_path="${metadata_dir}/${METADATA_FILE}"
    echo "Exporting collection metadata to ${metadata_path}..."
    
    # Create metadata directory
    mkdir -p "${metadata_dir}"
    
    # Use volume.list to extract collection -> replica_placement mapping
    local volume_list=$(${WEED_BIN} shell -master="${SEAWEEDFS_MASTER}" <<EOF
volume.list -v 5
EOF
)
    
    # Parse volume list and extract unique Collection:ReplicaPlacement pairs
    # Format: ReplicaPlacement:001, Collection:name
    # For duplicate collections, keep the highest replication value
    # Skip volumes with empty collection (Collection:,) and .backup-metadata collection
    echo "{" > "${metadata_path}"
    echo "$volume_list" | grep 'Collection:' | grep 'ReplicaPlacement:' | grep -v 'Collection:,' | grep -v 'Collection:\.backup-metadata' | \
        sed -n 's/.*ReplicaPlacement:\([^,]*\).*Collection:\([^,]*\).*/\2 \1/p' | \
        sort -k1,1 -k2,2r | \
        awk '!seen[$1]++ {printf "%s  \"%s\": \"%s\"", (NR>1 ? ",\n" : ""), $1, $2}' >> "${metadata_path}"
    echo "" >> "${metadata_path}"
    echo "}" >> "${metadata_path}"
    
    if [ -s "${metadata_path}" ]; then
        echo "Metadata exported successfully."
        cat "${metadata_path}"
    else
        echo "WARNING: Metadata export appears empty, creating minimal metadata file."
        echo '{}' > "${metadata_path}"
    fi
}

# Parse collection metadata from JSON
parse_metadata() {
    local metadata_path="${1}"
    
    if [ ! -f "${metadata_path}" ]; then
        return 1
    fi
    
    # Parse JSON and return collection replication settings
    # Skip empty collection names (default collection)
    cat "${metadata_path}" | grep -o '"[^"]*"[[:space:]]*:[[:space:]]*"[^"]*"' | \
        sed 's/"//g' | sed 's/[[:space:]]*:[[:space:]]*/=/'
}

# Generate collection configuration commands from metadata
generate_config_commands() {
    local metadata_path="${1}"
    local collections=$(parse_metadata "${metadata_path}")
    
    if [ -z "$collections" ]; then
        return 0
    fi
    
    for entry in $collections; do
        local collection=$(echo "$entry" | cut -d= -f1)
        local replication=$(echo "$entry" | cut -d= -f2)
        
        # Skip empty collection name or empty replication
        if [ -z "$collection" ] || [ -z "$replication" ]; then
            continue
        fi
        
        echo "volume.configure.replication -collectionPattern=\"${collection}\" -replication=\"${replication}\""
    done
}

# Configure collection replication settings
configure_collections() {
    local metadata_path="${1}"
    
    if [ ! -f "${metadata_path}" ]; then
        echo "WARNING: Metadata file not found, skipping collection configuration."
        return 0
    fi
    
    echo "Configuring collection replication settings..."
    
    local config_commands=$(generate_config_commands "${metadata_path}")
    
    if [ -z "$config_commands" ]; then
        echo "No collections to configure."
        return 0
    fi
    
    # Execute commands in lock session
    {
        echo "lock"
        echo "$config_commands"
        echo "unlock"
    } | ${WEED_BIN} shell -master="${SEAWEEDFS_MASTER}"
    
    echo "Collection configuration completed."
}

# Fix replication for entire system (run AFTER data restore)
fix_replication() {
    echo "Fixing replication for entire system..."
    
    # Run volume.fix.replication once for the whole system
    ${WEED_BIN} shell -master="${SEAWEEDFS_MASTER}" <<EOF
lock
volume.fix.replication -apply
unlock
EOF
    
    echo "Replication fix completed."
}

# Configure collections and fix replication in single lock session
configure_and_fix() {
    local metadata_path="${1}"
    echo "Configuring collections and fixing replication in single operation..."
    
    local config_commands=$(generate_config_commands "${metadata_path}" 2>/dev/null || true)
    
    # Execute configuration + fix in single lock session
    {
        echo "lock"
        [ -n "$config_commands" ] && echo "$config_commands"
        echo "volume.fix.replication -apply"
        echo "unlock"
    } | ${WEED_BIN} shell -master="${SEAWEEDFS_MASTER}"
    
    echo "Configuration and replication fix completed."
}

# Initialize restic repository if needed
init_repo() {
    echo "Checking restic repository..."
    if ! restic snapshots >/dev/null 2>&1; then
        echo "Initializing restic repository..."
        restic init
    else
        echo "Repository already initialized."
    fi
}

# Perform backup
do_backup() {
    original_pwd=$(pwd)
    cd "${SEAWEEDFS_PATH}"
    
    # Transform absolute path to relative
    backup_relative="${BACKUP_PATH#${SEAWEEDFS_PATH}/}"
    echo "Starting backup of ${BACKUP_PATH}..."
    
    # Check if backup path exists
    if [ ! -e "${backup_relative}" ]; then
        echo "WARNING: Backup path ${BACKUP_PATH} does not exist. Nothing to backup."
        echo "Exiting gracefully."
        exit 0
    fi
    
    # Export collection metadata before backup
    export_metadata "${backup_relative}"
    
    init_repo
    
    # Backup with tags (using relative path)
    # Note: restic exits with 1 if some files couldn't be read (warnings)
    # We treat that as acceptable since backup still completes
    set +e
    restic backup "${backup_relative}" \
        --tag "${BACKUP_TAG}" \
        --tag "$(date +%Y-%m-%d)"
    backup_exit=$?
    set -e
    
    cd "$original_pwd"

    if [ $backup_exit -eq 3 ]; then
        echo "WARNING: Backup completed with warnings (some files couldn't be read)"
    elif [ $backup_exit -ne 0 ]; then
        echo "ERROR: Backup failed with exit code $backup_exit"
        exit $backup_exit
    else
        echo "Backup completed successfully."
    fi
    
    echo "Applying retention policy..."
    
    # Apply retention policy and prune
    restic forget \
        --tag "${BACKUP_TAG}" \
        --keep-last "${KEEP_LAST}" \
        --keep-daily "${KEEP_DAILY}" \
        --keep-weekly "${KEEP_WEEKLY}" \
        --keep-monthly "${KEEP_MONTHLY}" \
        --prune
    
    echo "Backup finished successfully."
}

# Perform restore
do_restore() {
    original_pwd=$(pwd)
    cd "${RESTORE_TARGET}"
    
    # Transform absolute paths to relative
    backup_relative="${BACKUP_PATH#${SEAWEEDFS_PATH}/}"
    restore_relative="${RESTORE_TARGET#${SEAWEEDFS_PATH}/}"
    # If restore target is exactly SEAWEEDFS_PATH, use current dir
    [ "${restore_relative}" = "${SEAWEEDFS_PATH}" ] && restore_relative="."
    
    echo "Starting restore from backup to ${RESTORE_TARGET}..."
    
    # Check if this is an initial restore (data doesn't exist yet)
    is_initial_restore=false
    if [ ! -e "${backup_relative}" ]; then
        is_initial_restore=true
    elif [ "${FORCE_RESTORE}" != "true" ]; then
        echo "INFO: Backup path ${BACKUP_PATH} already exists."
        echo "Skipping restore (this appears to be an existing installation)."
        echo "Set FORCE_RESTORE=true to restore anyway."
        exit 0
    fi
    
    # List available snapshots
    echo "Available snapshots:"
    restic snapshots --tag "${BACKUP_TAG}"
    
    # Helper function to restore and return metadata path
    restore_metadata() {
        local metadata_dir_relative="${backup_relative}/${METADATA_DIR}"
        local metadata_temp="/tmp/seaweedfs-metadata-$$"
        
        rm -rf "${metadata_temp}"
        mkdir -p "${metadata_temp}"
        
        echo "Attempting to restore metadata from ${metadata_dir_relative}..." >&2
        
        if [ "${RESTORE_SNAPSHOT}" = "latest" ]; then
            restic restore latest --tag "${BACKUP_TAG}" --target "${metadata_temp}" --include "${metadata_dir_relative}" 2>/dev/null || true
        else
            restic restore "${RESTORE_SNAPSHOT}" --target "${metadata_temp}" --include "${metadata_dir_relative}" 2>/dev/null || true
        fi
        
        local metadata_file="${metadata_temp}/${metadata_dir_relative}/${METADATA_FILE}"
        if [ -f "${metadata_file}" ]; then
            echo "${metadata_file}"
            return 0
        else
            rm -rf "${metadata_temp}"
            return 1
        fi
    }
    
    # Configure collection replication BEFORE restore (only during initial restore)
    if [ "$is_initial_restore" = "true" ]; then
        echo "Restoring collection metadata for pre-configuration..."
        if metadata_file=$(restore_metadata); then
            configure_collections "${metadata_file}"
            rm -rf "$(dirname "$(dirname "${metadata_file}")")"  # Clean up /tmp/seaweedfs-metadata-$$
        else
            echo "No metadata file found in backup, skipping pre-configuration."
        fi
    else
        echo "Force restore mode: Skipping pre-configuration (collections already configured)."
    fi
    
    # Restore data (using relative path)
    # Note: Disable errexit to handle restore failures gracefully
    set +e
    if [ "${RESTORE_SNAPSHOT}" = "latest" ]; then
        echo "Restoring latest snapshot..."
        restic restore latest --tag "${BACKUP_TAG}" --target "${restore_relative}"
        restore_exit=$?
    else
        echo "Restoring snapshot ${RESTORE_SNAPSHOT}..."
        restic restore "${RESTORE_SNAPSHOT}" --target "${restore_relative}"
        restore_exit=$?
    fi
    set -e
    
    # Check if restore failed
    if [ $restore_exit -ne 0 ]; then
        echo "ERROR: Restore failed with exit code $restore_exit"
        cd "$original_pwd"
        exit 1
    fi
    
    # Configure and fix replication AFTER data restore (only during initial restore)
    if [ "$is_initial_restore" = "true" ]; then
        # Validate that restore created the backup path
        if [ ! -e "${backup_relative}" ]; then
            echo "ERROR: Restore succeeded but backup path ${BACKUP_PATH} was not created!"
            cd "$original_pwd"
            exit 1
        fi
        
        metadata_path="${backup_relative}/${METADATA_DIR}/${METADATA_FILE}"
        
        # Copy metadata to safe location outside SeaweedFS mount
        if [ -f "${metadata_path}" ]; then
            metadata_backup_dir="/var/lib/seaweedfs-restore-metadata"
            mkdir -p "${metadata_backup_dir}"
            cp "${metadata_path}" "${metadata_backup_dir}/${METADATA_FILE}"
            echo "Metadata backed up to ${metadata_backup_dir}/${METADATA_FILE}"
        fi
        
        if [ -f "${metadata_path}" ]; then
            echo "Metadata file found after restore, configuring and fixing replication..."
            configure_and_fix "${metadata_path}"
        else
            echo "No metadata file found, only running replication fix..."
            fix_replication
        fi
        
        echo "Restore validation: Backup path ${BACKUP_PATH} exists"
    else
        echo "Force restore mode: Skipping post-restore configuration (system already configured)."
    fi
    
    cd "$original_pwd"
    echo "Restore completed successfully."
}

# Main execution (operations only, mount happens before this)
main() {
    mount_seaweedfs

    case "${OPERATION}" in
        backup)
            do_backup
            ;;
        restore)
            do_restore
            ;;
        wait)
            echo "SeaweedFS mounted at ${SEAWEEDFS_PATH}. Waiting indefinitely..."
            echo "Use 'kubectl exec' to access this container."
            tail -f /dev/null
            ;;
        *)
            echo "ERROR: Invalid OPERATION: ${OPERATION}"
            echo "Valid operations: backup, restore, wait"
            exit 1
            ;;
    esac
}

# Auto-detect if script is being sourced vs executed
# When sourced: basename of $0 is the shell name (sh, -sh, ash, etc.)
# When executed: basename of $0 is the script name (entrypoint.sh, backup.sh, etc.)
case "$(basename "$0")" in
    sh|ash|dash|ksh|zsh|busybox|-sh|-ash|-dash|-ksh|-zsh|-busybox)
        RUN_MAIN=false
        ;;
esac

# Run main only if RUN_MAIN is not set to false
if [ "${RUN_MAIN:-true}" != "false" ]; then
    main
fi
