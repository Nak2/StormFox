
-- Server snow logic
	if SERVER then
		StormFox.SetNetworkData("SnowMaterial_Amount",0)

		local l = 0
		local old_lvl = -1
		hook.Add("Think","StormFox - Snow Replacement",function()
			if l > SysTime() then return end
				l = SysTime() + 5
			local temp = StormFox.GetNetworkData("Temperature",20)
			local Gauge = StormFox.GetData("Gauge",0)
			if temp > -2 or not StormFox.GetMapSetting("material_replacment") then
				StormFox.SetNetworkData("SnowMaterial_Amount",0)
				old_lvl = 0
			elseif Gauge > 0 then -- is cold and snowing
				local lvl = math.Clamp(math.Round((Gauge - 2) / 2),0,4)
				if StormFox.GetMapSetting("replace_dirtgrassonly") then
					lvl = 1
				end
				if old_lvl < lvl then
					old_lvl = lvl
					StormFox.SetNetworkData("SnowMaterial_Amount",lvl)
				end
			end
		end)
		return
	end

-- Delete old data from 1.119 and below
	local whitelist = {}
		whitelist["wizzard.txt"] = true
		whitelist["maplist.txt"] = true

	for _,fil in ipairs(file.Find( "stormfox/*", "DATA" )) do
		if not whitelist[fil] then
			file.Delete("stormfox/" .. fil)
		end
	end

_STORMFOX_ORIGNALTEX = _STORMFOX_ORIGNALTEX or {}
_STORMFOX_REPLACETEX_STR = _STORMFOX_REPLACETEX_STR or {}

-- Local functions
	local tab = {["grass"] = {"gravelfloor004a","gravelfloor002a","mudfloor06a","blendgrassmud01","dirt","train_grass_floor_01","blendmilground008_4","milground0"},
		["pavement"] = {"concretefloor027","concretefloor036a","concretefloor033b","stonefloor011","brickfloor001a","concretefloor019a","concretefloor028","concretefloor033y","cobble02","hall_concrete11_wet","stonefloor006","pavement001","cobble06","train_cement_floor_01"},
		["road"] = {"concretefloor033k","concretefloor033c","gravelpath01","bridge_concrete","road_texture","ajacks_10","asphalt_1_01"},
		["roof"] = {"dome005","concretefloor005a_-798_-1000_255","concretefloor005a_-915_-1136_255"}
	}
	local whitelist = {"models/props_rooftop/dome005","models/props_foliage/branches_003","de_dust/groundsand03"}
	local blacklist = {"concretefloor027a","swamp","indoor","foliage","model","dirtfloor005c","dirtground010"} -- "wood". dirtfloor005c see,s to be used a lot indoors
	local forcedlist = {"models/props_foliage/branches_003","nature/gravelfloor004a","nature/dirtfloor012a","nature/blendtoxictoxic004a","nature/blenddirtgrass001b","concrete/concretefloor033k","concrete/concretefloor033c","nature/grassfloor002a","nature/dirtfloor011a","nature/dirtfloor006a","nature/dirtfloor005c"}

	-- Local function
		local function tablescan(tab,str)
			for _,st in ipairs(tab) do
				if string.find(str,st) then
					return true
				end
			end
			return false
		end
		function ScanTexType(tex,mat_layers)
			if not tex then return end
			if tablescan(blacklist,tex:GetName()) then return end
			local str = type(tex) == "string" and tex or tex:GetName()
			if str == "error" then return end
			for _,mat_type in ipairs(mat_layers) do
				local fname = string.GetFileFromFilename(str)
				if tablescan(whitelist,str) then
					return mat_type
				elseif (string.find(fname,mat_type) or tablescan(tab[mat_type],fname)) and (not tablescan(blacklist,str)) then
					return mat_type
				end
			end
		end
		local function LoadTexts(tab)
			for str,_ in pairs(tab) do
				Material(str)
			end
		end
		local function ScanMapTextures(tab)
			local mat_layers = {"grass","roof","pavement","road"}
			local t = {}
				t["grass"] = {}
				t["roof"] = {}
				t["pavement"] = {}
				t["road"] = {}
			local t2 = {}
				t2["grass"] = {}
				t2["roof"] = {}
				t2["pavement"] = {}
				t2["road"] = {}

			for _,list in ipairs(forcedlist) do
				tab[list] = true
			end

			for str,_ in pairs(tab) do
				if not string.match(str,"^env/") then
					local mat = Material(str)
					local tex1,tex2 = mat:GetTexture("$basetexture"),mat:GetTexture("$basetexture2")
					local match1,match2 = ScanTexType(tex1,mat_layers),ScanTexType(tex2,mat_layers)
					if match1 then
						t[match1][mat] = {}
						t[match1][mat][1] = tex1:GetName()
						t2[match1][str] = {}
						t2[match1][str][1] = tex1:GetName()
					end
					if match2 then
						t[match2][mat] = t[match2][mat] or {}
						t[match2][mat][2] = tex2:GetName()
						t2[match2][str] = t2[match2][str] or {}
						t2[match2][str][2] = tex2:GetName()
					end
				end
			end
			return t,t2
		end
		local function ETHull(pos,pos2,min,max,mask)
			max.z = 0
			local t = util.TraceHull( {
			start = pos,
			endpos = pos + pos2,
			maxs = max,
			mins = min,
			mask = mask or LocalPlayer(),
			filter = LocalPlayer():GetViewEntity() or LocalPlayer()
			} )
			t.HitPos = t.HitPos or (pos + pos2)
			return t
		end

