#!/bin/bash
# Trimost-OLLAURA Bridge Fixed v2: Plne funkčný hybridný monolit
# Opravená syntax (únik \[ ), pridané mkdir logs/state, robustnejší check/revive
# Integrácia: trimost (py/go modules) <-> OLLAURA (cybertron/optimus/r4c0/aios/defense/emergent)
# Komunikácia: trimost_api + message_bus + bus.log
# Spúšťa paralelne, monitoruje, revive na fail

set -euo pipefail
trap 'echo "[FAIL] Bridge crash at $LINENO"; revive' ERR

ROOT_TRIMOST="$HOME/trimost"
ROOT_OLLAURA="$HOME/OLLAURA"
LOGS="$ROOT_TRIMOST/logs"
STATE="$ROOT_TRIMOST/state"
PID="$LOGS/bridge.pid"
BUS="$ROOT_OLLAURA/collective/bus.log"

log() { echo "[$(date '+%Y%m%d_%H%M%S')] $1" | tee -a "$LOGS/bridge.log"; }

revive() {
    log "Reviving bridge..."
    pkill -f "trimost|decision|healthcheck|system_monitor|watchdog|cybertron|optimus|r4c0|aios" || true
    rm -f "$PID" "$LOGS"/*.pid
    exec "$0" "$@"
}

check() {
    command -v go >/dev/null || { log "Go missing"; exit 1; }
    command -v python3 >/dev/null || { log "Python missing"; exit 1; }
    [ -d "$ROOT_OLLAURA" ] || { log "OLLAURA dir missing"; exit 1; }
    mkdir -p "$LOGS" "$STATE"
    log "Env OK"
}

compile() {
    log "Compiling Go + C/CPP..."
    if [ -f "$ROOT_TRIMOST/modules/system_monitor.go" ]; then
        go build -o "$ROOT_TRIMOST/modules/system_monitor" "$ROOT_TRIMOST/modules/system_monitor.go"
    fi
    for src in "$ROOT_OLLAURA"/*.c "$ROOT_OLLAURA"/*.cpp "$ROOT_OLLAURA"/cybertron*.c; do
        [ -f "\( src" ] && gcc -O3 -lm -lpthread -o " \){src%.*}" "$src" || log "Compile skip/fail: $src"
    done
    log "Compile done"
}

start_trimost() {
    log "Starting Trimost cores..."
    nohup python3 "$ROOT_TRIMOST/trimost.py" > "$LOGS/trimost_main.log" 2>&1 &
    echo $! > "$LOGS/trimost.pid"
    nohup python3 "$ROOT_TRIMOST/trimost_llm.py" > "$LOGS/trimost_llm.log" 2>&1 &
    echo $! > "$LOGS/trimost_llm.pid"
    nohup python3 "$ROOT_TRIMOST/trimost_api.py" > "$LOGS/api.log" 2>&1 &
    echo $! > "$LOGS/api.pid"
    nohup python3 "$ROOT_TRIMOST/modules/decision_engine.py" > "$LOGS/decision.log" 2>&1 &
    echo $! > "$LOGS/decision.pid"
    nohup python3 "$ROOT_TRIMOST/modules/watchdog.py" > "$LOGS/watchdog.log" 2>&1 &
    echo $! > "$LOGS/watchdog.pid"
    nohup bash "$ROOT_TRIMOST/modules/healthcheck.sh" > "$LOGS/healthcheck.log" 2>&1 &
    echo $! > "$LOGS/health.pid"
    nohup "$ROOT_TRIMOST/modules/system_monitor" > "$LOGS/system_monitor.log" 2>&1 &
    echo $! > "$LOGS/system.pid"
    log "Trimost running"
}

bridge_ollaura() {
    log "Bridging to OLLAURA cores..."
    for sh in "$ROOT_OLLAURA"/optimus_*.sh "$ROOT_OLLAURA"/r4c0_*.sh "$ROOT_OLLAURA"/koranos-*.sh "$ROOT_OLLAURA"/defense_blok*.sh "$ROOT_OLLAURA"/quantum_*.sh; do
        [ -f "$sh" ] && nohup bash "$sh" > "\( LOGS/ollaura_ \)(basename "$sh").log" 2>&1 &
    done
    for py in "$ROOT_OLLAURA"/aios_*.py "$ROOT_OLLAURA"/emergent_*.py "$ROOT_OLLAURA"/aurora_*.py "$ROOT_OLLAURA"/ultron_*.py; do
        [ -f "$py" ] && nohup python3 "$py" > "\( LOGS/ollaura_ \)(basename "$py").log" 2>&1 &
    done
    for bin in "$ROOT_OLLAURA"/cybertron*; do
        [ -x "$bin" ] && nohup "$bin" > "$LOGS/cybertron.log" 2>&1 &
    done
    mkdir -p "$(dirname "$BUS")" && touch "$BUS"
    log "Bridge complete"
}

monitor() {
    while true; do
        for pfile in "$LOGS"/*.pid; do
            [ -f "\( pfile" ] && pid= \)(cat "$pfile") && kill -0 "$pid" 2>/dev/null || revive
        done
        echo "Pulse $(date)" >> "$BUS"
        tail -n1 "$BUS" | grep "Pulse" >/dev/null || revive
        sleep 30
    done
}

main() {
    echo \] > "$PID"
    check
    compile
    start_trimost
    bridge_ollaura
    monitor &
    log "Hybrid bridge LIVE. PID: \[ "
    wait
}

main "$@"
