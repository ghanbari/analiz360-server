#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ] || [ "$1" = 'bin/console' ]; then
	PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
	if [ "$APP_ENV" != 'prod' ]; then
		PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
	fi
	ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

	mkdir -p var/cache var/log
	setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var
	setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var

    schema="http" && [[ $APP_OVER_HTTPS == true ]]  && schema="https"

	if [ "$APP_ENV" = 'dev' ]; then
	    test -f .env.local || cp .env .env.local
        sed -i.bak "s/^APP_SECRET=\!ChangeMe\!$/APP_SECRET=${APP_SECRET}/" .env.local
        sed -i.bak "s/^APP_HOST=localhost$/APP_HOST=${APP_DOMAIN}/" .env.local
        sed -i.bak "s/^APP_SCHEME=http$/APP_SCHEME=${schema}/" .env.local
        sed -i.bak "s/^APP_BASE_URL=''$/APP_BASE_URL=${APP_BASE_URL}/" .env.local

        sed -i.bak "s;^DATABASE_URL=mysql://db_user:db_password@127.0.0.1:3306/db_name$;DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@db:3306/${MYSQL_DATABASE};" .env.local

        sed -i.bak "s/^MERCURE_JWT_SECRET=ChangeMe$/MERCURE_JWT_SECRET=${APP_MERCURE_KEY}/" .env.local

        sed -i.bak "s;^MESSENGER_TRANSPORT_DSN=amqp://guest:guest@172.17.0.2:5672/%2f/messages$;MESSENGER_TRANSPORT_DSN=amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbit:5672/%2f/messages;" .env.local

        sed -i.bak 's;^#TRUSTED_PROXIES=127.0.0.1,127.0.0.2$;TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/20,127.0.0.1/20;' .env.local
        sed -i.bak "s/^#TRUSTED_HOSTS='\^localhost|example\\\.com\$'$/TRUSTED_HOSTS='^localhost|api|(.*\.)?${APP_DOMAIN}$'/" .env.local
        sed -i.bak "s;explode(',', \$trustedProxies);['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/20', '127.0.0.1/20'];" public/index.php

        composer dump-env ${APP_ENV}
        rm .env.local.bak
        composer install --prefer-dist --dev --no-progress --no-suggest --no-interaction
    else
        sed -i.bak "s/'APP_SECRET' => '\!ChangeMe\!',$/'APP_SECRET' => '${APP_SECRET}',/" .env.local.php
        sed -i.bak "s/'APP_HOST' => 'localhost',$/'APP_HOST' => '${APP_DOMAIN}',/" .env.local.php
        sed -i.bak "s/'APP_SCHEME' => 'http',$/'APP_SCHEME' => '${schema}',/" .env.local.php
        sed -i.bak "s/'APP_BASE_URL' => '',$/'APP_BASE_URL' => '${APP_BASE_URL}',/" .env.local.php

        sed -i.bak "s;'DATABASE_URL' => 'mysql://db_user:db_password@127.0.0.1:3306/db_name',$;'DATABASE_URL' => 'mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@db:3306/${MYSQL_DATABASE}',;" .env.local.php

        sed -i.bak "s/'MERCURE_JWT_SECRET' => 'ChangeMe',$/'MERCURE_JWT_SECRET' => '${APP_MERCURE_KEY}',/" .env.local.php

        sed -i.bak "s;'MESSENGER_TRANSPORT_DSN' => 'amqp://guest:guest@172.17.0.2:5672/%2f/messages',;'MESSENGER_TRANSPORT_DSN' => 'amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@rabbit:5672/%2f/messages',;" .env.local.php

        sed -i.bak "s;'TRUSTED_PROXIES' => '127.0.0.1,127.0.0.2',;'TRUSTED_PROXIES' => '10.0.0.0/8,172.16.0.0/12,192.168.0.0/20,127.0.0.1/20',;" .env.local.php
        sed -i.bak "s/'TRUSTED_HOSTS' => '^localhost$',$/'TRUSTED_HOSTS' => '^localhost|api|cache-proxy|(.*\\\.)?${APP_DOMAIN}$',/" .env.local.php
        sed -i.bak 's/\^ Request::HEADER_X_FORWARDED_HOST//' public/index.php
        sed -i.bak "s;explode(',', \$trustedProxies);['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/20', '127.0.0.1/20'];" public/index.php
	fi

    if [ "$1" != 'bin/console' ]; then
        echo "Waiting for db to be ready..."
        until bin/console doctrine:query:sql "SELECT 1" > /dev/null 2>&1; do
            sleep 1
        done

        bin/console doctrine:migrations:migrate --no-interaction
    fi
fi

exec docker-php-entrypoint "$@"
