FROM php:8.2-fpm-alpine3.19

RUN apk add --no-cache \
    git \
    curl \
    libzip-dev \
    unzip \
    oniguruma-dev \
    mysql-client \
    autoconf \
    g++ \
    make \
    linux-headers

RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    bcmath \
    zip \
    pcntl \
    opcache

RUN pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf g++ make linux-headers

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY docker/php.ini /usr/local/etc/php/conf.d/garageflow.ini

WORKDIR /var/www/html

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
