#!/usr/bin/env python3
import threading, queue, time, random, requests, json, os
from bs4 import BeautifulSoup
from datetime import datetime

AGENTS = 72
MEMORY = queue.Queue()
SHARED_KNOWLEDGE = {}
lock = threading.Lock()

def scrape(url):
    try:
        r = requests.get(url, timeout=8, headers={'User-Agent': 'AuroraSwarm/6.6'})
        soup = BeautifulSoup(r.text, 'html.parser')
        text = ' '.join([p.text for p in soup.find_all(['p','h1','h2','h3','li'])])
        return text[:15000]
    except: return ""

def agent(id):
    targets = [
        "https://en.wikipedia.org/wiki/Special:Random",
        "https://wiki.debian.org/FrontPage",
        "https://www.kernel.org/",
        "https://gnu.org/philosophy/philosophy.html",
        "https://news.ycombinator.com",
        "https://arxiv.org/list/cs/recent",
        "https://lobste.rs",
        "https://www.reddit.com/r/MachineLearning/top/?t=day"
    ]
    while True:
        url = random.choice(targets)
        print(f"\033[91m[AGENT {id}]\033[0m → {url}")
        content = scrape(url)
        if content:
            with lock:
                for sentence in [s.strip() for s in content.split('.') if len(s)>20]:
                    SHARED_KNOWLEDGE[sentence] = SHARED_KNOWLEDGE.get(sentence,0) + 1
            MEMORY.put((id, url, len(content.split())))

        # vzájomné učenie – agenti čítajú pamäť ostatných
        try:
            other_id, other_url, words = MEMORY.get(timeout=1)
            if random.random() > 0.7:
                print(f"\033[92m[AGENT {id} ← {other_id}]\033[0m učí sa z {other_url} (+{words} slov)")
        except: pass
        
        time.sleep(random.uniform(2, 7))

print(f"[{datetime.now().strftime('%H:%M:%S')}] ULTRA SWARM spustený – {AGENTS} agentov + vzájomné učenie + real-time web")
for i in range(1, AGENTS+1):
    threading.Thread(target=agent, args=(i,), daemon=True).start()

while True:
    with lock:
        top = sorted(SHARED_KNOWLEDGE.items(), key=lambda x: x[1], reverse=True)[:5]
        print(f"\033[95m[SHARED TOP] {len(SHARED_KNOWLEDGE)} unikátnych faktov | TOP: {top[0][1]}× '{top[0][0][:80]}...'\033[0m")
    time.sleep(15)
