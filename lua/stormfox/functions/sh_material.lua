
if SERVER then
	StormFox.SetData("SnowMaterial",0)

	local l = 0
	local old_lvl = -1
	hook.Add("Think","StormFox - Snow Replacement",function()
		if l > CurTime() then return end
			l = CurTime() + 5
		local temp = StormFox.GetData("Temperature",20)
		local Gauge = StormFox.GetData("Gauge",0)
		local con = GetConVar("sf_sv_material_replacment")
		if temp > -2 or not con:GetBool() then
			StormFox.SetData("SnowMaterial",0)
			old_lvl = 0
		elseif Gauge > 0 then -- is cold and snowing
			local lvl = math.Clamp(math.Round((Gauge - 2) / 2),0,4)
			if GetConVarNumber("sf_replacment_dirtgrassonly",0) > 0 then
				lvl = 1
			end
			if old_lvl < lvl then
				old_lvl = lvl
				StormFox.SetData("SnowMaterial",lvl)
			end
		end
	end)
	return
end

_STORMFOX_ORIGNALTEX = _STORMFOX_ORIGNALTEX or {}
_STORMFOX_REPLACETEX_STR = _STORMFOX_REPLACETEX_STR or {}

-- Local functions
	local tab = {["grass"] = {"gravelfloor004a","gravelfloor002a","mudfloor06a","blendgrassmud01","dirt","train_grass_floor_01","blendmilground008_4","milground0"},
		["pavement"] = {"concretefloor027","concretefloor036a","concretefloor033b","stonefloor011","brickfloor001a","concretefloor019a","concretefloor028","concretefloor033y","cobble02","hall_concrete11_wet","stonefloor006","pavement001","cobble06","train_cement_floor_01"},
		["road"] = {"concretefloor033k","concretefloor033c","gravelpath01","bridge_concrete","road_texture","ajacks_10","asphalt_1_01"},
		["roof"] = {"dome005","concretefloor005a_-798_-1000_255","concretefloor005a_-915_-1136_255"}
	}
	local whitelist = {"models/props_rooftop/dome005","models/props_foliage/branches_003"}
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
				if (string.find(fname,mat_type) or tablescan(tab[mat_type],fname)) and (not tablescan(blacklist,str) or tablescan(whitelist,str)) then
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

			for _,list in ipairs(forcedlist) do
				tab[list] = true
			end

			for str,_ in pairs(tab) do
				local mat = Material(str)
				local tex1,tex2 = mat:GetTexture("$basetexture"),mat:GetTexture("$basetexture2")
				local match1,match2 = ScanTexType(tex1,mat_layers),ScanTexType(tex2,mat_layers)
				if match1 then
					t[match1][mat] = {}
					t[match1][mat][1] = tex1:GetName()
				end
				if match2 then
					t[match2][mat] = t[match2][mat] or {}
					t[match2][mat][2] = tex2:GetName()
				end
			end
			return t
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

if not file.Exists("stormfox","data") then
	file.CreateDir("stormfox")
end

local function LoadMapData()
	if file.Exists("stormfox/" .. game.GetMap() .. ".txt","data") then
		print("[StormFox]: Loading cached texmap...")
		local materials = util.JSONToTable(file.Read("stormfox/" .. game.GetMap() .. ".txt","DATA"))
		_STORMFOX_ORIGNALTEX = ScanMapTextures(materials)
	else
		print("[StormFox]: Generating texmap (Might take a bit)...")

		local str = file.Read("maps/" .. game.GetMap() .. ".bsp","GAME")
		local materials = {}
		local mats = 0
		for w in string.gmatch( str, "materials/([%d%a_/%-]+).vmt" ) do
			materials[string.lower(w)] = true
			mats = mats + 1
		end
		for w in string.gmatch( str, [["$basetexture"%s-"([%d%a_/%-]+)"]] ) do
			materials[string.lower(w)] = true
			mats = mats + 1
		end
		for w in string.gmatch( str, [["$detail"%s-"([%d%a_/%-]+)"]] ) do
			materials[string.lower(w)] = true
			mats = mats + 1
		end
		for w in string.gmatch( str, [[(%u[%u%d_%-]+/%u[%u%d/_%-]+)]] ) do
			materials[string.lower(w)] = true
			if string.find(string.lower(w),"grass") then --[[print("Digging: " .. string.lower(w))]] end
		end
		local str = util.TableToJSON(materials)
		file.Write("stormfox/" .. game.GetMap() .. ".txt",str)
		LoadTexts(materials)

		_STORMFOX_ORIGNALTEX = ScanMapTextures(materials)
		print("[StormFox]: Saving texmap cache.")
	end
	print("[StormFox]: Texmap loaded (" .. table.Count(_STORMFOX_ORIGNALTEX) .. ").")
end
hook.Add("InitPostEntity","StormFox - MaterialLoader",timer.Simple(2,LoadMapData))
if #player.GetAll() > 0 then timer.Simple(2,LoadMapData) end

local function ReplaceMaterial(str,texture,id)
	if not id then id = 1 end
	-- Save old material
	local mat = str
	if type(str) != "IMaterial" then
		mat = Material(str)
	end
	local parm = "$basetexture" .. (id == 1 and "" or id)
	local currentbase = mat:GetTexture(parm)
	if (currentbase:GetName() or "null") == texture then return end

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
	if l > CurTime() then return end
		l = CurTime() + 5
	local lvl = math.Clamp(StormFox.GetData("SnowMaterial",0),0,3)
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

hook.Add("PlayerFootstep","StormFox - Material Footstep",function( ply, pos, foot, sound, volume, rf ) -- TODO: Move clientside or remove 
	local con = GetConVar("sf_material_replacment")
	if not con:GetBool() then return end
	local lvl = math.Clamp(StormFox.GetData("SnowMaterial",0),0,3)
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
