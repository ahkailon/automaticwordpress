#!/bin/bash

PROJECT=$1
CONTAINER="${PROJECT}-wp"

echo ""
echo "====================================="
echo " WordPress Project Setup"
echo "====================================="
echo ""

if [ -z "$PROJECT" ]; then
echo "Uso: ./setup-wordpress.sh nome-do-projeto"
exit 1
fi

echo "[1/8] Verificando container..."

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
echo "ERRO: Container não encontrado."
exit 1
fi

echo "OK"

echo ""
echo "[2/8] Verificando WP-CLI..."

if ! docker exec "${CONTAINER}"  wp --info >/dev/null 2>&1; then
echo "ERRO: WP-CLI não encontrado."
exit 1
fi

echo "OK"

echo ""
echo "[3/8] Verificando extensão Redis..."

if ! docker exec "${CONTAINER}"  php -m | grep -qi redis; then
echo "ERRO: Extensão Redis não instalada."
exit 1
fi

echo "OK"

echo ""
echo "[4/8] Verificando instalação WordPress..."

if ! docker exec "${CONTAINER}"  wp core is-installed --allow-root >/dev/null 2>&1; then
echo "ERRO: WordPress não instalado."
exit 1
fi

echo "OK"

echo ""
echo "[5/8] Verificando plugin Redis Cache..."

if ! docker exec "${CONTAINER}"  wp plugin is-installed redis-cache --allow-root >/dev/null 2>&1; then
echo "ERRO: Plugin redis-cache não encontrado."
exit 1
fi

echo "OK"

echo ""
echo "[6/8] Ativando plugin Redis..."

docker exec "${CONTAINER}" wp plugin activate redis-cache --allow-root >/dev/null 2>&1

echo "OK"

echo ""
echo "[7/8] Ativando Object Cache..."

docker exec "${CONTAINER}" wp redis enable --allow-root >/dev/null 2>&1

echo "OK"

echo ""
echo "[8/8] Limpando cache..."

docker exec "${CONTAINER}" wp cache flush --allow-root >/dev/null 2>&1

echo "OK"

echo ""
echo "====================================="
echo " STATUS FINAL"
echo "====================================="
echo ""

docker exec "${CONTAINER}"  wp redis status --allow-root 

echo ""
echo "====================================="
echo " Configuração concluída!"
echo "====================================="
echo ""

echo "Projeto: ${PROJECT}"
echo "URL: http://${PROJECT}.local"
echo ""
