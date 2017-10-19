
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
			local st = con:GetFloat()
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
			-- Check for cache
			if cdata[str] and cdata[str][1] > RealTime() then
				return cdata[str][2]
			end
			-- We need to calculate the data
			local n = LeapVarable(data[str],aimdata[str][1],t_start,t_stop)
			-- Cache it for other functions
			if SERVER then
				cdata[str] = {RealTime() + FrameTime(),n}
			else
				cdata[str] = {RealTime() + RealFrameTime(),n}
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
			if ply then
				ply.StormFox_S = true
			else
				for _,plyi in ipairs( player.GetAll() ) do
					plyi.StormFox_S = true
				end
			end
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
		local token = SysTime()
		net.Receive("StormFox - Data",function(len,ply)
			if ply.StormFox_S and ply.StormFox_S == token then return end -- Only one ticket
			ply.StormFox_S = token
			--print("[StormFox] - DataSend to " .. ply:Nick())
			StormFox.SendAllData(ply) -- first the base
			StormFox.SendAllAim(ply) -- then the aim
		end)
	end

	local netcashe = {}
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
				return
			end
		end
		netcashe[str] = var
		local t = CurTime()

		-- Delete old aimdata
			if network_aimdata[str] then
				network_data[str] = StormFox.GetNetworkData(str,network_aimdata[str][1])
				network_aimdata[str] = nil
			end
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
				hook.Call("StormFox - NetDataChange",nil,str,var,over_seconds)
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
			hook.Call("StormFox - NetDataChange",nil,str,var,over_seconds)
	end
	local cdata = {}
	function StormFox.GetNetworkData(str,base)
		if not network_data[str] then return base end
		if not network_aimdata[str] then -- No network_aimdata .. return the var
			return network_data[str] or nil
		end
		local t = CurTime()
		local st = con:GetFloat()
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
		-- Check for cache
		if cdata[str] and cdata[str][1] > RealTime() then
			return cdata[str][2]
		end
		-- We need to calculate the data
		local n = LeapVarable(network_data[str],network_aimdata[str][1],t_start,t_stop)
		-- Cache it for other functions
		if SERVER then
			cdata[str] = {RealTime() + FrameTime(),n}
		else
			cdata[str] = {RealTime() + RealFrameTime(),n}
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
				--print("Full update")
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
		--[[
		hook.Add("HUDPaint","StormFoxDebug",function()
			surface.SetFont("default")
			surface.SetTextColor(255,255,255)
			local i = 0
			for key,var in pairs(network_data) do
				surface.SetTextPos(10,10 + i * 15)
				surface.DrawText(key .. ":" .. tostring(StormFox.GetNetworkData(key,var)))
				i = i + 1
			end
				i = 0
			for key,var in pairs(aimdata) do
				surface.SetTextPos(ScrW() - 400,10 + i * 15)
				surface.DrawText(key .. " : " .. math.Round(aimdata[key][3] - CurTime()) .. " : " ..tostring(StormFox.GetData(key,var)))
				i = i + 1
			end
			surface.SetTextPos(ScrW() - 400,10 + i * 15)
			surface.DrawText(StormFox.GetRealTime())
		end)]]
	else
		hook.Add( "StormFox - PostEntityScan", "StormFox - SendEntities",function()
			StormFox.SetNetworkData("has_env_tonemap_controller",StormFox.env_tonemap_controller and true or false)
			StormFox.SetNetworkData("has_light_environment",StormFox.env_tonemap_controller and true or false)
			StormFox.SetNetworkData("has_env_fog_controller",StormFox.env_fog_controller and true or false)
			StormFox.SetNetworkData("has_env_skypaint",StormFox.env_skypaint and true or false)
			StormFox.SetNetworkData("has_shadow_control",StormFox.shadow_control and true or false)
		end)
	end