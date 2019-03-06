--[[-------------------------------------------------------------------------
Texture manager:
	SHARED
		StormFox.TexHandler.Materials() returns a table of generated materials
		StormFox.TexHandler.ApplyMaterial(sGroundMaterial,sGroundType,nLevel) 		-- Tell SF to change the ground to the given varables ( SERVER might override this )
			Diffrent levels:
				0 - None. This will clear all ground-materials.
				1 - Dirt/grass
				2 - Dirt/grass, Roof, Pavement
				3 - Dirt/grass, Roof, Pavement, Road
			sGroundType can be "snow", "rain", "sand" or a special type you added with StormFox.TexHandler.AddTypeMaterial. It will not be affected by nLevel.

	SERVER
		StormFox.TexHandler.Update() Forces clients to update the material data.
		StormFox.TexHandler.AddSnowMaterial(sMaterial, sReplaceMaterial, bDontSaveOrUpdate) 		Replaces a material with sReplaceMaterial when it snows.
		StormFox.TexHandler.AddSandMaterial(sMaterial, sReplaceMaterial, bDontSaveOrUpdate)			Replaces a material with sReplaceMaterial doing a sandstorm.
		StormFox.TexHandler.AddRainMaterial(sMaterial, sReplaceMaterial, bDontSaveOrUpdate)			Replaces a material with sReplaceMaterial doing rain.
		StormFox.TexHandler.AddMapMaterial(sMaterial, nBase_type, nBase2_type, bDontSaveOrUpdate)	Adds a ground material with the given data.
		StormFox.TexHandler.AddTypeMaterial(sType,str,str2,bDontSaveOrUpdate) 						Replaces a material with sReplaceMaterial doing <sType>.
		StormFox.TexHandler.RemoveSnowMaterial(sMaterial, bDontSaveOrUpdate)
		StormFox.TexHandler.RemoveSandMaterial(sMaterial, bDontSaveOrUpdate)
		StormFox.TexHandler.RemoveRainMaterial(sMaterial, bDontSaveOrUpdate)
		StormFox.TexHandler.RemoveMapMaterial(sMaterial, bDontSaveOrUpdate)
		StormFox.TexHandler.RemoveMapMaterial(sType, sMaterial, bDontSaveOrUpdate)

	CLIENT
		StormFox.TexHandler.ClearAll( ignore_table ) 								-- Reset all changed materials. Will ignore all material-paths in the given table.

Hooks:
	SERVER
		StormFox.TexHandler.Preload 			-- Called just before the server has loaded the settings. ( Useful for adding materials. Any added materials will not be saved, but will syncronise with clients ).
		StormFox.TexHandler.Postload 			-- Called after the textures has loaded or changed.
	
	SHARED
		StormFox.footstep 						-- Returns the footstep from an NPC or player; Entity, sSoundName, nFoot
		StormFox.TexHandler.Default 			-- Return a table to add to the "default"-BSP data. This is useful for large amount of data, without the need to send it all to the clients.
			This hook will not be blocked by returned data and that the CLIENT's will not be synchronised with this data from the SERVER. This will only be called once.

Entities:
	env_snowtexture		This list will replace both basetexture and basetexture2 with the target material. It will have priority over env_maptexture.
		PropertyName: Material 		Value: SnowMaterial

	env_raintexture 	The same function as env_snowtexture, but only triggeres doing rain.
	env_sandtexture 	The same function as env_snowtexture, but only triggeres doing sandstorms.
	env_maptextures 	This is a list of outdoor materials that will be replaced with snow/sand or other effects and stop SF from generating the list.
		PropertyName: Material		Value: StringData 		

		Examples of StringData:
			"0;0" tells that basetexture and basetexture2 is type 0. Wich is grass/dirt.
			"1" tells that basetexture is type 1. Wich is roofs.
			";2" tells that basetexture2 is type 2. Wich is roads.
			"3;3" tells that basetexture and basetexture2 is type 3. Wich is pavements.
---------------------------------------------------------------------------]]

local mat_version = 1.1
if SERVER then
	util.AddNetworkString("StormFox-MapSetting")
end
StormFox.TexHandler = {}
	local t = {"snow","map","sand","rain"}

-- Localized functions
	local clamp,max = math.Clamp,math.max
	local file_read = file.Read
	local file_write = file.Write
