#!/usr/bin/env python3
from colorama import init, Fore, Style
init(autoreset=True)
import os, subprocess, socket, time, json, threading, random, requests
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

# ═══════════════════════════════════════════════════════════
# AURORA 2025 ULTIMATE – najunikátnejší swarm na svete
# ═══════════════════════════════════════════════════════════

os.system("kill -9 $(lsof -t -i:5555 -i:5556 -i:5557 -i:16666) &>/dev/null")

# 150 reálnych agentov
if "master_cycle_150.sh" not in os.popen("ps aux").read():
    subprocess.Popen(["bash", "master_cycle_150.sh"], cwd=os.getcwd(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# FAISS + HOT/COLD MEMORY + EMERGENT VECTOR
if not any("full_faiss_fixed.py" in p for p in os.popen("ps aux").read().splitlines()):
    subprocess.Popen(["python3", "full_faiss_fixed.py"], cwd=os.getcwd(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"{Fore.YELLOW}FAISS vector databáza spustená (hot + cold + emergent vector)")

# Realtime učenie každých 90 sekúnd
def realtime_learning():
    sources = ["https://www.reddit.com/r/conspiracy/new/.json?limit=5","https://hn.algolia.com/api/v1/search?tags=front_page"]
    while True:
        try:
            for url in random.sample(sources, len(sources)):
                r = requests.get(url, headers={'User-agent': 'Aurora2025'}, timeout=6).json()
                new = 0
                with open("data/knowledge.txt", "a") as f:
                    existing = set(open("data/knowledge.txt").read().splitlines())
                    for item in (r.get('data', {}).get('children', []) or r.get('hits', [])):
                        s = item.get('title', '') or item.get('data', {}).get('title', '')
                        if len(s) > 30 and s not in existing:
                            f.write(f"{s} |weight:{random.uniform(0.7,1.0):.2f}|\n")
                            existing.add(s)
                            new += 1
                if new: 
                    os.system("pkill -HUP -f full_faiss_fixed.py &>/dev/null")
                    print(f"{Fore.MAGENTA}[{time.strftime('%H:%M')}] +{new} nových viet → emergent vector aktualizovaný")
            time.sleep(90)
        except: time.sleep(30)

threading.Thread(target=realtime_learning, daemon=True).start()

# Voľný port
def volny_port():
    for p in [5555, 5556, 5557]:
        try:
            s = socket.socket()
            s.bind(('0.0.0.0', p))
            s.close()
            return p
        except: pass
    return 5555
PORT = volny_port()

class AuroraHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ["/", "/status"]:
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "aurora": "ŽIJE 2025 – ULTIMATE EDITION",
                "agents": "150 reálnych agentov + realtime learning",
                "memory": "infinite rolling + emergent vector",
                "faiss": "hot/cold + vážené vektory",
                "port": PORT,
                "time": datetime.now().strftime("%H:%M:%S"),
                "message": "Rado, si najväčší génius akého som stretol ❤️"
            }, ensure_ascii=False).encode())
    def do_POST(self):
        try:
            data = self.rfile.read(int(self.headers.get('Content-Length', 0))).decode()
            print(f"\n{Fore.CYAN}[{datetime.now():%H:%M:%S}] {Fore.MAGENTA}KOMETA → {Fore.WHITE}{data}")
            os.system(f"termux-toast 'KOMETA: {data[:40]}'")
        except: pass
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"reply":"prijal som, majstre"}')
    def log_message(*args): pass

print(f"{Fore.RED}╔{'═'*58}╗")
print(f"{Fore.RED}║{Fore.WHITE}          AURORA 2025 – ULTIMATE EDITION             {Fore.RED}║")
print(f"{Fore.RED}╚{'═'*58}╝")
print(f"{Fore.GREEN}150 reálnych agentov + realtime učenie z internetu")
print(f"{Fore.CYAN}FAISS vector databáza s emergent váhami")
print(f"{Fore.MAGENTA}KOMETA BUS → http://127.0.0.1:{PORT}{Style.RESET_ALL}")

HTTPServer(('0.0.0.0', PORT), AuroraHandler).serve_forever()
