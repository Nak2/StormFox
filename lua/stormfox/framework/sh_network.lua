
--[[-------------------------------------------------------------------------
	Allows easy data shareing and data "leaping"
		StormFox.SetData(str,var,timestamp)
		StormFox.GetData(str)

	Server
		StormFox.SetGhostData(str,var) Sets the data without sending it to clients
		StormFox.SendAllData(ply) 	Send current data
		StormFox.SendAllAim(ply)	Send the datas 'aim'

---------------------------------------------------------------------------]]

-- SSetup varable tables
	local data = StormFox_DATA or {}
	StormFox_DATA = data
	local aimdata = StormFox_AIMDATA or {}
	StormFox_AIMDATA = aimdata

-- Setup async data
	-- functions and logic
		local CurTime = CurTime
		local RealTime = RealTime

		local function LeapVarable(basevar,aimvar,timestart,timeend) -- Number, table and color
			local t = CurTime()
			if t < 100 and timeend > 720 then
				return aimvar
			end
			if basevar == aimvar or timestart >= timeend or t >= timeend or type(basevar) ~= type(aimvar) then
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
	-- Get and set
		local con = GetConVar("sf_timespeed")
		local cdata = {}
		function StormFox.GetData(str,base)
			if not data[str] then return base end
			if not aimdata[str] then -- No aimdata .. return the var
				return data[str] or nil
			end
			-- Check for cache
				local cd = cdata[str]
				if cd and cd[1] > RealTime() then
					return cd[2]
				end
			local st = con:GetFloat() / 60
			local t = CurTime()
			local t_start = aimdata[str][2] or 0
			local t_stop = t_start + aimdata[str][3] / math.max(st,0.5)
			-- Is it old aimdata?
			if t_stop <= t or t_stop < t_start then
				-- Remove aimdata and set the final var
				data[str] = aimdata[str][1]
				aimdata[str] = nil
				StormFox_AIMDATA[str] = nil
				return data[str]
			end
			-- We need to calculate the data
			local n = LeapVarable(data[str],aimdata[str][1],t_start,t_stop)
			-- Cache it for other functions
			local expire = RealTime() + (SERVER and FrameTime() or RealFrameTime())
			if cd then
				cd[1],cd[2] = expire,n
			else
				cdata[str] = {expire,n}
			end
			return n
		end

		local datacashe = {}
		function StormFox.SetData(str,var,over_seconds)
			-- Support freezing time
			if con and con:GetFloat() <= 0 then
				over_seconds = nil
			end
			-- Check for duplicates
			if datacashe[str] == var and type(var) ~= "table" then
				-- Its a dupe
				return
			elseif IsColor(var) and datacashe[str] then
				local c = datacashe[str]
				if var.r == c.r and var.g == c.g and var.b == c.b and var.a == c.a then
					return
				end
			end
			datacashe[str] = var
			local t = CurTime()
			-- Set/Delete old aimdata
				if aimdata[str] and over_seconds then
					data[str] = StormFox.GetData(str,aimdata[str][1])
					aimdata[str] = nil
				end
			-- Set the value if its an 'instant'.
				if not data[str] or not over_seconds then -- No base or time .. send it instant to clients
					data[str] = var
					aimdata[str] = nil
					-- Notify scripts that something changed
					hook.Call("StormFox - DataChange",nil,str,var,over_seconds)
					return
				end
				aimdata[str] = {var,t,over_seconds}
			-- Notify scripts that something changed
				hook.Call("StormFox - DataChange",nil,str,var,over_seconds)
		end
		function StormFox.DumpData()
			for key,var in pairs(aimdata) do
				data[key] = StormFox.GetData(key,var)
			end
			table.Empty(aimdata)
		end

-- Network data tables
	local network_data = StormFox_NETWORK_DATA or {}
	StormFox_NETWORK_DATA = network_data
	local network_aimdata = StormFox_NETWORK_AIMDATA or {}
	StormFox_NETWORK_AIMDATA = network_aimdata

