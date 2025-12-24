#!/usr/bin/env bash
set -euo pipefail

# === Farby pre terminál ===
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
RED=$(printf '\033[0;31m')
CYAN=$(printf '\033[0;36m')
RESET=$(printf '\033[0m')

# === Adresáre a logy ===
mkdir -p ~/aurora/logs ~/aurora/editors ~/aurora/collective
CENTRAL_LOG=~/aurora/logs/CENTRAL_MONOLITH.log
AGENTS_LOG=~/aurora/logs/AGENTS_ATTACH.log
WATCHDOG_LOG=~/aurora/logs/AGENTS_WATCHDOG.log
PID_LIST=~/aurora/logs/agents_pids.list

: > "$CENTRAL_LOG"
: > "$AGENTS_LOG"
: > "$WATCHDOG_LOG"
: > "$PID_LIST"

echo "${CYAN}[INFO]$(date +'%F %T') | ULTRON MONOLITH HUB beží na porte 10010 – pripájam agentov...${RESET}" | tee -a "$CENTRAL_LOG"

# === Spustenie agentov ===
find ~/aurora/scripts -type f \( -iname "*agent*.sh" -o -iname "*agent*.py" -o -iname "*ultron*.sh" -o -iname "*monolith*.sh" -o -iname "*core*.sh" \) \
  -print | tee "$AGENTS_LOG" | while read -r agent; do
    echo "${CYAN}[ATTACH]$(date +'%F %T') | Spúšťam $agent -> server 127.0.0.1:10010${RESET}" | tee -a "$CENTRAL_LOG"
    if [[ "$agent" == *.py ]]; then
      nohup python3 "$agent" --server 127.0.0.1:10010 >> "$CENTRAL_LOG" 2>&1 &
    else
      nohup bash "$agent" --server 127.0.0.1:10010 >> "$CENTRAL_LOG" 2>&1 &
    fi
    echo "$!|$agent" >> "$PID_LIST"
done

# === Watchdog: sleduje agentov a reštartuje ak spadnú ===
echo "${YELLOW}[WATCHDOG] Spúšťam sledovanie agentov...${RESET}" | tee -a "$WATCHDOG_LOG"

while true; do
  while IFS="|" read -r pid agentpath; do
    [ -n "$pid" ] || continue
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "${RED}[WATCHDOG] Agent $agentpath (PID=$pid) spadol, reštartujem...${RESET}" | tee -a "$WATCHDOG_LOG" "$CENTRAL_LOG"
      if [[ "$agentpath" == *.py ]]; then
        nohup python3 "$agentpath" --server 127.0.0.1:10010 >> "$CENTRAL_LOG" 2>&1 &
      else
        nohup bash "$agentpath" --server 127.0.0.1:10010 >> "$CENTRAL_LOG" 2>&1 &
      fi
      newpid=$!
      sed -i "s|$pid|$newpid|" "$PID_LIST"
      echo "${GREEN}[WATCHDOG] Agent $agentpath reštartovaný s PID=$newpid${RESET}" | tee -a "$WATCHDOG_LOG" "$CENTRAL_LOG"
    fi
  done < "$PID_LIST"
  sleep 5
done
