
local Cloudy = StormFox.WeatherType( "cloudy" )
local max = math.max
Cloudy.Name = "sf_weather.cloudy"
Cloudy.CanGenerate = true
Cloudy.StormMagnitudeMin = 0.13
Cloudy.StormMagnitudeMax = 0.8
Cloudy.MaxLength = 1440 / 2

Cloudy.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0.4, 0.2, 0.54),
}

local rc = Color(143,148,152)
local a,aa = 0.1,0.4
Cloudy.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(rc.r * aa,rc.g * aa,rc.b * aa),
	TIME_SUNSET = Color(rc.r * a,rc.g * a,rc.b * a),
}


Cloudy.TimeDependentData.DuskColor = {
	TIME_SUNRISE = Color(3, 2.9, 3.5),
	TIME_SUNSET = Color(3, 2.5, .54),
	TIME_NIGHT = Color(.4, .2, .54)
}

Cloudy.TimeDependentData.DuskScale = {
	TIME_SUNRISE = 1,
	TIME_SUNSET = 0.26,
	TIME_NIGHT = 0
}

Cloudy.TimeDependentData.HDRScale = {
	TIME_SUNRISE = 0.33,
	TIME_SUNSET = 0.1
}

Cloudy.TimeDependentData.Fogdensity = {
	TIME_SUNRISE = 0.9,
	TIME_SUNSET = 0.95
}

Cloudy.TimeDependentData.Fogstart = {
	TIME_SUNRISE = 0,
	TIME_SUNSET = -1000
}

Cloudy.TimeDependentData.Fogend = {
	 TIME_SUNRISE = 108000 * 2,
	 TIME_SUNSET = 30000 * 1.5
}
Cloudy.CalculatedData.MapDayLight = 25
Cloudy.CalculatedData.MapNightLight = 0
Cloudy.CalculatedData.CloudsAlpha = 255

Cloudy.CalculatedData.SunColor = Color(255,255,255,15)

Cloudy.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 5, 0 ) end
Cloudy.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
Cloudy.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 90 end

Cloudy.StaticData.EnableThunder = true

function Cloudy:GetName( _, _, bThunder  )
	bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
	if bThunder then return StormFox.Language.Translate("sf_weather.thunder") end
	return StormFox.Language.Translate("sf_weather.cloudy")
end

local m = Material("stormfox/symbols/Cloudy.png")
local m2 = Material("stormfox/symbols/Thunder.png")
local m3 = Material("stormfox/symbols/Cloudy_Windy.png")
local m4 = Material("stormfox/symbols/Night - Cloudy.png")
function Cloudy:GetIcon(_, nWindSpeed, bThunder )
	bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
	nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
	if bThunder then return m2 end
	if nWindSpeed > 14 then return m3 end
	local flTime = StormFox.GetTime()
	local bIsNight = flTime < 340 or flTime > 1075
	return bIsNight and m4 or m
end

function Cloudy:GetStaticIcon()
	return m
end

StormFox.AddWeatherType( Cloudy )