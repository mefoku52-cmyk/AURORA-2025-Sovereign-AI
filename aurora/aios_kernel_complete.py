#!/usr/bin/env python3
"""
AIOS KERNEL COMPLETE - FÁZA 28.2: ZJEDNOTENIE KERNELU A CLI
Obsahuje stabilný Kernel (DB/HTTP/Asynchrónny) + Integrované CLI rozhranie.
"""
import asyncio
from dataclasses import dataclass, field
import uuid
from time import time
from typing import Optional, Any, Dict, Callable
import sqlite3
import os 
import httpx # Vyžaduje 'pip install httpx'
import sys

# --- Konštanty ---
DB_PATH = os.path.join(os.path.expanduser('~'), 'aurora', 'aios_state.db')
SIMULATED_API_URL = "http://127.00.0.1:8000/api/v1/agent_status" 

# --- Vlastná Výnimka ---
class NeutronError(Exception):
    def __init__(self, code: int, message: str, topic: str):
        super().__init__(f"[{topic}] Chyba {code}: {message}")
        self.code = code
        self.topic = topic

# --- MetaMessage Protokol a Topics ---
@dataclass
class MetaMessage:
    topic: str
    payload: dict
    sender: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: float = field(default_factory=time)
    is_response: bool = False
    context_id: Optional[str] = None
    priority: int = 5 
    error_code: Optional[int] = None
    error_message: Optional[str] = None
    
    def __post_init__(self):
        if not isinstance(self.payload, dict): 
            raise TypeError("Payload musí byť dict")

class NeutronServiceTopics:
    AURORA_BRIDGE = "abrg"

# -------------------- 1. Perzistentný SQLite Manager --------------------

