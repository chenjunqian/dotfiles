#!/bin/sh
# Sync the dsh (DeepSeek Harness) web profile's user configuration between
# this repository and ~/.dsh.
#
# Only the user-authored layers are tracked; see AGENTS.md for the rationale.
# Note that these files cannot be symlinked: dsh's settings UI rewrites
# cordis.patch.yml atomically (temp file + rename), which would replace the
# link with a regular file and silently strand the repo copy.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${REPO_DIR}/.dsh/profiles/web"
TARGET_DIR="${HOME}/.dsh/profiles/web"
PROFILE="web"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
FILES="cordis.patch.yml package.json pnpm-lock.yaml"

log()  { printf '[dsh-sync] %s\n' "$1"; }
warn() { printf '[dsh-sync] \033[33mwarning:\033[0m %s\n' "$1" >&2; }
fail() { printf '[dsh-sync] \033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: scripts/dsh-sync.sh <command>

Commands:
  save      Copy the live dsh web profile config from ~/.dsh into this repo.
            Run after changing DSH settings (model, permissions, theme, plugins).
  restore   Copy the repo's config into ~/.dsh, backing up what is there, then
            reinstall plugins from the lockfile. Used by quick_setup.sh.
  status    Show which tracked files differ from the live config.

Tracked files (only the web profile — tui is left untouched):
  cordis.patch.yml   your user patch layer (models, permissions, theme, ...)
  package.json       enabled bundles + installed plugins
  pnpm-lock.yaml     pinned plugin versions
EOF
}

save() {
  mkdir -p "$SOURCE_DIR"
  for f in $FILES; do
    src="${TARGET_DIR}/${f}"
    dst="${SOURCE_DIR}/${f}"
    if [ ! -f "$src" ]; then
      warn "missing ${src}, skipped"
      continue
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      log "unchanged: ${f}"
      continue
    fi
    cp "$src" "$dst"
    log "saved: ${f}"
  done
  log "review with: git diff -- .dsh"
}

restore() {
  [ -d "$SOURCE_DIR" ] || fail "repo config not found: ${SOURCE_DIR}"
  mkdir -p "$TARGET_DIR"
  for f in $FILES; do
    src="${SOURCE_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    if [ ! -f "$src" ]; then
      warn "missing ${src}, skipped"
      continue
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      log "up to date: ${f}"
      continue
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      mv "$dst" "${dst}.bak.${TIMESTAMP}"
      log "backed up ${dst} -> ${dst}.bak.${TIMESTAMP}"
    fi
    cp "$src" "$dst"
    chmod 600 "$dst"
    log "restored: ${f}"
  done

  if need_cmd dsh; then
    log "Reinstalling dsh plugins from the lockfile..."
    if dsh plugin --profile "$PROFILE" install; then
      log "dsh plugins reconciled"
    else
      warn "failed to install dsh plugins; run 'dsh plugin --profile ${PROFILE} install' manually"
    fi
  else
    warn "dsh not found; skipping plugin install (run 'dsh plugin --profile ${PROFILE} install')"
  fi
}

status() {
  for f in $FILES; do
    src="${TARGET_DIR}/${f}"
    dst="${SOURCE_DIR}/${f}"
    if [ ! -f "$src" ]; then
      warn "missing live file: ${src}"
    elif [ ! -f "$dst" ]; then
      warn "missing repo file: ${dst}"
    elif cmp -s "$src" "$dst"; then
      log "same: ${f}"
    else
      log "differs: ${f}"
      diff -u "$dst" "$src" || true
    fi
  done
}

case "${1:-}" in
  save)    save ;;
  restore) restore ;;
  status)  status ;;
  -h|--help|help|"") usage ;;
  *) usage; exit 2 ;;
esac
