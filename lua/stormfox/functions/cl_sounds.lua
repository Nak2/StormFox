--
assert(StormFox.Env,"Missing framework!")

local snd_glass =  Sound("stormfox/rain-glass.wav")
local snd_nextto =  Sound("stormfox/rain-light-outside.wav")
local snd_direct =  Sound("stormfox/rain-light.wav")
local snd_roof =  Sound("stormfox/rain_roof.wav")

local snd_windloop = Sound("ambient/ambience/wind_light02_loop.wav")
local snd_windgustlvl = {}
	snd_windgustlvl[1] = {Sound("ambient/wind/wind_hit2.wav"),Sound("ambient/wind/wind_hit1.wav")}
	snd_windgustlvl[2] = {Sound("ambient/wind/wind_med1.wav"),Sound("ambient/wind/wind_med2.wav")}
	snd_windgustlvl[3] = {Sound("ambient/wind/windgust.wav"),Sound("ambient/wind/windgust_strong.wav")}

_STORMFOX_SOUNDTAB = _STORMFOX_SOUNDTAB or {}

-- Handles sounds by distance
local function playSound(datatab,lvl,snd)
	if not _STORMFOX_SOUNDTAB[datatab] then
		_STORMFOX_SOUNDTAB[datatab] = CreateSound(LocalPlayer(),snd)
		_STORMFOX_SOUNDTAB[datatab]:SetSoundLevel( 0 )
	end
	if _STORMFOX_SOUNDTAB[datatab]:IsPlaying() and lvl <= 0 then
		_STORMFOX_SOUNDTAB[datatab]:FadeOut(0.2)
	elseif lvl >= 0 then
		if not _STORMFOX_SOUNDTAB[datatab]:IsPlaying() then
			_STORMFOX_SOUNDTAB[datatab]:PlayEx(lvl,100)
		else
			_STORMFOX_SOUNDTAB[datatab]:ChangeVolume(lvl)
		end
	end
end

local min,max,clamp = math.min,math.max,math.Clamp
hook.Add("StormFox - EnvUpdate","StormFox - RainSounds",function()
	if not LocalPlayer() then return end
	local con = GetConVar("sf_allow_rainsound")
	-- Don't play any sound if con is set
	local Gauge = StormFox.GetData("Gauge",0) -- How much rain
	local temp = StormFox.GetNetworkData("Temperature",20) -- Is snow

	if not con:GetBool() or Gauge <= 0 or not StormFox.EFEnabled() then
		playSound("Windows",0,snd_glass)
		playSound("Outdoors",0,snd_direct)
		playSound("Nextto",0,snd_nextto)
		playSound("Roof",0,snd_roof)
		return
	end
	local tempamount = max(0.14 * temp + 0.29,0)
	local soundAmmount = Gauge / 10 * tempamount
	playSound("DirectRain",soundAmmount * (StormFox.Env.IsInRain() and 1 or 0),snd_direct)

	playSound("Window",min(StormFox.Env.FadeDistanceToWindow() * soundAmmount * 0.4,0.4),snd_glass)

	local next_to = 0
	if StormFox.Env.NearOutside() then
		if StormFox.Env.IsOutside() then
			next_to = 1
		else
			next_to = 0.5
		end
	elseif StormFox.Env.IsOutside() then
		next_ro = 1
	end
	playSound("Nextto",next_to * soundAmmount * 0.5,snd_nextto)

	playSound("Roof",StormFox.Env.FadeDistanceToRoof() * soundAmmount * 0.2,snd_roof)
end)

local windGust = 0
local clamp = math.Clamp
hook.Add("StormFox - EnvUpdate","StormFox - WindSounds",function()
	if not LocalPlayer() then return end
	local con = GetConVar("sf_allow_windsound")
	-- Don't play any sound if con is set
	local Wind = math.floor(StormFox.GetNetworkData("Wind",0)) -- How much rain
	local temp = StormFox.GetData("Temperature",20) -- Is snow

	if not con:GetBool() or Wind <= 0 then
		playSound("Wind",0,snd_windloop)
		return
	end
	local inWind = StormFox.Env.IsInRain()
	local nearWindow = StormFox.Env.FadeDistanceToWindow()
	local nearOutside = StormFox.Env.NearOutside()
	local isOutside = StormFox.Env.IsOutside()

	local windAmount = 0
	if inWind then
		windAmount = 1
	elseif isOutside  then
		windAmount = 0.75
	elseif nearOutside then
		windAmount = 0.5
	else
		windAmount = 0.5 * nearWindow
	end
	if windGust <= SysTime() then
		windGust = SysTime() + math.random(10,30)
		local lvl = math.floor(math.Round(Wind / 6))
		if lvl < 1 then return end
		lvl = clamp(lvl,1,#snd_windgustlvl)
		if inWind then
			LocalPlayer():EmitSound(table.Random(snd_windgustlvl[lvl]),75,100,Wind / 20 * windAmount * 0.2)
		elseif nearOutside then
			LocalPlayer():EmitSound(table.Random(snd_windgustlvl[lvl]),75,100,Wind / 20 * windAmount * 0.2)
		end
	end
	local nn = clamp(Wind / 20 * windAmount,0,1)
	playSound("Wind",nn * 0.2,snd_windloop)
end)

local conVar = GetConVar("sf_disableambient_sounds")
hook.Add("EntityEmitSound","StormFox BlockSounds",function(data)
	if not conVar then return end
	if not conVar:GetInt() then return end
	if not IsValid(data.Entity) then return end
	if not data.Entity:IsWorld() then return end
	if data.OriginalSoundName:sub(0,8) ~= "ambient/" then return end

	return false
end)