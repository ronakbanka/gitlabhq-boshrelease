#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

# Helper to create a linux user
# Usage:
#  create_user $user $general_info
function create_user() {
  login=$1
  general_info=${2:-'stranger in the night'}
  if [ "$(cat /etc/passwd | grep ^${login}:)" = '' ]
  then
    echo creating user "${login}"
    login_home="/home/${login}"
    # different UID value from git user
    /usr/sbin/adduser \
        --system \
        --shell /bin/bash \
        --gecos "${general_info}" \
        --uid 111 \
        --group \
        --disabled-password \
        --home ${login_home} ${login}

    touch ${login_home}/.bashrc
    chown ${login}:${login} ${login_home}/.bashrc
  fi
}

# Adds a user to a group
# Creates the group if necessary
# add_user_to_group "gitlab" "vcap"
function add_user_to_group() {
  login=$1
  group=$2
  if [ "$(cat /etc/group | grep ^${group}:)" = '' ]
  then
    echo creating group "${group}"
    groupadd ${group}
  fi
  echo adding user "${login}" to group "${group}"
  usermod -a -G ${group} ${login}
}

# Helper for installing priv/pub keypair for target user
# Usage:
#  install_keypair $pubkey $privkey $login $keyname
function install_keypair() {
  pubkey=$1
  privkey=$2
  login=$3
  keyname=$4
  login_home="/home/${login}"
  
  ssh_dir=${login_home}/.ssh
  mkdir -p ${ssh_dir}
  chmod 700 ${ssh_dir}
  chown ${login}:${login} ${ssh_dir}
  
  echo "${pubkey}" > ${ssh_dir}/${keyname}.pub
  chmod 644 ${ssh_dir}/${keyname}.pub
  chown ${login}:${login} ${ssh_dir}/${keyname}.pub
  
  echo "${privkey}" > ${ssh_dir}/${keyname}
  chmod 600 ${ssh_dir}/${keyname}
  chown ${login}:${login} ${ssh_dir}/${keyname}
}
