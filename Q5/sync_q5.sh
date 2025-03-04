#!/usr/bin/env bash
# sync_q5.sh - Copy files created in each container to the host and log the details.

# Log file for synchronization details.
LOGFILE="container_sync.log"

# Directory on the host where container files will be copied.
HOST_SYNC_DIR="Q5_sync"

# Create a directory to store synced files if it doesn't exist.
mkdir -p "$HOST_SYNC_DIR"

# List of container names to sync from.
containers=(q5-container1 q5-container2)

# Clear previous log file.
: > "$LOGFILE"

for container in "${containers[@]}"; do
  echo "Processing container: $container" | tee -a "$LOGFILE"
  
  # Create a folder for this container's files on the host.
  DEST="$HOST_SYNC_DIR/$container"
  mkdir -p "$DEST"
  
  # Use sudo to copy the contents of /app from the container to DEST.
  # Note: If DEST already exists, docker cp will copy the contents of /app directly into DEST.
  sudo docker cp "$container":/app "$DEST"
  
  # Log the container's file listing (inside the copied destination folder).
  echo "Files in container $container:" | tee -a "$LOGFILE"
  ls -la "$DEST" | tee -a "$LOGFILE"
  
  # Log the contents of 5_output.txt if it exists.
  if [ -f "$DEST/5_output.txt" ]; then
    echo "Contents of 5_output.txt:" | tee -a "$LOGFILE"
    cat "$DEST/5_output.txt" | tee -a "$LOGFILE"
  fi
  
  echo "----------------------------------------" | tee -a "$LOGFILE"
done

echo "Synchronization complete. Log saved to $LOGFILE"
