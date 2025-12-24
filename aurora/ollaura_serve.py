#!/usr/bin/env python3
import subprocess
import time
import threading
import sys
import os

MODULES = [
    ("OLLAURA_SERVER", ["python3", os.path.expanduser("~/aurora/ollaura_server.py")]),
    ("AIOS_MAIN", ["python3", os.path.expanduser("~/aurora/PORIADOK/ai_core/aios_main.py")]),
    ("AIOS_IPC", ["python3", os.path.expanduser("~/aurora/PORIADOK/ai_core/aios_ipc.py")]),
    ("BRAIN", ["python3", os.path.expanduser("~/aurora/aurora_brain.py")]),
    ("LEARNING", ["python3", os.path.expanduser("~/aurora/realtime_learning.py")]),
    ("VISION_WHISPER", ["python3", os.path.expanduser("~/aurora/PORIADOK/ai_core/aios_whisper_vision.py")]),
    ("VISION_YOLO", ["python3", os.path.expanduser("~/aurora/PORIADOK/ai_core/aios_yolo_vision.py")]),
]

def stream_output(name, process):
    for line in iter(process.stdout.readline, b""):
        print(f"[{name}] {line.decode().rstrip()}")
    process.stdout.close()

def start_module(name, cmd):
    print(f"[BOOT] Spúšťam modul: {name}")
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    thread = threading.Thread(target=stream_output, args=(name, process))
    thread.daemon = True
    thread.start()
    return process

def main():
    print("======================================")
    print("        O L L A U R A   S E R V E     ")
    print("======================================")
    print("Tvoj systém sa prebúdza...")
    print("")

    processes = []

    for name, cmd in MODULES:
        try:
            p = start_module(name, cmd)
            processes.append(p)
            time.sleep(1)
        except Exception as e:
            print(f"[ERROR] Modul {name} sa nepodarilo spustiť: {e}")

    print("\n[INFO] Všetky moduly spustené. OLLAURA žije.")
    print("[INFO] Sledujem logy v reálnom čase.\n")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[SHUTDOWN] Ukončujem všetky moduly...")
        for p in processes:
            p.terminate()
        print("[SHUTDOWN] Hotovo.")

if __name__ == "__main__":
    main()
