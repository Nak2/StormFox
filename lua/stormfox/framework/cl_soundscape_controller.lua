--[[-------------------------------------------------------------------------
	Functions:
		StormFox.SoundScape.GetLoopSounds()					Returns the current loopsounds.
		StormFox.SoundScape.GetRandomSounds()				Returns the current randomsounds.
		StormFox.SoundScape.GetData() 						Returns the current soundscape data.
		StormFox.SoundScape.Reset() 						Resets the current soundscape.
		StormFox.SoundScape.Set(target_name) 				Activates the soundscape of an env_soundscape with that targetname.
		StormFox.SoundScape.FindScript(soundscape_name) 	Returns a soundscape-script with that name.
		StormFox.SoundScape.GetAll() 						Returns all soundscapes on the map, in form of a data-table.
	Hooks:
		StormFox.SoundScape.OnUpdate	SoundScape_Data 	Allows you to edit the soundscape table.
		StormFox.SoundScape.OnPlay 		Sound 		vol		Return a string to replace or false to block. Second argument can edit the volume.
---------------------------------------------------------------------------]]

-- Local tables and functions
	local clamp,max,min = math.Clamp,math.max,math.min
	local wind_sounds = {}
		wind_sounds.volscale = {} 	-- 5ms  - 45ms
		wind_sounds.low = {} 		-- 5ms  - 15ms
		wind_sounds.medium = {} 	-- 0.5 15ms - 25ms
		wind_sounds.high = {} 		-- 0.5 25ms - 45ms
	local replace_atnight = {}
	local replace_atday = {}
	local replace_atbadweather = {}
	local replace_belowtemp = {}
	CreateClientConVar("soundscape_debug2",0)
	local devcon = GetConVar("soundscape_debug2")
	local addcon = GetConVar("sf_addmapsounds")
	--[[local function devPrint(...)
		if not (devcon and devcon:GetBool()) then return end
		print(...)
	end]]
	--[[-------------------------------------------------------------------------
		Vol 	0 - 20ms (0 - 1 vol)
		Low wind: 0-10 ms (0 - 1 vol)
		Medium wind: 10-20 ms (0.5 - 1 vol)
		High wind: 20 - 30 ms (0.5 - 1 vol)
	---------------------------------------------------------------------------]]
	local function AddWindSound(snd_low,snd_medium,snd_high)
		if snd_medium or snd_high then
			wind_sounds.low[snd_medium] = snd_low
			wind_sounds.low[snd_high] = snd_low
			wind_sounds.medium[snd_low] = snd_medium
			wind_sounds.medium[snd_high] = snd_medium
			wind_sounds.high[snd_low] = snd_high
			wind_sounds.high[snd_medium] = snd_high
		else
			wind_sounds.volscale[snd_low] = true
		end
	end
	local function AddReplaceDayNight(snd_day,snd_night) -- nil is also an option to block it
		if not snd_day and snd_night then
			replace_atday[snd_night] = "nil"
			return
		end
		replace_atnight[snd_day] = snd_night or "nil"
		if not snd_night then return end
		replace_atday[snd_night] = snd_day
	end
	local function AddReplaceBadWeather(snd_original,snd_replace) -- nil is also an option to block it
		replace_atbadweather[snd_original] = snd_replace or "nil"
	end
	local function AddReplaceAtLowTemp(snd_original,snd_replace,min_temp)
		replace_belowtemp[snd_original] = {snd_replace,min_temp}
	end
	local function GuessSound(snd)	-- sound_type, only_night, lowest_temp
		if string.match(snd,"bird") or string.match(snd,"crow") then
			return "life",false,-5
		elseif string.match(snd,"owl") then
			return "life",true
		elseif string.match(snd,"frog") then
			return "life",true,5
		elseif string.match(snd,"dog") then
			return "life",false
		elseif string.match(snd,"wolf") then
			return "life"
		elseif string.match(snd,"snake") then
			return "life",false,5
		elseif string.match(snd,"cricket") then
			return "life",true,13
		elseif string.match(snd,"flies") then
			return "life",false,5
		elseif string.match(snd,"bugs") then
			return "life",false,5
		elseif string.match(snd,"life") then
			return "life",false,7
		end
	end
	local function HandleSound(snd,bIsNight,bBadWeather,nWind,nTemp)
		local dn,bw,osnd = false,false,snd
		-- DayNight
			if replace_atnight[snd] and bIsNight then
				snd = replace_atnight[snd]
				dn = true
			elseif replace_atday[snd] and not bIsNight then
				snd = replace_atday[snd]
				dn = true
			end
		-- Bad Weather
			if replace_atbadweather[snd] and bBadWeather then
				snd = replace_atbadweather[snd]
				bw = true
			end
		-- Low temp
			if replace_belowtemp[snd] and replace_belowtemp[snd][2] > nTemp then
				snd = replace_belowtemp[snd][1]
				lt = true
			end
		-- Guess
			if not dn and not bw then
				local _type,only_night,lowest_temp = GuessSound(snd)
				if _type == "life" and bBadWeather then
					snd = "nil"
				elseif _type == "life" then
					if lowest_temp and nTemp < lowest_temp then
						snd = "nil"
					end
					if only_night ~= nil then
						if only_night and not bIsNight then
							snd = "nil"
						elseif not only_night and bIsNight then
							snd = "nil"
						end
					end
				end
			end
		return snd ~= osnd and snd
	end
	local function IsWind(snd,nWind)
		if wind_sounds.volscale[snd] then return nil,clamp(nWind / 20,0,1) end
		if nWind <= 10 and wind_sounds.low[snd] then
			return wind_sounds.low[snd],clamp(nWind / 10,0,1)
		elseif nWind <= 20 and wind_sounds.medium[snd] then
			return wind_sounds.medium[snd],clamp(nWind / 20,0.5,1)
		elseif nWind <= 30 and wind_sounds.high[snd] then
			return wind_sounds.high[snd],clamp( (nWind - 10) / 20,0.5,1)
		elseif string.match(snd,"wind") then
			return nil,clamp(nWind / 20,0,1)
		end
	end
