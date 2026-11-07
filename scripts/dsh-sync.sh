#!/bin/sh
# Link the dsh (DeepSeek Harness) web profile's user configuration to this
# repository, and keep it that way.
#
# Two kinds of file are tracked:
#
#   * linked (cordis.patch.yml, package.json) — live is a symlink into the repo,
#     so an edit on either side shows up on both. dsh rewrites them through
#     writeFileAtomic (temp file + rename) and a rename replaces a symlink with
#     a regular file, so `watch` adopts the replaced content back into the repo
#     and recreates the link.
#
#   * mirrored (pnpm-lock.yaml) — live is a REGULAR file and the repo keeps a
#     copy. pnpm >= 11 refuses to write a symlinked lockfile
#     (ERR_PNPM_LOCKFILE_IS_SYMLINK), which makes every install/update issued by
#     `dsh plugin` or the plugin market fail, so this one cannot be a symlink.
#     `watch` copies live -> repo whenever pnpm rewrites it; `link` also pushes
#     the repo copy when the repo side is newer.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${REPO_DIR}/.dsh/profiles/web"
TARGET_DIR="${HOME}/.dsh/profiles/web"
PROFILE="web"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
LINK_FILES="cordis.patch.yml package.json"
MIRROR_FILES="pnpm-lock.yaml"
INTERVAL="${DSH_SYNC_INTERVAL:-2}"

log()  { printf '[dsh-sync] %s\n' "$1"; }
warn() { printf '[dsh-sync] \033[33mwarning:\033[0m %s\n' "$1" >&2; }
fail() { printf '[dsh-sync] \033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: scripts/dsh-sync.sh <command>

Commands:
  link      Reconcile ~/.dsh/profiles/web with this repo. cordis.patch.yml and
            package.json become symlinks into the repo; pnpm-lock.yaml is a
            regular file kept in sync with the repo copy (newer side wins, so a
            fresh `git checkout` is pushed out and a pnpm rewrite is adopted).
            Idempotent; `save` is an alias.
  restore   Force the repo's content onto ~/.dsh (backs up what is there).
            For a fresh machine.
  status    Show link/mirror state and content drift.
  watch     Keep everything in sync (every $DSH_SYNC_INTERVAL seconds, default 2).
            Run by the systemd user service installed by quick_setup.sh.

Only the web profile is tracked; the tui profile is left untouched.
EOF
}

# Serialize concurrent runs through a lock file. The caller must invoke this in
# a subshell (`( take_lock && sync_all ... )`): fd 9 stays open for the life of
# the calling shell, and the long-running `watch` process would otherwise hold
# the lock forever and block every manual `link`.
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
sync_link_one() {
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

# Keep $dst a regular file and mirror its content into $src.
# $3 = 1 lets a newer repo copy win (explicit `link`); in `watch` the repo copy
# is only ever updated from the live file, so a background sync can never
# clobber a fresh pnpm write.
sync_mirror_one() {
  local src="$1" dst="$2" name push="$3" mode="${4:-watch}"
  name="$(basename "$dst")"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    warn "${dst} is a symlink; pnpm refuses to write symlinked lockfiles — converting to a regular file"
    rm -f "$dst"
    if [ -f "$src" ]; then
      cp "$src" "$dst"
      log "seeded ${name} from the repo"
    fi
    return 0
  fi

  if [ ! -f "$dst" ]; then
    if [ -f "$src" ]; then
      cp "$src" "$dst"
      log "seeded ${name} from the repo"
    else
      warn "missing ${name} on both sides"
    fi
    return 0
  fi

  if [ ! -f "$src" ]; then
    cp "$dst" "$src"
    log "adopted (first copy): ${name}"
    return 0
  fi

  if cmp -s "$src" "$dst"; then
    log "in sync: ${name}"
    return 0
  fi

  if [ "$push" = 1 ] && [ "$src" -nt "$dst" ]; then
    cp "$src" "$dst"
    log "pushed (repo newer): ${name}"
  elif [ "$src" -nt "$dst" ]; then
    log "repo copy of ${name} is newer; run 'link' to push it"
  else
    cp "$dst" "$src"
    log "adopted (live newer): ${name}"
  fi
}

sync_all() {
  local mode="$1" f
  mkdir -p "$TARGET_DIR"
  for f in $LINK_FILES; do
    sync_link_one "${SOURCE_DIR}/${f}" "${TARGET_DIR}/${f}"
  done
  for f in $MIRROR_FILES; do
    if [ "$mode" = link ]; then
      sync_mirror_one "${SOURCE_DIR}/${f}" "${TARGET_DIR}/${f}" 1 link
    else
      sync_mirror_one "${SOURCE_DIR}/${f}" "${TARGET_DIR}/${f}" 0 watch
    fi
  done
}

link() {
  local f
  [ -d "$SOURCE_DIR" ] || fail "repo config not found: ${SOURCE_DIR}"
  for f in $LINK_FILES $MIRROR_FILES; do
    [ -f "${SOURCE_DIR}/${f}" ] || fail "missing repo file: ${SOURCE_DIR}/${f}"
  done
  ( take_lock && sync_all link ) || return 1
}

restore() {
  ( take_lock && restore_inner ) || return 1
}

restore_inner() {
  local f src dst
  [ -d "$SOURCE_DIR" ] || fail "repo config not found: ${SOURCE_DIR}"
  mkdir -p "$TARGET_DIR"

  for f in $LINK_FILES; do
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

  for f in $MIRROR_FILES; do
    src="${SOURCE_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    [ -f "$src" ] || { warn "missing ${src}, skipped"; continue; }
    if [ -L "$dst" ]; then
      rm -f "$dst"
    elif [ -f "$dst" ]; then
      if cmp -s "$src" "$dst"; then
        log "already mirrored: ${f}"
        continue
      fi
      mv "$dst" "${dst}.bak.${TIMESTAMP}"
      log "backed up ${dst} -> ${dst}.bak.${TIMESTAMP}"
    fi
    cp "$src" "$dst"
    log "mirrored: ${dst}"
  done
}

status() {
  local f src dst rc=0
  for f in $LINK_FILES; do
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

  for f in $MIRROR_FILES; do
    src="${SOURCE_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    if [ -L "$dst" ]; then
      warn "${f} is a symlink — pnpm updates fail until 'link' converts it to a regular file"
      rc=1
    elif [ -f "$dst" ]; then
      if cmp -s "$src" "$dst" 2>/dev/null; then
        log "mirrored: ${f}"
      elif [ "$src" -nt "$dst" ]; then
        warn "${f} differs: repo copy is newer; 'link' pushes it"
        rc=1
      else
        log "${f} differs: live copy is newer; 'link' adopts it into the repo"
      fi
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
  local f dst src broken
  while :; do
    broken=0
    for f in $LINK_FILES; do
      dst="${TARGET_DIR}/${f}"
      if [ -L "$dst" ] && [ "$(readlink "$dst")" = "${SOURCE_DIR}/${f}" ]; then :; else broken=1; fi
    done
    for f in $MIRROR_FILES; do
      dst="${TARGET_DIR}/${f}"
      src="${SOURCE_DIR}/${f}"
      if [ -L "$dst" ] || [ ! -f "$dst" ]; then
        broken=1
      elif [ -f "$src" ] && ! cmp -s "$src" "$dst" && [ "$dst" -nt "$src" ]; then
        broken=1
      fi
    done
    if [ "$broken" = 1 ]; then
      printf '[dsh-sync] drift detected (link broken or lockfile rewritten), healing\n'
      ( take_lock 2>/dev/null && sync_all watch ) || true
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
