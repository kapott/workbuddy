#!/usr/bin/env bash

pidof dunst && pkill dunst
dunst &

notify-send "Dunst."