# WordPress Site Template

Template base para criação de novos projetos WordPress utilizando:

* Docker
* WordPress PHP 8.3
* MariaDB 11
* Redis 7
* Traefik
* Mailpit
* Adminer
* WP-CLI

## Criar novo projeto

```bash
cd tools

./create-project.sh nome-do-projeto
```

Exemplo:

```bash
./create-project.sh biblioteca
```

## Subir ambiente

```bash
docker compose up -d
```

## Instalar WordPress

Acesse:

```
http://nome-do-projeto.local
```

## Ativar Redis

```bash
docker exec -it nome-do-projeto-wp wp redis enable --allow-root
```

## Verificar Redis

```bash
docker exec -it nome-do-projeto-wp wp redis status --allow-root
```

## Derrubar ambiente

```bash
docker compose down
```
