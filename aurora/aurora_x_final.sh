#!/bin/bash
cd "$(dirname "$0")"

# Maximálne 8 agentov naraz – Android to už nezabije
MAX_AGENTS=8

# Každý agent čaká 15–30 sekúnd pred ďalším requestom
while :; do
    CURRENT=$(pgrep -fc "curl|lynx" | wc -l)
    
    if (( CURRENT < MAX_AGENTS )); then
        (
            URLS=("news.ycombinator.com" "stallman.org" "kernel.org" "lukesmith.xyz" "en.wikipedia.org/wiki/Special:Random")
            URL=${URLS[\( RANDOM % \){#URLS[@]}]}
            
            # Veľmi pomaly – 15 až 40 sekúnd medzi requestmi
            sleep $((15 + RANDOM % 25))
            
            # Stiahne a vyčistí – ticho, bez výpisu
            timeout 60 curl -sL --max-time 45 "https://$URL" 2>/dev/null | \
            lynx -stdin -dump -nolist 2>/dev/null | \
            grep -E '^[[:space:]]*[A-Z].*\.' | \
            head -20 >> data/knowledge.txt 2>/dev/null
            
        ) &
    fi
    
    # Hlavný loop spí 5 sekúnd – žerie 0 CPU
    sleep 5
done
