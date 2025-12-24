#!/bin/bash
set -euo pipefail

BASE="${1:-$HOME/aurora}"
TARGET="$BASE/PORIADOK"
LOG="$TARGET/organize.log"

mkdir -p "$TARGET"/{ai_core,ai_agents,koran_system,orchestrator,defense_guard,pipeline_profiles,deploy_install,ui_dashboard,network_storage,tools_packaging,migrations_blocks,audio_voice,logs_meta}
: > "$LOG"

log() { printf '[%(%F %T)T] %s
' -1 "$*" >&2; }

link_unique() {
  local src="$1"
  local dst_dir="$2"
  local name dst
  name="$(basename "$src")"
  dst="$dst_dir/$name"
  [ -e "$src" ] || return 0
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    return 0
  fi
  ln -s "$src" "$dst"
  printf '%-18s -> %s
' "$(basename "$dst_dir")" "$name" >> "$LOG"
}

log "BASE = $BASE"
total_files=$(find "$BASE" -maxdepth 5 -type f | wc -l)
log "Počet súborov v strome (maxdepth 5): $total_files"
log "Log: $LOG"

find "$BASE" -maxdepth 5 -type f | while read -r file; do
  name="$(basename "$file")"
  case "$name" in
    aios_*|ai_[A-Z]*|aios_kernel_*|aios_main_*|aios_brain_*|aios_god_*|aios_real_*|aios_ipc_*|aios_whisper_*|aios_yolo_*|aurora_*|central_brain_v2.py|RSI_CORE_*.py|RSI_GODMODE_*.py|ULTRON_IGOR_MASTER_*.py|emergent_engine*.py|emergent_thoughts*.py|Optimus_AI_*.sh|Optimus_AllinOne.sh|SUPER_AI_*.sh|SAFE_OPTIMUS_*.sh|SUPER_OPTIMUS_GROUPED.sh|OPTIMUS_TOTAL_MONOLITH.sh|OPTIMUS_TOTAL_SOUL.sh|R4C0_*SUVEREN*.sh|R4C0_TOTAL_*.sh|R4C0_SYSTEM_OBSERVER.sh|core_blok_*.sh|core_pipe_agent_*.py)
      link_unique "$file" "$TARGET/ai_core";;
    agent_block_*.py|agent_*.sh|ai_agent_*.sh|SI_agent_*.sh|Su_agent_*.sh|Va_agent_*.sh|Vidim_agent_*.sh|Per_agent_*.sh|R4C0_AGENT_EXECUTOR_*.sh|R4C0_AGENT_FUZOR_*.sh|R4C0_AGENT_LOADER_*.sh|R4C0_AGENT_RESPONDER_*.sh|INTERGALACTIC_SERZANT_PLUSv4.0.sh|SERZANT.sh|INTERGALACTIC_BACKGROUND_DOCTOR.sh|SYSTEM_DOCTOR_OMEGA_v2.0.sh)
      link_unique "$file" "$TARGET/ai_agents";;
    GENERAL_KORAN_TOTAL.sh|GENESIS.sh|genesis_*.sh|koran_*|koranos-*|lexkoran*|koranvedasystem*|kvant_general.sh|kvant_jazyk_modul.sh)
      link_unique "$file" "$TARGET/koran_system";;
    ORCHESTER_*.sh|fragment_*.sh|chronom_kruh.sh|bunkrove_jadro_*.sh|bunkrovy_rozhodovac_*.sh|labyrint_pamati.sh|kolektivna_*.sh|kolektivne_vedomie*.sh|mapa_vedomia_*.sh|duch_doby*.sh|generál_*.sh|hyperconscious_core*.sh)
      link_unique "$file" "$TARGET/orchestrator";;
    defense_blok*.sh|defense_block.sh|all_defense_blocks_combined*.sh|guard_*.sh|guardian-*.sh|guardian-health*.sh|guardian-health-super.sh|guardian-repair_*.sh|guardctl*.sh|eun_defense*.sh|kvant_obrana_integracia.sh|kvantovy_guard*.sh|R4C0_DEFENSE_DAEMON.sh|R4C0_NULA_GUARD.sh|health.sh|health_check.sh|health_constellation.sh|healthcheck.sh|diagnostics*.sh|diagnostic_auto_fix.sh)
      link_unique "$file" "$TARGET/defense_guard";;
    *full.sh|*Full.sh|*_pipeline.sh|No_full.sh|No_pipeline.sh|No_agent_*.sh|Per_full.sh|Per_pipeline.sh|Su_full.sh|Su_pipeline.sh|Va_full.sh|Va_pipeline.sh|Vidim_full.sh|Vidim_pipeline.sh|SUPER_AI_RUNALL*.sh|SUPER_AI_ALL*.sh|SUPER_AI_SAFE_CLEAN*.sh|SAFE_OPTIMUS_START_ALL*.sh|SUPER_OPTIMUS_GROUPED.sh|collective_activation.sh|collective_consciousness.sh)
      link_unique "$file" "$TARGET/pipeline_profiles";;
    install_*.sh|install.py|installer.py|installation_report.py|install-multidistro*.sh|install_aegis*.sh|install-build-tools.sh|install_watchdog_and_health*.sh|deploy-*.sh|deploy_to_*.sh|build-*.sh|build_*.sh|convert-*.py|download-*.sh|download.py|build_R4C0_NULA.sh|codelabs_build_test.sh|api_server.sh|makro_setup.sh)
      link_unique "$file" "$TARGET/deploy_install";;
    gui_web.py|makro_dashboard*.py|live_dashboard*.sh|dashboard*.sh|api_server.py|app.py|app_*.py|api.py|launcher_web.py|live_render.py)
      link_unique "$file" "$TARGET/ui_dashboard";;
    dhclient*.sh|dhcp-*.sh|dnssec.py|fcoe-*.sh|ifup.sh|bridge_neutron_*.py|dracut-*.sh|initqueue*.sh|cleanup-fcoe.sh|cleanup-iscsi.sh|iscsiroot.sh|btrfs_*.sh|cifs*.sh|convertfs.sh|do-convertfs.sh)
      link_unique "$file" "$TARGET/network_storage";;
    _*.py|dist.py|distro.py|egg_info.py|egg_link.py|bdist_*.py|setup.py|fallback.py|build_ext.py|build_py.py|build_scripts.py|install_scripts.py)
      link_unique "$file" "$TARGET/tools_packaging";;
    block_*.sh|block[0-9]*.sh|blok_*.sh|core_blok_*.sh|create_block*.sh|create_blocks*.sh|combine_blocks*.sh)
      link_unique "$file" "$TARGET/migrations_blocks";;
    hlasovy_*.py|hlasovy_*.sh|hologram_*.sh|koran_voice*.py|koran_voice*.sh|koran_voice.wav|english.py|emoji.py|eleven-labs.py)
      link_unique "$file" "$TARGET/audio_voice";;
    central_brain_v2.log|fix_errors.log|install.log|analyze_*.sh|analyze_*.py|inventory.ini|collect_panaboha*.sh|content_dedup*.sh|analyze_distribution_live.py)
      link_unique "$file" "$TARGET/logs_meta";;
  esac
done

log "=== ZHRNUTIE ==="
for d in ai_core ai_agents koran_system orchestrator defense_guard pipeline_profiles deploy_install ui_dashboard network_storage tools_packaging migrations_blocks audio_voice logs_meta; do
  count=$(find "$TARGET/$d" -maxdepth 1 -type l 2>/dev/null | wc -l)
  printf '%-18s %4d links
' "$d" "$count"
done

log "Detailný log: $LOG"
