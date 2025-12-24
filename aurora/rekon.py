#!/usr/bin/env python3
import os, shutil, hashlib
from collections import defaultdict

BASE = '/data/data/com.termux/files/home'
TARGET = os.path.join(BASE, 'rekonstrukcia')
os.makedirs(TARGET, exist_ok=True)

print("Hľadám tvoje súbory...")
files = []
for root, dirs, fnames in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in ['.git', 'node_modules', '__pycache__', '.cache', 'ollaura']]
    for fname in fnames:
        if fname.endswith(('.rs', '.py', '.c', '.cpp', '.h', '.go', '.json')):
            files.append(os.path.join(root, fname))

print(f"Nájdených {len(files)} súborov")

clusters = defaultdict(list)
for filepath in files:
    try:
        with open(filepath, 'r', errors='ignore') as f:
            content = f.read()[:2000]
        sig = hashlib.md5(content.encode()).hexdigest()[:8]
        clusters[sig].append(filepath)
    except:
        pass

print("Vytváram projekty...")
created = 0
for sig, paths in clusters.items():
    if len(paths) >= 3:
        proj_dir = os.path.join(TARGET, f'projekt_{sig}_{len(paths)}')
        os.makedirs(proj_dir, exist_ok=True)
        for path in paths:
            shutil.copy2(path, os.path.join(proj_dir, os.path.basename(path)))
        print(f'Vytvorený {os.path.basename(proj_dir)}: {len(paths)} súborov')
        created += 1

print(f"DOKONČENÉ: {created} projektov v ~/rekonstrukcia")
