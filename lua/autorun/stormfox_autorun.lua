StormFox = {}
StormFox.Version = 1.118
StormFox.WorkShopVersion = false --game.IsDedicated()

if SERVER then
	game.ConsoleCommand("sv_skyname painted\n")
end
--if true then return end
-- Reload support
	hook.Add("InitPostEntity","StormFox - CallPostEntitiy",function()
		hook.Call("StormFox - PostEntity")
		_STORMFOX_POSTENTIY = true
	end)
	if _STORMFOX_POSTENTIY then
		timer.Simple(1,function()
			hook.Call("StormFox - PostEntity")
		end)
	end

-- Add configs
	if not ConVarExists("sf_timespeed") then
		CreateConVar("sf_timespeed",1, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "The minutes of gametime pr second." )
	end
	if not ConVarExists("sf_moonscale") then
		CreateConVar("sf_moonscale",6,{ FCVAR_REPLICATED , FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Set the moonscale." )
	end
	if not ConVarExists("sf_sv_material_replacment") then
		CreateConVar("sf_sv_material_replacment",1, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Replaces materials for weather effects.")
	end
	if not ConVarExists("sf_replacment_dirtgrassonly") then
		CreateConVar("sf_replacment_dirtgrassonly",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Replace only dirt and grass. (Useful on crazy maps)")
	end
	if not ConVarExists("sf_disablefog") then
		CreateConVar("sf_disablefog",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the fog.")
	end
	if not ConVarExists("sf_disableweatherdebuffs") then
		CreateConVar("sf_disableweatherdebuffs",game.IsDedicated() and 1 or 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable weather debuffs/damage/impact.")
	end
	if not ConVarExists("sf_disable_windpush") then
		CreateConVar("sf_disable_windpush",game.IsDedicated() and 1 or 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable wind-push on props (Careful on servers).")
	end
	if not ConVarExists("sf_disablelightningbolts") then
		CreateConVar("sf_disablelightningbolts",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable lightning strikes.")
	end
	if not ConVarExists("sf_disable_autoweather") then
		CreateConVar("sf_disable_autoweather",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the automatic weather-generator.")
	end
	if not ConVarExists("sf_disable_mapsupport") then
		CreateConVar("sf_disable_mapsupport",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the entity-support for maps.")
	end
	if not ConVarExists("sf_disable_autoweather_cold") then
		CreateConVar("sf_disable_autoweather_cold",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Stop the autoweather creating snow.")
	end
	if not ConVarExists("sf_sunmoon_yaw") then
		CreateConVar("sf_sunmoon_yaw",270, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "The sun/moon yaw.")
	end
	if not ConVarExists("sf_debugcompatibility") then
		CreateConVar("sf_debugcompatibility",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Enable SF compatability-debugger.")
	end
	if not ConVarExists("sf_disableskybox") then
		CreateConVar("sf_disableskybox",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the SF-skybox.")
	end
	if not ConVarExists("sf_enable_ekstra_lightsupport") then
		CreateConVar("sf_enable_ekstra_lightsupport",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Enable ekstra lightsupport (engine.LightStyle)")
	end
	if not ConVarExists("sf_start_time") then
		CreateConVar("sf_start_time","", { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Start the server at a specific time.")
	end
	if not ConVarExists("sf_disable_mapbloom") then
		CreateConVar("sf_disable_mapbloom",0, { FCVAR_REPLICATED, FCVAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE }, "Disable the light-bloom.")
	end

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
		--		if string.find(fil,"vmt") or string.find(fil,"png") then
		--			print('"' .. string.sub(fil,11) .. '",')
		--		end
				i = i + 1
			end
		end
		AddDir("materials/stormfox")
		AddDir("sound/stormfox")

		MsgN("[StormFox] Added " .. i .. " content files")
	end
else
	CreateClientConVar("sf_exspensive","0",true,false,"[0-7+] Enable exspensive weather calculations.")
	CreateClientConVar("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
	CreateClientConVar("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
	CreateClientConVar("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
	CreateClientConVar("sf_allow_dynamiclights","1",true,false,"Enable lamp-lights from SF.")
	CreateClientConVar("sf_allow_sunbeams","1",true,false,"Enable sunbeams.")
	CreateClientConVar("sf_allow_dynamicshadow","0",true,false,"Enable dynamic light/shadows.")
	CreateClientConVar("sf_redownloadlightmaps","1",true,false,"Lighterrors and light_environment fix (Can lagspike)")
	CreateClientConVar("sf_allow_raindrops","1",true,false,"Enables raindrops on the screen")
	CreateClientConVar("sf_renderscreenspace_effects","1",true,false,"Enables RenderScreenspaceEffects")
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
hook.Call("StormFox - PostInit")