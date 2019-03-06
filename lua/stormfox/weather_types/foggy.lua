

local Foggy = StormFox.WeatherType( "fog" )
local max,min = math.max,math.min
Foggy.CanGenerate = true
Foggy.TimeDependentGenerate = {340,400}
Foggy.StormMagnitudeMin = 0.6
Foggy.StormMagnitudeMax = 0.9
Foggy.MaxLength = 1440 / 4
Foggy.GenerateCondition = function()
	return GetConVar("sf_enablefog"):GetBool() and math.random(4) >= 3
end
local rc = Color(231,233,240)
local a,aa = 0.2,1
Foggy.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(rc.r * aa,rc.g * aa,rc.b * aa),
	TIME_SUNSET = Color(rc.r * a,rc.g * a,rc.b * a),
}

Foggy.DataCalculationFunctions.Fogdensity = function(flPercent)
	return 0.50 + 0.49 * flPercent
end
Foggy.DataCalculationFunctions.Fogend = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 8000 - 7800*flPercent
	else
		--night
		return 8000 - 6900*flPercent
	end
end
Foggy.DataCalculationFunctions.Fogstart = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	local rp = 1 - flPercent
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 4000 * rp
	else
		--night
		return 2000 * rp
	end
end

Foggy.CalculatedData.MapDayLight = 92.5
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
function Foggy:GetName( nTemperature, nWindSpeed, _  )
	local m = StormFox.GetNetworkData( "WeatherMagnitude")
	if m <= 0.5 then
		return "Light Fog"
	elseif m <= 0.8 then
		return "Fog"
	else
		return "Heavy fog"
	end
end


StormFox.AddWeatherType( Foggy )
