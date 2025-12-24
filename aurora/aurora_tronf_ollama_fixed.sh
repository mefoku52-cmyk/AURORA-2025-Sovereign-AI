#!/bin/bash
set -euo pipefail
trap 'echo "[TRONF REVIVE] Crash at $LINENO"; exec $0' ERR

ROOT="$HOME/aurora"
LLAMA="$ROOT/llama.cpp"
BUILD="$LLAMA/build"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS="$COLLECT/bus.log"

log() { echo "[$(date '+%Y%m%d_%H%M%S')] TRONF: $1" | tee -a "$LOGS/tronf.log"; }

mkdir -p "$BIN" "$LOGS" "$BUILD"

log "Build llama.cpp cez CMake (modern way)..."
cd "$LLAMA"
git pull || true
cmake -B "$BUILD" -DGGML_CUDA=ON -DGGML_METAL=ON -DGGML_OPENBLAS=ON -DGGML_VULKAN=ON -DGGML_SYCL=ON
cmake --build "$BUILD" --config Release -j $(nproc)
cp "$BUILD/bin/llama-server" "$BUILD/bin/llama-cli" "$BUILD/bin/llama-quantize" "$BIN/" 2>/dev/null || cp "$BUILD"/llama-* "$BIN/"

log "Start ultra tronf server..."
nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 16 --ctx-size 16384 --n-gpu-layers 99 --parallel 4 > "$LOGS/server.log" 2>&1 &

log "Start kernel + godmodes swarm + multimodal + realtime..."
nohup python3 "$AI_CORE/aios_main.py" > "$LOGS/kernel.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_FINAL.py" > "$LOGS/god_final.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_LIVE.py" > "$LOGS/god_live.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_APOKALYPSA.py" > "$LOGS/god_apok.log" 2>&1 &
nohup python3 "$AI_CORE/aios_whisper_vision.py" > "$LOGS/whisper.log" 2>&1 &
nohup python3 "$AI_CORE/aios_yolo_vision.py" > "$LOGS/yolo.log" 2>&1 &
nohup python3 "$ROOT/full_faiss_fixed.py" > "$LOGS/faiss.log" 2>&1 &
nohup python3 "$ROOT/realtime_learning.py" > "$LOGS/realtime.log" 2>&1 &
nohup python3 "$ROOT/aurora_brain.py" > "$LOGS/brain.log" 2>&1 &
nohup python3 "$ROOT/bridge_neutron_final.py" > "$LOGS/bridge.log" 2>&1 &
mkdir -p "$COLLECT" && touch "$BUS"

log "Start immortal guard..."
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &
nohup python3 "$ROOT/aurora_immortal.py" > "$LOGS/immortal_py.log" 2>&1 &

log "AURORA TRONF OLLAMA FIXED ŽIJE – CMake build, ultra accel, swarm godmodes, vision, realtime RAG, immortal revive"
log "API: http://127.0.0.1:8080 | Logs: $LOGS | Bus: $BUS | Bin: $BIN"
wait
