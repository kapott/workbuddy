#!/usr/bin/env bash

_run() {
    printf "\n>> %s \n\n" "$1"
    $1
}

runIfExists() {
    if [ -x "$(command -v "$1")" ]; then
        _run "$2"
    fi
}

runIfExists "apt" "sudo apt update -y"
runIfExists "apt" "sudo apt install curl git build-essential ansible -y"
runIfExists "yum" "sudo yum upgrade -y"
runIfExists "yum" "sudo yum install curl ansible -y"

export ANSIBLE_LOG_PATH=/tmp/ansible.log


TEMP_DIR=$(mktemp -d)
ansible-pull -i localhost -U https://github.com/Kapott/workbuddy -d "$TEMP_DIR"
rm -rf "$TEMP_DIR"
