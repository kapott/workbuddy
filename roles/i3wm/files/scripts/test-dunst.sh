#!/usr/bin/env bash

pidof dunst && killall dunst
dunst &

notify-send "Test message for dunst."