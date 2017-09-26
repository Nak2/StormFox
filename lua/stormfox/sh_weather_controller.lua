
local clamp = math.Clamp
local min = math.min

local LERP_AMOUNT = 0.02
local flStormMagnitude = 0
StormFox.tDailyWeatherForecast = StormFox.tDailyWeatherForecast or {}
local tPreviousWeatherValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), 0 ) or nil-- When the weather changes the previous values are set to this. We use this for time based lerps
local WEATHER_STOP = -1 -- The Systime the current weather type should stop at


-- SHARED
StormFox.StormMagnitude = 0
hook.Add( "StormFox-Tick", "StormFox - StormUpdate", function( flTime )

	if not StormFox.tDailyWeatherForecast then return end
	if StormFox.tDailyWeatherForecast.name != "clear" and StormFox.Weather.id != "clear" and math.Round(flTime) > StormFox.tDailyWeatherForecast.trigger then -- Look to trigger a storm
		StormFox.SetWeather( StormFox.tDailyWeatherForecast.name , 0 )
		StormFox.SetData( "Thunder", StormFox.tDailyWeatherForecast.thunder )
		WEATHER_STOP = SysTime() + StormFox.tDailyWeatherForecast.length - ( flTime - StormFox.tDailyWeatherForecast.trigger ) -- Keeps it consistent for clients that join in the middle
		StormFox.tDailyWeatherForecast.trigger = 1600 -- So it never triggers again for this day
	elseif WEATHER_STOP != -1  then -- Handle the current active storm, adjusting its magnitude or ending it
		if SysTime() >= WEATHER_STOP then
			StormFox.Weather = StormFox.GetWeatherType( "clear" )
			WEATHER_STOP = -1
			StormFox.StormMagnitude = 0
			MsgN("Storm over...")
		else
			if WEATHER_STOP - SysTime() <= 30 then -- ending the storm slowly
				StormFox.StormMagnitude = StormFox.tDailyWeatherForecast.percent * ( (WEATHER_STOP - SysTime()) / 30 )
				MsgN("Winding the storm down")
			elseif SysTime() - (WEATHER_STOP - StormFox.tDailyWeatherForecast.length) <= 30 then
				MsgN("Winding the storm up")
				StormFox.StormMagnitude = (SysTime() - (WEATHER_STOP - StormFox.tDailyWeatherForecast.length)) / 30
			end
		end
	end

end )

function StormFox.SetWeather( sWeatherId, flMagnitude )
	if not StormFox.GetWeatherType( sWeatherId ) then print( "[StormFox] Weather not found:", sWeatherId ) return end
	StormFox.Weather = StormFox.GetWeatherType( sWeatherId )
	local flTime = StormFox.GetTime()

	if flMagnitude != 0 then
		StormFox.tDailyWeatherForecast.name = sWeatherId
		StormFox.tDailyWeatherForecast.trigger = flTime + 1
		StormFox.tDailyWeatherForecast.length = 90
		StormFox.tDailyWeatherForecast.percent = clamp( flMagnitude, 0, 1 )
		WEATHER_STOP = -1
	end

	if CLIENT then
		tPreviousWeatherValues = StormFox.GetDataTable()
		StormFox.Weather:UpdateAllVariables( flTime, 0 )
		StormFox.Weather:UpdateTimeBasedDataImmediate( flTime )
	else
		net.Start("StormFox-ForceWeather")
			net.WriteString( sWeatherId )
			net.WriteFloat( flMagnitude or 0 )
		net.Broadcast()
	end
end


-- END SHARED
if SERVER then
	util.AddNetworkString("StormFox-ForceWeather")

	local skyUpdate = 0
	local UPDATE_INTERVAL = 5

	local function weatherThink()
		if skyUpdate > SysTime() then return end
		local flTimeSpeed = StormFox.GetTimeSpeed()
		skyUpdate = SysTime() + UPDATE_INTERVAL / flTimeSpeed

		local flTime = StormFox.GetTime() -- The UPDATE_INTERVAL seconds in the furture (Unless you speed up flTime)

		StormFox.SetData("MapLight", StormFox.Weather:GetLerpedTimeValue( "MapLight", StormFox.GetData("MapLight", 1), flTime ))
		StormFox.SetMapLight( StormFox.GetData("MapLight", 1) )
	end
	hook.Add( "Think", "StormFox - WeatherThink", weatherThink )

end

if CLIENT then

	net.Receive( "StormFox-ForceWeather", function()
		MsgN("[StormFox] Force setting weather at the request of the server")
		StormFox.SetWeather( net.ReadString(), net.ReadFloat() )
	end )

	net.Receive( "StormFox-NextDayWeather", function()
		MsgN("[StormFox] Daily weather received from server")
		StormFox.tDailyWeatherForecast = net.ReadTable()
	end )

	hook.Add( "StormFox-Tick", "StormFox - WeatherUpdate", function( flTime )

		StormFox.SetData("Wind", Lerp( LERP_AMOUNT, StormFox.GetData("Wind", 1), StormFox.tDailyWeatherForecast.wind or 1 ) )
		StormFox.SetData("Temperature", Lerp( LERP_AMOUNT, StormFox.GetData("Temperature", 1), StormFox.tDailyWeatherForecast.temp or 20) )
		StormFox.SetData("WindAngle", Lerp( LERP_AMOUNT, StormFox.GetData("WindAngle", 1), StormFox.tDailyWeatherForecast.windangle or 40) )

	end )


	local skyUpdate = 0
	local UPDATE_INTERVAL = 2
	local sTimeIntervalEnum = StormFox.Weather:GetCurrentTimeInterval( StormFox.GetTime() )
	local function weatherThink()
		if skyUpdate > SysTime() then return end
		local flTimeSpeed = StormFox.GetTimeSpeed()
		skyUpdate = SysTime() + UPDATE_INTERVAL / flTimeSpeed

		local flTime = StormFox.GetTime()

		if sTimeIntervalEnum != StormFox.Weather:GetCurrentTimeInterval( flTime ) then
			tPreviousWeatherValues = StormFox.GetDataTable()
			sTimeIntervalEnum = StormFox.Weather:GetCurrentTimeInterval( flTime )
		end

		StormFox.Weather:UpdateAllVariables( flTime, StormFox.StormMagnitude or 0, tPreviousWeatherValues )

	end
	hook.Add( "StormFox-Tick", "StormFox - WeatherThink", weatherThink )


end -- END CLIENT
