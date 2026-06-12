#!/bin/bash

docker compose down -v

rm -rf data/mariadb/*
rm -rf data/redis/*
rm -rf wp-content/uploads/*
rm -rf wp-content/upgrade/*

echo "Projeto resetado."