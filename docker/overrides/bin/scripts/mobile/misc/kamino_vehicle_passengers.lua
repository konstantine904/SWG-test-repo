-- Passenger-seat creature templates. The names are consumed by
-- VehicleObjectImplementation::slotPassenger().  Use the AV-21 seat proxy
-- that is already supplied by the AOTC client; bespoke passenger IFFs for
-- these three imports do not exist in its TRE archives.  The vehicle's rider
-- slots provide the actual positions and keep each passenger attached to it.
local passengerSeatTemplate = "object/mobile/passenger_av21.iff"

local function addPassengerSeats(prefix, objectTemplate, count)
	for seat = 1, count do
		local passenger = Creature:new {
			customName = "Passenger Seat",
			mobType = MOB_NPC,
			level = 1,
			pvpBitmask = NONE,
			creatureBitmask = NONE,
			optionsBitmask = INVULNERABLE,
			diet = HERBIVORE,
		templates = { string.format(objectTemplate, seat) },
			lootGroups = {},
			weapons = {},
			conversationTemplate = "",
			attacks = {}
		}
		CreatureTemplates:addCreatureTemplate(passenger, "passenger_" .. prefix .. "_" .. seat)
	end
end

addPassengerSeats("senate_pod", passengerSeatTemplate, 3)
addPassengerSeats("landspeeder_desert_skiff", passengerSeatTemplate, 8)

-- The Gunship uses its own named passenger template family.  Do not replace
-- this with an AV-21 template: the Gunship seat transforms are handled by the
-- server's Gunship-specific branch.
for seat = 1, 6 do
	local passenger = Creature:new {
		customName = "Republic Gunship Passenger Seat",
		mobType = MOB_NPC,
		level = 1,
		pvpBitmask = NONE,
		creatureBitmask = NONE,
		optionsBitmask = INVULNERABLE,
		diet = HERBIVORE,
		templates = { "object/mobile/passenger_tcg_republic_gunship_" .. seat .. ".iff" },
		lootGroups = {},
		weapons = {},
		conversationTemplate = "",
		attacks = {}
	}
	CreatureTemplates:addCreatureTemplate(passenger, "passenger_tcg_republic_gunship_" .. seat)
end
