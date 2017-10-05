
local Cloudy = StormFox.WeatherType( "cloudy" )
local max = math.max
Cloudy.CanGenerate = true
Cloudy.StormMagnitudeMin = 0.2
Cloudy.StormMagnitudeMax = 0.8
Cloudy.MaxLength = 1440 / 2

Cloudy.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0.4, 0.2, 0.54),
}

Cloudy.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0, 0.15, 0.525),
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
	TIME_SUNRISE = 54000,
	TIME_SUNSET = 30000
}
Cloudy.CalculatedData = {
	MapDayLight = 20,
	MapNightLight = 2
}
Cloudy.CalculatedData.SunColor = Color(255,255,255,15)

Cloudy.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
Cloudy.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
Cloudy.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 90 end

Cloudy.StaticData.EnableThunder = true

function Cloudy:GetName( nTemperature, nWindSpeed, bThunder  )
	if bThunder then return "Thunder" end

	return "Cloudy"
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