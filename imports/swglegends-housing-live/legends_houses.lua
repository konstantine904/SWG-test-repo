local houseRules = {
	baseMaintenanceRate = 16,
	allowedZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine"},
	publicStructure = 0,
	skillMods = {{"private_medical_rating", 100}, {"private_buff_mind", 100}, {"private_med_battle_fatigue", 5}, {"private_safe_logout", 1}},
	childObjects = {
		{templateFile = "object/tangible/sign/player/house_address.iff", x = 0, z = 1, y = 0, ox = 0, oy = 0, oz = 0, ow = 1, cellid = -1, containmentType = -1},
		{templateFile = "object/tangible/terminal/terminal_player_structure.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 1, cellid = 1, containmentType = -1},
	},
	length = 4,
	width = 4,
}

local function makeHouse(base, name, lotSize, length, width)
	local house = base:new { lotSize = lotSize, baseMaintenanceRate = houseRules.baseMaintenanceRate, allowedZones = houseRules.allowedZones, publicStructure = houseRules.publicStructure, skillMods = houseRules.skillMods, childObjects = houseRules.childObjects, constructionMarker = "object/building/player/construction/construction_player_house_generic_small_style_01.iff", length = length, width = width }
	ObjectTemplates:addTemplate(house, "object/building/player/" .. name .. ".iff")
end

makeHouse(object_building_player_shared_player_house_tree_house_01, "player_house_tree_house_01", 2, 4, 4)
makeHouse(object_building_player_shared_player_house_tree_house_02, "player_house_tree_house_02", 2, 4, 4)
makeHouse(object_building_player_shared_player_house_tcg_8_yoda_house, "player_house_tcg_8_yoda_house", 1, 3, 3)
makeHouse(object_building_player_shared_player_house_mustafar_lg, "player_house_mustafar_lg", 3, 5, 5)
