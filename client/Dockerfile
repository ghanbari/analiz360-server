# develop stage
FROM node:11.5-alpine as develop-stage

RUN apk add --no-cache \
        git; \
    mkdir -p /usr/src/client

WORKDIR /usr/src/client

# Prevent the reinstallation of node modules at every changes in the source code
COPY repo/package.json repo/yarn.lock ./
RUN yarn install

ARG APP_API_ENTRYPOINT
ENV APP_API_ENTRYPOINT $APP_API_ENTRYPOINT

COPY ./repo ./


# build stage
FROM develop-stage as build-stage
RUN yarn build


# production stage
FROM nginx:1.17-alpine as production-stage
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build-stage /usr/src/client/dist /var/www/html
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
