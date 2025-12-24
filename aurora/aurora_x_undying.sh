#!/bin/bash
cd ~/aurora
mkdir -p data logs
termux-wake-lock
termux-notification --title "AURORA X ŽIJE" --id 999 --ongoing --content "učí sa navždy"
while :; do
    if [ $(pgrep -fc "curl|lynx" 2>/dev/null || echo 0) -lt 4 ]; then
        (
            sites=("en.wikipedia.org/wiki/Special:Random" "stallman.org" "kernel.org" "lukesmith.xyz" "news.ycombinator.com")
            url="https://${sites[$RANDOM % 5]}"
            sleep $((20 + RANDOM % 35))
            timeout 40 curl -fsSL --max-time 35 "$url" 2>/dev/null | \
            lynx -stdin -dump -nolist 2>/dev/null | \
            grep -E '^[[:space:]]*[A-Z].*[a-z].*\.' | \
            head -15 >> data/knowledge.txt 2>/dev/null
        ) &
    fi
    sleep 5
done
