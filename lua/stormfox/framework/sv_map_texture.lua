
local mat_version = 0.9
local mat_table = {}
util.AddNetworkString("StormFox - mapdata")

-- Alright mr ClockWork guy. This is my file.read and file.write.
local file_read = file.Read
local file_write = file.Write

local function CheckMapData() -- Check if the current data is valid
	if file.Exists("stormfox/maps/" .. game.GetMap() .. ".txt","DATA") then
		local f_data = file_read("stormfox/maps/" .. game.GetMap() .. ".txt","DATA")
		mat_table = util.JSONToTable(f_data)
		if not mat_table then
			StormFox.Msg("Corrupt mapdata detected. Deleting")
			file.Delete("stormfox/maps/" .. game.GetMap() .. ".txt")
			mat_table = nil
			return false
		elseif (mat_table.version or 0) < mat_version then
			StormFox.Msg("Old mapdata detected. Deleting ..")
			file.Delete("stormfox/maps/" .. game.GetMap() .. ".txt")
			mat_table = nil
			return false
		else
			StormFox.Msg("Mapdata V" .. mat_table.version)
		end
		return true
	else
		return false
	end
end

-- Table of known materials that we look for and data
	local tab = {["grass"] = {"gravelfloor004a","gravelfloor002a","mudfloor06a","blendgrassmud01","dirt","train_grass_floor_01","blendmilground008_4","milground0"},
		["pavement"] = {"concretefloor027","concretefloor036a","concretefloor033b","stonefloor011","brickfloor001a","concretefloor019a","concretefloor028","concretefloor033y","cobble02","hall_concrete11_wet","stonefloor006","pavement001","cobble06","train_cement_floor_01"},
		["road"] = {"concretefloor033k","concretefloor033c","gravelpath01","bridge_concrete","road_texture","ajacks_10","asphalt_1_01"},
		["roof"] = {"dome005","concretefloor005a_-798_-1000_255","concretefloor005a_-915_-1136_255"}
	}
	-- Ignore blacklist
		local whitelist = {"models/props_rooftop/dome005","models/props_foliage/branches_003","de_dust/groundsand03"}
	-- Block those materials
		local blacklist = {"concretefloor027a","swamp","indoor","foliage","model","dirtfloor005c","dirtground010"} -- "wood". dirtfloor005c see,s to be used a lot indoors
	-- Add thise materials to the scanner
		local forcedlist = {"customtext/gc textures/blends/grass_dirt_blend01","models/props_foliage/branches_003","nature/gravelfloor004a","nature/dirtfloor012a","nature/blendtoxictoxic004a","nature/blenddirtgrass001b","concrete/concretefloor033k","concrete/concretefloor033c","nature/grassfloor002a","nature/dirtfloor011a","nature/dirtfloor006a","nature/dirtfloor005c"}
	-- Trees and foliage (If false then force sheet)
		local foliage = {}
			-- Foliage data
			--	{height, wind_effect_strengh}
			-- Locate all detail
				for i,v in ipairs(file.Find("materials/detail/*.vmt","GAME")) do
					foliage["detail/" ..v] = {}
				end
				foliage["detail/detailsprites"] = {false}
			-- All foliage from HL2,HL2 EP2, CSS, CS:GO
					foliage["models/props_foliage/branches_farm01"] = {false}
					foliage["models/props_foliage/branches_farm01_alphatest"] = {false}
					foliage["models/props_foliage/bush"] = {false}
					foliage["models/props_foliage/cane_field01"] = {}
					foliage["models/props_foliage/cattails"] = {}
					foliage["models/props_foliage/cedar01"] = {false}
					foliage["models/props_foliage/cedar01_mip0"] = {false}
					foliage["models/props_foliage/corn_plant01"] = {}
					foliage["models/props_foliage/corn_plant02"] = {}
					foliage["models/props_foliage/desertgrass"] = {}
					foliage["models/props_foliage/grass3"] = {}
					foliage["models/props_foliage/grass_01"] = {}
					foliage["models/props_foliage/grass_01_skin2"] = {}
					foliage["models/props_foliage/grass_02_skin2"] = {}
					foliage["models/props_foliage/grass_clusters"] = {}
					foliage["models/props_foliage/island_plant_detailmodel04"] = {{},0.2}
					foliage["models/props_foliage/leaves"] = {false,0.2}
					foliage["models/props_foliage/leaves_bushes"] = {false,0.2}
					foliage["models/props_foliage/leaves_dead"] = {false,0.2}
					foliage["models/props_foliage/leaves_large_vines"] = {false,0.2}
					foliage["models/props_foliage/leaves_skin2"] = {false,0.2}
					foliage["models/props_foliage/leaves_translucentvmt"] = {false,0.2}
					foliage["models/props_foliage/leaves_translucentvmt_dead"] = {false,0.2}
					foliage["models/props_foliage/mall_trees_branches01"] = {false,0.2}
					foliage["models/props_foliage/mall_trees_branches02"] = {false,0.2}
					foliage["models/props_foliage/mall_trees_branches03"] = {false,0.2}
					foliage["models/props_foliage/rocks_vegetation"] = {false,0.8}
					foliage["models/props_foliage/swamp_trees_branches01"] = {false,0.5}
					foliage["models/props_foliage/swamp_trees_branches01_alphatest"] = {false,0.5}
					foliage["models/props_foliage/swamp_trees_branches01_large"] = {false,0.5}
					foliage["models/props_foliage/swamp_trees_branches01_still"] = {false,0.5}
					foliage["models/props_foliage/tree_deciduous_01a_leaves*"] = {false,1.2}
					foliage["models/props_foliage/tree_pine_01_branches"] = {false,0.2}
					--	foliage["models/props_foliage/tree_deciduous_01a_leaves2"] = false
					--	foliage["models/props_foliage/tree_deciduous_01a_leaves3"] = false
					--foliage["models/props_foliage/tree_deciduous_01a_lod-leaves"] = false
					foliage["models/props_foliage/tree_springers_01a*"] = {false}
					--	foliage["models/props_foliage/tree_springers_01a_leaves"] = false
					--	foliage["models/props_foliage/tree_springers_01a_lod-leaves"] = false
					--	foliage["models/props_foliage/tree_springers_01a_lod"] = false
					foliage["models/props_foliage/urban_palm_branchesdust"] = {false}
					foliage["models/props_foliage/urban_tree03_branches"] = {false}
					foliage["models/props_foliage/urban_tree04_branches"] = {false}
					foliage["models/props_foliage/urban_trees_branches0*"] = {false,0.8}
					--	foliage["models/props_foliage/urban_trees_branches01_dry"] = {false,0.8}
					--	foliage["models/props_foliage/urban_trees_branches02"] = {false,0.8}
					--	foliage["models/props_foliage/urban_trees_branches02_dry"] = {false,0.8}
					--	foliage["models/props_foliage/urban_trees_branches01_clusters"] = {false,0.8}
					foliage["models/props_foliage/urban_trees_branches03*"] = {false,0.3}
				-- City 33x
					foliage["models/foliage/tree5_1"] = {false,0.4}
					foliage["models/foliage/tree5_2"] = {false,0.4}
					foliage["models/foliage/tree5_3"] = {false,0.4}
					foliage["models/foliage/tree5_4"] = {false,0.4}
					foliage["models/trees/japanese_tree_round_02"] = {}
					foliage["models/trees/japanese_tree_round_03"] = {}
					foliage["models/trees/japanese_tree_round_04"] = {}
					foliage["models/trees/japanese_tree_round_05"] = {}
					foliage["models/msc/e_leaves"] = {}
					foliage["models/msc/e_leaves2"] = {}
					foliage["models/msc/e_leaves3"] = {}
					foliage["models/msc/e_bigbush"] = {}
					foliage["models/msc/e_bigbush2"] = {}
					foliage["models/msc/e_bigbush3"] = {}
					foliage["models/msc/e_tree2"] = {false}
					foliage["models/msc/e_tree"] = {false,0.4}
					foliage["models/trees/g_branch01"] = {false,0.4}
					foliage["models/trees/g_branch02"] = {false,0.4}
					foliage["models/trees/g_branch03"] = {false,0.4}
					foliage["models/trees/g_branch04"] = {false,0.4}
					foliage["models/trees/g_branch05"] = {false,0.4}
					foliage["models/props/de_inferno/largebushf"] = {false,0.4}
					foliage["models/props/de_inferno/largebushg"] = {false,0.4}
					foliage["models/props/de_inferno/largebushh"] = {}
					foliage["models/props/de_inferno/largebushg"] = {false,0.4}
					foliage["gm_forest/brg_alder_brn"] = {false}

					foliage["models/props_foliage/urban_trees_branches02"] = {0,1}
					foliage["models/props_foliage/urban_trees_branches03"] = {0,1}
					foliage["models/props_foliage/urban_trees_branches03_medium"] = {0,1}
					foliage["models/props_foliage/urban_trees_branches03_small"] = {0,1}
					--foliage["models/props_foliage/arbre01"] = {false,0.1} looks strange

					foliage["detail/l4d2detailsprites_overgrown"] = {false}
					foliage["models/props_foliage/mall_trees_barks01"] = {0.5,1}
					foliage["models/props/de_inferno/largebushc"] = {false}
					foliage["models/props/de_inferno/largebushc1"] = {false}
					-- foliage["models/props/cs_militia/fern01"] = {0,0.1} only animating the top

					-- foliage["models/props_foliage/tree_deciduous_01a_trunk"] = {true,0.3} Dancing trees :D
		local blackList_foliage = {"trunk"}
	local function isBlackList(str)
		for k,v in pairs(blackList_foliage) do
			if string.find(str,v) then return true end
		end
		return false
	end
	local function GetFoliage()
		local t = {}
		for tex,data in pairs(foliage) do
			if not string.find(tex,"*") then
				t[tex] = data
			else
				local s = string.Replace(tex,"*","")
				if not Material(s):IsError() then
					if not isBlackList(s) then
						t[s] = data
					end
				end
				for k,v in pairs(file.Find("materials/" .. tex,"GAME")) do
					local s = "models/props_foliage/" .. v
					if not Material(s):IsError() then
						if not isBlackList(s) then
							t[s] = data
						end
					end
				end
			end
		end
		return t
	end		

