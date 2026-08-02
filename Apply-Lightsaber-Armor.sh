#!/usr/bin/env bash
set -euo pipefail

root=/home/swgemu/workspace/Core3/MMOCoreORB/bin/scripts/object/weapon/melee

while IFS= read -r template; do
  sed -Ei 's/armorPiercing[[:space:]]*=[[:space:]]*MEDIUM/armorPiercing = HEAVY/g' "$template"
done < <(grep -RIl 'armorPiercing = MEDIUM' "$root" 2>/dev/null | grep lightsaber || true)

remaining=$(grep -RIl 'armorPiercing = MEDIUM' "$root" 2>/dev/null | grep lightsaber | wc -l || true)
heavy=$(grep -RIl 'armorPiercing = HEAVY' "$root" 2>/dev/null | grep lightsaber | wc -l || true)

echo "Lightsaber templates set to Heavy: $heavy"
test "$remaining" -eq 0
