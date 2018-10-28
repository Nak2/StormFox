StormFox = {}
StormFox.Version = 1.394
StormFox.WorkShopVersion = false--game.IsDedicated()

function StormFox.Msg(...)
	MsgC(Color(155,155,255),"[StormFox] ",Color(255,255,255),...,"\n")
end
StormFox.Msg("V " .. StormFox.Version .. ".")

if SERVER then
	file.CreateDir("stormfox")
	file.CreateDir("stormfox/maps")
	AddCSLuaFile("stormfox/sh_settings.lua")
end

-- Skypaint creation fix.
	local con = GetConVar("sf_skybox")
	if not con or con:GetBool() then
		RunConsoleCommand("sv_skyname", "painted")
	end

-- Reload support
	hook.Add("InitPostEntity","StormFox - CallPostEntitiy",function()
		_STORMFOX_POSTENTIY = true
		hook.Call("StormFox - PostEntity")
	end)
	if _STORMFOX_POSTENTIY then
		timer.Simple(1,function()
			hook.Call("StormFox - PostEntity")
		end)
	end

-- Add configs
	StormFox.convars = {}
	local function AddConVar(str,default,helptext)
		StormFox.convars[str] = true
		if ConVarExists(str) then return end
		CreateConVar(str,default, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, helptext)
		-- FCVAR_REPLICATED is not 100% accurate for some reason
	end

	AddConVar("sf_timespeed",60,"Seconds of gametime pr real second.")
	AddConVar("sf_moonscale",6,"The scale of the moon.")
	AddConVar("sf_moonphase",1,"Enable moon-phases.")
	AddConVar("sf_enablefog",1,"Allow SF editing the fog.")
	AddConVar("sf_weatherdebuffs",game.IsDedicated() and 0 or 1,"Enable weather debuffs/damage/impact.")
	AddConVar("sf_windpush",game.IsDedicated() and 0 or 1,"Enable wind-push on props.")
	AddConVar("sf_lightningbolts",1,"Enable lightning strikes.")
	AddConVar("sf_enable_mapsupport",1,"Enable entity-support for maps.")
	AddConVar("sf_sunmoon_yaw",270,"The sun/moon yaw.")
	AddConVar("sf_debugcompatibility",0,"Enable SF compatability-debugger.")
	AddConVar("sf_skybox",1,"Enable SF-skybox.")
	--AddConVar("sf_enable_ekstra_lightsupport",1,"Enable ekstra lightsupport (engine.LightStyle)")
	AddConVar("sf_start_time","","Start the server at a specific time.")
	AddConVar("sf_mapbloom",0,"Allow SF editing light-bloom.")
	AddConVar("sf_enable_mapbrowser",game.IsDedicated() and 0 or 1,"Allow admins changing the map with SF-browser.")
	AddConVar("sf_allowcl_disableeffects",engine.ActiveGamemode() == "sandbox" and 1 or 0,"Allow clients to disable SF-effects.")
	AddConVar("sf_autoweather",1,"Enable weather-generation.")
	AddConVar("sf_block_lightenvdelete",1,"Set light_environment's targetname.")
	AddConVar("sf_realtime",0,"Follow the local time.")
	AddConVar("sf_foliagesway",1,"Enable foliagesway.")
	--	AddConVar("sf_disable_autoweather_cold",0,"Disable autoweather creating snow.")
	--	AddConVar("sf_sv_material_replacment",1,"Enable material-replacment for weather effects.")
	--	AddConVar("sf_replacment_dirtgrassonly",0,"Only replace dirt and grass. (Useful on crazy maps)")
	if CLIENT then
		CreateClientConVar("sf_disableeffects","0",true,false,"Disable all effects.")
		CreateClientConVar("sf_exspensive","0",true,false,"[0-7+] Enable exspensive weather calculations.")
		CreateClientConVar("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
		CreateClientConVar("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
		CreateClientConVar("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
		CreateClientConVar("sf_allow_dynamiclights","1",true,false,"Enable lamp-lights from SF.")
		CreateClientConVar("sf_allow_sunbeams","1",true,false,"Enable sunbeams.")
		CreateClientConVar("sf_allow_dynamicshadow","0",true,false,"Enable dynamic light/shadows.")
		CreateClientConVar("sf_dynamiclightamount","0",true,false,"Controls the dynamic-light amount.")
		CreateClientConVar("sf_redownloadlightmaps","1",true,false,"Lighterrors and light_environment fix (Can lagspike)")
		CreateClientConVar("sf_allow_raindrops","1",true,false,"Enable raindrops on the screen")
		CreateClientConVar("sf_renderscreenspace_effects","1",true,false,"Enable RenderScreenspaceEffects")
		CreateClientConVar("sf_useAInode","1",true,false,"Use AI nodes for more reliable sounds and effects.")
		CreateClientConVar("sf_enable_breath","1",true,false,"Enable cold breath-effect.")
		CreateClientConVar("sf_enablespooky","1",true,false,"Enable Halloween effect.")

	end
-- Add resources
	if SERVER then
		if StormFox.WorkShopVersion then
			resource.AddWorkshop("1132466603")
		else
		-- Add addon content
			local i = 0
			local function AddDir(dir,dirlen)
				if not dirlen then dirlen = dir:len() end
				local files, folders = file.Find(dir .. "/*", "GAME")
				for _, fdir in ipairs(folders) do
					if fdir != ".svn" then
						AddDir(dir .. "/" .. fdir)
					end
				end
				for k, v in ipairs(files) do
					local fil = dir .. "/" .. v --:sub(dirlen + 2)
					resource.AddFile(fil)
					i = i + 1
				end
			end
			AddDir("materials/stormfox")
			AddDir("sound/stormfox")
			AddDir("models/sf_models")

			StormFox.Msg("Added " .. i .. " content files")
		end
	end

-- Launch Stormfox
	-- Adds and runs files
	local function HandleFile(str)
		local path = str
		if string.find(str,"/") then
			path = string.GetFileFromFilename(str)
		end
		local _type = string.sub(path,0,3)
		if SERVER then
			if _type == "cl_" or _type == "sh_" then
				AddCSLuaFile(str)
			end
			if _type != "cl_" then
				--print("Running: " .. path)
				return include(str)
			end
		elseif _type != "sv_" then
			--print("Running: " .. path)
			return include(str)
		end
	end
	HandleFile("stormfox/" .. "cl_mvgui.lua")
	HandleFile("stormfox/" .. "sh_settings.lua")
	for _,fil in ipairs(file.Find("stormfox/framework/*.lua","LUA")) do
		HandleFile("stormfox/framework/" .. fil)
	end

	for _,fil in ipairs(file.Find("stormfox/functions/*.lua","LUA")) do
		HandleFile("stormfox/functions/" .. fil)
	end

	HandleFile("stormfox/" .. "sh_debugcompatibility.lua")
	HandleFile("stormfox/" .. "sh_weathertype_meta.lua")
	HandleFile("stormfox/" .. "sh_weather_controller.lua")

	if SERVER then
		HandleFile("stormfox/" .. "sv_map_lights.lua")
		HandleFile("stormfox/" .. "sv_weather_generator.lua")
	end
	for _,fil in ipairs(file.Find("stormfox/weather_types/*.lua","LUA")) do
		if SERVER then
			AddCSLuaFile("stormfox/weather_types/" .. fil)
		end
		include("stormfox/weather_types/" .. fil)
	end
	HandleFile("stormfox/" .. "sh_options.lua")
	HandleFile("stormfox/" .. "cl_wizard.lua")
	HandleFile("stormfox/" .. "cl_mapbrowser.lua")
	hook.Call("StormFox - PostInit")
-- Check version
	if CLIENT then
		local function ReportVersion(version)
			if StormFox.Version < version then
				chat.AddText(Color(155,155,255),"[StormFox]",Color(255,255,255),": You're running an older version of StormFox.")
				chat.AddText(Color(155,155,255),"[StormFox]",Color(255,255,255),": " .. StormFox.Version .. " < " .. version)
			end
		end
		hook.Add("StormFox - NetDataChange","VersionCheck",function(str,var)
			if str ~= "workshopVersion" then return end
			ReportVersion(var)
		end)
		local workshopVersion = StormFox.GetNetworkData("workshopVersion")
		if workshopVersion then
			ReportVersion(workshopVersion)
		end
		return
	end

	local function onSuccess(body)
		local workshopVersion = tonumber(body:match('Version ([%d%.]+)%s') or "") or StormFox.Version
		StormFox.SetNetworkData("workshopVersion",workshopVersion or StormFox.Version)
		if workshopVersion > StormFox.Version then
			StormFox.Msg(Color(255,0,0),"Outdated version. Workshop got version: " .. workshopVersion)
			StormFox.Msg("You're running: " .. StormFox.Version)
		elseif workshopVersion < StormFox.Version then
			StormFox.Msg("You're running a newer version than the workshop. Careful with unknown bugs.")
		else
			StormFox.Msg("Running last version.")
		end
	end
	http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=1132466603",onSuccess,function() StormFox.SetNetworkData("workshopVersion",StormFox.Version) end)

	hook.Add("PostGamemodeLoaded","StormFox.GM",function()
		local GM = GM or GAMEMODE
		if GM.StormFox then
			print("[StormFox]: What are we going to do tonight?")
			local mapsettings = GM.StormFox()
			if not mapsettings then return end
			print("[StormFox]: Alright .. got the settings.")
			StormFox.SetMapSettings(mapsettings)
		end
	end)

-- Sandbox load support
	-- Hack to stop cleanupmap breaking SF
		STORMFOX_CLEANUPMAP = STORMFOX_CLEANUPMAP or game.CleanUpMap
		function game.CleanUpMap( dontSendToClients, ExtraFilters )
			ExtraFilters = ExtraFilters or {}
			table.insert(ExtraFilters,"light_environment")
			table.insert(ExtraFilters,"env_fog_controller")
			table.insert(ExtraFilters,"shadow_control")
			table.insert(ExtraFilters,"env_tonemap_controller")
			table.insert(ExtraFilters,"env_wind")
			table.insert(ExtraFilters,"env_skypaint")
			STORMFOX_CLEANUPMAP(dontSendToClients,ExtraFilters)
		end
	-- Rescan a map when loaded from a save
		hook.Add("LoadGModSave","StormFox - SandboxLoadSupport",function()
			hook.Call( "StormFox - PostEntity" )
		end)