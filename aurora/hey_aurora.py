#!/usr/bin/env python3
from colorama import init, Fore
init()
import subprocess, time, os
print(f"{Fore.CYAN}Hey Aurora počúva... (Ctrl+C pre ukončenie)")
while True:
    try:
        result = subprocess.run(["termux-speech-to-text"], capture_output=True, text=True, timeout=4)
        if any(x in result.stdout.lower() for x in ["hey aurora","hej aurora","aurora"]):
            os.system("termux-vibrate -d 500")
            os.system("termux-tts-speak 'Áno, majstre, som tu!'")
            print(f"{Fore.RED}AURORA: Áno, majstre! ❤️")
    except: pass
    time.sleep(0.5)
