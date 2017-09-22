

local RainStorm = StormFox.WeatherType( "rain" )

RainStorm.StormMagnitudeMin = 0.2

RainStorm.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0.4, 0.2, 0.54),
}

RainStorm.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0, 0.15, 0.525),
}

RainStorm.TimeDependentData.DuskColor = {
	TIME_SUNRISE = Color(3, 2.9, 3.5),
	TIME_SUNSET = Color(3, 2.5, .54),
	TIME_NIGHT = Color(.4, .2, .54)
}

RainStorm.TimeDependentData.DuskScale = {
	TIME_SUNRISE = 1,
	TIME_SUNSET = 0.26,
	TIME_NIGHT = 0
}

RainStorm.TimeDependentData.HDRScale = {
	TIME_SUNRISE = 0.33,
	TIME_SUNSET = 0.1
}

RainStorm.TimeDependentData.MapLight = {
	TIME_SUNRISE = 8,
	TIME_NOON = 10,
	TIME_SUNSET = 4,
	TIME_NIGHT = 1
}

RainStorm.TimeDependentData.Fogdensity = {
	TIME_SUNRISE = 0.9,
	TIME_SUNSET = 0.95
}

RainStorm.TimeDependentData.Fogstart = {
	TIME_SUNRISE = 0,
	TIME_SUNSET = -1000
}

RainStorm.TimeDependentData.Fogend = {
	TIME_SUNRISE = 54000,
	TIME_SUNSET = 30000
}
RainStorm.CalculatedData.SunColor = Color(255,255,255,15)

RainStorm.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
RainStorm.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
RainStorm.DataCalculationFunctions.MoonLight = function( flPercent ) return 100 - flPercent * 90 end

function RainStorm:GetName( nTemperature, nWindSpeed, bThunder  )
	if bThunder then return "Thunder" end

	return ( nTemperature < 4 and nTemperature >=0 ) and "Sleet"
		or ( nTemperature < 0 and "Snowing" or "Raining" )
end

local m = Material("stormfox/symbols/Raining.png")
local m2 = Material("stormfox/symbols/Raining - Thunder.png")
local m3 = Material("stormfox/symbols/RainingSnowing.png")
local m4 = Material("stormfox/symbols/Snowing.png")
local m5 = Material("stormfox/symbols/Raining - Windy.png")
function RainStorm:GetIcon( nTemperature, nWindSpeed, bThunder )
	if bThunder then return m2 end
	if nWindSpeed > 14 then return m5 end
	if temp < 0 then return m4 end
	if temp < 4 then return m3 end
	return m
end

StormFox.AddWeatherType( RainStorm )
