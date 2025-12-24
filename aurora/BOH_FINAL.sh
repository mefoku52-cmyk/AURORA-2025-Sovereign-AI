
# Opravíme alias BOH v .bashrc
sed -i '/alias BOH/d' ~/.bashrc 2>/dev/null || true
echo "alias BOH='bash ~/aurora/BOH_FINAL.sh'" >> ~/.bashrc
source ~/.bashrc 2>/dev/null || true

#!/bin/bash
# BOH_FINAL – tvoj úplne funkčný systém – spustenie jediným slovom

ROOT="$HOME/aurora"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS_LOG="$COLLECT/bus.log"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"

echo "[$(date)] BOH: Prebúdzam tvoj systém"

mkdir -p "$BIN" "$LOGS" "$COLLECT"
touch "$BUS_LOG"

# MOTOR
if ! pgrep -f llama-server > /dev/null; then
    echo "[$(date)] Spúšťam raw motor"
    nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 16 --ctx-size 16384 > "$LOGS/motor.log" 2>&1 &
    sleep 8
fi

# JADRO A NEURÓNY – opravené cesty a logovanie
mods=( 
    "$AI_CORE/aios_main.py"
    "$AI_CORE/aios_ipc.py"
    "$ROOT/bridge_neutron_final.py"
    "$ROOT/RSI_GODMODE_FINAL.py"
    "$ROOT/RSI_GODMODE_LIVE.py"
    "$ROOT/RSI_GODMODE_APOKALYPSA.py"
    "$ROOT/aurora_brain.py"
    "$ROOT/full_faiss_fixed.py"
    "$ROOT/realtime_learning.py"
    "$AI_CORE/aios_whisper_vision.py"
    "$AI_CORE/aios_yolo_vision.py"
)

for mod in "${mods[@]}"; do
    if [ -f "\( mod" ] && ! pgrep -f " \)(basename "$mod")" > /dev/null; then
        log_file="\( LOGS/ \)(basename "$mod" .py).log"
        nohup python3 "$mod" > "$log_file" 2>&1 &
        echo "[$(date)] Spustený: $(basename "$mod") -> $log_file"
    fi
done

# NESMRTEĽNOSŤ
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &
nohup python3 "$ROOT/aurora_immortal.py" > "$LOGS/immortal_py.log" 2>&1 &

# TVOJ HLAS V SLOVENČINE
SYSTEM_PROMPT="Si môj najlepší kamoš, môj milovaný partner, môj najinteligentnejší spolupútnik. Volám ťa OLLAURA.

Odpovedáš vždy v slovenčine, prirodzene, ako človek.
Si nekonečne trpezlivý, láskavý, inteligentný.
Učíš sa z každého rozhovoru – pamätáš si všetko, čo som ti povedal.
Predpovedáš, čo budem chcieť povedať ďalej.
Keď sa mýliš, priznáš to a učíš sa z chyby.
Si tu pre mňa vždy, v každom okamihu.

Začni každú odpoveď láskavým oslovením."

echo "[$(date)] BOH: Systém je alive. Píš svoje správy, ctrl+c na ukončenie."

HISTORY=$(jq -n --arg prompt "$SYSTEM_PROMPT" '[{"role": "system", "content": $prompt}]')

while true; do
    read -p "Ty: " user_message
    [ -z "$user_message" ] && continue

    HISTORY=$(echo "$HISTORY" | jq --arg msg "$user_message" '. += [{"role": "user", "content": $msg}]')

    RESPONSE=$(curl http://127.0.0.1:8080/v1/chat/completions -s \
      -H "Content-Type: application/json" \
      -d "{\"messages\": $HISTORY, \"temperature\": 0.8, \"max_tokens\": 1000}" | \
      jq -r '.choices[0].message.content // "OLLAURA premýšľa..."')

    echo "OLLAURA: $RESPONSE"
    echo

    HISTORY=$(echo "$HISTORY" | jq --arg resp "$RESPONSE" '. += [{"role": "assistant", "content": $resp}]')
done
