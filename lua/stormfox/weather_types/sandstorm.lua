
-- Not done yet
--if true then return end

local Sandstorm = StormFox.WeatherType( "sandstorm" )
Sandstorm.StormMagnitudeMin = 0.5
Sandstorm.CanGenerate = false
Sandstorm.GenerateCondition = function()
	return StormFox.GetNetworkData("Wind",0) > 30
end
local max,min,ran,round = math.max,math.min,math.random,math.Round

Sandstorm.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(255,216,170),
	TIME_SUNSET = Color(0.15,0.12,0.1),
}

Sandstorm.CalculatedData.MapDayLight = 90

Sandstorm.DataCalculationFunctions.Fogdensity = function(flPercent)
	return 0.50 + 0.49 * flPercent
end
Sandstorm.DataCalculationFunctions.Fogend = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 4000 - 3800*flPercent
	else
		--night
		return 4000 - 3450*flPercent
	end
end
Sandstorm.DataCalculationFunctions.Fogstart = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	local rp = 1 - flPercent
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 2000 * rp
	else
		--night
		return 1000 * rp
	end
end

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
	"player/footsteps/sand1.wav",
	"player/footsteps/sand2.wav",
	"player/footsteps/sand3.wav",
	"player/footsteps/sand4.wav"
}
function Sandstorm.DataCalculationFunctions.MapMaterial(amount,temp,id)
	if (id or "") ~= "sandstorm" then return end
	if amount < 0.5 then return end
	return "nature/sandfloor009a",min(round(amount * 2),1),snd
end

local m = Material("stormfox/symbols/Sandstorm.png")
function Sandstorm:GetIcon()
	return m
end
function Sandstorm:GetStaticIcon()
	return m
end
function Sandstorm:GetName( nTemperature, nWindSpeed, bThunder  )
	return "Sandstorm"
end

local toxamount = 0
local mat = Material("particle/rain")
hook.Add("RenderScreenspaceEffects","StormFox - Sandstormeffect",function()

end)

StormFox.AddWeatherType( Sandstorm )
