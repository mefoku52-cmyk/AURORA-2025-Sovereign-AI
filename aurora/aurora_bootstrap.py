#!/usr/bin/env python3
import os
import subprocess
import time
import threading

home = os.path.expanduser("~")

modules = {
    "Aurora Central Brain": os.path.join(home, "aurora", "aurora_central_brain.py"),
    "Aurora v10": os.path.join(home, "aurora", "aurora_v10.py"),
    "Kometa Kernel": os.path.join(home, "aurora", "kometa_kernel.py"),
}

def start_module(name, path):
    print(f"Spúšťam {name} ...")
    try:
        proc = subprocess.Popen(["python3", path])
        return proc
    except Exception as e:
        print(f"[!] Chyba pri spustení {name}: {e}")
        return None

def monitor_modules(procs):
    while True:
        for name, proc in list(procs.items()):
            if proc.poll() is not None:  # proces skončil
                print(f"[!] Modul {name} ukončený s kódom {proc.returncode}, reštartujem ...")
                procs[name] = start_module(name, modules[name])
        time.sleep(2)

if __name__ == "__main__":
    procs = {}
    for name, path in modules.items():
        procs[name] = start_module(name, path)

    print("Všetky moduly spustené. Sledujem ich ...")
    monitor_modules(procs)
