#!/bin/sh
set -e

MASTER="${SEAWEEDFS_MASTER:?SEAWEEDFS_MASTER is required}"

# Wait for master to be available
echo "Waiting for SeaweedFS master at $MASTER..."
until echo "cluster.ps" | /usr/bin/weed shell -master="$MASTER" > /dev/null 2>&1; do
  echo "Master not ready, retrying in 5s..."
  sleep 5
done
echo "SeaweedFS master is ready"

# Wait for filer to be available (needed for bucket/collection operations)
echo "Waiting for SeaweedFS filer..."
until echo "fs.ls /" | /usr/bin/weed shell -master="$MASTER" > /dev/null 2>&1; do
  echo "Filer not ready, retrying in 5s..."
  sleep 5
done
echo "SeaweedFS filer is ready"

# Process collections
# COLLECTIONS env var format: name:replication per line
if [ -z "$COLLECTIONS" ]; then
  echo "No collections to create"
  exit 0
fi

# Build batched weed shell commands
commands=""
has_replication=false

while IFS=: read -r name replication; do
  [ -z "$name" ] && continue
  commands="${commands}s3.bucket.create -name ${name}
"
done <<EOF
$COLLECTIONS
EOF

# Add lock + replication configuration + unlock as a single locked session
while IFS=: read -r name replication; do
  [ -z "$name" ] && continue
  if [ -n "$replication" ]; then
    if [ "$has_replication" = false ]; then
      commands="${commands}lock
"
      has_replication=true
    fi
    commands="${commands}volume.configure.replication -collectionPattern ${name} -replication ${replication}
"
  fi
done <<EOF
$COLLECTIONS
EOF

if [ "$has_replication" = true ]; then
  commands="${commands}volume.fix.replication -force
unlock
"
fi

echo "Running weed shell commands:"
echo "$commands"
echo "$commands" | /usr/bin/weed shell -master="$MASTER"

echo "Post-up completed successfully"
