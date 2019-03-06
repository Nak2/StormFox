

local Radioactive = StormFox.WeatherType( "radioactive" )
local max,min,ran,round = math.max,math.min,math.random,math.Round
Radioactive.CanGenerate = false
Radioactive.GenerateCondition = function()
	return math.random(4) >= 3
end
Radioactive.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(13.0, 155.9, 13.5),
	TIME_SUNSET = Color(0.4, 55.2, 0.54),
}

local rc = Color(143,148,152)
local a,aa = 0.1,0.4
Radioactive.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(rc.r * aa,rc.g * aa,rc.b * aa),
	TIME_SUNSET = Color(rc.r * a,rc.g * a,rc.b * a),
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
	TIME_SUNSET = 0.99
}

Radioactive.TimeDependentData.Fogstart = {
	TIME_SUNRISE = -1000,
	TIME_SUNSET = -1000
}

Radioactive.TimeDependentData.Fogend = {
	TIME_SUNRISE = 5400,
	TIME_SUNSET = 3000
}
Radioactive.CalculatedData.MapDayLight = 87.5
Radioactive.CalculatedData.MapNightLight = 0
Radioactive.CalculatedData.Gauge = 2
Radioactive.CalculatedData.SunColor = Color(155,255,155,15)
Radioactive.CalculatedData.CloudsAlpha = 155

Radioactive.DataCalculationFunctions.StarFade = function( flPercent ) return max( 1 - flPercent * 10, 0 ) end
Radioactive.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 10 - ( 10 * flPercent ) ) end
Radioactive.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 100 - flPercent * 90 end

Radioactive.StaticData.GaugeColor = Color(65,255,65)
Radioactive.StaticData.EnableThunder = true
Radioactive.StaticData.EnableSnow = false
Radioactive.StaticData.RainTexture = Material("particle/particle_glow_03")
Radioactive.StaticData.RainMultiTexture = Material("particle/warp4_warp")
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
	"player/footsteps/gravel1.wav",
	"player/footsteps/gravel2.wav",
	"player/footsteps/gravel3.wav",
	"player/footsteps/gravel4.wav"
}
function Radioactive.DataCalculationFunctions.MapMaterial(amount,temp,id)
	if (id or "") ~= "radioactive" then return end
	if amount < 0.6 then return end -- Need more toxic
	return "nature/dirtfloor013a",min(round(amount * 2),1),snd
end

local m = Material("stormfox/symbols/Radioactive.png")
function Radioactive:GetIcon()
	return m
end
function Radioactive:GetStaticIcon()
	return m
end
function Radioactive:GetName( nTemperature, nWindSpeed, bThunder  )
	--local m = StormFox.GetNetworkData( "WeatherMagnitude")
	return "Radioactive Rain"
end

local toxamount = 0
local con = GetConVar("sf_weatherdebuffs")
function Radioactive:InRain(ply,mgn)
	if SERVER then
		if not con:GetBool() then return end
		local dmg = DamageInfo()
			dmg:SetDamage(mgn * 7)
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			dmg:SetDamageType(DMG_RADIATION)
		StormFox.CLEmitSound("player/geiger" .. math.random(1,3) .. ".wav",ply)
		ply:TakeDamageInfo(dmg)
	end
end
local mat = Material("particle/rain")
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
	local w,h = ScrW(),ScrH()
	surface.SetMaterial(mat)
	for i=1,10 do
		surface.SetDrawColor(255,255,255,55 * toxamount)
		surface.DrawTexturedRect(ran(w),ran(h),100,100)
	end
end)

StormFox.AddWeatherType( Radioactive )