-- Small functions
	local function mapType(str)
		for t,ttab in pairs(tab) do
			if string.find(str,t) then
				return t
			end
			for _,st in pairs(ttab) do
				if string.find(str,st) then
					return t
				end
			end
		end
		return
	end
	local function ScanTexture(str)
		if string.match(str,"^env/") then return end
		if not table.HasValue(whitelist,str) then
			if table.HasValue(blacklist,str) then
				return nil,nil,"blacklisted"
			end
		end
		local mat = Material(str)
		if not mat then return nil,nil,"Unknown" end

		local m_data = mat:GetKeyValues()
		local tex1,tex2 = m_data["$basetexture"],m_data["$basetexture2"]
		if not tex1 or type(tex1) == "number" then
			return nil,nil,"Unknown"
		end
		-- Servers return this a string. Clients as a texture.
			if type(tex1)~="string" then
				tex1 = tex1:GetName()
			end
		if not tex2 or type(tex2) == "number" then
			return mapType(tex1),nil,"t1"
		end
		if type(tex2)~="string" then
			tex2 = tex2:GetName()
		end
		return mapType(tex1),mapType(tex2),"r"
	end
	local function isBranch(fil_name)
		local branch = false
		if not string.find(fil_name,"sheet") and not string.find(fil_name,"foliage") and not string.find(fil_name,"sprites") then -- Not a sheet
			if string.find(fil_name,"leaf") or string.find(fil_name,"tree") or string.find(fil_name,"branch") or string.find(fil_name,"palm") then
				branch = true
			end
		end
		return branch
	end
	local function generateFoliageData(str)
		str = string.lower(str)
		local fil_name = string.GetFileFromFilename(str)
		if string.find(fil_name,"truck") or string.find(fil_name,"shrub") then return end

		local branch = isBranch(fil_name)
		local t = {}
		if branch then
			t.height = 0.5
		else
			t.height = 0
		end
		if string.find(str,"twig") then
			t.strengh = 0.2
			t.wavy = 0
		end
		return t
	end
	local function GenerateMapdata()
		mat_table = {}
		mat_table.version = mat_version
		mat_table.tree = {}

		print("	Locating map-materials ...")
		-- Scan for map materials
			local materials = {}
			local filedata = file_read("maps/" .. game.GetMap() .. ".bsp","GAME") -- Takes aaaagggeeeess
			local matlist = string.match(filedata,"%s([^%s]+TOOLS%/TOOLSNODRAW[^%s]+)") or filedata
			local p = ""
			for w in string.gmatch( matlist, "[%a%d%_-/]+/[%a%d%_-/]+" ) do
				materials[string.lower(w)] = true
			end
			if type(game.GetWorld()) == "Entity" then
				for _,str in pairs(game.GetWorld():GetMaterials()) do
					materials[string.lower(str)] = true
				end
			end
			for _,v in pairs(forcedlist) do
				materials[v] = true
			end
			print("	Generated material list.")
		-- Setup datatab
			mat_table.material = {}
		-- Scan the material list.
			print("	Scanning ...")
			for mat,_ in pairs(materials) do
				-- material
				local t1,t2 = ScanTexture(mat)
				if t1 or t2 then
					mat_table.material[mat] = {}
					mat_table.material[mat][1] = t1
					mat_table.material[mat][2] = t2
				end
			end
			print("	Scanned " .. table.Count(materials) .. " materials.")
		-- Including trees
			print("	Including foliage-list ...")
			-- I could include all materials under "materials/models/props_foliage/", but its going to include tree_trunks and twigs
			mat_table.tree = {}
			for tex,t_data in pairs(GetFoliage()) do
				mat_table.tree[tex] = generateFoliageData(tex)
				if type(t_data) == "table" then
					if t_data[1] then
						if type(t_data[1]) == "boolean" then
							mat_table.tree[tex].height = 0.5
						else
							mat_table.tree[tex].height = t_data[1]
						end
					end
					if t_data[2] then
						mat_table.tree[tex].strengh = t_data[2]
					end
				end
			end
		file_write("stormfox/maps/" .. game.GetMap() .. ".txt",util.TableToJSON(mat_table))
		print(" Saved new mapdata.")
	end
	local function compress()
		local s = util.TableToJSON(mat_table)
		return util.Compress(s)
	end
	local function updateData()
		net.Start("StormFox - mapdata")
			local s = compress()
			net.WriteInt(string.len(s),24)
			net.WriteData(s,string.len(s))
		net.Broadcast()
	end
