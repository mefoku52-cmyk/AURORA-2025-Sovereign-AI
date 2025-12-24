#!/usr/bin/env python3
import threading, time, random, os, faiss, requests, numpy as np
from datetime import datetime
from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer
from flask import Flask, request, jsonify
import logging, sys

logging.basicConfig(level=logging.INFO, format='%(asctime)s | %(message)s',
                    datefmt='%H:%M:%S', handlers=[logging.StreamHandler(sys.stdout)])
log = logging.getLogger()

log.info("Aurora Brain – načítavam model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
dim = 384

index_file = "data/brain.faiss"
meta_file = "data/metadata.npy"

if os.path.exists(index_file):
    index = faiss.read_index(index_file)
    metadata = list(np.load(meta_file, allow_pickle=True))
    log.info(f"Načítaný mozog: {index.ntotal:,} vektorov")
else:
    index = faiss.IndexHNSWFlat(dim, 32)
    index.hnsw.efConstruction = 200
    index.hnsw.efSearch = 64
    metadata = []

lock = threading.Lock()

app = Flask("Aurora")
@app.route("/ask", methods=["POST"])
def ask():
    q = request.json.get("question", "")
    if not q: return {"error": "žiadna otázka"}, 400
    vec = model.encode([q])
    D, I = index.search(np.array(vec, dtype='float32'), 5)
    res = []
    for i in I[0]:
        if i < len(metadata):
            text, src, t = metadata[i]
            res.append({"odpoveď": text, "zdroj": src})
    return {"otázka": q, "odpovede": res}

threading.Thread(target=lambda: app.run(host="0.0.0.0", port=16666), daemon=True).start()
log.info("API beží na http://127.0.0.1:16666/ask")

def pridaj(vety, zdroj):
    if not vety: return
    vety = list(dict.fromkeys([s.strip()+"." for s in vety if 30<len(s.strip())<500]))[:80]
    if not vety: return
    vecs = model.encode(vety, batch_size=32, show_progress_bar=False)
    with lock:
        for s, v in zip(vety, vecs):
            metadata.append((s, zdroj, datetime.now().strftime("%H:%M")))
            index.add(np.array([v], dtype='float32'))
        if len(metadata) % 1000 == 0:
            faiss.write_index(index, index_file)
            np.save(meta_file, np.array(metadata, dtype=object))
            log.info(f"Uložené {len(metadata):,} viet")

def scrape(url):
    try:
        r = requests.get(url, timeout=10, headers={'User-Agent': 'Mozilla/5.0'})
        soup = BeautifulSoup(r.text, 'lxml')
        vety = [s.strip() for s in soup.get_text().split('.') if 30<len(s.strip())<500]
        if vety:
            pridaj(vety, url)
            log.info(f"[+] {len(vety)} viet ← {url[:50]}")
    except: pass

stranky = [
    "https://en.wikipedia.org/wiki/Special:Random",
    "https://news.ycombinator.com",
    "https://www.kernel.org",
    "https://lukesmith.xyz",
    "https://stallman.org"
]

def agent(n):
    while True:
        url = random.choice(stranky)
        log.info(f"[A{n:02d}] → {url}")
        scrape(url)
        time.sleep(random.uniform(5, 12))

log.info("AURORA BRAIN ŠTARTUJE – 80 agentov")
for i in range(1, 81):
    threading.Thread(target=agent, args=(i,), daemon=True).start()

while True:
    time.sleep(20)
    log.info(f"STAV → {index.ntotal:,} vektorov | {len(metadata):,} viet | API aktívne")
