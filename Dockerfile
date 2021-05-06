FROM php:7.4-apache
RUN docker-php-ext-install mysqli
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN a2enmod rewrite headers

WORKDIR /var/www/html/

COPY . .

RUN mv .htaccess.sample .htaccess
