#!/bin/bash

PROJECT=$1

if [ -z "$PROJECT" ]; then
    echo "Uso: ./destroy-project.sh projeto"
    exit 1
fi

read -p "Remover projeto $PROJECT? (s/N): " CONFIRM

if [ "$CONFIRM" != "s" ]; then
    exit 0
fi

rm -rf "../projects/$PROJECT"

echo "Projeto removido."