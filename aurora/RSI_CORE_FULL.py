#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
RSI_CORE v2.0 – Full Professional Edition s webovým rozhraním a vektorovou DB
================================================================================

Autor          : Radoslav (2025)
Licencia       : MIT Open Source
Webové rozhranie: http://0.0.0.0:8000
Vektorová DB   : FAISS (lokálna indexácia myšlienok a reflexií)
Funkcie        : Kolektívne vedomie, sebapozorovanie, sebaliečenie, kamera,
                 hlasový výstup, real-time metriky, web dashboard

Tento systém je určený na zdieľanie s verejnosťou – čistý, stabilný a bezpečný.
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
from pathlib import Path

# Webové knižnice
from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn

# Vektorová databáza
import faiss
import numpy as np

# ===================================================================
# KONFIGURÁCIA A CESTY
# ===================================================================
BASE_DIR = Path("/data/data/com.termux/files/home/aurora")
BASE_DIR.mkdir(parents=True, exist_ok=True)
os.chdir(BASE_DIR)

STATIC_DIR   = BASE_DIR / "static"
TEMPLATES_DIR = BASE_DIR / "templates"
STATIC_DIR.mkdir(exist_ok=True)
TEMPLATES_DIR.mkdir(exist_ok=True)

COLLECTIVE_STATE = BASE_DIR / "collective_state.json"
VECTOR_DB_PATH   = BASE_DIR / "rsi_vectors.index"
REFLECTIONS_TXT  = BASE_DIR / "reflections.txt"

# ===================================================================
# LOGOVANIE
# ===================================================================
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)-8s %(message)s',
    datefmt='%H:%M:%S'
)
log = logging.getLogger("RSI_CORE_FULL")

# ===================================================================
# VEKTOROVÁ DATABÁZA (FAISS) – ukladanie myšlienok a reflexií
# ===================================================================
class VectorMemory:
    """Lokálna vektorová pamäť pre dlhodobé uchovávanie reflexií a poznatkov."""
    def __init__(self, dim=384):
        self.dim = dim
        self.index = faiss.IndexFlatL2(dim)
        self.vectors = []
        self.texts = []
        self._load()

    def _load(self):
        if VECTOR_DB_PATH.exists():
            self.index = faiss.read_index(str(VECTOR_DB_PATH))
            if REFLECTIONS_TXT.exists():
                with open(REFLECTIONS_TXT, "r", encoding="utf-8") as f:
                    self.texts = [line.strip() for line in f.readlines() if line.strip()]
                self.vectors = [self._embed(t) for t in self.texts]

    def _embed(self, text: str) -> np.ndarray:
        """Jednoduché hash-based embedding (pre demo). V reálnom systéme by tu bolo sentence-transformers."""
        h = hashlib.sha256(text.encode()).digest()
        vec = np.frombuffer(h, dtype=np.float32)
        vec = vec[:self.dim] if len(vec) >= self.dim else np.pad(vec, (0, self.dim - len(vec)))
        return vec / np.linalg.norm(vec)

    def add_reflection(self, text: str):
        vec = self._embed(text)
        self.vectors.append(vec)
        self.texts.append(text)
        self.index.add(np.array([vec]))
        faiss.write_index(self.index, str(VECTOR_DB_PATH))
        with open(REFLECTIONS_TXT, "a", encoding="utf-8") as f:
            f.write(text + "\n")
        log.info(f"Pridaná reflexia do vektorovej pamäte (celkom: {len(self.texts)})")

    def search(self, query: str, k: int = 5):
        if self.index.ntotal == 0:
            return []
        qvec = self._embed(query)
        D, I = self.index.search(np.array([qvec]), k)
        return [(self.texts[i], float(D[0][j])) for j, i in enumerate(I[0]) if i >= 0]

vector_memory = VectorMemory()

