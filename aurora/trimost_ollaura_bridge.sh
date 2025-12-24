#!/bin/bash
# Trimost-OLLAURA Bridge: Integrovaný hybridný systém
# Integruje: trimost (llm/api/decision/watchdog), OLLAURA (cybertron/optimus/r4c0/aios/emergent/defense/fragments)
# Komunikácia: trimost_api.py (API), message_bus.py (IPC/net), bus.log
# Oddelenie: modules (decision/health/system/watchdog), logs/state, core_ai (py/go/cpp)
# Logika: Compile go/cpp, start py/go/sh paralelne, monitor/restart, bridge k llama/ggml
# Syntax: Strict bash, trap revive

set -euo pipefail
trap 'echo "[FAIL] Bridge down at 149"; revive' ERR

ROOT_TRIMOST="/data/data/com.termux/files/home/trimost"
ROOT_OLLAURA="/data/data/com.termux/files/home/OLLAURA"
LOGS="/logs"
STATE="/state"
PID="/bridge.pid"
BUS="/collective/bus.log"

log() { echo "[Wed Dec 24 20:07:25 CET 2025] " | tee -a "/bridge.log"; }

revive() {
    log "Revive: Kill, restart..."
    pkill -f "trimost|decision|healthcheck|system_monitor|watchdog|cybertron|optimus|r4c0|aios" || true
    rm -f "" ""/*.pid
    exec "/data/data/com.termux/files/usr/bin/bash" ""
}

check() {
    command -v go >/dev/null || { log "Go missing"; exit 1; }
    command -v python3 >/dev/null || { log "Python missing"; exit 1; }
    [ -d "" ] || { log "OLLAURA missing"; exit 1; }
    log "OK"
}

compile() {
    log "Compile Go/CPP..."
    go build -o "/modules/system_monitor" "/modules/system_monitor.go"
    # Bridge k OLLAURA cpp (cybertron/ggml/llama)
    for c in ""/*.c ""/*.cpp; do
        [ -f "\( c" ] && gcc -o " \){c%.*}" "" -O3 -lm -lpthread || log "Fail "
    done
    log "Compiled"
}

start_trimost() {
    log "Start Trimost cores..."
    nohup python3 "/trimost.py" > "/trimost_main.log" 2>&1 &
    echo  > "/trimost.pid"
    nohup python3 "/trimost_llm.py" > "/trimost_llm.log" 2>&1 &
    echo  > "/trimost_llm.pid"
    nohup python3 "/trimost_api.py" > "/api.log" 2>&1 &
    echo  > "/api.pid"
    nohup python3 "/modules/decision_engine.py" > "/decision.log" 2>&1 &
    echo  > "/decision.pid"
    nohup python3 "/modules/watchdog.py" > "/watchdog.log" 2>&1 &
    echo  > "/watchdog.pid"
    nohup bash "/modules/healthcheck.sh" > "/healthcheck.log" 2>&1 &
    echo  > "/health.pid"
    nohup "/modules/system_monitor" > "/system_monitor.log" 2>&1 &
    echo  > "/system.pid"
    log "Trimost up"
}

bridge_ollaura() {
    log "Bridge to OLLAURA..."
    # Call OLLAURA cores/sh/py
    for sh in ""/optimus_*.sh ""/r4c0_*.sh ""/koranos-*.sh; do
        [ -f "" ] && nohup bash "" > "\( LOGS/ \)(basename "").log" 2>&1 &
    done
    for py in ""/aios_*.py ""/emergent_*.py; do
        [ -f "" ] && nohup python3 "" > "\( LOGS/ \)(basename "").log" 2>&1 &
    done
    for bin in ""/cybertron*; do
        [ -x "" ] && nohup "" > "/cybertron.log" 2>&1 &
    done
    touch ""
    log "Bridge active"
}

monitor() {
    while true; do
        for p in ""/*.pid; do
            [ -f "\( p" ] && pid= \)(cat "") && kill -0 "" 2>/dev/null || revive
        done
        echo "Pulse" >> ""
        tail -n1 "" | grep "Pulse" || revive
        sleep 30
    done
}

main() {
    echo \[ > ""
    check
    compile
    start_trimost
    bridge_ollaura
    monitor &
    log "Hybrid bridge live. PID: \]"
    wait
}

main ""
