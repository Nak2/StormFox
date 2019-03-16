
--[[-------------------------------------------------------------------------
	Time functions
		StormFox.GetTimeSpeed()
		StormFox.GetTime(pure)	Gets the current time. Pure returns the "whole" number
		StormFox.SetTime(var)	Sets the time (Serverside only ofc)
		StormFox.GetRealTime()	Gets the time in a string-format
		StormFox.GetDaylightAmount(num) Returns the day/night amount from 1-0
 ---------------------------------------------------------------------------]]
local mmin,clamp = math.min,math.Clamp
local BASE_TIME = CurTime() -- The base time we will use to calculate current time with.
local c = GetConVar("sf_timespeed")
local TIME_SPEED = 1 / 60
if c then
	TIME_SPEED = (c:GetFloat() or 1) / 60
end
function StormFox.GetBASE_TIME()
	return BASE_TIME
end

-- Local functions
	local function StringToTime( str )
		if not str then return 0 end
		local a = string.Explode( ":", str )
		if #a < 2 then return 0 end
		local h,m = string.match(a[1],"%d+"),string.match(a[2],"%d+")
		local ex = string.match(a[2]:lower(),"[ampm]+")
		if not h or not m then return end
			h,m = tonumber(h),tonumber(m)
		if ex then
			-- 12clock to 24clock
			if ex == "am" and h == 12 then
				h = h - 12
			end
			if h < 12 and ex == "pm" then
				h = h + 12
			end
		end
		return ( h * 60 + m ) % 1440
	end

	function StormFox.StringToTime(str)
		return StringToTime(str)
	end

-- Sync functions
	if SERVER then
		util.AddNetworkString( "StormFox_SetTimeData" )

		-- Network the current time and time speed to the client so they can calculate a syncronized time value
		hook.Add( "PlayerInitialSpawn", "StormFox_SendInitialTimeData", function( pPlayer )
			net.Start( "StormFox_SetTimeData" )
				net.WriteFloat( StormFox.GetTime() )
				net.WriteFloat( TIME_SPEED )
			net.Send( pPlayer )
		end )

		-- Update all the currently connected clients with the new time speed
		local function updateClientsTimeVars()
			net.Start( "StormFox_SetTimeData" )
				net.WriteFloat( StormFox.GetTime() )
				net.WriteFloat( TIME_SPEED )
			net.Broadcast()
		end

		-- Update our local TIME_SPEED variable if the convar is changed
		cvars.AddChangeCallback( "sf_timespeed", function( sConvarName, sOldValue, sNewValue )
			local flNewValue = (tonumber( sNewValue ) or 1)
			local flOldTime = StormFox.GetTime()
			if flNewValue > 3960 then
				MsgN( "[StormFox] WARNING: Timespeed was set to higer than 3960.0. Reverting to a value of 3960.")
				GetConVar( "sf_timespeed" ):SetFloat( 3960.0 )
				TIME_SPEED = 66
			elseif flNewValue > 0 and flNewValue < 0.06 then
				MsgN( "[StormFox] WARNING: Timespeed can't be between 0 and 0.06. Reverting to the value of 0.06.")
				GetConVar( "sf_timespeed" ):SetFloat( 0.06 )
				TIME_SPEED = 0.001
			elseif flNewValue <= 0 then
				if flNewValue < 0 then
					MsgN( "[StormFox] WARNING: Timespeed can't go below 0. Pausing the time.")
				else
					MsgN( "[StormFox] Pausing time.")
				end
				GetConVar( "sf_timespeed" ):SetFloat( 0 )
				TIME_SPEED = 0
			else
				MsgN( "[StormFox] Timespeed changed to: " .. flNewValue )
				TIME_SPEED = flNewValue / 60
			end
			if TIME_SPEED <= 0 then
				timer.Pause("StormFox - tick")
				BASE_TIME = flOldTime
			else
				BASE_TIME = CurTime() - ( flOldTime / TIME_SPEED )
				if tonumber(sOldValue) <= 0 then
					timer.UnPause("StormFox - tick")
				end
				timer.Adjust( "StormFox - tick", 1 / TIME_SPEED,0)
			end
			updateClientsTimeVars() -- Update the vars
		end, "StormFox_TimeSpeedChanged" )

		-- Used to update the current stormfox time
		function StormFox.SetTime( var )
			if not var then return false end
			local flNewTime = nil
			if type( var ) == "string" then
				flNewTime = StringToTime( var )
			elseif type( var ) == "number" then
				flNewTime = var
			else
				return false
			end
			if type(flNewTime) == "nil" then
				return false
			end
			if TIME_SPEED <= 0 then
				BASE_TIME = flNewTime
			else
				BASE_TIME = CurTime() - ( flNewTime / TIME_SPEED )
			end
			hook.Call( "StormFox.Time.Change", nil, flNewTime )
			hook.Call( "StormFox.Time.Set")
			updateClientsTimeVars()

			return flNewTime
		end
		timer.Simple(1,updateClientsTimeVars)


		local SUN_RISE = 360
		local SUN_SET = 1160
		local SUNRISE_CALLED = false
		local SUNSET_CALLED = false
		local NEWDAY_CALLED = false

		local timerfunction = function()
			if StormFox.GetTimeSpeed() <= 0 then return end
			local time = StormFox.GetTime()
			if not SUNRISE_CALLED and time >= SUN_RISE and time < SUN_SET then
				hook.Call( "StormFox.Time.Sunrise" )
				SUNRISE_CALLED = true
				SUNSET_CALLED = false
			elseif not SUNSET_CALLED and ( time < SUN_RISE or time >= SUN_SET ) then
				hook.Call( "StormFox.Time.Sunset" )
				SUNRISE_CALLED = false
				SUNSET_CALLED = true
				NEWDAY_CALLED = false
			elseif time < StormFox.GetTimeSpeed() and not NEWDAY_CALLED then
				hook.Call( "StormFox.Time.NewDay" )
				NEWDAY_CALLED = true
			end
			hook.Call( "StormFox.Time.Tick", nil, StormFox.GetTime() )
		end
		timer.Create( "StormFox - tick", 1, 0, timerfunction )
		hook.Add("StormFox.Time.Set","StormFox.Newdayfix",function()
			NEWDAY_CALLED = false
		end)
	else -- CLIENT
		net.Receive( "StormFox_SetTimeData", function()
			local flCurrentTime = net.ReadFloat()
			TIME_SPEED = net.ReadFloat()
			if TIME_SPEED > 0 then
				BASE_TIME = CurTime() - ( flCurrentTime / TIME_SPEED )
			else
				BASE_TIME = flCurrentTime
			end
			hook.Call( "StormFox.Time.Set")
		end )
	end

