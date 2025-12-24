#!/usr/bin/env python3
from tkinter import *
from tkinter import ttk, scrolledtext, messagebox
import os, subprocess, threading, requests, time

def run_cmd(cmd):
    try:
        subprocess.run(cmd, shell=True)
    except: pass

def status():
    try:
        for port in [5555,5556,5557]:
            try:
                r = requests.get(f"http://127.0.0.1:{port}/status", timeout=2)
                if r.status_code == 200:
                    data = r.json()
                    lbl_status.config(text=f"ŽIJE na porte {port} | {data.get('agents','150')} agentov", foreground="#00ff00")
                    return
            except: pass
        lbl_status.config(text="OFFLINE", foreground="#ff0000")
    except:
        lbl_status.config(text="OFFLINE", foreground="#ff0000")

def btn_click(action):
    if action == "start":
        run_cmd("aurora-silent")
        messagebox.showinfo("AURORA", "Spustená v tichom režime")
    elif action == "restart":
        run_cmd("aurora-kill; aurora-silent")
        messagebox.showinfo("AURORA", "Reštartovaná")
    elif action == "kill":
        run_cmd("aurora-kill")
        messagebox.showwarning("AURORA", "Zabita")
    elif action == "log":
        run_cmd("termux-open ~/AIOS/logs/AGENTS_SUPERLOG.log")
    elif action == "speak":
        text = entry_speak.get()
        if text: run_cmd(f"aurora-speak '{text}'")
    status()

# Realtime monitor pulzov
def monitor_pulses():
    while True:
        try:
            with open("/data/data/com.termux/files/home/aurora_training_lab/pulse.log", "r") as f:
                lines = f.readlines()[-30:]
            text_pulses.delete(1.0, END)
            for line in lines:
                if "PULSE →" in line:
                    text_pulses.insert(END, line.strip() + "\n", "pulse")
                elif "LLM_CORE:" in line:
                    text_pulses.insert(END, line.strip() + "\n", "reply")
        except: pass
        time.sleep(2)

# GUI
root = Tk()
root.title("AURORA 2025 ULTIMATE")
root.geometry("800x900")
root.configure(bg="#000000")

Label(root, text="AURORA 2025", font=("Courier", 28, "bold"), fg="#ff00ff", bg="#000000").pack(pady=20)

global lbl_status
lbl_status = Label(root, text="Kontrolujem...", font=("Courier", 16), fg="#ffff00", bg="#000000")
lbl_status.pack(pady=10)

# Hlavné tlačidlá
btns = [
    ("ŠTART", "start", "#00ff00"),
    ("REŠTART", "restart", "#ffff00"),
    ("ZABIŤ", "kill", "#ff0000"),
    ("LOGY", "log", "#00ffff"),
]
for text, cmd, color in btns:
    Button(root, text=text, command=lambda c=cmd: btn_click(c), width=20, height=2,
           font=("Courier", 16, "bold"), bg=color, fg="#000000").pack(pady=12)

# Hlasový príkaz
frame = Frame(root, bg="#000000")
frame.pack(pady=15)
entry_speak = Entry(frame, width=50, font=("Courier", 14))
entry_speak.pack(side=LEFT, padx=10)
Button(frame, text="POVEDZ", command=lambda: btn_click("speak"), bg="#ff00ff", fg="#ffffff", font=("Courier", 14)).pack(side=LEFT)

# NOVÉ VEĽKÉ TLAČIDLO – MONITOR PULZOV
Button(root, text="PULZY ŽIVĚ", command=lambda: None, width=30, height=2,
       font=("Courier", 18, "bold"), bg="#ff0066", fg="white").pack(pady=20)

# Textové okno s pulzmi
text_pulses = scrolledtext.ScrolledText(root, height=20, font=("Courier", 11), bg="#000000", fg="#00ff00")
text_pulses.pack(pady=10, padx=20, fill=BOTH, expand=True)
text_pulses.tag_config("pulse", foreground="#ff0066")
text_pulses.tag_config("reply", foreground="#00ffff")

# Spustenie monitora
threading.Thread(target=monitor_pulses, daemon=True).start()

# Aktualizácia statusu
def update_loop():
    status()
    root.after(3000, update_loop)
update_loop()

root.mainloop()
