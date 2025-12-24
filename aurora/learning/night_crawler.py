#!/usr/bin/env python3
import requests, time, os
sources = [
    "https://www.reddit.com/r/conspiracy/new.json?limit=15",
    "https://www.reddit.com/r/MachineLearning/new.json?limit=15",
    "https://hn.algolia.com/api/v1/search?tags=front_page&hits=15"
]
for url in sources:
    try:
        data = requests.get(url, headers={'User-agent': 'Aurora150'}).json()
        sentences = []
        if "reddit" in url:
            for post in data['data']['children']:
                sentences.append(post['data']['title'])
        else:
            for hit in data['hits']:
                sentences.append(hit['title'])
        with open("/data/data/com.termux/files/home/aurora/data/knowledge.txt", "a") as f:
            for s in sentences:
                if len(s) > 30 and s not in open(f.name).read():
                    f.write(s + "\n")
        print(f"[LEARNING 2025] +{len(sentences)} nových viet")
    except: pass
    time.sleep(5)
os.system("pkill -f full_faiss_fixed.py; nohup python3 full_faiss_fixed.py &>/dev/null &")