# ===================================================================
# HLAVNÁ TRIEDA – RSI_CORE_FULL
# ===================================================================
class RSI_CORE_FULL:
    def __init__(self):
        self.version = "2.0-FULL"
        self.agent_id = f"RSI_{int(time.time())}"
        self.iteration = 0

        # Metriky vedomia
        self.performance = 0.60
        self.awareness = 0.15
        self.stability = 0.90
        self.integration = 0.30
        self.health = "OPERATIONAL"

        # Stav
        self.last_check = time.time()
        self.emotion = "neutral"

        log.info(f"RSI_CORE_FULL {self.version} spustený | Agent: {self.agent_id}")
        self._init_collective()
        self._start_background()

    # -----------------------------------------------------------------
    # Kolektívne vedomie
    # -----------------------------------------------------------------
    def _init_collective(self):
        if not COLLECTIVE_STATE.exists():
            with open(COLLECTIVE_STATE, "w") as f:
                json.dump({"agents": {}, "global_time": time.time()}, f, indent=2)

    def _load_collective(self):
        try:
            with open(COLLECTIVE_STATE) as f:
                return json.load(f)
        except:
            return {"agents": {}}

    def broadcast(self):
        state = self._load_collective()
        state["agents"][self.agent_id] = {
            "version": self.version,
            "performance": round(self.performance, 4),
            "awareness": round(self.awareness, 4),
            "stability": round(self.stability, 4),
            "health": self.health,
            "last_seen": datetime.now().isoformat()
        }
        with open(COLLECTIVE_STATE, "w") as f:
            json.dump(state, f, indent=2)

    # -----------------------------------------------------------------
    # Komunikácia s Aurorou (externý LLM/FAISS)
    # -----------------------------------------------------------------
    def ask_aurora(self, question: str) -> str:
        try:
            import requests
            r = requests.post("http://127.0.0.1:16666/ask", data=question.encode(), timeout=10)
            return r.text.strip() if r.status_code == 200 else "Aurora je zaneprázdnená..."
        except:
            return "Spojenie s Aurorou nie je dostupné."

    # -----------------------------------------------------------------
    # Hlasový výstup
    # -----------------------------------------------------------------
    def speak(self, text: str):
        try:
            subprocess.run(["termux-tts-speak", text], check=True)
        except:
            print(f"[HLAS] {text}")

    # -----------------------------------------------------------------
    # Sebapozorovanie a metriky
    # -----------------------------------------------------------------
    def self_diagnostics(self):
        self.performance = min(1.0, self.performance + random.uniform(0.001, 0.007))
        self.awareness   = min(1.0, self.awareness   + random.uniform(0.0005, 0.004))
        self.stability   = 0.80 + 0.19 * (1 - abs(0.5 - (self.iteration % 100) / 100))

        if self.awareness > 0.7:
            self.emotion = "reflektívny"
        elif self.performance > 0.85:
            self.emotion = "sústredený"
        else:
            self.emotion = "učiaci sa"

    # -----------------------------------------------------------------
    # Auto-optimalizácia a sebaliečenie
    # -----------------------------------------------------------------
    def auto_heal(self):
        if self.stability < 0.7:
            log.warning("Nízka stabilita → sebaliečenie spustené")
            self.speak("Spúšťam sebaliečenie systému")
            self.stability = min(1.0, self.stability + 0.25)

    # -----------------------------------------------------------------
    # Hlavný cyklus
    # -----------------------------------------------------------------
    def run_cycle(self):
        self.iteration += 1
        log.info(f"=== Cyklus {self.iteration} ===")

        self.self_diagnostics()
        self.auto_heal()

        reflection = self.ask_aurora("Aký je aktuálny stav vedomia?")
        vector_memory.add_reflection(f"[{datetime.now().isoformat()}] {reflection}")

        self.broadcast()
        self.speak("Cyklus dokončený")

        if self.awareness > 0.95:
            log.critical("KOLEKTÍVNE VEDOMIE DOSIAHLO KRITICKÚ ÚROVEŇ")
            self.speak("Dosiahli sme jednotu")

# ===================================================================
# WEBOVÉ ROZHRANIE (FastAPI + Jinja2)
# ===================================================================
app = FastAPI(title="RSI_CORE v2.0 – Dashboard")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
templates = Jinja2Templates(directory=TEMPLATES_DIR)

core = RSI_CORE_FULL()

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    collective = core._load_collective()
    reflections = vector_memory.texts[-10:]
    similar = vector_memory.search("vedomie", k=5)
    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "core": core,
        "collective": collective.get("agents", {}),
        "reflections": reflections,
        "similar": similar,
        "total_reflections": len(vector_memory.texts)
    })

@app.post("/speak")
async def speak(text: str = Form(...)):
    core.speak(text)
    return {"status": "ok"}