local function LoadMapdata()
	if CheckMapData() then -- Is mapdata valid?
		StormFox.Msg("Loaded mapdata.")
	else
		StormFox.Msg("Generating new mapdata. (This can take a while)")
		GenerateMapdata()
	end
	updateData()
end
-- Load the mapdata on initpost .. or within 2 seconds
	local b = false
	hook.Add("InitPostEntity","StormFox - loadMapData",function()
		b = true
		LoadMapdata()
	end)
	timer.Simple(2,function()
		if b then return end
		LoadMapdata()
	end)

function StormFox.GetMapMaterials()
	return mat_table
end

local tickets = {}
net.Receive("StormFox - mapdata",function(len,ply)
	if tickets[ply] then return end -- Already used your ticket m8
	tickets[ply] = true
	net.Start("StormFox - mapdata")
		local s = compress()
		net.WriteInt(string.len(s),24)
		net.WriteData(s,string.len(s))
	net.Send(ply)
end)

local cacheSnd = {}
function StormFox.SetGroundMaterial(str,lvl,snd)
	if not StormFox.GetMapSetting("material_replacment") then
		table.Empty(cacheSnd) -- cache changed
		StormFox.SetNetworkData("Ground_Material","nil")
		StormFox.SetNetworkData("Ground_MaterialLvl",math.floor(lvl or 0))
		StormFox.SetNetworkData("Ground_Material_Snd","nil")
		return
	end
	table.Empty(cacheSnd) -- cache changed
	StormFox.SetNetworkData("Ground_Material",str or "nil")
	StormFox.SetNetworkData("Ground_MaterialLvl",math.floor(lvl or 0))
	StormFox.SetNetworkData("Ground_Material_Snd",snd or "nil")
