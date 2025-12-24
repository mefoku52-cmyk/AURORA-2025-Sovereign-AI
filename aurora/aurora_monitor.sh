#!/bin/bash
# AURORA MONITOR - AUTO-RESTART + STATUS
cd ~/aurora

while :; do
    PIDFILE="scraper.pid"
    LOGDIR="logs"
    
    if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat $PIDFILE) 2>/dev/null; then
        echo "$(date): 🛑 SCAPER MŘTVE - RESTART"
        pkill -f aurora_x_final_safe 2>/dev/null || true
        nohup ./aurora_x_final_safe.sh > nohup.out 2>&1 &
        echo $! > $PIDFILE
        renice 19 $! 2>/dev/null || true
    fi
    
    # STATUS
    KNOWLEDGE=$(wc -l < data/knowledge.txt 2>/dev/null || echo 0)
    AGENTS=$(jobs -p | wc -l 2>/dev/null || echo 0)
    
    echo "$(date): 🟢 PID=$(cat $PIDFILE 2>/dev/null || echo DEAD) | 🧠 $KNOWLEDGE lines | 👥 $AGENTS agents"
    
    sleep 60
done