-- Local variables
	local tex_list 				-- A list of textures generated or read from the map.
	local tex_generated_list = {}
	local tex_setting = {}
	local tex_generated = false
	local tex_blocksaveandload = false

	local NO_TYPE = -1
	local DIRTGRASS_TYPE = 0
	local ROOF_TYPE = 1
	local ROAD_TYPE = 2
	local PAVEMENT_TYPE = 3

	local lvl_list = {}
		lvl_list[0] = {}
		lvl_list[1] = {[DIRTGRASS_TYPE] = true}
		lvl_list[2] = {[DIRTGRASS_TYPE] = true,[ROOF_TYPE] = true,[PAVEMENT_TYPE] = true}
		lvl_list[3] = {[DIRTGRASS_TYPE] = true,[ROOF_TYPE] = true,[PAVEMENT_TYPE] = true,[ROAD_TYPE] = true}
-- Local functions
	local function compress(tab)
		local s = util.TableToJSON(tab)
		return util.Compress(s)
	end
	local function decompress(str)
		local s = util.Decompress(str)
		return util.JSONToTable(s)
	end
	local function CheckEntVars() -- Gathers entity data
		local t = {}
		for _,v in ipairs(StormFox.MAP.Entities()) do
			if v.classname == "env_snowtexture" then
				t["snow"] = t["snow"] or {}
				for t1,t2 in pairs(v) do
					if not string.find(t1,"%/") then continue end
					t["snow"][t1] = t2
				end
			elseif v.classname == "env_sandtexture" then
				t["sand"] = t["sand"] or {}
				for t1,t2 in pairs(v) do
					if not string.find(t1,"%/") then continue end
					t["sand"][t1] = t2
				end
			elseif v.classname == "env_raintexture" then
				t["rain"] = t["rain"] or {}
				for t1,t2 in pairs(v) do
					if not string.find(t1,"%/") then continue end
					t["rain"][t1] = t2
				end
			elseif v.classname == "env_maptextures" then
				t["map"] = t["map"] or {}
				for t1,t2 in pairs(v) do
					if not string.find(t1,"%/") then continue end
					t["map"][t1] = t2
				end
			end
		end
		return t
	end
	local function SplitData(str) -- Splits the string
		local t1,t2 = string.match(str,"^([%d%-]+)") or string.match(str,"basetexture=([%d%-]+)"),string.match(str,";([%d%-]+)") or string.match(str,"basetexture2=([%d%-]+)")
		return t1 or NO_TYPE,t2 or NO_TYPE
	end
	local function GetTextureList() -- Gathers the map data
		if tex_list then return tex_list end
		-- Generate texture list. This is only the map-varables.
		tex_list = {}
		local ent_text = CheckEntVars() -- Check for map-entities and get their texture list.
		-- Map textures.
			if not ent_text["map"] then -- The map doesn't have a maptexture-entity. Generate it from BSP.
				tex_list.map = StormFox.MAP.GenerateTextureTree() or {}
			else -- Phase the list from the entity.
				tex_list.map = {}
				for mat,data in pairs(ent_text["map"]) do
					local t1,t2 = SplitData(data)
					if t1 >= 0 then
						tex_list.map[mat] = {}
						tex_list.map[mat][1] = t1
					end
					if t2 >= 0 then
						tex_list.map[mat] = tex_list.map[mat] or {}
						tex_list.map[mat][2] = t2
					end
				end
			end
		-- Snow textures
			tex_list.snow = ent_text["snow"] or {}
		-- Rain textures
			tex_list.rain = ent_text["rain"] or {}
		-- Sand textures
			tex_list.sand = ent_text["sand"] or {}
		-- Run all the hooks for default-texture
			for _,func in pairs(hook.GetTable()["StormFox.TexHandler.Default"]) do
				table.Merge(tex_list,func() or {})
			end
		return tex_list
	end
	local function Mixer() -- Mix mapdata with mapsettings
		if not tex_list then ErrorNoHalt("Can't mix nil mapdata with settings.") return end
		table.Empty(tex_generated_list)
		tex_generated_list = table.Copy(tex_list)
		for t_type,_ in pairs(tex_setting) do
			if t_type == "version" then continue end
			if t_type == "map" then
				for k,v in pairs(tex_setting[t_type] or {}) do
					local t1,t2 = v[1] or NO_TYPE,v[2] or NO_TYPE
					if t1 <= NO_TYPE and t2 <= NO_TYPE then -- Remove
						tex_generated_list[t_type][k] = nil
					else
						tex_generated_list[t_type][k] = {t1,t2}
					end
				end
			else
				for k,v in pairs(tex_setting[t_type] or {}) do
					if v == "nil" then
						tex_generated_list[t_type][k] = nil
					else
						tex_generated_list[t_type][k] = v
					end
				end
			end
		end
	end
