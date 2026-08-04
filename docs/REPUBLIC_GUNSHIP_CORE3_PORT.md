# Republic Gunship: NGECore2 to Core3 port

## NGECore2 behavior

NGECore2 does not implement custom vehicle movement or placement. Its two
runtime hooks assign the normal vehicle PCD and vehicle radial menus:

* `tcg_republic_gunship_pcd.py` -> `datapad/vehicle_pcd`
* `tcg_republic_gunship.py` -> `creature/vehicle`

The item is awarded through the Series 7 TCG combine flow and is then handled
as a normal vehicle control device.

## Core3 equivalent

Core3 maps that behavior to the standard `VEHICLEDEED` flow:

1. The Series 7 combine reward object inherits the authentic shared
   `combine_reward_deed_republic_gunship` template.
2. Its server Lua specifies `templateType = VEHICLEDEED`, the gunship PCD
   path, and the gunship mobile-object path.
3. The PCD inherits the authentic shared gunship PCD template.
4. The mobile object inherits the authentic shared gunship vehicle template.
5. Seven passenger creatures are registered under the
   `tcg_republic_gunship` seat prefix, and the mobile object specifies
   `passengerCapacity = 7` and `passengerSeatString = "tcg_republic_gunship"`.

## Required client package before activation

The following original client paths must exist in a loaded client TRE. Do not
activate the Core3 port against substitute AV-21 templates.

* `object/tangible/tcg/series7/shared_combine_reward_deed_republic_gunship.iff`
* `object/intangible/vehicle/shared_tcg_republic_gunship_pcd.iff`
* `object/mobile/vehicle/shared_tcg_republic_gunship.iff`
* `appearance/republic_gunship.apt`
* `appearance/pv_republic_gunship.sat`
* `object/mobile/shared_passenger_tcg_republic_gunship_1.iff` through `_7.iff`

## Deliberate exclusions

No copied `VehicleObjectImplementation` or mount-command modifications are
part of the port. Those changes caused the earlier rubber-banding and seat
placement failures. The port uses Core3's normal vehicle behavior plus the
validated passenger registration pattern.
