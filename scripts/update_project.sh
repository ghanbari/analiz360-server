#!/usr/bin/env bash

if [[ ! ${PROJECT_DIR} ]]; then
    read -rp "Project directory is not defined, where is it?: " PROJECT_DIR
fi

docker-compose -f ${PROJECT_DIR}/docker-compose.yml -f ${PROJECT_DIR}/docker-compose.prod.yml build
docker-compose -f ${PROJECT_DIR}/docker-compose.yml -f ${PROJECT_DIR}/docker-compose.prod.yml up --no-deps -d
