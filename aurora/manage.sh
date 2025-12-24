#!/bin/bash
case $1 in
start)
    nohup ~/aurora/aurora_x_final_safe.sh > ~/aurora/scraper.log 2>&1 &
    echo $! > ~/aurora/scraper.pid
    renice 19 $! 2>/dev/null || true
    ;;
faiss)
    pkill -f full_faiss_fixed.py
    nohup python3 ~/aurora/full_faiss_fixed.py > ~/aurora/faiss.log 2>&1 &
    echo $! > ~/aurora/faiss.pid
    renice 19 $! 2>/dev/null || true
    ;;
stop)
    pkill -f "aurora_x_final_safe|full_faiss_fixed"
    rm -f ~/aurora/*.pid
    ;;
status)
    echo -n "🧠 Knowledge: "
    if [ -f ~/aurora/data/knowledge.txt ]; then
        wc -l < ~/aurora/data/knowledge.txt
    else
        echo "No knowledge.txt"
    fi

    echo -n "📜 Scraper: "
    if [ -f ~/aurora/scraper.pid ]; then
        ps -p $(cat ~/aurora/scraper.pid) -o pid,cmd --no-headers || echo "Dead/Stopped"
    else
        echo "No scraper.pid"
    fi

    echo -n "🤖 FAISS: "
    if [ -f ~/aurora/faiss.pid ]; then
        ps -p $(cat ~/aurora/faiss.pid) -o pid,cmd --no-headers || echo "Dead/Stopped"
    else
        echo "No faiss.pid"
    fi

    curl -s http://127.0.0.1:16666/status 2>/dev/null | jq . || echo "API down"
    ;;
*)
    echo "Usage: $0 {start|faiss|stop|status}"
    ;;
esac
