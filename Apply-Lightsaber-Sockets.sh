#!/usr/bin/env bash
set -euo pipefail

root=/home/swgemu/workspace/Core3/MMOCoreORB/bin/scripts/object/weapon/melee

# The AOTC client inventories have the requested capacities:
# inventory_1 = 2, inventory_2 = 3, inventory_3 = 4, inventory_4 = 5.
for generation in 1 2 3 4; do
  while IFS= read -r -d '' template; do
    sed -Ei "s@object/tangible/inventory/lightsaber_inventory_(training|[1-4])\.iff@object/tangible/inventory/lightsaber_inventory_${generation}.iff@g" "$template"
  done < <(find "$root" -type f -path '*crafted_saber*' -name "*lightsaber*gen${generation}*.lua" -print0)
done

for generation in 1 2 3 4; do
  total=$(find "$root" -type f -path '*crafted_saber*' -name "*lightsaber*gen${generation}*.lua" | wc -l)
  matched=$(find "$root" -type f -path '*crafted_saber*' -name "*lightsaber*gen${generation}*.lua" -exec grep -l "lightsaber_inventory_${generation}.iff" {} + | wc -l)
  echo "Generation ${generation}: ${matched}/${total} templates use lightsaber_inventory_${generation}.iff"
  test "$total" -gt 0
  test "$matched" -eq "$total"
done
