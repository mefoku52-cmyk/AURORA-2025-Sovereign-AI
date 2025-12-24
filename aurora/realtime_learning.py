#!/usr/bin/env python3
from colorama import init, Fore, Style
init(autoreset=True)
import requests, time, os, random

sources = [
    "https://nitter.net/elonmusk/rss",
    "https://nitter.net/realDonaldTrump/rss",
    "https://nitter.net/search/rss?q=ai",
    "https://nitter.net/search/rss?q=bitcoin",
    "https://nitter.net/search/rss?q=war",
    "https://www.reddit.com/r/conspiracy/new/.json?limit=5",
    "https://www.reddit.com/r/technology/new/.json?limit=5",
    "https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=10"
]

print(f"{Fore.YELLOW}REALTIME LEARNING 2025 AKTIVOVANÝ – učíme sa každých 60s{Style.RESET_ALL}")

while True:
    new = 0
    for url in random.sample(sources, len(sources)):
        try:
            r = requests.get(url, headers={'User-agent': 'Aurora2025'}, timeout=8).json()
            sentences = []
            if "reddit" in url:
                for item in r['data']['children']:
                    sentences.append(item['data']['title'])
            else:
                for hit in r['hits']:
                    sentences.append(hit['title'])

            with open("data/knowledge.txt", "a") as f:
                existing = set(open("data/knowledge.txt").read().splitlines())
                for s in sentences:
                    if len(s) > 25 and s not in existing:
                        f.write(s + "\n")
                        print(f"{Fore.GREEN}   [+] {s[:80]}{'...' if len(s)>80 else ''}")
                        new += 1
                        if "trump" in s.lower() or "elon" in s.lower() or "ai" in s.lower() or "war" in s.lower():
                            os.system("termux-notification --title \"AURORA ALERT\" --content \"...\" --vibrate 1000")
        except: pass
    if new:
        os.system("pkill -HUP -f full_faiss_fixed.py &>/dev/null")
        print(f"{Fore.MAGENTA}[{time.strftime('%H:%M:%S')}] +{new} nových viet → spím 60s{Style.RESET_ALL}")
    time.sleep(60)

    # X/TWITTER REALTIME (cez nitter – funguje 100 % bez API kľúča)
    twitter_sources = [
        "https://nitter.net/elonmusk/rss",
        "https://nitter.net/realDonaldTrump/rss",
        "https://nitter.net/search/rss?q=ai+OR+artificial+intelligence",
        "https://nitter.net/search/rss?q=bitcoin+OR+crypto",
        "https://nitter.net/search/rss?q=war+OR+ukraine+OR+russia",
        "https://nitter.net/search/rss?q=tesla+OR+spacex",
    ]
    for url in random.sample(twitter_sources, len(twitter_sources)):
        try:
            import xml.etree.ElementTree as ET
            r = requests.get(url, headers={'User-agent': 'Aurora2025'}, timeout=8)
            root = ET.fromstring(r.text)
            for item in root.findall('.//item'):
                title = item.find('title').text if item.find('title') is not None else ""
                desc = item.find('description').text if item.find('description') is not None else ""
                text = (title + " " + desc).strip()
                if len(text) > 30 and "http" not in text[:100]:
                    with open("data/knowledge.txt", "a") as f:
                        if text not in open("data/knowledge.txt").read():
                            f.write(f"{text} |weight:1.0|twitter\n")
                            print(f"{Fore.RED}   TWITTER FIRE → {text[:90]}{'...' if len(text)>90 else ''}")
        except: pass