-- SERVER Settings
	if SERVER then
		function StormFox.TexHandler._LoadSettings() -- Check if the current data is valid
			if file.Exists("stormfox/maps/" .. game.GetMap() .. ".txt","DATA") then
				local f_data = file_read("stormfox/maps/" .. game.GetMap() .. ".txt","DATA")
				local data = util.JSONToTable(f_data)
				if not data then
					StormFox.Msg("Corrupt mapdata detected. Deleting")
					file.Delete("stormfox/maps/" .. game.GetMap() .. ".txt")
					return false
				elseif (data.version or 0) < mat_version then
					StormFox.Msg("Old mapdata detected. Deleting ..")
					file.Delete("stormfox/maps/" .. game.GetMap() .. ".txt")
					return false
				end
				tex_setting = data
				StormFox.Msg("Mapdata V" .. tex_setting.version)
				return true
			else
				return false
			end
		end
		function StormFox.TexHandler._SaveSettings() -- Save the settings
			tex_setting.version = mat_version
			file_write("stormfox/maps/" .. game.GetMap() .. ".txt",util.TableToJSON(tex_setting))
		end
	end
-- SHARED
	function StormFox.TexHandler.Materials()
		return tex_generated_list
	end
	function StormFox.TexHandler._MatSettings()
		return tex_setting
	end
	function StormFox.TexHandler.GetAppliedMaterial()
		return StormFox.GetNetworkData("GroundTexture",nil),StormFox.GetNetworkData("GroundType",nil),StormFox.GetNetworkData("GroundLevel",0)
	end
-- Sync settings and changes
	hook.Add("StormFox.PostEntity","LoadMapTextures",function()
		if SERVER then
			local t = GetTextureList() -- Generate the texture list.
			StormFox.TexHandler._LoadSettings()
			if not t then error("Unable to gather BSP-data.") end
			tex_blocksaveandload = true -- Since this is called by Lua and at launch, we should not save or update changes.
			hook.Run("StormFox.TexHandler.Preload")
			tex_blocksaveandload = false
			Mixer()
			hook.Run("StormFox.TexHandler.Postload")
		else -- Request the texture-settings
			net.Start("StormFox-MapSetting")
			net.SendToServer()
		end
	end)
	if SERVER then
		local tickets = {}
		net.Receive("StormFox-MapSetting",function(len,ply)
			if tickets[ply] then return end -- 1 ticket pr person.
			tickets[ply] = true
			net.Start("StormFox-MapSetting")
				local s = compress(tex_setting)
				net.WriteInt(string.len(s),24)
				net.WriteData(s,string.len(s))
			net.Send(ply)
		end)
	else
		net.Receive("StormFox-MapSetting",function(len)
			local len = net.ReadInt(24)
			local data = net.ReadData(len)
			tex_setting = decompress(data)
			GetTextureList()
			Mixer()
			hook.Run("StormFox.TexHandler.Postload")
			tex_generated = true
			local a,b,c = StormFox.TexHandler.GetAppliedMaterial()
			StormFox.TexHandler.ApplyMaterial(a,b,c)
		end)
		hook.Add("StormFox - NetDataChange","StormFox.TexHandler.Updater",function(key,var)
			if not tex_generated then return end -- We don't have any data.
			if key ~= "GroundKey" then return end
			local a,b,c = StormFox.TexHandler.GetAppliedMaterial()
			StormFox.TexHandler.ApplyMaterial(a,b,c)
		end)
	end
