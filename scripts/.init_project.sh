#!/usr/bin/env bash

if [[ ! ${PROJECT_DIR} ]]; then
    read -rp "Project directory is not defined, where is it?: " PROJECT_DIR
fi

cd ${PROJECT_DIR}

if [[ ! -f ".env" ]]; then
    echo "Insert value for env variable, if you want use default value, only press enter:"
    while IFS= read -r line;do
        while IFS='=' read -ra VAR; do
            if [[ ${VAR[0]} ]]; then
                read -p "Insert value for ${VAR[0]} [${VAR[1]}]: " REPLY </dev/tty

                if [[ "${REPLY}" ]]; then
                    echo "${VAR[0]}=${REPLY}" | envsubst >> .env
                else
                    echo "${VAR[0]}=${VAR[1]}" | envsubst >> .env
                fi
            fi
        done <<< "$line"
    done < ".env.dist"
fi

docker-compose -f ${PROJECT_DIR}/docker-compose.yml -f ${PROJECT_DIR}/docker-compose.prod.yml pull
docker-compose -f ${PROJECT_DIR}/docker-compose.yml -f ${PROJECT_DIR}/docker-compose.prod.yml build --force-rm
