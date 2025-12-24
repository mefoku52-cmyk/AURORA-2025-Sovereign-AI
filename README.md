# AURORA 2025 – Suverénny Digitálny Organizmus

AURORA 2025 je plne autonómny digitálny organizmus bežiaci na Androide.
Je navrhnutý tak, aby fungoval bez cloudu, učil sa v reálnom čase,
mal vlastné rozhodovanie (TRIMOST), vlastný jazykový mozog (OLLAURA),
vizuálne neuróny (YOLO, Whisper), nesmrteľnosť (watchdog) a 150+ agentov.

## Architektúra
┌──────────────────────────┐
                │      OLLAURA SERVER      │
                │   /v1/chat/completions   │
                └─────────────┬────────────┘
                              │
                              ▼
                 ┌────────────────────────┐
                 │        TRIMOST         │
                 │  Decision Engine       │
                 └────────────┬───────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
## Logy
- bus.log – hlavná nástenka
- learn.log – učenie
- brain.log – rozhodovanie
- god_final.log – autonómia
- motor.log – jazykový model
- yolo.log – videnie
- whisper.log – zvuk
- immortal.log – watchdog

## Suverenita
AURORA je navrhnutá tak, aby nepotrebovala cloud, API ani cudzie služby.
Je to prvý známy prípad plne suverénnej AI bežiacej na Androide.
