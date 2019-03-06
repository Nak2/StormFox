
local mat_table = {}
-- Mat data
	net.Receive("StormFox - mapdata",function(_)
		local len = net.ReadInt(24)
		local data = net.ReadData(len)
		local json = util.Decompress(data)
		mat_table = util.JSONToTable(json)
		if not mat_table then
			StormFox.Msg("sf_mapdata_invalid")
		else
			StormFox.Msg("sf_mapdata_load")
		end
		hook.Call("StormFox.mapdata.receive")
	end)
	timer.Simple(1,function()
		net.Start("StormFox - mapdata")
			net.WriteBool(true)
		net.SendToServer()
	end)

	function StormFox.GetMapMaterials()
		return mat_table
	end

-- WindMat
	STORMFOX_ORIGINAL_TREE = STORMFOX_ORIGINAL_TREE or {}
	local function SetTree(str,data)
		if not data then ErrorNoHalt("Missing treedata") return end
		STORMFOX_ORIGINAL_TREE[str] = true
		local m = Material(str)
		if m:IsError() then return end
		if m:GetShader() ~= "VertexLitGeneric" then return end -- current supported shader
		if m:GetString("$bumpmap") then return end -- will break it
		local height = data.height or 0
		local wavy = data.wavy or (is_branch and 3 or 1)
		local strengh = data.strengh or (height>0.5 and 1 or 0.6)
		m:SetInt("$treeSway",1)
		m:SetFloat("$treeSwayHeight",8)
		m:SetFloat("$treeSwayStartHeight",height)
		m:SetFloat("$treeSwayRadius",1)
		m:SetFloat("$treeSwayStartRadius",height)
		m:SetFloat("$treeSwaySpeed",2)
		m:SetFloat("$treeSwayStrength",strengh / 10)
		m:SetFloat("$treeSwayScrumbleSpeed",wavy) -- "Wavy"
		m:SetFloat("$treeSwayScrumbleStrength",wavy * 0.06)
		m:SetFloat("$treeSwayScrumbleFrequency",wavy * 6.66) -- "wavy"
		m:SetFloat("$treeSwayFalloffExp",2)
		m:SetFloat("$treeSwayScrumbleFalloffExp",3)
		m:SetFloat("$treeSwaySpeedHighWindMultiplier",.2)
		m:SetFloat("$treeSwaySpeedLerpStart",1000.0)
		m:SetFloat("$treeSwaySpeedLerpEnd",2500.0)
		m:Recompute()
		return true
	end
	local function CleanTree(str)
		local m = Material(str)
		if m:IsError() then return end
		if m:GetShader() ~= "VertexLitGeneric" then return end
		m:SetFloat("$treeSway",0)
		m:Recompute()
	end
	local t_id,state = -1,-1
	local t_key = {}
	timer.Create("StormFox.TreeApplier",0.01,0,function()
		if not mat_table.tree then return end
		if t_id <= -1 then return end
		if state <= -1 then return end
		local mat = t_key[t_id]
		SetTree(mat,mat_table.tree[mat])

		t_id = t_id +1
		if t_id > table.Count(mat_table.tree) then
			t_id = -1
		end
	end)
	local function ApplyTrees(tab)
		if not tab then return end
		t_key = table.GetKeys(tab)
		state = 1
		t_id = 1
	end

