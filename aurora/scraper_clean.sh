#!/usr/bin/env bash
# =============================================================================
# AURORA CLEAN SCRAPER - CSS FILTRE + KVALITNÝ TEXT + STRUČNÉ LOGY
# 100x čistejší mozog, žiadny HTML/CSS bordel
# =============================================================================

cd ~/aurora || mkdir -p ~/aurora && cd ~/aurora
mkdir -p data logs

MAX_AGENTS=8
QUALITY_THRESHOLD=30  # Min znakov pre vetu

# ČISTIČ HTML/CSS bordelu
clean_text() {
    text="$1"
    # Odstráni CSS štýly, HTML tag komentáre, krátke fragmenty
    echo "$text" | \
    sed 's/[{][^}]*[}]//g' | \
    sed 's/[.][^.]{1,5}[.]/./g' | \
    sed 's/[;][^;]{1,10}[;]//g' | \
    sed 's/(px|em|%|#[0-9a-f]{6})//gi' | \
    sed 's/(margin|padding|width|height|display)[^a-zA-Z]*[:]?//gi' | \
    grep -E '^[[:space:]]*[A-Z][^[:space:]]{2,}' | \
    sed 's/[[:space:]]+/ /g' | \
    sed '/^[[:space:]]*$/d'
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
                "en.wikipedia.org/wiki/Special:Random"
                "www.gnu.org"
            )
            URL="https://${URLS[$RANDOM % ${#URLS[@]}]}"
            
            sleep $((15 + RANDOM % 20))
            
            # ULTRA ČISTÝ SCRAPE
            RAW=$(timeout 25 curl -sL --max-time 20 --user-agent "Mozilla/5.0 (Linux)" "$URL" 2>/dev/null)
            
            if [[ -n "$RAW" ]]; then
                # 1. BeautifulSoup-like čistenie cez sed (bez Python)
                CLEANED=$(echo "$RAW" | \
                    sed -E 's/<script[^>]*>.*?</script>//gi' | \
                    sed -E 's/<style[^>]*>.*?</style>//gi' | \
                    sed -E 's/<[^>]+>//g' | \
                    sed 's/[[:space:]]+/ /g' | \
                    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
                    grep -v '^[[:punct:]]*$')
                
                # 2. Kvalitné vety (min 30 znakov, začína veľkým písmenom)
                QUALITY_VET=$(echo "$CLEANED" | tr '[:upper:]' '[:lower:]' | \
                    grep -E '^[a-z][^.!?]{25,}[.!?]' | \
                    sed 's/([.!?])[[:space:]]*([A-Z])/\u0001 \u0002/gi' | \
                    grep -v -E '(px|em|%|#|margin|padding|width|height)' | \
                    head -30)
                
                # 3. Ulož len kvalitné vety
                if [[ -n "$QUALITY_VET" ]]; then
                    echo "$QUALITY_VET" >> data/knowledge_clean.txt
                    LINES_ADDED=$(echo "$QUALITY_VET" | wc -l)
                    echo "[$(date +%H:%M)] ✅ +${LINES_ADDED} ČISTÝCH viet <- $URL" >> logs/scraper_clean.log
                fi
            fi
            
        ) &
        renice 19 $! 2>/dev/null || true
    fi
    
    sleep 5  # 0% CPU
done
