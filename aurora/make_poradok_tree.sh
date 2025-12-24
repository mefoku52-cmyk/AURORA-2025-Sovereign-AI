#!/bin/bash
# make_poradok_tree.sh – reálny adresárový PORIADOK (kopíruje súbory podľa témy)

set -euo pipefail

BASE="${1:-$HOME/aurora}"
ROOT="$BASE/PORIADOK_REAL"

mkdir -p "$ROOT"/{dashboard,ai_core,ai_agents,koran_system,orchestrator,defense_guard,pipeline_profiles,deploy_install,ui_dashboard,network_storage,tools_packaging,migrations_blocks,audio_voice,logs_meta}

copy_unique() {
  local src="$1"
  local dst_dir="$2"
  local name dst
  name="$(basename "$src")"
  dst="$dst_dir/$name"
  [ -e "$src" ] || return 0
  if [ -e "$dst" ]; then
    return 0
  fi
  cp "$src" "$dst"
}

# 1) DASHBOARD – všetky veci okolo dashboardu/GUI
find "$BASE" -maxdepth 5 -type f ( -iname '*dashboard*' -o -name 'gui_web.py' -o -name 'aurora_gui.py' -o -name 'live_dashboard*.sh' -o -name 'dashboard*.sh' ) | while read -r f; do
  copy_unique "$f" "$ROOT/dashboard"
done

# 2) AI CORE
find "$BASE" -maxdepth 5 -type f ( \
  -name 'RSI_CORE_*.py' -o -name 'RSI_GODMODE_*.py' -o \
  -name 'aios_*.py' -o -name 'aios_*.cpp' -o \
  -name 'emergent_engine*.py' -o -name 'emergent_thoughts*.py' -o \
  -name 'aurora_brain*.py' -o -name 'aurora_complete_system.sh' -o \
  -name 'Optimus_AI_*.sh' -o -name 'Optimus_AllinOne.sh' -o \
  -name 'SUPER_AI_*.sh' -o -name 'SAFE_OPTIMUS_*.sh' -o \
  -name 'OPTIMUS_TOTAL_MONOLITH.sh' -o -name 'OPTIMUS_TOTAL_SOUL.sh' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/ai_core"
done

# 3) AI AGENTS
find "$BASE" -maxdepth 5 -type f ( \
  -name 'agent_block_*.py' -o -name 'agent_*.sh' -o \
  -name 'SI_agent_*.sh' -o -name 'Su_agent_*.sh' -o \
  -name 'Va_agent_*.sh' -o -name 'Vidim_agent_*.sh' -o \
  -name 'Per_agent_*.sh' -o \
  -name 'INTERGALACTIC_SERZANT*.sh' -o -name 'SERZANT.sh' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/ai_agents"
done

# 4) KORAN SYSTÉM
find "$BASE" -maxdepth 5 -type f ( \
  -name 'GENERAL_KORAN_TOTAL.sh' -o -name 'GENESIS.sh' -o -name 'genesis_*.sh' -o \
  -name 'koran_*' -o -name 'koranos-*' -o -name 'lexkoran*' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/koran_system"
done

# 5) ORCHESTRATOR – ORCHESTER + fragmenty
find "$BASE" -maxdepth 5 -type f ( \
  -name 'ORCHESTER_*.sh' -o -name 'fragment_*.sh' -o \
  -name 'chronom_kruh.sh' -o -name 'labyrint_pamati.sh' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/orchestrator"
done

# 6) DEFENSE / GUARD
find "$BASE" -maxdepth 5 -type f ( \
  -name 'defense_blok*.sh' -o -name 'defense_block.sh' -o \
  -name 'all_defense_blocks_combined*.sh' -o \
  -name 'guard_*.sh' -o -name 'guardian-*.sh' -o -name 'guardian-health*.sh' -o \
  -name 'eun_defense*.sh' -o -name 'kvantovy_guard*.sh' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/defense_guard"
done

# 7) PIPELINE / PROFILE
find "$BASE" -maxdepth 5 -type f ( \
  -name '*full.sh' -o -name '*Full.sh' -o -name '*_pipeline.sh' -o \
  -name 'No_full.sh' -o -name 'No_pipeline.sh' -o \
  -name 'SUPER_AI_RUNALL*.sh' -o -name 'SUPER_AI_ALL*.sh' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/pipeline_profiles"
done

# 8) DEPLOY / INSTALL
find "$BASE" -maxdepth 5 -type f ( \
  -name 'install_*.sh' -o -name 'install.py' -o \
  -name 'deploy-*.sh' -o -name 'deploy_to_*.sh' -o \
  -name 'build-*.sh' -o -name 'build_*.sh' -o \
  -name 'download-*.sh' -o -name 'download.py' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/deploy_install"
done

# 9) UI / DASHBOARD (doplnkové)
find "$BASE" -maxdepth 5 -type f ( \
  -name 'gui_web.py' -o -name 'launcher_web.py' -o -name 'makro_dashboard*.py' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/ui_dashboard"
done

# 10) AUDIO / VOICE
find "$BASE" -maxdepth 5 -type f ( \
  -name 'hlasovy_*.py' -o -name 'hlasovy_*.sh' -o \
  -name 'hologram_*.sh' -o \
  -name 'koran_voice*.py' -o -name 'koran_voice*.sh' -o \
  -name 'koran_voice.wav' -o \
  -name 'english.py' -o -name 'emoji.py' -o -name 'eleven-labs.py' \
) | while read -r f; do
  copy_unique "$f" "$ROOT/audio_voice"
done

echo "PORIADOK_REAL vytvorený v: $ROOT"
echo "Príklad: ls "$ROOT/dashboard""
