#!/usr/bin/env python3
"""
AIOS BRIDGE NEUTRON - 100% STABILNÁ VERZIA BEZ SEKANIA
Fáza 25: LLM Logika (Synchronný test)
"""

import asyncio
import threading
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
import uuid
from time import time
from typing import Optional, Any, Dict
import os 
import json 

# --- Vlastná Výnimka ---
class NeutronError(Exception):
    def __init__(self, code: int, message: str, topic: str):
        super().__init__(f"[{topic}] Chyba {code}: {message}")
        self.code = code
        self.topic = topic

# --- MetaMessage ---
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

# --- Topics ---
class NeutronServiceTopics:
    AURORA_BRIDGE = "abrg"

# --- NEUTRON MODULES ---
class AbstractNeutronModule:
    def __init__(self, neutron_bus): 
        self._neutron_bus = neutron_bus
    
    async def handle_request(self, message: MetaMessage) -> Dict[str, Any]:
        raise NotImplementedError

class AuroraBridge(AbstractNeutronModule):
    def __init__(self, neutron_bus):
        super().__init__(neutron_bus)
        self.critical_count = 0
        
    async def handle_request(self, message: MetaMessage) -> Dict[str, Any]:
        action = message.topic.split('.')[-1]
        
        if action == 'get_status':
            self.critical_count += 1
            is_critical = self.critical_count > 1
            return {
                "status": "success" if not is_critical else "CRITICAL", 
                "message": "Všetko v poriadku." if not is_critical else "NUTNÝ ZÁSAH LLM!"
            }
        elif action == 'deploy_patch':
            self.critical_count = 0 
            print(f"[AURORA] PATCH úspešne nasadený (P=9).")
            return {"status": "success", "message": "Patch nasadený."}
        elif action == 'log_passive':
            return {"status": "success", "message": "Pasívne logovanie (P=1)."}
        
        return {"status": "failed", "error_code": 404, "error_message": f"Neznáma akcia: {action}"}

class NeutronModuleCatalog:
    def __init__(self, neutron_bus):
        self.modules: Dict[str, AbstractNeutronModule] = {}
        self.modules[NeutronServiceTopics.AURORA_BRIDGE] = AuroraBridge(neutron_bus)
        
    async def get_module_handler(self, prefix: str):
        module = self.modules.get(prefix)
        if module:
            return module.handle_request
        return None

# --- KOMETA BUS ---
class KometaBus:
    def __init__(self):
        self._pending_requests: Dict[str, asyncio.Future] = {}
        self.neutron_proxy = None
        print("[KOMETA] Inicializovaný.")
    
    def set_loop(self, loop):
        self.loop = loop
    
    def lock_future(self, msg_id: str) -> asyncio.Future:
        future = asyncio.Future()
        self._pending_requests[msg_id] = future
        return future
    
    async def route_response(self, message: MetaMessage):
        if message.id in self._pending_requests:
            future = self._pending_requests.pop(message.id)
            future.set_result(message)

# --- NEUTRON BUS ---
class NeutronBus:
    def __init__(self):
        self.catalog = NeutronModuleCatalog(self)
        self.bridge = None
        
    def set_bridge(self, bridge):
        self.bridge = bridge
    
    async def send_service_request(self, message: MetaMessage):
        prefix = message.topic.split('.')[0]
        handler = await self.catalog.get_module_handler(prefix)
        
        if handler:
            response_payload = await handler(message)
            response_msg = MetaMessage(
                topic=f"response.{message.topic}",
                payload=response_payload,
                sender="Neutron",
                is_response=True,
                id=message.id,
                context_id=message.context_id,
                priority=message.priority
            )
            await self.bridge.handle_neutron_response(response_msg)
        else:
            error_msg = MetaMessage(
                topic=message.topic,
                payload={"status": "failed", "error_code": 404},
                sender="Neutron",
                id=message.id,
                error_code=404,
                error_message="Module not found"
            )
            await self.bridge.handle_neutron_response(error_msg)

# --- BRIDGE NEUTRON ---
class BridgeNeutron:
    def __init__(self, kometa_bus: KometaBus, neutron_bus: NeutronBus):
        self.kometa_bus = kometa_bus
        self.neutron_bus = neutron_bus
        self.neutron_bus.set_bridge(self)
        print(">> BridgeNeutron: Inicializovaný.")
    
    async def enqueue_sync_request(self, message: MetaMessage):
        await self.neutron_bus.send_service_request(message)
    
    async def handle_neutron_response(self, message: MetaMessage):
        await self.kometa_bus.route_response(message)

# --- PROXY ---
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
            
            request_msg = MetaMessage(
                topic=topic, 
                payload=kwargs, 
                sender="AI_Module_Via_Proxy", 
                context_id=context_id, 
                priority=priority
            )
            
            future = self._kometa.lock_future(request_msg.id)
            await self._bridge.enqueue_sync_request(request_msg)
            response = await future
            
            if response.error_code:
                raise NeutronError(
                    response.error_code, 
                    response.error_message or "Unknown error", 
                    response.topic
                )
            return response.payload
        
        return proxy_call

# --- AI REASONING UNIT ---
class AIReasoningUnit:
    def __init__(self, kometa_bus):
        self.proxy = None
        self.agent_id = "LLM_CORE"
        self.kometa_bus = kometa_bus
        self.bridge = None
        print(f"[{self.agent_id}] Inicializovaný.")
    
    def set_bridge(self, bridge):
        self.proxy = NeutronServiceProxy(self.kometa_bus, bridge)
        self.bridge = bridge
    
    async def run_decision_cycle(self):
        print("
--- LLM ROZHODOVACÍ CYKLUS ---")
        
        for i in range(4):
            print(f"[{self.agent_id}] Cyklus {i+1}: Dopytujem stav...")
            
            status_payload = await self.proxy.abrg_get_status(priority=8)
            current_status = status_payload['status']
            
            print(f"[{self.agent_id}] Input: '{current_status}'")
            
            if current_status == "CRITICAL":
                print(f"[{self.agent_id}] 🧠 KRITICKÝ! ZÁSAH P=9!")
                start = time()
                await self.proxy.abrg_deploy_patch(priority=9)
                print(f"[{self.agent_id}] ✅ ZÁSAH dokončený za {time()-start:.3f}s")
            else:
                print(f"[{self.agent_id}] 🧠 OK. Pasívne log (P=1)")
                await self.proxy.abrg_log_passive(priority=1)
            
            await asyncio.sleep(0.1)

# --- AIOS KERNEL ---
class AIOSKernel:
    def __init__(self):
        self.kometa = KometaBus()
        self.neutron = NeutronBus()
        self.bridge = BridgeNeutron(self.kometa, self.neutron)
        self.reasoning_unit = AIReasoningUnit(self.kometa)
        self.reasoning_unit.set_bridge(self.bridge)
        print("🧠 AIOS KERNEL Inicializovaný.")
    
    async def run_final_test(self):
        print("
--- FÁZA 25: LLM LOGIKA (STABILNÁ VERZIA) ---")
        await self.reasoning_unit.run_decision_cycle()
        print("
✅ AIOS JADRO - INTELIGENTNÁ LOGIKA ÚSPEŠNÁ!")
        await asyncio.sleep(1)

if __name__ == "__main__":
    try:
        kernel = AIOSKernel()
        asyncio.run(kernel.run_final_test())
    except Exception as e:
        print(f"❌ KERNEL CHYBA: {repr(e)}")
