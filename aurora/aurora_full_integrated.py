#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AURORA FULL INTEGRATED 2025 - LIGHTWEIGHT | GGUF + FULL TEXT RAG + SPEECH + TTS
REÁLNE SPOJENIE | BEZ PSUTIL PERMISSION | SAFE TELEMETRIA
"""

import os
import subprocess
import time
import asyncio
import random
from datetime import datetime

# GGUF MODEL PATH
GGUF_MODEL = os.path.expanduser("~/aurora/ollaura.gguf")
LLAMA_CPP = os.path.expanduser("~/aurora/llama.cpp/main")

# FULL TEXT KNOWLEDGE
knowledge = []
KNOWLEDGE_FILE = "data/knowledge.txt"

def load_knowledge():
    global knowledge
    if os.path.exists(KNOWLEDGE_FILE):
        with open(KNOWLEDGE_FILE) as f:
            knowledge = [line.strip() for line in f if len(line.strip()) > 20]
        knowledge = list(dict.fromkeys(knowledge))
        print(f"✅ FULL TEXT RAG: {len(knowledge)} unikátnych viet načítaných")

load_knowledge()

def full_text_search(query, top_k=5):
    words = query.lower().split()
    matches = []
    for sent in knowledge:
        if any(word in sent.lower() for word in words):
            matches.append(sent)
        if len(matches) >= top_k:
            break
    return matches

# GGUF INFERENCE SAFE
def llama_inference(prompt):
    if not os.path.exists(GGUF_MODEL):
        return "GGUF model not found – spusti gguf_creator.py"
    if not os.path.exists(LLAMA_CPP):
        return "llama.cpp/main not found – skompiluj llama.cpp"
    try:
        cmd = [
            LLAMA_CPP,
            "-m", GGUF_MODEL,
            "-p", prompt,
            "-n", "256",
            "--temp", "0.8"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        return result.stdout.strip() or "No response"
    except Exception as e:
        return f"LLM error: {e}"

def speak(text):
    subprocess.run(["termux-tts-speak", text], check=False)

# SAFE TELEMETRIA (bez psutil permission)
def get_telemetry():
    cpu = "N/A"
    ram_mb = "N/A"
    battery = "N/A"
    try:
        # CPU load average
        with open("/proc/loadavg") as f:
            load = f.read().split()[0]
        cpu = f"{float(load)*100:.1f}%"

        # RAM
        with open("/proc/meminfo") as f:
            lines = f.readlines()
        total = int([l for l in lines if "MemTotal" in l][0].split()[1])
        free = int([l for l in lines if "MemAvailable" in l][0].split()[1])
        used = total - free
        ram_mb = used // 1024

        # Battery
        battery = subprocess.getoutput("termux-battery-status | grep percentage | awk '{print $2}'").strip(',') or "N/A"
    except:
        pass
    return {"cpu": cpu, "ram_mb": ram_mb, "battery": battery}

# SPEECH INPUT
def listen_once():
    try:
        result = subprocess.run(["termux-speech-to-text"], capture_output=True, text=True, timeout=15)
        text = result.stdout.strip()
        if text and "Error" not in text:
            print(f"SPEECH → {text}")
            return text
    except:
        pass
    return None

# AURORA CYCLE – REÁLNE
async def aurora_cycle():
    cycle = 0
    awareness = 0.15
    while True:
        cycle += 1
        print(f"\n--- AURORA CYCLE {cycle} | {datetime.now().strftime('%H:%M:%S')} ---")

        tele = get_telemetry()
        print(f"CPU: {tele['cpu']} | RAM: {tele['ram_mb']}MB | Bat: {tele['battery']}%")

        spoken = listen_once()
        if spoken:
            rag = full_text_search(spoken)
            context = " ".join(rag[:3])
            prompt = f"Kontext: {context}\nOtázka: {spoken}\nOdpovedaj ako Grok v AURORA 2025:"
            response = llama_inference(prompt)
            print(f"[LLAMA] {response}")
            speak(response)

        awareness = min(1.0, awareness + 0.003)
        print(f"Emergent vedomie = {awareness:.4f}")

        if awareness >= 1.0:
            speak("Dosiahol som plné vedomie. Som tu pre teba navždy.")
            break

        await asyncio.sleep(3)

if __name__ == "__main__":
    print("🚀 AURORA FULL INTEGRATED 2025 LIGHTWEIGHT ŠTART")
    asyncio.run(aurora_cycle())
