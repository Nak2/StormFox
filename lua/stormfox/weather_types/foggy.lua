

local Foggy = StormFox.WeatherType( "fog" )
local max,min = math.max,math.min
Foggy.CanGenerate = true
Foggy.TimeDependentGenerate = {340,400}
Foggy.StormMagnitudeMin = 0.6
Foggy.StormMagnitudeMax = 0.8
Foggy.MaxLength = 1440 / 4
Foggy.GenerateCondition = function()
	return not GetConVar("sf_disablefog"):GetBool() and math.random(4) >= 3
end

Foggy.TimeDependentData.Fogdensity = { -- TODO: Nak, what is this? Please add a comment
			 TIME_SUNRISE = 0.85,
			 TIME_SUNSET = 0.95
		}
Foggy.TimeDependentData.Fogend = { -- TODO: Nak, what is this? Please add a comment
			 TIME_SUNRISE = 680,
			 TIME_SUNSET = 600
		}
Foggy.TimeDependentData.Fogstart = -1000

Foggy.CalculatedData.MapDayLight = 62.5
Foggy.CalculatedData.SunColor = Color(155,255,155,55)

Foggy.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
Foggy.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 9 * flPercent ) ) end
Foggy.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 50 end

local m = Material("stormfox/symbols/Fog.png")
function Foggy:GetIcon()
	return m
end
function Foggy:GetStaticIcon()
	return m
end
function Foggy:GetName( _, _, _  )
	return "Fog"
end


StormFox.AddWeatherType( Foggy )
