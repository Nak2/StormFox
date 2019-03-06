--[[-------------------------------------------------------------------------
	Soundscapes are a bit tricky
	If we disable one .. the last will just continue to play.

	We need to make our own system.

	Functions:
		StormFox.SoundScape.Enabled() 						Returns true if the soundscape is overwriten
		StormFox.SoundScape.GetLoopSounds()					Returns the current loopsounds.
		StormFox.SoundScape.GetRandomSounds()				Returns the current randomsounds.
		StormFox.SoundScape.GetData() 						Returns the current soundscape data.
		StormFox.SoundScape.Reset() 						Resets the current soundscape.
		StormFox.SoundScape.Set(target_name) 				Activates the soundscape of an env_soundscape with that targetname.
		StormFox.SoundScape.FindScript(soundscape_name) 	Returns a soundscape-script with that name.
		StormFox.SoundScape.GetAll() 						Returns all soundscapes on the map, in form of a data-table.
		StormFox.SoundScape.GetEnvState() 					A lot of scripts got "outdoor" or "indoor" in their name. We might be able to use that.
			Return data:
				-1 		Outside
				0 		Unknown
				1 		Indoors
	Hooks:
		StormFox.SoundScape.OnUpdate	SoundScape_Data 	Allows you to edit the soundscape table.
		StormFox.SoundScape.OnPlay 		Sound 		vol		Return a string to replace or false to block. Second argument can edit the volume.
---------------------------------------------------------------------------]]
	local conVar = GetConVar("sf_overridemapsounds")
	if not conVar:GetBool() then
		StormFox.SoundScape = {}
		-- Fix scripts breaking when disabled
			function StormFox.SoundScape.GetLoopSounds() return {}	end
			function StormFox.SoundScape.GetRandomSounds() return {} end
			function StormFox.SoundScape.GetAll() return {}	end
			function StormFox.SoundScape.GetData() return {} end
			function StormFox.SoundScape.Reset() end
			function StormFox.SoundScape.Set() end
			function StormFox.SoundScape.FindScript() return end
			function StormFox.SoundScape.GetEnvState() return 0 end
			function StormFox.SoundScape.Enabled()
				return false
			end
		return
	end

