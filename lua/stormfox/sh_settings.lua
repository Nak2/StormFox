local mapSettings = {}
local defaultSettings = {}
	defaultSettings["mintemp"] = -10 				--
	defaultSettings["maxtemp"] = 20					--
	defaultSettings["maxwind"] = 30					--
	defaultSettings["minlight"] = 2				--
	defaultSettings["maxlight"] = 80				--
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
		mapSettings = util.JSONToTable(file.Read("stormfox/mapsetting.txt","DATA"))
		mapSettings["weather_clear"] = true
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
			StormFox.CanEditMapSetting(ply,function()
				print(ply,"setting mapdata",key,var)
				StormFox.SetMapSetting(key,var)
			end)
		elseif msg == "menu" then
			StormFox.CanEditMapSetting(ply,function()
				net.Start("sf_mapsettings")
					net.WriteString("openmenu")
				net.Send(ply)
			end)
		elseif msg == "setconvar" then
			local con = net.ReadString()
			local var = net.ReadString()
			StormFox.CanEditSetting(ply,con,var)
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
			StormFox.OpenServerSettings()
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
	timer.Simple(1,function()
		net.Start("sf_mapsettings")
			net.WriteString("request")
		net.SendToServer()
	end)
end