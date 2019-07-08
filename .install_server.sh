#!/usr/bin/env bash

export PROJECT_DIR=$(pwd)

#!/usr/bin/env bash

## begin block: set env variables
OS_VERSION=$(lsb_release -sr)
## end block: set env variables

timedatectl set-timezone Asia/Tehran

## begin block: activate ubuntu firewall
ufw allow OpenSSH
ufw allow http
ufw allow https
# allow mercure
ufw allow 1338
ufw --force enable
## end block: activate ubuntu firewall

## begin block: install swap
read -p "Would you like to install swap: " -rn 1 WL_INSTALL_SWAP
echo
if [[ ${WL_INSTALL_SWAP} =~ ^[Yy]$ ]]; then
    read -p "How much swap do you want(per Gig)?: " SWAP_SIZE

    if [[ ! $(grep -q "swapfile.img" "/etc/fstab") ]]
    then
        dd if=/dev/zero of=/swapfile.img bs=1024 count=${SWAP_SIZE}M
        mkswap /swapfile.img

        echo "#swap" >> /etc/fstab
        echo "/swapfile.img swap swap sw 0 0" >> /etc/fstab

        swapon /swapfile.img
    else
        echo "Entry in fstab exists."
    fi
fi

## end block: install swap

## begin block: generate ssh key
if [[ ! -f "/root/.ssh/id_rsa" ]]; then
    echo "Generate ssh key: "
    read -sp 'Password: ' SSH_PASS
    ssh-keygen -t rsa -N ${SSH_PASS} -f /root/.ssh/id_rsa
fi;
## end block: generate ssh key

## begin block: clone project
read -p "Project name: " PROJECT_NAME
read -p "Would you like to clone ${PROJECT_NAME} project(y/n): " -rn 1 WL_CLONE_PROJECT
echo
if [[ ${WL_CLONE_PROJECT} =~ ^[Yy]$ ]]; then
    if [[ ! -d "${PROJECT_DIR}/${PROJECT_NAME}" ]]; then
        echo "Add this code to your repo: "
        cat /root/.ssh/id_rsa.pub

        read -p "If you add ssh key to your repo, then paste ssh path of your repo: " PROJECT_REPO
        if [[ ${PROJECT_REPO} ]]; then
            git clone --recurse-submodules ${PROJECT_REPO} "${PROJECT_DIR}/${PROJECT_NAME}"
        fi
    else
        echo "project folder is exists: ${PROJECT_DIR}/${PROJECT_NAME}"
    fi

    if [[ -d "${PROJECT_DIR}/${PROJECT_NAME}" ]]; then
        echo "change working directory"
        cd "${PROJECT_DIR}/${PROJECT_NAME}"
        export PROJECT_DIR=$(pwd)
        echo "PROJECT_DIR=${PROJECT_DIR}" >> /etc/environment
    else
        echo "project folder is not exists(${PROJECT_DIR}/${PROJECT_NAME})."
    fi
else
    echo "Ok, we assume current folder is project directory"
fi
## end block: clone project

## begin block: install mega.nz
if [[ ! "$(mega-log -v)" ]]; then
    wget "https://mega.nz/linux/MEGAsync/xUbuntu_${OS_VERSION}/amd64/megacmd-xUbuntu_${OS_VERSION}_amd64.deb"
    apt-get -f -y install ./megacmd-xUbuntu_${OS_VERSION}_amd64.deb
    read -p "Your mega email: " MEGA_EMAIL
    read -sp "Your mega pass: " MEGA_PASS
    mega-login ${MEGA_EMAIL} ${MEGA_PASS}
fi
## end block: install mega.nz

## begin block: install docker & docker-compose
if [[ ! "$(docker -v)" ]]; then
    apt-get update
    apt-get -f -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88

    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"

   apt-get update
   apt-get -f -y install docker-ce docker-ce-cli containerd.io
   curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   chmod +x /usr/local/bin/docker-compose
else
    echo "Docker is exists."
fi
## end block: install docker & docker compose

## begin block: install cron task
if [[ -f "${PROJECT_DIR}/scripts/cron.bak" ]]; then
    cat ${PROJECT_DIR}/scripts/cron.bak | envsubst | crontab
    service cron restart
fi
## end block: install cron task

if [[ -f "$PROJECT_DIR/scripts/.init_project.sh" ]]; then
    source "$PROJECT_DIR/scripts/.init_project.sh"
fi

echo "Please reboot system..."
