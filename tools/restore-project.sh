#!/bin/bash

PROJECT=$1
BACKUP_DATE=$2

if [ -z "$PROJECT" ]; then
    echo "Uso:"
    echo "./restore-project.sh projeto data-backup"
    echo ""
    echo "Exemplo:"
    echo "./restore-project.sh biblioteca 2026-06-04_22-50"
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PROJECT_DIR="${ROOT_DIR}/projects/${PROJECT}"

BACKUP_DIR="${ROOT_DIR}/storage/backups/${PROJECT}/${BACKUP_DATE}"

DB_CONTAINER="${PROJECT}-db"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup não encontrado:"
    echo "$BACKUP_DIR"
    exit 1
fi

source "${PROJECT_DIR}/.env"

echo ""
echo "====================================="
echo " RESTORE WORDPRESS"
echo "====================================="
echo ""
echo "Projeto: $PROJECT"
echo "Backup:  $BACKUP_DATE"
echo ""

read -p "Deseja continuar? (s/N): " CONFIRM

if [ "$CONFIRM" != "s" ]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "[1/3] Restaurando banco..."

docker exec -i "$DB_CONTAINER" \
    mariadb \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    "${DB_NAME}" \
    < "${BACKUP_DIR}/database.sql"

echo "Banco restaurado."

echo ""
echo "[2/3] Restaurando uploads..."

rm -rf "${PROJECT_DIR}/wp-content/uploads"

mkdir -p "${PROJECT_DIR}/wp-content/uploads"

tar -xzf "${BACKUP_DIR}/uploads.tar.gz" \
    -C "${PROJECT_DIR}/wp-content"

echo "Uploads restaurados."

echo ""
echo "[3/3] Limpando cache Redis..."

docker exec "${PROJECT}-wp" \
    wp cache flush --allow-root

echo "Cache limpo."

echo ""
echo "Restore concluído."