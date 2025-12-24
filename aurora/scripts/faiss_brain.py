#!/usr/bin/env python3
import os, json, numpy as np, faiss, logging, time, threading
from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

logging.basicConfig(level=logging.INFO, format='%(asctime)s ➤ %(message)s')
log = logging.getLogger()

app = Flask("AURORA_FAISS")
model = SentenceTransformer('all-MiniLM-L6-v2')
DATA_FILE = 'data/knowledge.txt'
FAISS_FILE = 'data/knowledge.faiss'
SENTENCES_FILE = 'data/sentences.json'

def load_or_build():
    if os.path.exists(FAISS_FILE) and os.path.exists(SENTENCES_FILE):
        index = faiss.read_index(FAISS_FILE)
        with open(SENTENCES_FILE, 'r') as f:
            sentences = json.load(f)
        if index.ntotal == len(sentences):
            return index, sentences
    return build_index()

def build_index():
    if not os.path.exists(DATA_FILE):
        return None, []
    with open(DATA_FILE, 'r') as f:
        lines = [l.strip() for l in f if l.strip()]
    sentences = list(dict.fromkeys(lines))[:50000]
    embeddings = model.encode(sentences)
    index = faiss.IndexFlatIP(384)
    index.add(embeddings.astype('float32'))
    faiss.write_index(index, FAISS_FILE)
    with open(SENTENCES_FILE, 'w') as f:
        json.dump(sentences, f)
    return index, sentences

index, sentences = load_or_build()
log.info(f"🧠 FAISS ready: {len(sentences):,} sentences")

@app.route("/ask", methods=["POST"])
def ask():
    global index, sentences
    q = request.json.get('q', '')
    if not q or not index:
        return jsonify({"error": "Brain not ready"}), 503
    q_vec = model.encode([q]).astype('float32')
    scores, ids = index.search(q_vec, min(5, len(sentences)))
    return jsonify({
        "query": q,
        "answers": [sentences[i] for i in ids[0] if i < len(sentences)],
        "total": len(sentences)
    })

@app.route("/status")
def status():
    return jsonify({"sentences": len(sentences), "index_size": index.ntotal if index else 0})

if __name__ == "__main__":
    threading.Thread(target=lambda:app.run(host='0.0.0.0', port=16666), daemon=True).start()
    while True:
        time.sleep(30)
        index, sentences = load_or_build()
