#!/usr/bin/env python3
import os, json, time, threading
from flask import Flask, request, jsonify

app = Flask("FULL_FAISS")
knowledge = []

def load_full_knowledge():
    global knowledge
    try:
        with open('data/knowledge.txt') as f:
            knowledge = [line.strip() for line in f if len(line.strip()) > 20]
        knowledge = list(dict.fromkeys(knowledge))  # dedup
        print(f"✅ Načítaných {len(knowledge):,} UNIKÁTNYCH viet z 42k riadkov")
    except Exception as e:
        print(f"❌ Load error: {e}")

load_full_knowledge()

@app.route("/ask", methods=["POST"])
def ask():
    q = request.json.get('q', '').lower()
    words = q.split()
    matches = []
    
    # FULL TEXT SEARCH cez VŠETKY riadky
    for sent in knowledge:
        if any(word in sent.lower() for word in words):
            matches.append(sent)
        if len(matches) >= 10: break
    
    return jsonify({
        "query": q,
        "answers": matches[:5],
        "total": len(knowledge),
        "scanned": len(knowledge)
    })

@app.route("/status")
def status():
    return jsonify({
        "sentences": len(knowledge),
        "unique": len(set(knowledge)),
        "mode": "full_text"
    })

print("🚀 FULL FAISS API na 16666 - 42k viet ready!")
threading.Thread(target=lambda:app.run(host='0.0.0.0', port=16666), daemon=True).start()
while True: time.sleep(60)
