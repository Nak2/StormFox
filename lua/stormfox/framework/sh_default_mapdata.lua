--[[-------------------------------------------------------------------------
This file contains the default SF texture-data, added to the BSP data.
---------------------------------------------------------------------------]]

local default_foliage = {}
	--[[-------------------------------------------------------------------------
	Foliage_type:
			-2 - No treesway
			-1 - Tree trunk
			0 - Tree / w branches andor leaves
			1 - Branches / Leaves
			2 - Ground Plant
		Bendyness multiplier:
			1 - default
		mat_height:
			0 - height
		WaveBonus_speed:
			<number>
	---------------------------------------------------------------------------]]
		--default_foliage["detail/detailsprites"] = {2} Not working
		default_foliage["models/props_coalmine/foliage1"] = {2}
		default_foliage["models/props_foliage/mall_trees_branches03"] = {2}
		default_foliage["models/props_foliage/tree_deciduous_01a_branches"] = {2}
		default_foliage["models/props_foliage/bramble01a"] = {2,0.4}
		default_foliage["models/props_foliage/leaves_bushes"] = {2}
		default_foliage["models/props_foliage/leaves"] = {2}
		default_foliage["models/props_foliage/cane_field01"] = {2,nil,0.3}
		--default_foliage["models/props_foliage/cattails"] = {2} Not working
		--default_foliage["models/props_foliage/trees_farm01"] = {-1,0.8,0.02,1.5} Doesn't look good on some trees
		default_foliage["models/props_foliage/cedar01_mip0"] = {0,0.4,0.02,3}
		default_foliage["models/props_foliage/coldstream_cedar_bark"] = {-1}
		default_foliage["models/props_foliage/coldstream_cedar_branches"] = {0}
		default_foliage["models/props_foliage/urban_trees_branches03"] = {0}
		default_foliage["models/props_foliage/bush"] = {2}
		default_foliage["models/props_foliage/corn_plant01"] = {1,3.4}
		default_foliage["models/props_foliage/detail_clusters"] = {2}
		default_foliage["models/cliffs/ferns01"] = {0,2,nil,2}
		default_foliage["models/props_foliage/rocks_vegetation"] = {0,4,nil,1,2}
		default_foliage["models/props_foliage/flower_barrel"] = {0,3,0.07,2}
		default_foliage["models/props_foliage/flower_barrel_dead"] = {0,1,0.07,2}
		default_foliage["models/props_foliage/flower_barrel_dead"] = {0,1,0.07,2}
		default_foliage["models/props/de_inferno/flower_barrel"] = {0,3,0.02,2}
		default_foliage["models/props_foliage/grass_01"] = {2,0.5}
		default_foliage["models/props_foliage/grass_02"] = {2,0.5}
		default_foliage["models/props_foliage/grass_clusters"] = {2}
		default_foliage["models/props_foliage/urban_trees_branches02_mip0"] = {-1}
		default_foliage["models/props_foliage/hedge_128"] = {2,0.8}
		default_foliage["models/props_foliage/foliage1"] = {2}
		default_foliage["models/props_foliage/hr_f/hr_medium_tree_color"] = {-1}
		default_foliage["models/props_foliage/ivy01"] = {2,0.1}
		default_foliage["models/props_foliage/mall_trees_branches01"] = {0,1,nil,2}
		default_foliage["models/props_foliage/mall_trees_barks01"] = {-1,1,nil,4}
		default_foliage["models/props_foliage/mall_trees_branches02"] = {-1,1,nil,4}
		--default_foliage["models/props_foliage/oak_tree01"] = {}
		default_foliage["models/props_foliage/potted_plants"] = {0,4,0.055}
		default_foliage["models/props_foliage/shrub_03"] = {2}
		default_foliage["models/props_foliage/shrub_03_skin2"] = {2}
		default_foliage["models/props_foliage/swamp_vegetation01"] = {-1,0.005,0.2}
		default_foliage["models/props_foliage/swamp_branches"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_branches01_large"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_barks_large"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_barks"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_branches01"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_barks_still"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_trees_barks_generic"] = {0,0.005,0.2,10}
		default_foliage["models/props_foliage/swamp_shrubwall01"] = {2}
		default_foliage["models/props_foliage/swamp_trees_branches01_alphatest"] = {0,0.05}
		default_foliage["models/props_foliage/swamp_trees_branches01_still"] = {0,0.05}
		default_foliage["models/props_foliage/branch_city"] = {-1}
		default_foliage["models/props_foliage/arbre01"] = {-1,0.4,0.04,2}
		default_foliage["models/props_foliage/arbre01_b"] = {-1,0.05,nil,2}
		default_foliage["models/props_foliage/tree_deciduous_01a-lod.mdl"] = {}
		default_foliage["models/props_foliage/tree_deciduous_01a_lod"] = {-1}
		default_foliage["models/props_foliage/tree_pine_01_branches"] = {-2} -- Looks bad. Remove.
		default_foliage["models/props_foliage/pine_tree_large"] = {-1,0.8}
		default_foliage["models/props_foliage/pine_tree_large_snow"] = {-1,0.8}
		default_foliage["models/props_foliage/branches_farm01"] = {-1,0.2,0.8}
		default_foliage["models/props_foliage/urban_trees_branches03_small"] = {2,0.8}
		default_foliage["models/props_foliage/urban_trees_barks01_medium"] = {-1}
		default_foliage["models/props_foliage/urban_trees_branches03_medium"] = {0,2}
		default_foliage["models/props_foliage/urban_trees_barks01_medium"] = {-1,2,0.2}
		default_foliage["models/props_foliage/urban_trees_branches02_small"] = {2}
		default_foliage["models/props_foliage/urban_trees_barks01_clusters"] = {-1,0.2,0.2}
		default_foliage["models/props_foliage/urban_trees_branches01_clusters"] = {0,0.2,0.2}
		default_foliage["models/props_foliage/urban_trees_barks01"] = {-1,0.2}
		default_foliage["models/props_foliage/urban_trees_barks01_dry"] = {2,nil,10}
		default_foliage["models/props_foliage/leaves_large_vines"] = {0}
		default_foliage["models/props_foliage/vines01"] = {2,0.3}
		default_foliage["models/map_detail/foliage/foliage_01"] = {2,0.5}
		default_foliage["models/map_detail/foliage/detailsprites_01"] = {2}
		default_foliage["models/nita/ph_resortmadness/pg_jungle_plant"] = {0,1.2}
		default_foliage["models/nita/ph_resortmadness/plant_03"] = {-1,0.3}
		default_foliage["models/nita/ph_resortmadness/leaf_8"] = {0,2}
		default_foliage["models/nita/ph_resortmadness/fern_2"] = {0,2}
		default_foliage["models/nita/ph_resortmadness/tx_plant_02"] = {0,4,nil,4}
		default_foliage["models/nita/ph_resortmadness/tx_plant_04"] = {0,4,nil,4}
		default_foliage["models/nita/ph_resortmadness/orchid"] = {0,4,nil,4}
		default_foliage["models/props_foliage/ah_foliage_sheet001"] = {2,0.4}
		default_foliage["models/props_foliage/ah_apple_bark001"] = {2,0.4}

		default_foliage["statua/nature/furcard1"] = {2,0.1}
		default_foliage["models/statua/shared/furcard1"] = {2,0.1}
		
