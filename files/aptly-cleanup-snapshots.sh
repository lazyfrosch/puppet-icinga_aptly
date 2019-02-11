#!/bin/bash

set -euo pipefail

if [ "$(id -un)" != aptly ]; then
  echo "Executing command via sudo: $0"
  exec sudo -u aptly "$0" "$@"
fi

log() {
  if [ $# -ge 2 ]; then
    level="$2"
  else
    level=info
  fi
  logger -p "local3.${level}" -t "aptly-cleanup-snapshots" -- "$1"
  echo "[${level}] $1"
}

stderr="$(mktemp -t aptly-cleanup.XXXXXX)"
trap 'rm -f "$stderr"' INT TERM

log "Starting cleanup"

repos=()
while read -r repo; do
  repos+=("$repo")
done < <(aptly repo list --raw=true)

for repo in "${repos[@]}"; do
  case "$repo" in
    *-release)
      continue
      ;;
  esac

  log "Cleaning up repository $repo"

  dup=false
  pkg_old=
  for p in $(aptly repo search "$repo" "Architecture" | sort -V); do
    #pkg=$(echo "$p" | sed 's,_.*,,')
    pkg="${p/_*/}"
    if [ "$pkg" = "$pkg_old" ]; then
        dup=true
    elif $dup; then
        dup=false
        # $p_old is latest version of some package with more than one version
        # Output a search spec for all versions older than this
        # Version is 2nd field in output of aptly repo search, separated by _
        v_old=$(echo "$p_old" | cut -d_ -f2)
        echo "Removing package in $repo: $pkg_old (<< $v_old)"
        if ! aptly repo remove "$repo" "$pkg_old (<< $v_old)" 2>"$stderr"; then
          log "aptly repo remove $repo $pkg_old (<< $v_old) failed:" "error"
          log "$(cat "$stderr")" "error"
        fi
    fi
    p_old="$p"
    pkg_old="$pkg"
  done
  if $dup; then
    # Otherwise duplicates of the last package will not be cleaned up
    v_old=$(echo "$p_old" | cut -d_ -f2)
    echo "Removing package in $repo: $pkg_old (<< $v_old)"
    if ! aptly repo remove "$repo" "$pkg_old (<< $v_old)" 2>"$stderr"; then
      log "aptly repo remove $repo $pkg_old (<< $v_old) failed:" "error"
      log "$(cat "$stderr")" "error"
    fi
  fi
done

published=()
while read -r repo; do
  published+=("$repo")
done < <(aptly publish list --raw=true)

for publish in "${published[@]}"; do
  os="$(echo "$publish" | cut -d' ' -f1)"
  repo="$(echo "$publish" | cut -d' ' -f2)"

  case "$repo" in
    *-giraffe)
      ;;
    *-snapshots)
      ;;
    *)
      continue
      ;;
  esac

  log "Publishing repository $os/$repo"
  if ! aptly publish update "$repo" "$os" 2>"$stderr"; then
    log "Could not update publish: $publish $(cat "$stderr")" "error"
  fi
done

log "Running DB cleanup..."
aptly db cleanup || log "DB cleanup failed!" "error"

log "Cleanup finished..."
rm -f "$stderr"
