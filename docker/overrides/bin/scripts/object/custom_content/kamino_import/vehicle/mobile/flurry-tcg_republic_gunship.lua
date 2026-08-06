
object_mobile_vehicle_tcg_republic_gunship = object_mobile_vehicle_shared_tcg_republic_gunship:new {
	templateType = VEHICLE,
	-- Dedicated Republic Gunship passenger template family. No AV-21 template
	-- or rider placement is used by this vehicle.
	passengerCapacity = 6,
	passengerSeatString = "tcg_republic_gunship",
	decayRate = 15, -- Damage tick per decay cycle
	decayCycle = 600 -- Time in seconds per cycle
}
ObjectTemplates:addTemplate(object_mobile_vehicle_tcg_republic_gunship, "object/mobile/vehicle/tcg_republic_gunship.iff")
