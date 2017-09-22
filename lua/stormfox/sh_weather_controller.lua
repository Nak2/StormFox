
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
end

function StormFox.CalculateMapLight( flTime )
	flTime = flTime or StormFox.GetTime()
	-- Just a function to calc daylight amount based on time. See here https://www.desmos.com/calculator/842tvu0nvq
	local flMapLight = -0.00058 * math.pow( flTime - 750, 2 ) + 100
	return clamp( flMapLight, 1, 100 )
end

if CLIENT then

	local LERP_AMOUNT = 0.1
	local flStormMagnitude = 0.1
	tDailyWeatherForecast = {}
	local tCurrentValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), 0 )

	function StormFox.SetWeather( sWeatherId, flMagnitude )
		if not StormFox.GetWeatherType( sWeatherId ) then print( "[StormFox] Weather not found:", sWeatherId ) return end
		StormFox.Weather = StormFox:GetWeatherType( sWeatherId )
		flMagnitude = clamp( flMagnitude or 1, 0, 1 )

		tCurrentValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), tCurrentValues, 0 )

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
		PrintTable(tDailyWeatherForecast)
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
	local function weatherThink()
		if skyUpdate > SysTime() then return end
		local flTimeSpeed = StormFox.GetTimeSpeed()
		skyUpdate = SysTime() + UPDATE_INTERVAL / flTimeSpeed

		local flTime = StormFox.GetTime() -- The UPDATE_INTERVAL seconds in the furture (Unless you speed up flTime)
		flTime = flTime + UPDATE_INTERVAL / flTimeSpeed

		-- TODO: We need to check when storms start and then they do adjust the third param which is storm amount and also switch StormFox.Weather to that weather type
		tCurrentValues = StormFox.Weather:GetAllVariables( StormFox.GetTime(), tCurrentValues, 0 )

		for index, value in pairs( tCurrentValues ) do -- update the internal variables @TODO: Maybe move this inside of the metatable itself?
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
