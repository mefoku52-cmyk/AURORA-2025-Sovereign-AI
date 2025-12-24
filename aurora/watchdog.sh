#!/bin/bash
while :; do
    if ! pgrep -f aurora_x_final.sh >/dev/null; then
        cd ~/aurora && nohup bash aurora_x_final.sh >/dev/null 2>&1 &
    fi
    sleep 30
done