-- SERVER
	if SERVER then
		STORMFOX_ORIGINAL_MAT = STORMFOX_ORIGINAL_MAT or {}
		function StormFox.TexHandler.Update()
			Mixer()
			net.Start("StormFox-MapSetting")
				local s = compress(tex_setting)
				net.WriteInt(string.len(s),24)
				net.WriteData(s,string.len(s))
			net.Broadcast()
			hook.Run("StormFox.TexHandler.Postload")
			local a,b,c = StormFox.TexHandler.GetAppliedMaterial()
			StormFox.TexHandler.ApplyMaterial(a,b,c)
		end
		-- Add materials
			function StormFox.TexHandler.AddSnowMaterial(str,str2,bDontSaveOrUpdate)
				tex_setting.snow = tex_setting.snow or {}
				tex_setting.snow[str:lower()] = str2:lower()
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.AddSandMaterial(str,str2,bDontSaveOrUpdate)
				tex_setting.sand = tex_setting.sand or {}
				tex_setting.sand[str:lower()] = str2:lower()
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.AddRainMaterial(str,str2,bDontSaveOrUpdate)
				tex_setting.rain = tex_setting.rain or {}
				tex_setting.rain[str:lower()] = str2:lower()
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.AddTypeMaterial(sType,str,str2,bDontSaveOrUpdate)
				if not sType then return end
				tex_setting.sType = tex_setting.sType or {}
				tex_setting.sType[str:lower()] = str2:lower()
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.AddMapMaterial(str,base_type,base2_type,bDontSaveOrUpdate)
				tex_setting.map = tex_setting.map or {}
				tex_setting.map[str:lower()] = {base_type or NO_TYPE,base2_type or NO_TYPE}
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
		-- Remove materials (This is a bit tricky, as map materials have to be overwriten)
			function StormFox.TexHandler.RemoveSnowMaterial(str,bDontSaveOrUpdate)
				tex_setting.snow = tex_setting.snow or {}
				if tex_list.snow[str:lower()] then
					tex_setting.snow[str:lower()] = "nil"
				else
					tex_setting.snow[str:lower()] = nil
				end
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.RemoveSandMaterial(str,bDontSaveOrUpdate)
				tex_setting.sand = tex_setting.sand or {}
				if tex_list.sand[str:lower()] then
					tex_setting.sand[str:lower()] = "nil"
				else
					tex_setting.sand[str:lower()] = nil
				end
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.RemoveRainMaterial(str,bDontSaveOrUpdate)
				tex_setting.rain = tex_setting.rain or {}
				if tex_list.rain[str:lower()] then
					tex_setting.rain[str:lower()] = "nil"
				else
					tex_setting.rain[str:lower()] = nil
				end
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.RemoveTypeMaterial(sType,str,bDontSaveOrUpdate)
				tex_setting.sType = tex_setting.sType or {}
				if tex_list.sType[str:lower()] then
					tex_setting.sType[str:lower()] = "nil"
				else
					tex_setting.sType[str:lower()] = nil
				end
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
			function StormFox.TexHandler.RemoveMapMaterial(str,bDontSaveOrUpdate)
				tex_setting.map = tex_setting.map or {}
				str = str:lower()
				if tex_list.map[str] then
					tex_setting.map[str] = {NO_TYPE,NO_TYPE}
				else
					tex_setting.map[str] = nil
				end
				if not bDontSaveOrUpdate and not tex_blocksaveandload then
					StormFox.TexHandler._SaveSettings()
					StormFox.TexHandler.Update()
				end
			end
		-- Applier ( Tell SF to change the ground to the given varables )
			function StormFox.TexHandler.ApplyMaterial(mat_replace,sGroundType,level,tFootstep_sounds)
				if sGroundType == "map" then error("Invalid sGroundType!") return end
				if sGroundType == "foliage" then error("Invalid sGroundType!") return end
				-- Network
					StormFox.SetNetworkData("GroundTexture",mat_replace or nil)
					StormFox.SetNetworkData("GroundType",sGroundType or nil)
					StormFox.SetNetworkData("GroundLevel",level or 0)
					StormFox.SetNetworkData("GroundSound",tFootstep_sounds or nil)
					StormFox.SetNetworkData("GroundKey",CurTime()) -- Doesn't really matter, this tells the client that data changed.
				-- The server don't need to change the material .. but we need to list them
					table.Empty(STORMFOX_ORIGINAL_MAT)
					local rep_tex = {}
					if sGroundType and tex_generated_list[sGroundType] then
						for str,mat_rep in pairs(tex_generated_list[sGroundType]) do
							if not mat_rep then continue end -- Nothing to replace the material with.
							STORMFOX_ORIGINAL_MAT[str] = true
						end
					end
				-- Replace the "ground"
					if mat_replace and tex_generated_list.map then
						if not level then level = 1 end
						level = math.Round(level)
						level = clamp(level,0,3)
						local allowed = lvl_list[level]
						for str,data in pairs(tex_generated_list.map) do
							if table.HasValue(rep_tex,str) then continue end -- We already replaced them in texture-type.
							local t1,t2 = data[1] or NO_TYPE,data[2] or NO_TYPE
							if not allowed[t1] then t1 = nil else t1 = mat_replace end
							if not allowed[t2] then t2 = nil else t2 = mat_replace end
							if t1 or t2 then
								STORMFOX_ORIGINAL_MAT[str] = true
							end
						end
					end
			end
			StormFox.TexHandler.ApplyMaterial() -- Clear any old texture, in case the script reloads
	end
