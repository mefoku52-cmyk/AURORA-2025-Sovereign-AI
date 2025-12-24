#!/usr/bin/env bash
set -euo pipefail
LOG="$1"
while read -r line; do
  # serialize append s flock
  {
    flock -x 9
    echo "$line" >> "$LOG"
  } 9>"$LOG.lock"
done