local Loaded = false
local function LoadMapData()
	if Loaded then return end
	if file.Exists("stormfox/maps/" .. game.GetMap() .. ".txt","data") then
		print("[StormFox]: Loading texturemap...")
		local tab = util.JSONToTable(file.Read("stormfox/maps/" .. game.GetMap() .. ".txt","DATA"))
		local t = {}
		for group,tt in pairs(tab) do
			t[group] = t[group] or {}
			for mat_string,data in pairs(tt) do
				t[group][Material(mat_string)] = data
			end
		end
		_STORMFOX_ORIGNALTEX = t
	else
		print("[StormFox]: Generating texturemap (Might take a bit)...")
		local str = file.Read("maps/" .. game.GetMap() .. ".bsp","GAME")
		local materials = {}
		local filedata = file.Read("maps/" .. game.GetMap() .. ".bsp","GAME")
		local matlist = string.match(filedata,"%s([^%s]+TOOLS%/TOOLSNODRAW[^%s]+)") or filedata
		local p = ""
		for w in string.gmatch( matlist, "[%a%d%_-/]+/[%a%d%_-/]+" ) do
			materials[string.lower(w)] = true
		end
		if game.GetWorld() and IsValid(game.GetWorld()) then
			for _,str in ipairs(game.GetWorld():GetMaterials()) do
				materials[string.lower(str)] = true
			end
		end
		LoadTexts(materials) -- Load materials
		local t,t2 = ScanMapTextures(materials)
		_STORMFOX_ORIGNALTEX = t
		local str = util.TableToJSON(t2)
		file.Write("stormfox/maps/" .. game.GetMap() .. ".txt",str)
		print("[StormFox]: Saving texturemap ..")
	end
	print("[StormFox]: Texturemap loaded.")
	Loaded = true
end
hook.Add("StormFox - PostEntity","StormFox - MaterialLoader",timer.Simple(2,LoadMapData))

