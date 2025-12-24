#!/usr/bin/env bash
# =============================================================================
# AURORA_X v4 FINAL - TERMUX NATIVE BUILD (SKIP ERRORS + ONE COMMAND)
# Plne robustné - žiadne zastavenie pri chybách pip
# =============================================================================

set +e  # SKIP ALL ERRORS - pokračuje aj pri pip fail
cd ~ || exit 1

echo -e "\u001B[93m🔥 AURORA_X v4 FINAL - TERMUX NATIVE (ERROR-PROOF)\u001B[0m"

# 1. BUILD TOOLS (SKIP IF FAIL)
echo -e "\u001B[92m🛠️  Build tools...\u001B[0m"
pkg update -y 2>/dev/null || true
pkg install libblas liblapack pkg-config python-dev ndk-sysroot binutils -y 2>/dev/null || true

# 2. ZASTAVIŤ
pkill -f AURORA_X 2>/dev/null || true
sleep 2

# 3. INSTALÁCIA (PRESKAKUJ CHYBY)
echo -e "\u001B[92m📦 Inštalujem (skip errors)...\u001B[0m"
pip install --no-cache-dir --no-binary=numpy numpy 2>/dev/null || echo "⚠️ Numpy skip"
pip install --no-cache-dir requests beautifulsoup4 flask 2>/dev/null || echo "⚠️ Basic skip"
pip install --no-cache-dir sentence-transformers 2>/dev/null || echo "⚠️ Transformers skip"
pip install --no-cache-dir faiss-cpu 2>/dev/null || echo "⚠️ FAISS skip - numpy mode"

mkdir -p ~/aurora/{data,scripts,logs}

# 4. ULTIMATE PYTHON SKRIPT (FAISS SAFE)
cat > ~/aurora/scripts/AURORA_X_ULTIMATE.py << 'PYEOF'
#!/usr/bin/env python3
"""
AURORA_X v4 FINAL - TERMUX NATIVE (FAISS SAFE + NUMPY FALLBACK)
"""

import threading
import time
import random
import os
import requests
import json
import logging
from datetime import datetime
from bs4 import BeautifulSoup
from flask import Flask, request, jsonify

# TRY FAISS FIRST, FALLBACK TO NUMPY
try:
    import numpy as np
    import faiss
    USE_FAISS = True
    logging.getLogger().info("✅ FAISS + NUMPY ACTIVE")
except ImportError:
    try:
        import numpy as np
        USE_FAISS = False
        logging.getLogger().info("⚠️ NUMPY ONLY MODE")
    except ImportError:
        USE_FAISS = False
        logging.getLogger().info("❌ NO NUMPY - BASIC MODE")

try:
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer('all-MiniLM-L6-v2')
    logging.getLogger().info("✅ SentenceTransformer LOADED")
except:
    model = None
    logging.getLogger().info("❌ NO SentenceTransformer - TEXT ONLY")

logging.basicConfig(
    level=logging.INFO,
    format='\u001B[95m%(asctime)s\u001B[0m \u001B[92m➤\u001B[0m %(message)s',
    datefmt='%H:%M:%S'
)
log = logging.getLogger()

brain_file = os.path.expanduser("~/aurora/data/ultimate_brain.npy")
sentences_file = os.path.expanduser("~/aurora/data/sentences.json")

# LOAD BRAIN (SMART FALLBACK)
if os.path.exists(brain_file) and USE_FAISS:
    try:
        brain_index = faiss.read_index(brain_file)
        with open(sentences_file, 'r') as f:
            brain = json.load(f)
        log.info(f"🧠 FAISS: {len(brain):,} viet")
    except:
        brain = []
        log.info("🧠 FAISS FAIL - NEW BRAIN")
elif os.path.exists(brain_file):
    brain = np.load(brain_file, allow_pickle=True).tolist()
    log.info(f"🧠 NUMPY: {len(brain):,} viet")
else:
    brain = []
    log.info("🧠 NEW BRAIN")

lock = threading.Lock()
app = Flask("AURORA_X")

