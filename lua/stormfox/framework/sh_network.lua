

--[[-------------------------------------------------------------------------
	Allows easy data shareing and data "leaping"
		StormFox.SetData(str,var,timestamp)
		StormFox.GetData(str)

	Server
		StormFox.SetGhostData(str,var) Sets the data without sending it to clients
		StormFox.SendAllData(ply) 	Send current data
		StormFox.SendAllAim(ply)	Send the datas 'aim'

---------------------------------------------------------------------------]]

-- Set tables .. kinda useless when it doesn't refresh
	local data = StormFox_DATA or {}
	StormFox_DATA = data
	local aimdata = StormFox_AIMDATA or {}
	StormFox_AIMDATA = aimdata

-- Set, get and handle data
	local function LeapVarable(basevar,aimvar,timestart,timeend) -- Number, table and color
		local t = StormFox.GetTime()
		if t < 100 and timeend > 720 then
			return aimvar
		end
		if basevar == aimvar or timestart >= timeend or t >= timeend or type(basevar) != type(aimvar) then
			return aimvar
		end
		if type(aimvar) == "number" then
			local delta = {aimvar - basevar, timeend - timestart} -- Deltavar, Deltatime
			local varprtime = delta[1] / delta[2]
			return basevar + (varprtime * (t - timestart))
		elseif type(aimvar) == "table" then
			if aimvar.r and aimvar.g and aimvar.b then
				-- color
				local r = LeapVarable(basevar.r,aimvar.r,timestart,timeend)
				local g = LeapVarable(basevar.g,aimvar.g,timestart,timeend)
				local b = LeapVarable(basevar.b,aimvar.b,timestart,timeend)
				local a = LeapVarable(basevar.a or 255,aimvar.a or 255,timestart,timeend)
				return Color(r,g,b,a)
			else
				-- A table of stuff? .. or what.
				local tab = table.Copy(basevar)
				for key,var in pairs(aimvar) do
					tab[key] = LeapVarable(basevar[key],var,timestart,timeend)
				end
				return tab
			end
			return
		end
		return aim
	end
	function StormFox.IsDon(str)
		return aimdata[str]
	end
	local cdata = {}
	function StormFox.GetData(str,base)
		if not StormFox.GetTime then return base end
		if not data[str] then return base end
		if not aimdata[str] then
			return data[str] or nil
		end
		local t = StormFox.GetTime()
		local timestamp = aimdata[str][3] or 0
		-- Is it over the aimdata?
		if (timestamp or 0) <= (t or 0) then
			-- Remove aimdata and set the final var
			data[str] = aimdata[str][1]
			aimdata[str] = nil
			StormFox_AIMDATA[str] = nil
			return data[str]
		end
		-- Cache
		if cdata[str] then
			if cdata[str][1] > SysTime() then
				return cdata[str][2]
			end
		end
		-- We need to calculate the data .. darn
		n = LeapVarable(data[str],aimdata[str][1],aimdata[str][2],timestamp)
		cdata[str] = {SysTime() + FrameTime() + 0.02,n}
		return n,aimdata[str][1],aimdata[str][2]
	end

	local datacashe = {}
	local con = GetConVar("sf_timespeed")
	function StormFox.SetData(str,var,timestamp)
		-- Support freezing time
		if con and con:GetFloat() <= 0 then
			timestamp = nil
		end
		-- Check for duplicates
		if datacashe[str] == var and type(var) ~= "table" and !IsColor(var) then
			-- Its a dupe
			return
		end
		datacashe[str] = var
		--print(str,var,timestamp)

		-- Notify scripts that something is about to change
			hook.Call("StormFox - DataChange",nil,str,var,timestamp)
		-- If its a instant set, only set the instant
			if not data[str] or not timestamp then -- No base or time .. send it instant to clients
				data[str] = var
				if SERVER then
				--	print("Sending data: ",str,var)
					net.Start("StormFox - Data")
						net.WriteInt(2,8)
						net.WriteString(str)
						net.WriteType(var)
						net.WriteFloat(-1)
					net.Broadcast()
				end
				return
			end
		-- Check for outdated vars
			if aimdata[str] and (aimdata[str][3] or 0) <= StormFox.GetTime() then
				--print("Delete oldass data: " .. str,(aimdata[str][3] or 0) - StormFox.GetTime())
				aimdata[str] = nil -- Old .. delete plz
			end
		-- Check if there is an aimdata
		if aimdata[str] then
			-- Check if what we got is invalid and got a less or equal timestamp
			if aimdata[str][1] == var and (aimdata[str][3] or 0) <= timestamp then
				-- Its a duplicate with a longer tick
				--print("Dupeaim: ",str,var,"==",aimdata[str][1])
				return
			end
			-- Not finished leaping .. override base and continue
			data[str] = StormFox.GetData(str)
		elseif data[str] == var and false then
			-- Its a duplicate
			--print("Dupe: ",str,var,"==",data[str])
			if type(var) != "table" then
				return
			end
		end
		aimdata[str] = {var,StormFox.GetTime(),timestamp}
		if SERVER then
		--	print("Sending data: ",str,var,timestamp - StormFox.GetTime())
			net.Start("StormFox - Data")
				net.WriteInt(2,8)
				net.WriteString(str)
				net.WriteType(var)
				net.WriteFloat(timestamp)
			net.Broadcast()
		end
	end
	if SERVER then
		function StormFox.SetGhostData(str,var) -- No share
			if not data[str] or not timestamp then
				data[str] = var
				return
			end
			if aimdata[str] then -- not finished leaping .. override base
				data[str] = StormFox.GetData(str)
			end
			aimdata[str] = {var,StormFox.GetTime(),timestamp}
		end
	end

