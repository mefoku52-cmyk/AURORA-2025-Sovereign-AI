#!/usr/bin/env python3
import os, json, time, threading
from flask import Flask, request, jsonify
from collections import deque

app = Flask("SIMPLE_FAISS")
knowledge = deque(maxlen=5000)

def load_knowledge():
    try:
        with open('data/knowledge.txt') as f:
            for line in f:
                if len(line.strip()) > 30:
                    knowledge.append(line.strip())
    except: pass

load_knowledge()
print(f"Načítaných {len(knowledge)} viet")

@app.route("/ask", methods=["POST"])
def ask():
    q = request.json.get('q', '').lower()
    matches = [s for s in list(knowledge)[-1000:] if any(word in s.lower() for word in q.split())][:5]
    return jsonify({"answers": matches, "total": len(knowledge)})

@app.route("/status")
def status():
    return jsonify({"sentences": len(knowledge)})

threading.Thread(target=lambda:app.run(host='0.0.0.0', port=16666), daemon=True).start()
print("FAISS API na 16666")
while True: time.sleep(60)
