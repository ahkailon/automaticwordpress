#!/bin/bash

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PROJECTS_DIR="${ROOT_DIR}/projects"

printf "\n"
printf "%-15s %-8s %-8s %-8s %-8s %-20s\n" \
"PROJETO" "WP" "DB" "REDIS" "CORE" "ULTIMO BACKUP"

printf "%-15s %-8s %-8s %-8s %-8s %-20s\n" \
"---------------" "------" "------" "------" "------" "--------------------"

for PROJECT_DIR in "$PROJECTS_DIR"/*; do

    [ ! -d "$PROJECT_DIR" ] && continue

    PROJECT=$(basename "$PROJECT_DIR")

    WP="OFF"
    DB="OFF"
    REDIS="OFF"
    BACKUP="-"

    # ---------------------------------
    # WordPress Container
    # ---------------------------------

    if docker ps --format '{{.Names}}' \
        | grep -q "^${PROJECT}-wp$"; then

        WP="OK"
    fi

    # ---------------------------------
    # Banco Container
    # ---------------------------------

    if docker ps --format '{{.Names}}' \
        | grep -q "^${PROJECT}-db$"; then

        DB="OK"
    fi

    # ---------------------------------
    # Redis
    # ---------------------------------

    if docker ps --format '{{.Names}}' \
        | grep -q "^${PROJECT}-redis$"; then

        REDIS_STATUS=$(docker exec ${PROJECT}-wp \
            wp redis status --allow-root 2>/dev/null \
            | grep "Status:")

        if echo "$REDIS_STATUS" | grep -q "Connected"; then
            REDIS="OK"
        else
            REDIS="WARN"
        fi
    fi
        # ---------------------------------
    # ---------------------------------
    # WordPress instalado
    # ---------------------------------

    if docker ps --format '{{.Names}}' \
        | grep -q "^${PROJECT}-wp$"; then

        if docker exec ${PROJECT}-wp \
            wp core is-installed --allow-root \
            >/dev/null 2>&1; then

            CORE="OK"
        else
            CORE="NO"
        fi

    fi

    # ---------------------------------
    # Último Backup
    # ---------------------------------

    BACKUP_DIR="${ROOT_DIR}/storage/backups/${PROJECT}"

    if [ -d "$BACKUP_DIR" ]; then

        LAST_BACKUP=$(ls -1 "$BACKUP_DIR" \
            2>/dev/null \
            | sort \
            | tail -n 1)

        [ ! -z "$LAST_BACKUP" ] && BACKUP="$LAST_BACKUP"
    fi

    printf "%-15s %-8s %-8s %-8s %-8s %-20s\n" \
"$PROJECT" "$WP" "$DB" "$REDIS" "$CORE" "$BACKUP"

done

echo ""