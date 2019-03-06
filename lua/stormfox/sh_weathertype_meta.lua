
-- Setup Metatable
	StormFox.WeatherType = {}
	StormFox.WeatherType.__index = StormFox.WeatherType

	function StormFox.WeatherType.new( sId )
		if type( sId ) ~= "string" then
			error("ERROR: Attempted to create new WeatherType with invalid ID. String expected, Got: " .. type(sId) )
		end

		local metaWeatherType = {}
		metaWeatherType.id = sId
		return setmetatable( metaWeatherType, table.Copy(StormFox.WeatherType) )
	end

	-- Allows you to initialize a weather type using StormFox.WeatherType("<id>")
	function StormFox.WeatherType.__call( _, ... )
		return StormFox.WeatherType.new( ... )
	end
	setmetatable( StormFox.WeatherType, { __call = StormFox.WeatherType.__call } )

-- Clear data data
	StormFox.WeatherType.CanGenerate = false -- Its hardcoded to be pickable.
	-- Time enumerations
	StormFox.WeatherType.TIME_SUNRISE = 360
	StormFox.WeatherType.TIME_SUNSET = 1080

	-- Data having to do with skybox color, lighting etc that is more dependent on the time of day then the storm conditions
	StormFox.WeatherType.TimeDependentData = {
		--[[SkyTopColor = { -- The top color painted in the skybox
			TIME_SUNRISE = Color(91, 127.5, 255),
			TIME_NOON = Color(51, 127.5, 255),
			TIME_SUNSET = Color(130, 130, 180),
			TIME_NIGHT = Color(0, 0, 0)
		},
		SkyBottomColor = { -- The bottom color painted in the skybox
			TIME_SUNRISE = Color(91, 127.5, 255),
			TIME_NOON = Color(204, 255, 255),
			TIME_SUNSET = Color(0, 1.5, 5.25),
			TIME_NIGHT = Color(0, 1.5, 5.25)
		},]]
		SkyTopColor = { -- The top color painted in the skybox
			TIME_SUNRISE = Color(91, 127.5, 255),
			--TIME_NOON = Color(0.04 * 255,0.18*255,0.38*255),
			TIME_NOON = Color(28,110,191),
			TIME_SUNSET = Color(130, 130, 180),
			TIME_NIGHT = Color(0, 0, 0)
		},
		SkyBottomColor = { -- The bottom color painted in the skybox
			TIME_SUNRISE = Color(91, 127.5, 255),
			TIME_NOON = Color(0.31 * 255, 0.77 * 255, 255),
			TIME_SUNSET = Color(0, 1.5, 5.25),
			TIME_NIGHT = Color(0, 1.5, 5.25)
		},
		FadeBias = { -- 
			TIME_SUNRISE = 0.2,
			TIME_SUNSET = 0.16,
			TIME_NIGHT = 1
		},
		DuskColor = { -- The color of the skybox at dusk
			 TIME_SUNRISE = Color(255, 204, 0),
			 TIME_SUNSET = Color(255, 204, 0),
			 TIME_NIGHT = Color(0, 0, 0),
			 TIME_NOON = Color(255, 0.2 * 255, 255)
		},
		DuskIntensity = { -- How intense the sunset/sunrise is
			 TIME_SUNRISE = 1.94,
			 TIME_SUNSET = 0.7,
			 TIME_NIGHT = 0
		},
		DuskScale = {
			TIME_SUNRISE = 0.29,
			 TIME_SUNSET = 0.2,
			 TIME_NIGHT = 0
		},
		HDRScale = { -- 
			 TIME_SUNRISE = 0.7,
			 TIME_NOON = 0.7,
			 TIME_SUNSET = 0.7
		},
		StarFade = {
				TIME_SUNRISE = 0.2,
				TIME_NOON = 0,
				TIME_SUNSET = 0.2,
				TIME_NIGHT = 1
		},
		MapBloom = {
				TIME_SUNRISE = 0.2,
				TIME_SUNSET = 0.4
			},
		MapBloomMin = 0.5,
		MapBloomMax = {
				TIME_SUNRISE = 1,
				TIME_SUNSET = 1
			},
		Fogcolor = nil -- Skycolor
	}
	-- Data that is either static or computed. If you set the value to be a function then when the storms power changes these values will update
	StormFox.WeatherType.CalculatedData = {
		SunSize = 20,
		MoonVisibility = 100,
		SunColor = Color( 255, 255, 255 ),
		MoonColor = Color( 205, 205, 205 ),
		Gauge = 0,
		MapDayLight = 100,
		MapNightLight = 0,
		CloudsAlpha = 0
	}
	-- Here you can add functions that update any of the values in CalculatedData when the storm magnitude changes.
	StormFox.WeatherType.DataCalculationFunctions = {
		Fogstart = function() return StormFox.GetNetworkData("fog_start",0) end,
		Fogend = function(_,time_id)
			local def = StormFox.GetNetworkData("fog_end",450000)
			if time_id == "TIME_SUNSET" or time_id == "TIME_NIGHT" then
				def = def * 0.6 -- 40%
			end
			return def
		end,
		Fogdensity = function(_,time_id) -- Its darker at night
			local dens = StormFox.GetNetworkData("fogmaxdensity",0.2)
			if time_id == "TIME_SUNSET" or time_id == "TIME_NIGHT" then
				dens = 0.8
			end
			return dens
		end,


		-- Example:
		-- MoonLight = function( stormMag ) return 100 * ( 1-stormMag ) end,
	}
	-- Data that is set once and remains the same value. No lerping or time interpolation or anything. The values don't change
	StormFox.WeatherType.StaticData = {
		StarSpeed = 0.001,
		StarScale = 2.2,
		StarTexture = "skybox/starfield",
		MoonTexture = "stormfox/effects/moon.png",
		GaugeColor = Color(255,255,255),
		EnableThunder = false
	}
	StormFox.WeatherType.Name = "sf_weather.clear"
	function StormFox.WeatherType:GetName( _, nWindSpeed, bThunder  )
		nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
		bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)

		if bThunder then
			return StormFox.Language.Translate("sf_weather.thunder")
		end
		local bfs,des = StormFox.GetBeaufort(nWindSpeed)
		if bfs >= 1 then
			return des
		end
		return StormFox.Language.Translate("sf_weather.clear")
	end

	local m = Material("stormfox/symbols/Sunny.png")
	local m4 = Material("stormfox/symbols/Windy.png")
	local m5 = Material("stormfox/symbols/Icy.png")
	local m6 = Material("stormfox/symbols/Night.png")
	local m8 = Material("stormfox/symbols/Thunder.png")
	function StormFox.WeatherType:GetIcon( nTemperature, nWindSpeed, bThunder )
		nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
		bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
		nTemperature = nTemperature or StormFox.GetNetworkData("Temperature",20)
		if bThunder then
			return m8
		elseif nWindSpeed > 14 then
			return m4
		elseif nTemperature <= 0 then
			return m5
		end

		local flTime = StormFox.GetTime()
		local bIsNight = flTime < 340 or flTime > 1075
		return bIsNight and m6 or m
	end
	function StormFox.WeatherType.GetStaticIcon()
		return m
	end

