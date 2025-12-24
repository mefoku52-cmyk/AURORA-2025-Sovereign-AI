#!/usr/bin/env python3
import os, time, subprocess
while True:
    if not any("aios_kernel_complete_final.py" in p for p in os.popen("ps aux").read().splitlines()):
        subprocess.Popen(["python3", "aios_kernel_complete_final.py"], cwd=os.path.expanduser("~/aurora"))
    time.sleep(6)
