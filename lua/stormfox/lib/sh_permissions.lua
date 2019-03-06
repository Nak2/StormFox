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
	function StormFox.Permission.WetherEdit(ply,funcsucc,funcfail)
		print(ply,"call weather edit")
		if not funcfail then funcfail = fail end
		-- If singleplayer/host
			if ply:IsListenServerHost() then
				funcsucc(ply)
				return
			end
		-- Check CAMI
			CAMI.PlayerHasAccess(ply,"StormFox WeatherEdit",function(b)
				if not b then funcfail(ply) return end
				funcsucc(ply)
			end)
	end
	function StormFox.Permission.SettingsEdit(ply,funcsucc,funcfail)
		if not funcfail then funcfail = failsettings end
		-- If singleplayer/host
			if ply:IsListenServerHost() then
				funcsucc(ply)
				return
			end
		-- Check CAMI
			CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
				if not b then funcfail(ply) return end
				funcsucc(ply)
			end)
	end
	local con = GetConVar("sf_enable_mapbrowser")
	function StormFox.Permission.MapChange(ply,map_name)
		if con and not con:GetBool() then
			return msg(ply,"sf_permisson.denymapsetting")
		end
		map_name = string.match(map_name,"(.+).bsp$") or map_name
		-- Check if its a valid map
			local validmap = false
			for i,v in ipairs(file.Find("maps/*.bsp","GAME")) do
				if v == map_name .. ".bsp" then
					validmap = true
				end
			end
		-- If singleplayer/host
			if ply:IsListenServerHost() then
				if SERVER then
					if validmap then
						print("[StormFox] " .. (ply and ply:Nick() .. " is changing the map to" or "Changing map to") .. " " .. map_name .. ".")
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
			CAMI.PlayerHasAccess(ply,"StormFox Changemap",function(b)
				if not b then msg(ply,"sf_permisson.denymap") return end
				if SERVER then
					if validmap then
						print("[StormFox] " .. (ply and ply:Nick() .. " is changing the map to" or "Changing map to") .. " " .. map_name .. ".")
						RunConsoleCommand("changelevel",map_name)
					else
						msg(ply,"sf_permisson.denymapmissing")
					end
					return
				else
					RunConsoleCommand("sf_map_change",map_name)
					return
				end
			end)
	end
	function StormFox.Permission.EasyConVar(ply,con,var)
		-- Check if its a stormfox setting
			if not StormFox.convars[con] then failsettings(ply) return end
		-- If singleplayer/host
			if ply:IsListenServerHost() then
				RunConsoleCommand(con,var)
				return
			end
		-- Check CAMI
			CAMI.PlayerHasAccess(ply,"StormFox Settings",function(b)
				if not b then failsettings(ply) return end
				RunConsoleCommand(con,var)
			end)
	end
-- Console command
	if CLIENT then
		concommand.Add("sf_map_change")
		return
	else
		concommand.Add("sf_map_change",function(ply,_,args)
			StormFox.Permission.MapChange(ply,args[1])
		end)
	end