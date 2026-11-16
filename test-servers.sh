#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: test-servers <preflight|quick|full>

Environment:
  MCSTART_SERVER_ROOT  Server root (default: $HOME/mc-srvrs)
  MCSTART_BIN           mcstart executable (default: mcstart)
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

java_group() {
  local version=${1##*/}
  local major minor point

  major=$(printf '%s' "$version" | cut -d. -f1)
  minor=$(printf '%s' "$version" | cut -d. -f2)
  point=$(printf '%s' "$version" | cut -d. -f3)

  if [[ ! "$major" =~ ^[0-9]+$ ]] || [[ ! "$minor" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  point=${point:-0}
  [[ "$point" =~ ^[0-9]+$ ]] || point=0

  if ((minor < 17)); then
    echo 8
  elif ((minor == 20 && point >= 4)) || ((minor >= 21)); then
    echo 21
  else
    echo 17
  fi
}

count_family_sessions() {
  local family=$1
  local count=0
  local prefix="MCServer_${family}-"

  while IFS= read -r session; do
    [[ "$session" == "$prefix"* ]] || continue
    count=$((count + 1))
  done < <(tmux list-sessions -F '#S' 2>/dev/null || true)
  echo "$count"
}

session_name() {
  local family=$1
  local world=$2
  local path="$MCSTART_SERVER_ROOT/$family/$world"

  if [[ -L "$path" || -d "$path" ]]; then
    world=$(basename "$(readlink -f "$path")")
  fi

  printf 'MCServer_%s-%s' "$family" "$world" | tr -c '[:alnum:]_-' '_'
}

cleanup_created_sessions() {
  local session

  if ((${#created_sessions[@]})); then
    for session in "${created_sessions[@]}"; do
      if tmux has-session -t "=$session" 2>/dev/null; then
        tmux kill-session -t "=$session"
      fi
    done
  fi
  created_sessions=()
}

launch() {
  local family=$1
  local world=$2
  local session
  local count
  local status=0
  local output

  output=$(MC_MEM_MIN=256M MC_MEM_MAX=512M "$MCSTART_BIN" "$family" "$world" 2>&1) || status=$?
  session=$(session_name "$family" "$world")

  if tmux has-session -t "=$session" 2>/dev/null; then
    created_sessions+=("$session")
  fi

  if ((status == 0)); then
    count=$(count_family_sessions "$family")
    if ((count == 0)); then
      printf 'FAIL: %-10s %-22s created no active session\n' "$family" "$world"
      FAILED=1
    elif ((count > MAX_CONCURRENT_SESSIONS)); then
      printf 'FAIL: %-10s %-22s exceeded %s sessions\n' \
        "$family" "$world" "$MAX_CONCURRENT_SESSIONS"
      FAILED=1
    else
      printf 'PASS: %-10s %-22s sessions=%s\n' \
      "$family" "$world" "$count"
    SUCCESSFUL_LAUNCHES=$((SUCCESSFUL_LAUNCHES + 1))
    fi
  else
    printf 'FAIL: %-10s %-22s\n%s\n' "$family" "$world" "$output"
    FAILED=1
  fi
}

mode=${1:-}
MCSTART_BIN=${MCSTART_BIN:-mcstart}
MCSTART_SERVER_ROOT=${MCSTART_SERVER_ROOT:-$HOME/mc-srvrs}

[[ "$mode" == "preflight" || "$mode" == "quick" || "$mode" == "full" ]] || { usage; exit 2; }

if [[ "$mode" == "preflight" ]]; then
  for java in \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java \
    /usr/lib/jvm/java-17-openjdk-amd64/bin/java \
    /usr/lib/jvm/java-21-openjdk-amd64/bin/java; do
    [[ -x "$java" ]] || fail "missing required Java executable: $java"
    printf 'Java: %s\n' "$("$java" -version 2>&1 | head -1)"
  done

  printf 'mcstart: %s\nserver root: %s\n' "$MCSTART_BIN" "$MCSTART_SERVER_ROOT"
  find "$MCSTART_SERVER_ROOT" -mindepth 1 -maxdepth 1 -type d -printf 'family: %f\n' | sort
  exit 0
fi
[[ $# -eq 1 ]] || { usage; exit 2; }
[[ $(id -u) -ne 0 ]] || fail "run as a non-root user"
command -v tmux >/dev/null 2>&1 || fail "tmux is required"
command -v "$MCSTART_BIN" >/dev/null 2>&1 || fail "mcstart is not on PATH"
[[ -d "$MCSTART_SERVER_ROOT" ]] || fail "server root not found: $MCSTART_SERVER_ROOT"

FAILED=0
MAX_CONCURRENT_SESSIONS=2
SUCCESSFUL_LAUNCHES=0
LAUNCH_ATTEMPTS=0
FAMILIES_TESTED=0
created_sessions=()

for family_path in "$MCSTART_SERVER_ROOT"/*/; do
  family=$(basename "$family_path")

  if [[ "$mode" == "quick" ]]; then
    world_count=0
    for world_path in "$family_path"*; do
      [[ -L "$world_path" ]] || continue
      world=$(basename "$world_path")
      [[ "$world" == "current" ]] || continue
      LAUNCH_ATTEMPTS=$((LAUNCH_ATTEMPTS + 1))
      launch "$family" "$world"
      world_count=$((world_count + 1))
    done

    if ((world_count == 0)); then
      printf 'SKIP: %-10s no symlinked worlds\n' "$family"
    else
      FAMILIES_TESTED=$((FAMILIES_TESTED + 1))
      cleanup_created_sessions
    fi
  else
    declare -A first_by_group=()
    groups_present=()
    for group in 8 17 21; do
      for version_path in "$family_path"*/; do
        [[ ! -L "$version_path" && -d "$version_path" ]] || continue
        version=$(basename "$version_path")
        if java_group "$version" >/dev/null 2>&1; then
          if [[ "$(java_group "$version")" == "$group" && -z "${first_by_group[$group]:-}" ]]; then
            first_by_group[$group]=$version
            groups_present+=("$group")
            break
          fi
        fi
      done
    done

    group_count=${#first_by_group[@]}
    if ((group_count == 0)); then
      printf 'SKIP: %-10s no parseable Minecraft versions\n' "$family"
      continue
    fi

    candidates=()
    if ((group_count >= 2)); then
      first_group=${groups_present[0]}
      last_group=${groups_present[group_count - 1]}
      candidates=("${first_by_group[$first_group]}" "${first_by_group[$last_group]}")
    else
      only_group=${groups_present[0]}
      first_version=${first_by_group[$only_group]}
      candidates=("$first_version")
      second_found=0
      for version_path in "$family_path"*/; do
        [[ ! -L "$version_path" && -d "$version_path" ]] || continue
        version=$(basename "$version_path")
        [[ "$version" == "$first_version" ]] && continue
        if java_group "$version" >/dev/null 2>&1; then
          if [[ "$(java_group "$version")" == "$only_group" ]]; then
            candidates+=("$version")
            second_found=1
            break
          fi
        fi
      done
      ((second_found == 1)) || printf 'NOTE: %-10s has only one %s-compatible version\n' \
        "$family" "$only_group"
    fi

    for version in "${candidates[@]}"; do
      LAUNCH_ATTEMPTS=$((LAUNCH_ATTEMPTS + 1))
      launch "$family" "$version"
    done

    family_sessions=$(count_family_sessions "$family")
    if ((family_sessions < ${#candidates[@]})) || ((family_sessions > MAX_CONCURRENT_SESSIONS)); then
      printf 'FAIL: %-10s expected %s sessions, found %s\n' \
        "$family" "${#candidates[@]}" "$family_sessions" >&2
      FAILED=1
    else
      FAMILIES_TESTED=$((FAMILIES_TESTED + 1))
    fi

    cleanup_created_sessions
    unset first_by_group groups_present first_group last_group only_group first_version candidates second_found
  fi
done

cleanup_created_sessions

printf '\nFamilies tested:       %s\nLaunch attempts:        %s\nSuccessful launches:    %s\nMaximum concurrency:    %s per family\n' \
  "$FAMILIES_TESTED" "$LAUNCH_ATTEMPTS" "$SUCCESSFUL_LAUNCHES" "$MAX_CONCURRENT_SESSIONS"
printf 'Remaining test sessions: %s\n' \
  "$(tmux list-sessions -F '#S' 2>/dev/null | grep -c '^MCServer_' || true)"

exit "$FAILED"
