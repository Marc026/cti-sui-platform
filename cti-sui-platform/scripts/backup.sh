# scripts/backup.sh
#!/bin/bash
# Backup script for CTI Platform

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/backup_$TIMESTAMP"

echo "Creating backup: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup configuration
echo "Backing up configuration..."
cp .env* "$BACKUP_DIR/" 2>/dev/null || true
cp docker-compose*.yml "$BACKUP_DIR/" 2>/dev/null || true
cp .gitignore "$BACKUP_DIR/" 2>/dev/null || true

# Backup smart contracts
echo "Backing up smart contracts..."
cp -r smart-contracts "$BACKUP_DIR/"

# Backup database (if running)
if docker ps | grep -q postgres; then
    echo "Backing up database..."
    docker exec -t $(docker ps -q -f name=postgres) pg_dumpall -c -U cti_user > "$BACKUP_DIR/database.sql" 2>/dev/null || true
fi

# Backup logs
echo "Backing up logs..."
cp -r logs "$BACKUP_DIR/" 2>/dev/null || true
cp -r api/logs "$BACKUP_DIR/api_logs" 2>/dev/null || true

# Create archive
echo "Creating archive..."
tar -czf "backups/cti_platform_backup_$TIMESTAMP.tar.gz" -C backups "backup_$TIMESTAMP"

# Remove temporary directory
rm -rf "$BACKUP_DIR"

echo "Backup completed: cti_platform_backup_$TIMESTAMP.tar.gz"

# Keep only last 10 backups
ls -t backups/cti_platform_backup_*.tar.gz | tail -n +11 | xargs rm -f 2>/dev/null || true

echo "Backup cleanup completed."