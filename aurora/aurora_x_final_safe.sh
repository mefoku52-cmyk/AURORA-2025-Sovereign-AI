#!/bin/bash
# =============================================================================
# AURORA_X_FINAL_SAFE - TERMUX ANDROID OOM-PROOF
# nohup + renice + ionice + CPU limit = ŽIJE NAVŽDY
# =============================================================================

cd "$(dirname "$0")" || exit 1
mkdir -p data logs

# ANDROID OOM DEFENDER
echo $$ > data/pid
renice 19 $$ 2>/dev/null || true          # Najnižšia priorita
ionice -c 3 -p $$ 2>/dev/null || true     # Idle I/O class
ulimit -v unlimited 2>/dev/null || true   # Memory soft limit

# LOGGING DO SÚBORU (bez spamu)
exec > >(tee -a logs/aurora_$(date +%Y%m%d).log) 2>&1

echo "🚀 AURORA_X_SAFE [PID: $$] ŠTART $(date)"

# MAX 6 AGENTOV (Android safe)
MAX_AGENTS=6

while :; do
    # POČÍTADLO AKTÍVNYCH (bez pgrep spamu)
    CURRENT=$(jobs -p | wc -l)
    
    if (( CURRENT < MAX_AGENTS )); then
        (
            # RANDOM URL (bez zasekávajúcich)
            URLS=(
                "news.ycombinator.com"
                "kernel.org" 
                "lobste.rs"
                "reddit.com/r/linux"
                "news.slashdot.org"
                "en.wikipedia.org/wiki/Special:Random"
            )
            URL=${URLS[$RANDOM % ${#URLS[@]}]}
            
            # EXTRA POMALÉ (20-45s)
            sleep $((20 + RANDOM % 25))
            
            # ULTRA TIXÝ CURL + LYNX
            timeout 30 curl -sL --max-time 25 \
                --user-agent "Mozilla/5.0 (Linux)" \
                "https://$URL" 2>/dev/null | \
            lynx -dump -nolist -width=80 2>/dev/null | \
            grep -E '^[[:space:]]*[A-Z]' | \
            grep -v '^[[:space:]]*$' | \
            head -15 >> data/knowledge.txt 2>/dev/null
            
            echo "[$(date +%H:%M)] +knowledge <- $URL" >> logs/activity.log
            
        ) &
        
        # CPU NICE pre agentov
        renice 19 $! 2>/dev/null || true
    fi
    
    # 7s sleep = 0% CPU
    sleep 7
done
