
--[[-------------------------------------------------------------------------
	Soundscapes are a bit tricky
	We need to make our own system.
	We create most of it on the client, however we need some server-entities and env_soundscape_triggerable.

	Problems with Vavles soundscape
		- EmitSound hook doesn't get called with soundscape.
		- If we disable all .. the last will just continue to play.
		- If we remove all and create our own. It'll crash.
		- Override the varables doesn't do anything:
			ent:SetSaveValue("m_soundscapeName","Nothing")
			ent:SetSaveValue("m_iName","Nothing")
			Besides the debug tool changing name.
---------------------------------------------------------------------------]]
	local conVar = GetConVar("sf_overridemapsounds")
	if not conVar:GetBool() then return end

STORMFOX_SOUNDSCAPE_ENTITY = STORMFOX_SOUNDSCAPE_ENTITY or {}
-- "Delete" all soundscapes
	hook.Add("OnEntityCreated","StormFox.SoundScape.Delete",function(ent)
		if ent:GetClass() ~= "env_soundscape" and ent:GetClass() ~= "env_soundscape_proxy" and ent:GetClass() ~= "env_soundscape_triggerable" then return end
		--timer.Simple(0,function() ent:Remove() end) Can crash on some maps. For some odd reason.
		ent:Fire("Disable")
		timer.Simple(0,function()
			ent:Fire("Disable")
		end)
	end)
	-- Just to be sure about the nail in the coffin
		timer.Simple(1,function()
			for i,v in ipairs(ents.FindByClass("env_soundscape*")) do
				v:Fire("Disable")
			end
		end)
	-- Stop the default soundscape from waking up
		hook.Add("AcceptInput","StormFox.SoundScape.IO",function(ent,input,act,call,val)
			if not IsValid(ent) then return end
			local class = ent:GetClass()
			if class == "trigger_soundscape" then
				if input == "Enable" then
					ent.enabled = true
				elseif input == "Disable" then
					ent.enabled = false
				end
			elseif class == "env_soundscape_triggerable" or class == "env_soundscape" or class == "env_soundscape_proxy" then
				local kv = ent:GetKeyValues()
				if kv.hammerid and StormFox.SoundScape.EnableSoundScape then
					if input == "Enable" then
						ent.IgnoreTick = true
					end
					if ent.IgnoreTick and input == "Disable" then
						ent.IgnoreTick = false
					else
						StormFox.SoundScape.EnableSoundScape(kv.hammerid,input ~= "Disable")
					end
				end
				if input == "Enable" then -- No no no, don't wake the zombie up.
					ent:Fire("Disable")
					return true
				end
			end
		end)