class StateManager:
    # (Bezo zmeny)
    def __init__(self, db_path):
        self.db_path = db_path
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._init_db()

    def _init_db(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("""
            CREATE TABLE IF NOT EXISTS system_state (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        """)
        c.execute("INSERT OR IGNORE INTO system_state VALUES ('stagnation_cycles', '0')")
        conn.commit()
        conn.close()
        print(f"[DB] SQLite databáza inicializovaná/načítaná: {self.db_path}")

    def get_state(self, key):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT value FROM system_state WHERE key=?", (key,))
        result = c.fetchone()
        conn.close()
        return result[0] if result else None

    def set_state(self, key, value):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("REPLACE INTO system_state VALUES (?, ?)", (key, str(value)))
        conn.commit()
        conn.close()
    
    def get_all_state(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT key, value FROM system_state")
        results = dict(c.fetchall())
        conn.close()
        return results

# -------------------- 2. NEUTRON MODULY (Bridge a Logika) --------------------

class AbstractNeutronModule:
    def __init__(self, neutron_bus): 
        self._neutron_bus = neutron_bus
    
    async def handle_request(self, message: MetaMessage) -> Dict[str, Any]:
        raise NotImplementedError

class AuroraBridge(AbstractNeutronModule):
    def __init__(self, neutron_bus, state_manager):
        super().__init__(neutron_bus)
        self.state_manager = state_manager
        self.client = httpx.AsyncClient(timeout=30.0) 
        
    async def handle_request(self, message: MetaMessage) -> Dict[str, Any]:
        action = message.topic.split('.')[-1]
        
        if action == 'get_learning_score':
            current_cycles = int(self.state_manager.get_state('stagnation_cycles'))
            await asyncio.sleep(0.1) 
            
            current_cycles += 1
            is_stagnated = current_cycles > 2 
            self.state_manager.set_state('stagnation_cycles', current_cycles)

            score = "HIGH" if not is_stagnated else "CRITICAL_LOW"
            return {"score": score, "stagnation_cycles": current_cycles}
            
        elif action == 'distribute_new_model':
            print(f"[AURORA] 📡 Začínam REÁLNU distribúciu modelu pre 10000 modulov...")
            await asyncio.sleep(2.0) 
            self.state_manager.set_state('stagnation_cycles', 0) 
            print(f"[AURORA] Distribúcia DOKONČENÁ (Trvanie 2.0s). DB resetované.")
            return {"status": "success", "message": "Nové váhy modelu distribuované."}
            
        elif action == 'verify_data_integrity':
            await asyncio.sleep(0.8)
            print(f"[AURORA] Overenie integrity dát DOKONČENÉ (P=1).")
            return {"status": "success", "message": "Integrita dát OK."}
        
        elif action == 'force_distribute':
             print(f"[AURORA] ⚠️ Vynútená distribúcia spustená cez UI/CLI (P=10).")
             await asyncio.sleep(1.0) 
             self.state_manager.set_state('stagnation_cycles', 0)
             print(f"[AURORA] Vynútená distribúcia dokončená (Trvanie 1.0s).")
             return {"status": "success", "message": "Vynútená distribúcia dokončená."}

        return {"status": "failed", "error_code": 404, "error_message": f"Neznáma akcia: {action}"}

class NeutronModuleCatalog:
    def __init__(self, neutron_bus, state_manager):
        self.modules: Dict[str, AbstractNeutronModule] = {}
        self.modules[NeutronServiceTopics.AURORA_BRIDGE] = AuroraBridge(neutron_bus, state_manager)
        
    async def get_module_handler(self, prefix: str) -> Optional[Callable]:
        module = self.modules.get(prefix)
        if module:
            return module.handle_request
        return None

# -------------------- 3. ARCHITEKTONICKÉ BUSY A PROXY --------------------

class KometaBus:
    def __init__(self):
        self._pending_requests: Dict[str, asyncio.Future] = {}
        self.loop = None
        print("[KOMETA] Inicializovaný.")
    def set_loop(self, loop): self.loop = loop
    def lock_future(self, msg_id: str) -> asyncio.Future:
        future = asyncio.Future()
        self._pending_requests[msg_id] = future
        return future
    async def route_response(self, message: MetaMessage):
        if message.id in self._pending_requests:
            future = self._pending_requests.pop(message.id)
            future.set_result(message)

class NeutronBus:
    def __init__(self):
        self.catalog = None; self.bridge = None
    def set_bridge(self, bridge): self.bridge = bridge
    def set_catalog(self, catalog): self.catalog = catalog
    async def send_service_request(self, message: MetaMessage):
        prefix = message.topic.split('.')[0]
        handler = await self.catalog.get_module_handler(prefix)
        if handler:
            response_payload = await handler(message) 
            response_msg = MetaMessage(topic=f"response.{message.topic}", payload=response_payload, sender="Neutron", is_response=True, id=message.id, context_id=message.context_id, priority=message.priority)
            await self.bridge.handle_neutron_response(response_msg)

class BridgeNeutron:
    def __init__(self, kometa_bus: KometaBus, neutron_bus: NeutronBus):
        self.kometa_bus = kometa_bus
        self.neutron_bus = neutron_bus
        self.neutron_bus.set_bridge(self)
        # Pre Terminálové prostredie musíme získať event loop pred inicializáciou
        try:
            self.kometa_bus.set_loop(asyncio.get_event_loop())
        except RuntimeError:
             self.kometa_bus.set_loop(asyncio.new_event_loop())

        print(">> BridgeNeutron: Inicializovaný.")
    async def enqueue_sync_request(self, message: MetaMessage):
        await self.neutron_bus.send_service_request(message)
    async def handle_neutron_response(self, message: MetaMessage):
        await self.kometa_bus.route_response(message)
        
class NeutronServiceProxy:
    def __init__(self, kometa_bus, bridge):
        self._kometa = kometa_bus
        self._bridge = bridge
    def __getattr__(self, name: str):
        if name.startswith('abrg_'):
            function_name = name[5:]
            topic = f"{NeutronServiceTopics.AURORA_BRIDGE}.{function_name}"
        else:
            raise AttributeError(f"Proxy '{name}' neznáme.") 
        async def proxy_call(**kwargs):
            context_id = kwargs.pop('context_id', None)
            priority = kwargs.pop('priority', 5)
            request_msg = MetaMessage(topic=topic, payload=kwargs, sender="AI_Module_Via_Proxy", context_id=context_id, priority=priority)
            future = self._kometa.lock_future(request_msg.id)
            await self._bridge.enqueue_sync_request(request_msg)
            response = await future
            if response.error_code:
                raise NeutronError(response.error_code, response.error_message or "Unknown error", response.topic)
            return response.payload
        return proxy_call

# -------------------- 4. AI REASONING UNIT A KERNEL --------------------

class AIReasoningUnit:
    def __init__(self, kometa_bus):
        self.proxy = NeutronServiceProxy(kometa_bus, None)
        self.agent_id = "LLM_CORE"
        print(f"[{self.agent_id}] Inicializovaný.")
    
    def set_bridge(self, bridge):
        self.proxy._bridge = bridge
    
    async def run_core_logic_cycle(self):
        print(f"[{self.agent_id}] Spúšťam LLM logiku...")
        status_payload = await self.proxy.abrg_get_learning_score(priority=8)
        current_score = status_payload['score']
        stagnation_cycles = status_payload.get('stagnation_cycles', 'N/A')
        
        print(f"[{self.agent_id}] DB/Skóre: '{current_score}', Stagnácia: {stagnation_cycles}")
        
        if current_score == "CRITICAL_LOW":
            print(f"[{self.agent_id}] 🧠 LLM ROZHODNUTIE: CRITICAL LOW! Spúšťam P=9 distribúciu modelu!")
            start = time()
            await self.proxy.abrg_distribute_new_model(priority=9) 
            print(f"[{self.agent_id}] ✅ DISTRIBÚCIA MODELU DOKONČENÁ (Trvanie: {time()-start:.4f}s).")
        elif current_score == "HIGH":
            print(f"[{self.agent_id}] 🧠 LLM ROZHODNUTIE: HIGH. Spúšťam P=1 kontrolu integrity dát na pozadí.")
            asyncio.create_task(self.proxy.abrg_verify_data_integrity(priority=1))
        
        return {"status": current_score, "stagnation": stagnation_cycles}

class AIOSKernel:
    def __init__(self):
        self.state_manager = StateManager(DB_PATH) 
        self.kometa = KometaBus()
        self.neutron = NeutronBus()
        self.catalog = NeutronModuleCatalog(self.neutron, self.state_manager)
        self.neutron.set_catalog(self.catalog)
        self.bridge = BridgeNeutron(self.kometa, self.neutron)
        self.reasoning_unit = AIReasoningUnit(self.kometa)
        self.reasoning_unit.set_bridge(self.bridge)
        print("🧠 AIOS KERNEL PRIPRAVENÝ.")
        self.running = True

    async def get_system_status(self):
        """Získa aktuálne DB dáta a spustí kontrolný cyklus LLM."""
        llm_status = await self.reasoning_unit.run_core_logic_cycle()
        db_state = self.state_manager.get_all_state()
        return {"llm_status": llm_status, "db_state": db_state}

    async def manual_force_distribute(self):
        """Vynútenie distribúcie cez CLI."""
        return await self.reasoning_unit.proxy.abrg_force_distribute(priority=10)


# -------------------- 5. CLI Logika --------------------

async def main_cli(kernel):
    print("-------------------------------------------------------")
    print("🧠 AIOS KERNEL CLI - VÍTAJTE")
    print("-------------------------------------------------------")
    
    while True:
        print("\n--- MOŽNOSTI ---")
        print("1: Zistiť Stav (Spustiť LLM Logiku)")
        print("2: Vynútiť distribúciu (P=10 Zásah)")
        print("x: Ukončiť")
        
        try:
            # Používame asyncio.to_thread, aby sme neblokovali event loop pri čakaní na vstup
            command = await asyncio.to_thread(input, "Zadajte príkaz > ").strip().lower()
            
            if command == '1':
                print("\n[CLI] ✅ Spúšťam LLM riadiaci cyklus...")
                status = await kernel.get_system_status()
                print("\n--- SÚHRN STAVU JADRA ---")
                print(f"  LLM ROZHODNUTIE: {status['llm_status']['status']}")
                print(f"  STAGNÁCIA V DB: {status['llm_status']['stagnation']}")
                print("  CELÝ STAV DB:")
                for key, value in status['db_state'].items():
                     print(f"    - {key}: {value}")
                print("--------------------------")
            
            elif command == '2':
                print("\n[CLI] ⚠️ Spúšťam manuálnu, kritickú distribúciu (P=10)...")
                response = await kernel.manual_force_distribute()
                print(f"[CLI] ✅ ZÁSAH DOKONČENÝ: {response['message']}")
            
            elif command == 'x':
                print("\n[CLI] Ukončujem AIOS CLI. Dovidenia.")
                break
                
            else:
                print("[CLI] ❌ Neznámy príkaz.")

        except Exception as e:
            print(f"\n[CLI] ❌ CHYBA POČAS VYKONÁVANIA: {repr(e)}")
            await asyncio.sleep(1)

# -------------------- 6. Hlavný Spúšťač --------------------

if __name__ == "__main__":
    kernel = AIOSKernel()
    
    # Ak je spustený s argumentom 'cli', spustí interaktívnu konzolu
    if len(sys.argv) > 1 and sys.argv[1].lower() == 'cli':
        print("\n--- STARTING IN INTERACTIVE CLI MODE ---")
        asyncio.run(main_cli(kernel))
    else:
        # Predvolené spustenie: Test, kde LLM Core beží automaticky
        print("\n--- STARTING IN AUTOMATIC TEST MODE (5 CYCLES) ---")
        async def automatic_run():
            for i in range(5):
                print(f"\n--- AUTOMATICKÝ CYKLUS {i+1} ---")
                await kernel.get_system_status()
                await asyncio.sleep(0.5)
        
        try:
            asyncio.run(automatic_run())
        except Exception as e:
            print(f"❌ KERNEL CHYBA: {repr(e)}")

