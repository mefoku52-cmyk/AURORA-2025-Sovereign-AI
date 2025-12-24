import time
import json
import requests
import os
from pathlib import Path

TRIMOST_URL = "http://127.0.0.1:8090/decision"
STATUS_URL = "http://127.0.0.1:8090/status"

LOG_DIR = Path.home() / "aurora" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "aurora_trmost_bridge.log"

def log(msg: str):
    line = f"[AURORA→TRIMOST] {msg}"
    print(line)
    try:
        with LOG_FILE.open("a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass

def get_basic_state():
    # Tu môžeš neskôr napojiť reálne metriky z AURORY
    return {
        "cpu": 0,
        "ram": 0,
        "module": "AURORA",
        "status": "OK",
        "qkd": "",
        "quantum": "",
    }

def check_trimost_online():
    try:
        r = requests.get(STATUS_URL, timeout=5)
        return r.status_code == 200
    except Exception:
        return False

def main_loop():
    log("Spúšťam AURORA ↔ TRIMOST bridge")
    if not check_trimost_online():
        log("TRIMOST nie je online na /status, ale aj tak pokračujem…")

    while True:
        state = get_basic_state()
        try:
            resp = requests.post(
                TRIMOST_URL,
                json={"state": state},
                timeout=30,
            )
            data = resp.json()
            log(f"Stav: {json.dumps(state)}")
            log(f"Rozhodnutie z TRIMOSTU: {json.dumps(data, ensure_ascii=False)}")
        except Exception as e:
            log(f"Chyba pri volaní TRIMOST: {e}")

        time.sleep(10)

if __name__ == "__main__":
    main_loop()