hook.Add("StormFox.TexHandler.Default","StormFox.DefaultTexData",function()
	local t = {}
	t.snow = {
		-- DOD
			["models/props_foliage/hedge_128"] = "models/props_foliage/hedgesnow_128",
			["models/props_fortifications/dragonsteeth"] = "models/props_fortifications/dragonsteeth_snow",
			["models/props_fortifications/sandbags"] = "models/props_fortifications/sandbags_snow",
			["models/props_normandy/logpile"] = "models/props_normandy/logpile_snow",
			["models/props_vehicles/222_darkyellow44"] = "models/props_vehicles/222_snow",
			["models/props_urban/light_fixture01"] = "models/props_urban/light_fixture01_snow",
			["models/props_urban/light_fixture01_on"] = "models/props_urban/light_fixture01_snow_on",
			["models/props_urban/light_streetlight01"] = "models/props_urban/light_streetlight01_snow",
			["stone/stonefloor002"] = "stone/stonefloor002_snow",
			["stone/stonefloor002b"] = "stone/stonefloor002b_snow",
			["stone/stonewall017"] = "stone/stonewall017_snow",
			["stone/stonewall014"] = "stone/stonewall014b_snow",
			["plaster/plasterwall017b"] = "plaster/plasterwall017b_snow",
			["plaster/plasterwall04b"] = "plaster/plasterwall04b_snow",
			["plaster/plasterwall015f"] = "plaster/plasterwall015f_snow",
			["plaster/plasterwall012b"] = "plaster/plasterwall012b_snow",
			["plaster/plasterwall010b"] = "plaster/plasterwall010b_snow",
			["models/props_fortifications/hedgehog"] = "models/props_fortifications/hedgehog_snow",
		-- HL2 EP2
			["models/props_foliage/hedge_128"] = "models/props_foliage/hedgesnow_128",
		-- TF2
			["models/props_foliage/grass_02"] = "models/props_foliage/grass_02_snow",
			["models/props_foliage/grass_02_dark"] = "models/props_foliage/grass_02_snow",
			["models/props_foliage/grass_02_detailmodel"] = "models/props_foliage/grass_02_snow",
			--["models/props_foliage/pine_tree_large"] = "models/props_foliage/pine_tree_large_snow", Looks bad
			["models/props_foliage/shrub_03_skin2"] = "models/props_foliage/shrub_03_snow",
			["models/props_foliage/tree_pine01"] = "models/props_foliage/tree_pine01_snow",
			["models/props_forest/cliff_wall_02"] = "models/props_forest/cliff_wall_02_snow",
			["models/props_forest/cliff_wall_05"] = "models/props_forest/cliff_wall_05_snow",
			["models/props_forest/cliff_wall_06"] = "models/props_forest/cliff_wall_06_snow",
			["models/props_forest/cliff_wall_09"] = "models/props_forest/cliff_wall_09_snow",
			["models/props_forest/cliff_wall_10"] = "models/props_forest/cliff_wall_10_snow",
			["models/props_forest/cliff_wall_10a"] = "models/props_forest/cliff_wall_10a_snow",
			["models/props_forest/train_stop"] = "models/props_forest/train_stop_snow",
			["models/props_vehicles/tiger_tank"] = "models/props_vehicles/tiger_tank_snow",
			["models/props_vehicles/tiger_tank_navyb"] = "models/props_vehicles/tiger_tank_snow",
		-- SF
			["models/buggy/buggy001"] = "stormfox/textures/buggy001-snow",
	}
	t.rain = {}
	local con = GetConVar("sf_overridefoliagesway")
	if con and con:GetBool() then
		t.foliage = default_foliage
	end
	return t
end)