-- Material replacment
	STORMFOX_ORIGINAL_MAT = STORMFOX_ORIGINAL_MAT or {}
	local changedTextures = {}
	-- Small functions
		local function saveMat(mat,data)
			if STORMFOX_ORIGINAL_MAT[mat] then return end
			local m = Material(mat)
			STORMFOX_ORIGINAL_MAT[mat] = {}
			if data[1] and m:GetTexture("$basetexture") then
				STORMFOX_ORIGINAL_MAT[mat][1] = m:GetTexture("$basetexture"):GetName()
			end
			if data[2] and m:GetTexture("$basetexture2") then
				STORMFOX_ORIGINAL_MAT[mat][2] = m:GetTexture("$basetexture2"):GetName()
			end
		end
		local function cleanupMat(mat)
			if not STORMFOX_ORIGINAL_MAT[mat] then return false end
			local m = Material(mat)
			local data = STORMFOX_ORIGINAL_MAT[mat]
			if data[1] then
				m:SetTexture("$basetexture",data[1])
			end
			if data[2] then
				m:SetTexture("$basetexture2",data[2])
			end
			-- Need to run twice
			if data[1] then
				m:SetTexture("$basetexture",data[1])
			end
			if data[2] then
				m:SetTexture("$basetexture2",data[2])
			end
			return true
		end
		local function setMat(mat,tex,data_type,allowed)
			if not STORMFOX_ORIGINAL_MAT[mat] then ErrorNoHalt("Material is not backed up. This should not happen.") return end
			local m = Material(mat)
			local data = STORMFOX_ORIGINAL_MAT[mat]
			if data[1] then
				if allowed[data_type[1] or "grass"] then
					changedTextures[mat] = {data_type[1] or "grass"}
					m:SetTexture("$basetexture",tex)
				else
					cleanupMat(mat)
				end
			end
			if data[2] then
				if allowed[data_type[2] or "grass"] then
					if not changedTextures[mat] then
						changedTextures[mat] = {}
					end
					table.insert(changedTextures[mat],data_type[2] or "grass")
					m:SetTexture("$basetexture2",tex)
				else
					cleanupMat(mat)
				end
			end
			-- Need to run twice
				if data[1] then
					if allowed[data_type[1] or "grass"] then
						m:SetTexture("$basetexture",tex)
					end
				end
				if data[2] then
					if allowed[data_type[2] or "grass"] then
						m:SetTexture("$basetexture2",tex)
					end
				end
		end
		local function getOriginalMat(mat)
			return STORMFOX_ORIGINAL_MAT[mat]
		end

	local current_override = ""
	local allowed_type = {}
		allowed_type[0] = {}
		allowed_type[1] = {["grass"] = true}
		allowed_type[2] = {["grass"] = true,["roof"] = true,["pavement"] = true}
		allowed_type[3] = {["grass"] = true,["roof"] = true,["pavement"] = true,["road"] = true}
	local cacheSnd = {}
	local function SetGroundMaterial(str,lvl)
		if not mat_table.material then return false end
		current_override = str
		--print("Mat-replace",str,lvl)
		if not str then str = "" end
		if lvl == 0 then str = "" end -- 0 = none
		if str ~= "" and StormFox.GetMapSetting("replace_dirtgrassonly",false) then
			lvl = 1
		end
		local cur_type = allowed_type[lvl] or {}
		table.Empty(changedTextures)
		table.Empty(cacheSnd)
		if type(str) == "table" then
			for mat,data in pairs(mat_table.material) do
				saveMat(mat,data)
				local tex = table.Random(str)
				setMat(mat,tex,data,cur_type)
			end
		elseif str == "" or str == "nil" then
			for mat,data in pairs(mat_table.material) do
				cleanupMat(mat,data)
			end
		else
			for mat,data in pairs(mat_table.material) do
				saveMat(mat,data)
				setMat(mat,str,data,cur_type)
			end
		end
		return true
	end

