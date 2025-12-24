#!/bin/bash

# Spúšťací skript pre editáciu súborov Aurora (Alternatívna verzia s podčiarkovníkmi)
# Používa názvy súborov presne tak, ako boli uvedené s '_' miesto '/'

# Presun do hlavného adresára projektu
cd ~/aurora || { echo "Adresár ~/aurora nebol nájdený. Skript ukončený."; exit 1; }

echo "--- Spúšťam editáciu súborov Aurora s podčiarkovníkmi v názve ---"

# Zoznam súborov
nano core_math.go
nano core_model.go
nano core_engine.go

# OS-INT súbory
nano os_int_aurora_os.h
nano os_int_aurora_os.cpp

# SCHEDULER súbory
# Opravené z 'scheduler_Cargo.toml' a 'scheduler_src_main.rs' (vypúšťam stredné podčiarkovníky pre väčšiu logiku)
nano scheduler/Cargo.toml # Predpokladám, že toto je správna cesta
nano scheduler/src/main.rs # Predpokladám, že toto je správna cesta

# Ak naozaj chcete názvy s podčiarkovníkmi aj pre tieto:
# nano scheduler_Cargo.toml
# nano scheduler_src_main.rs

# PYTHON/API súbory
nano api_main.py
nano models_manager.py
nano models_convert_hf_to_aurora.py

# Ostatné
nano watchdog_watchdog.go
nano tests_test_math.go
nano README.md

echo "--- Editácia dokončená. ---"
