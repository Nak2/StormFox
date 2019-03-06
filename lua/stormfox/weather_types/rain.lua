
local RainStorm = StormFox.WeatherType( "rain" )
local max,min,round = math.max,math.min,math.Round
RainStorm.Name = "sf_weather.rain"
RainStorm.CanGenerate = true
RainStorm.StormMagnitudeMin = 0.13
RainStorm.MaxLength = 1440 / 3

RainStorm.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(3.0, 2.9, 3.5),
	TIME_SUNSET = Color(0.4, 0.2, 0.54),
}

local rc = Color(143,148,152)
local a,aa = 0.1,0.4
RainStorm.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(rc.r * aa,rc.g * aa,rc.b * aa),
	TIME_SUNSET = Color(rc.r * a,rc.g * a,rc.b * a),
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

RainStorm.DataCalculationFunctions.Fogdensity = function(flPercent)
	return 0.50 + 0.4 * flPercent
end
RainStorm.DataCalculationFunctions.Fogend = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 75600 - 74600 * flPercent -- 1000
	else
		--night
		return 16000 - 15200 * flPercent -- 800
	end
end
RainStorm.DataCalculationFunctions.Fogstart = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	local rp = 1 - flPercent
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 3000 * rp
	else
		--night
		return 2000 * rp
	end
end

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

--[[-------------------------------------------------------------------------
MapMaterial controls the material on the ground. 
This function will stay, even after weather change. Until it returns nil or gets replaced by another.
	return:
		#1
			nil = Remove replaced materials and self
			string = Replace all material
		#2 lvl (This can only increase)
			0 = none
			1 = ground only
			2 = ground, pavement and roofs
			3 = ground, pavement, roofs and roads
		#3 snd (Footstep sound)
			string or table
---------------------------------------------------------------------------]]
local snd = {
	"stormfox/footstep/footstep_snow0.ogg",
	"stormfox/footstep/footstep_snow1.ogg",
	"stormfox/footstep/footstep_snow2.ogg",
	"stormfox/footstep/footstep_snow3.ogg",
	"stormfox/footstep/footstep_snow4.ogg",
	"stormfox/footstep/footstep_snow5.ogg",
	"stormfox/footstep/footstep_snow6.ogg",
	"stormfox/footstep/footstep_snow7.ogg",
	"stormfox/footstep/footstep_snow8.ogg",
	"stormfox/footstep/footstep_snow9.ogg"
}
-- Temp: -2 = 0.3, -6 = 1
function RainStorm.DataCalculationFunctions.MapMaterial(amount,temp)
	if temp > -2 then -- Rain
		return
	end
	local lvl = round(amount * 3) * min(max(temp * -0.166,0),1)
	return "nature/snowfloor001a","snow",lvl,snd -- ,"nature/snowfloor002a","nature/snowfloor003a" doesn't look seemless together
end

function RainStorm:GetName( nTemperature, nWindSpeed, bThunder )
	nWindSpeed = nWindSpeed or StormFox.GetNetworkData("Wind",0)
	bThunder = bThunder or StormFox.GetNetworkData("Thunder",false)
	nTemperature = nTemperature or StormFox.GetNetworkData("Temperature",20)
	if nWindSpeed >= 10 then
		return StormFox.Language.Translate("sf_weather.storm")
	end
	if bThunder then return StormFox.Language.Translate("sf_weather.thunder") end
	return ( nTemperature < 4 and nTemperature >= 0 ) and StormFox.Language.Translate("sf_weather.sleet")
		or ( nTemperature < 0 and StormFox.Language.Translate("sf_weather.snowing") or StormFox.Language.Translate("sf_weather.raining") )
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