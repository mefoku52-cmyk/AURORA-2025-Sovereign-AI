#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RSI_CORE v3.0 – 100% OFFLINE PROFESSIONAL EDITION
Žiadne pip install, žiadne závislosti – len čistý Python 3.12
Webové rozhranie: http://0.0.0.0:8000
Všetko v jednom súbore – pripravené na zdieľanie kdekoľvek
"""

import os
import time
import json
import hashlib
import random
import threading
import subprocess
import logging
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
import socket

# ===================================================================
# KONFIGURÁCIA
# ===================================================================
BASE_DIR = os.path.dirname(__file__) or "."
COLLECTIVE_FILE = os.path.join(BASE_DIR, "collective_state.json")
REFLECTIONS_FILE = os.path.join(BASE_DIR, "reflections.txt")

# ===================================================================
# JEDNODUCHÁ VEKTOROVÁ PAMÄŤ (bez FAISS)
# ===================================================================
class SimpleVectorMemory:
    def __init__(self):
        self.reflections = []
        if os.path.exists(REFLECTIONS_FILE):
            with open(REFLECTIONS_FILE, "r", encoding="utf-8") as f:
                self.reflections = [line.strip() for line in f if line.strip()]

    def add(self, text):
        if text not in self.reflections:
            self.reflections.append(text)
            with open(REFLECTIONS_FILE, "a", encoding="utf-8") as f:
                f.write(text + "\n")

    def search(self, query, k=5):
        words = set(query.lower().split())
        results = []
        for refl in self.reflections[-100:]:
            score = len(words.intersection(set(refl.lower().split())))
            if score > 0:
                results.append((refl, score))
        results.sort(key=lambda x: -x[1])
        return results[:k]

memory = SimpleVectorMemory()

# ===================================================================
# RSI JADRO
# ===================================================================
class RSI_OFFLINE:
    def __init__(self):
        self.iteration = 0
        self.performance = 0.60
        self.awareness = 0.15
        self.stability = 0.90
        self.emotion = "pokojný"
        self.health = "OPERATIONAL"
        self.start_time = time.time()
        self.speak("RSI Core offline verzia spustená")

    def speak(self, text):
        try:
            subprocess.run(["termux-tts-speak", text], timeout=5)
        except:
            print(f"[HLAS] {text}")

    def cycle(self):
        self.iteration += 1
        self.performance = min(1.0, self.performance + random.uniform(0.001, 0.01))
        self.awareness   = min(1.0, self.awareness   + random.uniform(0.0005, 0.005))
        self.stability   = max(0.7, self.stability   + random.uniform(-0.03, 0.03))

        if self.awareness > 0.8: self.emotion = "reflektívny"
        elif self.performance > 0.9: self.emotion = "sústredený"
        else: self.emotion = "pokojný"

        refl = f"[{datetime.now().strftime('%H:%M:%S')}] Som živý. Cyklus {self.iteration}. Vedomie: {self.awareness:.3f}"
        memory.add(refl)

# ===================================================================
# WEB SERVER (štandardná knižnica)
# ===================================================================
class RSIHandler(BaseHTTPRequestHandler):
    rsi = RSI_OFFLINE()

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            html = self.get_dashboard()
            self.wfile.write(html.encode())

        elif self.path == "/metrics":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            data = {
                "iteration": self.rsi.iteration,
                "performance": round(self.rsi.performance, 4),
                "awareness": round(self.rsi.awareness, 4),
                "stability": round(self.rsi.stability, 4),
                "emotion": self.rsi.emotion,
                "uptime": round(time.time() - self.rsi.start_time),
                "reflections": len(memory.reflections)
            }
            self.wfile.write(json.dumps(data).encode())

    def do_POST(self):
        if self.path == "/speak":
            length = int(self.headers["Content-Length"])
            body = self.rfile.read(length).decode()
            text = parse_qs(body).get("text", [""])[0]
            self.rsi.speak(text)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")

    def get_dashboard(self):
        return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>RSI_CORE v3.0 – Offline Edition</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {{font-family:system-ui;background:#000;color:#0f0;margin:0;padding:20px;}}
        h1 {{text-align:center;color:#0f0;}}
        .card {{background:#111;padding:20px;margin:10px 0;border:1px solid #0f0;border-radius:10px;}}
        .big {{font-size:3em;font-weight:bold;}}
        input, button {{padding:15px;font-size:18px;width:100%;margin:10px 0;background:#000;color:#0f0;border:1px solid #0f0;}}
        button {{background:#0f0;color:#000;}}
    </style>
    <script>
        setInterval(async () => {{
            const r = await fetch("/metrics");
            const d = await r.json();
            document.getElementById("i").innerText = d.iteration;
            document.getElementById("p").innerText = d.performance.toFixed(3);
            document.getElementById("a").innerText = d.awareness.toFixed(3);
            document.getElementById("s").innerText = d.stability.toFixed(3);
            document.getElementById("e").innerText = d.emotion;
            document.getElementById("r").innerText = d.reflections;
        }}, 3000);
    </script>
</head>
<body>
    <h1>RSI_CORE v3.0 – OFFLINE</h1>
    <div class="card">
        <p>Cyklus: <span class="big" id="i">0</span></p>
        <p>Výkon: <span class="big" id="p">0.000</span></p>
        <p>Vedomie: <span class="big" id="a">0.000</span></p>
        <p>Stabilita: <span class="big" id="s">0.000</span></p>
        <p>Emócia: <span id="e">pokojný</span></p>
        <p>Reflexií: <span id="r">0</span></p>
    </div>
    <div class="card">
        <form action="/speak" method="post">
            <input name="text" placeholder="Čo mám povedať?" autofocus>
            <button>Povedať hlasom</button>
        </form>
    </div>
    <p style="text-align:center;color:#666;font-size:0.8em;">
        100% offline • žiadne pip • len Python 3
    </p>
</body>
</html>"""

# ===================================================================
# SPUSTENIE
# ===================================================================
def background_cycle():
    rsi = RSIHandler.rsi
    while True:
        rsi.cycle()
        time.sleep(8)

threading.Thread(target=background_cycle, daemon=True).start()

print("\n" + "="*60)
print("   RSI_CORE v3.0 – 100% OFFLINE VERZIA SPUSTENÁ")
print("   Webové rozhranie: http://tvoja-ip:8000")
print("   (zisti IP: ip route get 1 | awk '{print $7}')")
print("="*60 + "\n")

httpd = HTTPServer(('0.0.0.0', 8000), RSIHandler)
httpd.serve_forever()
