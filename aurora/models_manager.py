#!/usr/bin/env python3
import struct
import os

def create_dummy_model(path="dummy.aurora"):
    with open(path, "wb") as f:
        # Magic + header
        f.write(b"AURORA01")
        f.write(struct.pack("<I", 1))  # version
        f.write(struct.pack("<IIIIII", 10000, 512, 24, 8, 2048, 1))  # model params
        
        # Dummy weights (100MB)
        for _ in range(100*1024*1024//4):
            f.write(struct.pack("<f", 0.001))
    
    print(f"Dummy model created: {path}")

if __name__ == "__main__":
    create_dummy_model()
