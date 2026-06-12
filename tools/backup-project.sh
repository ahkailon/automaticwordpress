#!/bin/bash

# =====================================================
# Backup WordPress Project
# =====================================================

PROJECT=$1

if [ -z "$PROJECT" ]; then
    echo "Uso: ./backup-project.sh nome-do-projeto"
    exit 1
fi

# --------------------------------------------------
# Diretórios
# --------------------------------------------------

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PROJECT_DIR="${ROOT_DIR}/projects/${PROJECT}"

DATE=$(date +"%Y-%m-%d_%H-%M")

BACKUP_DIR="${ROOT_DIR}/storage/backups/${PROJECT}/${DATE}"

# --------------------------------------------------
# Containers
# --------------------------------------------------

DB_CONTAINER="${PROJECT}-db"

# --------------------------------------------------
# Verificações
# --------------------------------------------------

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Projeto não encontrado:"
    echo "$PROJECT_DIR"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo ""
echo "====================================="
echo " Backup WordPress"
echo "====================================="
echo ""

echo "Projeto: $PROJECT"
echo "Destino: $BACKUP_DIR"

# --------------------------------------------------
# Carregar .env
# --------------------------------------------------

source "${PROJECT_DIR}/.env"

# --------------------------------------------------
# Backup Banco
# --------------------------------------------------

echo ""
echo "[1/3] Backup Banco"

docker exec "$DB_CONTAINER" \
    mariadb-dump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    "${DB_NAME}" \
    > "${BACKUP_DIR}/database.sql"

if [ $? -eq 0 ]; then
    echo "✓ Banco salvo"
else
    echo "✗ Erro no backup do banco"
fi

# --------------------------------------------------
# Backup Uploads
# --------------------------------------------------

echo ""
echo "[2/3] Backup Uploads"

tar -czf "${BACKUP_DIR}/uploads.tar.gz" \
    -C "${PROJECT_DIR}/wordpress/wp-content" \
    uploads

if [ $? -eq 0 ]; then
    echo "✓ Uploads salvos"
else
    echo "✗ Erro no backup dos uploads"
fi

# --------------------------------------------------
# Backup Projeto Completo
# --------------------------------------------------

echo ""
echo "[3/3] Backup Projeto Completo"

tar -czf "${BACKUP_DIR}/full-project.tar.gz" \
    -C "${PROJECT_DIR}" \
    .

if [ $? -eq 0 ]; then
    echo "✓ Projeto salvo"
else
    echo "✗ Erro no backup completo"
fi

# --------------------------------------------------
# Resultado
# --------------------------------------------------

echo ""
echo "====================================="
echo " Backup concluído"
echo "====================================="
echo ""

ls -lh "$BACKUP_DIR"
