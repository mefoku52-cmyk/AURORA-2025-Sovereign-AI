#!/bin/bash

echo "🔧 Removing problematic large files from Git index..."
git rm --cached aurora/dummy.aurora 2>/dev/null
git rm --cached aurora/aurora_dataset.txt 2>/dev/null

echo "🛡️ Adding them to .gitignore..."
echo "aurora/dummy.aurora" >> .gitignore
echo "aurora/aurora_dataset.txt" >> .gitignore

echo "🧹 Removing any nested .git folders (submodule cleanup)..."
find aurora -type d -name ".git" -exec rm -rf {} +

echo "📜 Creating LICENSE (All Rights Reserved)..."
cat << 'LIC' > LICENSE
Copyright (c) 2025 Koran

All Rights Reserved.

This software and all associated files, scripts, modules, and assets are the exclusive property of the author.

You MAY NOT:
- copy
- modify
- merge
- publish
- distribute
- sublicense
- sell
- reverse engineer
- train AI models on this code
- create derivative works
- use any part of this project for commercial or non-commercial purposes

You MAY:
- view the code on GitHub for informational purposes only.

Any violation of these terms is strictly prohibited and may result in legal action.
LIC

echo "🛡️ Adding LICENSE to Git..."
git add LICENSE

echo "📦 Committing changes..."
git add .
git commit -m "Secure AURORA system: remove large files, add license, fix submodules"

echo "🚀 Pushing to GitHub..."
git push

echo "🔥 AURORA is now secured, licensed, and fully uploaded."
