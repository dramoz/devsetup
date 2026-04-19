#!/usr/bin/env bash
# scripts/claude/claude_backup.sh
# Sync live ~/.claude/ managed files back into this repo so changes are preserved.
# Run from any directory — the script resolves its own absolute path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo "[backup] $*"; }
success() { echo "[backup] OK: $*"; }
warn()    { echo "[backup] WARN: $*" >&2; }

# If the source is a symlink back into this repo, skip (already in sync).
# If it's a real file, copy it.
backup_file() {
  local src="$1"    # path in ~/.claude/
  local dst="$2"    # path in repo

  if [[ ! -e "$src" ]]; then
    warn "source not found, skipping: $src"
    return
  fi

  if [[ -L "$src" ]]; then
    local target
    target="$(readlink "$src")"
    if [[ "$target" == "$dst" ]]; then
      info "already symlinked to repo, skipping: $src"
      return
    fi
    warn "$src is a symlink to $target (not repo). Copying target content."
    src="$target"
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  success "$src → $dst"
}

# ---------------------------------------------------------------------------
# Global config files
# ---------------------------------------------------------------------------
info "Backing up global config files..."
backup_file "${CLAUDE_DIR}/CLAUDE.md"     "${SCRIPT_DIR}/globalsetup/CLAUDE.md"
backup_file "${CLAUDE_DIR}/settings.json" "${SCRIPT_DIR}/globalsetup/settings.json"

# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------
info "Backing up hooks..."
backup_file "${CLAUDE_DIR}/hooks/bash_safe_cmd_chk.py" "${SCRIPT_DIR}/hooks/bash_safe_cmd_chk.py"

# ---------------------------------------------------------------------------
# Policies
# ---------------------------------------------------------------------------
info "Backing up policies..."
backup_file "${CLAUDE_DIR}/policies/bash_policy.yaml" "${SCRIPT_DIR}/policies/bash_policy.yaml"

# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------
info "Backing up scripts..."
backup_file "${CLAUDE_DIR}/scripts/statusline.sh" "${SCRIPT_DIR}/scripts/statusline.sh"

# ---------------------------------------------------------------------------
# Skills — copy SKILL.md for each skill (or entire dir if not symlinked)
# ---------------------------------------------------------------------------
info "Backing up skills..."
if [[ -d "${CLAUDE_DIR}/skills" ]]; then
  for skill_dir in "${CLAUDE_DIR}/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    repo_skill="${SCRIPT_DIR}/skills/${skill_name}"

    if [[ -L "${skill_dir%/}" ]]; then
      local_target
      local_target="$(readlink "${skill_dir%/}")"
      if [[ "$local_target" == "$repo_skill" ]]; then
        info "skill ${skill_name} already symlinked to repo, skipping"
        continue
      fi
    fi

    mkdir -p "$repo_skill"
    # Copy all files within the skill directory
    find "$skill_dir" -maxdepth 1 -type f | while read -r f; do
      cp "$f" "${repo_skill}/$(basename "$f")"
      success "$f → ${repo_skill}/$(basename "$f")"
    done
  done
fi

# ---------------------------------------------------------------------------
# Plugins — known_marketplaces.json
# ---------------------------------------------------------------------------
if [[ -f "${CLAUDE_DIR}/plugins/known_marketplaces.json" ]]; then
  info "Backing up plugins/known_marketplaces.json..."
  backup_file "${CLAUDE_DIR}/plugins/known_marketplaces.json" "${SCRIPT_DIR}/plugins/known_marketplaces.json"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Backup complete. Review changes with: git -C '${SCRIPT_DIR}' diff --stat"
