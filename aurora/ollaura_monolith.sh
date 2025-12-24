#!/bin/bash
# OLLAURA MONOLITH: Tvoj originál AI OS – kernel, bus, godmodes, vision, realtime, immortal
# Tvoj aios kernel riadi všetko, llama.cpp len raw cpp inference accelerator (napojený cez API + bus)

set -euo pipefail
trap 'echo "[OLLAURA REVIVE] Crash at $LINENO"; ollaura_revive' ERR

ROOT="$HOME/aurora"
LLAMA="$ROOT/llama.cpp"
BUILD="$LLAMA/build"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS="$COLLECT/bus.log"

log() { echo "[$(date '+%Y%m%d_%H%M%S')] OLLAURA: $1" | tee -a "$LOGS/ollaura.log"; }

ollaura_revive() {
    log "Ollaura revive – tvoj kernel eternal..."
    pkill -f "llama|aios|rsi|godmode|bridge|watchdog|aurora|collective|faiss|vision|cybertron|optimus|koran|r4c0" || true
    exec "$0" "$@"
}

mkdir -p "$BIN" "$LOGS" "$BUILD"

log "Build raw cpp inference accelerator pre OLLAURA kernel"
cd "$LLAMA"
git pull || true
rm -rf "$BUILD"
cmake -B "$BUILD" -DGGML_CUDA=OFF -DGGML_METAL=OFF -DGGML_VULKAN=OFF -DGGML_SYCL=OFF -DGGML_OPENMP=ON -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD" --config Release -j $(nproc)
cp "$BUILD/bin/llama-server" "$BUILD/bin/llama-cli" "$BIN/" 2>/dev/null || cp "$BUILD"/llama-* "$BIN/"

log "Start raw inference accelerator"
nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 16 --ctx-size 16384 > "$LOGS/inference.log" 2>&1 &

log "Start tvoj OLLAURA kernel + bus + godmodes + vision + realtime + collective"
nohup python3 "$AI_CORE/aios_main.py" > "$LOGS/kernel.log" 2>&1 &
nohup python3 "$AI_CORE/aios_ipc.py" > "$LOGS/ipc.log" 2>&1 &
nohup python3 "$ROOT/bridge_neutron_final.py" > "$LOGS/bridge.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_FINAL.py" > "$LOGS/god_final.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_LIVE.py" > "$LOGS/god_live.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_APOKALYPSA.py" > "$LOGS/god_apok.log" 2>&1 &
nohup python3 "$ROOT/aurora_brain.py" > "$LOGS/brain.log" 2>&1 &
nohup python3 "$ROOT/full_faiss_fixed.py" > "$LOGS/faiss.log" 2>&1 &
nohup python3 "$ROOT/realtime_learning.py" > "$LOGS/realtime.log" 2>&1 &
nohup python3 "$AI_CORE/aios_whisper_vision.py" > "$LOGS/whisper.log" 2>&1 &
nohup python3 "$AI_CORE/aios_yolo_vision.py" > "$LOGS/yolo.log" 2>&1 &
mkdir -p "$COLLECT" && touch "$BUS"

log "Start tvoj OLLAURA immortal guard"
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &
nohup python3 "$ROOT/aurora_immortal.py" > "$LOGS/immortal_py.log" 2>&1 &

log "OLLAURA ŽIJE – tvoj originál kernel bus plne ovláda raw cpp power"
log "Inference API (pre tvoj kernel): http://127.0.0.1:8080 | Tvoj bus: $BUS | Logs: $LOGS"
wait