-- Sound replace list (In this order)
	-- DayNight
		AddReplaceDayNight("ambient/forest_day.wav","ambient/forest_night.wav")
		AddReplaceDayNight("ambient/forest_life.wav","ambient/forest_night.wav")
	-- Bad Weather
		AddReplaceBadWeather("ambient/outdoors_quiet_birds.wav","ambient/outdoors.wav")
		AddReplaceBadWeather("ambient/forest_day.wav","nil")
		AddReplaceBadWeather("ambient/forest_life.wav","nil")
		AddReplaceBadWeather("ambient/forest_night.wav","nil")
	-- Low temp
		--AddReplaceAtLowTemp("ambient/forest_night.wav","nil",7)
		--AddReplaceAtLowTemp("ambient/forest_life.wav","nil",7)
		--AddReplaceAtLowTemp("ambient/forest_day.wav","nil",-5)
-- Sound add list
	local outside = {}
	local inside = {}
		outside.loopsound = {}
		inside.loopsound = {}

	hook.Add("StormFox.SoundScape.OnUpdate","StormFox.SoundScape.Controller",function(soundscape)
		local bad_weather,_,is_night,last_temp = StormFox.SoundScape._EnvironmentVars()
		local nwind = StormFox.GetNetworkData("Wind",0)
		local snd = {}
		-- Check playloop
			for k,v in ipairs(soundscape.playlooping or {}) do
				local override = HandleSound(v.wave,is_night,bad_weather,nwind,last_temp)
				table.insert(snd,v.wave)
				if override then
					--devPrint("Overriding",v.wave,"to",override)
					soundscape.playlooping[k].wave = override
				else
					local override,vol = IsWind(v.wave,nwind)
					if override then
						--devPrint("Overriding",v.wave,"to",override)
						soundscape.playlooping[k].wave = override
					end
					if vol then -- Loopsounds can be important, even if its just wind. We always need some sound in the background.
						vol = math.Round(vol,2)
						local minvol = min(v.volume[1] or 0,v.volume[2] or 0,0.1)
						--devPrint("Overriding volume of",v.wave,"to",max(vol,minvol))
						soundscape.playlooping[k].volume[1] = max(vol,minvol)
						soundscape.playlooping[k].volume[2] = max(vol,minvol)
					end
				end
			end
		-- Check playrandom
			for k,v in ipairs(soundscape.playrandom or {}) do
				for i,wave in ipairs(v.wave) do
					table.insert(snd,wave)
					local override = HandleSound(wave,is_night,bad_weather,nwind,last_temp)
					if override then
						--devPrint("Overriding",wave,"to",override)
						soundscape.playrandom[k].wave[i] = override
					else
						local override,vol = IsWind(wave,nwind)
						if override then
							--devPrint("Overriding",wave,"to",override)
							soundscape.playrandom[k].wave[i] = override
						end
						if vol then
							--devPrint("Overriding volume of",wave,"to",vol)
							soundscape.playrandom[k].volume[1] = vol
							soundscape.playrandom[k].volume[2] = vol
						end
					end
				end
			end
		-- Add sounds
		if not (addcon and addcon:GetBool()) then return end
		local guess_state = StormFox.SoundScape.GetEnvState()
		if guess_state == 0 then return end -- We don't know
		if guess_state < 0 then -- We're outside

		else -- We're inside

		end
	end)