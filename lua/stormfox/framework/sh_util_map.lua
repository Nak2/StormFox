
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
		local function SkyTexture(str,vec)
			vec = vec or Vector(0,0,0)
			if str == "TOOLS/TOOLSNODRAW" and vec.z < 0 then return true end
			if str == "TOOLS/TOOLSINVISIBLE" and vec.z < 0 then return true end
			if str == "TOOLS/TOOLSSKYBOX" then return true end
			if str == "**empty**" then return true end
			return false
		end
		local function ET(pos,pos2,mask)
			local t = util.TraceLine( {
				start = pos,
				endpos = pos + pos2,
				mask = mask
			} )
			local l = 0
			local norm = Vector(pos2.x,pos2.y,pos2.z)
				norm:Normalize()
			--print("Scan:",norm)
			while t.Hit and not t.Hitsky and l < 10 and not SkyTexture(t.HitTexture,norm) do
				l = l + 1
				--print("	",l,t.HitTexture)
				local sp = t.HitPos + norm * 3
				t = nil
				t = util.TraceLine( {
					start = sp,
					endpos = sp + pos2,
					mask = mask
				} )
			end
			--print("Don",t.HitTexture,not t.HitSky,t.Hit,not SkyTexture(t.HitTexture,norm))

			t.HitPos = t.HitPos or (pos + pos2)
			return t
		end
		StormFox_NETWORK_DATA = StormFox_NETWORK_DATA or {} -- Not sure what runs first .. but this table is global
		local function scan()
			StormFox_NETWORK_DATA["mapobbmaxs"] =  game.GetWorld():GetSaveTable().m_WorldMaxs or Vector(0,0,1000)
			StormFox_NETWORK_DATA["mapobbmins"] =  game.GetWorld():GetSaveTable().m_WorldMins or Vector(0,0,0)
			StormFox_NETWORK_DATA["mapobbcenter"] = StormFox_NETWORK_DATA["mapobbmins"] + (StormFox_NETWORK_DATA["mapobbmaxs"] - StormFox_NETWORK_DATA["mapobbmins"]) / 2

			local l = ents.FindByClass("sky_camera")

			if #l < 1 then return end
			sky_cam = l[1]
			sky_scale = l[1]:GetSaveTable().scale
			StormFox_NETWORK_DATA["skybox_scale"] = sky_scale
			StormFox_NETWORK_DATA["skybox_pos"] = sky_cam:GetSaveTable()["m_skyboxData.origin"] or sky_cam:GetPos()
		end
		hook.Add("StormFox - PostEntity","StormFox - FindSkyBox",scan)

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

-- AI nodes
ai_node = {}
SF_INFO_NODES = SF_INFO_NODES or {["node"] = {},["climb"] = {}}
SF_INFO_NODES_HINT = SF_INFO_NODES_HINT or {}
SF_DEBUG_NODE = {}
    hook.Add("EntityRemoved","StormFox_NodeCatcher",function(ent)
        local class = ent:GetClass()
        SF_DEBUG_NODE[class] = true
        if class == "info_node" then
            table.insert(SF_INFO_NODES["node"],ent:GetPos())
        elseif class == "info_node_hint" then
            local id = table.insert(SF_INFO_NODES["node"],ent:GetPos()) -- info_node_hint is also used as a normal node
            SF_INFO_NODES_HINT[id] = ent:GetKeyValues()
        elseif class == "info_node_climb" then
            table.insert(SF_INFO_NODES["climb"],ent:GetPos())
        end
    end) 
    function ai_node.findInfoNode(pos,class)
        local _id,_dis,curpos = nil,-1,nil
        for id,npos in pairs(SF_INFO_NODES[class or "node"]) do
            local n_dis = pos:DistToSqr(npos)
            if _dis > n_dis or _dis < 0 then
                _dis = n_dis
                curpos = npos
                _id = id
            end
        end
        return curpos,_id
    end
    function ai_node.getNodes(class)
        return SF_INFO_NODES[class or "node"]
    end
--[[Read the .ain file (Doesn't really matter. If I can't read them. The file is empty)

	local function readByte(f,size)
		local b = {string.byte(f:Read(size),1,size)}
		return b[1] + b[2]*256 + b[3]*65536 + b[4]*16777216
	end
	function ai_node.readFile()
		local str = "maps/graphs/" .. game.GetMap() .. ".ain"
		if not file.Exists(str,"GAME") then return end
		local f = file.Open(str,"rb","GAME")
			local version = readByte(f,4)
			if version < 37 then return end
			local map = readByte(f,4)

			local nodes = readByte(f,4)
		f:Close()
		return nodes
	end
	]]