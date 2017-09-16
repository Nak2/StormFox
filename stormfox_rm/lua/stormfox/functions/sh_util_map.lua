
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
local sky_cam = nil
local sky_scale = 0

if SERVER then
	StormFox_DATA = StormFox_DATA or {} -- Not sure what runs first .. but this table is global
	local function scan()
		local l = ents.FindByClass("sky_camera")
		if #l < 1 then return end
		sky_cam = l[1]
		sky_scale = l[1]:GetSaveTable().scale
		StormFox_DATA["skybox_pos"] = sky_cam:GetSaveTable()["m_skyboxData.origin"] or sky_cam:GetPos()
		StormFox_DATA["skybox_scale"] = sky_scale

		StormFox_DATA["mapobbmaxs"] =  game.GetWorld():GetSaveTable().m_WorldMaxs or Vector(0, 0, 0)
		StormFox_DATA["mapobbmins"] =  game.GetWorld():GetSaveTable().m_WorldMins or Vector(0, 0, 0)
		StormFox_DATA["mapobbcenter"] = StormFox_DATA["mapobbmins"] + (StormFox_DATA["mapobbmaxs"] - StormFox_DATA["mapobbmins"]) / 2
	end
	hook.Add("InitPostEntity", "MapScan", scan)
	if #player.GetAll() > 0 then scan() end --Reloaded 

	function util.Is3DSkybox()
		return IsValid(sky_cam)
	end
else
	function util.Is3DSkybox()
		return StormFox_DATA["skybox_pos"] ~= nil
	end
end

function util.SkyboxPos()
	return StormFox_DATA["skybox_pos"]
end

function util.SkyboxScale()
	return StormFox_DATA["skybox_scale"]
end

function util.WorldToSkybox(pos)
	if not util.Is3DSkybox() then return end
	local offset = pos / util.SkyboxScale()
	return util.SkyboxPos() + offset
end

function util.SkyboxToWorld(pos)
	if not util.Is3DSkybox() then return end
	local set = pos - util.SkyboxPos()
	return set * util.SkyboxScale()
end

-- Thise don't give the world size .. but brushsize. This means that the topspace of the map might or might not count.
function util.MapOBBMaxs()
	return StormFox_DATA["mapobbmaxs"]
end

function util.MapOBBMins()
	return StormFox_DATA["mapobbmins"]
end

function util.MapOBBCenter()
	return StormFox_DATA["mapobbcenter"]
end

function util.IsTF2Map()
	local str = game.GetMap()
	return string.match(str, "^[(arena_)(cp_)(koth_)(cft_)(pl_)(plr_)(tr_)(sd_)(mvm_)(rd_)(ctf_)(pass_)]")
end