-- CLIENT
	if CLIENT then
		STORMFOX_ORIGINAL_MAT = STORMFOX_ORIGINAL_MAT or {}
		STORMFOX_REPLACED_MAT = STORMFOX_REPLACED_MAT or {}
		local replace_textures = {"$basetexture","$basetexture2","$selfillummask"}
		local replace_strs = {"$selfillummask"}
		-- Local functions
			local function getTexture(mat,tax)
				if not mat then return end
				local t1 = mat:GetTexture(tax)
				if not t1 then return end
				local str
				if t1 then
					str = t1:GetName() or ""
					if #str < 1 then str = "Black" end
				end
				return str
			end
			local function saveMat(str)
				if STORMFOX_ORIGINAL_MAT[str] then return end
				STORMFOX_ORIGINAL_MAT[str] = {}
				local mat = Material(str)
				for _,tex in ipairs(replace_textures) do
					STORMFOX_ORIGINAL_MAT[str][tex] = getTexture(mat,tex)
				end
				for _,tex in ipairs(replace_strs) do
					STORMFOX_ORIGINAL_MAT[str][tex] = mat:GetString(tex)
				end
			end
			local function restoreMat(str)
				if not STORMFOX_ORIGINAL_MAT[str] then return end
				local mat = Material(str)
				for _,tex in ipairs(replace_textures) do
					if not STORMFOX_ORIGINAL_MAT[str][tex] then continue end
					mat:SetTexture(tex,STORMFOX_ORIGINAL_MAT[str][tex] or "Black")
				end
				for _,tex in ipairs(replace_strs) do
					if not STORMFOX_ORIGINAL_MAT[tex] then continue end
					mat:SetInt(tex,STORMFOX_ORIGINAL_MAT[str][tex])
				end
				STORMFOX_ORIGINAL_MAT[str] = nil
			end
			local function setMat(str,tex1,tex2)
				restoreMat(str)
				saveMat(str)
				local mat = Material(str)
				if tex1 then
					mat:SetTexture("$basetexture",tex1)
				end
				if tex2 then
					mat:SetTexture("$basetexture2",tex2)
				end
			end
			local function setMatFromMat(str,rep_str)
				local rep = Material(rep_str)
				setMat(str,rep:GetTexture("$basetexture"),rep:GetTexture("$basetexture2"))
			end
		-- Functons
			function StormFox.TexHandler.ClearAll(ignore_table)
				for str,_ in pairs(STORMFOX_ORIGINAL_MAT) do
					if ignore_table and table.HasValue(ignore_table,str) then
						continue
					end
					restoreMat(str)
				end
			end
			function StormFox.TexHandler.GetOriginial(str)
				if not STORMFOX_ORIGINAL_MAT[str] then return end
				return STORMFOX_ORIGINAL_MAT[str]["$basetexture"]
			end
			-- In case we reload the script and the ground has changed.
				StormFox.TexHandler.ClearAll()
			function StormFox.TexHandler.ApplyMaterial(mat_replace,sGroundType,lvl)
				if not tex_generated_list then return false end -- We don't know what materials to replace. Ignore.
				if sGroundType == "map" then error("Invalid sGroundType!") return end
				local mat
				if type(mat_replace) == "string" then
					if string.match(mat_replace,".png$") then
						mat = Material(mat_replace,"noclamp smooth")
						mat_replace = Mat:GetTexture("$basetexture")
					else
						mat = Material(mat_replace)
						mat_replace = mat:GetTexture("$basetexture")
					end
				elseif type(mat_replace) == "IMaterial" then
					mat = mat_replace
					mat_replace = mat_replace:GetTexture("$basetexture")
				end

				local rep_tex = {}
				-- Replace the type
					if sGroundType and tex_generated_list[sGroundType] then
						for str,mat_rep in pairs(tex_generated_list[sGroundType]) do
							if not mat_rep then continue end -- Nothing to replace the material with.
							table.insert(rep_tex,str)
							setMatFromMat(str,mat_rep)
						end
					end
				-- Replace the ground
					if mat_replace and tex_generated_list.map then
						if not lvl then lvl = 1 end
						lvl = math.Round(lvl)
						lvl = clamp(lvl,0,3)
						local allowed = lvl_list[lvl]
						for str,data in pairs(tex_generated_list.map) do
							if table.HasValue(rep_tex,str) then continue end -- We already replaced them in texture-type.
							local t1,t2 = data[1] or NO_TYPE,data[2] or NO_TYPE
							if not allowed[t1] then t1 = nil else t1 = mat_replace end
							if not allowed[t2] then t2 = nil else t2 = mat_replace end
							if t1 or t2 then
								table.insert(rep_tex,str)
								setMat(str,t1,t2)
							end
						end
					end
				-- Clear all unchanged materials
					StormFox.TexHandler.ClearAll(rep_tex)
			end
	end
