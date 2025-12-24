#!/usr/bin/env bash
# =============================================================================
# AI/OS MODULE HUNTER - Nájde všetky súvisiace moduly v distribúcii
# =============================================================================

# Uisti sa, že sme v HOME adresári
cd ~ || { echo "Chyba: Nedá sa prejsť do home adresára (~)." >&2; exit 1; }
mkdir -p ai_os_modules

# Vytvorenie dočasného súboru pre výsledky
RESULTS_FILE=ai_os_modules/source_hits.txt
> "$RESULTS_FILE"
echo "🔍 Hľadám AI/OS moduly v celej distribúcii..."

# KĽÚČOVÉ SLOVÁ PRE HľadANIE
# Kľúčové slová sú spojené do jedného reťazca pre efektívne vyhľadávanie
# Používame | ako oddeľovač pre grep -E
KEYWORDS_REGEX='sentence.*transformer|bert|gpt|llama|transformers|torch|tensorflow|faiss|vector|embedding|nlp|neural|model|llm|kernel|init|systemd|service|daemon|boot|initramfs|device|driver|module|sched|mm|shell|bash|zsh|fish|terminal|gui|wayland|x11|launcher|desktop|wm|compositor|aosp|android|framework|hal|binder|surfaceflinger|activity|service|receiver|manifest|selinux|apparmor|seccomp|capability|keyring|tpm'

# Hľadanie v SOURCE CODES (Optimálna verzia so správnou syntaxou find)
echo "📂 Hľadám v zdrojových kódoch a skriptoch..."
find . -type f \( -name "*.py" -o -name "*.sh" -o -name "*.c" -o -name "*.cpp" -o -name "*.java" \) \
    -exec grep -lE "$KEYWORDS_REGEX" {} \; 2>/dev/null \
    | while read file; do
        # Pridávame detaily o type modulu
        if echo "$file" | grep -qE 'aurora|ultron|ai|nlp|llm'; then
            echo "AI → $file" >> "$RESULTS_FILE"
        elif echo "$file" | grep -qE 'kernel|init|boot|systemd'; then
            echo "KERNEL → $file" >> "$RESULTS_FILE"
        elif echo "$file" | grep -qE 'shell|bash|zsh|gui|terminal'; then
            echo "SHELL → $file" >> "$RESULTS_FILE"
        fi
    done

# Hľadanie v PKG/MANIFEST (Jednoduché a efektívne)
echo "📦 Hľadám v balíkoch/manifestoch..."
find . -name "PKGBUILD" -o -name "*.manifest" -o -name "Makefile" -o -name "CMakeLists.txt" 2>/dev/null | \
while read file; do
    if grep -qiE "ai|nlp|kernel|android|shell|gui|security" "$file" 2>/dev/null; then
        echo "PKG → $file" >> "$RESULTS_FILE"
    fi
done

# Zhrnutie modulov
SUMMARY_FILE=ai_os_modules/modules_summary.txt
echo "📋 Zhrnutie modulov (TOP HITS):" > "$SUMMARY_FILE"
echo "AI/ML Moduly: $(grep -c '^AI →' "$RESULTS_FILE") hits" >> "$SUMMARY_FILE"
echo "KERNEL Moduly: $(grep -c '^KERNEL →' "$RESULTS_FILE") hits" >> "$SUMMARY_FILE"
echo "SHELL Moduly: $(grep -c '^SHELL →' "$RESULTS_FILE") hits" >> "$SUMMARY_FILE"
echo "PKG/Build Hity: $(grep -c '^PKG →' "$RESULTS_FILE") hits" >> "$SUMMARY_FILE"


echo "✅ MODULE HUNT DOKONČENÝ!"
echo "📁 Výsledky: ~/ai_os_modules/"
echo "--------------------------------------------------------"
cat "$SUMMARY_FILE"
echo "--------------------------------------------------------"
echo "🔥 TOP 20 NÁJDENÝCH SÚBOROV (unikátny počet):"
# Spočítanie UNIKÁTNYCH NÁZVOV súborov (bez duplicity, bez ohľadu na kategóriu)
cat "$RESULTS_FILE" | cut -d' ' -f3- | sort | uniq -c | sort -nr | head -20
