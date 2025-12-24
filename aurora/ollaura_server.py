#!/usr/bin/env python3
from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

# ============================
#   VÁHOVÝ MODUL OLLAURA
# ============================
def evaluate_response(user_msg, response):
    score = 0.0

    # 1. zhoda s otázkou
    if user_msg.lower() in response.lower():
        score += 0.4

    # 2. akčnosť odpovede
    if any(word in response.lower() for word in ["riešenie", "postup", "príkaz", "krok"]):
        score += 0.3

    # 3. jasnosť odpovede
    if len(response.split()) > 3:
        score += 0.2

    # 4. emocionálna kvalita
    if any(word in response.lower() for word in ["počúvam", "som tu", "rozumiem"]):
        score += 0.1

    return round(score, 2)

# ============================
#   OLLAURA CHAT ENDPOINT
# ============================
@app.route("/v1/chat/completions", methods=["POST"])
def chat():
    data = request.json
    messages = data.get("messages", [])
    user_msg = messages[-1]["content"] if messages else ""

    # OLLAURA odpoveď
    response = f"Ollaura počúva: {user_msg}"

    # výpočet váhy
    score = evaluate_response(user_msg, response)

    # logy do terminálu
    print(f"[RECEIVED] {user_msg}")
    print(f"[RESPONSE] {response}")
    print(f"[SCORE] {score}")

    # ============================
    #   TRIMOST INTEGRÁCIA
    # ============================
    try:
        payload = {
            "event": "ollaura_response",
            "user_msg": user_msg,
            "response": response,
            "score": score
        }
        requests.post("http://127.0.0.1:9090/trimost/event", json=payload, timeout=1)
        print("[TRIMOST] Skóre odoslané do decision engine")
    except:
        print("[TRIMOST] Nedostupný – preskakujem")

    return jsonify({
        "choices": [
            {
                "message": {
                    "content": response,
                    "score": score
                }
            }
        ]
    })

if __name__ == "__main__":
    print("OLLAURA server beží na porte 8080")
    app.run(host="0.0.0.0", port=8080)