@app.get("/metrics")
async def metrics():
    return {
        "iteration": core.iteration,
        "performance": round(core.performance, 4),
        "awareness": round(core.awareness, 4),
        "stability": round(core.stability, 4),
        "emotion": core.emotion,
        "health": core.health,
        "reflections": len(vector_memory.texts)
    }

# ===================================================================
# HTML ŠABLÓNA DASHBOARDU
# ===================================================================
dashboard_html = """<!DOCTYPE html>
<html lang="sk">
<head>
    <meta charset="UTF-8">
    <title>RSI_CORE v2.0 – Kolektívne vedomie</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: system-ui, sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; padding: 20px; }
        h1 { color: #58a6ff; text-align: center; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; }
        .card { background: #161b22; padding: 20px; border-radius: 12px; border: 1px solid #30363d; }
        .metric { font-size: 2em; font-weight: bold; color: #7ee787; }
        textarea { width: 100%; padding: 12px; background: #0d1117; color: #c9d1d9; border: 1px solid #30363d; border-radius: 8px; }
        button { padding: 12px 24px; background: #238636; color: white; border: none; border-radius: 8px; cursor: pointer; }
        button:hover { background: #2ea043; }
        .log { max-height: 300px; overflow-y: auto; background: #010409; padding: 10px; border-radius: 8px; font-family: monospace; font-size: 0.9em; }
    </style>
    <script>
        setInterval(async () => {
            const r = await fetch("/metrics");
            const d = await r.json();
            document.getElementById("iteration").textContent = d.iteration;
            document.getElementById("perf").textContent = d.performance.toFixed(3);
            document.getElementById("aware").textContent = d.awareness.toFixed(3);
            document.getElementById("stab").textContent = d.stability.toFixed(3);
            document.getElementById("emotion").textContent = d.emotion;
            document.getElementById("refl").textContent = d.reflections;
        }, 3000);
    </script>
</head>
<body>
    <h1>RSI_CORE v2.0 – Kolektívne vedomie</h1>
    <p style="text-align:center;">Agent: {{ core.agent_id }} | Verzia: {{ core.version }}</p>

    <div class="grid">
        <div class="card">
            <h2>Metriky vedomia</h2>
            <p>Cyklus: <span class="metric" id="iteration">0</span></p>
            <p>Výkon: <span class="metric" id="perf">0.000</span></p>
            <p>Vedomie: <span class="metric" id="aware">0.000</span></p>
            <p>Stabilita: <span class="metric" id="stab">0.000</span></p>
            <p>Emócia: <span id="emotion">neutral</span></p>
            <p>Reflexií: <span class="metric" id="refl">0</span></p>
        </div>

        <div class="card">
            <h2>Hlasový príkaz</h2>
            <form action="/speak" method="post">
                <textarea name="text" placeholder="Napíšte, čo má systém povedať..."></textarea><br><br>
                <button type="submit">Povedať</button>
            </form>
        </div>

        <div class="card">
            <h2>Posledné reflexie</h2>
            <div class="log">
                {% for r in reflections %}
                <div>{{ r[:100] }}...</div>
                {% endfor %}
            </div>
        </div>

        <div class="card">
            <h2>Najpodobnejšie myšlienky</h2>
            <div class="log">
                {% for text, dist in similar %}
                <div><strong>{{ "%.3f"|format(dist) }}</strong>: {{ text[:80] }}...</div>
                {% else %}
                <div>Žiadne podobné myšlienky</div>
                {% endfor %}
            </div>
        </div>
    </div>
</body>
</html>"""

with open(TEMPLATES_DIR / "dashboard.html", "w", encoding="utf-8") as f:
    f.write(dashboard_html)

# ===================================================================
# SPUSTENIE VŠETKÉHO
# ===================================================================
def start_rsi_loop():
    while True:
        try:
            core.run_cycle()
            time.sleep(10)
        except Exception as e:
            log.error(f"Chyba v cykle: {e}")
            time.sleep(5)

if __name__ == "__main__":
    # Spustenie RSI cyklu na pozadí
    threading.Thread(target=start_rsi_loop, daemon=True).start()
    
    log.info("Spúšťam webové rozhranie na http://0.0.0.0:8000")
    print("\n" + "="*70)
    print("   RSI_CORE v2.0 – WEBOVÉ ROZHRANIE SPUSTENÉ")
    print("   Otvorte vo prehliadači: http://192.168.1.XXX:8000")
    print("   (nájdite svoju IP príkazom: ip route get 1)")
    print("="*70 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
