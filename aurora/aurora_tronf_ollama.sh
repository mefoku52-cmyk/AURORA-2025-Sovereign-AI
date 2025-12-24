#!/bin/bash
set -euo pipefail
trap 'echo "[TRONF REVIVE] Crash at $LINENO"; exec $0' ERR

ROOT="$HOME/aurora"
LLAMA="$ROOT/llama.cpp"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS="$COLLECT/bus.log"

log() { echo "[$(date '+%Y%m%d_%H%M%S')] $1" | tee -a "$LOGS/tronf.log"; }

mkdir -p "$BIN" "$LOGS"

log "Build ultra cpp core..."
cd "$LLAMA" && make clean && make -j LLAMA_CUDA=1 LLAMA_METAL=1 LLAMA_OPENBLAS=1
cp bin/llama-server bin/llama-cli "$BIN/"

log "Start tronf server..."
nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 12 --ctx-size 16384 --n-gpu-layers 99 > "$LOGS/server.log" 2>&1 &

log "Start kernel + godmodes + multimodal + collective..."
nohup python3 "$AI_CORE/aios_main.py" > "$LOGS/kernel.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_FINAL.py" > "$LOGS/god_final.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_LIVE.py" > "$LOGS/god_live.log" 2>&1 &
nohup python3 "$AI_CORE/aios_whisper_vision.py" > "$LOGS/whisper.log" 2>&1 &
nohup python3 "$AI_CORE/aios_yolo_vision.py" > "$LOGS/yolo.log" 2>&1 &
nohup python3 "$ROOT/full_faiss_fixed.py" > "$LOGS/faiss.log" 2>&1 &
nohup python3 "$ROOT/realtime_learning.py" > "$LOGS/realtime.log" 2>&1 &
nohup python3 "$ROOT/bridge_neutron_final.py" > "$LOGS/bridge.log" 2>&1 &
touch "$BUS"

log "Start immortal guard..."
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &

log "AURORA TRONF OLLAMA ŽIJE – ultra rýchly, swarm reasoning, realtime learn, vision, immortal"
log "API: http://127.0.0.1:8080 | Logs: $LOGS | Bus: $BUS"
wait
