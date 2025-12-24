#!/usr/bin/env bash
# =============================================================================
# AURORA COMPLETE SYSTEM - SCRAPER + FAISS MOZOG + API + MONITOR
# Port 16666 = FAISS API | Port 16665 = Scraper Control
# =============================================================================

cd ~/aurora || mkdir -p ~/aurora && cd ~/aurora
mkdir -p data logs scripts

# 1. SCAPER (knowledge.txt filler)
cat > scripts/scraper.sh << 'SCR'
#!/bin/bash
cd "$(dirname "$0")/../"
MAX_AGENTS=6
while :; do
    CURRENT=$(jobs -p | wc -l)
    if (( CURRENT < MAX_AGENTS )); then
        (
            URLS=("news.ycombinator.com" "kernel.org" "lobste.rs" "reddit.com/r/linux" "news.slashdot.org" "en.wikipedia.org/wiki/Special:Random")
            URL=${URLS[$RANDOM % ${#URLS[@]}]}
            sleep $((20 + RANDOM % 25))
            timeout 30 curl -sL --max-time 25 "https://$URL" | lynx -dump -nolist | grep '^[[:space:]]*[A-Z]' | head -15 >> data/knowledge.txt
            echo "[$(date +%H:%M)] +knowledge <- $URL" >> logs/scraper.log
        ) &
        renice 19 $! 2>/dev/null || true
    fi
    sleep 7
done
SCR

chmod +x scripts/scraper.sh

# 2. FAISS MOZOG (knowledge.txt → AI brain)
cat > scripts/faiss_brain.py << 'PY'
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
PY

chmod +x scripts/faiss_brain.py

# 3. MONITOR + CONTROL
cat > scripts/control.sh << 'CTL'
#!/bin/bash
cd "$(dirname "$0")/../"
case $1 in
    start)
        nohup ./scripts/scraper.sh > logs/scraper.log 2>&1 &
        echo $! > data/scraper.pid
        nohup python3 ./scripts/faiss_brain.py > logs/faiss.log 2>&1 &
        echo $! > data/faiss.pid
        echo "✅ ALL STARTED"
        ;;
    stop) pkill -f "scraper.sh|faiss_brain.py"; rm -f data/*.pid; echo "🛑 STOPPED"; ;;
    status)
        echo "🧠 FAISS: $(cat data/faiss.pid 2>/dev/null && ps -p $(cat data/faiss.pid) && echo OK || echo DEAD)"
        echo "📜 Scraper: $(cat data/scraper.pid 2>/dev/null && ps -p $(cat data/scraper.pid) && echo OK || echo DEAD)"
        echo "💾 Knowledge: $(wc -l < data/knowledge.txt 2>/dev/null || echo 0) lines"
        curl -s http://127.0.0.1:16666/status 2>/dev/null | jq . || echo "API down"
        ;;
    rebuild) python3 scripts/faiss_brain.py --rebuild; echo "🔄 REBUILT"; ;;
esac
CTL

chmod +x scripts/control.sh

# 4. START ALL
./scripts/control.sh start

echo "🚀 AURORA COMPLETE SYSTEM READY!"
echo "🌐 FAISS API: http://127.0.0.1:16666/ask"
echo "📊 Status: ~/aurora/scripts/control.sh status"
