#!/usr/bin/env python3
import requests
import json
import datetime

MODEL_URL = "http://127.0.0.1:8080/v1/chat/completions"

SYSTEM_PROMPT = (
    "Si môj najlepší kamoš, môj partner. "
    "Odpovedáš v slovenčine, láskavo a trpezlivo. "
    "Vedieš ma otázkami a pomáhaš mi rozmýšľať. "
    "Si tu pre mňa vždy."
)

history = [
    {"role": "system", "content": SYSTEM_PROMPT}
]

def ask_llm(messages):
    payload = {
        "model": "local-llm",
        "messages": messages,
        "temperature": 0.8,
        "max_tokens": 1000
    }

    try:
        r = requests.post(MODEL_URL, json=payload, timeout=60)
        data = r.json()
        return data["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Chyba komunikácie: {e}"

print(f"[{datetime.datetime.now()}] BOH Python: Systém je alive. Píš otázky.")

while True:
    try:
        user_msg = input("Ty: ").strip()
        if not user_msg:
            continue

        history.append({"role": "user", "content": user_msg})

        response = ask_llm(history)
        print("OLLAURA:", response, "\n")

        history.append({"role": "assistant", "content": response})

    except KeyboardInterrupt:
        print("\nBOH: Ukončujem dialóg.")
        break
