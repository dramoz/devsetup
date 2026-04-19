#!/usr/bin/env bash
# scripts/claude/claude_setup.sh
# Set up Claude Code global settings on a new host using symlinks back to this repo.
# Run from any directory — the script resolves its own absolute path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo "[setup] $*"; }
success() { echo "[setup] OK: $*"; }
warn()    { echo "[setup] WARN: $*" >&2; }

make_link() {
  local src="$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  mkdir -p "$dst_dir"

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      success "already linked: $dst → $src"
      return
    else
      warn "replacing existing symlink: $dst → $current_target"
      rm "$dst"
    fi
  elif [[ -e "$dst" ]]; then
    local backup="${dst}.bak.$(date +%s)"
    warn "backing up existing file: $dst → $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  success "$dst → $src"
}

# ---------------------------------------------------------------------------
# Check dependencies
# ---------------------------------------------------------------------------
command -v claude >/dev/null 2>&1 || warn "claude CLI not found — install it first"

# ---------------------------------------------------------------------------
# Global config files (live directly in ~/.claude/)
# ---------------------------------------------------------------------------
info "Linking global config files..."
make_link "${SCRIPT_DIR}/globalsetup/CLAUDE.md"    "${CLAUDE_DIR}/CLAUDE.md"
make_link "${SCRIPT_DIR}/globalsetup/settings.json" "${CLAUDE_DIR}/settings.json"

# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------
info "Linking hooks..."
make_link "${SCRIPT_DIR}/hooks/bash_safe_cmd_chk.py" "${CLAUDE_DIR}/hooks/bash_safe_cmd_chk.py"
chmod +x "${SCRIPT_DIR}/hooks/bash_safe_cmd_chk.py"

# ---------------------------------------------------------------------------
# Policies
# ---------------------------------------------------------------------------
info "Linking policies..."
make_link "${SCRIPT_DIR}/policies/bash_policy.yaml" "${CLAUDE_DIR}/policies/bash_policy.yaml"

# ---------------------------------------------------------------------------
# Scripts (statusline, etc.)
# ---------------------------------------------------------------------------
info "Linking scripts..."
make_link "${SCRIPT_DIR}/scripts/statusline.sh" "${CLAUDE_DIR}/scripts/statusline.sh"
chmod +x "${SCRIPT_DIR}/scripts/statusline.sh"

# ---------------------------------------------------------------------------
# Skills — symlink each skill directory under ~/.claude/skills/
# ---------------------------------------------------------------------------
info "Linking skills..."
if [[ -d "${SCRIPT_DIR}/skills" ]]; then
  mkdir -p "${CLAUDE_DIR}/skills"
  for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    dst_skill="${CLAUDE_DIR}/skills/${skill_name}"
    # Remove existing dir (non-symlink) so we can replace with symlink
    if [[ -d "$dst_skill" && ! -L "$dst_skill" ]]; then
      warn "backing up existing skill dir: ${dst_skill} → ${dst_skill}.bak.$(date +%s)"
      mv "$dst_skill" "${dst_skill}.bak.$(date +%s)"
    fi
    make_link "${skill_dir%/}" "$dst_skill"
  done
fi

# ---------------------------------------------------------------------------
# Plugins — register known marketplaces
# ---------------------------------------------------------------------------
if [[ -f "${SCRIPT_DIR}/plugins/known_marketplaces.json" ]]; then
  info "Linking plugins/known_marketplaces.json..."
  mkdir -p "${CLAUDE_DIR}/plugins"
  make_link "${SCRIPT_DIR}/plugins/known_marketplaces.json" "${CLAUDE_DIR}/plugins/known_marketplaces.json"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Claude Code global settings configured. Verify with: claude --version"
