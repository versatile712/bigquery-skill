#!/usr/bin/env bash
# install.sh — install this repo as an Agent Skill on macOS/Linux.
# Auto-detects Cursor / Claude Code / Codex CLI skills directories and
# installs into each that exists. Prefers symlink.
#
# Usage:
#   ./install.sh                   # auto-detect and install into all found platforms
#   ./install.sh --target cursor   # install into a specific platform only
#   ./install.sh --all             # install into all three (create missing dirs)

set -euo pipefail

source_dir="$(cd "$(dirname "$0")" && pwd)"
skill_name="bigquery"

declare -A platforms=(
    ["cursor"]="$HOME/.cursor/skills"
    ["claude"]="$HOME/.claude/skills"
    ["codex"]="$HOME/.codex/skills"
)

target=""
all=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) target="$2"; shift 2 ;;
        --all)    all=true; shift ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

selected=()
if [[ -n "$target" ]]; then
    if [[ -z "${platforms[$target]:-}" ]]; then
        echo "Unknown --target '$target'. Valid: cursor, claude, codex."
        exit 1
    fi
    selected+=("$target")
elif $all; then
    selected=("${!platforms[@]}")
else
    for k in "${!platforms[@]}"; do
        [[ -d "${platforms[$k]}" ]] && selected+=("$k")
    done
    if [[ ${#selected[@]} -eq 0 ]]; then
        echo "No known agent skills directories found; falling back to --all."
        selected=("${!platforms[@]}")
    fi
fi

echo "Installing skill '$skill_name' from: $source_dir"
echo "Targets: ${selected[*]}"
echo

for p in "${selected[@]}"; do
    base_dir="${platforms[$p]}"
    target_dir="$base_dir/$skill_name"

    mkdir -p "$base_dir"

    if [[ -e "$target_dir" ]]; then
        read -r -p "[$p] Target already exists: $target_dir. Overwrite? (y/N) " ans
        if [[ "$ans" != "y" ]]; then
            echo "[$p] Skipped."
            continue
        fi
        rm -rf "$target_dir"
    fi

    ln -s "$source_dir" "$target_dir"
    echo "[$p] Symlinked -> $target_dir"
done

echo
echo "Done. Restart your agent (or reload the workspace) to pick up the skill."
