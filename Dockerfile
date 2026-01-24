# ---- Build stage (PHP + Composer + Node) ----
FROM php:8.4-cli-alpine AS build

# Install system deps + Node + npm (needed for Vite build)
RUN apk add --no-cache \
    bash git unzip libzip-dev icu-dev oniguruma-dev \
    nodejs npm

# PHP extensions commonly needed by Laravel artisan commands
RUN docker-php-ext-install intl zip

WORKDIR /app

# Copy app source
COPY . .

# Laravel needs these directories during composer/artisan scripts
RUN mkdir -p bootstrap/cache storage/framework/cache storage/framework/sessions storage/framework/views storage/logs \
    && chmod -R 777 bootstrap/cache storage

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies (runs artisan package:discover)
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# If your build complains about APP_KEY missing, uncomment these 2 lines:
# RUN cp .env.example .env
# RUN php artisan key:generate --force

# Install JS deps + build frontend (Wayfinder runs php artisan, so PHP must exist here)
RUN npm ci && npm run build

# ---- Runtime stage (Nginx + PHP-FPM) ----
FROM php:8.4-fpm-alpine

RUN apk add --no-cache nginx supervisor bash icu-dev oniguruma-dev libzip-dev \
    && docker-php-ext-install pdo pdo_mysql intl zip \
    && mkdir -p /run/nginx

WORKDIR /var/www/html

# Copy the entire built app (includes vendor + public/build) from build stage
COPY --from=build /app /var/www/html

# Copy configs
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor.d/webapp.ini

# Correct runtime permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["/usr/bin/supervisord","-n"]
