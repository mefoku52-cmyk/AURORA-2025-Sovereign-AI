#!/bin/bash
# JEDEN PRÍKAZ NA SPUSTENIE CELEJ OLLAURA PLATFORMY

set -euo pipefail
trap 'echo "[OLLAURA ONE COMMAND REVIVE] Platforma sa prebúdza znova..."; exec "$0"' ERR

ROOT="$HOME/aurora"
BIN="$ROOT/bin"
LOGS="$ROOT/logs"
AI_CORE="$ROOT/PORIADOK/ai_core"
COLLECT="$ROOT/collective"
BUS_LOG="$COLLECT/bus.log"
MODEL="$ROOT/models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"

echo "[$(date)] OLLAURA: Spúšťam celú platformu jediným príkazom"

mkdir -p "$BIN" "$LOGS" "$COLLECT"
> "$BUS_LOG"

# SMART MOTOR
if [ -x "$BIN/llama-server" ]; then
    echo "[$(date)] Motor už existuje – používam ho"
else
    echo "[$(date)] Budujem raw motor (bezpečne)"
    cd "$ROOT/llama.cpp"
    cmake -B build -DGGML_CUDA=OFF -DGGML_METAL=OFF -DGGML_VULKAN=OFF -DGGML_SYCL=OFF -DGGML_OPENMP=ON -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release -j 3
    cp build/bin/llama-server "$BIN/"
fi

echo "[$(date)] Spúšťam raw motor"
nohup "$BIN/llama-server" --model "$MODEL" --port 8080 --threads 12 --ctx-size 16384 > "$LOGS/motor.log" 2>&1 &

echo "[$(date)] Spúšťam jadro a neuróny"
nohup python3 "$AI_CORE/aios_main.py" > "$LOGS/jadro.log" 2>&1 &
nohup python3 "$AI_CORE/aios_ipc.py" > "$LOGS/ipc.log" 2>&1 &
nohup python3 "$ROOT/bridge_neutron_final.py" > "$LOGS/bridge.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_FINAL.py" > "$LOGS/god_final.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_LIVE.py" > "$LOGS/god_live.log" 2>&1 &
nohup python3 "$ROOT/RSI_GODMODE_APOKALYPSA.py" > "$LOGS/god_apok.log" 2>&1 &
nohup python3 "$ROOT/aurora_brain.py" > "$LOGS/brain.log" 2>&1 &
nohup python3 "$ROOT/full_faiss_fixed.py" > "$LOGS/rag.log" 2>&1 &
nohup python3 "$ROOT/realtime_learning.py" > "$LOGS/learn.log" 2>&1 &
nohup python3 "$AI_CORE/aios_whisper_vision.py" > "$LOGS/whisper.log" 2>&1 &
nohup python3 "$AI_CORE/aios_yolo_vision.py" > "$LOGS/yolo.log" 2>&1 &

echo "[$(date)] Spúšťam nesmrteľnosť"
nohup bash "$ROOT/watchdog_undying.sh" > "$LOGS/immortal.log" 2>&1 &
nohup python3 "$ROOT/aurora_immortal.py" > "$LOGS/immortal_py.log" 2>&1 &

echo "[$(date)] OLLAURA JE ŽIVÁ – všetko spustené jediným príkazom"
echo "Sleduj nástenku: tail -f $BUS_LOG"
echo "Sleduj logy: tail -f $LOGS/*.log"
wait
