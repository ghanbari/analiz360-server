# the different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target


# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG PHP_VERSION=7.3
ARG NGINX_VERSION=1.15
ARG VARNISH_VERSION=6.2


# "php" stage
FROM php:${PHP_VERSION}-fpm-alpine AS api_platform_php

# persistent / runtime deps
RUN apk add --no-cache \
		acl \
		file \
		gettext \
		git \
		libpng-dev \
		rabbitmq-c-dev \
	;

ARG APP_ENV
ENV APP_ENV $APP_ENV
ARG AMQP_VERSION=1.9.4
ARG APCU_VERSION=5.1.17
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		libzip-dev \
		zlib-dev \
        freetype \
        libpng \
        libjpeg-turbo \
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
	; \
	\
	docker-php-ext-configure zip --with-libzip; \
	docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
     ; \
	docker-php-ext-install -j$(nproc) \
		intl \
		pdo_mysql \
		zip \
		gd \
	; \
	pecl install \
        amqp-${AMQP_VERSION} \
		apcu-${APCU_VERSION} \
	; \
	pecl clear-cache; \
	docker-php-ext-enable \
		amqp \
		apcu \
		opcache \
		gd \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps; \
	apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY docker/php/conf.d/api-platform.${APP_ENV}.ini $PHP_INI_DIR/conf.d/api-platform.ini
COPY docker/php/php-fpm.d/ /usr/local/etc/php-fpm.d/

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
# install Symfony Flex globally to speed up download of Composer packages (parallelized prefetching)
RUN set -eux; \
	composer global require "symfony/flex" --prefer-dist --no-progress --no-suggest --classmap-authoritative; \
	composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /srv/api

# prevent the reinstallation of vendors at every changes in the source code
COPY repo/composer.json repo/composer.lock repo/symfony.lock ./
RUN set -eux; \
	if [ "$APP_ENV" = "dev" ]; \
        then composer install --dev --no-scripts --no-progress --no-suggest; \
        else composer install --prefer-dist --no-dev --no-scripts --no-progress --no-suggest; \
    fi; \
	composer clear-cache

# copy only specifically what we need
COPY repo/bin bin/
COPY repo/public public/
COPY repo/translations translations/
COPY repo/config config/
COPY docker/php/jwt config/jwt
COPY repo/src src/
COPY repo/templates templates/

# do not use .env files in production
COPY repo/.env ./
RUN composer dump-env ${APP_ENV}; \
	rm .env

RUN set -eux; \
	mkdir -p var/cache var/log; \
	if [ "$APP_ENV" = "dev" ]; \
        then composer dump-autoload --classmap-authoritative; \
            composer run-script --dev post-install-cmd; \
        else composer dump-autoload --classmap-authoritative --no-dev; \
            composer run-script --no-dev post-install-cmd; \
    fi; \
	chmod +x bin/console; sync
# Cache folder size is a little and log folder is mounted
#VOLUME /srv/api/var

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]


# "nginx" stage
# depends on the "php" stage above
FROM nginx:${NGINX_VERSION}-alpine AS api_platform_nginx

COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

WORKDIR /srv/api

COPY --from=api_platform_php /srv/api/public public/


# "varnish" stage
# does not depend on any of the above stages, but placed here to keep everything in one Dockerfile
FROM cooptilleuls/varnish:${VARNISH_VERSION}-alpine AS api_platform_varnish

COPY docker/varnish/conf/default.vcl /usr/local/etc/varnish/default.vcl
