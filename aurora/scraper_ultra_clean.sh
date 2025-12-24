#!/usr/bin/env bash
# =============================================================================
# AURORA ULTRA CLEAN V2 - 1000x ČISTEJŠÍ MOZOG
# ZABÍJA VŠETOK CSS/HTML/SPAM - IBA KVALITNÝ TEXT
# =============================================================================

cd ~/aurora || mkdir -p ~/aurora && cd ~/aurora
mkdir -p data logs

MAX_AGENTS=6

ultra_clean_text() {
    local text="$1"
    # 1. ZABIŤ HTML TAGS + SCRIPTS + STYLES
    text=$(echo "$text" | sed -E 's/<(script|style|nav|aside|footer|header)[^>]*>.*?</\u0001>//gi')
    text=$(echo "$text" | sed -E 's/<[^>]+>//g')
    
    # 2. ZABIŤ CSS PROPERTIES + UNITS
    text=$(echo "$text" | sed -E 's/[{}][^{}]*[{}][^{}]*//g')
    text=$(echo "$text" | sed -E 's/([a-z-]*:)[^;{}]*[;}]/ /gi')
    text=$(echo "$text" | sed -E 's/(px|em|rem|%|vw|vh|#[0-9a-f]{3,6}|[0-9]+.[0-9]+)//gi')
    
    # 3. ZABIŤ CSS CLASS NAMES + ID
    text=$(echo "$text" | sed -E 's/(first|second)-column//gi')
    text=$(echo "$text" | sed -E 's/(vid|gnu)-container//gi')
    text=$(echo "$text" | sed -E 's/(margin|padding|width|height|display|position)[^a-z]*//gi')
    
    # 4. NORMALIZÁCIA BIELYCH PRIESTOROV
    text=$(echo "$text" | tr -s '[:space:]' ' ')
    text=$(echo "$text" | sed 's/^ *| *$/ /g')
    
    # 5. ULTRA KVALITNÉ VETSY (min 40 znakov, ľudský text)
    echo "$text" | grep -E '^[A-Z][^.!?]{35,}[.!?]' | \
    grep -viE '(px|em|rem|%|#[0-9a-f]|margin|padding|width|height|display|position|first-column|second-column|vid-container|gnu-linux)' | \
    head -25
}

while :; do
    CURRENT=$(jobs -p | wc -l 2>/dev/null || echo 0)
    
    if (( CURRENT < MAX_AGENTS )); then
        (
            URLS=(
                "news.ycombinator.com"
                "kernel.org"
                "lobste.rs" 
                "reddit.com/r/linux"
                "news.slashdot.org"
                "www.gnu.org"
                "en.wikipedia.org/wiki/Special:Random"
            )
            DOMAIN=${URLS[$RANDOM % ${#URLS[@]}]}
            URL="https://$DOMAIN"
            
            sleep $((12 + RANDOM % 15))
            
            # ULTRA ČISTÝ CURL
            RAW=$(timeout 20 curl -sL --max-time 18 \
                --user-agent "Mozilla/5.0 (Linux; Android 13)" \
                "$URL" 2>/dev/null)
            
            if [[ -n "$RAW" && ${#RAW} -gt 1000 ]]; then
                # ULTRA ČISTENIE
                CLEAN_VETS=$(ultra_clean_text "$RAW")
                
                if [[ -n "$CLEAN_VETS" ]]; then
                    echo "$CLEAN_VETS" >> data/knowledge_ultra.txt
                    LINES=$(echo "$CLEAN_VETS" | wc -l)
                    echo "[$(date +%H:%M)] 🎯 +$LINES viet <- $DOMAIN" >> logs/ultra_clean.log
                fi
            fi
            
        ) &
        renice 19 $! 2>/dev/null || true
    fi
    
    sleep 4  # Ultra nízka CPU
done
