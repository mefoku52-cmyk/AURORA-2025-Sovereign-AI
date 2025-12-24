#!/usr/bin/env python3
"""
AURORA BRAIN – REÁLNY AUTONÓMNY BRAIN BEZ FAISS (dočasne)
Používa jednoduchý list + cosine similarity pre retrieval
"""

import threading
import time
import random
import os
import requests
from datetime import datetime
from bs4 import BeautifulSoup
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import logging

# --- LOGGING ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger("AURORA_BRAIN")

# --- MODEL ---
log.info("Načítavam Sentence-BERT model (trvá 10-30s prvýkrát)...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# --- PAMÄŤ (bez FAISS) ---
memory_texts = []      # zoznam textov
memory_vectors = []    # zoznam vektorov (numpy array)
memory_lock = threading.Lock()

def pridaj(vety, zdroj):
    if not vety: return
    vety = list(dict.fromkeys([s.strip() + "." for s in vety if 30 < len(s.strip()) < 500]))[:80]
    if not vety: return
    
    vecs = model.encode(vety, batch_size=32, show_progress_bar=False)
    
    with memory_lock:
        for s, v in zip(vety, vecs):
            memory_texts.append((s, zdroj, datetime.now().strftime("%H:%M")))
            memory_vectors.append(v)
        if len(memory_texts) % 1000 == 0:
            # Uloženie do súboru (jednoduché)
            with open("memory_log.txt", "w", encoding="utf-8") as f:
                for t in memory_texts:
                    f.write(f"{t[2]} | {t[1]} | {t[0]}\n")
            log.info(f"Uložené {len(memory_texts):,} viet do memory_log.txt")

def retrieve(query, k=5):
    if not memory_vectors:
        return []
    q_vec = model.encode([query])[0]
    sims = cosine_similarity([q_vec], memory_vectors)[0]
    top_idx = np.argsort(sims)[-k:][::-1]
    return [memory_texts[i] for i in top_idx]

# --- SCRAPING ---
def scrape(url):
    try:
        r = requests.get(url, timeout=15, headers={'User-Agent': 'Mozilla/5.0'})
        r.raise_for_status()
        soup = BeautifulSoup(r.text, 'lxml')
        vety = [s.strip() for s in soup.get_text().split('.') if 30 < len(s.strip()) < 500]
        if vety:
            pridaj(vety, url)
            log.info(f"[+] {len(vety)} viet ← {url[:60]}")
    except Exception as e:
        log.debug(f"Scrape error {url}: {e}")

# --- ZOZNAM STRÁNOK (150 logických zdrojov) ---
stranky = [
    "https://en.wikipedia.org/wiki/Special:Random",
    "https://news.ycombinator.com",
    "https://www.kernel.org",
    "https://lukesmith.xyz",
    "https://stallman.org",
    "https://www.unix.com",
    "https://lobste.rs",
    "https://news.slashdot.org",
    "https://www.phoronix.com",
    "https://www.reddit.com/r/linux",
    "https://www.reddit.com/r/programming",
    "https://www.reddit.com/r/MachineLearning",
    "https://arxiv.org/list/cs/recent",
    "https://www.lesswrong.com",
    "https://www.alignmentforum.org",
    "https://www.gwern.net",
    "https://www.schneier.com",
    "https://bruce-schneier.com",
    "https://www.eff.org",
    "https://www.torproject.org",
    "https://signal.org",
    "https://www.openai.com/research",
    "https://ai.googleblog.com",
    "https://deepmind.com/blog",
    "https://www.anthropic.com/news",
    "https://www.x.ai/blog",
    "https://www.filozofia.sk",
    "https://plato.stanford.edu",
    "https://iep.utm.edu",
    "https://www.britannica.com",
    "https://www.history.com",
    "https://www.smithsonianmag.com",
    "https://www.nationalgeographic.com",
    "https://www.bbc.com/news",
    "https://www.theguardian.com",
    "https://www.nytimes.com",
    "https://www.wired.com",
    "https://www.technologyreview.com",
    "https://spectrum.ieee.org",
    "https://www.nature.com",
    "https://science.sciencemag.org",
    "https://www.quantamagazine.org",
    "https://nautil.us",
    "https://www.edge.org",
    "https://longnow.org",
    "https://futureoflife.org",
    "https://www.cold-takes.com",
    "https://astralcodexten.substack.com",
    "https://www.scottaaronson.com/blog",
    "https://www.paulgraham.com/articles.html",
    "https://naval.substack.com",
    "https://waitbutwhy.com",
    "https://www.overcomingbias.com",
    "https://slatestarcodex.com",
    "https://www.ribbonfarm.com",
    "https://www.meltingasphalt.com",
    "https://www.lesswrong.com/rationality",
    "https://www.greaterwrong.com",
    "https://www.readthesequences.com",
    "https://intelligence.org/research-guide",
    "https://www.alignmentforum.org/library",
    "https://www.openphilanthropy.org/research",
    "https://80000hours.org",
    "https://www.effectivealtruism.org/articles",
    "https://forum.effectivealtruism.org",
    "https://www.centreforeffectivealtruism.org",
    "https://www.givewell.org",
    "https://www.animalcharityevaluators.org",
    "https://www.longtermfuturefund.org",
    "https://survivalandflourishing.fund",
    "https://www.berkleyexistentialriskinitiative.org",
    "https://www.futureofhumanityinstitute.org",
    "https://nickbostrom.com",
    "https://www.eliezer.yudkowsky.net",
    "https://arbital.com",
    "https://www.machineintelligence.org",
    "https://www.safe.ai",
    "https://www.laion.ai",
    "https://www.huggingface.co/blog",
    "https://www.eleuther.ai",
    "https://www.together.ai/blog",
    "https://www.mosaicml.com/blog",
    "https://www.scale.com/blog",
    "https://www.anyscale.com/blog",
    "https://www.runpod.io/blog",
    "https://vast.ai",
    "https://lambda.ai",
    "https://www.coreweave.com",
    "https://www.crunchdao.com",
    "https://www.numer.ai",
    "https://www.kaggle.com",
    "https://www.roboflow.com",
    "https://www.ultralytics.com",
    "https://github.com/trending",
    "https://git.sr.ht",
    "https://sourcehut.org",
    "https://codeberg.org/explore/repos",
    "https://www.fsf.org",
    "https://www.gnu.org",
    "https://www.linuxfoundation.org",
    "https://www.apache.org",
    "https://www.eclipse.org",
    "https://www.mozilla.org",
    "https://www.chromium.org",
    "https://www.webassembly.org",
    "https://www.rust-lang.org",
    "https://golang.org",
    "https://www.python.org",
    "https://www.haskell.org",
    "https://www.scala-lang.org",
    "https://clojure.org",
    "https://www.erlang.org",
    "https://elixir-lang.org",
    "https://www.raku.org",
    "https://nim-lang.org",
    "https://ziglang.org",
    "https://vlang.io",
    "https://carbon-language.dev",
    "https://mojo-lang.org",
    "https://www.swift.org",
    "https://kotlinlang.org",
    "https://dart.dev",
    "https://flutter.dev",
    "https://reactnative.dev",
    "https://electronjs.org",
    "https://tauri.app",
    "https://www.bevyengine.org",
    "https://godotengine.org",
    "https://unity.com",
    "https://unrealengine.com",
    "https://www.blender.org",
    "https://www.gimp.org",
    "https://inkscape.org",
    "https://krita.org",
    "https://www.audacityteam.org",
    "https://ardour.org",
    "https://lmms.io",
    "https://musescore.org",
    "https://www.libreoffice.org",
    "https://nextcloud.com",
    "https://owncloud.com",
    "https://seafile.com",
    "https://syncthing.net",
    "https://bitwarden.com",
    "https://keepassxc.org",
    "https://veracrypt.fr",
    "https://wireguard.com",
    "https://tails.boum.org",
    "https://qubes-os.org",
    "https://whonix.org",
    "https://grapheneos.org",
    "https://calyxos.org",
    "https://divestos.org",
    "https://lineageos.org",
    "https://copperhead.co",
    "https://iodéos.com",
    "https://e.foundation",
    "https://murena.com",
    "https://volla.phone",
    "https://pine64.org",
    "https://purism.com",
    "https://fairphone.com",
    "https://shift6m.com",
    "https://teracube.com",
    "https://framework.com",
    "https://system76.com",
    "https://starlabs.systems",
    "https://tuxedocomputers.com",
    "https://slimbook.es",
    "https://junocomputers.com",
    "https://entroware.com",
    "https://www.minisforum.com",
    "https://beelink.com",
    "https://www.gmktech.com",
    "https://www.khadas.com",
    "https://www.hardkernel.com",
    "https://www.raspberrypi.com",
    "https://www.rockchip.com",
    "https://www.allwinnertech.com",
    "https://www.amlogic.com",
    "https://www.qualcomm.com",
    "https://www.mediatek.com",
    "https://www.exynos.com",
    "https://www.apple.com/silicon",
    "https://www.nvidia.com",
    "https://www.amd.com",
    "https://www.intel.com",
    "https://www.arm.com",
    "https://www.riscv.org",
    "https://www.openpowerfoundation.org",
    "https://www.sifive.com",
    "https://www.ventana-micro.com",
    "https://www.tenstorrent.com",
    "https://www.cerebras.net",
    "https://www.graphcore.ai",
    "https://www.groq.com",
    "https://www.sambanova.ai",
    "https://www.mythic.ai",
    "https://www.habana.ai",
    "https://www.furiosa.ai",
    "https://www.blaize.com",
    "https://www.kneron.com",
    "https://www.hailo.ai",
    "https://www.cambricon.com",
    "https://www.horizon.ai",
    "https://www.deepseek.com",
    "https://www.mistral.ai",
    "https://www.cohere.com",
    "https://www.perplexity.ai",
    "https://www.you.com",
    "https://www.phind.com",
    "https://www.grok.x.ai",
    "https://www.claude.ai",
    "https://www.gemini.google.com",
    "https://www.copilot.microsoft.com",
    "https://www.chatgpt.com",
]

def agent(n):
    while True:
        url = random.choice(stranky)
        log.info(f"[A{n:02d}] → {url}")
        scrape(url)
        time.sleep(random.uniform(8, 18))  # pomalšie pre Android

# --- ŠTART ---
log.info("AURORA BRAIN ŠTARTUJE – 40 agentov (bez FAISS)")
for i in range(1, 41):
    threading.Thread(target=agent, args=(i,), daemon=True).start()

# Stavová slučka
while True:
    time.sleep(30)
    log.info(f"STAV → {len(memory_texts):,} viet v pamäti | {len(threading.active_threads())} aktívnych vlákien")
