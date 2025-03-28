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

BUDDY_DIR="${1:-$HOME/.config/workbuddy}"
mkdir -p $BUDDY_DIR
ansible-pull -i localhost -U https://github.com/kapott/workbuddy -d "$BUDDY_DIR"