-- Read the soundscapes
		local function ReadKeyVars(str)
			local key,var = string.match(str,[[([^"%s]+)[%s	"]+([^"%s]+)]])
			if var and (#var <= 0 or string.match(var,"^//")) then
				var = nil
			end
			if key and (#key <= 0 or string.match(key,"^//")) then
				key = nil
			end
			if key and var then
				return key,var
			else
				return string.match(str,[[([^"%s	]+)]])
			end
		end
	-- File
		local function ReadLooping(f)
			local t = {}
			for i = 1,20 do
				local l = f:ReadLine()
				local key,var = ReadKeyVars(l)
				if key and var then
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
				local key,var = ReadKeyVars(l)
				if key and var then
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
				local key,var = ReadKeyVars(l)
				if key and var then
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
					if not l then break end
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
					soundscape[l] = {}
					cur_soundscape = l
				elseif lvl == 1 then
					local key,var = ReadKeyVars(l)
					if key and not var then
						soundscape[cur_soundscape][key] = soundscape[cur_soundscape][key] or {}
						if key == "playrandom" then
							table.insert(soundscape[cur_soundscape][key],ReadRandom(f))
						elseif key == "playsoundscape" then
							table.insert(soundscape[cur_soundscape][key],ReadSoundscape(f))
						elseif key == "playlooping" then
							table.insert(soundscape[cur_soundscape][key],ReadLooping(f))
						end
					elseif key and var then
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
	-- String
		local function ReadDataLooping(arr,line)
			local t = {}
			for i = 1,30 do
				local l = arr[line + i]
				local key,var = ReadKeyVars(l)
				if key and var then
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
		local function ReadDataSoundscape(arr,line)
			local t = {}
			for i = 1,30 do
				local l = arr[line + i]
				local key,var = ReadKeyVars(l)
				if key and var then
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
		local function ReadDataRandom(arr,line)
			local t = {}
			local lvl = 0
			for i = 1,80 do
				local l = arr[line + i]
				local key,var = ReadKeyVars(l)
				if key and var then
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
		local function ReadSoundScapeData(data)
			local lvl = 0
			local soundscape = {}
			local cur_soundscape
			local cur_tab = {}
			local arr = string.Explode("\n",data)
			for i = 1,3000 do -- I hate while loops
				local l = arr[i]
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
					soundscape[l] = {}
					cur_soundscape = l
				elseif lvl == 1 then
					local key,var = ReadKeyVars(l)
					if key and not var then
						soundscape[cur_soundscape][key] = soundscape[cur_soundscape][key] or {}
						if key == "playrandom" then
							table.insert(soundscape[cur_soundscape][key],ReadDataRandom(arr,i))
						elseif key == "playsoundscape" then
							table.insert(soundscape[cur_soundscape][key],ReadDataSoundscape(arr,i))
						elseif key == "playlooping" then
							table.insert(soundscape[cur_soundscape][key],ReadDataLooping(arr,i))
						end
					elseif key and var then
						if key == "dps" then
							soundscape[cur_soundscape][key] = tonumber(var)
						else
							soundscape[cur_soundscape][key] = var
						end
					end
				end
			end
			return soundscape
		end
		--_STORMFOX_MAP__SoundScapes
	local function ReadsoundScapeFolder(tab,folder)
		if not tab then tab = {} end
		local files,folders = file.Find(folder .. "/*","GAME")
		for _,v in pairs(files) do
			local path = folder .. "/" .. v
			for k,v in pairs(ReadSoundScapeFile(path)) do
				tab[k] = v
			end
		end
		for _,v in pairs(folders) do
			local path = folder .. "/" .. v
			ReadsoundScapeFolder(tab,path)
		end
		return tab
	end
	local t
	local function GetAllSoundScapes()
		if t then return t end
		t = ReadsoundScapeFolder(t,"scripts/soundscapes")
		for fil,data in pairs(_STORMFOX_MAP__SoundScapes or {}) do
			for k,v in pairs(ReadSoundScapeData(data)) do
				t[k] = v
			end
		end
		return t
	end
-- Place entities
	local function GetEntityLocation(str)
		if STORMFOX_SOUNDSCAPE_ENTITY[str] then
			if IsValid(STORMFOX_SOUNDSCAPE_ENTITY[str]) then
				return STORMFOX_SOUNDSCAPE_ENTITY[str]
			else
				STORMFOX_SOUNDSCAPE_ENTITY[str] = nil
			end
		end
		for id,data in pairs(StormFox.MAP.Entities()) do
			if data.targetname ~= str then continue end
			local e = ents.Create("stormfox_soundscape")
				e:SetPos(data.origin)
				e:SetNWString("targetname",str)
				e:Spawn()
			STORMFOX_SOUNDSCAPE_ENTITY[str] = e
			return STORMFOX_SOUNDSCAPE_ENTITY[str]
		end
	end

-- Load the soundscapes
	local function SoundScapes()
		-- Load the soundscape list
			local snd = GetAllSoundScapes()
		-- Get the list of soundscape data from the map.
			local snd_list = {}
			for id,data in pairs(StormFox.MAP.Entities()) do
				if data.classname == "env_soundscape" then
					local t = {}
					t.soundscape = data.soundscape
					t.radius = data.radius
					t.powradius = data.radius^2 -- Cause its faster
					--t.mapdata = data
					t.origin = util.StringToType(data.origin or "0 0 0","Vector")
					t.snd = snd[t.soundscape] or {}
					t.classname = data.classname
					t.targetname = data.targetname
					t.soundpositions = {}
						for i = 0,7 do
							if data["position" .. i] then
								local e = GetEntityLocation(data["position" .. i])
								table.insert(t.soundpositions,e)
							end
						end
					table.insert(snd_list,t)
				elseif data.classname == "env_soundscape_proxy" or data.classname == "env_soundscape_triggerable" then
					local t = {}
					t.soundscape = data.soundscape
					t.radius = data.radius
					t.powradius = data.radius^2 -- Cause its faster
					--t.mapdata = data
					t.origin = util.StringToType(data.origin or "0 0 0","Vector")
					t.snd = snd[t.soundscape] or {}
					t.classname = data.classname
					t.targetname = data.targetname
					t.proxy = true
					t.soundpositions = {}
						for i = 0,7 do
							if data["position" .. i] then
								table.insert(t.soundpositions,GetEntityLocation(data["position" .. i]))
							end
						end
					table.insert(snd_list,t)
				end
			end
		return snd_list
	end

-- Will create all soundscape entities
	hook.Add("StormFox.PostEntity","StormFox.ScanSoundScape",SoundScapes)
-- Serverside things
	StormFox.SoundScape = {}
	util.AddNetworkString("sv_trigger_soundscape")
	function StormFox.SoundScape.TriggerSoundScape(str,ply)
		net.Start("sv_trigger_soundscape")
			net.WriteInt(0,3)
			net.WriteString(str)
		net.Send(ply)
	end
	function StormFox.SoundScape.EnableSoundScape(hammerid,bool)
		net.Start("sv_trigger_soundscape")
			net.WriteInt(1,3)
			net.WriteString(hammerid .. "")
			net.WriteBool(bool)
		net.Broadcast()
	end

