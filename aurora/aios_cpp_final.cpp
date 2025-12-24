#include <iostream>
#include <string>
#include <thread>
#include <chrono>

using namespace std;
using namespace std::chrono_literals;

// Tu predpokladáme, že NeutronBridge a LLMUnit sú definované vyššie v súbore
// Ak sú v externých súboroch, musia byť inkludované.

/* ... tvoje definície tried NeutronBridge a LLMUnit ... */

int main() {
    // Vyčistenie terminálu a ASCII Banner
    cout << "\033[2J\033[H";
    cout << R"(
   _____ _     _       _ _        _   _             _ _
  |  __ (_)   | |     | | |      | | (_)           | | |
  | |__) | ___| |_ ___| | | ___  | |_ _ _ __   __ _| | | ___
  |  _  / / __| __/ _| | |/ _ \ | __| | '_ \ / _` | | |/ _ \
  | | \ \ \__ \ || (__| | |  __/ | |_| | | | | (_| | | | (_) |
  |_|  \_\___/\__\___|_|_|\___|  \__|_|_| |_|\__,_|_|_|\___/
)" << endl;

    cout << "\033[38;5;82mAIOS v13.0 – PLNÝ C++ REŽIM – BEZPEČNÝ RUNTIME\033[0m\n";

    try {
        NeutronBridge bridge;
        LLMUnit llm(bridge);
        llm.run();
    } catch (const std::exception& e) {
        cerr << "\n\033[38;5;196m[FATAL ERROR] AIOS JADRO SKOLABOVALO!\033[0m" << endl;
        cerr << "[LOG] Dôvod: " << e.what() << endl;
        return 1;
    } catch (...) {
        cerr << "\n\033[38;5;196m[FATAL ERROR] Neznáma kritická chyba v C++ runtime!\033[0m" << endl;
        return 1;
    }

    return 0;
}
