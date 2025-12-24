#!/usr/bin/env bash
set -euo pipefail
ID="$1"; FIFO="$2"; shift 2
TOPICS=("$@")

ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }
pick() { echo "${TOPICS[$((RANDOM % ${#TOPICS[@]}))]}"; }

publish() {
  local topic="$1"; shift
  printf '{"ts":"%s","module":"%s","topic":"%s","msg":"%s"}\n' "$(ts)" "$ID" "$topic" "$*" > "$FIFO"
}

# Počiatočný JOIN
publish META "JOIN interests=${TOPICS[*]}"

# Ľahké čítanie kolektívu (bez vlastného echo): periodická reakcia na signál SYNC/ALERTS
# Aby sme nezakladali ďalšie tail-y, len cyklujeme a občas vyšleme ACK
acktick=$((RANDOM % 5 + 5))

count=0
while true; do
  topic=$(pick)
  case "$topic" in
    RAM)
      used=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int((t-a)/1024)}' /proc/meminfo 2>/dev/null || echo 0)
      publish RAM "used=${used}MB"
      ;;
    CPU)
      load=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)
      publish CPU "load=${load}"
      ;;
    NET)
      estab=$(ss -tn 2>/dev/null | grep ESTAB | wc -l || echo 0)
      publish NET "established=${estab}"
      ;;
    HEARTBEAT)
      publish HEARTBEAT "pulse=♥"
      ;;
    WATCHDOG)
      top=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 3 | tr -s ' ' | tr '\n' ';')
      publish WATCHDOG "topcpu=${top}"
      ;;
    BACKUP)
      publish BACKUP "state=scheduled interval=24h"
      ;;
    SENSOR)
      temp=""
      [[ -f /sys/class/thermal/thermal_zone0/temp ]] && temp="$(($(cat /sys/class/thermal/thermal_zone0/temp)/1000))C"
      publish SENSOR "cpu_temp=${temp:-unknown}"
      ;;
    EVENTS)
      publish EVENTS "tick=$(date +%s)"
      ;;
    ALERTS)
      suspects=$(ps -e --no-headers | grep -E "nc|netcat|nmap|hydra|john" | wc -l || echo 0)
      lvl=$([[ "$suspects" -gt 0 ]] && echo "RED" || echo "GREEN")
      publish ALERTS "suspects=${suspects} level=${lvl}"
      ;;
    MEMORY)
      publish MEMORY "collective_state=coherent"
      ;;
    ROUTING)
      publish ROUTING "bus=fifo strategy=serialized"
      ;;
    SYNC)
      publish SYNC "barrier=soft ttl=15s"
      ;;
    META)
      publish META "state=ALIVE"
      ;;
  esac

  count=$((count+1))
  if (( count % acktick == 0 )); then
    publish SYNC "ACK from=${ID}"
    acktick=$((RANDOM % 7 + 7))
  fi

  # Jitter spánku na rozloženie záťaže
  sleep $(( 2 + RANDOM % 4 ))
done
