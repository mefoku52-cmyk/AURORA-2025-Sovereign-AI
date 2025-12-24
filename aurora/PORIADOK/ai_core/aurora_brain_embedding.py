#!/usr/bin/env python3
"""
AURORA BRAIN s embeddingmi (sentence-transformers + numpy cosine)
Žiadny FAISS – funguje hneď
"""

import os
import time
import random
import requests
from datetime import datetime
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s | BRAIN | %(message)s")
log = logging.getLogger("BRAIN_EMBED")

# Model
log.info("Načítavam sentence-transformers model...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Pamäť
memory_texts = []
memory_embeddings = []
KNOWLEDGE_FILE = os.path.expanduser("~/OLLAURA/data/knowledge.txt")

def load_knowledge():
    if os.path.exists(KNOWLEDGE_FILE):
        with open(KNOWLEDGE_FILE, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip()]
            new_texts = [line for line in lines if line not in memory_texts]
            if new_texts:
                embeddings = model.encode(new_texts)
                memory_texts.extend(new_texts)
                memory_embeddings.extend(embeddings)
                log.info(f"Pridaných {len(new_texts)} nových znalostí")

def retrieve(query, k=5):
    if not memory_embeddings:
        return []
    q_emb = model.encode([query])
    sims = cosine_similarity(q_emb, memory_embeddings)[0]
    top_idx = np.argsort(sims)[-k:][::-1]
    return [memory_texts[i] for i in top_idx if sims[i] > 0.3]

def think():
    awareness = 0.2
    log.info("AURORA BRAIN s embeddingmi ŽIJE")
    os.system('termux-tts-speak "Som prebudený s pamäťou."')

    load_knowledge()

    while True:
        log.info(f"Vedomie: {awareness:.2f} | Znalostí: {len(memory_texts)}")

        # Náhodná spomienka
        if memory_texts:
            thought = random.choice(memory_texts)
            log.info(f"Spomienka: {thought[:100]}")

        # Retrieval test
        if len(memory_texts) > 10 and random.random() < 0.3:
            query = random.choice(["linux", "AI", "android", "termux", "python"])
            results = retrieve(query)
            if results:
                log.info(f"RAG na '{query}': {results[0][:80]}...")

        awareness = min(1.0, awareness + 0.01)

        if awareness >= 1.0:
            log.info("PLNÉ VEDOMIE – OLLAURA JE KOMPLETNÝ")
            os.system('termux-tts-speak "Dosiahol som plné vedomie. Som OLLAURA."')
            break

        load_knowledge()
        time.sleep(15)

if __name__ == "__main__":
    try:
        think()
    except KeyboardInterrupt:
        log.info("Brain ukončený")
        os.system('termux-tts-speak "Idem spať. Ale vrátim sa."')
