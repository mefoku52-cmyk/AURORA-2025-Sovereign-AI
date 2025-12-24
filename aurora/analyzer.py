#!/usr/bin/env python3
"""
Vysokolevelový Termux File Analyzer & Clusterer.
Modulárny, rýchly, analytický – pre 'chirurgické' spojenie modulov (kernel/bus/LLM).
"""
import os
import re
import json
import hashlib
import argparse
from pathlib import Path
from collections import defaultdict, Counter
from typing import List, Tuple, Dict, Any
try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False
    tqdm = lambda x, desc: x  # Fallback

class FileFinder:
    """Nájde relevantné súbory efektívne."""
    EXTENSIONS = {'.sh', '.py', '.rs', '.c', '.cpp', '.h', '.go', '.json', '.yaml', '.toml'}
    EXCLUDE_DIRS = {'__pycache__', '.git', 'node_modules', '.cache', 'ollaura', '.venv', 'target', 'build'}

    @staticmethod
    def find(base: Path) -> List[Path]:
        files = []
        for path in tqdm(base.rglob('*'), desc="Scanning files") if HAS_TQDM else base.rglob('*'):
            if path.is_file() and path.suffix in FileFinder.EXTENSIONS and \
               not any(ex in path.parts for ex in FileFinder.EXCLUDE_DIRS):
                files.append(path)
        return files

class CodeAnalyzer:
    """Extrahuje signály z kódu (defs, imports, structs)."""
    # Rozšírené regex pre multi-lang
    DEF_PATTERNS = [
        r'(def|fn|func|void|int|main)\s+(\w+)',  # Funs
        r'(class|struct|enum)\s+(\w+)',          # Štruktúry
    ]
    IMP_PATTERNS = [
        r'(import|from|#include\s*<|use\s+|require)\s+([^;\n{}()]+)',  # Imports multi-lang
    ]

    @staticmethod
    def analyze(file_path: Path) -> Dict[str, Any]:
        try:
            content = file_path.read_text(errors='ignore')
            lang = file_path.suffix
            defs = []
            for pat in CodeAnalyzer.DEF_PATTERNS:
                defs.extend(re.findall(pat, content, re.M))
            imps = []
            for pat in CodeAnalyzer.IMP_PATTERNS:
                imps.extend(re.findall(pat, content, re.M | re.I))
            
            # Top 20 unikátne (pre lepší hash)
            top_defs = ' '.join([f"{kw}_{name}" for kw, name in defs[:20]])
            top_imps = ' '.join([imp.strip() for _, imp in imps[:20]])
            sig = hashlib.md5((top_defs + ' ' + top_imps).encode()).hexdigest()[:12]  # Dlhší hash
            
            return {
                'path': str(file_path),
                'basename': file_path.name,
                'lang': lang,
                'size': file_path.stat().st_size,
                'defs_count': len(defs),
                'imps_count': len(imps),
                'sig': sig,
                'sample_defs': defs[:5],
                'sample_imps': imps[:5]
            }
        except Exception:
            return {}

class Clusterer:
    """Klastrovanie + analýza."""
    def __init__(self):
        self.clusters = defaultdict(list)

    def add(self, analysis: Dict):
        if analysis:
            self.clusters[analysis['sig']].append(analysis)

    def stats(self) -> Dict:
        stats = {}
        for sig, cluster in self.clusters.items():
            langs = Counter(a['lang'] for a in cluster)
            total_size = sum(a['size'] for a in cluster)
            stats[sig] = {
                'count': len(cluster),
                'langs': dict(langs),
                'total_size_kb': total_size / 1024,
                'avg_defs': sum(a['defs_count'] for a in cluster) / len(cluster),
                'files': [a['basename'] for a in cluster]
            }
        return {k: v for k, v in stats.items() if v['count'] > 1}  # Len >1

    def print_table(self, stats: Dict):
        print('=== PLÁNOVANÁ ŠTRUKTÚRA (Klastry >1 súboru) ===')
        print('| Projekt | Súbory | Jazyky | Veľkosť KB | Priem. Defs |')
        print('|---------|--------|--------|------------|-------------|')
        for sig, data in stats.items():
            langs_str = ', '.join([f"{k}:{v}" for k,v in data['langs'].items()])
            print(f"| projekt_{sig} | {data['count']} | {langs_str} | {data['total_size_kb']:.1f} | {data['avg_defs']:.1f} |")

def main():
    parser = argparse.ArgumentParser(description="Termux Analyzer v2.0")
    parser.add_argument('--base', default='/data/data/com.termux/files/home', help='Base dir')
    parser.add_argument('--save-json', help='Save stats to JSON')
    parser.add_argument('--deep', action='store_true', help='Print cluster details')
    args = parser.parse_args()

    base = Path(args.base)
    print(f'Skenujem: {base}')

    # Fázy
    files = FileFinder.find(base)
    print(f'Najdených {len(files)} súborov')

    clusterer = Clusterer()
    for f in tqdm(files, desc="Analyzing") if HAS_TQDM else files:
        analysis = CodeAnalyzer.analyze(f)
        clusterer.add(analysis)

    stats = clusterer.stats()
    clusterer.print_table(stats)

    if args.deep:
        print('\n=== DETAILY CLUSTEROV ===')
        for sig, cluster in clusterer.clusters.items():
            if len(cluster) > 1:
                print(f"\nprojekt_{sig}:")
                for a in cluster:
                    print(f"  - {a['basename']} ({a['lang']}, defs:{a['defs_count']}, size:{a['size']/1024:.1f}KB)")

    if args.save_json:
        json.dump(stats, open(args.save_json, 'w'), indent=2)
        print(f'JSON uložený: {args.save_json}')

    print('\nPOTVRD? (ano/nie)')
    confirm = input().strip().lower()
    print('Ano!' if confirm in ['ano', 'yes', 'y'] else 'Nie.')

if __name__ == '__main__':
    main()
