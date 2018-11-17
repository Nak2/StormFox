
--[[-------------------------------------------------------------------------
Map nodes
	SHARED
	- StormFox.GetAllONodes() -- returns a table of all outside nodes
	- StormFox.GetONode(position, range[, minimumsize]) -- returns a table of all close outside nodes
	- StormFox.debugoverlayONode(pos,range[,lifetime]) -- displays the nodes in the given area
	CLIENT
	- StormFox.GetCloseONodes([minimumsize]) -- returns the nearby outside nodes

---------------------------------------------------------------------------]]
local outdoors = {}
function StormFox.GetAllONodes()
	return outdoors
end
local offset = Vector(0,0,20)
local max = math.max
local clamp = math.Clamp
-- Local functions
	local function ETPos(pos,pos2,mask)
		local t = util.TraceLine( {
		start = pos,
		endpos = pos2,
		mask = mask,
		filter = filter
		} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end
	local function sendData(ply)
		net.Start("StormFox-AINodes")
			local str = util.TableToJSON(outdoors)
			local s = util.Compress(str)
			net.WriteInt(string.len(s),24)
			net.WriteData(s,string.len(s))
		if not ply then
			net.Broadcast()
		else
			net.Send(ply)
		end
	end
	local function setData()
		local len = net.ReadInt(24)
		local data = net.ReadData(len)
		local data = util.Decompress(data)
		outdoors = util.JSONToTable(data)
	end

function StormFox.GetONode(pos,range,minimumsize)
	if type(pos)~="Vector" then return {} end
	local r = range ^ 2
	if not minimumsize then minimumsize = 0 end
	local c = {}
	for _,data in pairs(outdoors) do
		if type(data[1]) ~= "Vector" then continue end
		if pos:DistToSqr(data[1]) <= r and (data[2] or 0)>=minimumsize then
			table.insert(c,{data[1],data[2]})
		end
	end
	return c
end
function StormFox.debugoverlayONode(pos,range,lifetime)
	local c = StormFox.GetONode(pos,range)
	for _,d in pairs(c) do
		debugoverlay.Sphere(d[1],d[2],lifetime,Color( 255, 255, 255,55 ))
	end
end

if SERVER then
	local maxlength = 300
	util.AddNetworkString("StormFox-AINodes")	
	local function isOutside(pos)
		-- Find skybox
		local checkEasy = ETPos(pos,pos + Vector(0,0,1) * 16384)
		return checkEasy.HitSky or false
	end
	local function scanArea(pos)
		local n = 10
		local a = 360 / n
		local defl = maxlength
		for i=1,n do
			local ang = a * i
			local t = ETPos(pos,pos + Angle(0,ang,0):Forward() * maxlength)
			local tl = t.HitPos:Distance(pos)
			defl = math.min(tl,defl)
		end
		local t = ETPos(pos,pos + Vector(0,0,maxlength))
		local tl = t.HitPos:Distance(pos)
		defl = math.min(tl,defl)
		return defl
	end
	local function handleNode(pos)
		local p = pos + offset
		if not isOutside(p) then return end -- Indoors
		table.insert(outdoors,{pos, scanArea(p)})
	end
	local function getN(i)
		if not SF_INFO_NODES then return nil end
		if not SF_INFO_NODES["node"] then return nil end
		return SF_INFO_NODES["node"][i]
	end
	local function getL()
		if not SF_INFO_NODES then return 0 end
		if not SF_INFO_NODES["node"] then return 0 end
		return table.Count(SF_INFO_NODES["node"])
	end
	local i = 0
	local done = false
	local function FindEntities()
		if done then return end
		local l = getL()
		if i > l then return end -- Done
		local n = getN(i)
		if n then
			handleNode(n)
		end
		i = i + 1
		if i > l then
			-- Done
			StormFox.Msg("Outside-Navpoints done [" .. table.Count(outdoors) .. "]")
			sendData()
			done = true
		end
	end
	hook.Add( "Think", "StormFox - ScanNavs", function()
		if done then return end
		for i=1,10 do
			FindEntities()
		end
	end )
	hook.Add("PlayerInitialSpawn","StormFox - ScanNavsSend",sendData)
else
	-- NET
		net.Receive("StormFox-AINodes",function()
			setData()
			StormFox.Msg("Outside-Navpoints recived [" .. table.Count(outdoors) .. "]")
		end)
	-- Data handling
		local nodes = {}
		local updatetime = -1
		local lastPos = nil
		timer.Create("StormFox - AINodeUpdater",0.8,0,function()
			if StormFox.GetExspensive() <= 2 then return end
			if not IsValid(LocalPlayer()) then return end
			if updatetime > CurTime() then return end
			if not StormFox then return end
			if not StormFox.GetEyePos then return end
			if not StormFox.GetExspensive then return end

			local speed = LocalPlayer():GetVelocity()
			local vspeed = speed:Length()
			local CP = StormFox.GetEyePos() + speed * 2
			if lastPos then
				if lastPos:DistToSqr(CP) < 400 then return end -- no need to update
			end
			lastPos = CP
			table.Empty(nodes)
			
			local range = max(clamp(StormFox.GetExspensive() * 150,500,1500) - vspeed,400)
			updatetime = CurTime() + max(2.5 - (vspeed / 400),1)
			nodes = StormFox.GetONode(CP,range)
		end)
	function StormFox.GetCloseONodes(minimumsize)
		if not minimumsize then
			return nodes
		else
			local t = {}
			for _,data in pairs(nodes) do
				if data[2]>=minimumsize then
					table.insert(t,data)
				end
			end
			return t
		end
	end	
end