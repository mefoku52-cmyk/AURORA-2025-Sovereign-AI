# AURORA AI ENGINE PRINCIPLES

## "100× lepšie" znamená:
- Nikdy nespusti model, ak to nie je nutné
- Nikdy nevezme viac CPU/RAM, než systém dovolí  
- Rozumie stavu zariadenia (batéria, teplota, pamäť)
- Vie zabiť sám seba, keď nemá dôvod existovať
- Nebeží ako démon, ale ako udalosť

## Architektúra:
1. Core Runtime - striktne limitovaný inference
2. Intelligence Orchestrator - rozhoduje KEDY spustiť
3. OS integrácia - občan systému, nie parazit
4. API + Agent layer - úloha, cieľ, kontext, povolenia

## Ollama je šablóna, nie cieľ:
- Používame ako referenciu
- Nahradzujeme vlastným GGUF enginom
- Pridávame 100× lepšie rozhodovanie
