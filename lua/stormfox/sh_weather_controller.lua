
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

	-- Weather Brain
	local function LerpVariable(at_zero,at_one,percent) -- Number, table and color
		--if not percent then percent = 1 end
		if percent <= 0 then
			if type(at_zero) == "function" then
				return at_zero(percent)
			else
				return at_zero
			end
		end
		if percent >= 1 or type(at_zero) != type(at_one) then
			if type(at_one) == "function" then
				return at_one(percent)
			else
				return at_one
			end
		end
		if type(at_zero) == "number" then
			local delta = at_one - at_zero -- Deltavar
			return at_zero + delta * percent
		elseif type(at_zero) == "table" then
			if at_zero.a and at_zero.r and at_zero.g and at_zero.b then
				-- color
				local r = LerpVariable(at_zero.r,at_one.r,percent)
				local g = LerpVariable(at_zero.g,at_one.g,percent)
				local b = LerpVariable(at_zero.b,at_one.b,percent)
				local a = LerpVariable(at_zero.a,at_one.a,percent)
				return Color(r,g,b,a)
			else
				-- A table of stuff? .. or what.
				local tab = table.Copy(at_zero)
				for key,var in pairs(at_one) do
					tab[key] = LerpVariable(at_zero[key],var,percent)
				end
				return tab
			end
		elseif type(at_one) == "function" then
			return at_one(percent)
		elseif type(at_zero) == "function" then
			return at_one(percent)
		end
		if percent < 0.5 then
			return at_zero
		end
		return at_one
	end


	local UPDATE_INTERVAL = 10
	local LERP_AMOUNT = 0.5
	local CurrentWeatherData = table.Copy( StormFox.GetWeatherType("Clear") )
	local tDailyWeatherForecast = {}


	function StormFox.SetWeather( name, percent )
		if not StormFox.GetWeatherType( name ) then print( "[StormFox] Weather not found:", name ) return end
		StormFox.Weather = name
		percent = clamp( percent or 1, 0, 1 )

		CurrentWeatherData = table.Copy( StormFox.GetWeatherType( "Clear" ) )
		if percent <= 0 then
			return CurrentWeatherData
		end
		for key,data in pairs(StormFox.GetWeatherType(name)) do
			if not CurrentWeatherData[key] then
				CurrentWeatherData[key] = data
			else
				CurrentWeatherData[key] = LerpVariable( CurrentWeatherData[ key ], data, percent )
			end
		end
		return CurrentWeatherData
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

	local function Get(var,id)
		if type(var) == "table" then
			return var[id] or var[1]
		end
		return var
	end

	local skyUpdate = 0
	local function weatherThink()
		if skyUpdate > SysTime() then return end
		local flTimeSpeed = StormFox.GetTimeSpeed()
		skyUpdate = SysTime() + UPDATE_INTERVAL / flTimeSpeed

		local flTime = StormFox.GetTime() -- The UPDATE_INTERVAL seconds in the furture (Unless you speed up flTime)
		flTime = flTime + UPDATE_INTERVAL / flTimeSpeed

		local daytime = StormFox.GetDaylightAmount( flTime )
		local cTopColor = StormFox.GetData( "Topcolor", Color(10,10,220) )
		local cBottomColor = StormFox.GetData( "Bottomcolor", Color( 110, 0, 202))
		local timeIndex = flTime < 720 and 0 or 1

		local cTargetTop = CurrentWeatherData["Topcolor"][timeIndex] or Color(10,10,220)
		local cTargetBottom = CurrentWeatherData["Bottomcolor"][timeIndex] or Color(10,10,220)
		-- This is temporary. Ill replace it with a better solution soon
		StormFox.SetData("Topcolor", Color( Lerp( LERP_AMOUNT, cTopColor.r, cTargetTop.r ), Lerp( LERP_AMOUNT, cTopColor.g, cTargetTop.g ), Lerp( LERP_AMOUNT, cTopColor.b, cTargetTop.b ) ) )
		StormFox.SetData("Bottomcolor",Color( Lerp( LERP_AMOUNT, cBottomColor.r, cTargetBottom.r ), Lerp( LERP_AMOUNT, cBottomColor.g, cTargetBottom.g ), Lerp( LERP_AMOUNT, cBottomColor.b, cTargetBottom.b ) ) )


		local n = (CurrentWeatherData["StarFade"] or 1.5) * clamp(((1 - daytime) - 0.5) * 2,0,1)
		StormFox.SetData("StarFade",n)
		if n > 0 then
			StormFox.SetData("DrawStars",CurrentWeatherData["DrawStars"])
			StormFox.SetData("StarTexture",CurrentWeatherData["StarTexture"])
			StormFox.SetData("StarSpeed",CurrentWeatherData["StarSpeed"])
		end

		StormFox:SetData("MapLight", StormFox.CalculateMapLight( flTime ))


		local blacklist = {"SkyColor","NightColor","StarFade"}
			for key,var in pairs(CurrentWeatherData) do
				if not table.HasValue(blacklist,key) then
					if type(var) == "table" then
						if (var.r and var.g and var.b) or #var < 2 then
							-- Just color or something
							StormFox.SetData(key,var)
						else
							-- Alright, flTime based
							if #var == 2 then
								-- Day, night
								local nn = LerpVariable(var[1],var[2],1 - daytime)
								StormFox.SetData(key,nn)
							else
								-- Day, sunset/sunrise, night
								local p = daytime * 2 -- DayLight [0-2] (0 night, 1 sunset/rise, 2 day)
								if daytime > 0.5 then -- 0 horizon - 1 day
									p = (daytime - 0.5) * 2 -- (0 sunset/rise, 1 day)
									local nn = LerpVariable(var[2],var[1],p)
									StormFox.SetData(key,nn)
								else -- 0 night - 1 horizon
									local nn = LerpVariable(var[3],var[2],min(p * 1.25,1)) -- (1.25 gives a nice 'effect' as sunrise is quicker)
									StormFox.SetData(key,nn)
								end
							end
						end
					elseif type(var) != "function" then
						-- String, numbers, set varables
						StormFox.SetData(key,var)
					end
				end
			end
	end
	hook.Add( "Think", "StormFox - WeatherThink", weatherThink )


end -- END CLIENT
