#!/usr/bin/env bash
# Rename the agent in the pane that was focused when this popup opened.
# Bound in config.toml under [[keys.command]].
set -uo pipefail

die() { printf '%s\n' "$*" >&2; read -r -p "Press Enter to close..." _ || true; exit 1; }

hosts_agent() {
  [ -n "${1:-}" ] || return 1
  herdr agent list | jq -e --arg p "$1" '.result.agents[] | select(.pane_id == $p)' >/dev/null 2>&1
}

snapshot=$(herdr api snapshot) || die "cannot reach herdr server"
focused_pane=$(printf '%s' "$snapshot" | jq -r '.result.snapshot.focused_pane_id // empty')
focused_tab=$(printf '%s' "$snapshot" | jq -r '.result.snapshot.focused_tab_id // empty')

# Resolution order: inherited caller context, UI-focused pane, sole agent in focused tab.
target=""
for cand in "${HERDR_PANE_ID:-}" "$focused_pane"; do
  if hosts_agent "$cand"; then target=$cand; break; fi
done

if [ -z "$target" ] && [ -n "$focused_tab" ]; then
  mapfile -t in_tab < <(herdr agent list |
    jq -r --arg t "$focused_tab" '.result.agents[] | select(.tab_id == $t) | .pane_id')
  case ${#in_tab[@]} in
    1) target=${in_tab[0]} ;;
    0) die "no agent found in focused tab $focused_tab" ;;
    *) die "focused tab $focused_tab hosts ${#in_tab[@]} agents; rename by pane id instead: ${in_tab[*]}" ;;
  esac
fi

[ -n "$target" ] || die "could not resolve a pane hosting an agent"

info=$(herdr agent list | jq -r --arg p "$target" \
  '.result.agents[] | select(.pane_id == $p) | "\(.agent)  \(.agent_status)  \(.cwd)"')
printf 'Renaming agent in pane %s\n  %s\n\n' "$target" "$info"

read -r -p "New name (a-z0-9_- , empty to clear): " name || exit 1

if [ -z "$name" ]; then
  herdr agent rename "$target" --clear >/dev/null || die "clear failed"
  printf 'Cleared name for %s\n' "$target"
else
  [[ $name =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || die "invalid name: must match [a-z][a-z0-9_-]{0,31}"
  out=$(herdr agent rename "$target" "$name" 2>&1) || die "rename failed: $out"
  printf 'Renamed %s -> %s\n' "$target" "$name"
fi

sleep 1
read -r -p "Press Enter to close..." _ || true
