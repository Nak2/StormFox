--[[ 
	Copyrighted by Nak
	Darn useful
	https://github.com/NicolasDe/AlienSwarm/blob/c5a2d3fa853c726d040032ff2c7b90c8ed8d5d84/src/game/server/ai_networkmanager.cpp
]]
local ain = {}

local AINET_VERSION_NUMBER = 37
local MAX_NODES = 1500
local MAX_NODE_LINKS = 30
local NUM_HULLS = 10
--[[-------------------------------------------------------------------------
HULL Types:
	ai_hull_t  Human_Hull			(bits_HUMAN_HULL,			"HUMAN_HULL",			Vector(-13,-13,   0),	Vector(13, 13, 72),		Vector(-8,-8,   0),		Vector( 8,  8, 72) );
	ai_hull_t  Small_Centered_Hull	(bits_SMALL_CENTERED_HULL,	"SMALL_CENTERED_HULL",	Vector(-20,-20, -20),	Vector(20, 20, 20),		Vector(-12,-12,-12),	Vector(12, 12, 12) );
	ai_hull_t  Wide_Human_Hull		(bits_WIDE_HUMAN_HULL,		"WIDE_HUMAN_HULL",		Vector(-15,-15,   0),	Vector(15, 15, 72),		Vector(-10,-10, 0),		Vector(10, 10, 72) );
	ai_hull_t  Tiny_Hull			(bits_TINY_HULL,			"TINY_HULL",			Vector(-12,-12,   0),	Vector(12, 12, 24),		Vector(-12,-12, 0),	    Vector(12, 12, 24) );
	ai_hull_t  Wide_Short_Hull		(bits_WIDE_SHORT_HULL,		"WIDE_SHORT_HULL",		Vector(-35,-35,   0),	Vector(35, 35, 32),		Vector(-20,-20, 0),	    Vector(20, 20, 32) );
	ai_hull_t  Medium_Hull			(bits_MEDIUM_HULL,			"MEDIUM_HULL",			Vector(-16,-16,   0),	Vector(16, 16, 64),		Vector(-8,-8, 0),	    Vector(8, 8, 64) );
	ai_hull_t  Tiny_Centered_Hull	(bits_TINY_CENTERED_HULL,	"TINY_CENTERED_HULL",	Vector(-8,	-8,  -4),	Vector(8, 8,  4),		Vector(-8,-8, -4),		Vector( 8, 8, 4) );
	ai_hull_t  Large_Hull			(bits_LARGE_HULL,			"LARGE_HULL",			Vector(-40,-40,   0),	Vector(40, 40, 100),	Vector(-40,-40, 0),		Vector(40, 40, 100) );
	ai_hull_t  Large_Centered_Hull	(bits_LARGE_CENTERED_HULL,	"LARGE_CENTERED_HULL",	Vector(-38,-38, -38),	Vector(38, 38, 38),		Vector(-30,-30,-30),	Vector(30, 30, 30) );
	ai_hull_t  Medium_Tall_Hull		(bits_MEDIUM_TALL_HULL,		"MEDIUM_TALL_HULL",		Vector(-18,-18,   0),	Vector(18, 18, 100),	Vector(-12,-12, 0),	    Vector(12, 12, 100) );

	1 = default/player 		Vector(-13,-13,   0),	Vector(13, 13, 72)	1
	2 = small hull 			Vector(-12,-12,   0),	Vector(12, 12, 24) 	4
	3 = medium hull 		Vector(-16,-16,   0),	Vector(16, 16, 64) 	6
	4 = large hull 			Vector(-40,-40,   0),	Vector(40, 40, 100) 8
---------------------------------------------------------------------------]]
	local util_TraceLine = util.TraceLine
	local function ET(pos,pos2,filter)
		local tr = util_TraceLine( {
			start = pos,
			endpos = pos2,
			filter = filter
		} )
		if not tr then -- Trace error!
			return {}
		end
		return tr
	end
	local util_TraceHull = util.TraceHull
	local function ETHull(pos,pos2,size,mask)
		local t = util_TraceHull( {
			start = pos,
			endpos = pos + pos2,
			maxs = Vector(size,size,4),
			mins = Vector(-size,-size,0),
			mask = mask,
			filter = LocalPlayer():GetViewEntity() or LocalPlayer()
			} )
		if not t then
			local t = {}
			t.HitPos = pos + pos2
			return t
		end
		return t
	end

	--[[-------------------------------------------------------------------------
		bits_BUILD_GROUND		=			0x00000001, // 
		bits_BUILD_JUMP			=			0x00000002, //
		bits_BUILD_FLY			=			0x00000004, // 
		bits_BUILD_CLIMB		=			0x00000008, //
		bits_BUILD_CRAWL		=			0x00000010, //
		bits_BUILD_GIVEWAY		=			0x00000020, //
		bits_BUILD_TRIANG		=			0x00000040, //
		bits_BUILD_IGNORE_NPCS	=			0x00000080, // Ignore collisions with NPCs
		bits_BUILD_COLLIDE_NPCS	=			0x00000100, // Use    collisions with NPCs (redundant for argument clarity)
		bits_BUILD_GET_CLOSE	=			0x00000200, // the route will be built even if it can't reach the destination
		bits_BUILD_NO_LOCAL_NAV	=			0x00000400, // No local navigation
		bits_BUILD_UNLIMITED_DISTANCE = 0x00000800, // Path can be an unlimited distance away
	---------------------------------------------------------------------------]]