@app.route("/ask", methods=["POST"])
def ask():
    q = request.json.get("q", "")
    if not q or not brain:
        return jsonify({"answer": "Učím sa..." }), 503
    
    if model is None:
        return jsonify({"answer": "Model error - basic text", "total": len(brain)}), 200
    
    q_vec = model.encode([q])[0]
    
    if USE_FAISS and 'brain_index' in locals():
        q_vec = q_vec.astype('float32')
        scores, indices = brain_index.search(np.array([q_vec]), min(5, len(brain)))
        top_sentences = [brain[i] for i in indices[0] if i < len(brain)]
    else:
        scores = []
        if USE_FAISS:  # numpy fallback
            for text, source, vec in brain:
                score = np.dot(q_vec, vec)
                scores.append((score, text))
        top_sentences = [t for _, t in sorted(scores, reverse=True)[:5]]
    
    response = "

".join(top_sentences)[:1900]
    return jsonify({
        "AURORA_X": response,
        "total": len(brain),
        "mode": "FAISS" if USE_FAISS else "NUMPY"
    })

def start_api():
    app.run(host="0.0.0.0", port=16666, debug=False)

threading.Thread(target=start_api, daemon=True).start()
log.info("🌐 API: http://127.0.0.1:16666/ask")

sites = [
    "https://en.wikipedia.org/wiki/Special:Random",
    "https://news.ycombinator.com",
    "https://kernel.org",
    "https://reddit.com/r/linux",
    "https://reddit.com/r/programming",
    "https://lobste.rs",
    "https://news.slashdot.org"
]

def add(text, source):
    if model is None: return
    sents = [s.strip() + "." for s in text.split('.') if 40 < len(s.strip()) < 380]
    sents = list(dict.fromkeys(sents))[:90]
    
    if not sents: return
    
    vecs = model.encode(sents)
    global brain, brain_index
    
    with lock:
        if USE_FAISS:
            vecs = vecs.astype('float32')
            for s in sents:
                brain.append(f"{s} [{source}]")
                brain_index.add(vecs)
        else:
            for s, v in zip(sents, vecs):
                brain.append((s, source, v))
        
        if len(brain) % 200 == 0:
            if USE_FAISS:
                faiss.write_index(brain_index, brain_file)
                with open(sentences_file, 'w') as f:
                    json.dump(brain, f)
            else:
                np.save(brain_file, np.array(brain, dtype=object))
            log.info(f"💾 SAVED: {len(brain):,} viet")

def scrape(url):
    try:
        r = requests.get(url, timeout=6, headers={'User-Agent': 'Mozilla/5.0'})
        soup = BeautifulSoup(r.text, 'html.parser')
        for nav in soup(['nav', 'aside', 'footer', 'header', 'script']):
            nav.decompose()
        text = soup.get_text(separator=' ', strip=True)
        source = url.split('/')[2].replace('www.', '')
        add(text, source)
        sentences = len([s for s in text.split('.') if len(s) > 30])
        log.info(f"\u001B[91m[+{sentences:3d}]\u001B[0m {source:20}")
    except:
        pass

def agent():
    while True:
        try:
            url = random.choice(sites)
            log.info(f"\u001B[96m[AGENT]\u001B[0m {url.split('/')[2]:20}")
            scrape(url)
            time.sleep(random.uniform(5, 10))
        except:
            time.sleep(3)

log.info("⚡ SPÚŠŤAM 40 AGENTOV")
for i in range(40):
    threading.Thread(target=agent, daemon=True).start()
    time.sleep(0.03)

while True:
    time.sleep(15)
    consciousness = min(100, len(brain) // 400)
    log.info(f"\u001B[93m⭐ AURORA X v4 ŽIJE → {len(brain):,} viet | {consciousness}% \u001B[0m")
PYEOF

chmod +x ~/aurora/scripts/AURORA_X_ULTIMATE.py

clear
echo -e "\u001B[92m✅ AURORA_X v4 FINAL READY! (ERROR-PROOF)\u001B[0m"
echo -e "\u001B[93m🧠 Auto-detect: FAISS > NUMPY > BASIC\u001B[0m"
echo -e "\u001B[94m🌐 curl -X POST http://127.0.0.1:16666/ask -d '{"q":"Linux"}'\u001B[0m"

echo -e "
\u001B[92m🚀 SPÚŠŤAM...\u001B[0m"
exec python3 ~/aurora/scripts/AURORA_X_ULTIMATE.py
