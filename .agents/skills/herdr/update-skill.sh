#!/usr/bin/env bash
#
# Refresh the global "herdr" agent skill from the upstream source of truth.
#
# Run this after `herdr update` (or whenever you want the latest skill):
#     ~/.agents/skills/herdr/update-skill.sh
#
# It is safe to run repeatedly: it only rewrites SKILL.md when the upstream
# content has actually changed, and it keeps a .bak of the previous version.

set -euo pipefail

SKILL_DIR="${HOME}/.agents/skills/herdr"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
SRC_URL="https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching herdr SKILL.md from upstream..."
if ! curl -fsSL --max-time 30 "$SRC_URL" -o "$TMP"; then
  echo "ERROR: download failed; skill left unchanged." >&2
  exit 1
fi

# Guard against fetching an error page or an unrelated file: it must be the
# herdr skill with YAML frontmatter. This prevents clobbering a good skill
# with garbage if the URL ever moves or returns HTML.
if ! head -1 "$TMP" | grep -q '^---'; then
  echo "ERROR: upstream file has no YAML frontmatter; aborting." >&2
  exit 1
fi
if ! grep -q '^name:[[:space:]]*herdr' "$TMP"; then
  echo "ERROR: upstream file is not the herdr skill (name mismatch); aborting." >&2
  exit 1
fi

# Re-inject a local metadata block so the installed copy records where it came
# from. Upstream ships only name + description; we add provenance without
# touching the body or the description.
python3 - "$TMP" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path).read()
m = re.match(r'^---\n(.*?)\n---\n(.*)$', text, re.S)
if not m:
    sys.exit("frontmatter parse failed")
fm, body = m.group(1), m.group(2)
# Drop any pre-existing metadata block, then append our own.
fm = re.sub(r'\nmetadata:\n(?:[ \t]+.*\n?)*', '\n', fm).rstrip('\n')
meta = (
    "\nmetadata:\n"
    "  author: herdr (ogulcancelik)\n"
    "  source: https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md\n"
    "  docs: https://herdr.dev/docs/\n"
)
open(path, "w").write(f"---\n{fm}{meta}---\n{body}")
PY

if [ -f "$SKILL_FILE" ] && cmp -s "$TMP" "$SKILL_FILE"; then
  echo "Already up to date: $SKILL_FILE"
  exit 0
fi

mkdir -p "$SKILL_DIR"
if [ -f "$SKILL_FILE" ]; then
  cp "$SKILL_FILE" "${SKILL_FILE}.bak"
  echo "Backed up previous version -> ${SKILL_FILE}.bak"
fi
cp "$TMP" "$SKILL_FILE"
echo "Updated: $SKILL_FILE"
