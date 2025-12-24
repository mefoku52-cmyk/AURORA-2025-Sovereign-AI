#!/bin/bash
while :; do
    if ! pgrep -f aurora_x_undying.sh >/dev/null; then
        echo "[$(date)] AURORA X zomrela – oživujem" >> ~/aurora/logs/revive.log
        cd ~/aurora && nohup bash aurora_x_undying.sh >> ~/aurora/logs/main.log 2>&1 &
    fi
    sleep 45
done