--[[-------------------------------------------------------------------------
Footstep Sound
Since we change the material, we need to change the sound as well
---------------------------------------------------------------------------]]
	-- IsNextbot
		local NEXTBOT = FindMetaTable("NextBot")
		local function IsNextbot(ent)
			if SERVER then
				return getmetatable(ent) == NEXTBOT
			else
				return ent.Base == "base_nextbot"
			end
		end
	-- Local functions
		local function IsReplaced(str)
			return STORMFOX_ORIGINAL_MAT[str:lower()] and true or false
		end
		local function ETHull(ent,pos,pos2,min,max)
			local filter = ent
			if ent.GetViewEntity then
				filter = ent:GetViewEntity()
			end
			local t = util.TraceHull( {
				start = pos,
				endpos = pos + pos2,
				maxs = max,
				mins = min,
				collisiongroup = ent:GetCollisionGroup(),
				filter = filter
			} )
			t.HitPos = t.HitPos or (pos + pos2)
			return t
		end
		local function EntTraceTexture(ent) -- Returns the texture the entity is "on"
			local mt = ent:GetMoveType()
			if mt < 2 or mt > 3 then return end
			local mins,maxs = ent:OBBMins(),ent:OBBMaxs()
			local h = maxs.z - mins.z
			local t = ETHull(ent,ent:GetPos() + ent:OBBCenter(),Vector(0,0,-h / 2 - 20),Vector(mins.x,mins.y,-5),Vector(maxs.x,maxs.y,5))
			if not t.Hit then return end -- flying
			return t.HitTexture
		end
		local function ShouldReplaceSound(sTexture,sound,isNPCFootKnown) -- Given the texture and sound, return true if it should be replaced.
			if not sTexture then return false end
			if IsReplaced(sTexture) then return true end
			local mat = Material(sTexture)
			if not mat then return false end
			local mat_name = mat:GetName()
			if mat_name == "___error" then
				if sound and (string.find(sound,"dirt") or string.find(sound,"grass")) or isNPCFootKnown then
					return true
				else
					return false
				end
			end
			return false
		end
		local function GetGroundFootsteps()
			return StormFox.GetNetworkData("GroundSound",nil)
		end
	-- Fixes
		local lastFoot = {}
		local canTrigger = {}
		hook.Add("PlayerFootstep","StormFox.TexHandler.Footstep",function( ply, pos, foot, sound, volume, rf )
			lastFoot[ply] = foot
			canTrigger[ply] = true
		end)
	-- Hooks
		local unknown = {}
		local npclast = {}
		hook.Add("EntityEmitSound","StormFox.Footstep.Detect",function(data)
			-- Get sound data
				local ent = data.Entity
				local snd = data.SoundName:lower()
				local originalS = data.OriginalSoundName:lower()
				local foot = lastFoot[ent] or -1
			-- Check if entity is valid
				if not IsValid(ent) then return end
				if ent:IsWorld() then return end
				local npc = false
			-- Check if its a player or NPC and if the sound is a footstep.		
				if ent:IsPlayer() then
					if not canTrigger[ent] then return end -- E2s and other addons can play sounds on players. This will allow it to only be triggered doing footsteps.
					if not string.match(snd,"footstep") and not string.match(originalS,"footstep") then return end -- No footloose
					canTrigger[ent] = false
				elseif ent:IsNPC() or IsNextbot(ent) then
					if (canTrigger[ent] or 0) > CurTime() then return end -- This is a simple 0.4 timer to prevent abuse.
					canTrigger[ent] = CurTime() + 0.4
					if not string.match(snd,"foot") and not string.match(originalS,"foot") then return end -- No footloose
					npc = true
				else
					return
				end
			-- Figure out what foot is being triggered
				if foot < 0 then
					if originalS and (string.match(originalS,"stepleft") or string.match(originalS,"stepright")) then
						foot = string.match(originalS,"left") and 0 or 1
					else -- In case we get no result. Make one up.
						if unknown[ent] then
							foot = 1
							unknown[ent] = nil
						else
							unknown[ent] = true
							foot = 0
						end
					end
				end
			-- Check if we know this is a known NPC footstep.
				local knownfoot = npc and (foot >= 0 or (string.match(snd,"footstep") or string.match(snd,"_step%d+.wav$") or string.match(snd,"foot%d+.wav")))
			-- Some NPC's seems to be born with two left feet when running.
				if npc then
					if npclast[ent] and npclast[ent] == foot then
						foot = 1 - foot
					end
					npclast[ent] = foot
				end
			-- Should we replace it?
				local sound_table = GetGroundFootsteps()
				local replaced = nil
				local tex = EntTraceTexture(ent)
				if tex then
					if ShouldReplaceSound(tex,snd,knownfoot) then
						if sound_table then
							data.SoundName = table.Random(sound_table)
							replaced = true
						end
						if StormFox.Weather:GetData("OnGroundWalk") then
							StormFox.Weather:GetData("OnGroundWalk")(ent,tex,data.SoundName)
						end
					end
				end
			-- This is a footstep. Call hook. This is for snow footsteps .. ect.
				hook.Run("StormFox.Footstep",ent,data.SoundName,foot)
			-- This hook won't be called clientside in singleplayer
				if SERVER and game.SinglePlayer() then
					net.Start("StormFox.FeetFix")
						net.WriteEntity(ent)
						net.WriteString(data.SoundName)
						net.WriteInt(foot,2)
					net.Broadcast()
				end
			return replaced
		end)
		-- Feet fix in singleplayer
		if game.SinglePlayer() then
			if SERVER then
				util.AddNetworkString("StormFox.FeetFix")
			else
				net.Receive("StormFox.FeetFix",function()
					local ent,snd,foot = net.ReadEntity(),net.ReadString(),net.ReadInt(2)
					hook.Run("StormFox.Footstep",ent,snd,foot)
				end)
			end
		end
