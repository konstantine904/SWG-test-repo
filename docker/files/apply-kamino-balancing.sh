#!/bin/bash

set -e

core3_scripts="${HOME_DIR}/workspace/Core3/MMOCoreORB/bin/scripts"
saber_root="${core3_scripts}/object/weapon/melee"
core3_config="${HOME_DIR}/workspace/Core3/MMOCoreORB/bin/conf/config.lua"

# Reversible Republic Gunship forge test. The server must load the same test
# TRE as the client so it can resolve the shared deed, PCD, and vehicle IFFs.
if ! grep -Fq 'project_kamino_gunship_forge_test.tre' "${core3_config}"; then
    sed -i '/TreFiles = {/a\    "project_kamino_gunship_forge_test.tre",' "${core3_config}"
fi

# Keep the AV-21's client movement prediction identical to its server override.
if ! grep -Fq 'project_kamino_av21_speed.tre' "${core3_config}"; then
    sed -i '/TreFiles = {/a\    "project_kamino_av21_speed.tre",' "${core3_config}"
fi

# AOTC's generated saber templates point each generation at a container that is
# two sizes too small.  A color crystal occupies one slot, leaving the remaining
# slots for power crystals or pearls.
for generation in 1 2 3 4; do
    inventory="lightsaber_inventory_${generation}.iff"

    find "${saber_root}" -type f -path '*/crafted_saber/*.lua' -name "*gen${generation}*.lua" -print0 |
        while IFS= read -r -d '' saber_template; do
            sed -E -i \
                "s/lightsaber_inventory_(training|[1-4])\\.iff/${inventory}/g" \
                "${saber_template}"
        done
done

# Lightsaber damage should use Heavy armor penetration across every saber
# template, including crafted hilts, NPC sabers, and AOTC custom variants.
find "${core3_scripts}/object/weapon" -type f -name '*.lua' -print0 |
    while IFS= read -r -d '' weapon_template; do
        if grep -q 'damageType = LIGHTSABER' "${weapon_template}"; then
            sed -E -i 's/armorPiercing = (NONE|LIGHT|MEDIUM),/armorPiercing = HEAVY,/' \
                "${weapon_template}"
        fi
    done

# Keep the Blue Frog's complete doctor/entertainer enhancement active for
# three hours. The stock configuration already permits two characters from
# one account to be online simultaneously.
player_manager="${core3_scripts}/managers/player_manager.lua"
sed -E -i \
    -e 's/^performanceDuration = [0-9]+(.*)$/performanceDuration = 10800 -- in seconds/' \
    -e 's/^medicalDuration = [0-9]+(.*)$/medicalDuration = 10800 -- in seconds/' \
    -e 's/^baseStoredVehicles = [0-9]+(.*)$/baseStoredVehicles = 80 -- vehicles per character/' \
    "${player_manager}"