-- Time functions
	function StormFox.GetTimeSpeed()
		return TIME_SPEED
	end

	function StormFox.GetTime( bNearestSecond )
		if TIME_SPEED <= 0 then
			return bNearestSecond and math.Round( BASE_TIME ) or BASE_TIME
		end
		local flTime = ( ( CurTime() - BASE_TIME ) * TIME_SPEED ) % 1440

		return bNearestSecond and math.Round( flTime ) or flTime
	end

	function StormFox.GetRealTime(num, _12clock )
		local var = num or StormFox.GetTime()
		local h = math.floor(var / 60)
		local m = math.floor(var - (h * 60))
		if not _12clock then return h .. ":" .. (m < 10 and "0" or "") .. m end

		local e = "PM"
		if h < 12 or h == 0 then
			e = "AM"
		end
		if h == 0 then
			h = 12
		elseif h > 12 then
			h = h - 12
		end
		return h .. ":" .. (m < 10 and "0" or "") .. m .. " " .. e
	end

	function StormFox.CalculateMapLight( flTime, nMin, nMax )
		nMax = nMax or 100
		flTime = flTime or StormFox.GetTime()
		-- Just a function to calc daylight amount based on time. See here https://www.desmos.com/calculator/842tvu0nvq
		local flMapLight = -0.00058 * math.pow( flTime - 750, 2 ) + nMax
		return clamp( flMapLight, nMin or 1, nMax )
	end

if SERVER then
	StormFox.SetTime( os.time() % 1440 )
	cvars.AddChangeCallback( "sf_realtime", function( convar_name, value_old, value_new )
		if value_new == "1" then
			RunConsoleCommand("sf_timespeed",1) -- match the real world timespeed. Seconds of gametime pr second
			local dt = string.Explode(":",os.date("%H:%M:%S"))
			StormFox.SetTime(dt[1] * 60 + dt[2] + (dt[3] / 60))
			print("[StormFox] Setting time to localtime (" .. os.date("%H:%M:%S") .. ")")
		end
	end, "StormFox - SF_REALTIMESET" )
	timer.Create("StormFox - SF_KeepRealTime",6,0,function()
		local con = GetConVar("sf_realtime")
		if not con:GetBool() then return end
		-- In case of desync
		local con2 = GetConVar("sf_timespeed")
		if con2:GetInt() ~= 1 then
			StormFox.Msg("sf_timespeed desync detected while running sf_timespeed.")
			RunConsoleCommand("sf_timespeed",1) -- match the real world timespeed. Seconds of gametime pr second
		end
		local dt = string.Explode(":",os.date("%H:%M:%S"))
		local t = dt[1] * 60 + dt[2] + (dt[3] / 60)
		if StormFox.GetTime() ~= t then
			--StormFox.Msg("Desync detected while running sf_timespeed.")
			StormFox.SetTime(dt[1] * 60 + dt[2] + (dt[3] / 60))
		end
	end)
end

-- Setup server varables
	if SERVER then
		hook.Add("StormFox.PostInit","StormFox.StartTime",function()
			local con = GetConVar("sf_start_time")
			local con2 = GetConVar("sf_realtime")

			-- Realtime setting
				if con2 and con2:GetBool() then
					RunConsoleCommand("sf_timespeed",1) -- match the real world timespeed. Seconds of gametime pr second
					local dt = string.Explode(":",os.date("%H:%M:%S"))
					StormFox.SetTime(dt[1] * 60 + dt[2] + (dt[3] / 60))
					print("[StormFox] sf_start_time: Setting time to localtime (" .. os.date("%H:%M:%S") .. ")")
					return
				end

			if con and con:GetString() ~= "" then
				local str = string.Replace(con:GetString()," ","")
				local n = StringToTime(str)
				if not n then print("[StormFox] WARNING. sf_start_time is invalid: " .. str) return end
				print("[StormFox] sf_start_time: Setting time to: " .. str)
				StormFox.SetTime(n)
			else
				local cookie = cookie.GetString("StormFox - ShutDown",nil)
				if cookie then
					local a = string.Explode("|",cookie)
					local diff_time = os.time() - tonumber(a[2])
					if TIME_SPEED > 0 then
						diff_time = diff_time * TIME_SPEED
					end
					local n = tonumber(a[1]) + diff_time
					StormFox.SetTime(n % 1440)
					print("[StormFox] Loaded time.")
				end
			end
			cookie.Delete("StormFox - ShutDown") -- Always delete
		end)
		hook.Add("ShutDown","StormFox.OnShutdown",function()
			cookie.Set("StormFox - ShutDown",StormFox.GetTime() .. "|" .. os.time( ))
			print("[StormFox] Saved time.")
		end)
	end
