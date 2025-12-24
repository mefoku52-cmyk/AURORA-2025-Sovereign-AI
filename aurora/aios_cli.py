#!/usr/bin/env python3
"""
AIOS CLI: Konzola pre interakciu s AIOS Kernelom.
"""
import asyncio
# DÔLEŽITÉ: Importujeme VŠETKY globálne triedy, ktoré Kernel potrebuje pri inicializácii
from aios_final_kernel import (
    AIOSKernel, StateManager, KometaBus, NeutronBus, BridgeNeutron, 
    NeutronModuleCatalog, AIReasoningUnit, NeutronServiceProxy,
    DB_PATH # Import aj pre DB_PATH, ak by bolo potrebné
)
from aios_final_kernel import NeutronServiceTopics # Aj Topicy, ak by boli použité

async def main_cli():
    print("-------------------------------------------------------")
    print("🧠 AIOS KERNEL CLI - VÍTAJTE")
    print("-------------------------------------------------------")
    
    # Inicializácia Kernelu
    kernel = AIOSKernel()
    
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
                # Volanie hlavného asynchrónneho cyklu LLM
                status = await kernel.get_system_status()
                print("\n--- SÚHRN STAVU JADRA ---")
                print(f"  LLM ROZHODNUTIE: {status['llm_status']['status']}")
                print(f"  STAGNÁCIA V DB: {status['llm_status']['stagnation']}")
                # Elegantné formátovanie stavu DB pre CLI
                print("  CELÝ STAV DB:")
                for key, value in status['db_state'].items():
                     print(f"    - {key}: {value}")
                print("--------------------------")
            
            elif command == '2':
                print("\n[CLI] ⚠️ Spúšťam manuálnu, kritickú distribúciu (P=10)...")
                # Volanie manuálneho zásahu
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

if __name__ == "__main__":
    try:
        asyncio.run(main_cli())
    except Exception as e:
        print(f"❌ KERNEL CHYBA: {repr(e)}")
