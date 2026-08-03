local function addDeed(base, name, building)
	local deed = base:new { templateType = STRUCTUREDEED, placeStructureComponent = "PlaceStructureComponent", generatedObjectTemplate = building }
	ObjectTemplates:addTemplate(deed, "object/tangible/deed/player_house_deed/" .. name .. ".iff")
end

-- Use Core3's native, fully client-supported deed presentation template.
-- The generated structure remains the imported house listed in each entry.
addDeed(object_tangible_deed_player_house_deed_shared_generic_house_small_deed, "tree_house_01_deed", "object/building/player/player_house_tree_house_01.iff")
addDeed(object_tangible_deed_player_house_deed_shared_generic_house_small_deed, "tree_house_02_deed", "object/building/player/player_house_tree_house_02.iff")
addDeed(object_tangible_deed_player_house_deed_shared_generic_house_small_deed, "yoda_house_deed", "object/building/player/player_house_tcg_8_yoda_house.iff")
addDeed(object_tangible_deed_player_house_deed_shared_generic_house_small_deed, "mustafar_house_lg_deed", "object/building/player/player_house_mustafar_lg.iff")
