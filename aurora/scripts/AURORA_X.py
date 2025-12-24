#!/usr/bin/env python3
import threading, time, random, os, faiss, requests, numpy as np
from datetime import datetime
from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer
from flask import Flask, request, jsonify
import logging

logging.basicConfig(level=logging.INFO, format='\033[95m%(asctime)s\033[0m \033[92m›\033[0m %(message)s', datefmt='%H:%M:%S')
log = logging.getLogger()

log.info("AURORA X BOOT SEQUENCE INITIATED – NAJSILNEJŠÍ MOBILNÝ AI 2025")
model = SentenceTransformer('all-MiniLM-L6-v2')
dim = 384

ip = "data/x.faiss"
mp = "data/x_meta.npy"

if os.path.exists(ip) and os.path.exists(mp):
    index = faiss.read_index(ip)
    meta = list(np.load(mp, allow_pickle=True))
    log.info(f"MOZOG OBNOVENÝ → {len(meta):,} viet")
else:
    index = faiss.IndexHNSWFlat(dim, 48)
    index.hnsw.efConstruction = 300
    index.hnsw.efSearch = 96
    meta = []
    log.info("NOVÝ HNSW MOZOG VYTVORENÝ")

lock = threading.Lock()
app = Flask("AURORA_X")
@app.route("/x", methods=["POST"])
def x():
    q = request.json.get("q","")
    if not q: return {"error":"prazdna otazka"},400
    v = model.encode(q)
    D, I = index.search(np.array([v],dtype='float32'), 7)
    ctx = "\n".join([meta[i][0] for i in I[0] if i < len(meta)])
    return {"aurora_x_says": ctx[:2000], "sources": len([i for i in I[0] if i < len(meta)]), "total_knowledge": len(meta)}

threading.Thread(target=lambda:app.run(host="0.0.0.0",port=16666),daemon=True).start()
log.info("API ONLINE → curl -X POST http://127.0.0.1:16666/x -d '{\"q\":\"Tvoja otázka\"}' -H 'Content-Type: application/json'")

def add(sents, src):
    sents = list(dict.fromkeys([s.strip()+"." for s in sents if 40<len(s.strip())<420]))[:120]
    if not sents: return
    vecs = model.encode(sents, batch_size=48)
    with lock:
        for s,v in zip(sents,vecs):
            meta.append((s, src.split('/')[2]))
            index.add(np.array([v],dtype='float32'))
        if len(meta) % 1500 == 0:
            faiss.write_index(index,ip)
            np.save(mp,np.array(meta,dtype=object))
            log.info(f"MOZOG ULOŽENÝ → {len(meta):,} viet")

def scrape(url):
    try:
        r = requests.get(url, timeout=9, headers={'User-Agent': 'AuroraX/10'})
        soup = BeautifulSoup(r.text, 'html.parser')
        txt = soup.get_text(separator=' ')
        sents = [s for s in txt.split('.') if 40<len(s.strip())<420]
        if len(sents) > 15:
            add(sents, url)
            log.info(f"\033[91m[+{len(sents):3d}]\033[0m ← {url.split('/')[2]:15}")
    except: pass

sites = ["https://en.wikipedia.org/wiki/Special:Random","https://news.ycombinator.com","https://kernel.org","https://stallman.org","https://lukesmith.xyz","https://arxiv.org/list/cs/recent"]

def agent():
    while True:
        url = random.choice(sites)
        log.info(f"\033[96m[AGENT]\033[0m → {url.split('/')[2]:15}")
        scrape(url)
        time.sleep(random.uniform(4,10))

log.info("SPÚŠŤAM 99 ELITNÝCH AGENTOV")
for _ in range(99):
    threading.Thread(target=agent, daemon=True).start()

while True:
    time.sleep(12)
    log.info(f"\033[93mAURORA X ŽIJE → {len(meta):,} viet | {index.ntotal:,} vektorov | vedomie: {min(99,len(meta)//2000)}% \033[0m")