local function ReplaceMaterial(str,texture,id)
	if not id then id = 1 end
	-- Save old material
	local mat = str
	if type(str) != "IMaterial" then
		mat = Material(str)
	end
	local parm = "$basetexture" .. (id == 1 and "" or id)
	local currentbase = mat:GetTexture(parm)
	if not currentbase or (currentbase:GetName() or "null") == texture then return end

	if not _STORMFOX_REPLACETEX_STR[str] then
		_STORMFOX_REPLACETEX_STR[str] = {}
	end
	if not _STORMFOX_REPLACETEX_STR[str][id] and (currentbase:GetName() or "null") != "nature/snowfloor001a" then
		_STORMFOX_REPLACETEX_STR[str][id] = currentbase:GetName()
	end
	mat:SetTexture(parm,texture)
end

local function UndoAll()
	for mat,data in pairs(_STORMFOX_REPLACETEX_STR) do
		for id,str in pairs(data) do
			--print("undo",mat,id,str:GetName())
			if str == "nature/snowfloor001a" then
				print("SNOW ERROR!")
			end
			ReplaceMaterial(mat,str,id)
		end
	end
--	Material("detail/detailsprites"):SetVector("$color",Vector(1,1,1))
end

local function MakeSnow(lvl)
	local allowed = {}
	local ls = {"grass","roof" --[["pavement",]],"road"}
	for I = 1, lvl do
		allowed[ls[I]] = true
	end
	if lvl <= 0 then return end
	for _type,data in pairs(_STORMFOX_ORIGNALTEX) do
		if allowed[_type] then
			--print(_type)
			for mat,textab in pairs(data) do
				for id,_ in pairs(textab) do
					--print(mat,tex,id)
					ReplaceMaterial(mat,"nature/snowfloor001a",id)
				end
			end
		end
	end
--	Material("detail/detailsprites"):SetVector("$color",Vector(6000,6000,6000))
end

local l,lvl_old = 0,-1
hook.Add("Think","StormFox - Snow Replacement",function()
	if l > SysTime() then return end
		l = SysTime() + 5
	if not Loaded then return end
	local lvl = math.Clamp(StormFox.GetNetworkData("SnowMaterial_Amount",0),0,3)
	local con = GetConVar("sf_material_replacment")
	if not con:GetBool() then
		lvl = 0
	end
	if lvl_old != lvl then
		lvl_old = lvl
		UndoAll()
		MakeSnow(lvl)
		MakeSnow(lvl)
	end
end)

hook.Add("PlayerFootstep","StormFox - Material Footstep",function( ply, pos, foot, sound, volume, rf )
	local con = GetConVar("sf_material_replacment")
	if not con:GetBool() then return end
	local lvl = math.Clamp(StormFox.GetNetworkData("SnowMaterial_Amount",0),0,3)
	if lvl <= 0 then return end
	if table.Count(_STORMFOX_REPLACETEX_STR) <= 0 then return end
	local mz = ply:OBBMins().z
	local t = ETHull(ply:GetPos(),Vector(0,0,-(mz + 25)),ply:OBBMins(),ply:OBBMaxs())
	if not t.Hit then return end
	local mat = Material(t.HitTexture)
	local mat_name = mat:GetName()
	if mat_name == "___error" then
		-- check for other things
		if string.find(sound,"player/footsteps/dirt") or string.find(sound,"player/footsteps/grass") then
			ply:EmitSound( "player/footsteps/snow" .. math.random(1,6) .. ".wav" )
			return true
		end
		return
	end
	if _STORMFOX_REPLACETEX_STR[mat_name] then
		ply:EmitSound( "player/footsteps/snow" .. math.random(1,6) .. ".wav" )
		return true
	end
	if mat:GetTexture("$basetexture") then
		if mat:GetTexture("$basetexture"):GetName() == "nature/snowfloor001a" then
			ply:EmitSound( "player/footsteps/snow" .. math.random(1,6) .. ".wav" )
			return true
		end
	end
	if mat:GetTexture("$basetexture2") then
		if mat:GetTexture("$basetexture2"):GetName() == "nature/snowfloor001a" then
			ply:EmitSound( "player/footsteps/snow" .. math.random(1,6) .. ".wav" )
			return true
		end
	end
end)