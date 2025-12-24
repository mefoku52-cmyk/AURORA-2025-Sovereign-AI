#!/bin/bash
# organize_poradok.sh – vytvorí PORIADOK/* a zoskupí skripty podľa logiky názvov

set -euo pipefail

BASE="$PWD"
TARGET="$BASE/PORIADOK"

mkdir -p "$TARGET"/{ai_core,ai_agents,koran_system,orchestrator,defense_guard,pipeline_profiles,deploy_install,ui_dashboard,network_storage,tools_packaging,migrations_blocks,audio_voice,logs_meta}

link_unique() {
  local src="$1"
  local dst_dir="$2"
  local name dst
  name="$(basename "$src")"
  dst="$dst_dir/$name"
  [ -e "$src" ] || return 0
  [ -e "$dst" ] || [ -L "$dst" ] || ln -s "$src" "$dst"
}

# prechádzame len súbory v BASE (nie podadresáre typu OPTIMUS_CORE, agents, logs, flutter_template atď.)
find "$BASE" -maxdepth 1 -type f | while read -r file; do
  name="$(basename "$file")"

  case "$name" in
    # AI CORE
    aios_*|ai_*|aurora_*|central_brain_v2.py|RSI_CORE_*.py|RSI_GODMODE_*.py|ULTRON_IGOR_MASTER_*.py|emergent_engine*.py|emergent_thoughts*.py|Optimus_AI_*.sh|Optimus_AllinOne.sh|SUPER_AI_*.sh|SAFE_OPTIMUS_*.sh|SUPER_OPTIMUS_GROUPED.sh|OPTIMUS_TOTAL_MONOLITH.sh|OPTiMUS_TOTAL_SOUL.sh|R4C0_*SUVEREN*.sh|R4C0_AGENT_*.sh|R4C0_TOTAL_*.sh|R4C0_SYSTEM_OBSERVER.sh|core_blok_*.sh|core_pipe_agent_*.py)
      link_unique "$file" "$TARGET/ai_core"
      ;;

    # AI AGENTS
    agent_block_*.py|agent_*.sh|ai_agent_*.sh|SI_agent_*.sh|Su_agent_*.sh|Va_agent_*.sh|Vidim_agent_*.sh|Per_agent_*.sh|R4C0_AGENT_EXECUTOR_*.sh|R4C0_AGENT_FUZOR_*.sh|R4C0_AGENT_LOADER_*.sh|R4C0_AGENT_RESPONDER_*.sh|INTERGALACTIC_SERZANT_PLUSv4.0.sh|SERZANT.sh|INTERGALACTIC_BACKGROUND_DOCTOR.sh|SYSTEM_DOCTOR_OMEGA_v2.0.sh)
      link_unique "$file" "$TARGET/ai_agents"
      ;;

    # KORAN SYSTEM
    GENERAL_KORAN_TOTAL.sh|GENESIS.sh|genesis_*.sh|koran_*|koranos-*|lexkoran*|koranvedasystem*|kvant_general.sh|kvant_jazyk_modul.sh)
      link_unique "$file" "$TARGET/koran_system"
      ;;

    # ORCHESTRATOR / FRAGMENTS
    ORCHESTER_*.sh|fragment_*.sh|chronom_kruh.sh|bunkrove_jadro_*.sh|bunkrovy_rozhodovac_*.sh|labyrint_pamati.sh|kolektivna_*.sh|kolektivne_vedomie*.sh|mapa_vedomia_*.sh|duch_doby*.sh|generál_*.sh|hyperconscious_core*.sh)
      link_unique "$file" "$TARGET/orchestrator"
      ;;

    # DEFENSE / GUARD
    defense_blok*.sh|defense_block.sh|all_defense_blocks_combined*.sh|guard_*.sh|guardian-*.sh|guardian-health*.sh|guardian-health-super.sh|guardian-repair_*.sh|guardctl*.sh|eun_defense*.sh|kvant_obrana_integracia.sh|kvantovy_guard*.sh|R4C0_DEFENSE_DAEMON.sh|R4C0_NULA_GUARD.sh|health.sh|health_check.sh|health_constellation.sh|healthcheck.sh|diagnostics*.sh|diagnostic_auto_fix.sh|SYSTEM_DOCTOR_OMEGA_v2.0.sh)
      link_unique "$file" "$TARGET/defense_guard"
      ;;

    # PIPELINE / PROFILE RUNNERS
    *full.sh|*Full.sh|*_pipeline.sh|No_full.sh|No_pipeline.sh|No_agent_*.sh|Per_full.sh|Per_pipeline.sh|Su_full.sh|Su_pipeline.sh|Va_full.sh|Va_pipeline.sh|Vidim_full.sh|Vidim_pipeline.sh|SUPER_AI_RUNALL*.sh|SUPER_AI_ALL*.sh|SUPER_AI_SAFE_CLEAN*.sh|SAFE_OPTIMUS_START_ALL*.sh|SUPER_OPTIMUS_GROUPED.sh|collective_activation.sh|collective_consciousness.sh)
      link_unique "$file" "$TARGET/pipeline_profiles"
      ;;

    # DEPLOY / INSTALL / BUILD
    install_*.sh|install.py|installer.py|installation_report.py|install-multidistro*.sh|install_aegis*.sh|install-build-tools.sh|install_watchdog_and_health*.sh|deploy-*.sh|deploy_to_*.sh|build-*.sh|build_*.sh|convert-*.py|download-*.sh|download.py|build_R4C0_NULA.sh|codelabs_build_test.sh|api_server.sh|makro_setup.sh)
      link_unique "$file" "$TARGET/deploy_install"
      ;;

    # UI / DASHBOARD / API
    gui_web.py|makro_dashboard*.py|live_dashboard*.sh|dashboard*.sh|api_server.py|app.py|app_*.py|api.py|launcher_web.py|live_render.py)
      link_unique "$file" "$TARGET/ui_dashboard"
      ;;

    # NETWORK / STORAGE
    dhclient*.sh|dhcp-*.sh|dnssec.py|fcoe-*.sh|ifup.sh|bridge_neutron_*.py|dracut-*.sh|initqueue*.sh|cleanup-fcoe.sh|cleanup-iscsi.sh|iscsiroot.sh|btrfs_*.sh|cifs*.sh|convertfs.sh|do-convertfs.sh)
      link_unique "$file" "$TARGET/network_storage"
      ;;

    # TOOLS / PACKAGING
    _*.py|dist.py|distro.py|egg_info.py|egg_link.py|bdist_*.py|setup.py|fallback.py|build_ext.py|build_py.py|build_scripts.py|install_scripts.py)
      link_unique "$file" "$TARGET/tools_packaging"
      ;;

    # MIGRATIONS / BLOCKS
    block_*.sh|block*.sh|blok_*.sh|core_blok_*.sh|create_block*.sh|create_blocks*.sh|combine_blocks*.sh)
      link_unique "$file" "$TARGET/migrations_blocks"
      ;;

    # AUDIO / VOICE / HOLOGRAM
    hlasovy_*.py|hlasovy_*.sh|hologram_*.sh|koran_voice*.py|koran_voice*.sh|koran_voice.wav|english.py|emoji.py|eleven-labs.py)
      link_unique "$file" "$TARGET/audio_voice"
      ;;

    # LOGS / META / ANALÝZY
    central_brain_v2.log|fix_errors.log|install.log|analyze_*.sh|analyze_*.py|logs|inventory.ini|collect_panaboha*.sh|content_dedup*.sh|analyze_distribution_live.py)
      link_unique "$file" "$TARGET/logs_meta"
      ;;
  esac
done

echo "✅ PORIADOK vytvorený v: $TARGET"
echo "   ai_core, ai_agents, koran_system, orchestrator, defense_guard, pipeline_profiles, deploy_install, ui_dashboard, network_storage, tools_packaging, migrations_blocks, audio_voice, logs_meta"