-- Nethandle data
	local token = SysTime()
	if SERVER then
		util.AddNetworkString("StormFox - Data")
		function StormFox.SendAllData(ply)
			if ply then
				ply.StormFox_S = token
			else
				for _,plyi in ipairs( player.GetAll() ) do
					plyi.StormFox_S = token
				end
			end
			net.Start("StormFox - Data")
				net.WriteInt(1,8)
				local t = {}
				for key,var in pairs(data) do
					t[key] = StormFox.GetData(key)
				end
				net.WriteTable(t)
			if ply then
				net.Send(ply)
			else
				net.Broadcast()
			end
		end
		function StormFox.SendAllAim(ply)
			if ply then
				ply.StormFox_S = true
			else
				for _,plyi in ipairs( player.GetAll() ) do
					plyi.StormFox_S = true
				end
			end
			net.Start("StormFox - Data")
				net.WriteInt(1,8)
				local t = {}
				for key,var in pairs(aimdata) do
					t[key] = StormFox.GetData(key)
				end
				net.WriteTable(t)
			if ply then
				net.Send(ply)
			else
				net.Broadcast()
			end
		end
		net.Receive("StormFox - Data",function(len,ply)
			if ply.StormFox_S and ply.StormFox_S == token then return end -- Only one ticket
			ply.StormFox_S = token
			--print("[StormFox] - DataSend to " .. ply:Nick())
			StormFox.SendAllData(ply) -- first the base
			StormFox.SendAllAim(ply) -- then the aim
		end)
	else
		-- Got any more of that weather data?
		timer.Simple(1,function()
			net.Start("StormFox - Data")
			net.SendToServer()
		end)

		net.Receive("StormFox - Data",function(len)
			if not StormFox.GetTime then return end
			local msg = net.ReadInt(8)
			if msg == 1 then -- Full update of all vars
				--print("Full update")
				for key,var in pairs(net.ReadTable()) do
					StormFox.SetData(key,var)
				end
			elseif msg == 2 then
				local key = net.ReadString()
				local var = net.ReadType(dtype)
				local t = net.ReadFloat() or -1
				StormFox.SetData(key,var,t >= 0 and t or nil)
			else
				--print("I didn't get that?")
			end
		end)
	end
