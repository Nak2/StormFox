

local Radioactive = StormFox.WeatherType( "radioactive" )
local max,min = math.max,math.min

Radioactive.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(13.0, 155.9, 13.5),
	TIME_SUNSET = Color(0.4, 55.2, 0.54),
}

Radioactive.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(3.0, 3.9, 3.5),
	TIME_SUNSET = Color(0, 0.525, 0.15),
}

Radioactive.TimeDependentData.DuskColor = {
	TIME_SUNRISE = Color(3, 2.9, 3.5),
	TIME_SUNSET = Color(3, 2.5, .54),
	TIME_NIGHT = Color(.4, .2, .54)
}

Radioactive.TimeDependentData.DuskScale = {
	TIME_SUNRISE = 1,
	TIME_SUNSET = 0.26,
	TIME_NIGHT = 0
}

Radioactive.TimeDependentData.HDRScale = {
	TIME_SUNRISE = 0.33,
	TIME_SUNSET = 0.1
}

Radioactive.TimeDependentData.Fogdensity = {
	TIME_SUNRISE = 0.9,
	TIME_SUNSET = 0.95
}

Radioactive.TimeDependentData.Fogstart = {
	TIME_SUNRISE = -1000,
	TIME_SUNSET = -1000
}

Radioactive.TimeDependentData.Fogend = {
	TIME_SUNRISE = 5400,
	TIME_SUNSET = 3000
}
Radioactive.CalculatedData.MapDayLight = 10
Radioactive.CalculatedData.MapNightLight = 1
Radioactive.CalculatedData.Gauge = 2
Radioactive.CalculatedData.SunColor = Color(155,255,155,15)

Radioactive.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
Radioactive.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
Radioactive.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 90 end

Radioactive.StaticData.GaugeColor = Color(65,255,65)
Radioactive.StaticData.EnableThunder = true
Radioactive.StaticData.EnableSnow = false
Radioactive.StaticData.RainTexture = Material("particle/particle_glow_03")
Radioactive.StaticData.RainMultiTexture = Material("particle/warp4_warp")
Radioactive.StaticData.RainMapMaterial = "nature/snowfloor001a"

local m = Material("hud/killicons/default")
function Radioactive:GetIcon()
	return m
end
function Radioactive:GetStaticIcon()
	return m
end
function Radioactive:GetName( nTemperature, nWindSpeed, bThunder  )
	return "Radioactive"
end

local toxamount = 0
function Radioactive:InRain(ply,mgn)
	if SERVER then
		local con = GetConVar("sf_disableweatherdebuffs")
		if con:GetBool() then return end
		local dmg = DamageInfo()
			dmg:SetDamage(mgn)
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			dmg:SetDamageType(DMG_RADIATION)
		StormFox.CLEmitSound("player/geiger" .. math.random(1,3) .. ".wav",ply)
		ply:TakeDamageInfo(dmg)
	end
end
hook.Add("RenderScreenspaceEffects","StormFox - Toxxeffect",function()
	if not StormFox.Weather then return end
	if StormFox.Weather.id ~= "radioactive" then return end
	local inRain = StormFox.Env.IsInRain()
	if inRain then
		toxamount = min(toxamount + FrameTime(),1)
	else
		toxamount = max(toxamount - FrameTime(),0)
	end
	if toxamount <= 0 then return end
	print(toxamount)
	local tab = {}
	tab[ "$pp_colour_addr" ] = 0
	tab[ "$pp_colour_addg" ] = 0.1 * toxamount
	tab[ "$pp_colour_addb" ] = 0
	tab[ "$pp_colour_brightness" ] = 0.1 * toxamount
	tab[ "$pp_colour_contrast" ] = 1
	tab[ "$pp_colour_colour" ] = 1
	tab[ "$pp_colour_mulr" ] = 0
	tab[ "$pp_colour_mulg" ] = 0.1 * toxamount
	tab[ "$pp_colour_mulb" ] = 0

	DrawColorModify( tab )
end)

StormFox.AddWeatherType( Radioactive )
