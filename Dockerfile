# Use the official PHP image with FPM
FROM php:8.1-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    unzip \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql sockets zip

# Set the working directory
WORKDIR /var/www/slim_app

# Copy the current directory contents into the container
COPY . .

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# Install Composer dependencies
RUN composer install

# Expose port 9000 and start PHP-FPM server
EXPOSE 9000

CMD ["php-fpm"]
