
-- Not done yet
--if true then return end

local lava = StormFox.WeatherType( "lava" )
lava.Name = "sf_weather.lava"
lava.StormMagnitudeMin = 0.5
lava.CanGenerate = false
lava.GenerateCondition = function()
	local chance = StormFox.GetNetworkData( "Temperature",0) - 30
	return math.random(100) > 100 - chance
end
local max,min,ran,round = math.max,math.min,math.random,math.Round


lava.TimeDependentData.SkyBottomColor = {
	TIME_SUNRISE = Color(25.5,21.6,17),
	TIME_SUNSET = Color(0.15,0.12,0.1),
}
lava.TimeDependentData.SkyTopColor = {
	TIME_SUNRISE = Color(25.5,21.6,17),
	TIME_SUNSET = Color(0.15,0.12,0.1),
}


lava.CalculatedData.MapDayLight = 60
lava.CalculatedData.MapNightLight = 30

lava.CalculatedData.SunColor = Color(255,155,155,15)

lava.DataCalculationFunctions.StarFade = function( flPercent ) return max( 0.5 - flPercent * 2.5, 0 ) end
lava.DataCalculationFunctions.SunSize = function( flPercent ) return max( 0, 5 - ( 5 * flPercent ) ) end
lava.DataCalculationFunctions.MoonVisibility = function( flPercent ) return 50 - flPercent * 90 end
lava.DataCalculationFunctions.CloudsAlpha = function( flPercent) return 127.5 + 127.5 * flPercent end
lava.StaticData.GaugeColor = Color(65,65,65)
function lava.StaticData.OnGroundWalk(ent) -- Gets called when a player/NPC or nextbot walks on the covered "ground"
	if SERVER then
		local dmg = DamageInfo()
		local speed = math.sqrt(ent:GetVelocity():Length()) / 6
		dmg:SetDamage( speed )
		dmg:SetDamageType( DMG_BURN )
		dmg:SetAttacker(Entity(0))
		dmg:SetInflictor(Entity(0))
		ent:TakeDamageInfo(dmg)
		if math.random(10) >= 9 then
			ent:Ignite(2,2)
		end
	else
		local dlight = DynamicLight( )
		if ( dlight ) then
			dlight.pos = ent:GetPos() + Vector(0,0,10)
			dlight.r = 205
			dlight.g = 255
			dlight.b = 155
			dlight.brightness = math.random(6,8)
			dlight.Decay = 1000
			dlight.Size = 228
			dlight.DieTime = CurTime() + 1.5
		end
		StormFox.WeatherEmitter = StormFox.WeatherEmitter or ParticleEmitter( Vector(0,0,0) )
		if StormFox.WeatherEmitter then
			for i = 1,math.random(4,6) do
				local part = StormFox.WeatherEmitter:Add("particle/particle_smokegrenade",ent:GetPos() + Vector(math.Rand(-10,10),math.Rand(-10,10),math.Rand(0,10)))
				if part then
					part:SetDieTime(1)
					part:SetStartAlpha(155)
					part:SetEndAlpha(0)
					part:SetStartSize(math.random(5,6))
					part:SetEndSize(math.random(12,20))
					part:SetGravity(Vector(0,0,20))
					part:SetVelocity(VectorRand() * 20)
				end
			end
		end
	end
end
lava.DataCalculationFunctions.Fogdensity = function(flPercent)
	return 0.66 + 0.20 * flPercent
end
lava.DataCalculationFunctions.Fogend = function(flPercent)
	local tv = StormFox.GetTimeEnumeratedValue()
	if tv == "TIME_SUNRISE" or tv == "TIME_NOON" then
		--day
		return 3000 - 2200 * flPercent
	else
		--night
		return 3000 - 2200 * flPercent
	end
end
lava.DataCalculationFunctions.Fogstart = function(flPercent)
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

local snd = {
	"player/footsteps/sand1.wav",
	"player/footsteps/sand2.wav",
	"player/footsteps/sand3.wav",
	"player/footsteps/sand4.wav"
}
function lava.DataCalculationFunctions.MapMaterial(amount,temp,id)
	if (id or "") ~= "lava" then return end
	if amount < 0.5 then return end
	return "stormfox/textures/lava_ground","lava",1,snd
end

local m = Material("stormfox/symbols/Lava.png")
function lava:GetIcon()
	return m
end
function lava:GetStaticIcon()
	return m
end
function lava:GetName( _, _, _  )
	return StormFox.Language.Translate("sf_weather.lava_eruption")
end

local mat = Material("particle/rain")
hook.Add("RenderScreenspaceEffects","StormFox - Sandstormeffect",function()

end)

StormFox.AddWeatherType( lava )
