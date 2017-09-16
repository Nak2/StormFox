
--[[-------------------------------------------------------------------------
	Time functions
		StormFox.GetTimeSpeed()
		StormFox.GetTime(pure)	Gets the current time. Pure returns the "whole" number
		StormFox.SetTime(var)	Sets the time (Serverside only ofc)
		StormFox.GetRealTime()	Gets the time in a string-format
		StormFox.GetDaylightAmount(num) Returns the day/night amount from 1-0
 ---------------------------------------------------------------------------]]
 local mmin = math.min
	local time = os.time() % 1440 -- Make a "finart" time
	function StormFox.GetTimeSpeed()
		local con = GetConVar("sf_timespeed")
		if not con then return 1 end
		return con:GetFloat() or 1
	end
	-- Local functions
		local function StringToTime(str)
			if !str then return 0 end
			local a = string.Explode(":",str)
			if #a < 2 then return 0 end
			return ( tonumber(a[1]) * 60 + tonumber( a[2] ) ) % 1440
		end

	if SERVER then
		util.AddNetworkString("StormFox_NET")
		function StormFox.GetTime(pure)
			local t = StormFox.GetTimeSpeed()
			if t <= 0 or pure then
				return time
			end
			local d = mmin( (t - timer.TimeLeft("StormFox-tick")) * t, 5 )
			return time  + d
		end
		function StormFox.SetTime(var)
			if type(var) == "string" then
				time = StringToTime(var)
				hook.Call("StormFox - Timechange",nil,time)
				return time
			elseif type(var) == "number" then
				time = var
				hook.Call("StormFox - Timechange",nil,time)
				return time
			end
			return false
		end

		local timerfunction = function()
			if StormFox.GetTimeSpeed() <= 0 then return end
			time = (time + 1) % 1440
			net.Start("StormFox_NET",true)
				net.WriteString("tick")
				net.WriteFloat(time)
			net.Broadcast()
			hook.Call("StormFox-Tick",nil,time)
		end
		timer.Create("StormFox-tick",1,0,timerfunction)

		if #(cvars.GetConVarCallbacks("sf_timespeed") or {}) > 0 then
			cvars.RemoveChangeCallback("sf_timespeed", "StormFox-tick")
		end
		cvars.AddChangeCallback("sf_timespeed", function(_,_,new)
			print("[StormFox] Changed timespeed")
			local n3 = tonumber(new)
			if n3 == 0 then n3 = 1 end
			timer.Adjust("StormFox-tick",1 / n3,0,timerfunction)
		end,"StormFox-tick")
	else
		local timetoken = SysTime()
		net.Receive("StormFox_NET",function(len)
			local msg = net.ReadString()
			if msg == "tick" then
				time = net.ReadFloat()
				timetoken = SysTime() -- allows us to get in details .. without being exspensive
				return
			end
		end)
		function StormFox.GetTime(pure)
			local t = StormFox.GetTimeSpeed()
			if t <= 0 or pure then
				return time
			end
			local since = (SysTime() - timetoken) * t
			return time + mmin(since,60 / t) -- Max 60 seconds lagcomp
		end
	end

	function StormFox.GetRealTime(num,_12clock)
		local t = num or time
			local h = math.floor(t / 60)
			local m = t - (h * 60)
		if _12clock then
			local e = " AM"
			if h >= 12 then
				h = h - 12
				e = " PM"
			end
			return h .. ":" .. ( m < 10 and "0" or "" ) .. m .. e
		end
		return h .. ":" .. ( m < 10 and "0" or "" ) .. m
	end

	function StormFox.GetDaylightAmount(num)
		local t = num or StormFox.GetTime()
		if t <= 320 or t >= 1120 then return 0 end -- Night
		if t >= 400 and t <= 1040 then return 1 end -- Day
		if t < 400 then
			-- sun rise
			return (t - 320) / 80
		else
			return 1 - (t - 1040) / 80
		end
	end
