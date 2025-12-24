#!/usr/bin/env python3
from fastapi import FastAPI, WebSocket
from pydantic import BaseModel
from typing import List
import uvicorn
import psutil
import subprocess
import asyncio
import time
import os

app = FastAPI(title="Aurora AI Engine API")

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    max_tokens: int = 2048
    temperature: float = 0.7

health = {
    "cpu": 0, "ram_gb": 0, "battery": 100, "uptime": time.time()
}

async def monitor():
    while True:
        health["cpu"] = psutil.cpu_percent()
        health["ram_gb"] = psutil.virtual_memory().available / 1e9
        await asyncio.sleep(1)

@app.on_event("startup")
async def start():
    asyncio.create_task(monitor())

@app.get("/v1/models")
async def models():
    return {"data": [{"id": "aurora-tiny", "object": "model"}]}

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    if health["ram_gb"] < 1.0:
        return {"error": "Low resources"}
    
    # Run engine
    proc = subprocess.Popen([
        "go", "run", "../core/engine.go", 
        "../models/dummy.aurora",
        "--prompt", request.messages[-1].content
    ], stdout=subprocess.PIPE, text=True)
    
    output, _ = proc.communicate(timeout=60)
    
    return {
        "id": "chat-1",
        "choices": [{
            "message": {"role": "assistant", "content": output.decode().strip()}
        }]
    }

@app.get("/health")
async def health_check():
    return health

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
