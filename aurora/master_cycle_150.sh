#!/usr/bin/env bash
# MASTER CYKLUS PRE SPUSTENIE 150 PLNE FUNKČNÝCH AI-AGENTOV (Real Mode)
AGENT_DIR="$HOME/modules_all/agents"
LOG_DIR="$HOME/AIOS/logs/agents"
mkdir -p $LOG_DIR
# Log pre SÚHRN v AIOS/logs
SUPERLOG="$HOME/AIOS/logs/AGENTS_SUPERLOG.log"

echo "$(date '+%H:%M:%S') [SYSTEM_CYCLE] - STARTING FULL AI-AIOs INVOCATION." >> "$SUPERLOG"

# Slúži ako hlavná slučka, ktorá sa spúšťa neustále
while true; do
    START_TIME=$(date +%s.%N)
    # Iterácia od 1 do 150
    for i in $(seq 1 150); do
        BLOCK_NUM=$(printf "%03d" $i)
        AGENT_NAME="B${BLOCK_NUM}.sh"
        AGENT_PATH="$AGENT_DIR/$AGENT_NAME"
        AGENT_LOG="$LOG_DIR/${AGENT_NAME}.log"

        if [ -x "$AGENT_PATH" ]; then
            # REAL MODE: Spustenie agenta. Presmerovanie jeho výstupu do logu.
            # Každý agent by mal bežať krátko (0.1s - 0.5s) a potom sa ukončiť.
            # Zabezpečenie, že sa nebudú hromadiť procesy, je kľúčové.
            nohup bash "$AGENT_PATH" >> "$AGENT_LOG" 2>&1 &
            AGENT_PID=$!
            
            # Nastavenie priority (ak treba) a uloženie PID do master logu
            echo $AGENT_PID >> "$HOME/AIOS/pids/agents.pid"

            # Krátka mikropauza na zabránenie zahltenia
            sleep 0.005 # 5 milisekúnd
        fi
    done
    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc)
    
    # Kľúčové – cyklus by mal spať, ak sa dokončil príliš rýchlo.
    # Napríklad, ak trval 0.75s, počkáme 1s - 0.75s = 0.25s
    MIN_CYCLE_TIME=1.0 
    REMAINING_SLEEP=$(echo "$MIN_CYCLE_TIME - $DURATION" | bc)

    if (( $(echo "$REMAINING_SLEEP > 0" | bc -l) )); then
        sleep $REMAINING_SLEEP
        DURATION=$MIN_CYCLE_TIME
    fi

    # Zápis do hlavného logu
    echo "$(date '+%H:%M:%S') [SYSTEM_CYCLE] - CYCLE COMPLETE. Duration: ${DURATION}s. Next cycle in 0s." >> "$SUPERLOG"
done