-- Sound
	local function checkSnd(mat)
		if not mat_table.material then return false end
		if not current_override then return false end
		if current_override == "" or current_override == "nil" then return false end
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
		if changedTextures[mat] or changedTextures[t1] or changedTextures[t2] then
			result = true
		end
		cacheSnd[mat] = result
		return cacheSnd[mat]
	end
	local function ETHull(ent,pos,pos2,min,max,mask)
		max.z = 0
		local filter = ent
		if ent.GetViewEntity then
			filter = ent:GetViewEntity()
		end
		local t = util.TraceHull( {
		start = pos,
		endpos = pos + pos2,
		maxs = max,
		mins = min,
		mask = mask,
		filter = filter
		} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end
	local currentMaterial,currentLvl = "nil",0
	local function DataChanged(mat,lvl)
		local checkMat = mat or "nil"
		if type(mat) == "table" then
			checkMat = mat[1]
		end
		if currentMaterial == checkMat and currentLvl == lvl then return false end -- No change
			currentMaterial = checkMat
			currentLvl = lvl
		table.Empty(cacheSnd)
		return true -- Material or lvl changed
	end
	local allowed_type = {}
		allowed_type[0] = {}
		allowed_type[1] = {["grass"] = true}
		allowed_type[2] = {["grass"] = true,["roof"] = true,["pavement"] = true}
		allowed_type[3] = {["grass"] = true,["roof"] = true,["pavement"] = true,["road"] = true}

	local function ShouldOverrideSound(ply,sound)
		local lvl = StormFox.GetNetworkData("Ground_MaterialLvl",0)
		if lvl <= 0 then return false end -- No materials changed
		-- Player hullTrace
			local mz = ply:OBBMins().z
			local t = ETHull(ply,ply:GetPos() + Vector(0,0,20),Vector(0,0,-(mz + 45)),ply:OBBMins(),ply:OBBMaxs())
			if not t.Hit then return false end -- Flying
		-- Get material type
			local mat = Material(t.HitTexture)
			local mat_name = mat:GetName()
			-- In case of nil
				if mat_name == "___error" then -- Often the "ground" material. Check for dirt and grass sounds
					if string.find(sound,"dirt") or string.find(sound,"grass") then
						return true
					end
					return false
				end
		-- Check if its a replaced material
			if not mat_table then return false end -- Invalid material table
			if not mat_table.material then return false end -- Invalid material
			return checkSnd(mat_name,lvl)
	end

	-- PlayerFootstep is only for players. But we still need some data
		local lastFoot = {}
		hook.Add("PlayerFootstep","StormFox - Material Footstep",function( ply, pos, foot, sound, volume, rf )
			lastFoot[ply] = foot
		end)
	-- Hook into emitsound
		local unknown = {}
		hook.Add("EntityEmitSound","StormFox - Footstep",function(data)
			-- Check if its a footstep sound and what foot
				-- Gather sound data
					local ent = data.Entity
					local snd = data.SoundName
					local originalS = data.OriginalSoundName
					local foot = lastFoot[ent] or -1
				if not string.match(snd,"footstep") then return end -- No footloose
				if not IsValid(ent) then return end
				if ent:IsWorld() then return end
				-- NPC info
					if originalS and (string.match(originalS,"stepleft") or string.match(originalS,"stepright")) then
						foot = string.match(originalS,"left") and 0 or 1
					end
				-- Unknown feet
					if foot == -1 then
						if unknown[ent] then
							foot = 1
							unknown[ent] = nil
						else
							unknown[ent] = true
							foot = 0
						end
					end
			-- Check if materialsounds got replaced
				local overridesnd = StormFox.GetNetworkData("Ground_Material_Snd","nil")
				if not overridesnd then 
					hook.Run("StormFox - Footstep",ent,snd,foot) 
					return
				end
			-- Check if we should override
				local succ = ShouldOverrideSound(ent,snd)
				if not succ then
					hook.Run("StormFox - Footstep",ent,snd,foot) 
					return
				end
			-- Override sound
				data.SoundName = table.Random(overridesnd)
				hook.Run("StormFox - Footstep",ent,data.SoundName,foot)
			return true
		end)
	-- So .. singleplayer don't call EntityEmitSound
		if game.SinglePlayer() then
			net.Receive("StormFox.FeetFix",function()
				local snd = net.ReadString()
				local bool = net.ReadBool()
				hook.Run("StormFox - Footstep",LocalPlayer(),snd,bool and 1 or 0)
			end)
		end

-- Controller
	local lw,lwa = -1,-1
	local conset = true
	
	timer.Create("StormFox - WindC",1,0,function()
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
		local nw = StormFox.GetNetworkData( "Wind", 0 ) * 3
		local nwa = StormFox.GetNetworkData( "WindAngle", 0 )
		if lw == nw and nwa == lwa then return end -- same as last time
		local ra = math.rad(nwa)
		local wx,wy = math.cos(ra) * nw,math.sin(ra) * nw
		RunConsoleCommand("cl_tree_sway_dir",wx,wy)
		lw = nw
		lwa = nwa
	end)
	hook.Add("StormFox.mapdata.receive","StormFox.mapdata.setup",function()
		if table.Count(STORMFOX_ORIGINAL_MAT) > 0 then
			StormFox.Msg("sf_mapdata_cleanup")
			SetGroundMaterial("")
		end
		if table.Count(STORMFOX_ORIGINAL_TREE) > 0 and mat_table.tree then
			local t = false
			for tex,_ in pairs(STORMFOX_ORIGINAL_TREE) do
				if not mat_table.tree[tex] then
					if not t then
						t = true
					end
					CleanTree(tex)
					STORMFOX_ORIGINAL_TREE[tex] = nil
				end
			end
		end
		ApplyTrees(mat_table.tree)
	end)
	local function MaterialReplacementThink()
		-- Is material data valid?
			if not mat_table.material then return end
			if table.Count(mat_table.material) <= 0 then return end
		-- Get data
			local mat = StormFox.GetNetworkData("Ground_Material","nil")
			local lvl = StormFox.GetNetworkData("Ground_MaterialLvl",0)
		-- Check if data changed
			if not DataChanged(mat,lvl) then return end
		SetGroundMaterial(mat,lvl)
	end
	hook.Add("StormFox - NetDataChange","StormFox - MoonSmooth",function(var,day)
		if var ~= "Ground_Material" then return end
		MaterialReplacementThink()
	end)
	timer.Create("StormFox - MapDataControlelr",5,0,function()
		MaterialReplacementThink()
	end)