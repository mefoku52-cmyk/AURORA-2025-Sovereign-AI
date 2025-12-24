#!/usr/bin/env python3
import os, shutil, hashlib
from collections import defaultdict

BASE = '/data/data/com.termux/files/home'
TARGET = os.path.join(BASE, 'rekonstrukcia')
os.makedirs(TARGET, exist_ok=True)

print("Hľadám LEN KÓD...")
files = []
for root, dirs, fnames in os.walk(BASE):
    dirs[:] = [d for d in dirs if d not in ['.git', 'node_modules', '__pycache__', '.cache', 'ollaura']]
    for fname in fnames:
        if fname.endswith(('.rs', '.py', '.c', '.cpp', '.h', '.go')) and len(fname) > 5:  # LEN KÓD, nie configy
            files.append(os.path.join(root, fname))

print(f"Nájdených {len(files)} KÓDOVÝCH súborov")

clusters = defaultdict(list)
for filepath in files:
    try:
        with open(filepath, 'r', errors='ignore') as f:
            content = f.read()
        if len(content) > 100:  # LEN relevantné súbory
            sig = hashlib.md5(content.encode()).hexdigest()[:8]
            clusters[sig].append(filepath)
    except:
        pass

print("Vytváram TOP projekty...")
created = 0
for sig, paths in sorted(clusters.items(), key=lambda x: len(x[1]), reverse=True):
    if len(paths) >= 3:
        proj_dir = os.path.join(TARGET, f'projekt_{sig}_{len(paths)}')
        os.makedirs(proj_dir, exist_ok=True)
        for path in paths[:10]:  # MAX 10 na cluster
            shutil.copy2(path, os.path.join(proj_dir, os.path.basename(path)))
        print(f'✅ {os.path.basename(proj_dir)}: {len(paths)} súborov')
        created += 1
        if created >= 20:  # MAX 20 TOP projektov
            break

print(f"DOKONČENÉ: TOP {created} projektov v ~/rekonstrukcia")
print("Skontroluj: ls ~/rekonstrukcia/")