local AI_NODE_ZONE_UNKNOWN	= 0
local AI_NODE_ZONE_SOLO 	 	= 1
local AI_NODE_ZONE_UNIVERSAL	= 3
local AI_NODE_FIRST_ZONE = 4

local NODE_ANY		= 0	 --	// Used to specify any type of node (for search)
local NODE_DELETED	= 1	 --	// Used in wc_edit mode to remove nodes during runtime     
local NODE_GROUND   	= 2
local NODE_AIR   		= 3
local NODE_CLIMB 		= 4
local NODE_WATER 		= 5
-- Read functions
	local function ReadBits( f, bits ) -- save.WriteInt
		local b = f:Read(bits)
		local i = 0
		for n,v in pairs( {string.byte(b,1,bits)} ) do
			i = i + v * (256 ^ (n - 1) )
		end
		if i > 2147483647 then i = i - 4294967296 end
		return i
	end
	local function ReadVec( f )
		return Vector( f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
	end
	local i = 0
	local function ReadNode( f )
		i = i + 1
		local vec = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
		local yaw = f:ReadFloat()
		local m_flVOffset = {}
		for i=1,NUM_HULLS do
			m_flVOffset[i] = f:ReadFloat()
		end
		local _type = f:ReadByte()
		local m_eNodeInfo = ReadBits(f,2)
		local zone = f:ReadShort()
		local pos = ET(vec + Vector(0,0,20),vec - Vector(0,0,60)).HitPos or vec
		local tr = ET(pos + Vector(0,0,20),pos + Vector(0,0,4000000000))
		local invalid = not tr.Hit
		return {
			["pos"] = pos,
			["yaw"] = yaw,
			["vOffset"] = m_flVOffset,
			["type"] = _type,
			["nodeInfo"] = m_eNodeInfo,
			["zone"] = zone,
			["IsOuterside"] = tr.HitSky,
			["invalid"] = invalid
		}
	end
	local function ReadLink( f )
		local node_from = f:ReadShort() + 1
		local node_to = f:ReadShort() + 1
		local AcceptedMoveTypes = {}
		for i = 1,NUM_HULLS do
			AcceptedMoveTypes[i] = f:ReadByte()
		end
		return node_from,node_to,AcceptedMoveTypes
	end

-- Local functions
	local valid = false
	local Nodes = {}
	local Links = {}
	function StormFox.AIAinIsValid()
		return valid
	end
	function ain.Load() -- https://github.com/NicolasDe/AlienSwarm/blob/c5a2d3fa853c726d040032ff2c7b90c8ed8d5d84/src/game/server/ai_networkmanager.cpp
		valid = false
		if not file.Exists("maps/graphs/" .. game.GetMap() .. ".ain","GAME") then return StormFox.Msg("No .ain file located.") end
		local f = file.Open("maps/graphs/" .. game.GetMap() .. ".ain","rb","GAME")
			local version = ReadBits(f,4)
			local m_version = ReadBits(f,4)
			if version ~= AINET_VERSION_NUMBER then return StormFox.Msg("Invalid .ain file version.") end -- Wrong version

			--[[-------------------------------------------------------------------------
			Network
			---------------------------------------------------------------------------]]
				local Network = ReadBits(f,4)
				if Network > MAX_NODES or Network <= 0 then
					if Network > 0 then
						StormFox.Msg("Invalid .ain file.")
					else
						StormFox.Msg("No nodes in .ain file.")
					end
					return false
				end -- Too many nodes or too few
				for i = 1,Network do
					Nodes[i] = ReadNode(f)
				end
			--[[-------------------------------------------------------------------------
			Links
			---------------------------------------------------------------------------]]
				local totalNumLinks = ReadBits(f,4)
				if totalNumLinks > MAX_NODES * MAX_NODE_LINKS then StormFox.Msg("Invalid link amount.")  return false end -- Too many links
				for i = 1,totalNumLinks do
					local node_from,node_to,AcceptedMoveTypes = ReadLink( f )
					if not Links[node_from] then Links[node_from] = {} end
					if not Links[node_to] then Links[node_to] = {} end
					table.insert(Links[node_from],{node_to,AcceptedMoveTypes})
					table.insert(Links[node_to],{node_from,AcceptedMoveTypes})
				end
			-- Ignore WC lookup
		f:Close()
		StormFox.Msg("sf_ain_load")
		valid = true
	end
	timer.Simple(3,ain.Load)

	function StormFox.GetAINode(node_id)
		return Nodes[node_id]
	end
	function StormFox.GetAINodePos(node_id)
		return Nodes[node_id].pos
	end
	function StormFox.GetAIConnectedNNodes(node_id)
		return Links[node_ID] or {}
	end
	function StormFox.GetAIAllNNodes( node_type, bOutside_Only, nOutside_HULL )
		local t = {}
		local r_invalid = false
		for node_id,node in pairs(Nodes) do
			if node.type ~= 0 then -- NODE_ANY
				if node_type ~= node.type then
					continue
				end
			end
			if bOutside_Only ~= nil then
				if node.invalid and (node.tick or 0) < 10 then -- Not scanned .. and less than 10 nodes
					local tr = ET(node.pos + Vector(0,0,20),node.pos + Vector(0,0,40000000000000),MASK_SOLID_BRUSHONLY)
					local invalid = not tr.Hit
					Nodes[node_id].IsOuterside = tr.HitSky
					Nodes[node_id].invalid = invalid
					Nodes[node_id].tick = (node.tick or 0) + 1
					r_invalid = r_invalid or invalid
				end
				if node.IsOuterside ~= bOutside_Only then
					continue
				end
			end
			if nOutside_HULL then
				if not ETHull(node.pos,Vector(0,0,50000),nOutside_HULL,MASK_SOLID_BRUSHONLY).HitSky then
					continue
				end
			end
			table.insert(t,node_id)
		end
		return t,r_invalid
	end
	function StormFox.FindAIClosestNode(vec, node_type, filter, bOutside_Only)
		if not node_type then node_type = 2 end
		local d,n_id = -1,-1
		for id,node in pairs(Nodes) do
			-- Check the node_type
				if node.type ~= 0 then -- NODE_ANY
					if node_type ~= node.type then
						continue
					end
				end
				if bOutside_Only ~= nil then
					if node.invalid and (node.tick or 0) < 10 then -- Not scanned .. and less than 10 nodes
						local tr = ET(node.pos + Vector(0,0,20),node.pos + Vector(0,0,40000000000000),MASK_SOLID_BRUSHONLY)
						local invalid = not tr.Hit
						Nodes[node_id].IsOuterside = tr.HitSky
						Nodes[node_id].invalid = invalid
						Nodes[node_id].tick = node.tick + 1
						r_invalid = r_invalid or invalid
					end
					if node.IsOuterside ~= bOutside_Only then
						continue
					end
				end
			local nd = node.pos:DistToSqr(vec)
			if d < 0 or nd < d then
				if ET(vec,node.pos,filter).Hit then
					continue
				end
				d = nd
				n_id = id
			end
		end
		return n_id > 0 and n_id or nil
	end
	function StormFox.FindAINodesInRange(vec, dis, node_type, bOutside_Only)
		if not node_type then node_type = 2 end
			dis = dis ^ 2
		local t = {}
		for id,node in pairs(ain.Nodes) do
			-- Check the node_type
				if node.type ~= 0 then -- NODE_ANY
					if node_type ~= node.type then
						continue
					end
				end
				if bOutside_Only ~= nil then
					if node.invalid and (node.tick or 0) < 10 then -- Not scanned .. and less than 10 nodes
						local tr = ET(node.pos + Vector(0,0,20),node.pos + Vector(0,0,40000000000000),MASK_SOLID_BRUSHONLY)
						local invalid = not tr.Hit
						Nodes[node_id].IsOuterside = tr.HitSky
						Nodes[node_id].invalid = invalid
						Nodes[node_id].tick = node.tick + 1
						r_invalid = r_invalid or invalid
					end
					if node.IsOuterside ~= bOutside_Only then
						continue
					end
				end
			local nd = node.pos:DistToSqr(vec)
			if nd <= dis then
				table.insert(t,{id,nd})
			end
		end
		table.sort(t,function(a,b) return a[2] < b[2] end)
		return t
	end
