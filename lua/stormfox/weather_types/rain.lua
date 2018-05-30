

local RainStorm = StormFox.WeatherType( "rain" )
local max = math.max
RainStorm.CanGenerate = true
RainStorm.StormMagnitudeMin = 0.13
RainStorm.MaxLength = 1440 / 3

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
RainStorm.TimeDependentData.MapBloom = {
	TIME_SUNRISE = 1.2,
	TIME_SUNSET = 1.4
}
RainStorm.TimeDependentData.MapBloomMax = {
	TIME_SUNRISE = 0.4,
	TIME_SUNSET = 1.4
}

RainStorm.CalculatedData.MapDayLight = 12.5
RainStorm.CalculatedData.MapNightLight = 0
RainStorm.CalculatedData.Gauge = 10

RainStorm.CalculatedData.SunColor = Color(255,255,255,15)
RainStorm.CalculatedData.CloudsAlpha = 255

RainStorm.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
RainStorm.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
RainStorm.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 90 end

RainStorm.StaticData.GaugeColor = Color(255,255,255)
RainStorm.StaticData.EnableThunder = true
RainStorm.StaticData.EnableSnow = true
RainStorm.StaticData.RainTexture = Material("stormfox/raindrop.png","noclamp smooth")
RainStorm.StaticData.RainMultiTexture = Material("stormfox/raindrop-multi.png","noclamp smooth")
RainStorm.StaticData.SnowTexture = Material("particle/snow")
RainStorm.StaticData.SnowMultiTexture = Material("stormfox/snow-multi.png","noclamp smooth")
RainStorm.StaticData.SnowMapMaterial = "nature/snowfloor001a"

function RainStorm:GetName( nTemperature, nWindSpeed, bThunder )
		nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
		bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
		nTemperature = nTemperature or StormFox.GetNetworkData("Temperature",20)
	if nWindSpeed >= 10 then
		return "Storm"
	end
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
		nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
		bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
		nTemperature = nTemperature or StormFox.GetNetworkData("Temperature",20)
	if bThunder then return m2 end
	if nWindSpeed > 14 then return m5 end
	if nTemperature < 0 then return m4 end
	if nTemperature < 4 then return m3 end
	return m
end
function RainStorm:GetStaticIcon()
	return m
end

StormFox.AddWeatherType( RainStorm )