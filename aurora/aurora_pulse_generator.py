import requests
import json
import time
import random
from datetime import datetime

# --- KONFIGURÁCIA ---
TARGET_URL = "http://127.0.0.1:5556/send_message"
RECIPIENT = "LLM_CORE"
INTERVAL_SECONDS = 60  # ZMENENÉ: 1 minúta (60 sekúnd)

def generate_random_message():
    """Generuje náhodné a zmysluplné testovacie správy pre LLM_CORE."""
    templates = [
        "Vytvor krátku analýzu trendov v oblasti AI pre Q4 2025.",
        "Aktivuj subsystém Master Cyklu #{} a over stav databázy FAISS.",
        "Aké sú tri najväčšie bezpečnostné riziká v AIOS architektúre?",
        "Vygeneruj stručný úvodný príspevok pre môj blog o umelých inteligenciách.",
        "Ako môžem začať pracovať na svojich cieľoch pre modul {}?",
        "Vyhodnoť efektivitu agentov v poslednom cykle a navrhni zmenu plánu."
    ]
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    # Používame PID procesu ($$) pre unikátnosť, ak by sme to spúšťali cez Bash
    pid = random.randint(1000, 9999) 
    message = random.choice(templates).format(pid, "Alpha-Task")
    return f"[{current_time}] AUTO-PULS: {message}"

def send_pulse():
    """Odošle jednu požiadavku do Kometa Bus."""
    payload = {
        "recipient": RECIPIENT,
        "data": generate_random_message()
    }
    try:
        response = requests.post(TARGET_URL, json=payload, timeout=5)
        
        # Logovanie odpovede z KERNELU
        print(f"[{datetime.now().strftime('%H:%M:%S')}] PULSE OK. Odpoveď: {response.text}")
        return True
    except requests.exceptions.RequestException as e:
        # Pre prípad, že KERNEL padol
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ CHYBA PULSU: Spojenie zlyhalo (Port 5556 nie je aktívny). {e}")
        return False

def main_loop():
    print(f"\n--- 🤖 AURORA PULSE GENERATOR STARTED ---")
    print(f"Cieľ: {TARGET_URL} | Interval: {INTERVAL_SECONDS / 60:.0f} minúta.")
    
    # Pošle prvý pulz hneď na začiatok
    send_pulse()
    
    while True:
        time.sleep(INTERVAL_SECONDS)
        send_pulse()

if __name__ == "__main__":
    main_loop()
