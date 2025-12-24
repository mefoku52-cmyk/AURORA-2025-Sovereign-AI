#!/bin/bash
while :; do
    if ! pgrep -f aurora_x_final.sh >/dev/null 2>&1; then
        echo "[$(date +'%H:%M:%S')] AURORA X MŔTVA – OŽIVUJEM" >> ~/aurora/logs/revive.log
        cd ~/aurora && nohup bash aurora_x_final.sh >/dev/null 2>&1 &
        # dáme im okamžite najvyššiu prioritu
        sleep 3
        pgrep -f aurora_x_final.sh | xargs -I {} ionice -c 1 -n 0 -p {} 2>/dev/null
        pgrep -f aurora_x_final.sh | xargs -I {} renice -n -19 -p {} 2>/dev/null
    fi
    sleep 15
done
