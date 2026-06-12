#!/bin/bash

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PROJECTS_DIR="$ROOT_DIR/projects"

LOG_FILE="$ROOT_DIR/storage/logs/backup.log"

mkdir -p "$ROOT_DIR/storage/logs"

echo "" >> "$LOG_FILE"
echo "==================================" >> "$LOG_FILE"
date >> "$LOG_FILE"

for PROJECT_DIR in "$PROJECTS_DIR"/*; do

    if [ -f "$PROJECT_DIR/backup.conf" ]; then

        source "$PROJECT_DIR/backup.conf"

        if [ "$ENABLED" = "true" ]; then

            PROJECT=$(basename "$PROJECT_DIR")

            echo "Backup: $PROJECT"

            "$ROOT_DIR/tools/backup-project.sh" "$PROJECT" \
                >> "$LOG_FILE" 2>&1

        fi

    fi

done