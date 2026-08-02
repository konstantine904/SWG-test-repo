# SWG Legends structure client assets — Core3 port assessment

## Collected client templates

`extracted/` contains 92 original IFF files recovered from `swgsource_3.0.tre`:

- 41 player-house deeds;
- 37 player-house and merchant-tent building templates;
- 14 TCG structure deeds.

They are client-side assets only.  They are not mounted into the Project Kamino
client, copied into the server, or registered in Core3.

## Already represented by Core3

Core3 already has server Lua templates and structure deeds for the standard
Corellian, Generic, Naboo, and Tatooine houses; all three merchant tents;
Jabba's Sail Barge; YT-1300; Bespin House; Jedi and Sith Meditation Rooms; and
the VIP Bunker.  These do not need a new port.  The extracted assets serve as
the verified client-side counterpart for their existing Core3 definitions.

## Port candidates requiring new Core3 definitions

| Client structure | Client building template | Client deed | Core3 work still required |
| --- | --- | --- | --- |
| Nightsister Hut | `player_house_wod_ns_hut` | `wod_ns_hut*_deed` | Building Lua, deed Lua, loader registration, placement terminal/sign coordinates, and reward/vendor source. |
| Singing Mountain Hut | `player_house_wod_sm_hut` | `wod_sm_hut*_deed` | Same as Nightsister Hut. |
| Kashyyyk Tree House 1/2 | `player_house_tree_house_01/02` | `tree_house_01/02_deed` | Building/deed Lua plus precise terminal, sign, and placement data. |
| Yoda's Dagobah Hut | `player_house_tcg_8_yoda_house` | `player_house_tcg_8_yoda_house` | Building/deed Lua plus TCG/reward source. |
| Mustafarian Large House | `player_house_mustafar_lg` | `mustafar_house_lg` | Building/deed Lua plus placement and maintenance data. |
| AT-AT House | not present in this archive's player-building set | `structure_deed_player_house_atat` | The appearance/cell template is not available in this archive; cannot safely create a player house from this deed alone. |
| Starship Hangar | not present in this archive's player-building set | `structure_deed_player_house_hangar` | Same missing building/cell template issue. |
| Emperor's / Rebel Spire | not present in this archive's player-building set | respective Series 6 deeds | Appearance/cell templates and server definitions are absent. |
| Commando Bunker / Vehicle Garage / Relaxation Pool | not present in this archive's player-building set | respective TCG deeds | Appearance/cell templates and server definitions are absent. |
| Barn / Diner | not present in this archive's player-building set | Series 1/2 deeds | Need the matching building/cell templates and server definitions. |

## Reverse-engineering conclusion

Core3 requires more than a client deed: a placeable building template, child
terminal and sign coordinates, lot/maintenance/planet rules, and a registered
Lua loader entry.  The archive provides the complete client building + deed
pair for the first five rows above, so those are suitable for a separate draft
port after their terminal/cell metadata is recovered from a compatible Core3
server source.  The remaining rows have only deed assets here; activating them
would create incomplete or broken structures, so they are deliberately held
out of the port.

## Extraction reproducibility

`tools/extract_tre_entries.cpp` is a read-only EERT5000 TRE extractor written
for this review.  It preserves original bytes and creates the source path below
`extracted/`.  It does not alter the source TRE archive.
