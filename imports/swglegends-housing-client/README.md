# SWG Legends client-side housing staging package

This package is an archival, non-active compatibility reference for future
Core3 housing ports.  It was extracted from the public SWGLegends client
archive, and contains the original client IFF templates for player houses,
house deeds, and relevant TCG structure deeds.

Nothing in this folder is mounted into Docker, copied into the live client, or
loaded by Core3.  A structure should only be enabled after its Core3 building
Lua template, deed Lua template, loader registration, and placement metadata
have been implemented and tested together.

## Contents

- `extracted/object/building/player/` — player-house and merchant-tent client
  templates.
- `extracted/object/tangible/deed/player_house_deed/` — player-house deed
  templates.
- `extracted/object/tangible/tcg/` — relevant TCG structure deed templates.
- `CORE3-STRUCTURE-PORT.md` — compatibility and port-readiness assessment.
- `tools/extract_tre_entries.cpp` — read-only extraction utility used to
  preserve the original IFF entries from `swgsource_3.0.tre`.

## Port readiness

Core3 already supports the conventional housing families and several special
homes.  The staged port candidates are the Nightsister Hut, Singing Mountain
Hut, both Kashyyyk Tree Houses, Yoda's Hut, and the Mustafarian Large House.
The remaining special deed-only entries deliberately remain inactive because
the necessary building/cell templates are not present in this client archive.
