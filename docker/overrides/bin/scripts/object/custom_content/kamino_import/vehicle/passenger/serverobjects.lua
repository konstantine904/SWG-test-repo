-- Passenger-seat objects for Project Kamino multi-passenger vehicles.
-- Dedicated Republic Gunship passenger-template family.  These need explicit
-- object registrations: dynamically-created Lua tables do not receive a
-- stable Core3 template CRC and cannot be spawned by VehicleObject.
-- The Gunship's position data is supplied by VehicleObjectImplementation;
-- this is only the neutral passenger-seat creature schema, never AV-21 data.
object_mobile_passenger_tcg_republic_gunship_1 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_1, "object/mobile/passenger_tcg_republic_gunship_1.iff")
object_mobile_passenger_tcg_republic_gunship_2 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_2, "object/mobile/passenger_tcg_republic_gunship_2.iff")
object_mobile_passenger_tcg_republic_gunship_3 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_3, "object/mobile/passenger_tcg_republic_gunship_3.iff")
object_mobile_passenger_tcg_republic_gunship_4 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_4, "object/mobile/passenger_tcg_republic_gunship_4.iff")
object_mobile_passenger_tcg_republic_gunship_5 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_5, "object/mobile/passenger_tcg_republic_gunship_5.iff")
object_mobile_passenger_tcg_republic_gunship_6 = object_mobile_passenger_lava_skiff:new {}
ObjectTemplates:addTemplate(object_mobile_passenger_tcg_republic_gunship_6, "object/mobile/passenger_tcg_republic_gunship_6.iff")
object_mobile_passenger_senate_pod = object_mobile_shared_passenger_av21:new {
}
ObjectTemplates:addTemplate(object_mobile_passenger_senate_pod, "object/mobile/passenger_senate_pod.iff")

object_mobile_passenger_landspeeder_desert_skiff = object_mobile_shared_passenger_av21:new {
}
ObjectTemplates:addTemplate(object_mobile_passenger_landspeeder_desert_skiff, "object/mobile/passenger_landspeeder_desert_skiff.iff")
