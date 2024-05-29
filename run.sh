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
runIfExists "apt" "sudo apt install curl build-essential ansible -y"
runIfExists "yum" "sudo yum upgrade -y"
runIfExists "yum" "sudo yum install curl ansible -y"

ansible-pull -t terminal -U https://github.com/Kapott/workbuddy/local-tools.yml 