--[[-------------------------------------------------------------------------
Wind Texture
---------------------------------------------------------------------------]]
	local lw,lwa = -1,-1
	local conset = true
	timer.Create("StormFox.WindController",1,0,function()
		local con = GetConVar("sf_foliagesway")
		if con:GetInt() ~= 1 then
			if conset then
				RunConsoleCommand("cl_tree_sway_dir",0,0)
				conset = false
				lw,lwa = -1,-1
			end
			return
		end
		conset = true
		local nw = StormFox.GetNetworkData( "Wind", 0 ) * 4
		local nwa = StormFox.GetNetworkData( "WindAngle", 0 )
		if lw == nw and nwa == lwa then return end -- same as last time
		local ra = math.rad(nwa)
		local wx,wy = math.cos(ra) * nw,math.sin(ra) * nw
		RunConsoleCommand("cl_tree_sway_dir",wx,wy)
		lw = nw
		lwa = nwa
	end)
--[[-------------------------------------------------------------------------
Tree Texture
---------------------------------------------------------------------------]]
	if CLIENT then -- Only clients need to do this
		STORMFOX_REPLACED_TREE = STORMFOX_REPLACED_TREE or {}
		function StormFox.TexHandler.SetFoliageData(texture,foliage_type,bendyness,mat_height,wave_speed)
			if not texture then return end
			if not wave_speed then wave_speed = 0 end
			if not bendyness then bendyness = 1 end
			if not mat_height then mat_height = 0 end
			local mat = Material(texture)
			if mat:IsError() then return end -- This client don't know what the material this is
			-- Enable / Disable the material
				if foliage_type < -1 then
					mat:SetInt("$treeSway",0)
					return
				end
				mat:SetInt("$treeSway",1) -- 0 is no sway, 1 is classic tree sway, 2 is an alternate, radial tree sway effect.
			-- 'Default' settings
				mat:SetFloat("$treeswayspeed",2)					-- The treesway speed	
				mat:SetFloat("$treeswayspeedlerpstart",1000) 		-- Sway starttime	
			-- Default varables I don't know what do or doesn't have much to do with cl_tree_sway_dir
				mat:SetFloat("$treeswayscrumblefalloffexp",3)
				mat:SetFloat("$treeswayspeedhighwindmultiplier",0.2)
				mat:SetFloat("$treeswaystartradius",0)
				mat:SetFloat("$treeswayscrumblefrequency",6.6)
				mat:SetFloat("$treeswayspeedlerpend",2500 * bendyness)
			-- Special varables
			if foliage_type == -1 then --Trunk
				mat:SetFloat("$treeSwayStartHeight",mat_height)				-- When it starts to sway
				mat:SetFloat("$treeswayheight",max(700 - bendyness * 100,0)) 				-- << How far up before XY starts to matter
				mat:SetFloat("$treeswayradius",max(110 - bendyness * 10,0))					-- ?
				mat:SetFloat("$treeswayscrumblespeed",3 + (wave_speed or 0))			-- ?
				mat:SetFloat("$treeswayscrumblestrength",0.1 * bendyness)			-- "Strechyness" 
				mat:SetFloat("$treeswaystrength",0) 				-- "Strechyness" 
			elseif foliage_type == 0 then -- Trees
				mat:SetFloat("$treeSwayStartHeight",mat_height)				-- When it starts to sway
				mat:SetFloat("$treeswayheight",max(700 - bendyness * 100,0)) 				-- << How far up before XY starts to matter
				mat:SetFloat("$treeswayradius",max(110 - bendyness * 10,0))					-- ?
				mat:SetFloat("$treeswayscrumblespeed",3 + (wave_speed or 0) )			-- ?
				mat:SetFloat("$treeswayscrumblestrength",0.1 * bendyness)			-- "Strechyness" 
				mat:SetFloat("$treeswaystrength",0) 				-- ?
			elseif foliage_type == 1 then -- Leaves
				mat:SetFloat("$treeSwayStartHeight",0.5 + mat_height / 2)
				mat:SetFloat("$treeswayheight",8)
				mat:SetFloat("$treeswayradius",1)
				mat:SetFloat("$treeswayscrumblespeed",1 + (wave_speed or 0))
				mat:SetFloat("$treeswayscrumblestrength",0.1)
				mat:SetFloat("$treeswaystrength",0.06 * bendyness)
			else
				mat:SetFloat("$treeSwayStartHeight",0.1 + mat_height / 10)
				mat:SetFloat("$treeswayheight",8)
				mat:SetFloat("$treeswayradius",1)
				mat:SetFloat("$treeswayscrumblespeed",wave_speed or 0)
				mat:SetFloat("$treeswayscrumblestrength",0)
				mat:SetFloat("$treeswaystrength",0.05 * bendyness)
			end
		end
		hook.Add("StormFox.TexHandler.Postload","StormFox.TexHandler.TreeApplier",function()
			local tab = StormFox.TexHandler.Materials() or {}
			if not tab.foliage then return end -- No foliage data
			-- Remove tree materials
				for texture,_ in pairs(STORMFOX_REPLACED_TREE) do
					if not tab.foliage[texture] then
						StormFox.TexHandler.SetFoliageData(texture,-2)
						STORMFOX_REPLACED_TREE[texture] = nil
					end
				end
			-- Apply new tree materials
				for texture,data in pairs(tab.foliage) do
					if not data or #data < 1 then continue end
					if data[1] < -1 then
						StormFox.TexHandler.SetFoliageData(texture,-2)
						STORMFOX_REPLACED_TREE[texture] = nil
					else
						StormFox.TexHandler.SetFoliageData(texture,unpack(data))
						STORMFOX_REPLACED_TREE[texture] = true
					end
				end
		end)
	end

--[[-------------------------------------------------------------------------
Old map-data
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

---------------------------------------------------------------------------]]