-- Setup network data
	-- Update incoming people
	if SERVER then
		util.AddNetworkString("StormFox - Data")
		local token = SysTime()
		function StormFox.SendAllData(ply)
			net.Start("StormFox - Data")
				net.WriteInt(1,8)
				local t = {}
				for key,v in pairs(network_data) do
					if type(v) ~= "IMaterial" then
						t[key] = v
					end
				end
				net.WriteTable(t)
			if ply then
				net.Send(ply)
			else
				net.Broadcast()
			end
		end
		function StormFox.SendAllAim(ply)
			net.Start("StormFox - Data")
				net.WriteInt(3,8)
				local t = {}
				for k,v in pairs(network_aimdata) do
					if type(v) ~= "IMaterial" then
						t[k] = v
					end
				end
				net.WriteTable(t)
			if ply then
				net.Send(ply)
			else
				net.Broadcast()
			end
		end
		net.Receive("StormFox - Data",function(len,ply)
			if not IsValid(ply) or ply.StormFox_S == token then return end -- Only one ticket
			ply.StormFox_S = token
			--print("[StormFox] - DataSend to " .. ply:Nick())
			StormFox.SendAllData(ply) -- first the base
			StormFox.SendAllAim(ply) -- then the aim
		end)
	end

	local netcashe = {}
	local synced_convars = {}
	local function SyncConVars()
		for conname,_ in pairs(StormFox.convars) do
			if not synced_convars[conname] then
				local sf_con = GetConVar(conname)
				if sf_con then
					synced_convars[conname] = true
					network_data["con_" .. conname] = sf_con:GetString()
					cvars.AddChangeCallback(conname, function( name, _, value )
						StormFox.SetNetworkData("con_" .. name,value)
					end,"SF_Netupdate-" .. conname )
				end
			end
		end
	end
	function StormFox.SetNetworkData(str,var,over_seconds)
		if con and con:GetFloat() <= 0 then
			over_seconds = nil
		end
		-- Check for duplicates
		if netcashe[str] == var and type(var) ~= "table" then
			-- Its a dupe
			return
		elseif IsColor(var) and netcashe[str] then
			local c = netcashe[str]
			if var.r == c.r and var.g == c.g and var.b == c.b and var.a == c.a then
				return -- Also a dupe
			end
		end
		netcashe[str] = var
		local t = CurTime()

		-- Delete old aimdata
			if network_aimdata[str] then
				network_data[str] = StormFox.GetNetworkData(str,network_aimdata[str][1])
				network_aimdata[str] = nil
			end
		-- SetConvars
			SyncConVars()
		-- Set the value if its an 'instant'.
			if not network_data[str] or not over_seconds then -- No base or time .. send it instant to clients
				network_data[str] = var
				if SERVER then
				--	print("Sending data: ",str,var)
					net.Start("StormFox - Data")
						net.WriteInt(2,8)
						net.WriteString(str)
						net.WriteType(var)
						net.WriteFloat(-1)
					net.Broadcast()
				end
				-- Notify scripts that something changed
				hook.Run("StormFox - NetDataChange",str,var,over_seconds)
				return
			end
			network_aimdata[str] = {var,t,over_seconds}
		-- Send the data to clients
			if SERVER and not ghost then
				net.Start("StormFox - Data")
					net.WriteInt(2,8)
					net.WriteString(str)
					net.WriteType(var)
					net.WriteFloat(over_seconds)
				net.Broadcast()
			end
		-- Notify scripts that something changed
			hook.Run("StormFox - NetDataChange",str,var,over_seconds)
	end
	local cdata = {}
	function StormFox.GetNetworkData(str,base)
		if type(network_data[str]) == "nil" then return base end
		if type(network_aimdata[str]) == "nil" then -- No network_aimdata .. return the var
			return network_data[str]
		end
		-- Check for cache
			local cd = cdata[str]
			if cd and cd[1] > RealTime() then
				return cd[2]
			end

		local t = CurTime()
		local st = con:GetFloat() / 60
		local t_start = network_aimdata[str][2] or 0
		local t_stop = t_start + (network_aimdata[str][3] or 0) / math.max(st,0.5)
		-- Is it old aimdata?
		if t_stop <= t or t_stop < t_start then
			-- Remove aimdata and set the final var
			network_data[str] = network_aimdata[str][1]
			network_aimdata[str] = nil
			StormFox_AIMDATA[str] = nil
			return network_data[str]
		end
		
		-- We need to calculate the data
		local n = LeapVarable(network_data[str],network_aimdata[str][1],t_start,t_stop)
		-- Cache it for other functions
		local expire = RealTime() + (SERVER and FrameTime() or RealFrameTime())
		if cd then
			cd[1],cd[2] = expire,n
		else
			cdata[str] = {expire,n}
		end
		return n
	end
	if CLIENT then
		timer.Simple(1,function()
			net.Start("StormFox - Data")
			net.SendToServer()
		end)
		net.Receive("StormFox - Data",function(len)
			if not StormFox.GetTime then return end
			local msg = net.ReadInt(8)
			if msg == 1 then -- Full update of all vars
				for key,var in pairs(net.ReadTable()) do
					StormFox.SetNetworkData(key,var)
				end
			elseif msg == 2 then
				local key = net.ReadString()
				local var = net.ReadType(dtype)
				local t = net.ReadFloat() or -1
				if t > 0 then
					StormFox.SetNetworkData(key,var,t)
				else
					StormFox.SetNetworkData(key,var)
				end
			elseif msg == 3 then
				for key,var in pairs(net.ReadTable()) do
					StormFox.SetNetworkData(key,var[1],var[2])
				end
			end
		end)
	end