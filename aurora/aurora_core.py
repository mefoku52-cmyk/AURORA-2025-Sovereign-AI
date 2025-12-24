#!/usr/bin/env python3
import os, time, json, threading, subprocess

# ===============================
# AURORA CORE – JEDINÉ JADRO
# ===============================

BASE_DIR = os.path.expanduser("~/aurora")
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")
STATE_FILE = os.path.join(BASE_DIR, "aurora_state.json")

TICK_SECONDS = 5

STATE = {
    "boot_time": time.time(),
    "cycles": 0,
    "modules_loaded": [],
    "last_errors": []
}

LOCK = threading.Lock()


def log(msg):
    print(f"[AURORA_CORE] {msg}")


def save_state():
    with LOCK:
        with open(STATE_FILE, "w") as f:
            json.dump(STATE, f, indent=2)


def load_modules():
    if not os.path.isdir(SCRIPTS_DIR):
        log(f"❌ scripts dir neexistuje: {SCRIPTS_DIR}")
        return []

    modules = []
    for f in sorted(os.listdir(SCRIPTS_DIR)):
        if f.endswith((".aurora", ".py", ".sh")):
            modules.append(f)

    STATE["modules_loaded"] = modules
    log(f"🧩 Načítané moduly: {len(modules)}")
    return modules


def run_module(name):
    path = os.path.join(SCRIPTS_DIR, name)

    try:
        if name.endswith(".py"):
            subprocess.run(["python3", path], timeout=30)

        elif name.endswith(".sh"):
            subprocess.run(["bash", path], timeout=30)

        elif name.endswith(".aurora"):
            # zatiaľ len evidenčné spracovanie
            with open(path) as f:
                content = f.read()
            log(f"📄 .aurora modul {name} spracovaný ({len(content)} znakov)")

    except Exception as e:
        err = {"module": name, "error": str(e), "ts": time.time()}
        STATE["last_errors"].append(err)
        STATE["last_errors"] = STATE["last_errors"][-50:]
        log(f"🔥 Chyba v module {name}: {e}")


def core_loop():
    log("🧠 AURORA CORE ONLINE")
    log(f"📂 Trestný priečinok: {SCRIPTS_DIR}")

    modules = load_modules()

    if not modules:
        log("⚠️ Žiadne moduly – jadro ide naprázdno")

    while True:
        STATE["cycles"] += 1

        for m in modules:
            run_module(m)

        save_state()
        time.sleep(TICK_SECONDS)


if __name__ == "__main__":
    os.makedirs(BASE_DIR, exist_ok=True)
    os.makedirs(SCRIPTS_DIR, exist_ok=True)
    core_loop()
