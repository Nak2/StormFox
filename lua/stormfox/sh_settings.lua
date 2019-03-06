local mapSettings = {}
local defaultSettings = {}
	defaultSettings["mintemp"] = -10 				--
	defaultSettings["maxtemp"] = 20					--
	defaultSettings["maxwind"] = 30					--
	defaultSettings["minlight"] = 4				--
	defaultSettings["maxlight"] = 40				--
	defaultSettings["dynamiclight"] = true 			--
	defaultSettings["material_replacment"] = true 		--
	defaultSettings["replace_dirtgrassonly"] = false 	--
	defaultSettings["override_sounds"] = false
	defaultSettings["sound_birds"] = false
	defaultSettings["sound_crickets"] = false
	defaultSettings["wind_breakconstraints"] = true
mapSettings = table.Copy(defaultSettings)
function StormFox.GetMapSetting(str,var)
	if mapSettings[str]~=nil then return mapSettings[str] end
	ErrorNoHalt("Unknown mapsetting: " .. str .. "\n")
	print(debug.Trace())
	return var
--	return var
end
function StormFox.AddMapSetting(cmd,key)
	if mapSettings[cmd]~=nil then return end
	mapSettings[cmd] = key
	if CLIENT then return end
	net.Start("sf_mapsettings")
		net.WriteString("up")
		net.WriteString(cmd)
		net.WriteType(key)
	net.Broadcast()
end

if SERVER then
	util.AddNetworkString("sf_mapsettings")
	if file.Exists("stormfox/mapsetting.txt","DATA") then
		local data = file.Read("stormfox/mapsetting.txt","DATA")
		local jsondata = util.JSONToTable(data)
		if not jsondata then
			ErrorNoHalt("INVALID MAP SETTINGS!")
			StormFox.Msg("Can't read the file: data/stormfox/mapsetting.txt")
		else
			mapSettings = jsondata
		end
		mapSettings["weather_clear"] = true -- Override it .. just in case someone disables it.
	end
	local function saveMapdata()
		local json = util.TableToJSON(mapSettings)
		file.Write("stormfox/mapsetting.txt",json)
	end
	function StormFox.SetMapSetting(str,var)
		if str == "weather_clear" then return end -- no no no
		mapSettings[str] = var
		saveMapdata()
		net.Start("sf_mapsettings")
			net.WriteString("up")
			net.WriteString(str)
			net.WriteType(var)
		net.Broadcast()
	end
	local function sendMapSettings(ply)
		net.Start("sf_mapsettings")
			net.WriteString("all")
			net.WriteTable(mapSettings)
		net.Send(ply)
	end
	local tickets = {}
	net.Receive("sf_mapsettings",function(len,ply)
		local msg = net.ReadString()
		if msg == "request" and not tickets[ply] then
			sendMapSettings(ply)
			tickets[ply] = true
		elseif msg == "set" then
			local key = net.ReadString()
			local var = net.ReadType()
			StormFox.Permission.SettingsEdit(ply,function()
				print(ply,"setting mapdata",key,var)
				StormFox.SetMapSetting(key,var)
			end)
		elseif msg == "menu" then
			local n = net.ReadInt(4)
			StormFox.Permission.SettingsEdit(ply,function()
				net.Start("sf_mapsettings")
					net.WriteString("openmenu")
					net.WriteInt(n,4)
				net.Send(ply)
			end)
		elseif msg == "setconvar" then
			local con = net.ReadString()
			local var = net.ReadString()
			StormFox.Permission.EasyConVar(ply,con,var)
		end
	end)
else
	net.Receive("sf_mapsettings",function(len,ply)
		local msg = net.ReadString()
		if msg == "all" then
			mapSettings = net.ReadTable()
		elseif msg == "up" then
			local key = net.ReadString()
			local var = net.ReadType()
			mapSettings[key] = var
		elseif msg == "openmenu" then
			local n = net.ReadInt(4)
			StormFox.OpenServerSettings(n)
		end
	end)
	function StormFox.SetConvarSetting(con,var)
		net.Start("sf_mapsettings")
			net.WriteString("setconvar")
			net.WriteString(con)
			net.WriteString(tostring(var))
		net.SendToServer()
	end
	function StormFox.SetMapSetting(str,var)
		net.Start("sf_mapsettings")
			net.WriteString("set")
			net.WriteString(str)
			net.WriteType(var)
		net.SendToServer()
	end
	timer.Simple(2,function()
		net.Start("sf_mapsettings")
			net.WriteString("request")
		net.SendToServer()
	end)
end

if CLIENT then return end
-- Auto pilot
	local function convar_check(str,var)
		local c = GetConVar(str)
		if not c then ErrorNoHalt("Unknown convar: " .. str) return end
		return c:GetString() == var
	end
local function RunPilot()
	if not convar_check("sf_autopilot","1") then return end
	StormFox.Msg("[AutoPilot] Checking settings ..")
	-- Light settings
		if StormFox.light_environment then
			-- Check for large map with ekstra lightsupport. We don't need the ektra lightsupport it.
			if convar_check("sf_enable_ekstra_lightsupport","1") then
				local mapsize = StormFox.MapOBBMaxs() - StormFox.MapOBBMins()
				local unit = mapsize:Length()
				if unit > 20000 then
					StormFox.Msg("[AutoPilot] Large map detected: sf_enable_ekstra_lightsupport 0")
					RunConsoleCommand("sf_enable_ekstra_lightsupport",0)
				elseif game.IsDedicated() then
					StormFox.Msg("[AutoPilot] No need for sf_enable_ekstra_lightsupport")
					RunConsoleCommand("sf_enable_ekstra_lightsupport",0)
				end
			end
		elseif convar_check("sf_enable_ekstra_lightsupport","0") then
			-- No light control. We need sf_enable_ekstra_lightsupport on 1
			StormFox.Msg("[AutoPilot] No light_environment detected: sf_enable_ekstra_lightsupport 1")
			RunConsoleCommand("sf_enable_ekstra_lightsupport",1)
		end
	-- Mapsupport
		if convar_check("sf_enable_mapsupport","0") then
			StormFox.Msg("[AutoPilot] No mapsupport. Requires restart: sf_enable_mapsupport 1")
			RunConsoleCommand("sf_enable_mapsupport",1)
		end
	-- Skybox
		if convar_check("sf_skybox","0") then
			StormFox.Msg("[AutoPilot] No skybox. Requires restart: sf_skybox 1")
			RunConsoleCommand("sf_skybox",1)
		end
	-- Dynamic light on 2D map
		if StormFox.GetMapSetting("dynamiclight") and not StormFox.Is3DSkybox() then
			StormFox.Msg("[AutoPilot] Disabled dynamic light: 2D map")
			StormFox.SetMapSetting("dynamiclight",false)
		end
	-- TreeSway isn't really that important

end
hook.Add("StormFox.PostEntityScan","StormFox - RunAutopilot",function()
	timer.Simple(1,RunPilot)
end)
