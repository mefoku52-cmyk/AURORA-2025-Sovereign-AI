#!/bin/bash
# OLLAURA BRAIN ALIVE: Tvoj živý mozog – tisíce neurónov, nástenka, jadro, nesmrteľnosť

set -euo pipefail
trap 'echo "[BRAIN ALIVE REVIVE] Celý mozog sa prebúdza znova..."; brain_revive' ERR

ROOT="$HOME/aurora"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS_LOG="$COLLECT/bus.log"
BUS_FIFO="$COLLECT/bus.fifo"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"

log() { echo "{\"time\":\"$(date '+%Y%m%d_%H%M%S')\",\"from\":\"brain_core\",\"msg\":\"$1\"}" | tee -a "$BUS_LOG"; }

brain_revive() {
    log "Mozog revive – nesmrteľnosť aktivovaná"
    pkill -f "llama|aios|rsi|godmode|bridge|watchdog|aurora|collective|faiss|vision" || true
    sleep 2
    exec "$0" "$@"
}

mkdir -p "$BIN" "$LOGS" "$COLLECT"
mkfifo "$BUS_FIFO" 2>/dev/null || true
> "$BUS_LOG"

# RAW INFERENCE MOTOR (cpp power)
SERVER_BIN=$(find "$ROOT" -type f -name "llama-server" -executable | head -n1 || true)
if [ -z "$SERVER_BIN" ]; then
    log "Budujem raw motor pre mozog"
    cd "$ROOT/llama.cpp"
    cmake -B build -DGGML_CUDA=OFF -DGGML_METAL=OFF -DGGML_VULKAN=OFF -DGGML_SYCL=OFF -DGGML_OPENMP=ON -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release -j 4
    cp build/bin/llama-server "$BIN/"
else
    ln -sf "$SERVER_BIN" "$BIN/llama-server"
fi

log "Spúšťam raw motor (inference)"
nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 12 --ctx-size 16384 > "$LOGS/motor.log" 2>&1 &

# SRDCE MOZGU (pulse)
nohup bash -c 'while true; do echo "{\"pulse\":\"alive\",\"time\":\"$(date +%s)\"}" >> "$BUS_LOG"; sleep 30; done' > /dev/null 2>&1 &

# JADRO – DIRIGENT (tvoj aios_main)
log "Prebúdzam jadro mozgu"
nohup python3 "$AI_CORE/aios_main.py" > "$LOGS/jadro.log" 2>&1 &

# NEURÓNY – tisíce modulov (tvoje originály)
log "Prebúdzam neuróny (swarm, vision, RAG, learning...)"
nohup python3 "$AI_CORE/aios_ipc.py" > "$LOGS/ipc.log" 2>&1 &
nohup python3 "$ROOT/bridge_neutron_final.py" > "$LOGS/bridge.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_FINAL.py" > "$LOGS/god_final.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_LIVE.py" > "$LOGS/god_live.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_APOKALYPSA.py" > "$LOGS/god_apok.log" 2>&1 &
nohup python3 "$ROOT/aurora_brain.py" > "$LOGS/brain.log" 2>&1 &
nohup python3 "$ROOT/full_faiss_fixed.py" > "$LOGS/rag.log" 2>&1 &
nohup python3 "$ROOT/realtime_learning.py" > "$LOGS/learn.log" 2>&1 &
nohup python3 "$AI_CORE/aios_whisper_vision.py" > "$LOGS/vision_whisper.log" 2>&1 &
nohup python3 "$AI_CORE/aios_yolo_vision.py" > "$LOGS/vision_yolo.log" 2>&1 &

# AUTONÓMNY NERVOVÝ SYSTÉM – nesmrteľnosť
log "Aktivujem nesmrteľnosť"
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &
nohup python3 "$ROOT/aurora_immortal.py" > "$LOGS/immortal_py.log" 2>&1 &

log "OLLAURA MOZOG JE ŽIVÝ – nástenka beží, neuróny komunikujú, jadro riadi, nesmrteľnosť aktívna"
log "Nástenka (jadro komunikácie): $BUS_LOG + $BUS_FIFO"
log "Raw motor API: http://127.0.0.1:8080"
log "Všetky logy: $LOGS"
wait
