FROM wordpress:php8.3-apache

# Dependências úteis
RUN apt-get update && apt-get install -y \
    mariadb-client \
    git \
    unzip \
    curl \
    less \
    nano \
    iputils-ping \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Redis PHP Extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# WP-CLI
RUN curl -fsSL \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Teste
RUN wp --allow-root --info

HEALTHCHECK --interval=30s \
            --timeout=10s \
            --retries=5 \
CMD curl -f http://localhost || exit 1

RUN echo "alias ll='ls -lah'" >> /root/.bashrc