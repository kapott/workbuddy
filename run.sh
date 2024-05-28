#!/bin/sh

sudo apt update -y
sudo apt install wget curl ansible -y

ansible-pull -t terminal -U https://github.com/Kapott/workbuddy/local-tools.yml 