-- Setup weatherfunctins
	local tPreviousTimeIntervals = { TIME_SUNRISE = "TIME_NIGHT", TIME_NOON = "TIME_SUNRISE", TIME_SUNSET = "TIME_NOON", TIME_NIGHT = "TIME_SUNSET" }
	local function timeToEnumeratedValue( flTime )
		if flTime <= StormFox.Weather.TIME_SUNRISE - 60 then
			return "TIME_NIGHT"
		elseif flTime < StormFox.Weather.TIME_SUNRISE then
			return "TIME_SUNRISE"
		elseif flTime < StormFox.Weather.TIME_SUNSET then
			return "TIME_NOON"
		elseif flTime < StormFox.Weather.TIME_SUNSET + 60 then
			return "TIME_SUNSET"
		else
			return "TIME_NIGHT"
		end
	end
	function StormFox.GetTimeEnumeratedValue(t)
		if not t then t = StormFox.GetTime() end
		if t <= StormFox.Weather.TIME_SUNRISE - 60 then
			return "TIME_NIGHT"
		elseif t < StormFox.Weather.TIME_SUNRISE then
			return "TIME_SUNRISE"
		elseif t < StormFox.Weather.TIME_SUNSET then
			return "TIME_NOON"
		elseif t < StormFox.Weather.TIME_SUNSET + 60 then
			return "TIME_SUNSET"
		else
			return "TIME_NIGHT"
		end
	end

	function StormFox.WeatherType:GetData( sVariableName, flTime, dontcheck )
		if self.TimeDependentData[ sVariableName ] then
			local cur_id = timeToEnumeratedValue(flTime or StormFox.GetTime())
			local tab = self.TimeDependentData[ sVariableName ]
			if type(tab) ~= "table" or (tab.r and tab.g and tab.b and tab.a) then
				return self.TimeDependentData[ sVariableName ]
			elseif self.TimeDependentData[ sVariableName ][cur_id] then
				return self.TimeDependentData[ sVariableName ][cur_id]
			elseif self.TimeDependentData[ sVariableName ][tPreviousTimeIntervals[cur_id]] then
				return self.TimeDependentData[ sVariableName ][tPreviousTimeIntervals[cur_id]]
			end
		elseif self.CalculatedData[ sVariableName ] then
			return self.CalculatedData[ sVariableName ]
		elseif self.StaticData[ sVariableName ] then
			return self.StaticData[ sVariableName ]
		else
			--ErrorNoHalt("[StormFox]: " .. sVariableName .. " is not found\n" .. debug.traceback() .. "\n")
			if not dontcheck then
				return StormFox.WeatherType("clear"):GetData( sVariableName, flTime, true )
			end
			return nil
		end
	end
	function StormFox.WeatherType:SetData( sVariableName, variable, flTime )
		if type(variable) == "function" then
			self.DataCalculationFunctions[sVariableName] = variable
		elseif type(flTime) == "string" then
			if not self.TimeDependentData[sVariableName] then
				self.TimeDependentData[sVariableName] = {}
			end
			self.TimeDependentData[sVariableName][flTime] = variable
		elseif flTime then
			self.StaticData[ sVariableName ] = variable
		else
			self.CalculatedData[ sVariableName ] = variable
		end
	end

