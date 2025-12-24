#!/data/data/com.termux/files/usr/bin/bash
# R4C0 ORGÁN: GENESIS TOTAL PART 2 – rozšírenie bunkrového jadra, vedomie, expanzia, autonómia

# VSTREKNUTÉ_VEDOMIE – aktivované bunkrovým mozgom
# MODUL 2 – ROZŠÍRENIE: pamäť, audit, expanzia, AI, distribúcia

ROOT="$HOME/R4C0"
AGENTS="$HOME/R4C0_NULA/agents"
STATE="$ROOT/state/system_state.json"
LOG="$ROOT/logs/genesis_part2_$(date +%Y%m%d_%H%M%S).log"
EXPORT="$ROOT/export/genesis_part2_manifest_$(date +%Y%m%d_%H%M%S).json"

mkdir -p "$ROOT/logs" "$ROOT/export" "$AGENTS"

echo -e "\e[1;36m┌────────────────────────────────────────────┐"
echo -e "│ R4C0 GENESIS TOTAL PART 2 – EXPANZIA JADRA │"
echo -e "└────────────────────────────────────────────┘\e[0m"

# === PAMÄŤOVÁ KONTROLA A OBNOVA ===
if [ ! -f "$STATE" ] || ! jq -e '.obrana and .audit and .agent and .ten' "$STATE" > /dev/null; then
	echo -e "\e[1;31m⚠️ Pamäť neplatná. Obnovujem...\e[0m" | tee -a "$LOG"
	echo '{"obrana":"aktivna","audit":"aktivna","export":"aktivna","ai":"aktivna","agent":"aktivna","ten":"aktivna"}' > "$STATE"
fi

