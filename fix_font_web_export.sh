#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_SCRIPT="$PROJECT_ROOT/scripts/campus_decor.gd"
PRESETS="$PROJECT_ROOT/export_presets.cfg"

echo "== MasseySim Web Font Fix =="
echo

# ------------------------------------------------------------
# 1. Sanity checks
# ------------------------------------------------------------

if [[ ! -f "$FONT_SCRIPT" ]]; then
    echo "ERROR: $FONT_SCRIPT not found."
    exit 1
fi

if [[ ! -f "$PRESETS" ]]; then
    echo "ERROR: $PRESETS not found."
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/assets/fonts/WorkSans.ttf" ]]; then
    echo "ERROR: WorkSans.ttf not found."
    exit 1
fi

if [[ ! -f "$PROJECT_ROOT/assets/fonts/Fraunces.ttf" ]]; then
    echo "ERROR: Fraunces.ttf not found."
    exit 1
fi

echo "[1/5] Font files found:"
ls -lh \
    "$PROJECT_ROOT/assets/fonts/WorkSans.ttf" \
    "$PROJECT_ROOT/assets/fonts/Fraunces.ttf"
echo

# ------------------------------------------------------------
# 2. Backup
# ------------------------------------------------------------

BACKUP="$FONT_SCRIPT.bak.$(date +%Y%m%d-%H%M%S)"
cp "$FONT_SCRIPT" "$BACKUP"

echo "[2/5] Backup created:"
echo "       $BACKUP"
echo

# ------------------------------------------------------------
# 3. Replace _ensure_fonts()
# ------------------------------------------------------------

python3 - "$FONT_SCRIPT" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

pattern = re.compile(
    r'''(?ms)^    static func _ensure_fonts\(\) -> void:\n'''
    r'''    .*?(?=^    ## |\Z)'''
)

replacement = '''    static func _ensure_fonts() -> void:
        if _body_font != null:
                return
        _body_font = load("res://assets/fonts/WorkSans.ttf") as FontFile
        _display_font = load("res://assets/fonts/Fraunces.ttf") as FontFile

'''

match = pattern.search(text)

if not match:
    print("ERROR: Could not locate _ensure_fonts() in campus_decor.gd")
    sys.exit(1)

old = match.group(0)
new = replacement

text = text[:match.start()] + new + text[match.end():]
path.write_text(text)

print("Replaced _ensure_fonts().")
print()
print("Old:")
print(old)
print("New:")
print(new)
PY

echo

# ------------------------------------------------------------
# 4. Check export preset
# ------------------------------------------------------------

echo "[3/5] Web export preset:"
grep -A20 'name="Web"' "$PRESETS" || true
echo

# We deliberately leave include_filter empty.
# export_filter="all_resources" is already enabled.
if grep -q 'include_filter="assets/fonts/' "$PRESETS"; then
    echo "[4/5] Removing old font include_filter workaround..."

    python3 - "$PRESETS" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

text = text.replace(
    'include_filter="assets/fonts/*.ttf"',
    'include_filter=""'
)

path.write_text(text)
PY

    echo "      Done."
else
    echo "[4/5] No font include_filter workaround found."
    echo "      Leaving include_filter as-is."
fi

echo

# ------------------------------------------------------------
# 5. Show final state
# ------------------------------------------------------------

echo "[5/5] Final _ensure_fonts():"
nl -ba "$FONT_SCRIPT" | sed -n '20,35p'
echo

echo "Final Web preset:"
grep -A20 'name="Web"' "$PRESETS"
echo

echo "Git diff:"
git diff -- "$FONT_SCRIPT" "$PRESETS" || true
echo

echo "========================================"
echo "FIX APPLIED"
echo "========================================"
echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "The fonts now load through Godot's resource system:"
echo '  load("res://assets/fonts/WorkSans.ttf")'
echo '  load("res://assets/fonts/Fraunces.ttf")'
echo
echo "No Web export has been performed yet."
echo
echo "Next:"
echo "  1. Run the game in Godot/editor and verify fonts."
echo "  2. Export the Web preset."
echo "  3. Zip builds/web/."
echo
