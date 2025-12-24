import zmq
import asyncio
import json
import time

class KometaMessage:
    def __init__(self, sender: str, recipient: str, data: dict, priority: float = 0.5, context_id: str = None):
        self.sender = sender
        self.recipient = recipient
        self.data = data
        self.priority = priority
        self.context_id = context_id or f"{sender}-{int(time.time())}"
        self.timestamp = time.time()

    def serialize(self) -> bytes:
        return json.dumps({
            "sender": self.sender,
            "recipient": self.recipient,
            "data": self.data,
            "priority": self.priority,
            "context_id": self.context_id,
            "timestamp": self.timestamp
        }).encode('utf-8')

    @staticmethod
    def deserialize(data: bytes) -> 'KometaMessage':
        d = json.loads(data.decode('utf-8'))
        return KometaMessage(
            sender=d['sender'],
            recipient=d['recipient'],
            data=d['data'],
            priority=d.get('priority', 0.5),
            context_id=d.get('context_id')
        )

class KometaBus:
    def __init__(self, port: str = "5555"):
        self.context = zmq.Context()
        self.pub_socket = self.context.socket(zmq.PUB)
        self.pub_socket.bind(f"tcp://*:{port}")
        self.sub_sockets = {}
        self.port = port
        print(f"[KOMETA BUS] Spustený na porte {port}")

    async def publish(self, message: KometaMessage):
        payload = message.serialize()
        self.pub_socket.send_multipart([message.recipient.encode(), payload])

    async def subscribe(self, name: str):
        if name not in self.sub_sockets:
            sock = self.context.socket(zmq.SUB)
            sock.connect(f"tcp://127.0.0.1:{self.port}")
            sock.setsockopt(zmq.SUBSCRIBE, name.encode())
            sock.setsockopt(zmq.SUBSCRIBE, b"")
            self.sub_sockets[name] = sock
        return self.sub_sockets[name]

    async def receive(self, socket):
        topic, data = await socket.recv_multipart()
        return KometaMessage.deserialize(data)
