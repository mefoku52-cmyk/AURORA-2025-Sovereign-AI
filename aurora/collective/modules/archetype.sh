#!/usr/bin/env bash
set -euo pipefail
ID="$1"; BUS="$2"; shift 2
TOPICS=("$@")

rand_topic() { echo "${TOPICS[$((RANDOM % ${#TOPICS[@]}))]}"; }
ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }

publish() {
  local topic="$1"; shift
  echo "{\"ts\":\"$(ts)\",\"module\":\"$ID\",\"topic\":\"$topic\",\"msg\":\"$*\"}" >> "$BUS"
}

# Počiatočný handshake do kolektívu
publish "META" "JOIN id=$ID interests=${TOPICS[*]}"

# Listener: reaguje na správy iných (ľahký filter podľa záujmov)
tail -n0 -F "$BUS" 2>/dev/null | \
while read -r line; do
  # ignoruj vlastné echo, reaguj len občas a len na svoje témy
  [[ "$line" == *"\"module\":\"$ID\""* ]] && continue
  for t in "${TOPICS[@]}"; do
    if [[ "$line" == *"\"topic\":\"$t\""* ]]; then
      # 1 z 8 správ spracuj (throttle), inak nechaj plynúť
      if (( RANDOM % 8 == 0 )); then
        # vytiahni stručný obsah
        origin=$(echo "$line" | sed -n 's/.*"module":"\([^"]*\)".*/\1/p')
        msg=$(echo "$line" | sed -n 's/.*"msg":"\([^"]*\)".*/\1/p')
        publish "SYNC" "ACK from=$ID to=$origin on=$t take=\"$msg\""
      fi
    fi
  done
done &

# Periodické publikovanie: modul pozbiera signály a zdieľa
while true; do
  topic=$(rand_topic)
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
      hot=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 3 | tr -s ' ')
      publish WATCHDOG "topcpu=$(echo "$hot" | tr '\n' ';')"
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
      publish ROUTING "bus=append-only strategy=fair"
      ;;
    SYNC)
      publish SYNC "barrier=soft ttl=15s"
      ;;
    META)
      publish META "state=ALIVE"
      ;;
  esac
  sleep $(( 3 + RANDOM % 5 ))
done
