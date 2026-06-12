#!/bin/bash

# =====================================================
# WordPress Project Creator 3.1
#
# Autor: Thiago Victor A. Souza
#
# Provisionamento completo de ambiente WordPress
# =====================================================

PROJECT="$1"

if [ -z "$PROJECT" ]; then
    echo ""
    echo "Uso:"
    echo "./create-project.sh nome-do-projeto"
    echo ""
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

TEMPLATE_DIR="${ROOT_DIR}/templates/wordpress-site"
PROJECT_DIR="${ROOT_DIR}/projects/${PROJECT}"

echo ""
echo "====================================="
echo " WordPress Provisioning 3.1"
echo "====================================="
echo ""

# -----------------------------------------------------
# Validações
# -----------------------------------------------------

echo "[0/8] Validando ambiente..."

if ! command -v docker >/dev/null 2>&1; then
    echo "ERRO: Docker não encontrado."
    exit 1
fi

if ! docker network inspect wordpress-network >/dev/null 2>&1; then
    echo "ERRO: Rede docker 'wordpress-network' não existe."
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "ERRO: Template não encontrado."
    echo "$TEMPLATE_DIR"
    exit 1
fi

if [ ! -f "$TEMPLATE_DIR/.env.example" ]; then
    echo "ERRO: .env.example não encontrado."
    exit 1
fi

echo "OK"

# -----------------------------------------------------
# Projeto já existe?
# -----------------------------------------------------

if [ -d "$PROJECT_DIR" ]; then
    echo ""
    echo "ERRO: Projeto '${PROJECT}' já existe."
    echo ""
    exit 1
fi

# -----------------------------------------------------
# Copiar template
# -----------------------------------------------------

echo ""
echo "[1/8] Copiando template..."

mkdir -p "${ROOT_DIR}/projects"

cp -a "$TEMPLATE_DIR" "$PROJECT_DIR"

echo "OK"

# -----------------------------------------------------
# Gerar .env
# -----------------------------------------------------

echo ""
echo "[2/8] Gerando configuração..."

cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"

sed -i "s/^PROJECT_NAME=.*/PROJECT_NAME=${PROJECT}/" "$PROJECT_DIR/.env"
sed -i "s/^PROJECT_DOMAIN=.*/PROJECT_DOMAIN=${PROJECT}.local/" "$PROJECT_DIR/.env"
sed -i "s/^DB_NAME=.*/DB_NAME=${PROJECT}/" "$PROJECT_DIR/.env"
sed -i "s/^DB_USER=.*/DB_USER=${PROJECT}/" "$PROJECT_DIR/.env"
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${PROJECT}123/" "$PROJECT_DIR/.env"

echo "OK"

# -----------------------------------------------------
# Estrutura persistente
# -----------------------------------------------------

echo ""
echo "[3/8] Criando estrutura..."

mkdir -p "$PROJECT_DIR/wordpress"
mkdir -p "$PROJECT_DIR/logs"

echo "OK"

# -----------------------------------------------------
# Backup padrão
# -----------------------------------------------------

cat > "$PROJECT_DIR/backup.conf" << EOF
ENABLED=true
KEEP_DAYS=30
EOF

# -----------------------------------------------------
# Subir containers
# -----------------------------------------------------

echo ""
echo "[4/8] Iniciando containers..."

cd "$PROJECT_DIR" || exit 1

docker compose up -d

if [ $? -ne 0 ]; then
    echo ""
    echo "ERRO ao iniciar containers."
    echo ""
    exit 1
fi

echo "OK"

# -----------------------------------------------------
# Ler senha root do banco
# -----------------------------------------------------

MYSQL_ROOT_PASSWORD=$(grep '^MYSQL_ROOT_PASSWORD=' .env | cut -d '=' -f2)

# -----------------------------------------------------
# Aguarda MariaDB
# -----------------------------------------------------

echo ""
echo "[5/8] Aguardando MariaDB..."

for i in {1..30}; do

    docker exec "${PROJECT}-db" \
        mariadb-admin ping \
        -u root \
        -p"${MYSQL_ROOT_PASSWORD}" \
        >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "OK"
        break
    fi

    sleep 2

done

# -----------------------------------------------------
# Aguarda WordPress
# -----------------------------------------------------

echo ""
echo "[6/8] Aguardando WordPress..."

for i in {1..30}; do

    docker exec "${PROJECT}-wp" \
        wp --info \
        >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "OK"
        break
    fi

    sleep 2

done

# -----------------------------------------------------
# DNS interno
# -----------------------------------------------------

echo ""
echo "[7/8] Validando DNS interno..."

docker exec "${PROJECT}-wp" \
    getent hosts "${PROJECT}-db" \
    >/dev/null 2>&1

DB_OK=$?

docker exec "${PROJECT}-wp" \
    getent hosts "${PROJECT}-redis" \
    >/dev/null 2>&1

REDIS_OK=$?

if [ $DB_OK -eq 0 ] && [ $REDIS_OK -eq 0 ]; then
    echo "OK"
else
    echo "FALHA"
fi

# -----------------------------------------------------
# Health Check
# -----------------------------------------------------

echo ""
echo "[8/8] Health Check..."
echo ""

printf "%-20s %-10s\n" "SERVIÇO" "STATUS"
printf "%-20s %-10s\n" "--------------------" "----------"

if docker ps --format '{{.Names}}' | grep -q "^${PROJECT}-wp$"; then
    printf "%-20s %-10s\n" "WordPress" "OK"
else
    printf "%-20s %-10s\n" "WordPress" "ERRO"
fi

if docker ps --format '{{.Names}}' | grep -q "^${PROJECT}-db$"; then
    printf "%-20s %-10s\n" "MariaDB" "OK"
else
    printf "%-20s %-10s\n" "MariaDB" "ERRO"
fi

if docker ps --format '{{.Names}}' | grep -q "^${PROJECT}-redis$"; then
    printf "%-20s %-10s\n" "Redis" "OK"
else
    printf "%-20s %-10s\n" "Redis" "ERRO"
fi

# -----------------------------------------------------
# Resumo
# -----------------------------------------------------

echo ""
echo "====================================="
echo " Projeto Criado"
echo "====================================="
echo ""

echo "Projeto:"
echo "  ${PROJECT}"

echo ""
echo "URL:"
echo "  http://${PROJECT}.local"

echo ""
echo "Banco:"
echo "  ${PROJECT}"

echo ""
echo "Usuário:"
echo "  ${PROJECT}"

echo ""
echo "Senha:"
echo "  ${PROJECT}123"

echo ""
echo "====================================="
echo " Próximo passo"
echo "====================================="
echo ""

echo "1) Acesse:"
echo "   http://${PROJECT}.local"

echo ""
echo "2) Finalize a instalação do WordPress"

echo ""
echo "3) Execute:"
echo "   ${ROOT_DIR}/tools/setup-wordpress.sh ${PROJECT}"

echo ""