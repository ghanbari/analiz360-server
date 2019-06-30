FROM nginx:1.15-alpine

RUN mkdir -p /etc/nginx/ssl/
COPY ./ssl/ /etc/nginx/ssl
COPY conf.d /etc/nginx/conf.d/