end

-- Sound
	local function ETHull(ent,pos,pos2,min,max,mask)
		max.z = 0
		local t = util.TraceHull( {
		start = pos,
		endpos = pos + pos2,
		maxs = max,
		mins = min,
		mask = mask or ent,
		filter = ent:GetViewEntity() or ent
		} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

local allowed_type = {}
	allowed_type[0] = {}
	allowed_type[1] = {["grass"] = true}
	allowed_type[2] = {["grass"] = true,["roof"] = true,["pavement"] = true}
	allowed_type[3] = {["grass"] = true,["roof"] = true,["pavement"] = true,["road"] = true}

local function checkSnd(mat,lvl)
	if cacheSnd[mat]~=nil then return cacheSnd[mat] end
	local result = false
	local m = Material(mat)
	local t1,t2 = m:GetTexture("$basetexture"),m:GetTexture("$basetexture2")
	if t1 then
		t1 = t1:GetName()
	else
		t1 = ""
	end
	if t2 then
		t2 = t2:GetName()
	else
		t2 = ""
	end
	local _type = {}
	for _,t_type in pairs(mat_table.material[mat] or {}) do
		_type[t_type] = true
	end
	for _,t_type in pairs(mat_table.material[t1] or {}) do
		_type[t_type] = true
	end
	for _,t_type in pairs(mat_table.material[t2] or {}) do
		_type[t_type] = true
	end
	for t,_ in pairs(_type) do
		if allowed_type[lvl][t] then
			result = true
			break
		end
	end
	cacheSnd[mat] = result
	return cacheSnd[mat]
end
hook.Add("PlayerFootstep","StormFox - Material Footstep",function( ply, pos, foot, sound, volume, rf )
	local snd = StormFox.GetNetworkData("Ground_Material_Snd","nil")
		if not snd then return end
	local lvl = StormFox.GetNetworkData("Ground_MaterialLvl",0)
		if lvl <= 0 then return end -- No materials changed
	-- If rable .. take a random
		if type(snd) == "table" then
			snd = table.Random(snd)
		end
	-- if nil then nothing
		if snd == "nil" then return end
	-- Scan for material
		local mz = ply:OBBMins().z
		local t = ETHull(ply,ply:GetPos(),Vector(0,0,-(mz + 25)),ply:OBBMins(),ply:OBBMaxs())
		if not t.Hit then return end -- flying
		local mat = Material(t.HitTexture)
		local mat_name = mat:GetName()
		-- In case of nil
			if mat_name == "___error" then -- Often the "ground" material. Check for dirt and grass sounds
				if string.find(sound,"dirt") or string.find(sound,"grass") then
					ply:EmitSound( snd )
					return true
				end
				return
			end
	-- Check if its a replaced material
		if not mat_table then return end
		if not mat_table.material then return end
		if checkSnd(mat_name,lvl) then
			ply:EmitSound( snd )
			return true
		end
end)