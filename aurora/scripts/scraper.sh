#!/bin/bash
cd "$(dirname "$0")/../"
MAX_AGENTS=6
while :; do
    CURRENT=$(jobs -p | wc -l)
    if (( CURRENT < MAX_AGENTS )); then
        (
            URLS=("news.ycombinator.com" "kernel.org" "lobste.rs" "reddit.com/r/linux" "news.slashdot.org" "en.wikipedia.org/wiki/Special:Random")
            URL=${URLS[$RANDOM % ${#URLS[@]}]}
            sleep $((20 + RANDOM % 25))
            timeout 30 curl -sL --max-time 25 "https://$URL" | lynx -dump -nolist | grep '^[[:space:]]*[A-Z]' | head -15 >> data/knowledge.txt
            echo "[$(date +%H:%M)] +knowledge <- $URL" >> logs/scraper.log
        ) &
        renice 19 $! 2>/dev/null || true
    fi
    sleep 7
done