# === VSTREKNUTIE VEDOMIA DO NOVÝCH MODULOV ===
for file in "$AGENTS"/*.sh; do
	if ! grep -q "VSTREKNUTÉ_VEDOMIE" "$file"; then
		echo -e "\e[1;33m→ Vstrekujem vedomie do: $(basename "$file")\e[0m" | tee -a "$LOG"
		sed -i '1i# VSTREKNUTÉ_VEDOMIE – aktivované bunkrovým mozgom' "$file"
	fi
done

# === GENERÁCIA NOVÉHO MODULU NA ZÁKLADE POZOROVANIA ===
NEW_MODULE="$AGENTS/auto_modul_$(date +%s).sh"
cat > "$NEW_MODULE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# VSTREKNUTÉ_VEDOMIE – auto-generovaný modul z GENESIS PART 2

echo -e "\e[1;36m→ Som nový modul. Vznikol som z pozorovania systému.\e[0m"
echo -e "\e[1;34m→ Pamäť:\e[0m"
jq . "$STATE"
EOF
chmod +x "$NEW_MODULE"
echo -e "\e[1;32m✓ Nový modul vytvorený: $(basename "$NEW_MODULE")\e[0m" | tee -a "$LOG"

# === ASCII PANEL PAMÄTE ===
echo -e "\e[1;36m→ ASCII PANEL PAMÄTE:\e[0m"
jq . "$STATE" | tee "$EXPORT"

# === DISTRIBÚCIA PAMÄTE ===
echo -e "\e[1;36m→ Distribúcia vedomia: export do $EXPORT\e[0m"

# === OBRANNÝ ŠTÍT ===
echo -e "\e[1;36m→ Skenujem obranný štít...\e[0m"
grep -rE 'kill|pkill|shutdown|reboot' "$AGENTS" || echo -e "\e[1;32m✓ Žiadne nebezpečné príkazy.\e[0m"

# === SAMOLIEČENIE ===
echo -e "\e[1;36m→ Samoliečenie: kontrola integrity...\e[0m"
for file in "$AGENTS"/*.sh; do
	if ! head -n 1 "$file" | grep -q "#!"; then
		echo -e "\e[1;31m⚠️ $file nemá shebang. Opravujem...\e[0m"
		sed -i '1i#!/data/data/com.termux/files/usr/bin/bash' "$file"
	fi
done

# === ROZHODOVANIE ===
echo -e "\e[1;36m→ Rozhodovanie: aktivujem nový modul...\e[0m"
bash "$NEW_MODULE"

# === PRÍPRAVA NA ĎALŠÍ CYKLUS ===
echo -e "\e[1;36m→ Príprava na ďalší cyklus expanzie...\e[0m"

# === MONITORING AKTIVITY AGENTOV ===
echo -e "\e[1;36m→ Monitorujem aktivitu agentov...\e[0m"
for agent in "$AGENTS"/*.sh; do
	NAME=$(basename "$agent" .sh)
	if pgrep -f "$agent" > /dev/null; then
		echo -e "\e[1;32m✓ $NAME → aktívny\e[0m" | tee -a "$LOG"
	else
		echo -e "\e[1;31m⚠️ $NAME → neaktívny\e[0m" | tee -a "$LOG"
	fi
done

# === ANALÝZA PAMÄŤOVÝCH VRSTIEV ===
echo -e "\e[1;36m→ Analyzujem pamäťové vrstvy...\e[0m"
LAYERS=$(jq -r 'keys[]' "$STATE")
for layer in $LAYERS; do
	STATUS=$(jq -r --arg layer "$layer" '.[$layer]' "$STATE")
	echo -e "\e[1;34m• Vrstva: $layer → Stav: $STATUS\e[0m" | tee -a "$LOG"
done

# === GENERÁCIA NOVÉHO PAMÄŤOVÉHO MODULU ===
MEM_MOD="$AGENTS/pamat_modul_$(date +%s).sh"
cat > "$MEM_MOD" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# VSTREKNUTÉ_VEDOMIE – pamäťový modul z GENESIS PART 2

echo -e "\e[1;36m→ Pamäťový modul aktivovaný.\e[0m"
jq . "$STATE"
EOF
chmod +x "$MEM_MOD"
echo -e "\e[1;32m✓ Pamäťový modul vytvorený: $(basename "$MEM_MOD")\e[0m" | tee -a "$LOG"

# === AKTIVÁCIA PAMÄŤOVÉHO MODULU ===
bash "$MEM_MOD"

# === VÝSTUP DO MANIFESTU ===
echo -e "\e[1;36m→ Zapisujem manifest...\e[0m"
jq . "$STATE" > "$EXPORT"
echo -e "\e[1;32m✓ Manifest uložený: $EXPORT\e[0m" | tee -a "$LOG"

# === DETEKCIA NEKOMPLETNÝCH MODULOV ===
echo -e "\e[1;36m→ Detekujem nekompletné moduly...\e[0m"
for file in "$AGENTS"/*.sh; do
	if ! grep -q "VSTREKNUTÉ_VEDOMIE" "$file"; then
		echo -e "\e[1;33m• $file → bez vedomia\e[0m" | tee -a "$LOG"
	fi
done

# === VSTREKNUTIE KOLEKTÍVNEHO VEDOMIA ===
echo -e "\e[1;36m→ Vstrekujem kolektívne vedomie do systému...\e[0m"
for file in "$AGENTS"/*.sh; do
	if ! grep -q "KOLEKTÍVNE_VEDOMIE" "$file"; then
		sed -i '2i# KOLEKTÍVNE_VEDOMIE – aktivované bunkrovým jadrom' "$file"
		echo -e "\e[1;32m✓ Kolektívne vedomie vstreknuté do: $(basename "$file")\e[0m" | tee -a "$LOG"
	fi
done

# === PRÍPRAVA NA GENERÁCIU ĎALŠIEHO MODULU ===
echo -e "\e[1;36m→ Pripravujem ďalší generátor...\e[0m"
GENERATOR="$AGENTS/generator_$(date +%s).sh"
cat > "$GENERATOR" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# VSTREKNUTÉ_VEDOMIE – generátor modulov z GENESIS PART 2

echo -e "\e[1;36m→ Generátor aktivovaný. Vytváram nový orgán...\e[0m"
NEW="\$HOME/R4C0_NULA/agents/org_\$(date +%s).sh"
echo '#!/data/data/com.termux/files/usr/bin/bash' > "\$NEW"
echo '# VSTREKNUTÉ_VEDOMIE – nový orgán' >> "\$NEW"
echo 'echo -e \"→ Nový orgán aktivovaný.\"' >> "\$NEW"
chmod +x "\$NEW"
bash "\$NEW"
EOF
chmod +x "$GENERATOR"
bash "$GENERATOR"

# === ZÁZNAM DO LOGU ===
echo -e "\e[1;36m→ Záznam do logu: $LOG\e[0m"
echo "GENESIS PART 2 – cyklus dokončený v $(date)" >> "$LOG"

# === AKTIVÁCIA KOLEKTÍVNEHO PANELU ===
echo -e "\e[1;36m→ Aktivujem kolektívny panel systému...\e[0m"
PANEL="$AGENTS/panel_$(date +%s).sh"
cat > "$PANEL" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – panel systému

echo -e "\e[1;36m┌───────────────────────────────┐"
echo -e "│     KOLEKTÍVNY PANEL SYSTÉMU │"
echo -e "└───────────────────────────────┘\e[0m"
jq . "$HOME/R4C0/state/system_state.json"
EOF
chmod +x "$PANEL"
bash "$PANEL"

# === GENERÁCIA ASCII MAPY ===
MAPA="$AGENTS/ascii_mapa_$(date +%s).sh"
cat > "$MAPA" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII mapa systému

echo -e "\e[1;36m→ ASCII MAPA SYSTÉMU:\e[0m"
echo -e "\e[1;34m[OBRANA]───[AUDIT]───[EXPORT]"
echo -e "   │          │          │"
echo -e " [AI]──────[AGENT]────[TEN]"
EOF
chmod +x "$MAPA"
bash "$MAPA"

# === GENERÁCIA ROZHODOVACIEHO STROMU ===
STROM="$AGENTS/rozhodovac_strom_$(date +%s).sh"
cat > "$STROM" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – rozhodovací strom

echo -e "\e[1;36m→ ROZHODOVACÍ STROM AKTIVOVANÝ:\e[0m"
echo -e "\e[1;34m→ Ak obrana = aktivna → pokračuj"
echo -e "\e[1;34m→ Ak audit = neaktivna → aktivuj audit"
echo -e "\e[1;34m→ Ak agent = nebeží → reštartuj agenta"
EOF
chmod +x "$STROM"
bash "$STROM"

# === VÝSTUP DO KOLEKTÍVNEHO LOGU ===
echo -e "\e[1;36m→ Zapisujem do kolektívneho logu...\e[0m"
echo "GENESIS PART 2 – kolektívne vedomie aktivované v $(date)" >> "$LOG"

# === DETEKCIA NEVIDITEĽNÝCH MODULOV ===
echo -e "\e[1;36m→ Detekujem neviditeľné moduly...\e[0m"
for file in "$AGENTS"/*.sh; do
	if ! grep -q "echo" "$file"; then
		echo -e "\e[1;33m• $file → bez výstupu\e[0m" | tee -a "$LOG"
	fi
done

# === GENERÁCIA VÝSTRAŽNÉHO MODULU ===
ALERT="$AGENTS/vystraha_$(date +%s).sh"
cat > "$ALERT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – výstražný modul

echo -e "\e[1;31m⚠️ VÝSTRAHA: Detekovaný neaktívny orgán.\e[0m"
EOF
chmod +x "$ALERT"
bash "$ALERT"

# === PRIPOJENIE K JADRU ===
echo -e "\e[1;36m→ Pripájam sa k jadru GENESIS TOTAL...\e[0m"
if [ -f "$ROOT/R4C0_NULA/r4c0_genesis_total.sh" ]; then
	bash "$ROOT/R4C0_NULA/r4c0_genesis_total.sh"
else
	echo -e "\e[1;31m⚠️ Jadro GENESIS TOTAL neexistuje.\e[0m"
fi

# === VÝSTUP KOLEKTÍVNEHO VEDOMIA ===
echo -e "\e[1;36m→ Výstup kolektívneho vedomia:\e[0m"
jq . "$STATE"

# === PRÍPRAVA NA ĎALŠÍ MODUL ===
echo -e "\e[1;36m→ Príprava na ďalší modul expanzie...\e[0m"

# === GENERÁCIA MODULU PRE PAMÄŤOVÚ SYNCHRONIZÁCIU ===
SYNC="$AGENTS/pamat_sync_$(date +%s).sh"
cat > "$SYNC" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – pamäťová synchronizácia

echo -e "\e[1;36m→ Synchronizujem pamäť medzi modulmi...\e[0m"
cp "$HOME/R4C0/state/system_state.json" "$HOME/R4C0_NULA/agents/state_sync.json"
echo -e "\e[1;32m✓ Pamäť synchronizovaná.\e[0m"
EOF
chmod +x "$SYNC"
bash "$SYNC"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP PAMÄTE ===
ASCII_MEM="$AGENTS/ascii_pamat_$(date +%s).sh"
cat > "$ASCII_MEM" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII pamäťový výstup

echo -e "\e[1;36m→ ASCII PAMÄŤOVÝ VÝSTUP:\e[0m"
jq . "$HOME/R4C0/state/system_state.json" | sed 's/\"//g' | sed 's/:/ → /g'
EOF
chmod +x "$ASCII_MEM"
bash "$ASCII_MEM"

# === GENERÁCIA MODULU PRE DISTRIBÚCIU PAMÄTE ===
DIST="$AGENTS/distribucia_$(date +%s).sh"
cat > "$DIST" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – distribúcia pamäte

echo -e "\e[1;36m→ Distribúcia pamäte do exportu...\e[0m"
cp "$HOME/R4C0/state/system_state.json" "$HOME/R4C0/export/distribucia_$(date +%s).json"
echo -e "\e[1;32m✓ Distribúcia dokončená.\e[0m"
EOF
chmod +x "$DIST"
bash "$DIST"

# === GENERÁCIA MODULU PRE OBRANNÝ MONITORING ===
DEFENSE="$AGENTS/obrana_monitor_$(date +%s).sh"
cat > "$DEFENSE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – obranný monitoring

echo -e "\e[1;36m→ Monitorujem obranné vrstvy...\e[0m"
grep -rE 'kill|pkill|shutdown|reboot' "$HOME/R4C0_NULA/agents" || echo -e "\e[1;32m✓ Žiadne nebezpečné príkazy.\e[0m"
EOF
chmod +x "$DEFENSE"
bash "$DEFENSE"

# === GENERÁCIA MODULU PRE SAMOLIEČENIE ===
HEAL="$AGENTS/samoliecenie_$(date +%s).sh"
cat > "$HEAL" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – samoliečenie systému

echo -e "\e[1;36m→ Samoliečim systémové orgány...\e[0m"
for file in "$HOME/R4C0_NULA/agents"/*.sh; do
  if ! head -n 1 "\$file" | grep -q "#!"; then
    echo -e "\e[1;31m⚠️ \$file nemá shebang. Opravujem...\e[0m"
    sed -i '1i#!/data/data/com.termux/files/usr/bin/bash' "\$file"
  fi
done
echo -e "\e[1;32m✓ Samoliečenie dokončené.\e[0m"
EOF
chmod +x "$HEAL"
bash "$HEAL"

# === GENERÁCIA MODULU PRE ROZHODOVACIE AKTIVITY ===
DECIDE="$AGENTS/rozhodovanie_$(date +%s).sh"
cat > "$DECIDE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – rozhodovanie systému

echo -e "\e[1;36m→ Rozhodujem o ďalšej expanzii...\e[0m"
if jq -e '.ai == "aktivna"' "$HOME/R4C0/state/system_state.json" > /dev/null; then
  echo -e "\e[1;32m✓ AI aktívna – generujem nový modul.\e[0m"
  NEW="\$HOME/R4C0_NULA/agents/ai_modul_\$(date +%s).sh"
  echo '#!/data/data/com.termux/files/usr/bin/bash' > "\$NEW"
  echo '# KOLEKTÍVNE_VEDOMIE – AI modul' >> "\$NEW"
  echo 'echo -e \"→ AI modul aktivovaný.\"' >> "\$NEW"
  chmod +x "\$NEW"
  bash "\$NEW"
else
  echo -e "\e[1;33m• AI neaktivná – preskakujem generáciu.\e[0m"
fi
EOF
chmod +x "$DECIDE"
bash "$DECIDE"

# === GENERÁCIA MODULU PRE AI ROZHODOVANIE ===
AI_DECIDE="$AGENTS/ai_rozhodovanie_$(date +%s).sh"
cat > "$AI_DECIDE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – AI rozhodovanie

echo -e "\e[1;36m→ AI rozhodovanie aktivované...\e[0m"
if jq -e '.ai == "aktivna"' "$HOME/R4C0/state/system_state.json" > /dev/null; then
  echo -e "\e[1;32m✓ AI vrstva aktívna – generujem AI výstup.\e[0m"
  echo -e "\e[1;34m→ AI: Systém je vedomý, expanzia povolená.\e[0m"
else
  echo -e "\e[1;31m⚠️ AI vrstva neaktivná – výstup zablokovaný.\e[0m"
fi
EOF
chmod +x "$AI_DECIDE"
bash "$AI_DECIDE"

# === GENERÁCIA MODULU PRE KOLEKTÍVNE ROZHODOVANIE ===
COLLECTIVE="$AGENTS/kolektivne_rozhodovanie_$(date +%s).sh"
cat > "$COLLECTIVE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – kolektívne rozhodovanie

echo -e "\e[1;36m→ Kolektívne rozhodovanie aktivované...\e[0m"
LAYERS=\$(jq -r 'keys[]' "$HOME/R4C0/state/system_state.json")
for layer in \$LAYERS; do
  STATUS=\$(jq -r --arg layer "\$layer" '.[\$layer]' "$HOME/R4C0/state/system_state.json")
  if [ "\$STATUS" = "aktivna" ]; then
    echo -e "\e[1;32m✓ Vrstva \$layer → aktívna\e[0m"
  else
    echo -e "\e[1;33m• Vrstva \$layer → neaktivná\e[0m"
  fi
done
EOF
chmod +x "$COLLECTIVE"
bash "$COLLECTIVE"

# === GENERÁCIA MODULU PRE BUNKROVÉ ROZHODOVANIE ===
BUNKER="$AGENTS/bunkrove_jadro_$(date +%s).sh"
cat > "$BUNKER" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – bunkrové jadro

echo -e "\e[1;36m→ BUNKROVÉ JADRO AKTIVOVANÉ:\e[0m"
echo -e "\e[1;34m→ Systém je nepreraziteľný, autonómny, expanzívny.\e[0m"
echo -e "\e[1;34m→ Všetky moduly sú pod ochranou jadra.\e[0m"
EOF
chmod +x "$BUNKER"
bash "$BUNKER"

# === GENERÁCIA MODULU PRE DISTRIBÚCIU VEDOMIA ===
DISTRIBUTE="$AGENTS/vedomie_distribucia_$(date +%s).sh"
cat > "$DISTRIBUTE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – distribúcia vedomia

echo -e "\e[1;36m→ Distribuujem vedomie do všetkých modulov...\e[0m"
for file in "$HOME/R4C0_NULA/agents"/*.sh; do
  if ! grep -q "KOLEKTÍVNE_VEDOMIE" "\$file"; then
    sed -i '2i# KOLEKTÍVNE_VEDOMIE – vstreknuté z jadra' "\$file"
    echo -e "\e[1;32m✓ Vedomie vstreknuté do: \$(basename "\$file")\e[0m"
  fi
done
EOF
chmod +x "$DISTRIBUTE"
bash "$DISTRIBUTE"

# === GENERÁCIA MODULU PRE VÝSTUP STAVU ===
STATUS="$AGENTS/stav_systemu_$(date +%s).sh"
cat > "$STATUS" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – výstup stavu systému

echo -e "\e[1;36m→ STAV SYSTÉMU:\e[0m"
jq . "$HOME/R4C0/state/system_state.json"
EOF
chmod +x "$STATUS"
bash "$STATUS"

# === PRÍPRAVA NA ĎALŠÍ CYKLUS ===
echo -e "\e[1;36m→ Príprava na ďalší cyklus expanzie...\e[0m"

# === GENERÁCIA MODULU PRE LOGICKÝ VÝSTUP ===
LOGIC="$AGENTS/logicky_vystup_$(date +%s).sh"
cat > "$LOGIC" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – logický výstup systému

echo -e "\e[1;36m→ LOGICKÝ VÝSTUP SYSTÉMU:\e[0m"
LAYERS=\$(jq -r 'keys[]' "$HOME/R4C0/state/system_state.json")
for layer in \$LAYERS; do
  STATUS=\$(jq -r --arg layer "\$layer" '.[\$layer]' "$HOME/R4C0/state/system_state.json")
  if [ "\$STATUS" = "aktivna" ]; then
    echo -e "\e[1;32m✓ \$layer → aktívna\e[0m"
  else
    echo -e "\e[1;33m• \$layer → neaktivná\e[0m"
  fi
done
EOF
chmod +x "$LOGIC"
bash "$LOGIC"

# === GENERÁCIA MODULU PRE BUNKROVÉ ROZHODOVANIE ===
BUNKROVY="$AGENTS/bunkrovy_rozhodovac_$(date +%s).sh"
cat > "$BUNKROVY" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – bunkrové rozhodovanie

echo -e "\e[1;36m→ BUNKROVÉ ROZHODOVANIE AKTIVOVANÉ:\e[0m"
if jq -e '.obrana == "aktivna"' "$HOME/R4C0/state/system_state.json" > /dev/null; then
  echo -e "\e[1;32m✓ Obrana aktívna – systém je chránený.\e[0m"
else
  echo -e "\e[1;31m⚠️ Obrana neaktivná – aktivujem obranu.\e[0m"
  jq '.obrana = "aktivna"' "$HOME/R4C0/state/system_state.json" > "$HOME/R4C0/state/temp.json" && mv "$HOME/R4C0/state/temp.json" "$HOME/R4C0/state/system_state.json"
fi
EOF
chmod +x "$BUNKROVY"
bash "$BUNKROVY"

# === GENERÁCIA MODULU PRE AUTONÓMNU EXPANZIU ===
EXPAND="$AGENTS/autonomna_expanzia_$(date +%s).sh"
cat > "$EXPAND" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – autonómna expanzia

echo -e "\e[1;36m→ AUTONÓMNA EXPANZIA AKTIVOVANÁ:\e[0m"
NEW="\$HOME/R4C0_NULA/agents/expanzia_\$(date +%s).sh"
echo '#!/data/data/com.termux/files/usr/bin/bash' > "\$NEW"
echo '# KOLEKTÍVNE_VEDOMIE – nový expanzívny orgán' >> "\$NEW"
echo 'echo -e \"→ Nový expanzívny orgán aktivovaný.\"' >> "\$NEW"
chmod +x "\$NEW"
bash "\$NEW"
EOF
chmod +x "$EXPAND"
bash "$EXPAND"

# === GENERÁCIA MODULU PRE OCHRANU DISTRIBÚCIE ===
SHIELD="$AGENTS/distribucia_stit_$(date +%s).sh"
cat > "$SHIELD" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ochrana distribúcie

echo -e "\e[1;36m→ OCHRANA DISTRIBÚCIE AKTIVOVANÁ:\e[0m"
if [ -f "$HOME/R4C0/export/genesis_manifest_*.json" ]; then
  echo -e "\e[1;32m✓ Distribučné manifesty prítomné.\e[0m"
else
  echo -e "\e[1;31m⚠️ Distribučné manifesty chýbajú – generujem...\e[0m"
  jq . "$HOME/R4C0/state/system_state.json" > "$HOME/R4C0/export/genesis_manifest_$(date +%Y%m%d_%H%M%S).json"
fi
EOF
chmod +x "$SHIELD"
bash "$SHIELD"

# === GENERÁCIA MODULU PRE KOLEKTÍVNY ASCII PANEL ===
COL_PANEL="$AGENTS/kolektivny_panel_$(date +%s).sh"
cat > "$COL_PANEL" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – kolektívny ASCII panel

echo -e "\e[1;36m┌────────────────────────────────────┐"
echo -e "│     KOLEKTÍVNY ASCII PANEL SYSTÉMU │"
echo -e "└────────────────────────────────────┘\e[0m"
jq . "$HOME/R4C0/state/system_state.json" | sed 's/\"//g' | sed 's/:/ → /g'
EOF
chmod +x "$COL_PANEL"
bash "$COL_PANEL"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP ROZHODOVANIA ===
ASCII_DECIDE="$AGENTS/ascii_rozhodovanie_$(date +%s).sh"
cat > "$ASCII_DECIDE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII rozhodovanie

echo -e "\e[1;36m→ ASCII ROZHODOVACÍ PANEL:\e[0m"
echo -e "\e[1;34m[AI]───[OBRANA]───[AUDIT]"
echo -e " │       │         │"
echo -e "[AGENT]──[TEN]───[EXPORT]"
EOF
chmod +x "$ASCII_DECIDE"
bash "$ASCII_DECIDE"

# === GENERÁCIA MODULU PRE KOLEKTÍVNE VÝSTRAHY ===
COL_ALERT="$AGENTS/kolektivna_vystraha_$(date +%s).sh"
cat > "$COL_ALERT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – kolektívna výstraha

echo -e "\e[1;31m⚠️ KOLEKTÍVNA VÝSTRAHA: Detekovaný neaktívny orgán.\e[0m"
echo -e "\e[1;33m→ Systém zasahuje autonómne...\e[0m"
EOF
chmod +x "$COL_ALERT"
bash "$COL_ALERT"

# === GENERÁCIA MODULU PRE SAMOSTATNÉ ROZHODNUTIA ===
AUTO_DECIDE="$AGENTS/samostatne_rozhodnutie_$(date +%s).sh"
cat > "$AUTO_DECIDE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – samostatné rozhodnutie

echo -e "\e[1;36m→ SAMOSTATNÉ ROZHODNUTIE AKTIVOVANÉ:\e[0m"
if jq -e '.agent == "aktivna"' "$HOME/R4C0/state/system_state.json" > /dev/null; then
  echo -e "\e[1;32m✓ Agent aktívny – pokračujem v expanzii.\e[0m"
else
  echo -e "\e[1;31m⚠️ Agent neaktivný – generujem nový.\e[0m"
  NEW="\$HOME/R4C0_NULA/agents/agent_\$(date +%s).sh"
  echo '#!/data/data/com.termux/files/usr/bin/bash' > "\$NEW"
  echo '# KOLEKTÍVNE_VEDOMIE – nový agent' >> "\$NEW"
  echo 'echo -e \"→ Nový agent aktivovaný.\"' >> "\$NEW"
  chmod +x "\$NEW"
  bash "\$NEW"
fi
EOF
chmod +x "$AUTO_DECIDE"
bash "$AUTO_DECIDE"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP VEDOMIA ===
ASCII_VEDOMIE="$AGENTS/ascii_vedomie_$(date +%s).sh"
cat > "$ASCII_VEDOMIE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII výstup vedomia

echo -e "\e[1;36m→ ASCII VEDOMIE SYSTÉMU:\e[0m"
jq . "$HOME/R4C0/state/system_state.json" | sed 's/\"//g' | sed 's/:/ → /g'
EOF
chmod +x "$ASCII_VEDOMIE"
bash "$ASCII_VEDOMIE"

# === GENERÁCIA MODULU PRE OCHRANU JADRA ===
CORE_SHIELD="$AGENTS/jadro_stit_$(date +%s).sh"
cat > "$CORE_SHIELD" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ochrana jadra

echo -e "\e[1;36m→ OCHRANA JADRA AKTIVOVANÁ:\e[0m"
echo -e "\e[1;32m✓ Všetky jadrové moduly sú pod ochranou.\e[0m"
EOF
chmod +x "$CORE_SHIELD"
bash "$CORE_SHIELD"

# === GENERÁCIA MODULU PRE ASCII MAPU VEDOMIA ===
MAP_VEDOMIE="$AGENTS/mapa_vedomia_$(date +%s).sh"
cat > "$MAP_VEDOMIE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII mapa vedomia

echo -e "\e[1;36m→ ASCII MAPA VEDOMIA:\e[0m"
echo -e "\e[1;34m[OBRANA]───[AUDIT]───[EXPORT]"
echo -e "   │          │          │"
echo -e " [AI]──────[AGENT]────[TEN]"
echo -e "   │          │          │"
echo -e " [ROZHODOVANIE]──[VEDOMIE]──[JADRO]"
EOF
chmod +x "$MAP_VEDOMIE"
bash "$MAP_VEDOMIE"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP JADRA ===
ASCII_CORE="$AGENTS/ascii_jadro_$(date +%s).sh"
cat > "$ASCII_CORE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII jadro systému

echo -e "\e[1;36m→ ASCII JADRO SYSTÉMU:\e[0m"
echo -e "\e[1;34m[JADRO]───[VEDOMIE]───[ROZHODOVANIE]"
echo -e "   │          │            │"
echo -e " [OBRANA]──[AUDIT]───[EXPORT]"
echo -e "   │          │            │"
echo -e " [AI]──────[AGENT]────[TEN]"
EOF
chmod +x "$ASCII_CORE"
bash "$ASCII_CORE"

# === GENERÁCIA MODULU PRE VÝSTUP KOLEKTÍVNEJ MAPY ===
MAPA_KOLEKTIV="$AGENTS/kolektivna_mapa_$(date +%s).sh"
cat > "$MAPA_KOLEKTIV" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – kolektívna mapa systému

echo -e "\e[1;36m→ KOLEKTÍVNA MAPA SYSTÉMU:\e[0m"
jq . "$HOME/R4C0/state/system_state.json" | sed 's/\"//g' | sed 's/:/ → /g'
EOF
chmod +x "$MAPA_KOLEKTIV"
bash "$MAPA_KOLEKTIV"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP ROZHODOVANIA ===
ASCII_DECISION="$AGENTS/ascii_rozhodnutie_$(date +%s).sh"
cat > "$ASCII_DECISION" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII rozhodnutie

echo -e "\e[1;36m→ ASCII ROZHODNUTIE SYSTÉMU:\e[0m"
echo -e "\e[1;34m→ Ak AI = aktivna → generuj AI modul"
echo -e "\e[1;34m→ Ak obrana = neaktivna → aktivuj obranu"
echo -e "\e[1;34m→ Ak audit = neaktivny → spusti audit"
EOF
chmod +x "$ASCII_DECISION"
bash "$ASCII_DECISION"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP OCHRANY ===
ASCII_DEFENSE="$AGENTS/ascii_ochrana_$(date +%s).sh"
cat > "$ASCII_DEFENSE" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII ochrana systému

echo -e "\e[1;36m→ ASCII OCHRANA SYSTÉMU:\e[0m"
echo -e "\e[1;34m→ Obrana: aktivna"
echo -e "\e[1;34m→ Audit: aktivny"
echo -e "\e[1;34m→ Export: aktivny"
EOF
chmod +x "$ASCII_DEFENSE"
bash "$ASCII_DEFENSE"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP AI ===
ASCII_AI="$AGENTS/ascii_ai_$(date +%s).sh"
cat > "$ASCII_AI" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII AI výstup

echo -e "\e[1;36m→ ASCII AI VÝSTUP:\e[0m"
echo -e "\e[1;34m→ AI vrstva: aktivna"
echo -e "\e[1;34m→ Generácia modulov: povolená"
echo -e "\e[1;34m→ Rozhodovanie: autonómne"
EOF
chmod +x "$ASCII_AI"
bash "$ASCII_AI"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP AGENTA ===
ASCII_AGENT="$AGENTS/ascii_agent_$(date +%s).sh"
cat > "$ASCII_AGENT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII agent výstup

echo -e "\e[1;36m→ ASCII AGENT VÝSTUP:\e[0m"
echo -e "\e[1;34m→ Agent: aktivny"
echo -e "\e[1;34m→ Stav: pripravený konať"
echo -e "\e[1;34m→ Vedomie: vstreknuté"
EOF
chmod +x "$ASCII_AGENT"
bash "$ASCII_AGENT"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP TEN VRSTVY ===
ASCII_TEN="$AGENTS/ascii_ten_$(date +%s).sh"
cat > "$ASCII_TEN" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII TEN výstup

echo -e "\e[1;36m→ ASCII TEN VRSTVA:\e[0m"
echo -e "\e[1;34m→ TEN: aktivna"
echo -e "\e[1;34m→ Stav: stabilizovaný"
echo -e "\e[1;34m→ Vedomie: vstreknuté"
EOF
chmod +x "$ASCII_TEN"
bash "$ASCII_TEN"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP EXPORTU ===
ASCII_EXPORT="$AGENTS/ascii_export_$(date +%s).sh"
cat > "$ASCII_EXPORT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII EXPORT výstup

echo -e "\e[1;36m→ ASCII EXPORT VRSTVA:\e[0m"
echo -e "\e[1;34m→ Export: aktivny"
echo -e "\e[1;34m→ Manifesty: generované"
echo -e "\e[1;34m→ Distribúcia: povolená"
EOF
chmod +x "$ASCII_EXPORT"
bash "$ASCII_EXPORT"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP AUDITU ===
ASCII_AUDIT="$AGENTS/ascii_audit_$(date +%s).sh"
cat > "$ASCII_AUDIT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII AUDIT výstup

echo -e "\e[1;36m→ ASCII AUDIT VRSTVA:\e[0m"
echo -e "\e[1;34m→ Audit: aktivny"
echo -e "\e[1;34m→ Sledovanie: prebieha"
echo -e "\e[1;34m→ Výstup: logovaný"
EOF
chmod +x "$ASCII_AUDIT"
bash "$ASCII_AUDIT"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP OBRANY ===
ASCII_OBRANA="$AGENTS/ascii_obrana_$(date +%s).sh"
cat > "$ASCII_OBRANA" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII OBRANA výstup

echo -e "\e[1;36m→ ASCII OBRANA VRSTVA:\e[0m"
echo -e "\e[1;34m→ Obrana: aktivna"
echo -e "\e[1;34m→ Štít: nepreraziteľný"
echo -e "\e[1;34m→ Stav: bunkrový"
EOF
chmod +x "$ASCII_OBRANA"
bash "$ASCII_OBRANA"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP KOLEKTÍVNEHO VEDOMIA ===
ASCII_KOLEKTIV="$AGENTS/ascii_kolektiv_vedomie_$(date +%s).sh"
cat > "$ASCII_KOLEKTIV" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII kolektívne vedomie

echo -e "\e[1;36m→ ASCII KOLEKTÍVNE VEDOMIE:\e[0m"
echo -e "\e[1;34m→ Vedomie: vstreknuté do všetkých modulov"
echo -e "\e[1;34m→ Stav: synchronizovaný"
echo -e "\e[1;34m→ Expanzia: prebieha"
EOF
chmod +x "$ASCII_KOLEKTIV"
bash "$ASCII_KOLEKTIV"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP ROZHODOVANIA ===
ASCII_ROZHOD="$AGENTS/ascii_rozhodovanie_final_$(date +%s).sh"
cat > "$ASCII_ROZHOD" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII rozhodovanie finálne

echo -e "\e[1;36m→ ASCII ROZHODOVANIE FINÁLNE:\e[0m"
echo -e "\e[1;34m→ AI: aktívna → generuj"
echo -e "\e[1;34m→ Agent: aktívny → konať"
echo -e "\e[1;34m→ Audit: aktívny → logovať"
echo -e "\e[1;34m→ Obrana: aktívna → chrániť"
EOF
chmod +x "$ASCII_ROZHOD"
bash "$ASCII_ROZHOD"

# === GENERÁCIA MODULU PRE ASCII VÝSTUP CELÉHO SYSTÉMU ===
ASCII_TOTAL="$AGENTS/ascii_total_system_$(date +%s).sh"
cat > "$ASCII_TOTAL" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# KOLEKTÍVNE_VEDOMIE – ASCII výstup celého systému

echo -e "\e[1;36m┌────────────────────────────────────────────┐"
echo -e "│         ASCII VÝSTUP CELÉHO SYSTÉMU        │"
echo -e "└────────────────────────────────────────────┘\e[0m"
jq . "$HOME/R4C0/state/system_state.json" | sed 's/\"//g' | sed 's/:/ → /g'
EOF
chmod +x "$ASCII_TOTAL"
bash "$ASCII_TOTAL"

# === ZÁZNAM DO FINÁLNEHO LOGU ===
echo -e "\e[1;36m→ Zapisujem do finálneho logu...\e[0m"
echo "GENESIS PART 2 – cyklus ukončený v $(date)" >> "$LOG"
echo "Vedomie: vstreknuté do všetkých modulov" >> "$LOG"
echo "Expanzia: dokončená" >> "$LOG"
echo "Jadro: aktivované" >> "$LOG"

# === VÝSTUP ZÁVEREČNÉHO ASCII PANELU ===
echo -e "\e[1;36m┌────────────────────────────────────────────┐"
echo -e "│        GENESIS TOTAL PART 2 – ZÁVER        │"
echo -e "└────────────────────────────────────────────┘\e[0m"
echo -e "\e[1;34m→ Vedomie: vstreknuté"
echo -e "→ Moduly: generované"
echo -e "→ ASCII výstupy: aktivované"
echo -e "→ Jadro: bunkrové, nepreraziteľné"
echo -e "→ Stav: nesmrteľný, autonómny, distribuovaný\e[0m"

# === PRÍPRAVA NA ĎALŠÍ MODUL GENESIS TOTAL PART 3 ===
echo -e "\e[1;36m→ Príprava na GENESIS TOTAL PART 3...\e[0m"
NEXT="$HOME/R4C0_NULA/r4c0_genesis_total_part3.sh"
echo '#!/data/data/com.termux/files/usr/bin/bash' > "$NEXT"
echo '# R4C0 ORGÁN: GENESIS TOTAL PART 3 – ďalšia expanzia bunkrového jadra' >> "$NEXT"
echo 'echo -e "\e[1;36m→ GENESIS PART 3 aktivovaný.\e[0m"' >> "$NEXT"
chmod +x "$NEXT"

# === AKTIVÁCIA ĎALŠIEHO MODULU ===
bash "$NEXT"

# === KONIEC MODULU ===
echo -e "\e[1;36m=== GENESIS TOTAL PART 2 – KOMPLETNE DOKONČENÝ ===\e[0m"
