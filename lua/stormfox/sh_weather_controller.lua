
local clamp = math.Clamp
local min = math.min

if SERVER then
	util.AddNetworkString("StormFox-ForceWeather")

	function StormFox.SetWeather( sWeatherId, nPercent )
		net.Start("StormFox-ForceWeather")
			net.WriteString( sWeatherId )
			net.WriteFloat( nPercent or 1 )
		net.Broadcast()
	end

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

	local LERP_AMOUNT = 0.02
	local flStormMagnitude = 0
	local tDailyWeatherForecast = {}
	local tCurrentValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), 0 )
	local tPreviousWeatherValues = tCurrentValues-- When the weather changes the previous values are set to this. We use this for time based lerps

	function StormFox.SetWeather( sWeatherId, flMagnitude )
		if not StormFox.GetWeatherType( sWeatherId ) then print( "[StormFox] Weather not found:", sWeatherId ) return end
		StormFox.Weather = StormFox:GetWeatherType( sWeatherId )
		flMagnitude = clamp( flMagnitude or 0, 0, 1 )
		tPreviousWeatherValues = tCurrentValues
		flStormMagnitude = 0
		tCurrentValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), flMagnitude, tPreviousWeatherValues )
	end



	net.Receive( "StormFox-ForceWeather", function()
		MsgN("[StormFox] Force setting weather at the request of the server")
		StormFox.SetWeather( net.ReadString(), net.ReadFloat() )
	end )

	net.Receive( "StormFox-NextDayWeather", function()
		MsgN("[StormFox] Daily weather received from server")
		tDailyWeatherForecast = net.ReadTable()
	end )

	hook.Add( "StormFox-Tick", "StormFox - WeatherUpdate", function( flTime )

		StormFox.SetData("Wind", Lerp( LERP_AMOUNT, StormFox.GetData("Wind", 1), tDailyWeatherForecast.wind or 1 ) )
		StormFox.SetData("Temperature", Lerp( LERP_AMOUNT, StormFox.GetData("Temperature", 1), tDailyWeatherForecast.temp or 20) )
		StormFox.SetData("WindAngle", Lerp( LERP_AMOUNT, StormFox.GetData("WindAngle", 1), tDailyWeatherForecast.windangle or 40) )

		if tDailyWeatherForecast.name != "Clear" and flTime == tDailyWeatherForecast.trigger  then
			StormFox.SetWeather( tDailyWeatherForecast.name , tDailyWeatherForecast.percent or 1 )
			StormFox.SetData( "Thunder", tDailyWeatherForecast.thunder )
		elseif flTime == tDailyWeatherForecast.stoptime then
			StormFox.SetWeather( "Clear" )
		end

	end )


	local skyUpdate = 0
	local UPDATE_INTERVAL = 5
	local sTimeIntervalEnum = StormFox.Weather:GetCurrentTimeInterval( StormFox.GetTime() )
	local function weatherThink()
		if skyUpdate > SysTime() then return end
		local flTimeSpeed = StormFox.GetTimeSpeed()
		skyUpdate = SysTime() + UPDATE_INTERVAL / flTimeSpeed

		local flTime = StormFox.GetTime()
		-- TODO: We need to check when storms start and then they do adjust the third param which is storm amount and also switch StormFox.Weather to that weather type

		if sTimeIntervalEnum != StormFox.Weather:GetCurrentTimeInterval( flTime ) then
			tPreviousWeatherValues = tCurrentValues
			sTimeIntervalEnum = StormFox.Weather:GetCurrentTimeInterval( flTime )
		end

		tCurrentValues = StormFox.Weather:GetAllVariables( flTime, 0, tPreviousWeatherValues )
		for index, value in pairs( tCurrentValues ) do
			StormFox.SetData( index, value )
		end
		
		-- local daytime = StormFox.GetDaylightAmount( flTime )
		--
		-- local n = (CurrentWeatherData["StarFade"] or 1.5) * clamp(((1 - daytime) - 0.5) * 2,0,1)
		-- StormFox.SetData("StarFade",n)
		-- if n > 0 then
		-- 	StormFox.SetData("DrawStars",CurrentWeatherData["DrawStars"])
		-- 	StormFox.SetData("StarTexture",CurrentWeatherData["StarTexture"])
		-- 	StormFox.SetData("StarSpeed",CurrentWeatherData["StarSpeed"])
		-- end
		--
		-- StormFox:SetData("MapLight", StormFox.CalculateMapLight( flTime ))

	end
	hook.Add( "Think", "StormFox - WeatherThink", weatherThink )


end -- END CLIENT
