--[[-------------------------------------------------------------------------
Permission system
	Functions:
		- StormFox.Permission.WetherEdit(ply,funcsucc,funcfail)
		- StormFox.Permission.SettingsEdit(ply,funcsucc,funcfail)
		- StormFox.Permission.MapChange(ply,map_name)

	CAMI Permissions:
		- StormFox WeatherEdit
		- StormFox Settings
		- StormFox Changemap

	Console command:
		- sf_map_change 	<map_name>
---------------------------------------------------------------------------]]
include("stormfox/cami/sh_cami.lua")
if SERVER then
	util.AddNetworkString("sf_msg")
	AddCSLuaFile("stormfox/cami/sh_cami.lua")
end
if not CAMI then return end
StormFox.Permission = {}
-- Permission to edit StormFox settings
	CAMI.RegisterPrivilege{
		Name = "StormFox Settings",
		MinAccess = "superadmin"
	}
-- Permission to edit StormFox weather and time
	CAMI.RegisterPrivilege{
		Name = "StormFox WeatherEdit",
		MinAccess = "admin"
	}
-- Permission to use the mapchanger
	CAMI.RegisterPrivilege{
		Name = "StormFox Changemap",
		MinAccess = "superadmin"
	}

-- Msg functions
	if CLIENT then
		net.Receive("sf_msg",function()
			local msg = net.ReadString()
			chat.AddText(Color(155,155,255),"[StormFox] ",Color(255,255,255),StormFox.Language.Translate(msg) .. ".")
		end)
	end
	local function msg(ply,str)
		if SERVER then
			if not IsValid(ply) then -- Server console
				StormFox.Msg(str) -- Msg translates it
				return
			end
			net.Start("sf_msg")
				net.WriteString(str)
			net.Send(ply)
		else
			chat.AddText(Color(155,155,255),"[StormFox] ",Color(255,255,255),StormFox.Language.Translate(str) .. ".")
		end
	end
	local function fail(ply)
		msg(ply,"sf_permisson.deny")
	end
	local function failsettings(ply)
		msg(ply,"sf_permisson.denysettings")
	end
-- Functions
	-- Asks if ply has the privilege and calls answer(bool). CAMI might answer later.
	local function HasAccess(ply,privilege,answer)
		-- The server console can do anything.
		if SERVER and not IsValid(ply) then return answer(true) end
		-- Nobody is there to ask.
		if not IsValid(ply) then return answer(false) end
		-- Singleplayer / listen server host
		if ply:IsListenServerHost() then return answer(true) end
		CAMI.PlayerHasAccess(ply,privilege,answer)
	end
	-- Turns the answer into the success / fail functions the old api uses.
	local function Branch(ply,privilege,onYes,onNo)
		HasAccess(ply,privilege,function(allowed)
			local func = allowed and onYes or onNo
			if isfunction(func) then func(ply) end
		end)
	end
	function StormFox.Permission.WetherEdit(ply,funcsucc,funcfail)
		Branch(ply,"StormFox WeatherEdit",funcsucc,funcfail or fail)
	end
	function StormFox.Permission.SettingsEdit(ply,funcsucc,funcfail)
		Branch(ply,"StormFox Settings",funcsucc,funcfail or failsettings)
	end
	local con = GetConVar("sf_enable_mapbrowser")
	local function MapChangeText(ply)
		if not IsValid(ply) then return "Changing map to" end
		return ply:Nick() .. " is changing the map to"
	end
	local function denymap(ply)
		msg(ply,"sf_permisson.denymap")
	end
	function StormFox.Permission.MapChange(ply,map_name)
		if con and not con:GetBool() then
			return msg(ply,"sf_permisson.denymapsetting")
		end
		if type(map_name) ~= "string" or #map_name < 1 then return end
		map_name = string.match(map_name,"^(.+)%.bsp$") or map_name
		-- Check if its a valid map
			local validmap = false
			for i,v in ipairs(file.Find("maps/*.bsp","GAME")) do
				if v == map_name .. ".bsp" then
					validmap = true
				end
			end
		-- If singleplayer/host/server console
			if not IsValid(ply) or ply:IsListenServerHost() then
				if SERVER then
					if validmap then
						print("[StormFox] " .. MapChangeText(ply) .. " " .. map_name .. ".")
						RunConsoleCommand("changelevel",map_name)
					else
						msg(ply,"sf_permisson.denymapmissing")
					end
					return
				else
					RunConsoleCommand("sf_map_change",map_name)
					return
				end
			end
		-- Check CAMI
			Branch(ply,"StormFox Changemap",function()
				if SERVER then
					if validmap then
						print("[StormFox] " .. MapChangeText(ply) .. " " .. map_name .. ".")
						RunConsoleCommand("changelevel",map_name)
					else
						msg(ply,"sf_permisson.denymapmissing")
					end
					return
				else
					RunConsoleCommand("sf_map_change",map_name)
					return
				end
			end,denymap)
	end
	function StormFox.Permission.EasyConVar(ply,con,var)
		-- Check if its a stormfox setting
			if not StormFox.convars[con] then failsettings(ply) return end
		Branch(ply,"StormFox Settings",function()
			RunConsoleCommand(con,var == nil and "" or tostring(var))
		end,failsettings)
	end
-- Console command
	if CLIENT then return end -- Clients forward unknown commands to the server
	concommand.Add("sf_map_change",function(ply,_,args)
		if not args[1] then return end
		StormFox.Permission.MapChange(ply,args[1])
	end)