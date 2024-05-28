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
runIfExists "apt" "sudo apt install wget curl ansible -y"
runIfExists "yum" "sudo yum update -y"
runIfExists "yum" "sudo yum install wget curl ansible -y"

ansible-pull -t terminal -U https://github.com/Kapott/workbuddy/local-tools.yml 
