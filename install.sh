#!/usr/bin/env bash
# install.sh — install this repo as a personal Cursor skill on macOS/Linux.
set -euo pipefail

source_dir="$(cd "$(dirname "$0")" && pwd)"
target_dir="$HOME/.cursor/skills/bigquery"

if [ -e "$target_dir" ]; then
    read -r -p "Target already exists: $target_dir. Overwrite? (y/N) " ans
    if [ "$ans" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$target_dir"
fi

mkdir -p "$(dirname "$target_dir")"
ln -s "$source_dir" "$target_dir"
echo "Symlinked $target_dir -> $source_dir"
echo
echo "Done. Restart Cursor (or reload the workspace) to pick up the skill."
