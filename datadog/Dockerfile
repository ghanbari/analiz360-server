FROM datadog/agent:latest

COPY ./conf.d/php_fpm.yml /etc/datadog-agent/conf.d/php_fpm.d/conf.yaml
COPY ./conf.d/nginx.yml /etc/datadog-agent/conf.d/nginx.d/conf.yaml
COPY ./conf.d/varnish.yml /etc/datadog-agent/conf.d/varnish.d/conf.yaml
COPY ./varnish/ /usr/bin/
RUN chmod 777 /usr/bin/varnishstat && chmod 777 /usr/bin/varnishadm && groupadd -g 999 docker && usermod -a -G docker dd-agent
