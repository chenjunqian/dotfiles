#!/bin/sh
# Link the dsh (DeepSeek Harness) web profile's user configuration to this
# repository, and keep the links alive.
#
# dsh rewrites cordis.patch.yml, package.json and pnpm-lock.yaml through
# writeFileAtomic (temp file + rename), and a rename replaces a symlink with a
# regular file. `watch` — or any manual run — notices the replaced file, adopts
# its content into the repo, and recreates the link, so edits made inside dsh
# still land in this repository.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${REPO_DIR}/.dsh/profiles/web"
TARGET_DIR="${HOME}/.dsh/profiles/web"
PROFILE="web"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
FILES="cordis.patch.yml package.json pnpm-lock.yaml"
INTERVAL="${DSH_SYNC_INTERVAL:-2}"

log()  { printf '[dsh-sync] %s\n' "$1"; }
warn() { printf '[dsh-sync] \033[33mwarning:\033[0m %s\n' "$1" >&2; }
fail() { printf '[dsh-sync] \033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: scripts/dsh-sync.sh <command>

Commands:
  link      Symlink ~/.dsh/profiles/web/{cordis.patch.yml,package.json,
            pnpm-lock.yaml} to this repo. A newer regular file on either side
            wins before the link is created. Idempotent; `save` is an alias.
  restore   Force the repo's content onto ~/.dsh (backs up what is there),
            then link. For a fresh machine.
  status    Show link state and content drift.
  watch     Keep the links alive (every $DSH_SYNC_INTERVAL seconds, default 2).
            Run by the systemd user service installed by quick_setup.sh.

Only the web profile is tracked; the tui profile is left untouched.
EOF
}

take_lock() {
  local dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
  mkdir -p "$dir"
  exec 9>"${dir}/dsh-sync.lock"
  if need_cmd flock; then
    flock -w 5 9 || { warn "another dsh-sync run holds the lock; skipping"; return 1; }
  fi
  return 0
}

# Make $dst a symlink to $src, reconciling content first: whichever side has
# the newer regular file wins, then the link is recreated.
sync_one() {
  local src="$1" dst="$2" name target
  name="$(basename "$dst")"

  if [ -L "$dst" ]; then
    target="$(readlink "$dst")"
    if [ "$target" = "$src" ] && [ -f "$src" ]; then
      log "ok: ${name}"
      return 0
    fi
    warn "${dst} -> ${target} (expected ${src}); relinking"
    rm -f "$dst"
  elif [ -f "$dst" ]; then
    if [ -f "$src" ] && cmp -s "$src" "$dst"; then
      log "content equal: ${name}"
    elif [ ! -f "$src" ] || [ "$dst" -nt "$src" ]; then
      cp "$dst" "$src"
      log "adopted (live newer): ${name}"
    else
      cp "$src" "$dst"
      log "pushed (repo newer): ${name}"
    fi
    warn "${dst} was a regular file instead of a link; replacing it with a symlink"
    rm -f "$dst"
  else
    log "creating link: ${name}"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  log "linked: ${dst} -> ${src}"
}

sync_all() {
  local f
  mkdir -p "$TARGET_DIR"
  for f in $FILES; do
    sync_one "${SOURCE_DIR}/${f}" "${TARGET_DIR}/${f}"
  done
}

link() {
  local f
  [ -d "$SOURCE_DIR" ] || fail "repo config not found: ${SOURCE_DIR}"
  for f in $FILES; do
    [ -f "${SOURCE_DIR}/${f}" ] || fail "missing repo file: ${SOURCE_DIR}/${f}"
  done
  take_lock || return 0
  sync_all
}

restore() {
  local f src dst
  [ -d "$SOURCE_DIR" ] || fail "repo config not found: ${SOURCE_DIR}"
  take_lock || return 0
  mkdir -p "$TARGET_DIR"
  for f in $FILES; do
    src="${SOURCE_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    [ -f "$src" ] || { warn "missing ${src}, skipped"; continue; }
    if [ -L "$dst" ]; then
      if [ "$(readlink "$dst")" = "$src" ]; then
        log "already linked: ${f}"
        continue
      fi
      rm -f "$dst"
    elif [ -e "$dst" ]; then
      if cmp -s "$src" "$dst"; then
        rm -f "$dst"
        log "replacing identical file with a link: ${f}"
      else
        mv "$dst" "${dst}.bak.${TIMESTAMP}"
        log "backed up ${dst} -> ${dst}.bak.${TIMESTAMP}"
      fi
    fi
    ln -s "$src" "$dst"
    log "linked: ${dst} -> ${src}"
  done
}

status() {
  local f src dst rc=0
  for f in $FILES; do
    src="${SOURCE_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    if [ -L "$dst" ]; then
      if [ "$(readlink "$dst")" = "$src" ]; then
        log "linked: ${f}"
      else
        warn "${f} is a symlink to $(readlink "$dst"), not to the repo"
        rc=1
      fi
    elif [ -f "$dst" ]; then
      warn "${f} is a regular file — dsh's atomic write replaced the link"
      if cmp -s "$src" "$dst" 2>/dev/null; then
        log "  content identical to the repo; 'link' will restore the symlink"
      else
        log "  content DIFFERS; 'link' adopts the live copy into the repo"
      fi
      rc=1
    else
      warn "${f} missing"
      rc=1
    fi
  done
  return $rc
}

watch() {
  trap 'exit 0' INT TERM
  printf '[dsh-sync] watching %s (interval %ss)\n' "$TARGET_DIR" "$INTERVAL"
  local f dst broken
  while :; do
    broken=0
    for f in $FILES; do
      dst="${TARGET_DIR}/${f}"
      if [ -L "$dst" ] && [ "$(readlink "$dst")" = "${SOURCE_DIR}/${f}" ]; then :; else broken=1; fi
    done
    if [ "$broken" = 1 ]; then
      printf '[dsh-sync] link broken for at least one file, healing\n'
      if take_lock 2>/dev/null; then sync_all || true; fi
    fi
    sleep "$INTERVAL"
  done
}

case "${1:-}" in
  link|save) link ;;
  restore)   restore ;;
  status)    status ;;
  watch)     watch ;;
  -h|--help|help|"") usage ;;
  *) usage; exit 2 ;;
esac
