
--[[	
	util.Is3DSkybox()	 -- return [true/false]
	util.SkyboxPos()	 -- return vector
	util.SkyboxScale()	 -- return number
	util.WorldToSkybox(Vector) -- return vector
	util.SkyboxToWorld(Vector) -- return vector
	util.MapOBBMaxs() 	 -- return vector
	util.MapOBBMins()	 -- return vector
	util.IsTF2Map()		 -- return [true/false]

	navmesh.GetNavAreaBySize(xyminsize) -- returns all navmeshs equal to or bigger than the input
]]

-- Skybox
	local sky_cam = nil
	local sky_scale = 0

	if SERVER then
		StormFox_NETWORK_DATA = StormFox_NETWORK_DATA or {} -- Not sure what runs first .. but this table is global
		local function scan()
			local saveTbl = game.GetWorld():GetSaveTable() or {}
			StormFox_NETWORK_DATA["mapobbmaxs"] =  saveTbl.m_WorldMaxs or Vector(0,0,1000)
			StormFox_NETWORK_DATA["mapobbmins"] =  saveTbl.m_WorldMins or Vector(0,0,0)
			StormFox_NETWORK_DATA["mapobbcenter"] = StormFox_NETWORK_DATA["mapobbmins"] + (StormFox_NETWORK_DATA["mapobbmaxs"] - StormFox_NETWORK_DATA["mapobbmins"]) / 2

			local l = ents.FindByClass("sky_camera")

			if #l < 1 then return end
			sky_cam = l[1]
			local keyvalues = sky_cam:GetSaveTable() or {}
			sky_scale = tonumber(keyvalues.scale) or 16
			StormFox_NETWORK_DATA["skybox_scale"] = sky_scale
			StormFox_NETWORK_DATA["skybox_pos"] = keyvalues["m_skyboxData.origin"] or sky_cam:GetPos()
		end
		hook.Add("StormFox.PostEntity","StormFox.FindSkyBox",scan)

		function StormFox.Is3DSkybox()
			return IsValid(sky_cam)
		end
	else
		function StormFox.Is3DSkybox()
			return StormFox_NETWORK_DATA["skybox_pos"] ~= nil
		end
	end

	function StormFox.SkyboxPos()
		return StormFox_NETWORK_DATA["skybox_pos"]
	end

	function StormFox.SkyboxScale()
		return StormFox_NETWORK_DATA["skybox_scale"]
	end

	function StormFox.WorldToSkybox(pos)
		if not StormFox.Is3DSkybox() then return end
		local offset = pos / StormFox.SkyboxScale()
		return StormFox.SkyboxPos() + offset
	end

	function StormFox.SkyboxToWorld(pos)
		if not StormFox.Is3DSkybox() then return end
		local set = pos - StormFox.SkyboxPos()
		return set * StormFox.SkyboxScale()
	end

-- World
	-- Thise don't give the world size .. but brushsize. This means that the topspace of the map might or might not count.
	function StormFox.MapOBBMaxs()
		return StormFox_NETWORK_DATA["mapobbmaxs"] or Vector(0,0,1000)
	end

	function StormFox.MapOBBMins()
		return StormFox_NETWORK_DATA["mapobbmins"] or Vector(0,0,0)
	end

	function StormFox.MapOBBCenter()
		return StormFox_NETWORK_DATA["mapobbcenter"] or Vector(0,0,0)
	end

	function StormFox.IsTF2Map()
		local str = game.GetMap()
		return string.match(str, "^[(arena_)(cp_)(koth_)(cft_)(pl_)(plr_)(tr_)(sd_)(mvm_)(rd_)(ctf_)(pass_)]")
	end