# NAHRADÍ AI_OS_MASTER.SH

#!/usr/bin/env bash
# AI OS MASTER - PREPOJÍ VŠETKO DO JEDNÉHO SYSTÉMU
# Upravené pre spustenie 150 AI-Agentov
echo "🧠 AI OS BOOT - PREPOJENIE $(date)"

# 1. MASTER DATABASE
# (Pôvodná sekcia bezo zmeny)
mkdir -p ~/AIOS/master_db ~/AIOS/pids
sqlite3 ~/AIOS/master_db/ai_os.db << SQL
CREATE TABLE modules (
    id INTEGER PRIMARY KEY,
    path TEXT,
    type TEXT,
    status TEXT DEFAULT 'idle',
    pid INTEGER,
    last_run REAL
);
CREATE TABLE system_state (key TEXT PRIMARY KEY, value TEXT);
INSERT OR REPLACE INTO system_state VALUES ('status','BOOTING');
SQL

# 2. LOAD VŠETKÝCH MODULES
# (Pôvodná sekcia bezo zmeny)
echo "📂 Načítavam $(find ~/ZACHRANA ~/modules_all -name '*.py' | wc -l) modulov..."
find ~/ZACHRANA ~/modules_all -name '*.py' | head -50 | while read module; do
    sqlite3 ~/AIOS/master_db/ai_os.db "
    INSERT OR IGNORE INTO modules (path, type)
    VALUES ('$module', '$(basename "$module" .py | sed 's/_/ /g')');
    "
done

# 3. ŠTART RSI + BRIDGE (UŽ BEŽÍ)
echo "🧠 Štartujem RSI Master (RSI_CORE_FULL) a Asynchrónny Bridge..."
# Predpokladám, že RSI_CORE_FULL.py beží na 8000
cd ~/aurora && nohup python3 RSI_CORE_FULL.py > ~/AIOS/logs/rsi_master.log 2>&1 &
echo $! >> ~/AIOS/pids/master.pid

# 4. ŠTART NEUTRON KERNELU (LLM CORE)
echo "🧠 Štartujem AIOS KERNEL (DB/Asynchrónny LLM Riadiaci Cyklus)..."
# Jadro beží v automatickom (nekonečnom) cykle
cd ~/aurora && nohup python3 aios_kernel_complete_final.py > ~/AIOS/logs/kernel_core.log 2>&1 &
echo $! >> ~/AIOS/pids/master.pid

# 5. AKTIVÁCIA 150 AI-AGENTOV (NOVÝ KROK PRE REAL MODE)
echo "⚡ AKTIVUJEM KOLEKTÍVNE VEDOMIE: Spúšťam Master Cyklus 150 AI-Agentov..."
bash ~/AIOS/master_cycle_150.sh > ~/AIOS/logs/agents_master_loop.log 2>&1 &
echo $! >> ~/AIOS/pids/master.pid

# 6. SENTINEL + MONITOR
echo "🛡️ Štartujem Sentinel a Watchdog (Oživovanie a Monitoring)..."
cd ~/modules_all && nohup bash sentinel_core7.sh > ~/AIOS/logs/sentinel.log 2>&1 &
echo $! >> ~/AIOS/pids/master.pid
# watchdog_forever.sh (monitoruje AURORA X mŕtve procesy)
cd ~/aurora && nohup bash watchdog_forever.sh > ~/AIOS/logs/watchdog.log 2>&1 &
echo $! >> ~/AIOS/pids/master.pid

# 7. AI OS DASHBOARD (VOLITEĽNÉ)
echo "🖼️ Spúšťam Dashboard..."
bash ~/AIOS/ai_os_dashboard.sh # Ak chcete vidieť dashboard v termináli

sqlite3 ~/AIOS/master_db/ai_os.db "INSERT OR REPLACE INTO system_state VALUES ('status','RUNNING');"
echo "✅ SYSTÉM AIOS SPUSŤENÝ V REAL MODE."
