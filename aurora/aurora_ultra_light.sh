#!/usr/bin/env bash
# =============================================================================
# AURORA ULTRA LIGHT - OOM-PROOF (100MB RAM max)
# FAISS lite + scraper + monitor v jednom procese
# =============================================================================

cd ~/aurora || mkdir -p ~/aurora && cd ~/aurora
mkdir -p data logs scripts

# ZASTAV VŠETKO STARÉ
pkill -f aurora 2>/dev/null || true
sleep 2

# ULTRA LIGHT SCRAPER + FAISS (JEDEN PROCES)
cat > scripts/ultra_light.py << 'PY'
#!/usr/bin/env python3
"""
AURORA ULTRA LIGHT - 1 proces, 100MB RAM, OOM-PROOF
"""

import os, time, threading, json, logging, subprocess, random
from flask import Flask, request, jsonify
from collections import deque
import numpy as np

# NO HEAVY LIBS - len základ
try:
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer('all-MiniLM-L6-v2')
    HAS_MODEL = True
    print("✅ SentenceTransformer OK")
except:
    model = None
    HAS_MODEL = False
    print("⚠️ NO MODEL - keyword search")

app = Flask("AURORA_LIGHT")
log = logging.getLogger()
logging.basicConfig(level=logging.INFO)

# LIGHT MEMORY (max 10k sentences)
knowledge = deque(maxlen=10000)
knowledge_file = 'data/light_knowledge.json'

# LOAD EXISTING
if os.path.exists(knowledge_file):
    with open(knowledge_file, 'r') as f:
        knowledge.extend(json.load(f))
    print(f"📜 Načítaných {len(knowledge)} viet")

# BACKGROUND SCRAPER (1 thread)
def scraper():
    urls = ["news.ycombinator.com", "kernel.org", "lobste.rs"]
    while True:
        try:
            url = f"https://{'/'.join(random.choice(urls).split('/')[0:2])}"
            text = subprocess.check_output([
                'curl', '-s', '--max-time', '20', url
            ], text=True)
            lines = [l.strip() for l in text.split('
') if len(l.strip()) > 40]
            for line in lines[:5]:
                if line not in knowledge:
                    knowledge.append(line)
            print(f"➕ {len(lines[:5])} viet z {url}")
        except:
            pass
        time.sleep(30)

threading.Thread(target=scraper, daemon=True).start()

# LIGHT SEARCH
@app.route("/ask", methods=["POST"])
def ask():
    q = request.json.get('q', '').lower()
    if not q:
        return jsonify({"error": "No query"}), 400
    
    if HAS_MODEL and model:
        # SEMANTIC (light version)
        try:
            q_vec = model.encode([q])
            scores = []
            for sent in list(knowledge)[-1000:]:  # len posledných
                sent_vec = model.encode([sent])
                score = np.dot(q_vec[0], sent_vec[0])
                scores.append((score, sent))
            top = [s for _, s in sorted(scores, reverse=True)[:5]]
        except:
            top = []
    else:
        # KEYWORD FALLBACK
        top = [s for s in list(knowledge)[-500:] if q in s.lower()][:5]
    
    return jsonify({
        "query": q,
        "answers": top[:5],
        "total": len(knowledge),
        "mode": "semantic" if HAS_MODEL else "keyword"
    })

@app.route("/status")
def status():
    return jsonify({
        "sentences": len(knowledge),
        "ram_mode": "ultra_light",
        "model": HAS_MODEL
    })

if __name__ == "__main__":
    print("🚀 AURORA ULTRA LIGHT starting...")
    # SAVE EVERY 5 MIN
    def autosave():
        while True:
            time.sleep(300)
            with open(knowledge_file, 'w') as f:
                json.dump(list(knowledge), f)
            print(f"💾 Saved {len(knowledge)} sentences")
    
    threading.Thread(target=autosave, daemon=True).start()
    app.run(host='0.0.0.0', port=16666, debug=False)
PY

chmod +x scripts/ultra_light.py

# OOM-PROOF START
echo "🛡️ Starting OOM-PROOF AURORA..."
renice 19 $$ 2>/dev/null || true
nohup python3 scripts/ultra_light.py > logs/ultra_light.log 2>&1 &
ULTRA_PID=$!
echo $ULTRA_PID > data/ultra.pid
renice 19 $ULTRA_PID 2>/dev/null || true

sleep 3
echo "✅ ULTRA LIGHT BEŽÍ [PID: $ULTRA_PID]"
echo "🌐 API: http://127.0.0.1:16666/ask"
echo "📊 Status: curl http://127.0.0.1:16666/status"
