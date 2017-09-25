
--[[-------------------------------------------------------------------------
	Time functions
		StormFox.GetTimeSpeed()
		StormFox.GetTime(pure)	Gets the current time. Pure returns the "whole" number
		StormFox.SetTime(var)	Sets the time (Serverside only ofc)
		StormFox.GetRealTime()	Gets the time in a string-format
		StormFox.GetDaylightAmount(num) Returns the day/night amount from 1-0
 ---------------------------------------------------------------------------]]
local mmin = math.min
local BASE_TIME = SysTime() -- The base time we will use to calculate current time with.
local TIME_SPEED = SERVER and ( GetConVar("sf_timespeed") and GetConVar("sf_timespeed"):GetFloat() or 1 ) or 1

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
        local flNewValue = tonumber( sNewValue )
        if flNewValue < 0 or flNewValue > 66 then
            local bHigher = flNewValue > 66
            TIME_SPEED = bHigher and 66 or 1
            MsgN( "[StormFox] WARNING: Timespeed was set to invalid value (Must be between 0 and 66). Reverting to a value of " .. TIME_SPEED)
            GetConVar( "sf_timespeed" ):SetFloat( TIME_SPEED )
        else
            MsgN( "[StormFox] Timespeed changed to: " .. flNewValue )
            TIME_SPEED = flNewValue
            if TIME_SPEED <= 0 then
                timer.Pause("StormFox-tick")
            else
                if tonumber( sOldValue ) <= 0 then
                    timer.UnPause("StormFox-tick")
                end
                timer.Adjust( "StormFox-tick", 1 / TIME_SPEED,0)
            end
        end
        local flOldTime = StormFox.GetTime()
        BASE_TIME = SysTime() - ( flOldTime / TIME_SPEED )
        updateClientsTimeVars()
    end, "StormFox_TimeSpeedChanged" )

    -- Used to update the current stormfox time
    function StormFox.SetTime( var )
        local flNewTime = nil
        if type( var ) == "string" then
            flNewTime = StringToTime( var )
        elseif type( var ) == "number" then
            flNewTime = var
        else
            return false
        end

        BASE_TIME = SysTime() - ( flNewTime / TIME_SPEED )
        hook.Call( "StormFox - Timechange", nil, flNewTime )
        updateClientsTimeVars()

        return flNewTime
    end


    local SUN_RISE = 360
    local SUN_SET = 1160
    local SUNRISE_CALLED = false
    local SUNSET_CALLED = false
    local NEWDAY_CALLED = false

    local timerfunction = function()
        if StormFox.GetTimeSpeed() <= 0 then return end
        local time = StormFox.GetTime()
        if not SUNRISE_CALLED and time >= SUN_RISE and time < SUN_SET then
            hook.Call( "StormFox-Sunrise" )
            SUNRISE_CALLED = true
            SUNSET_CALLED = false
        elseif not SUNSET_CALLED and ( time < SUN_RISE or time >= SUN_SET ) then
            hook.Call( "StormFox-Sunset" )
            SUNRISE_CALLED = false
            SUNSET_CALLED = true
            NEWDAY_CALLED = false
        elseif time < 5 and not NEWDAY_CALLED then
            hook.Call( "StormFox-NewDay" )
            NEWDAY_CALLED = true
        end

        hook.Call( "StormFox-Tick", nil, StormFox.GetTime() )
    end
    timer.Create( "StormFox-tick", 1, 0, timerfunction )

else -- CLIENT

    timer.Create( "StormFox-tick", 1, 0, function()
        hook.Call( "StormFox-Tick", nil, StormFox.GetTime and StormFox.GetTime() )
    end )

    net.Receive( "StormFox_SetTimeData", function()
        local flCurrentTime = net.ReadFloat()
        TIME_SPEED = net.ReadFloat()
        BASE_TIME = SysTime() - ( flCurrentTime / TIME_SPEED )
        timer.Adjust( "StormFox-tick", 1 / TIME_SPEED, 0, timerfunction )
    end )

end

function StormFox.GetTimeSpeed()
	return TIME_SPEED
end

-- Local functions
local function StringToTime( str )
    if !str then return 0 end
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

function StormFox.GetTime( bNearestSecond )
    local flTime = ( ( SysTime() - BASE_TIME ) * TIME_SPEED ) % 1440
    return bNearestSecond and math.Round( flTime ) or flTime
end

function StormFox.GetRealTime(num, _12clock )
	local t = num or StormFox.GetTime()
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

function StormFox.GetDaylightAmount( num )
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
