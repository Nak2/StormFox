Weather = {}
StormFox.Weather = "Clear"

function StormFox.AddWeather( sWeatherId, tWeatherTable )
	Weather[ sWeatherId ] = tWeatherTable
end

function StormFox.GetWeatherType( sWeatherId )
	return Weather[ sWeatherId ]
end

--[[-------------------------------------------------------------------------
	Valid weather data-templats
	[KeyData] = {Day[,Sunset/sunrise],Night}
	[KeyData] = Varable
	[KeyData] = function(weather %)

	Weathers can also be mixed with percents .. however it will use a function over data

---------------------------------------------------------------------------]]

-- Basic Weatherdata
local floor,round,clamp,min,max = math.floor,math.Round,math.Clamp,math.min,math.max

Weather.Clear = {
	-- SkyPaint
				
	["Topcolor"] = { Color(51, 127.5, 255), Color(0, 0, 0) },
	["Bottomcolor"] = { Color(204, 255, 255), Color(0, 1.5, 5.25) },
				-- Day, [sunrise/sunset,] night
	["FadeBias"] = { 0.3, 0.16, 0.06 },
	["DuskColor"] = { Color(255, 255, 255), Color(255, 204, 0), Color(0, 0, 0) },
	["DuskScale"] = { 1, 0.46, 0 },
	["DuskIntensity"] = { 1, 0.7, 0 },
	["HDRScale"] = { 0.66, 0.1 },
	["StarsEnabled"] = true,
	["StarFade"] = 1,
	["StarSpeed"] = 0.001,
	["DrawStars"] = true,
	["StarTexture"] = "skybox/starfield",

	-- Sun
	["SunSize"] = 20,
	["SunOverlay"] = 20,
	["SunColor"] = Color(255,255,255),
	["MapLight"] = {100,15},
	["SunLight"] = 100,
	["MapBloom"] = {0.2,0.4},
	["MapBloomMax"] = {1,1},

	-- Moon
	["MoonLight"] = 100,
	["MoonColor"] = Color(205,205,205),

	-- Fog
	["Fogdensity"] = {0.8,0.9},
	["Fogend"] = {108000,60000},
	["Fogstart"] = 0,

	-- Rain
	["Gauge"] = 0
}

local BasicClouds = {
	-- SkyPaint
	["SkyColor"] = {Color(3.0, 2.9, 3.5),Color(3.0, 2.9, 3.5)}, -- {Color(30, 29, 35),Color(30, 29, 35)},
	["NightColor"] = {Color(0.4, 0.2, 0.54),Color(0, 0.15, 0.525)}, -- {Color(4, 2, 5.4),Color(0, 1.5, 5.25)},
	["FadeBias"] = {0.3,0.16,0.06},
	["DuskColor"] = {Color(3, 2.9, 3.5),Color(3, 2.5, .54),Color(.4, .2, .54)}, -- {Color(30, 29, 35),Color(30, 25, 5.4),Color(4, 2, 5.4)},
	["DuskScale"] = {1,0.26,0},
	["DuskIntensity"] = {1,0.7,0},
	["HDRScale"] = {0.33,0.1},
	["StarFade"] = function(percent) return max(1 - percent * 10,0) end,

	-- Sun
	["SunSize"] = function(percent) return max(0,10 - (10 * percent)) end,
	["SunOverlay"] = function(percent) return max(0,2 - (2 * percent)) end,
	["SunColor"] = Color(255,255,255,15),
	["MapLight"] = {10,1},
	["SunLight"] = 10,

	-- Moon
	["MoonLight"] = function(percent) return 100 - percent * 90 end,

	-- Fog
	["Fogdensity"] = {0.9,0.95},
	["Fogend"] = {54000,30000},
	["Fogstart"] = {0,-1000},
	-- Rain
	["Gauge"] = 0
}
StormFox.AddWeather("Cloudy",BasicClouds)

local fog = table.Copy( BasicClouds )
fog["Fogstart"] = { -400, -500 }
fog["Fogend"] = { 800, 600 }
fog["Fogdensity"] = { 0.8, 0.8 }
fog["SkyColor"] = { Color( 51, 127.5, 255 ), Color( 204, 255, 255 ) }
StormFox.AddWeather( "Fog", fog )

local Rain = table.Copy( BasicClouds )
	Rain["Gauge"] = function( percent ) return percent * 10 end
	Rain["MapBloom"] = { 1.2, 1.4 }
	Rain["MapBloomMax"] = { 0.4, 1.4 }
StormFox.AddWeather( "Rain", Rain )
