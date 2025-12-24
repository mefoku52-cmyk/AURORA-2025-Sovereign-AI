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
