# SWG-Source Republic Gunship client package

This branch deliberately does **not** store the multi-gigabyte SWG-Source
client release. It stores the NGECore2 source reference needed for the Core3
port and records the locally staged original gunship client assets.

## Source repositories

* `ProjectSWGCore/NGECore2` — reward, PCD, vehicle, and Series 7 combine flow.
* `SWG-Source/dsrc` — authoritative object-template source definitions.
* `SWG-Source/clientdata_OLD` — original gunship visual assets.
* `SWG-Source/swg-main` — original client template/TRE build tooling.

## Verified visual assets

* `appearance/pv_republic_gunship.sat`
* `appearance/republic_gunship.apt`
* `appearance/republic_gunship.ssa`
* `appearance/republic_gunship_itv.apt`
* `appearance/republic_gunship_static.apt`
* `appearance/skeleton/pv_republic_gunship.skt`
* `appearance/mesh/pv_republic_gunship.mgn`
* `appearance/mesh/republic_gunship_*.msh`
* `appearance/lod/republic_gunship.lod`
* `clientdata/vehicle/tcg_republic_gunship.cdf`

`appearance/lod/republic_gunship.lod` includes the original named passenger
anchors `passenger_1` through `passenger_10`. The Core3 implementation uses
seven passenger slots plus the driver.

## Still required for the final client TRE

The client package must include compiled IFFs generated or extracted from the
authoritative definitions:

* Series 7 gunship reward/deed template
* gunship PCD template
* gunship vehicle template
* passenger-seat templates

These outputs are kept out of Git because they belong in a locally installed
client TRE, not in the server-source repository.