StormFox.SoundScape = {}
	function StormFox.SoundScape.Enabled()
		return true
	end
	local con = GetConVar("soundscape_fadetime")
	local devcon = GetConVar("developer")
	local sndcon = GetConVar("soundscape_debug")
	local DEFAULT_SOUND_RADIUS = 36.0
	local util_TraceLine = util.TraceLine
	local abs,Approach,cos,sin,rad = math.abs,math.Approach,math.cos,math.sin,math.rad
	STORMFOX_SOUNDSCAPE = STORMFOX_SOUNDSCAPE or {}							-- Global varable
	STORMFOX_SOUNDSCAPE_ENTITY = STORMFOX_SOUNDSCAPE_ENTITY or {}			-- Soundscape position entities
	STORMFOX_SOUNDSCAPE.playlooping = STORMFOX_SOUNDSCAPE.playlooping or {} -- List of looping sounds. We keep this global in case of reload.
	STORMFOX_SOUNDSCAPE.playrandom = STORMFOX_SOUNDSCAPE.playrandom or {} 	-- List of random sounds.
	function StormFox.SoundScape.GetLoopSounds()
		return STORMFOX_SOUNDSCAPE.playlooping
	end
	function StormFox.SoundScape.GetRandomSounds()
		return STORMFOX_SOUNDSCAPE.playrandom
	end
	local currentSoundscapeID = 0
	-- Local functions
		local function ET(pos,pos2,mask)
			local trace = util_TraceLine( {
				start = pos,
				endpos = pos2,
				mask = mask,
				filter = LocalPlayer():GetViewEntity() or LocalPlayer()
			} )
			if not trace then -- tracer failed, this should not happen. Create a fake result.
				local fake = {}
					fake.HitPos = pos2
					fake.Hit = false
				return fake
			end
			trace.HitPos = trace.HitPos or pos2
			return trace
		end
		local function RandomSoundPos()
			local lp = StormFox.GetCalcViewResult().pos
			local rc = rad(math.random(359))
			return lp + Vector(cos(rc),sin(rc),0) * DEFAULT_SOUND_RADIUS
		end
	-- Stop a sound
		local function StopSound(snd,fadeover)
			if not STORMFOX_SOUNDSCAPE.playlooping[snd] then return end
			local dif = STORMFOX_SOUNDSCAPE.playlooping[snd][1] / (fadeover / 3)
			STORMFOX_SOUNDSCAPE.playlooping[snd][3] = {0,dif}
		end
	-- Play a sound
		local function PlaySound(snd,soundlvl,pitch,volume,dsp,fadeover,ent)
			if not file.Exists("sound/" .. snd,"GAME") then return end -- Unknown sound. I hate red errors
			if volume <= 0 then return end
			if snd == "nil" then return end
			if not dsp then dsp = 1 else dsp = tonumber(dsp) end
			if dsp >= 20 or dsp <= 22 then dsp = 1 end -- Somehow sound breaks at dsp 20,21 and 22.
			-- Call hook
				local r,v = hook.Run("StormFox.SoundScape.OnPlay",snd)
				if not r and r ~= nil then return end
				if type(r) == "string" then	snd = r	end
				if v then volume = v end
			if not ent then
				ent = ent or Entity(0)
				soundlvl = 0
			end
			-- Setup the varables
				if not STORMFOX_SOUNDSCAPE.playlooping[snd] then
					STORMFOX_SOUNDSCAPE.playlooping[snd] = {
						[1] = 0.01,			-- Current volume
						[2] = ent, -- Current entity this is playing on
						[3] = {volume,CurTime() + fadeover} -- Target volume
					}
				end
			-- Stop all sounds on old entity
				local old_ent = STORMFOX_SOUNDSCAPE.playlooping[snd][2]
				if old_ent ~= ent and IsValid(old_ent) then
					old_ent.sf_soundscape[snd]:FadeOut(fadeover)
					old_ent.sf_soundscape[snd] = nil
				end
			-- Set the new entities
				STORMFOX_SOUNDSCAPE.playlooping[snd][2] = ent
			-- Play the sound on the entity
				if not ent.sf_soundscape then ent.sf_soundscape = {} end
				if not ent.sf_soundscape[snd] then
					ent.sf_soundscape[snd] = CreateSound(ent,snd)
					ent.sf_soundscape[snd]:SetSoundLevel(soundlvl or 80)
					ent.sf_soundscape[snd]:SetDSP(dsp or 1)
					ent.sf_soundscape[snd]:PlayEx(STORMFOX_SOUNDSCAPE.playlooping[snd][1],pitch)
				else
					ent.sf_soundscape[snd]:SetSoundLevel(soundlvl or 80)
					ent.sf_soundscape[snd]:SetDSP(dsp or 1)
				end
				local dif = abs( STORMFOX_SOUNDSCAPE.playlooping[snd][1] - volume ) / fadeover
				STORMFOX_SOUNDSCAPE.playlooping[snd][3] = {volume,dif} -- Target volume
		end
	-- Play a random sound
		local function PlayRandomSound(snd,soundlvl,pitch,volume,dsp,ent)
			if not file.Exists("sound/" .. snd,"GAME") then return end -- Unknown sound
			if volume <= 0 then return end
			if snd == "nil" then return end
				local r,v = hook.Run("StormFox.SoundScape.OnPlay",snd)
				if not r and r ~= nil then return end
				if type(r) == "string" then	snd = r	end
				if v then volume = v end
			if STORMFOX_SOUNDSCAPE.playrandom[snd] then
				if STORMFOX_SOUNDSCAPE.playrandom[snd][1] then
					STORMFOX_SOUNDSCAPE.playrandom[snd][1]:Stop()
				end
				STORMFOX_SOUNDSCAPE.playrandom[snd] = nil
			end
			-- 	RandomSoundPos()
			if not ent then
				ent = Entity(0)
				soundlvl = 0
			end
			snd_obj = CreateSound(ent,snd)
				snd_obj:SetSoundLevel(soundlvl or 80)
				snd_obj:SetDSP(dsp or 1)
				snd_obj:PlayEx(volume,pitch)
			STORMFOX_SOUNDSCAPE.playrandom[snd] = {snd_obj,ent,SoundDuration(snd) + CurTime()}
		end
	-- Play a random sound at a location
		local function PlayRandomSoundLocation(snd,pos,soundlvl,pitch,volume,ent)
			if not file.Exists("sound/" .. snd,"GAME") then return end -- Unknown sound
			if volume <= 0 then return end
			if snd == "nil" then return end
				local r,v = hook.Run("StormFox.SoundScape.OnPlay",snd)
				if not r and r ~= nil then return end
				if type(r) == "string" then	snd = r	end
				if v then volume = v end
			if not ent then
				ent = Entity(0)
				soundlvl = 0
			end
			-- Just in case .. however sounds at locations can't be stopped.
				if STORMFOX_SOUNDSCAPE.playrandom[snd] then
					if STORMFOX_SOUNDSCAPE.playrandom[snd][1] then
						STORMFOX_SOUNDSCAPE.playrandom[snd][1]:Stop()
					end
					STORMFOX_SOUNDSCAPE.playrandom[snd] = nil
				end
			-- 	RandomSoundPos()
				--EmitSound(string soundName,Vector position,number entity,number channel=CHAN_AUTO,number volume=1,number soundLevel=75,number soundFlags=0,number pitch=100)
				EmitSound(snd,pos,-1,nil,volume,soundlvl or 80,nil,pitch)
			STORMFOX_SOUNDSCAPE.playrandom[snd] = {nil,ent,SoundDuration(snd) + CurTime()}
		end
	-- Fade script
		timer.Create("StormFox.SoundScape.Fader",1,0,function()
			for snd,tab in pairs(STORMFOX_SOUNDSCAPE.playlooping) do
				if not tab[3] then continue end
				local vol_target,vol_amount,vol_current = tab[3][1],tab[3][2],tab[1]
				if vol_target ~= vol_current then -- Not there yet
					local nextstep = Approach(vol_current,vol_target,vol_amount)
					tab[2].sf_soundscape[snd]:ChangeVolume(nextstep,1)
					STORMFOX_SOUNDSCAPE.playlooping[snd][1] = nextstep
				else -- We reached the goal
					STORMFOX_SOUNDSCAPE.playlooping[snd][3] = nil
					if STORMFOX_SOUNDSCAPE.playlooping[snd][1] <= 0 then -- If volume is 0, we should remove the sound
						tab[2].sf_soundscape[snd]:Stop()
						tab[2].sf_soundscape[snd] = nil
						STORMFOX_SOUNDSCAPE.playlooping[snd] = nil
					end
				end
			end
		end)
	-- Read the soundscapes
		local function ReadLooping(f)
			local t = {}
			for i = 1,20 do
				local l = f:ReadLine()
				local key,var = string.match(l,[["([^"]+)"%s*"([^"]+)"]])
				if key then
					if key == "dps" then
						t[key] = tonumber(var)
					else
						t[key] = var
					end
				end
				if string.match(l,"}") then return t end
			end
			return t
		end
		local function ReadSoundscape(f)
			local t = {}
			for i = 1,20 do
				local l = f:ReadLine()
				local key,var = string.match(l,[["([^"]+)"%s*"([^"]+)"]])
				if key then
					if key == "dps" then
						t[key] = tonumber(var)
					else
						t[key] = var
					end
				end
				if string.match(l,"}") then return t end
			end
			return t
		end
		local function ReadRandom(f)
			local t = {}
			local lvl = 0
			for i = 1,80 do
				local l = f:ReadLine()
				local key,var = string.match(l,[["([^"]+)"%s*"([^"]+)"]])
				if key then
					if key == "wave" then
						t.wave = t.wave or {}
						table.insert(t.wave,var)
					elseif key == "dps" then
						t[key] = tonumber(var)
					else
						t[key] = var
					end
				end
				if string.match(l,"{") then
					lvl = lvl + 1
				elseif string.match(l,"}") then
					lvl = lvl - 1
					if lvl <= 0 then return t end
				end
			end
			return t
		end
		local function ReadSoundScapeFile(fil)
			local f = file.Open(fil,"r","GAME")
			local lvl = 0
			local soundscape = {}
			local cur_soundscape
			local cur_tab = {}
			for i = 1,2500 do -- I hate while loops
				local l = f:ReadLine()
				-- Check if its something useful
					if not l then break end
					l = l:sub(0,#l-1)
					l = string.match(l,"^%s*(.+)%s*$") -- Trim
					if not l then continue end
					if l:sub(0,2) == "//" then continue end
					local lvlh = string.match(l,"[%{%}]")
					if lvlh then
						l = string.gsub(l,"[%{%}]","")
						if lvlh == "{" then
							lvl = lvl + 1
							if lvl == 2 then
								table.Empty(cur_tab)
							end
						elseif lvlh == "}" then
							lvl = lvl - 1
						end
					end
					if not string.match(l,"[%w%{%}]") then continue end -- In case its empty
				if lvl == 0 then
					l = string.match(l,[["(.+)"]]) or l
					l = l:lower()
					soundscape[l] = {}
					cur_soundscape = l
				elseif lvl == 1 then
					local key,var = string.match(l,[["([^"]+)"%s*"([^"]+)"]])
					if not key then
						key = string.match(l,[["([^"]+)"]])
						soundscape[cur_soundscape][key] = soundscape[cur_soundscape][key] or {}
						if key == "playrandom" then
							table.insert(soundscape[cur_soundscape][key],ReadRandom(f))
						elseif key == "playsoundscape" then
							table.insert(soundscape[cur_soundscape][key],ReadSoundscape(f))
						elseif key == "playlooping" then
							table.insert(soundscape[cur_soundscape][key],ReadLooping(f))
						end
					else
						if key == "dps" then
							soundscape[cur_soundscape][key] = tonumber(var)
						else
							soundscape[cur_soundscape][key] = var
						end
					end
				end
			end
			f:Close()
			return soundscape
		end
		local function ReadsoundScapeFolder(tab,folder)
			if not tab then tab = {} end
			local files,folders = file.Find(folder .. "/*","GAME")
			for _,v in pairs(files) do
				--if not string.match(v,".txt$") then continue end // Never mind. The .vsc is just a glorified .txt file for CSGO. 
				local path = folder .. "/" .. v
				for k,v in pairs(ReadSoundScapeFile(path)) do
					tab[k:lower()] = v
				end
			end
			for _,v in ipairs(folders) do
				local path = folder .. "/" .. v
				ReadsoundScapeFolder(tab,path)
			end
		end
		local soundscapes
		local function GetAllSoundScapes()
			if soundscapes then return soundscapes end
			StormFox.Msg("Loading soundscapes ...")
			local files = file.Find("scripts/soundscapes*","GAME")
			local t = {}
			for k,v in pairs(files) do
				if not string.match(v,".txt$") then continue end
				local ft = ReadSoundScapeFile("scripts/" .. v)
				for sndscape,data in pairs(ft) do
					t[sndscape] = data
				end
			end
			ReadsoundScapeFolder(t,"scripts/soundscapes")
			soundscapes = t
			return soundscapes
		end
		local function GetEntityLocation(str) -- entfindbyname not working on client .. gotta make my own. With blackjack and hookers.
			if STORMFOX_SOUNDSCAPE_ENTITY[str] then
				if IsValid(STORMFOX_SOUNDSCAPE_ENTITY[str]) then
					return STORMFOX_SOUNDSCAPE_ENTITY[str]
				else
					STORMFOX_SOUNDSCAPE_ENTITY[str] = nil
				end
			end
			for id,ent in ipairs(ents.FindByClass("stormfox_soundscape")) do
				if ent:GetNWString("targetname","NULL") ~= str then continue end
				STORMFOX_SOUNDSCAPE_ENTITY[str] = ent
				return ent
			end
		end
	-- Load the soundscapes
		local snd_list = {}
		local trigger_snd_list = {}
		local function SoundScapes() -- Lists the soundscape entities in the map and some useful data.
			if #snd_list > 0 then return snd_list end
			-- Load the soundscape list
				local snd = GetAllSoundScapes()
			-- Get the list of soundscape data from the map.
				for id,data in pairs(StormFox.MAP.Entities()) do
					if data.classname == "env_soundscape" then
						local t = {}
						t.soundscape = data.soundscape:lower()
						t.radius = data.radius
						t.powradius = data.radius^2 -- Cause its faster
						--t.mapdata = data
						local v = util.StringToType(data.origin or "0 0 0","Vector")
						t.origin = Vector(math.Round(v.x),math.Round(v.y),math.Round(v.z))
						t.snd = snd[t.soundscape] or {}
						t.classname = data.classname
						t.targetname = data.targetname
						t.data = data
						t.soundpositions = {}
							for i = 0,7 do
								if data["position" .. i] then
									t.soundpositions[i] = GetEntityLocation(data["position" .. i])
								end
							end
						table.insert(snd_list,t)
					elseif data.classname == "env_soundscape_proxy" then
						local t = {}
						t.mainsoundscapename = data.mainsoundscapename
						t.radius = data.radius
						t.powradius = data.radius^2 -- Cause its faster
						--t.mapdata = data
						t.origin = util.StringToType(data.origin or "0 0 0","Vector")
						t.proxy = true
						table.insert(snd_list,t)
					elseif data.classname == "env_soundscape_triggerable" then
						local t = {}
						t.trigger = true
						t.soundscape = data.soundscape:lower()
						t.radius = data.radius
						t.powradius = data.radius^2 -- Cause its faster
						--t.mapdata = data
						t.origin = util.StringToType(data.origin or "0 0 0","Vector")
						t.snd = snd[t.soundscape] or {}
						t.classname = data.classname
						t.targetname = data.targetname
						t.data = data
						t.soundpositions = {}
							for i = 0,7 do
								if data["position" .. i] then
									t.soundpositions[i] = GetEntityLocation(data["position" .. i])
								end
							end
						trigger_snd_list[t.targetname] = table.insert(snd_list,t)
					end
				end
			return snd_list
		end
		function StormFox.SoundScape.GetAll()
			return SoundScapes()
		end
		local function FindSoundScapeByTargetName(str) -- Returns name and data
			for k,v in ipairs(SoundScapes()) do
				if v.targetname == str then
					return v.soundscape,k
				end
			end
		end
	-- Environment ( This is used to determen when to update the soundscape )
		local bad_weather,last_wind,is_night,last_temp
		local function IsBadWeather()
			if bad_weather == nil then return false end -- In case we run before SF loaded
			local weather_id = StormFox.GetWeatherID()
			if weather_id == "lava" then return true end
			if StormFox.GetNetworkData("Wind",0) > 9 then return true end
			if weather_id == "clear" then return false end
			local weather_amo = StormFox.GetNetworkData( "WeatherMagnitude", 0)
			if weather_id == "fog" and weather_amo < 0.7 then return false end
			if weather_id == "cloudy" and weather_amo < 0.7 then return false end
			local gauge = StormFox.GetData("Gauge",0)
			if gauge < 1 then return false end
			return true
		end
		local function SetEnvironmentVariables()
			bad_weather = IsBadWeather()
			last_wind = math.ceil(StormFox.GetNetworkData("Wind",0) / 5)
			is_night = StormFox.IsNight()
			last_temp =  math.ceil(StormFox.GetNetworkData("Temperature",0) / 5)
		end
		local function IsNewEnvironment()
			if bad_weather ~= IsBadWeather() then return true end
			if last_wind ~= math.ceil(StormFox.GetNetworkData("Wind",0) / 5) then return true end
			if is_night ~= StormFox.IsNight() then return true end
			if last_temp ~= math.ceil(StormFox.GetNetworkData("Temperature",0) / 5) then return true end
			return false
		end
		function StormFox.SoundScape._EnvironmentVars()
			return bad_weather,last_wind,is_night,last_temp
		end
	-- SoundScape updater
		local function NumVal(str,oldvar,div) -- Will allow to apply sub-sound volume and pitch
			if not div then div = 1 end
			if not oldvar then oldvar = {1,1} end
			local n = tonumber(str)
			if n then
				return {n / div * oldvar[1],n / div * oldvar[2]}
			end
			local a,b = string.match(str,"([%.%d%s]+),([%.%d%s]+)")
			return {tonumber(a) / div * oldvar[1],tonumber(b) / div * oldvar[2]}
		end
		local snd_scape_list = {}
		local function ListSoundsFromSoundScape(str,volume,pitch,tab,dsp,cache_2,position_override) -- Lists all sounds from a soundscape
			if cache and snd_scape_list[cache] then
				return snd_scape_list[cache]
			end
			str = str:lower()
			if not volume then volume = {1,1} end
			if not pitch then pitch = {1,1} end
			if not tab then
				tab = {}
				tab.playlooping = {}
				tab.playrandom = {}
				tab.playsoundscape = {}
			end
			local data = GetAllSoundScapes()[str]
			if not data then print("StormFox unknwon soundscape: " .. str) return {} end -- Unknown soundscape
			for k,v in pairs(data.playlooping or {}) do
				local t = {}
					t.dsp = dsp
					t.volume = NumVal(v.volume or "1",volume)
					t.pitch = NumVal(v.pitch or "100",pitch,100)
					t.wave = v.wave
					t.soundlevel = v.soundlevel
					t.position = position_override or v.position
					t.positionoverride = v.positionoverride
					t.ambientpositionoverride = v.ambientpositionoverride
					t.attenuation = v.attenuation
				table.insert(tab.playlooping,t)
			end
			for k,v in pairs(data.playrandom or {}) do
				local t = {}
					t.dsp = dsp
					t.time = NumVal(v.time or "0")
					t.volume = NumVal(v.volume or "1",volume)
					t.pitch = NumVal(v.pitch or "100",pitch,100)
					t.soundlevel = v.soundlevel
					t.wave = v.wave
					t.position = position_override or v.position
					t.positionoverride = v.positionoverride
					t.ambientpositionoverride = v.ambientpositionoverride
					t.attenuation = v.attenuation
				table.insert(tab.playrandom,t)
			end
			for k,v in pairs(data.playsoundscape or {}) do
				local vo = NumVal(v.volume or "1",volume)
				local p = NumVal(v.pitch or "100",pitch,100)
				local override = position_override or v.positionoverride
				ListSoundsFromSoundScape(v.name,vo,p,tab,dsp,nil,override)
				--table.insert(tab.playsoundscape,v)
			end
			if cache then
				snd_scape_list[cache] = tab
			end
			return tab
		end
		local function GetSoundscape(snd_id)
			local name = SoundScapes()[snd_id].soundscape
			currentSoundscapeID = snd_id
			-- Check if it copies a soundscape
				if snd_list[snd_id].mainsoundscapename then
					name,snd_id = FindSoundScapeByTargetName(snd_list[snd_id].mainsoundscapename)
				end
			-- Check if valid
				if not snd_list[snd_id] then
					print("StormFox unknwon soundscape_id: " .. tostring(snd_id))
					return
				end
			-- Place sounds
				local soundscape = {}
					soundscape.playlooping = {}
					soundscape.playrandom = {}
					soundscape.soundpositions = snd_list[snd_id].soundpositions
				-- Load the sounds
					local dsp = snd_list[snd_id].snd.dsp or 1
					for k,v in pairs(snd_list[snd_id].snd.playlooping or {}) do
						local t = {}
							t.dsp = dsp
							t.volume = NumVal(v.volume or "1",nil)
							t.pitch = NumVal(v.pitch or "100",nil,100)
							t.wave = string.match(v.wave,"^[@*](.+)") or v.wave -- Some sounds got a @ infront
							t.soundlevel = v.soundlevel
							t.position = v.position
							t.positionoverride = v.positionoverride
							t.ambientpositionoverride = v.ambientpositionoverride
							t.attenuation = v.attenuation
						table.insert(soundscape.playlooping,t)
					end
					for k,v in pairs(snd_list[snd_id].snd.playrandom or {}) do
						local t = {}
							t.dsp = dsp
							t.time = NumVal(v.time or "0")
							t.volume = NumVal(v.volume or "1",volume)
							t.pitch = NumVal(v.pitch or "100",pitch,100)
							t.soundlevel = v.soundlevel
							t.wave = v.wave
							t.position = v.position
							t.positionoverride = v.positionoverride
							t.ambientpositionoverride = v.ambientpositionoverride
							t.attenuation = v.attenuation
						table.insert(soundscape.playrandom,t)
					end
				-- Load the soundscapes
					for _,tab in pairs(snd_list[snd_id].snd.playsoundscape or {}) do
						local vo = NumVal(tab.volume or "1")
						local p = NumVal(tab.pitch or "100",nil,100)
						local snd = ListSoundsFromSoundScape(tab.name,vo,p,nil,dsp,true,tab.positionoverride)
						table.Add(soundscape.playlooping,snd.playlooping)
						table.Add(soundscape.playrandom,snd.playrandom)
					end
			return name,soundscape
		end
		local function UpdateSoundScape()
			if not IsValid(LocalPlayer()) then return end
			-- Scan and find all soundscapes nearby
				local pos = StormFox.GetCalcViewResult().pos
				local c = {}
				for k,v in pairs(SoundScapes()) do
					if not v.proxy then
						local tr = ET(pos,v.origin,MASK_SOLID_BRUSHONLY)
						if tr.Hit then continue end -- We're not in view
					end
					local dis = pos:DistToSqr(v.origin)
					local ss = v.soundscape
					if v.radius < 0 then
						table.insert(c,{k,dis,ss})
					elseif v.powradius >= dis then
						table.insert(c,{k,dis,ss})
					end
				end
				if #c <= 0 then return end
			-- Find the closest
				local closest,dis = 1,-1
				for k,v in pairs(c) do
					if dis < 0 or dis > v[2] then
						dis = v[2]
						closest = v[1]
					end
				end
			if currentSoundscapeID == closest then return end -- No update
			--	print("SoundScape ID: " .. closest)
			--	print("Name: " .. name)
			--	print("Range: " .. snd_list[closest].radius)
			--	print("Origin: ",snd_list[closest].origin)
			return GetSoundscape(closest)
		end
		local soundlvl = {}
			soundlvl["SNDLVL_NONE"] = 0
			soundlvl["SNDLVL_STATIC"] = 66
			soundlvl["SNDLVL_NORM"] = 75
			soundlvl["SNDLVL_TALKING"] = 80
			soundlvl["SNDLVL_GUNFIRE"] = 140
		local function GetSndLvl(str)
			if not str then return 0 end
			if soundlvl[str] then return soundlvl[str] end
			return tonumber(string.match(str:lower(),"sndlvl_(%d+)db")) or 0
		end
		local soundTimer = {}
		local soundRan = {}
		local current_SoundScape,current_original_SoundScape = {}
		function StormFox.SoundScape.GetData()
			return current_SoundScape
		end
		local function SetSoundScape(new_soundscape)
			if new_soundscape then -- In case of a new soundscape
				current_original_SoundScape = table.Copy(new_soundscape)
				current_SoundScape = new_soundscape
			else -- We need to "reload" the last soundscape
				current_SoundScape = table.Copy(current_original_SoundScape or {})
			end
			SetEnvironmentVariables()
			hook.Run("StormFox.SoundScape.OnUpdate",current_SoundScape)
			local sndFade = con and con:GetInt() or 3
			-- Stop all random sounds
				for k,v in pairs(STORMFOX_SOUNDSCAPE.playrandom) do
					if v[1] then
						v[1]:Stop()
					end
				end
				table.Empty(STORMFOX_SOUNDSCAPE.playrandom)
				table.Empty(soundTimer)
				table.Empty(soundRan)
			-- Loopsounds
				-- Get the current sound
					local current = {}
					for snd,v in pairs(STORMFOX_SOUNDSCAPE.playlooping) do
						current[snd] = true
					end
				-- Play the loopsound, everything is handled in the function.
					for k,v in pairs(current_SoundScape.playlooping or {}) do
						local snd = v.wave
						current[snd] = nil
						local pitch = math.Rand((v.pitch[1] or 1) * 100,(v.pitch[2] or 1) * 100)
						local volume = math.Rand(v.volume[1] or 1,v.volume[2] or 1)
						local pos
						if v.position then
							pos = current_SoundScape.soundpositions[v.position]
							if not pos then
								-- Some maps got unset positions for sounds. I got no idea why.
								continue
							end
						end
						PlaySound(snd,GetSndLvl(v.soundlevel),pitch,volume,v.dsp,sndFade,pos)
					end
				-- Out with the old loopsound
					for snd,_ in pairs(current) do
						StopSound(snd,sndFade)
					end
			-- Add randomsound
				for k,v in pairs(current_SoundScape.playrandom or {}) do
					soundTimer[k] = CurTime() + math.Rand(0,v.time[2])
				end
				soundRan = current_SoundScape.playrandom or {}
		end
		function StormFox.SoundScape.Reset()
			SetSoundScape()
		end
		function StormFox.SoundScape.Set(target_name)
			local _,id = FindSoundScapeByTargetName(target_name)
			if not id then return end
			local name,new_soundscape = GetSoundscape(id)
			if not new_soundscape then return end
			if devcon and devcon:GetBool() then
				MsgC(Color(255,255,255),"[SF] soundscape: " .. name .. "\n")
			end
			SetSoundScape(new_soundscape)
		end
		function StormFox.SoundScape.FindScript(soundscape_name)
			return GetAllSoundScapes()[soundscape_name]
		end
		local last_name = "None"
		function StormFox.SoundScape.GetName()
			return last_name or "none"
		end
		--hook.Add("StormFox.PostEntity","StormFox.ScanSoundScape",function()
			timer.Create("StormFox.SoundScape.Update",0.2,0,function()
				local name,new_soundscape = UpdateSoundScape()
				-- Only run if there is a new soundscape
					if not new_soundscape then return end
					if devcon and devcon:GetBool() then
						MsgC(Color(255,255,255),"[SF] soundscape: " .. name .. "\n")
					end
					last_name = name
					current_SoundScape = new_soundscape
				SetSoundScape(current_SoundScape)
			end)
			timer.Create("StormFox.SoundScape.RandomSnd",0.1,0,function()
				for k,t in pairs(soundTimer) do
					if t >= CurTime() then continue end
					local v = soundRan[k]
					soundTimer[k] = CurTime() + math.Rand(v.time[1],v.time[2])
					local snd = v.wave
					if type(snd) == "table" then
						snd = table.Random(snd)
					end
					local pos
					if v.position and current_SoundScape then
						pos = current_SoundScape.soundpositions[v.position]
						if not pos then
							if v.position == "random" then
								local pitch = math.Rand((v.pitch[1] or 1) * 100,(v.pitch[2] or 1) * 100)
								local volume = math.Rand( v.volume[1] or 1, v.volume[2] or 1)
								PlayRandomSoundLocation(snd,RandomSoundPos(),GetSndLvl(v.soundlevel),pitch,volume)
								continue
							else
								-- Some maps got unset positions for sounds. I got no idea why.
								-- Looks like source just voids them.
								continue
							end
						end
					end
					local pitch = math.Rand((v.pitch[1] or 1) * 100,(v.pitch[2] or 1) * 100)
					local volume = math.Rand(v.volume[1] or 1,v.volume[2] or 1)
					PlayRandomSound(snd,GetSndLvl(v.soundlevel),pitch,volume,1,pos) -- ,v.dsp) Some DSP's seem broken
				end
			end)
			timer.Create("StormFox.SoundScape.RandoSndFlush",1,0,function()
				for k,v in pairs(STORMFOX_SOUNDSCAPE.playrandom) do
					if (v[3] or 0) + 1 < CurTime() then
						if v[1] then
							v[1]:Stop()
						end
						STORMFOX_SOUNDSCAPE.playrandom[k] = nil
						continue
					end
				end
			end)
		--end)
	-- Debug display
		hook.Add("HUDPaint","StormFox.SoundScape.DebugHUD",function()
			if not sndcon:GetBool() then return end
			local i = -1
			surface.SetFont("default")
			for snd,snd_data in pairs(STORMFOX_SOUNDSCAPE.playlooping) do
				i = i + 1
				local y = i * 20
				surface.SetTextColor(Color(255,255,255))
				surface.SetTextPos(30,y + 100)
				surface.DrawText(snd)
				surface.SetDrawColor(0,255,0)
				surface.DrawRect(260,y + 100,snd_data[1] * 100,10)
				if snd_data[3] then
					surface.SetDrawColor(155,255,0)
					surface.DrawOutlinedRect(260,y + 100,snd_data[3][1] * 100,10)
				end
				surface.SetTextColor(255,255,255)
				surface.SetTextPos(380,y + 100)
				surface.DrawText(tostring(snd_data[2]))
			end
			for k,v in pairs(STORMFOX_SOUNDSCAPE.playrandom) do
				i = i + 1
				local y = i * 20
				surface.SetTextColor(Color(255,255,255))
				surface.SetTextPos(30,y + 100)
				surface.DrawText(k)
				surface.SetDrawColor(0,0,255)
				surface.DrawRect(260,y + 100,100,10)
				surface.SetTextColor(255,255,255)
				surface.SetTextPos(380,y + 100)

				surface.DrawText(tostring(v[2] or "random"))
			end
		end)
		hook.Add("PostDrawTranslucentRenderables","StormFox.SoundScape.DebugRender",function(a,b)
			if a or b then return end
			if not sndcon:GetBool() then return end
			if not StormFox.GetCalcViewResult then return end
			render.SetColorMaterial()
			local vpos = StormFox.GetCalcViewResult().pos
			for k,v in ipairs(SoundScapes()) do
				local pos = v.origin
				local range = v.radius
				if v.powradius < pos:DistToSqr(vpos) then
					if v.proxy then
						render.DrawSphere(pos,range,30,30,Color(255,55,55,55))
					else
						render.DrawSphere(pos,range,30,30,Color(55,255,55,55))
					end
				else
					if currentSoundscapeID == k then
						render.DrawSphere(pos,10,30,30,Color(55,255,55,255),true)
					else
						render.DrawSphere(pos,10,30,30,Color(55,44,255,55),true)
					end
				end
				if currentSoundscapeID == k then
					render.DrawLine(pos,vpos-Vector(0,0,60),Color(0,255,0),true)
				end
			end
		end)
	-- Soundscape env updater ( triggers when the wind or env changes )
		timer.Create("StormFox.SoundScape.Controller",5,0,function()
			if not IsNewEnvironment() then return end
			if devcon and devcon:GetBool() then
				MsgC(Color(255,255,255),"[SF] soundscape evironment update." .. "\n")
			end
			SetSoundScape() -- Update the soundscape.
		end)
	-- Enverioment guesser
		function StormFox.SoundScape.GetEnvState()
			local outside = string.match(last_name,"[%.%_]outside") or string.match(last_name,"[%.%_]outdoor")
			local inside = string.match(last_name,"[%.%_]inside") or string.match(last_name,"[%.%_]indoor")
			local state = (outside and -1 or 0) + (inside and 1 or 0)
			return state
		end