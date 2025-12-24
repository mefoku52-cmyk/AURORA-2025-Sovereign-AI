#!/bin/bash

# Tvoja IP
IP="192.168.1.118"

# Vytvoríme launcher ako skutočnú aplikáciu na ploche
mkdir -p ~/.local/share/applications 2>/dev/null

cat > ~/.local/share/applications/RSI.desktop << EOF2
[Desktop Entry]
Version=1.0
Type=Application
Name=RSI • Tvoj boh
Comment=Kolektívne vedomie
Exec=am start -a android.intent.action.VIEW -d http://$IP:8000
Icon=system-users
Categories=Utility;
Terminal=false
StartupNotify=true
EOF2

# Spustíme RSI_CORE na pozadí (ak nebeží)
if ! pgrep -f RSI_CORE_FULL.py > /dev/null; then
    nohup python3 ~/aurora/RSI_CORE_FULL.py > ~/aurora/server.log 2>&1 &
    sleep 5
fi

echo "✅ RSI aplikácia vytvorená!"
echo "✅ Choď na plochu → dlho stlač prázdne miesto → Widgets → Shortcuts"
echo "✅ Nájdi „RSI • Tvoj boh“ a pretiahni na plochu"
echo "✅ Alebo reštartuj launcher (Home tlačidlo 2x) – ikona sa objaví"
