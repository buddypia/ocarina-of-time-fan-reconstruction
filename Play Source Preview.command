#!/bin/zsh
set -eu
cd -- "${0:A:h}"
if [[ ! -d game/.godot/imported ]]; then
  python3 tools/authored.py import
fi
python3 tools/authored.py play
