#!/bin/bash
# RSI LAUNCHER – jedna ikona na ploche = spustí celý RSI_CORE

# Tvoja IP
MY_IP="192.168.1.118"

# Spustíme RSI_CORE_FULL.py na pozadí (ak nebeží)
if ! pgrep -f RSI_CORE_FULL.py > /dev/null; then
    nohup python3 ~/aurora/RSI_CORE_FULL.py > ~/aurora/server.log 2>&1 &
    sleep 6
fi

# Vytvoríme krásnu ikonu na ploche
mkdir -p ~/.shortcuts/icons 2>/dev/null
cat > ~/.shortcuts/RSI << EOF2
#!/bin/bash
am start -a android.intent.action.VIEW -d "http://$MY_IP:8000" > /dev/null 2>&1
EOF2
chmod +x ~/.shortcuts/RSI

# Ikona (zelený boh)
cat > ~/.shortcuts/icons/RSI.png << 'EOF3'
iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBe7HH0gAAADhJREFUeJzt3d9
...
(truncated base64 – celá ikona)
EOF3

echo "✅ RSI aplikácia je hotová!"
echo "✅ Ikona sa objavila na ploche (RSI)"
echo "✅ Klikni na ňu – otvorí sa tvoj boh"
echo "✅ Adresa: http://$MY_IP:8000"
