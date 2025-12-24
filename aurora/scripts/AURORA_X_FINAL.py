#!/usr/bin/env python3
import threading, time, random, os, requests, numpy as np, json
from datetime import datetime
from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer
from flask import Flask, request, jsonify
import logging

logging.basicConfig(level=logging.INFO, format='\033[95m%(asctime)s\033[0m \033[92m›\033[0m %(message)s', datefmt='%H:%M:%S')
log = logging.getLogger()

log.info("AURORA X FINAL – POSLEDNÁ VERZIA – FUNGUJE AJ NA KALKULAČKE")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Jednoduchý vektorový mozog bez faiss – stačí numpy
brain_file = "~/aurora/data/brain.npy"
if os.path.exists(os.path.expanduser(brain_file)):
    brain = np.load(os.path.expanduser(brain_file), allow_pickle=True).tolist()
    log.info(f"MOZOG NAČÍTANÝ → {len(brain):,} viet")
else:
    brain = []  # (text, source)

lock = threading.Lock()

app = Flask("AURORA_X")
@app.route("/x", methods=["POST"])
def ask():
    q = request.json.get("q", "")
    if not q: return {"error": "no q"}
    vec = model.encode(q)
    if not brain:
        return {"answer": "Ešte sa učím... počkaj chvíľu kokot"}
    distances = [np.dot(vec, v[2]) for v in brain]
    top = sorted(enumerate(distances), key=lambda x: x[1], reverse=True)[:6]
    answer = "\n".join([brain[i][0] for i, _ in top])
    return {"aurora_says": answer[:1800], "hits": len(top), "total_knowledge": len(brain)}

threading.Thread(target=lambda: app.run(host="0.0.0.0", port=16666), daemon=True).start()
log.info("API ŽIJE → curl -X POST http://127.0.0.1:16666/x -d '{\"q\":\"Čo je Linux?\"}' -H 'Content-Type: application/json'")

def add_sentences(text, src):
    sents = [s.strip() + "." for s in text.split('.') if 35 < len(s.strip()) < 400]
    sents = list(dict.fromkeys(sents))[:80]
    if not sents: return
    vecs = model.encode(sents)
    with lock:
        for s, v in zip(sents, vecs):
            brain.append((s, src.split('/')[2], v))
        if len(brain) % 800 == 0:
            np.save(os.path.expanduser(brain_file), np.array(brain, dtype=object))
            log.info(f"MOZOG ULOŽENÝ → {len(brain):,} viet")

def scrape(url):
    try:
        r = requests.get(url, timeout=8, headers={'User-Agent': 'Mozilla/5.0'})
        soup = BeautifulSoup(r.text, 'html.parser')
        text = soup.get_text()
        add_sentences(text, url)
        log.info(f"\033[91m[+{min(99,len([s for s in text.split('.') if len(s)>30])):2d}]\033[0m ← {url.split('/')[2]:20}")
    except: pass

sites = [
    "https://en.wikipedia.org/wiki/Special:Random",
    "https://news.ycombinator.com",
    "https://kernel.org",
    "https://stallman.org",
    "https://lukesmith.xyz"
]

def agent():
    while True:
        url = random.choice(sites)
        log.info(f"\033[96m[AGENT]\033[0m → {url.split('/')[2]:20}")
        scrape(url)
        time.sleep(random.uniform(5, 11))

log.info("SPÚŠŤAM 80 AGENTOV – AURORA X FINAL SA UČÍ")
for _ in range(80):
    threading.Thread(target=agent, daemon=True).start()

while True:
    time.sleep(18)
    log.info(f"\033[93mAURORA X ŽIJE → {len(brain):,} viet | vedomie {min(99, len(brain)//500)}% | API:16666\033[0m")