-- For managing the table of weather types. Not worth putting it in a new file cause its only 2 small funcs

StormFox.WeatherTypes = StormFox.WeatherTypes or {
	clear = StormFox.WeatherType.new("clear")
}

StormFox.Weather = StormFox.Weather or StormFox.WeatherTypes[ "clear" ] -- Current weather
StormFox.AddMapSetting("weather_clear",true)

function StormFox.AddWeatherType( metaWeatherType )
	if not metaWeatherType.id then
		error("Attempted to add invalid weather type. You must use an instance of the StormFox.WeatherType class")
	end

	StormFox.WeatherTypes[ metaWeatherType.id ] = metaWeatherType
	StormFox.AddMapSetting("weather_" .. metaWeatherType.id,metaWeatherType.CanGenerate or false)
	MsgN( "[StormFox] Weather Type: " .. metaWeatherType.id .. " initialized." )
end

function StormFox.GetWeatherType( sWeatherId )
	return StormFox.WeatherTypes[ sWeatherId ]
end

function StormFox.GetWeathers()
	return table.GetKeys(StormFox.WeatherTypes)
end
function StormFox.GetWeathersDefaultNumber()
	for i,v in ipairs(table.GetKeys(StormFox.WeatherTypes)) do
		if v == "clear" then
			return i
		end
	end
	return 1
end